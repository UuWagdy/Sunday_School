import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';

final visitationRepositoryProvider = Provider<VisitationRepository>((ref) {
  return VisitationRepository(ref);
});

const List<String> visitationTypes = [
  'تليفون',
  'زيارة منزلية',
  'سوشيال ميديا',
  'واتس',
  'فيس',
];

class VisitationPersonDTO {
  final int? visitId;
  final int personId;
  final String personName;
  final String? visitDate;
  final bool isVisited;
  final String visitType;
  final String notes;
  final int? stageId;
  final String stageName;
  final int? khorosId;
  final String khorosName;
  final int? areaId;
  final String areaName;
  final int? fatherId;
  final String fatherName;
  final String phone;
  final String mobile;
  final String address;
  final String? gender;
  final int? day;
  final int? month;
  final int? year;
  final int? serviceId;
  final String serviceName;
  final String? rohot;
  final String? leader;
  final String services;
  final List<int> serviceIds;
  final Map<int, String> customValues;

  const VisitationPersonDTO({
    this.visitId,
    required this.personId,
    required this.personName,
    this.visitDate,
    required this.isVisited,
    required this.visitType,
    required this.notes,
    this.stageId,
    required this.stageName,
    this.khorosId,
    required this.khorosName,
    this.areaId,
    required this.areaName,
    this.fatherId,
    required this.fatherName,
    required this.phone,
    required this.mobile,
    required this.address,
    this.gender,
    this.day,
    this.month,
    this.year,
    this.serviceId,
    required this.serviceName,
    this.rohot,
    this.leader,
    required this.services,
    required this.serviceIds,
    required this.customValues,
  });
}

class VisitationRepository {
  VisitationRepository(this.ref);

  final Ref ref;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<List<VisitationPersonDTO>> fetchVisitations({
    required DateTime dateFrom,
    required DateTime dateTo,
    List<int>? serviceIds,
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
    bool? visitedStatus,
    String? visitType,
    Map<int, dynamic> customFilters = const {},
    int? limit,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final user = ref.read(authServiceProvider).value;
    final filters = user?.visibilityFilters ?? {};

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
    if (birthdayDay != null && birthdayDay.isNotEmpty) {
      query.where(db.persons.day.isIn(birthdayDay));
    }
    if (birthdayMonth != null && birthdayMonth.isNotEmpty) {
      query.where(db.persons.month.isIn(birthdayMonth));
    }
    if (birthdayYear != null && birthdayYear.isNotEmpty) {
      query.where(db.persons.year.isIn(birthdayYear));
    }
    if (rohots != null && rohots.isNotEmpty) {
      query.where(db.persons.rohot.isIn(rohots));
    }
    if (leaders != null && leaders.isNotEmpty) {
      query.where(db.persons.leader.isIn(leaders));
    }
    if (search != null && search.trim().isNotEmpty) {
      final pattern = '%${search.trim()}%';
      query.where(
        db.persons.personName.like(pattern) |
            db.persons.personId.cast<String>().like(pattern) |
            db.persons.mobile.like(pattern) |
            db.persons.phone.like(pattern) |
            db.persons.streetName.like(pattern),
      );
    }

    if (user != null && user.canPersons) {
      // Management users see all people.
    } else if (user != null && user.isAdvanced) {
      await _applyVisibilityFilters(query, db, filters);
    }

    query.orderBy([
      drift.OrderingTerm(
        expression: db.persons.personName,
        mode: drift.OrderingMode.asc,
      ),
    ]);

    if (limit != null) query.limit(limit);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final personIds = rows
        .map((row) => row.readTable(db.persons).personId)
        .whereType<int>()
        .toList();

    final personServicesMap = <int, List<int>>{};
    final personServiceNamesMap = <int, List<String>>{};
    final serviceNameById = <int, String>{};

    final serviceRows = await (db.select(db.personServices).join([
      drift.innerJoin(
        db.services,
        db.services.serviceId.equalsExp(db.personServices.serviceId),
      ),
    ])..where(db.personServices.personId.isIn(personIds))).get();

    for (final row in serviceRows) {
      final ps = row.readTable(db.personServices);
      final service = row.readTable(db.services);
      personServicesMap.putIfAbsent(ps.personId, () => []).add(ps.serviceId);
      final serviceName = service.serviceName ?? '';
      if (serviceName.isNotEmpty) {
        serviceNameById[service.serviceId] = serviceName;
        personServiceNamesMap
            .putIfAbsent(ps.personId, () => [])
            .add(serviceName);
      }
    }

    final customValuesMap = <int, Map<int, String>>{};
    final customRows = await (db.select(
      db.personCustomFieldValues,
    )..where((t) => t.personId.isIn(personIds))).get();
    for (final row in customRows) {
      customValuesMap.putIfAbsent(row.personId, () => {})[row.fieldId] =
          row.value ?? '';
    }

    final dateFromText = _dateFormat.format(dateFrom);
    final dateToText = _dateFormat.format(dateTo);
    final visitQuery = db.select(db.visitations)
      ..where((t) => t.personId.isIn(personIds))
      ..where((t) => t.visitDate.isBiggerOrEqualValue(dateFromText))
      ..where((t) => t.visitDate.isSmallerOrEqualValue(dateToText))
      ..orderBy([
        (t) => drift.OrderingTerm.desc(t.visitDate),
        (t) => drift.OrderingTerm.desc(t.id),
      ]);
    if (serviceIds != null && serviceIds.isNotEmpty) {
      visitQuery.where((t) => t.serviceId.isIn(serviceIds));
    }

    final visitRows = await visitQuery.get();
    final visitsByPerson = <int, VisitationData>{};
    for (final visit in visitRows) {
      visitsByPerson.putIfAbsent(visit.personId, () => visit);
    }

    final filtered = <VisitationPersonDTO>[];
    final selectedServices = serviceIds?.toSet() ?? const <int>{};

    for (final row in rows) {
      final person = row.readTable(db.persons);
      final personId = person.personId;

      final linkedServiceIds = personServicesMap[personId] ?? const <int>[];
      if (selectedServices.isNotEmpty &&
          !linkedServiceIds.any(selectedServices.contains)) {
        continue;
      }

      final customValues = customValuesMap[personId] ?? const <int, String>{};
      if (!_matchesCustomFilters(customValues, customFilters)) continue;

      final visit = visitsByPerson[personId];
      final isVisited = visit?.isVisited ?? false;
      final type = visit?.visitType ?? visitationTypes.first;

      if (visitedStatus != null && isVisited != visitedStatus) continue;
      if (visitType != null && visitType.isNotEmpty && type != visitType) {
        continue;
      }

      final stage = row.readTableOrNull(db.stages);
      final khoros = row.readTableOrNull(db.khoroses);
      final area = row.readTableOrNull(db.areas);
      final father = row.readTableOrNull(db.fathers);
      final selectedServiceId = selectedServices.length == 1
          ? selectedServices.first
          : visit?.serviceId;

      filtered.add(
        VisitationPersonDTO(
          visitId: visit?.id,
          personId: personId,
          personName: person.personName ?? '',
          visitDate: visit?.visitDate ?? dateFromText,
          isVisited: isVisited,
          visitType: type,
          notes: visit?.notes ?? '',
          stageId: person.stageId,
          stageName: stage?.stageName ?? '',
          khorosId: person.khorosId,
          khorosName: khoros?.khorosName ?? '',
          areaId: person.areaId,
          areaName: area?.areaName ?? '',
          fatherId: person.fatherId,
          fatherName: father?.fatherName ?? '',
          phone: person.phone ?? '',
          mobile: person.mobile ?? '',
          address: person.streetName ?? '',
          gender: person.jenderName,
          day: person.day,
          month: person.month,
          year: person.year,
          serviceId: selectedServiceId,
          serviceName: selectedServiceId == null
              ? ''
              : serviceNameById[selectedServiceId] ?? '',
          rohot: person.rohot,
          leader: person.leader,
          services: personServiceNamesMap[personId]?.join('، ') ?? '',
          serviceIds: linkedServiceIds,
          customValues: customValues,
        ),
      );
    }

    return filtered;
  }

  Future<void> saveVisitation({
    required int personId,
    required DateTime visitDate,
    int? serviceId,
    required bool isVisited,
    required String visitType,
    String? notes,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final visitDateText = _dateFormat.format(visitDate);
    final safeType = visitationTypes.contains(visitType)
        ? visitType
        : visitationTypes.first;

    final existingQuery = db.select(db.visitations)
      ..where((t) => t.personId.equals(personId))
      ..where((t) => t.visitDate.equals(visitDateText));
    if (serviceId == null) {
      existingQuery.where((t) => t.serviceId.isNull());
    } else {
      existingQuery.where((t) => t.serviceId.equals(serviceId));
    }

    final existing = await existingQuery.getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.visitations)
          .insert(
            VisitationsCompanion.insert(
              personId: personId,
              serviceId: drift.Value(serviceId),
              visitDate: visitDateText,
              isVisited: drift.Value(isVisited),
              visitType: drift.Value(safeType),
              notes: drift.Value(notes?.trim()),
            ),
          );
      return;
    }

    await (db.update(
      db.visitations,
    )..where((t) => t.id.equals(existing.id))).write(
      VisitationsCompanion(
        isVisited: drift.Value(isVisited),
        visitType: drift.Value(safeType),
        notes: drift.Value(notes?.trim()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  bool _matchesCustomFilters(
    Map<int, String> values,
    Map<int, dynamic> filters,
  ) {
    for (final entry in filters.entries) {
      final filterValue = entry.value;
      if (filterValue == null) continue;
      final storedValue = values[entry.key] ?? '';

      if (filterValue is String) {
        if (filterValue.isEmpty) continue;
        if (filterValue == 'has_files' || filterValue == 'no_files') {
          continue;
        }
        if (!storedValue.contains(filterValue)) return false;
      } else if (filterValue is List) {
        if (filterValue.isEmpty) continue;
        final parts = storedValue
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet();
        if (!filterValue.any((value) => parts.contains(value.toString()))) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _applyVisibilityFilters(
    dynamic query,
    AppDatabase db,
    Map<String, List<int>> filters,
  ) async {
    if (filters.isEmpty) return;

    for (final entry in filters.entries) {
      final values = entry.value;
      switch (entry.key) {
        case 'stage':
          query.where(
            values.isEmpty
                ? db.persons.stageId.isNull() & db.persons.stageId.isNotNull()
                : db.persons.stageId.isIn(values),
          );
          break;
        case 'khoros':
          query.where(
            values.isEmpty
                ? db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull()
                : db.persons.khorosId.isIn(values),
          );
          break;
        case 'area':
          if (values.isEmpty) {
            query.where(
              db.persons.areaId.isNull() & db.persons.areaId.isNotNull(),
            );
          } else {
            final areaIds = await db.getMultipleAreasAndDescendantIds(values);
            query.where(db.persons.areaId.isIn(areaIds));
          }
          break;
        case 'father':
          query.where(
            values.isEmpty
                ? db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull()
                : db.persons.fatherId.isIn(values),
          );
          break;
      }
    }
  }
}
