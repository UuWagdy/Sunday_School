import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import 'persons_repository.dart';
import 'service_eligibility_repository.dart';

part 'attendance_repository.g.dart';

class AttendanceDTO {
  final int? id;
  final int personId;
  final String personName;
  final String? dateWeek;
  final int? point;
  final int? month;
  final int? year;
  final String? stageName;
  final String? khorosName;
  final String? areaName;
  final String? fatherName;

  final String? phone;
  final String? mobile;
  final String? address;
  final int? serviceId;
  final String? serviceName;
  final String? attendTime;
  final String? checkoutTime;
  final int? visited;
  final String? visitType;
  final String? visitNotes;
  final String? gender;
  final int? behavior;
  final String? rohot;
  final String? leader;
  final String? services;
  final Map<int, String> customValues;

  AttendanceDTO({
    this.id,
    required this.personId,
    required this.personName,
    this.dateWeek,
    this.point,
    this.month,
    this.year,
    this.stageName,
    this.khorosName,
    this.areaName,
    this.fatherName,
    this.phone,
    this.mobile,
    this.address,
    this.serviceId,
    this.serviceName,
    this.attendTime,
    this.checkoutTime,
    this.visited,
    this.visitType,
    this.visitNotes,
    this.gender,
    this.behavior,
    this.rohot,
    this.leader,
    this.services,
    this.customValues = const {},
  });
}

@Riverpod(keepAlive: true)
class AttendanceRepository extends _$AttendanceRepository {
  @override
  FutureOr<List<AttendanceDTO>> build() async {
    ref.watch(appDatabaseProvider);
    ref.watch(personsRepositoryProvider);
    final auth = ref.watch(authServiceProvider);
    if (auth.isLoading) return [];

    return fetchAttendance(status: 'all');
  }

  Future<List<AttendanceDTO>> fetchAttendance({
    List<int>? month,
    List<int>? year,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<int>? stageIds,
    List<int>? khorosIds,
    List<int>? areaIds,
    List<int>? fatherIds,
    List<String>? genders,
    List<int>? birthdayDay,
    List<int>? birthdayMonth,
    List<int>? birthdayYear,
    int? serviceId,
    List<int>? serviceIds,
    int? visitedStatus,
    String? notesFilter,
    String? lateAfterTime,
    String? status,
    int? limit,
    int? offset,
    Map<int, dynamic> customFilters = const {},
    String? callId,
    bool deduplicatePeople = true,
    void Function(bool hasMore)? onHasMore,
  }) async {
    final cid = callId ?? 'INTERNAL';

    try {
      final db = ref.read(appDatabaseProvider);
      final user = ref.read(authServiceProvider).value;
      final filters = user?.visibilityFilters ?? {};

      var joinCondition = db.coming.personId.equalsExp(db.persons.personId);
      if (month != null && month.isNotEmpty)
        joinCondition = joinCondition & db.coming.mont1.isIn(month);
      if (year != null && year.isNotEmpty)
        joinCondition = joinCondition & db.coming.year1.isIn(year);
      if (dateFrom != null)
        joinCondition =
            joinCondition &
            db.coming.dateWeek.isBiggerOrEqualValue(
              DateFormat('yyyy-MM-dd').format(dateFrom),
            );
      if (dateTo != null)
        joinCondition =
            joinCondition &
            db.coming.dateWeek.isSmallerOrEqualValue(
              DateFormat('yyyy-MM-dd').format(dateTo),
            );
      if (serviceId != null) {
        joinCondition = joinCondition & db.coming.serviceId.equals(serviceId);
      } else if (serviceIds != null && serviceIds.isNotEmpty) {
        joinCondition = joinCondition & db.coming.serviceId.isIn(serviceIds);
      }

      final personQuery = db.select(db.persons).join([
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
        drift.leftOuterJoin(db.coming, joinCondition),
        drift.leftOuterJoin(
          db.services,
          db.services.serviceId.equalsExp(db.coming.serviceId),
        ),
      ]);

      if (stageIds != null && stageIds.isNotEmpty)
        personQuery.where(db.persons.stageId.isIn(stageIds));
      if (khorosIds != null && khorosIds.isNotEmpty)
        personQuery.where(db.persons.khorosId.isIn(khorosIds));
      if (areaIds != null && areaIds.isNotEmpty) {
        final descendantIds = await db.getMultipleAreasAndDescendantIds(
          areaIds,
        );
        personQuery.where(db.persons.areaId.isIn(descendantIds));
      }
      if (fatherIds != null && fatherIds.isNotEmpty)
        personQuery.where(db.persons.fatherId.isIn(fatherIds));
      if (genders != null && genders.isNotEmpty)
        personQuery.where(db.persons.jenderName.isIn(genders));

      if (birthdayDay != null && birthdayDay.isNotEmpty)
        personQuery.where(db.persons.day.isIn(birthdayDay));
      if (birthdayMonth != null && birthdayMonth.isNotEmpty)
        personQuery.where(db.persons.month.isIn(birthdayMonth));
      if (birthdayYear != null && birthdayYear.isNotEmpty)
        personQuery.where(db.persons.year.isIn(birthdayYear));

      if (search != null && search.trim().isNotEmpty) {
        final pattern = '%${search.trim()}%';
        personQuery.where(
          db.persons.personName.like(pattern) |
              db.persons.personId.cast<String>().like(pattern),
        );
      }

      if (status == 'absent') {
        personQuery.where(
          db.coming.id.isNull() | db.coming.attendTime.isNull(),
        );
      } else if (status == 'present') {
        personQuery.where(
          db.coming.id.isNotNull() & db.coming.attendTime.isNotNull(),
        );
      } else if (status == 'checked_out') {
        personQuery.where(
          db.coming.id.isNotNull() &
              db.coming.attendTime.isNotNull() &
              db.coming.checkoutTime.isNotNull(),
        );
      } else if (status == 'complete') {
        personQuery.where(
          db.coming.id.isNotNull() &
              db.coming.attendTime.isNotNull() &
              db.coming.checkoutTime.isNotNull(),
        );
      }

      if (visitedStatus != null) {
        personQuery.where(
          db.coming.visited.equals(visitedStatus) | db.coming.id.isNull(),
        );
      }
      if (notesFilter == 'with') {
        personQuery.where(
          db.coming.visitNotes.isNotNull() & db.coming.visitNotes.like('_%'),
        );
      } else if (notesFilter == 'without') {
        personQuery.where(
          db.coming.visitNotes.isNull() |
              db.coming.visitNotes.equals('') |
              db.coming.id.isNull(),
        );
      }
      if (lateAfterTime != null) {
        personQuery.where(
          db.coming.attendTime.isBiggerThanValue(lateAfterTime) |
              db.coming.id.isNull(),
        );
      }

      if (user != null && user.isAdvanced) {
        await _applyVisibilityFilters(personQuery, db, filters, user);
      }

      personQuery.orderBy([
        drift.OrderingTerm(
          expression: db.persons.personId,
          mode: drift.OrderingMode.desc,
        ),
        drift.OrderingTerm(
          expression: db.coming.dateWeek,
          mode: drift.OrderingMode.desc,
        ),
      ]);

      if (limit != null) personQuery.limit(limit, offset: offset ?? 0);

      final rows = await personQuery.get();

      if (onHasMore != null) {
        onHasMore(limit != null && rows.length == limit);
      }

      final personIds = rows
          .map((r) => r.readTable(db.persons).personId)
          .toSet()
          .toList();
      final Map<int, Map<int, String>> personCustomValues = {};
      final Map<int, List<String>> personServicesNames = {};

      if (personIds.isNotEmpty) {
        final customRows = await (db.select(
          db.personCustomFieldValues,
        )..where((t) => t.personId.isIn(personIds))).get();
        for (final r in customRows) {
          personCustomValues.putIfAbsent(r.personId, () => {})[r.fieldId] =
              r.value ?? '';
        }

        final serviceRows = await (db.select(db.personServices).join([
          drift.innerJoin(
            db.services,
            db.services.serviceId.equalsExp(db.personServices.serviceId),
          ),
        ])..where(db.personServices.personId.isIn(personIds))).get();
        for (final r in serviceRows) {
          final pId = r.readTable(db.personServices).personId;
          final sName = r.readTable(db.services).serviceName ?? '';
          if (sName.isNotEmpty) {
            personServicesNames.putIfAbsent(pId, () => []).add(sName);
          }
        }
      }

      final List<AttendanceDTO> resultList = [];
      if (deduplicatePeople) {
        final Map<int, AttendanceDTO> uniqueResults = {};
        for (final row in rows) {
          final person = row.readTable(db.persons);
          final coming = row.readTableOrNull(db.coming);
          if (!uniqueResults.containsKey(person.personId) || coming != null) {
            uniqueResults[person.personId] = AttendanceDTO(
              id: coming?.id,
              personId: person.personId,
              personName: person.personName ?? 'غير معروف',
              dateWeek: coming?.dateWeek,
              point: coming?.point,
              month: coming?.mont1,
              year: coming?.year1,
              stageName: row.readTableOrNull(db.stages)?.stageName,
              khorosName: row.readTableOrNull(db.khoroses)?.khorosName,
              areaName: row.readTableOrNull(db.areas)?.areaName,
              fatherName: row.readTableOrNull(db.fathers)?.fatherName,
              phone: person.phone,
              mobile: person.mobile,
              address: person.streetName,
              serviceId: coming?.serviceId,
              serviceName: row.readTableOrNull(db.services)?.serviceName,
              attendTime: coming?.attendTime,
              checkoutTime: coming?.checkoutTime,
              visited: coming?.visited,
              visitNotes: coming?.visitNotes,
              gender: person.jenderName,
              behavior: coming?.behavior,
              rohot: person.rohot,
              leader: person.leader,
              services: personServicesNames[person.personId]?.join('، ') ?? '',
              customValues: personCustomValues[person.personId] ?? {},
            );
          }
        }
        resultList.addAll(uniqueResults.values);
      } else {
        final Set<String> seenKeys = {};
        for (final row in rows) {
          final person = row.readTable(db.persons);
          final coming = row.readTableOrNull(db.coming);
          final key = coming != null
              ? 'coming_${coming.id}'
              : 'person_${person.personId}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            resultList.add(
              AttendanceDTO(
                id: coming?.id,
                personId: person.personId,
                personName: person.personName ?? 'غير معروف',
                dateWeek: coming?.dateWeek,
                point: coming?.point,
                month: coming?.mont1,
                year: coming?.year1,
                stageName: row.readTableOrNull(db.stages)?.stageName,
                khorosName: row.readTableOrNull(db.khoroses)?.khorosName,
                areaName: row.readTableOrNull(db.areas)?.areaName,
                fatherName: row.readTableOrNull(db.fathers)?.fatherName,
                phone: person.phone,
                mobile: person.mobile,
                address: person.streetName,
                serviceId: coming?.serviceId,
                serviceName: row.readTableOrNull(db.services)?.serviceName,
                attendTime: coming?.attendTime,
                checkoutTime: coming?.checkoutTime,
                visited: coming?.visited,
                visitNotes: coming?.visitNotes,
                gender: person.jenderName,
                behavior: coming?.behavior,
                rohot: person.rohot,
                leader: person.leader,
                services:
                    personServicesNames[person.personId]?.join('، ') ?? '',
                customValues: personCustomValues[person.personId] ?? {},
              ),
            );
          }
        }
      }
      return resultList;
    } catch (e, st) {
      print('REPO ERROR in [$cid][fetchAttendance]: $e\n$st');
      return [];
    }
  }

  Future<void> _applyVisibilityFilters(
    drift.JoinedSelectStatement query,
    AppDatabase db,
    Map<String, List<int>> filters,
    dynamic user,
  ) async {
    if (user != null && (user.canPersons || user.canAbsence)) return;

    for (final type in filters.keys) {
      final values = filters[type]!;
      if (values.isEmpty) continue;
      switch (type) {
        case 'stage':
          query.where(db.persons.stageId.isIn(values));
          break;
        case 'gender':
          query.where(
            db.persons.jenderName.isIn(
              values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList(),
            ),
          );
          break;
        case 'area':
          final descendants = await db.getMultipleAreasAndDescendantIds(values);
          query.where(db.persons.areaId.isIn(descendants));
          break;
        case 'service':
          final subMine = db.selectOnly(db.personServices)
            ..addColumns([db.personServices.personId])
            ..where(db.personServices.serviceId.isIn(values));
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
          break;
      }
    }
  }

  Future<Map<String, int>> fetchAttendanceSummary({
    List<int>? month,
    List<int>? year,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<int>? stageIds,
    List<int>? khorosIds,
    List<int>? areaIds,
    List<int>? fatherIds,
    List<String>? genders,
    List<int>? birthdayDay,
    List<int>? birthdayMonth,
    List<int>? birthdayYear,
    int? serviceId,
    List<int>? serviceIds,
    int? visitedStatus,
    String? notesFilter,
    String? lateAfterTime,
    String? status,
    Map<int, dynamic> customFilters = const {},
    String? callId,
  }) async {
    final cid = callId ?? 'INTERNAL';
    final db = ref.read(appDatabaseProvider);
    final user = ref.read(authServiceProvider).value;
    final filters = user?.visibilityFilters ?? {};

    try {
      final totalQuery = db.selectOnly(db.persons)
        ..addColumns([db.persons.personId.count()]);
      if (stageIds != null && stageIds.isNotEmpty)
        totalQuery.where(db.persons.stageId.isIn(stageIds));
      if (khorosIds != null && khorosIds.isNotEmpty)
        totalQuery.where(db.persons.khorosId.isIn(khorosIds));
      if (areaIds != null && areaIds.isNotEmpty)
        totalQuery.where(
          db.persons.areaId.isIn(
            await db.getMultipleAreasAndDescendantIds(areaIds),
          ),
        );
      if (fatherIds != null && fatherIds.isNotEmpty)
        totalQuery.where(db.persons.fatherId.isIn(fatherIds));
      if (genders != null && genders.isNotEmpty)
        totalQuery.where(db.persons.jenderName.isIn(genders));

      if (birthdayDay != null && birthdayDay.isNotEmpty)
        totalQuery.where(db.persons.day.isIn(birthdayDay));
      if (birthdayMonth != null && birthdayMonth.isNotEmpty)
        totalQuery.where(db.persons.month.isIn(birthdayMonth));
      if (birthdayYear != null && birthdayYear.isNotEmpty)
        totalQuery.where(db.persons.year.isIn(birthdayYear));

      if (search != null && search.isNotEmpty)
        totalQuery.where(
          db.persons.personName.like('%$search%') |
              db.persons.personId.cast<String>().like('%$search%'),
        );

      if (user != null && user.isAdvanced)
        await _applyVisibilityFilters(totalQuery, db, filters, user);
      final totalRow = await totalQuery.getSingle();
      final total = totalRow.read(db.persons.personId.count()) ?? 0;

      final presentQuery = db.selectOnly(db.coming).join([
        drift.innerJoin(
          db.persons,
          db.persons.personId.equalsExp(db.coming.personId),
        ),
      ]);
      presentQuery.addColumns([db.coming.personId.count(distinct: true)]);
      presentQuery.where(db.coming.attendTime.isNotNull());

      if (month != null && month.isNotEmpty)
        presentQuery.where(db.coming.mont1.isIn(month));
      if (year != null && year.isNotEmpty)
        presentQuery.where(db.coming.year1.isIn(year));
      if (serviceId != null) {
        presentQuery.where(db.coming.serviceId.equals(serviceId));
      } else if (serviceIds != null && serviceIds.isNotEmpty) {
        presentQuery.where(db.coming.serviceId.isIn(serviceIds));
      }
      if (dateFrom != null)
        presentQuery.where(
          db.coming.dateWeek.isBiggerOrEqualValue(
            DateFormat('yyyy-MM-dd').format(dateFrom),
          ),
        );
      if (dateTo != null)
        presentQuery.where(
          db.coming.dateWeek.isSmallerOrEqualValue(
            DateFormat('yyyy-MM-dd').format(dateTo),
          ),
        );

      if (stageIds != null && stageIds.isNotEmpty)
        presentQuery.where(db.persons.stageId.isIn(stageIds));
      if (khorosIds != null && khorosIds.isNotEmpty)
        presentQuery.where(db.persons.khorosId.isIn(khorosIds));
      if (areaIds != null && areaIds.isNotEmpty)
        presentQuery.where(
          db.persons.areaId.isIn(
            await db.getMultipleAreasAndDescendantIds(areaIds),
          ),
        );
      if (fatherIds != null && fatherIds.isNotEmpty)
        presentQuery.where(db.persons.fatherId.isIn(fatherIds));
      if (genders != null && genders.isNotEmpty)
        presentQuery.where(db.persons.jenderName.isIn(genders));

      if (visitedStatus != null)
        presentQuery.where(db.coming.visited.equals(visitedStatus));
      if (notesFilter == 'with')
        presentQuery.where(
          db.coming.visitNotes.isNotNull() & db.coming.visitNotes.like('_%'),
        );
      else if (notesFilter == 'without')
        presentQuery.where(
          db.coming.visitNotes.isNull() | db.coming.visitNotes.equals(''),
        );
      if (lateAfterTime != null)
        presentQuery.where(
          db.coming.attendTime.isBiggerThanValue(lateAfterTime),
        );

      if (user != null && user.isAdvanced)
        await _applyVisibilityFilters(presentQuery, db, filters, user);
      final presentRow = await presentQuery.getSingle();
      final present =
          presentRow.read(db.coming.personId.count(distinct: true)) ?? 0;

      return {'total': total, 'present': present, 'absent': total - present};
    } catch (e, st) {
      print('REPO ERROR in [$cid][fetchAttendanceSummary]: $e\n$st');
      return {'total': 0, 'present': 0, 'absent': 0};
    }
  }

  Future<String?> addAttendance({
    required int personId,
    required String dateWeek,
    int? point,
    required int month,
    required int year,
    int? serviceId,
    String? attendTime,
    bool isCheckout = false,
    int? behavior,
    String? personName,
    String? serviceName,
  }) async {
    final db = ref.read(appDatabaseProvider);
    try {
      final eligibilityRepository = ServiceEligibilityRepository(db);
      if (serviceId != null &&
          !await eligibilityRepository.isPersonEligibleForService(
            personId: personId,
            serviceId: serviceId,
          )) {
        return eligibilityRepository.serviceEligibilityErrorFor(
          personId: personId,
          serviceId: serviceId,
          personName: personName,
          serviceName: serviceName,
        );
      }

      final matchingQuery = db.select(db.coming)
        ..where(
          (t) =>
              t.personId.equals(personId) &
              t.dateWeek.equals(dateWeek) &
              (serviceId != null
                  ? t.serviceId.equals(serviceId)
                  : t.serviceId.isNull()),
        )
        ..orderBy([(t) => drift.OrderingTerm.desc(t.id)])
        ..limit(1);
      final exists = await matchingQuery.getSingleOrNull();

      if (isCheckout) {
        final pendingQuery = db.select(db.coming)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.dateWeek.equals(dateWeek) &
                t.attendTime.isNotNull() &
                t.checkoutTime.isNull() &
                (serviceId != null
                    ? t.serviceId.equals(serviceId)
                    : t.serviceId.isNull()),
          )
          ..orderBy([(t) => drift.OrderingTerm.desc(t.id)])
          ..limit(1);
        final pending = await pendingQuery.getSingleOrNull();

        if (pending == null) {
          if (exists?.checkoutTime != null)
            return 'تم تسجيل انصراف هذا الشخص مسبقاً';
          return 'لا يمكن تسجيل انصراف بدون تسجيل حضور أولاً';
        }
        await (db.update(
          db.coming,
        )..where((t) => t.id.equals(pending.id!))).write(
          ComingCompanion(
            point: drift.Value((pending.point ?? 0) + (point ?? 0)),
            checkoutTime: drift.Value(
              attendTime ?? DateFormat('HH:mm').format(DateTime.now()),
            ),
            behavior: behavior != null
                ? drift.Value(behavior)
                : const drift.Value.absent(),
          ),
        );
      } else {
        if (exists != null) {
          if (exists.attendTime != null) {
            return 'مسجل مسبقاً اليوم في هذه الخدمة';
          } else {
            // Update existing behavior-only record with attendance details
            await (db.update(
              db.coming,
            )..where((t) => t.id.equals(exists.id!))).write(
              ComingCompanion(
                point: drift.Value(point ?? 0),
                attendTime: drift.Value(
                  attendTime ?? DateFormat('HH:mm').format(DateTime.now()),
                ),
              ),
            );
            return null;
          }
        }

        final maxIdRow = await db
            .customSelect(
              'SELECT COALESCE(MAX(COALESCE("Id", rowid)), 0) AS max_id FROM "Coming"',
            )
            .getSingle();
        final newId = maxIdRow.read<int>('max_id') + 1;

        await db
            .into(db.coming)
            .insert(
              ComingCompanion(
                id: drift.Value(newId),
                personId: drift.Value(personId),
                dateWeek: drift.Value(dateWeek),
                point: drift.Value(point ?? 0),
                mont1: drift.Value(month),
                year1: drift.Value(year),
                serviceId: drift.Value(serviceId),
                attendTime: drift.Value(attendTime),
                visited: const drift.Value(0),
                behavior: drift.Value(behavior ?? 5),
              ),
            );
      }
      return null;
    } catch (e, st) {
      print('DB Error in addAttendance: $e\n$st');
      return 'خطأ في قاعدة البيانات: $e';
    }
  }

  Future<int> checkoutAll({
    required String dateWeek,
    required String checkoutTime,
    required int points,
    int? serviceId,
  }) async {
    final db = ref.read(appDatabaseProvider);

    return db.transaction(() async {
      final query = db.select(db.coming)
        ..where(
          (t) =>
              t.dateWeek.equals(dateWeek) &
              t.attendTime.isNotNull() &
              t.checkoutTime.isNull() &
              (serviceId != null
                  ? t.serviceId.equals(serviceId)
                  : t.serviceId.isNull()),
        );
      final records = await query.get();
      var updatedCount = 0;

      for (final record in records) {
        final id = record.id;
        if (id == null) continue;
        updatedCount +=
            await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
              ComingCompanion(
                point: drift.Value((record.point ?? 0) + points),
                checkoutTime: drift.Value(checkoutTime),
              ),
            );
      }

      return updatedCount;
    });
  }

  Future<int> updateAttendancePointsForIds({
    required Iterable<int> ids,
    required int points,
    bool isCheckoutMode = false,
    int defaultAttendancePoints = 2,
  }) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return 0;

    final db = ref.read(appDatabaseProvider);
    return db.transaction(() async {
      final records = await (db.select(
        db.coming,
      )..where((t) => t.id.isIn(idList))).get();
      var updatedCount = 0;

      for (final record in records) {
        final id = record.id;
        if (id == null) continue;

        final totalPoints = record.point ?? 0;
        final hasCheckout =
            record.checkoutTime != null && record.checkoutTime!.isNotEmpty;
        final attendancePoints = hasCheckout
            ? (totalPoints <= defaultAttendancePoints
                  ? totalPoints
                  : defaultAttendancePoints)
            : totalPoints;
        final checkoutPoints = hasCheckout ? totalPoints - attendancePoints : 0;
        final normalizedCheckoutPoints = checkoutPoints < 0
            ? 0
            : checkoutPoints;
        final newTotalPoints = isCheckoutMode
            ? attendancePoints + points
            : points + normalizedCheckoutPoints;

        updatedCount +=
            await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
              ComingCompanion(point: drift.Value(newTotalPoints)),
            );
      }

      return updatedCount;
    });
  }

  Future<int> clearCheckoutForIds(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return 0;

    final db = ref.read(appDatabaseProvider);
    return (db.update(db.coming)..where((t) => t.id.isIn(idList))).write(
      const ComingCompanion(checkoutTime: drift.Value(null)),
    );
  }

  Future<int> deleteAttendanceForIds(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return 0;

    final db = ref.read(appDatabaseProvider);
    return (db.delete(db.coming)..where((t) => t.id.isIn(idList))).go();
  }

  Future<bool> updateAttendance({
    required int id,
    int? point,
    String? dateWeek,
    int? behavior,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
      ComingCompanion(
        point: point != null ? drift.Value(point) : const drift.Value.absent(),
        dateWeek: dateWeek != null
            ? drift.Value(dateWeek)
            : const drift.Value.absent(),
        behavior: behavior != null
            ? drift.Value(behavior)
            : const drift.Value.absent(),
      ),
    );
    return true;
  }

  Future<bool> updateVisitation({
    required int id,
    int? visited,
    String? visitNotes,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
      ComingCompanion(
        visited: drift.Value(visited),
        visitNotes: drift.Value(visitNotes),
      ),
    );
    return true;
  }

  Future<bool> deleteAttendance(int id) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.coming)..where((t) => t.id.equals(id))).go();
    return true;
  }

  Future<bool> saveBehaviorScores({
    required Map<int, int> scores,
    required String dateWeek,
    required int month,
    required int year,
    List<int>? serviceIds,
    int? serviceId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    try {
      final List<int?> targetServiceIds = serviceIds?.isNotEmpty == true
          ? serviceIds!.cast<int?>()
          : <int?>[serviceId];
      await db.transaction(() async {
        for (final targetServiceId in targetServiceIds) {
          for (final entry in scores.entries) {
            final personId = entry.key;
            final score = entry.value;

            final exists =
                await (db.select(db.coming)
                      ..where(
                        (t) =>
                            t.personId.equals(personId) &
                            t.dateWeek.equals(dateWeek) &
                            (targetServiceId != null
                                ? t.serviceId.equals(targetServiceId)
                                : t.serviceId.isNull()),
                      )
                      ..limit(1))
                    .getSingleOrNull();

            if (exists != null) {
              await (db.update(db.coming)
                    ..where((t) => t.id.equals(exists.id!)))
                  .write(ComingCompanion(behavior: drift.Value(score)));
            } else {
              final maxIdRow = await db
                  .customSelect(
                    'SELECT COALESCE(MAX(COALESCE("Id", rowid)), 0) AS max_id FROM "Coming"',
                  )
                  .getSingle();
              final newId = maxIdRow.read<int>('max_id') + 1;

              await db
                  .into(db.coming)
                  .insert(
                    ComingCompanion(
                      id: drift.Value(newId),
                      personId: drift.Value(personId),
                      dateWeek: drift.Value(dateWeek),
                      point: const drift.Value(0),
                      mont1: drift.Value(month),
                      year1: drift.Value(year),
                      serviceId: drift.Value(targetServiceId),
                      visited: const drift.Value(0),
                      behavior: drift.Value(score),
                    ),
                  );
            }
          }
        }
      });
      return true;
    } catch (e) {
      print('DB Error in saveBehaviorScores: $e');
      return false;
    }
  }

  Future<Map<int, int>> fetchBehaviorScores({
    required String dateWeek,
    required List<int> serviceIds,
  }) async {
    if (serviceIds.isEmpty) return {};

    final db = ref.read(appDatabaseProvider);
    final rows =
        await (db.select(db.coming)..where(
              (t) => t.dateWeek.equals(dateWeek) & t.serviceId.isIn(serviceIds),
            ))
            .get();

    final totals = <int, int>{};
    final counts = <int, int>{};
    for (final row in rows) {
      final personId = row.personId;
      if (personId == null) continue;

      totals[personId] = (totals[personId] ?? 0) + (row.behavior ?? 5);
      counts[personId] = (counts[personId] ?? 0) + 1;
    }

    return {
      for (final entry in totals.entries)
        entry.key: (entry.value / counts[entry.key]!).round().clamp(0, 7),
    };
  }
}
