import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import 'service_eligibility_repository.dart';

part 'persons_repository.g.dart';

class PersonListDTO {
  final int id;
  final String name;
  final String stageName;
  final String khorosName;
  final String areaName;
  final String phone;
  final String mobile;
  final String streetName;
  final String fatherName;
  final int? stageId;
  final int? khorosId;
  final int? areaId;
  final int? fatherId;
  final int? day;
  final int? month;
  final int? year;
  final String? jenderName;
  final Uint8List? photo;
  final List<int> serviceIds;
  final String? rohot;
  final String? leader;
  final String? relationship;
  final String? services;
  final Map<int, String> customValues;

  PersonListDTO({
    required this.id,
    required this.name,
    required this.stageName,
    required this.khorosName,
    required this.areaName,
    required this.phone,
    required this.mobile,
    required this.streetName,
    required this.fatherName,
    this.stageId,
    this.khorosId,
    this.areaId,
    this.fatherId,
    this.day,
    this.month,
    this.year,
    this.jenderName,
    this.photo,
    this.serviceIds = const [],
    this.relationship,
    this.rohot,
    this.leader,
    this.services,
    this.customValues = const {},
  });
}

@Riverpod(keepAlive: true)
class PersonsRepository extends _$PersonsRepository {
  @override
  FutureOr<List<PersonListDTO>> build() async {
    ref.watch(appDatabaseProvider);
    ref.watch(authServiceProvider);

    // Initial build returns a baseline of persons for autocompletion suggestions.
    // We limit this to 1000 to balance between performance and availability of suggestions.
    return fetchPersons(limit: 1000, includeServices: false);
  }

  Future<List<PersonListDTO>> fetchPersons({
    String? search,
    int? limit,
    int? offset,
    List<int>? stageIds,
    List<int>? khorosIds,
    List<int>? areaIds,
    List<int>? fatherIds,
    List<String>? genders,
    List<int>? birthdayDay,
    List<int>? birthdayMonth,
    List<int>? birthdayYear,
    List<String>? rohots,
    List<String>? leaders,
    List<int>? personIds,
    bool includeServices = true,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final user = ref.read(authServiceProvider).value;
    final filters = user?.visibilityFilters ?? {};

    var query = db.select(db.persons).join([
      drift.leftOuterJoin(
        db.stages,
        db.stages.stageId.equalsExp(db.persons.stageId),
      ),
      drift.leftOuterJoin(
        db.khoroses,
        db.khoroses.khorosId.equalsExp(db.persons.khorosId),
      ),
      drift.leftOuterJoin(
        db.areas,
        db.areas.areaId.equalsExp(db.persons.areaId),
      ),
      drift.leftOuterJoin(
        db.fathers,
        db.fathers.fatherId.equalsExp(db.persons.fatherId),
      ),
    ]);

    if (stageIds != null && stageIds.isNotEmpty) {
      query.where(db.persons.stageId.isIn(stageIds));
    }
    if (khorosIds != null && khorosIds.isNotEmpty) {
      query.where(db.persons.khorosId.isIn(khorosIds));
    }
    if (areaIds != null && areaIds.isNotEmpty) {
      final descendantIds = await db.getMultipleAreasAndDescendantIds(areaIds);
      query.where(db.persons.areaId.isIn(descendantIds));
    }
    if (fatherIds != null && fatherIds.isNotEmpty) {
      query.where(db.persons.fatherId.isIn(fatherIds));
    }
    if (genders != null && genders.isNotEmpty) {
      query.where(db.persons.jenderName.isIn(genders));
    }
    if (rohots != null && rohots.isNotEmpty) {
      query.where(db.persons.rohot.isIn(rohots));
    }
    if (leaders != null && leaders.isNotEmpty) {
      query.where(db.persons.leader.isIn(leaders));
    }

    if (birthdayDay != null && birthdayDay.isNotEmpty) {
      query.where(db.persons.day.isIn(birthdayDay));
    }
    if (birthdayMonth != null && birthdayMonth.isNotEmpty) {
      query.where(db.persons.month.isIn(birthdayMonth));
    }
    if (birthdayYear != null && birthdayYear.isNotEmpty) {
      query.where(db.persons.year.isIn(birthdayYear));
    }
    if (personIds != null && personIds.isNotEmpty) {
      query.where(db.persons.personId.isIn(personIds));
    }

    // Admins or managers see everyone by default to avoid confusion
    if (user != null && user.canPersons) {
      // Skip visibility filters
    } else if (user != null && user.isAdvanced) {
      await _applyVisibilityFilters(query, db, filters);
    }

    if (search != null && search.isNotEmpty) {
      final s = '%${search.trim()}%';
      query.where(
        db.persons.personName.like(s) |
            db.persons.mobile.like(s) |
            db.persons.phone.like(s) |
            db.persons.streetName.like(s) |
            db.persons.personId.cast<String>().like(s),
      );
    }

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    query.orderBy([
      drift.OrderingTerm(
        expression: db.persons.personId,
        mode: drift.OrderingMode.desc,
      ),
    ]);

    final results = await query.get();

    final fetchedPersonIds = results
        .map((row) => row.readTable(db.persons).personId)
        .whereType<int>()
        .toList();

    final personServicesMap = <int, List<int>>{};
    final personServiceNamesMap = <int, List<String>>{};
    final personCustomValuesMap = <int, Map<int, String>>{};

    if (fetchedPersonIds.isNotEmpty) {
      final allServices = await (db.select(db.personServices).join([
        drift.innerJoin(
          db.services,
          db.services.serviceId.equalsExp(db.personServices.serviceId),
        ),
      ])..where(db.personServices.personId.isIn(fetchedPersonIds))).get();

      for (final row in allServices) {
        final ps = row.readTable(db.personServices);
        final svc = row.readTable(db.services);
        personServicesMap.putIfAbsent(ps.personId, () => []).add(ps.serviceId);
        if (svc.serviceName != null && svc.serviceName!.isNotEmpty) {
          personServiceNamesMap
              .putIfAbsent(ps.personId, () => [])
              .add(svc.serviceName!);
        }
      }

      final customRows = await (db.select(
        db.personCustomFieldValues,
      )..where((t) => t.personId.isIn(fetchedPersonIds))).get();
      for (final r in customRows) {
        personCustomValuesMap.putIfAbsent(r.personId, () => {})[r.fieldId] =
            r.value ?? '';
      }
    }

    return results.map((row) {
      final person = row.readTable(db.persons);
      final stage = row.readTableOrNull(db.stages);
      final khoros = row.readTableOrNull(db.khoroses);
      final area = row.readTableOrNull(db.areas);
      final father = row.readTableOrNull(db.fathers);

      return PersonListDTO(
        id: person.personId ?? 0,
        name: person.personName ?? 'Unknown',
        stageName: stage?.stageName ?? '',
        khorosName: khoros?.khorosName ?? '',
        areaName: area?.areaName ?? '',
        phone: person.phone ?? '',
        mobile: person.mobile ?? '',
        streetName: person.streetName ?? '',
        fatherName: father?.fatherName ?? '',
        stageId: person.stageId,
        khorosId: person.khorosId,
        areaId: person.areaId,
        fatherId: person.fatherId,
        day: person.day,
        month: person.month,
        year: person.year,
        jenderName: person.jenderName,
        photo: person.photo,
        serviceIds: personServicesMap[person.personId] ?? [],
        rohot: person.rohot,
        leader: person.leader,
        services: personServiceNamesMap[person.personId]?.join('، ') ?? '',
        customValues: personCustomValuesMap[person.personId] ?? {},
      );
    }).toList();
  }

  Future<PersonListDTO?> fetchPersonById(int id) async {
    // Direct DB query by exact ID so the dialog can re-read the inserted row
    // immediately after addPerson without waiting for a provider rebuild.
    try {
      final db = ref.read(appDatabaseProvider);

      final query = db.select(db.persons).join([
        drift.leftOuterJoin(
          db.stages,
          db.stages.stageId.equalsExp(db.persons.stageId),
        ),
        drift.leftOuterJoin(
          db.khoroses,
          db.khoroses.khorosId.equalsExp(db.persons.khorosId),
        ),
        drift.leftOuterJoin(
          db.areas,
          db.areas.areaId.equalsExp(db.persons.areaId),
        ),
        drift.leftOuterJoin(
          db.fathers,
          db.fathers.fatherId.equalsExp(db.persons.fatherId),
        ),
      ]);
      query.where(db.persons.personId.equals(id));

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      final person = row.readTable(db.persons);
      final stage = row.readTableOrNull(db.stages);
      final khoros = row.readTableOrNull(db.khoroses);
      final area = row.readTableOrNull(db.areas);
      final father = row.readTableOrNull(db.fathers);

      final serviceIds = await ServiceEligibilityRepository(db)
          .resolvedPersonServiceIds(
            personId: id,
            stageId: person.stageId,
            khorosId: person.khorosId,
          );

      final customRows = await (db.select(
        db.personCustomFieldValues,
      )..where((t) => t.personId.equals(id))).get();
      final customValues = {for (var r in customRows) r.fieldId: r.value ?? ''};

      final serviceRows = await (db.select(db.personServices).join([
        drift.innerJoin(
          db.services,
          db.services.serviceId.equalsExp(db.personServices.serviceId),
        ),
      ])..where(db.personServices.personId.equals(id))).get();
      final serviceNames = serviceRows
          .map((r) => r.readTable(db.services).serviceName ?? '')
          .where((n) => n.isNotEmpty)
          .join('، ');

      return PersonListDTO(
        id: person.personId,
        name: person.personName ?? 'Unknown',
        stageName: stage?.stageName ?? '',
        khorosName: khoros?.khorosName ?? '',
        areaName: area?.areaName ?? '',
        phone: person.phone ?? '',
        mobile: person.mobile ?? '',
        streetName: person.streetName ?? '',
        fatherName: father?.fatherName ?? '',
        stageId: person.stageId,
        khorosId: person.khorosId,
        areaId: person.areaId,
        fatherId: person.fatherId,
        day: person.day,
        month: person.month,
        year: person.year,
        jenderName: person.jenderName,
        photo: person.photo,
        serviceIds: serviceIds.toList(),
        rohot: person.rohot,
        leader: person.leader,
        services: serviceNames,
        customValues: customValues,
      );
    } catch (e) {
      print('FLUTTER DB ERROR [fetchPersonById]: $e');
      return null;
    }
  }

  Future<int> fetchTotalCount({
    String? search,
    List<int>? stageIds,
    List<int>? khorosIds,
    List<int>? areaIds,
    List<int>? fatherIds,
    List<String>? genders,
    List<int>? birthdayDay,
    List<int>? birthdayMonth,
    List<int>? birthdayYear,
    List<String>? rohots,
    List<String>? leaders,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final user = ref.read(authServiceProvider).value;
      final filters = user?.visibilityFilters ?? {};

      final query = db.selectOnly(db.persons);
      query.addColumns([db.persons.personId.count()]);

      if (stageIds != null && stageIds.isNotEmpty) {
        query.where(db.persons.stageId.isIn(stageIds));
      }
      if (khorosIds != null && khorosIds.isNotEmpty) {
        query.where(db.persons.khorosId.isIn(khorosIds));
      }
      if (areaIds != null && areaIds.isNotEmpty) {
        final descendantIds = await db.getMultipleAreasAndDescendantIds(
          areaIds,
        );
        query.where(db.persons.areaId.isIn(descendantIds));
      }
      if (fatherIds != null && fatherIds.isNotEmpty) {
        query.where(db.persons.fatherId.isIn(fatherIds));
      }
      if (genders != null && genders.isNotEmpty) {
        query.where(db.persons.jenderName.isIn(genders));
      }
      if (rohots != null && rohots.isNotEmpty) {
        query.where(db.persons.rohot.isIn(rohots));
      }
      if (leaders != null && leaders.isNotEmpty) {
        query.where(db.persons.leader.isIn(leaders));
      }

      if (birthdayDay != null && birthdayDay.isNotEmpty) {
        query.where(db.persons.day.isIn(birthdayDay));
      }
      if (birthdayMonth != null && birthdayMonth.isNotEmpty) {
        query.where(db.persons.month.isIn(birthdayMonth));
      }
      if (birthdayYear != null && birthdayYear.isNotEmpty) {
        query.where(db.persons.year.isIn(birthdayYear));
      }

      // Admins bypass filters
      if (user != null && user.canPersons) {
        // No filters
      } else if (user != null && user.isAdvanced) {
        await _applyVisibilityFilters(query, db, filters);
      }

      if (search != null && search.isNotEmpty) {
        final s = '%${search.trim()}%';
        query.where(
          db.persons.personName.like(s) |
              db.persons.mobile.like(s) |
              db.persons.phone.like(s) |
              db.persons.streetName.like(s) |
              db.persons.personId.cast<String>().like(s),
        );
      }

      final row = await query.getSingle();
      return row.read(db.persons.personId.count()) ?? 0;
    } catch (e) {
      print('Error in fetchTotalCount: $e');
      return 0;
    }
  }

  Future<void> _applyVisibilityFilters(
    dynamic query,
    AppDatabase db,
    Map<String, List<int>> filters,
  ) async {
    final user = ref.read(authServiceProvider).value;
    // Super-bypass for management accounts:
    if (user != null && user.canPersons) return;

    if (filters.isEmpty) return;

    print('FLUTTER REPO: Applying filters: $filters');

    for (final type in filters.keys) {
      final values = filters[type]!;

      switch (type) {
        case 'stage':
          if (values.isEmpty)
            query.where(
              db.persons.stageId.isNull() & db.persons.stageId.isNotNull(),
            );
          else
            query.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty)
            query.where(
              db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull(),
            );
          else
            query.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            query.where(
              db.persons.areaId.isNull() & db.persons.areaId.isNotNull(),
            );
          } else {
            final allDescendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            query.where(db.persons.areaId.isIn(allDescendants));
          }
          break;
        case 'father':
          if (values.isEmpty)
            query.where(
              db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull(),
            );
          else
            query.where(db.persons.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            query.where(
              db.persons.jenderName.isNull() &
                  db.persons.jenderName.isNotNull(),
            );
          } else {
            final genderStrs = values
                .map((v) => v == 1 ? 'ذكر' : 'أنثى')
                .toList();
            query.where(db.persons.jenderName.isIn(genderStrs));
          }
          break;
        case 'service':
          if (values.isEmpty) {
            query.where(drift.Constant(false));
          } else {
            final subMine = db.selectOnly(db.personServices)
              ..addColumns([db.personServices.personId]);
            subMine.where(db.personServices.serviceId.isIn(values));

            final subAny = db.selectOnly(db.personServices)
              ..addColumns([db.personServices.personId]);

            query.where(
              drift.existsQuery(
                    subMine..where(
                      db.personServices.personId.equalsExp(db.persons.personId),
                    ),
                  ) |
                  drift.notExistsQuery(
                    subAny..where(
                      db.personServices.personId.equalsExp(db.persons.personId),
                    ),
                  ),
            );
          }
          break;
      }
    }
  }

  Future<List<PersonListDTO>> searchPersons(String query) async {
    return fetchPersons(search: query, limit: 100);
  }

  Future<int> nextPersonId() async {
    final db = ref.read(appDatabaseProvider);
    final row = await db
        .customSelect(
          'SELECT COALESCE(MAX("Person_ID"), 0) + 1 AS next_id FROM "Persons"',
        )
        .getSingle();
    return row.read<int>('next_id');
  }

  Future<bool> personIdExists(int id, {int? exceptId}) async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.persons)..where((t) => t.personId.equals(id));
    if (exceptId != null) {
      query.where((t) => t.personId.equals(exceptId).not());
    }
    return await query.getSingleOrNull() != null;
  }

  Future<int?> addPerson({
    int? id,
    required String name,
    int? stageId,
    int? khorosId,
    int? areaId,
    int? fatherId,
    String? streetName,
    String? phone,
    String? mobile,
    int? day,
    int? month,
    int? year,
    String? jenderName,
    Uint8List? photo,
    List<int> serviceIds = const [],
    Map<int, String> customValues = const {},
    String? rohot,
    String? leader,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      int? newId;

      await db.transaction(() async {
        // Use regular Companion constructor instead of .insert for better flexibility
        final companion = PersonsCompanion(
          personId: id != null ? drift.Value(id) : const drift.Value.absent(),
          personName: drift.Value(name),
          stageId: drift.Value(stageId),
          khorosId: drift.Value(khorosId),
          areaId: drift.Value(areaId),
          fatherId: drift.Value(fatherId),
          streetName: drift.Value(streetName),
          phone: drift.Value(phone),
          mobile: drift.Value(mobile),
          day: drift.Value(day),
          month: drift.Value(month),
          year: drift.Value(year),
          jenderName: drift.Value(jenderName),
          photo: drift.Value(photo),
          rohot: drift.Value(rohot),
          leader: drift.Value(leader),
        );

        final personId = await db.into(db.persons).insert(companion);
        newId = personId;

        await ServiceEligibilityRepository(db).replacePersonServiceLinks(
          personId: personId,
          explicitServiceIds: serviceIds,
          stageId: stageId,
          khorosId: khorosId,
        );

        for (final entry in customValues.entries) {
          await db
              .into(db.personCustomFieldValues)
              .insert(
                PersonCustomFieldValuesCompanion.insert(
                  personId: personId,
                  fieldId: entry.key,
                  value: drift.Value(entry.value),
                ),
              );
        }
      });

      // IMPORTANT: Do NOT invalidateSelf here.
      // The caller (PersonDialog) re-reads the inserted row immediately after addPerson,
      // and the screen will refresh normally once the dialog closes.
      return newId;
    } catch (e, stack) {
      print('FLUTTER DB ERROR [addPerson]: $e');
      print(stack);
      return null;
    }
  }

  Future<bool> updatePerson({
    required int id,
    required String name,
    int? stageId,
    int? khorosId,
    int? areaId,
    int? fatherId,
    String? streetName,
    String? phone,
    String? mobile,
    int? day,
    int? month,
    int? year,
    String? jenderName,
    Uint8List? photo,
    List<int> serviceIds = const [],
    Map<int, String> customValues = const {},
    String? rohot,
    String? leader,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await (db.update(
          db.persons,
        )..where((t) => t.personId.equals(id))).write(
          PersonsCompanion(
            personName: drift.Value(name),
            stageId: drift.Value(stageId),
            khorosId: drift.Value(khorosId),
            areaId: drift.Value(areaId),
            fatherId: drift.Value(fatherId),
            streetName: drift.Value(streetName),
            phone: drift.Value(phone),
            mobile: drift.Value(mobile),
            day: drift.Value(day),
            month: drift.Value(month),
            year: drift.Value(year),
            jenderName: drift.Value(jenderName),
            photo: drift.Value(photo),
            rohot: drift.Value(rohot),
            leader: drift.Value(leader),
          ),
        );

        await ServiceEligibilityRepository(db).replacePersonServiceLinks(
          personId: id,
          explicitServiceIds: serviceIds,
          stageId: stageId,
          khorosId: khorosId,
        );

        await (db.delete(
          db.personCustomFieldValues,
        )..where((t) => t.personId.equals(id))).go();
        for (final entry in customValues.entries) {
          await db
              .into(db.personCustomFieldValues)
              .insert(
                PersonCustomFieldValuesCompanion.insert(
                  personId: id,
                  fieldId: entry.key,
                  value: drift.Value(entry.value),
                ),
              );
        }
      });

      // Invalidate after all operations complete so the autocomplete list updates
      ref.invalidateSelf();
      return true;
    } catch (e, stack) {
      print('FLUTTER DB ERROR [updatePerson]: $e');
      print(stack);
      return false;
    }
  }

  Future<bool> bulkTransfer(
    List<int> personIds,
    String fieldType,
    int newValueId,
  ) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final eligibility = ServiceEligibilityRepository(db);

      await db.transaction(() async {
        for (final id in personIds) {
          final oldPerson = await (db.select(
            db.persons,
          )..where((t) => t.personId.equals(id))).getSingleOrNull();
          if (oldPerson == null) continue;

          switch (fieldType) {
            case 'stage':
              await (db.update(db.persons)..where((t) => t.personId.equals(id)))
                  .write(PersonsCompanion(stageId: drift.Value(newValueId)));
              await eligibility.syncResolvedServicesForPerson(id);
              break;

            case 'khoros':
              await (db.update(db.persons)..where((t) => t.personId.equals(id)))
                  .write(PersonsCompanion(khorosId: drift.Value(newValueId)));
              await eligibility.syncResolvedServicesForPerson(id);
              break;

            case 'area':
              await (db.update(db.persons)..where((t) => t.personId.equals(id)))
                  .write(PersonsCompanion(areaId: drift.Value(newValueId)));
              break;
            case 'father':
              await (db.update(db.persons)..where((t) => t.personId.equals(id)))
                  .write(PersonsCompanion(fatherId: drift.Value(newValueId)));
              break;
          }
        }
      });

      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error in bulkTransfer: $e');
      return false;
    }
  }

  Future<bool> deletePerson(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);

      bool success = await db.transaction(() async {
        await (db.delete(db.coming)..where((t) => t.personId.equals(id))).go();
        await (db.delete(db.credit)..where((t) => t.personId.equals(id))).go();
        await (db.delete(
          db.absentPersons,
        )..where((t) => t.personId.equals(id))).go();
        await (db.delete(
          db.absentPrint,
        )..where((t) => t.personId.equals(id))).go();

        final deletedRows = await (db.delete(
          db.persons,
        )..where((t) => t.personId.equals(id))).go();
        return deletedRows > 0;
      });

      if (!success) return false;

      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error deleting person: $e');
      return false;
    }
  }

  Future<Map<int, String>> fetchCustomFieldValues(int personId) async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(
      db.personCustomFieldValues,
    )..where((t) => t.personId.equals(personId))).get();
    return {for (var r in rows) r.fieldId: r.value ?? ''};
  }

  Future<void> updatePersonsRohot(
    Map<int, String?> rohotMap,
    Map<int, String?> leaderMap,
    List<int> stageIds,
  ) async {
    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      if (stageIds.isNotEmpty) {
        // Clear rohot and leader for anyone in these stages who is not in the map
        await (db.update(db.persons)..where(
              (t) =>
                  t.stageId.isIn(stageIds) &
                  t.personId.isNotIn(rohotMap.keys.toList()),
            ))
            .write(
              const PersonsCompanion(
                rohot: drift.Value(null),
                leader: drift.Value(null),
              ),
            );
      }
      for (final entry in rohotMap.entries) {
        final personId = entry.key;
        await (db.update(
          db.persons,
        )..where((t) => t.personId.equals(personId))).write(
          PersonsCompanion(
            rohot: drift.Value(entry.value),
            leader: drift.Value(leaderMap[personId]),
          ),
        );
      }
    });
    ref.invalidateSelf();
  }

  Future<bool> bulkDeletePersons(List<int> ids) async {
    try {
      final db = ref.read(appDatabaseProvider);

      await db.transaction(() async {
        for (final id in ids) {
          await (db.delete(
            db.coming,
          )..where((t) => t.personId.equals(id))).go();
          await (db.delete(
            db.credit,
          )..where((t) => t.personId.equals(id))).go();
          await (db.delete(
            db.absentPersons,
          )..where((t) => t.personId.equals(id))).go();
          await (db.delete(
            db.absentPrint,
          )..where((t) => t.personId.equals(id))).go();
          await (db.delete(
            db.persons,
          )..where((t) => t.personId.equals(id))).go();
        }
      });

      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error in bulkDeletePersons: $e');
      return false;
    }
  }

  Future<bool> bulkUpdatePersons({
    required List<int> ids,
    drift.Value<int?> stageId = const drift.Value.absent(),
    drift.Value<int?> khorosId = const drift.Value.absent(),
    drift.Value<int?> areaId = const drift.Value.absent(),
    drift.Value<int?> fatherId = const drift.Value.absent(),
    drift.Value<String?> streetName = const drift.Value.absent(),
    drift.Value<String?> phone = const drift.Value.absent(),
    drift.Value<String?> mobile = const drift.Value.absent(),
    drift.Value<int?> day = const drift.Value.absent(),
    drift.Value<int?> month = const drift.Value.absent(),
    drift.Value<int?> year = const drift.Value.absent(),
    drift.Value<String?> jenderName = const drift.Value.absent(),
    drift.Value<Uint8List?> photo = const drift.Value.absent(),
    drift.Value<String?> rohot = const drift.Value.absent(),
    drift.Value<String?> leader = const drift.Value.absent(),
    List<int>? serviceIds,
    Map<int, String>? customValues,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        final companion = PersonsCompanion(
          stageId: stageId,
          khorosId: khorosId,
          areaId: areaId,
          fatherId: fatherId,
          streetName: streetName,
          phone: phone,
          mobile: mobile,
          day: day,
          month: month,
          year: year,
          jenderName: jenderName,
          photo: photo,
          rohot: rohot,
          leader: leader,
        );

        for (final id in ids) {
          await (db.update(
            db.persons,
          )..where((t) => t.personId.equals(id))).write(companion);

          if (serviceIds != null) {
            int? currentStageId;
            int? currentKhorosId;
            if (stageId.present) {
              currentStageId = stageId.value;
            } else {
              final p = await (db.select(
                db.persons,
              )..where((t) => t.personId.equals(id))).getSingleOrNull();
              currentStageId = p?.stageId;
            }
            if (khorosId.present) {
              currentKhorosId = khorosId.value;
            } else {
              final p = await (db.select(
                db.persons,
              )..where((t) => t.personId.equals(id))).getSingleOrNull();
              currentKhorosId = p?.khorosId;
            }
            await ServiceEligibilityRepository(db).replacePersonServiceLinks(
              personId: id,
              explicitServiceIds: serviceIds,
              stageId: currentStageId,
              khorosId: currentKhorosId,
            );
          } else {
            if (stageId.present || khorosId.present) {
              await ServiceEligibilityRepository(
                db,
              ).syncResolvedServicesForPerson(id);
            }
          }

          if (customValues != null) {
            for (final entry in customValues.entries) {
              await (db.delete(db.personCustomFieldValues)..where(
                    (t) => t.personId.equals(id) & t.fieldId.equals(entry.key),
                  ))
                  .go();
              await db
                  .into(db.personCustomFieldValues)
                  .insert(
                    PersonCustomFieldValuesCompanion.insert(
                      personId: id,
                      fieldId: entry.key,
                      value: drift.Value(entry.value),
                    ),
                  );
            }
          }
        }
      });

      ref.invalidateSelf();
      return true;
    } catch (e, stack) {
      print('FLUTTER DB ERROR [bulkUpdatePersons]: $e');
      print(stack);
      return false;
    }
  }
}
