import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import 'service_eligibility_repository.dart';
import '../utils/arabic_helper.dart';

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
  final List<AttendanceServiceRecord> serviceRecords;
  final String? checkColor;
  final String? attendanceNotes;
  final String? checkoutNotes;
  final String? checkoutType;

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
    this.serviceRecords = const [],
    this.checkColor,
    this.attendanceNotes,
    this.checkoutNotes,
    this.checkoutType,
  });
}

class AttendanceServiceRecord {
  final int id;
  final int? serviceId;
  final String? serviceName;
  final String? dateWeek;
  final String? attendTime;
  final String? checkoutTime;
  final int point;
  final int? attendancePoint;
  final int? checkoutPoint;
  final String? checkColor;
  final String? attendanceNotes;
  final String? checkoutNotes;
  final String? checkoutType;

  const AttendanceServiceRecord({
    required this.id,
    this.serviceId,
    this.serviceName,
    this.dateWeek,
    this.attendTime,
    this.checkoutTime,
    required this.point,
    this.attendancePoint,
    this.checkoutPoint,
    this.checkColor,
    this.attendanceNotes,
    this.checkoutNotes,
    this.checkoutType,
  });
}

@Riverpod(keepAlive: true)
class AttendanceRepository extends _$AttendanceRepository {
  @override
  FutureOr<List<AttendanceDTO>> build() async {
    ref.watch(appDatabaseProvider);
    ref.watch(authServiceProvider);
    // Screens request their own filtered pages. Initializing this notifier must
    // not also download the entire attendance history in the background.
    return const [];
  }

  Future<List<AttendanceDTO>> fetchAttendance({
    List<int>? changedPersonIds,
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
    String? sortBy,
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

      final personQuery = db.selectOnly(db.persons)
        ..addColumns(db.persons.$columns.where((c) => c != db.persons.photo))
        ..join([
          drift.leftOuterJoin(
            db.stages,
            db.stages.stageId.equalsExp(db.persons.stageId),
            useColumns: true,
          ),
          drift.leftOuterJoin(
            db.khoroses,
            db.khoroses.khorosId.equalsExp(db.persons.khorosId),
            useColumns: false,
          ),
          drift.leftOuterJoin(
            db.areas,
            db.areas.areaId.equalsExp(db.persons.areaId),
            useColumns: true,
          ),
          drift.leftOuterJoin(
            db.fathers,
            db.fathers.fatherId.equalsExp(db.persons.fatherId),
            useColumns: true,
          ),
          drift.leftOuterJoin(db.coming, joinCondition, useColumns: true),
          drift.leftOuterJoin(
            db.services,
            db.services.serviceId.equalsExp(db.coming.serviceId),
            useColumns: false,
          ),
        ])
        ..addColumns([
          db.khoroses.khorosName,
          db.services.serviceName,
          db.services.checkColor,
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
      if (changedPersonIds != null) {
        personQuery.where(db.persons.personId.isIn(changedPersonIds));
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
        final queryNormalized = normalizeArabic(search);
        final pattern = '%$queryNormalized%';
        final normalizedName = normalizeArabicSql(db.persons.personName);
        personQuery.where(
          normalizedName.like(pattern) |
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

      if (sortBy == 'name') {
        personQuery.orderBy([
          drift.OrderingTerm(
            expression: db.persons.personName,
            mode: drift.OrderingMode.asc,
          ),
          drift.OrderingTerm.asc(db.persons.personId),
          drift.OrderingTerm(
            expression: db.coming.dateWeek,
            mode: drift.OrderingMode.desc,
          ),
        ]);
      } else {
        personQuery.orderBy([
          drift.OrderingTerm(
            expression: db.persons.personId,
            mode: drift.OrderingMode.asc,
          ),
          drift.OrderingTerm(
            expression: db.coming.dateWeek,
            mode: drift.OrderingMode.desc,
          ),
        ]);
      }

      if (limit != null) personQuery.limit(limit, offset: offset ?? 0);

      final rows = await personQuery.get();

      if (onHasMore != null) {
        onHasMore(limit != null && rows.length == limit);
      }

      final personIds = rows
          .map((r) => r.read(db.persons.personId)!)
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

        final serviceRows =
            await (db.select(db.personServices).join([
                    drift.innerJoin(
                      db.services,
                      db.services.serviceId.equalsExp(
                        db.personServices.serviceId,
                      ),
                      useColumns: false,
                    ),
                  ])
                  ..addColumns([db.services.serviceName])
                  ..where(db.personServices.personId.isIn(personIds)))
                .get();
        for (final r in serviceRows) {
          final pId = r.readTable(db.personServices).personId;
          final sName = r.read(db.services.serviceName) ?? '';
          if (sName.isNotEmpty) {
            personServicesNames.putIfAbsent(pId, () => []).add(sName);
          }
        }
      }

      final List<AttendanceDTO> resultList = [];
      if (deduplicatePeople) {
        final Map<int, AttendanceDTO> uniqueResults = {};
        for (final row in rows) {
          final person = db.persons.map(
            row.rawData.data,
            tablePrefix: db.persons.aliasedName,
          );
          final coming = row.readTableOrNull(db.coming);
          if (!uniqueResults.containsKey(person.personId)) {
            uniqueResults[person.personId] = AttendanceDTO(
              id: coming?.id,
              personId: person.personId,
              personName: person.personName ?? 'غير معروف',
              dateWeek: coming?.dateWeek,
              point: coming?.point,
              month: coming?.mont1,
              year: coming?.year1,
              stageName: row.readTableOrNull(db.stages)?.stageName,
              khorosName: row.read(db.khoroses.khorosName),
              areaName: row.readTableOrNull(db.areas)?.areaName,
              fatherName: row.readTableOrNull(db.fathers)?.fatherName,
              phone: person.phone,
              mobile: person.mobile,
              address: person.streetName,
              serviceId: coming?.serviceId,
              serviceName: row.read(db.services.serviceName),
              attendTime: coming?.attendTime,
              checkoutTime: coming?.checkoutTime,
              visited: coming?.visited,
              visitNotes: coming?.visitNotes,
              attendanceNotes: coming?.attendanceNotes,
              checkoutNotes: coming?.checkoutNotes,
              checkoutType: coming?.checkoutType,
              gender: person.jenderName,
              behavior: coming?.behavior,
              rohot: person.rohot,
              leader: person.leader,
              services: personServicesNames[person.personId]?.join('، ') ?? '',
              customValues: personCustomValues[person.personId] ?? {},
              serviceRecords: <AttendanceServiceRecord>[],
              checkColor: row.read(db.services.checkColor),
            );
          }
          if (coming != null) {
            final comingId = coming.id;
            if (comingId == null) continue;
            final records = uniqueResults[person.personId]!.serviceRecords;
            if (!records.any((record) => record.id == comingId)) {
              records.add(
                AttendanceServiceRecord(
                  id: comingId,
                  serviceId: coming.serviceId,
                  serviceName: row.read(db.services.serviceName),
                  dateWeek: coming.dateWeek,
                  attendTime: coming.attendTime,
                  checkoutTime: coming.checkoutTime,
                  point: coming.point ?? 0,
                  attendancePoint: coming.attendancePoint,
                  checkoutPoint: coming.checkoutPoint,
                  checkColor: row.read(db.services.checkColor),
                  attendanceNotes: coming.attendanceNotes,
                  checkoutNotes: coming.checkoutNotes,
                  checkoutType: coming.checkoutType,
                ),
              );
            }
          }
        }
        resultList.addAll(uniqueResults.values);
      } else {
        final Set<String> seenKeys = {};
        for (final row in rows) {
          final person = db.persons.map(
            row.rawData.data,
            tablePrefix: db.persons.aliasedName,
          );
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
                khorosName: row.read(db.khoroses.khorosName),
                areaName: row.readTableOrNull(db.areas)?.areaName,
                fatherName: row.readTableOrNull(db.fathers)?.fatherName,
                phone: person.phone,
                mobile: person.mobile,
                address: person.streetName,
                serviceId: coming?.serviceId,
                serviceName: row.read(db.services.serviceName),
                attendTime: coming?.attendTime,
                checkoutTime: coming?.checkoutTime,
                visited: coming?.visited,
                visitNotes: coming?.visitNotes,
                attendanceNotes: coming?.attendanceNotes,
                checkoutNotes: coming?.checkoutNotes,
                checkoutType: coming?.checkoutType,
                gender: person.jenderName,
                behavior: coming?.behavior,
                rohot: person.rohot,
                leader: person.leader,
                services:
                    personServicesNames[person.personId]?.join('، ') ?? '',
                customValues: personCustomValues[person.personId] ?? {},
                checkColor: row.read(db.services.checkColor),
              ),
            );
          }
        }
      }
      return resultList;
    } catch (e, st) {
      print('REPO ERROR in [$cid][fetchAttendance]: $e\n$st');
      rethrow;
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

      if (search != null && search.isNotEmpty) {
        final queryNormalized = normalizeArabic(search);
        final pattern = '%$queryNormalized%';
        final normalizedName = normalizeArabicSql(db.persons.personName);
        totalQuery.where(
          normalizedName.like(pattern) |
              db.persons.personId.cast<String>().like(pattern),
        );
      }

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
      rethrow;
    }
  }

  Future<drift.Value<int?>> _newAttendanceId(AppDatabase db) async {
    // Server mode uses PostgreSQL SERIAL, which reserves distinct IDs across
    // devices. Legacy local Coming tables still need an explicit nullable Id.
    if (!db.visibilityContext.applyLocally) return const drift.Value.absent();
    final row = await db
        .customSelect(
          'SELECT COALESCE(MAX(COALESCE("Id", rowid)), 0) AS max_id FROM "Coming"',
        )
        .getSingle();
    return drift.Value(row.read<int>('max_id') + 1);
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
    String? attendanceNotes,
    String? checkoutNotes,
    String? checkoutType,
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
            point: drift.Value(
              (pending.attendancePoint ?? pending.point ?? 0) + (point ?? 0),
            ),
            attendancePoint: drift.Value(
              pending.attendancePoint ?? pending.point ?? 0,
            ),
            checkoutPoint: drift.Value(point ?? 0),
            checkoutTime: drift.Value(
              attendTime ?? DateFormat('HH:mm').format(DateTime.now()),
            ),
            behavior: behavior != null
                ? drift.Value(behavior)
                : const drift.Value.absent(),
            checkoutType: checkoutType != null
                ? drift.Value(checkoutType)
                : const drift.Value.absent(),
            checkoutNotes: checkoutNotes != null
                ? drift.Value(checkoutNotes)
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
                attendancePoint: drift.Value(point ?? 0),
                checkoutPoint: const drift.Value(0),
                attendTime: drift.Value(
                  attendTime ?? DateFormat('HH:mm').format(DateTime.now()),
                ),
                attendanceNotes: attendanceNotes != null
                    ? drift.Value(attendanceNotes)
                    : const drift.Value.absent(),
              ),
            );
            return null;
          }
        }

        final newId = await _newAttendanceId(db);

        await db
            .into(db.coming)
            .insert(
              ComingCompanion(
                id: newId,
                personId: drift.Value(personId),
                dateWeek: drift.Value(dateWeek),
                point: drift.Value(point ?? 0),
                attendancePoint: drift.Value(point ?? 0),
                checkoutPoint: const drift.Value(0),
                mont1: drift.Value(month),
                year1: drift.Value(year),
                serviceId: drift.Value(serviceId),
                attendTime: drift.Value(attendTime),
                visited: const drift.Value(0),
                behavior: drift.Value(behavior ?? 5),
                attendanceNotes: attendanceNotes != null
                    ? drift.Value(attendanceNotes)
                    : const drift.Value.absent(),
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
                point: drift.Value(
                  (record.attendancePoint ?? record.point ?? 0) + points,
                ),
                attendancePoint: drift.Value(
                  record.attendancePoint ?? record.point ?? 0,
                ),
                checkoutPoint: drift.Value(points),
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
        final legacyAttendancePoints = hasCheckout
            ? (totalPoints <= defaultAttendancePoints
                  ? totalPoints
                  : defaultAttendancePoints)
            : totalPoints;
        final attendancePoints =
            record.attendancePoint ?? legacyAttendancePoints;
        final checkoutPoints =
            record.checkoutPoint ??
            (hasCheckout ? totalPoints - legacyAttendancePoints : 0);
        final normalizedCheckoutPoints = checkoutPoints < 0
            ? 0
            : checkoutPoints;
        final newTotalPoints = isCheckoutMode
            ? attendancePoints + points
            : points + normalizedCheckoutPoints;

        updatedCount +=
            await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
              ComingCompanion(
                point: drift.Value(newTotalPoints),
                attendancePoint: drift.Value(
                  isCheckoutMode ? attendancePoints : points,
                ),
                checkoutPoint: drift.Value(
                  isCheckoutMode ? points : normalizedCheckoutPoints,
                ),
              ),
            );
      }

      return updatedCount;
    });
  }

  Future<int> clearCheckoutForIds(Iterable<int> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return 0;

    final db = ref.read(appDatabaseProvider);
    final records = await (db.select(
      db.coming,
    )..where((t) => t.id.isIn(idList))).get();
    var updatedCount = 0;
    for (final record in records) {
      final id = record.id;
      if (id == null) continue;
      final attendancePoints = record.attendancePoint ?? record.point ?? 0;
      updatedCount +=
          await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
            ComingCompanion(
              point: drift.Value(attendancePoints),
              attendancePoint: drift.Value(attendancePoints),
              checkoutPoint: const drift.Value(0),
              checkoutTime: const drift.Value(null),
            ),
          );
    }
    return updatedCount;
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
    int? attendancePoint,
    int? checkoutPoint,
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
        attendancePoint: attendancePoint != null
            ? drift.Value(attendancePoint)
            : const drift.Value.absent(),
        checkoutPoint: checkoutPoint != null
            ? drift.Value(checkoutPoint)
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

  Future<bool> updateAttendanceNotes({
    required int id,
    String? attendanceNotes,
    String? checkoutNotes,
    String? checkoutType,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.coming)..where((t) => t.id.equals(id))).write(
      ComingCompanion(
        attendanceNotes: drift.Value(attendanceNotes),
        checkoutNotes: drift.Value(checkoutNotes),
        checkoutType: checkoutType != null
            ? drift.Value(checkoutType)
            : const drift.Value.absent(),
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
              final newId = await _newAttendanceId(db);

              await db
                  .into(db.coming)
                  .insert(
                    ComingCompanion(
                      id: newId,
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
