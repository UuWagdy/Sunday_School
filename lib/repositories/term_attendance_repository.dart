import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';

final termAttendanceRepositoryProvider = Provider<TermAttendanceRepository>((
  ref,
) {
  return TermAttendanceRepository(ref);
});

class TermAttendanceMeeting {
  final DateTime date;
  final int serviceId;
  final String serviceName;

  const TermAttendanceMeeting({
    required this.date,
    required this.serviceId,
    required this.serviceName,
  });

  String get key => TermAttendanceRepository.attendanceKey(serviceId, date);
}

class TermAttendanceStudent {
  final int personId;
  final String personName;
  final String khorosName;
  final int? khorosId;
  final int? stageId;
  final String stageName;
  final Set<int> serviceIds;
  final Set<String> attendedKeys;
  final int attendedCount;
  final int possibleCount;
  final double grade;
  final double attendanceGrade;
  final double attendancePercentage;
  final int totalDailyPoints;
  final double averageBehavior;
  final Map<String, int> dailyPoints;

  const TermAttendanceStudent({
    required this.personId,
    required this.personName,
    required this.khorosName,
    this.khorosId,
    this.stageId,
    required this.stageName,
    required this.serviceIds,
    required this.attendedKeys,
    required this.attendedCount,
    required this.possibleCount,
    required this.grade,
    required this.attendanceGrade,
    required this.attendancePercentage,
    required this.totalDailyPoints,
    required this.dailyPoints,
    required this.averageBehavior,
  });
}

class TermAttendanceReport {
  final DateTime startDate;
  final DateTime endDate;
  final double maxGrade;
  final double dayMaxGrade;
  final bool addBehavior;
  final List<ServiceData> services;
  final List<TermAttendanceMeeting> meetings;
  final List<TermAttendanceStudent> students;

  const TermAttendanceReport({
    required this.startDate,
    required this.endDate,
    required this.maxGrade,
    required this.dayMaxGrade,
    required this.addBehavior,
    required this.services,
    required this.meetings,
    required this.students,
  });

  int get totalMeetings => meetings.length;
}

class TermAttendanceRepository {
  TermAttendanceRepository(this._ref);

  final Ref _ref;
  static final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  static String attendanceKey(int serviceId, DateTime date) {
    return '$serviceId|${_dateKeyFormat.format(_dateOnly(date))}';
  }

  Future<TermAttendanceReport> buildReport({
    required List<int> serviceIds,
    required DateTime startDate,
    required DateTime endDate,
    required double maxGrade,
    required double dayMaxGrade,
    required bool addBehavior,
  }) async {
    final db = _ref.read(appDatabaseProvider);
    final safeStart = _dateOnly(startDate);
    final safeEnd = _dateOnly(endDate);
    final selectedIds = serviceIds.toSet().toList();

    if (selectedIds.isEmpty || safeEnd.isBefore(safeStart)) {
      return TermAttendanceReport(
        startDate: safeStart,
        endDate: safeEnd,
        maxGrade: maxGrade,
        dayMaxGrade: dayMaxGrade,
        addBehavior: addBehavior,
        services: const [],
        meetings: const [],
        students: const [],
      );
    }

    final services = await (db.select(
      db.services,
    )..where((t) => t.serviceId.isIn(selectedIds))).get();
    final serviceMap = {
      for (final service in services) service.serviceId: service,
    };
    final meetings = _buildMeetings(services, safeStart, safeEnd);

    final personServiceRows = await (db.select(
      db.personServices,
    )..where((t) => t.serviceId.isIn(selectedIds))).get();
    final personServices = <int, Set<int>>{};
    for (final row in personServiceRows) {
      if (serviceMap.containsKey(row.serviceId)) {
        personServices
            .putIfAbsent(row.personId, () => <int>{})
            .add(row.serviceId);
      }
    }

    // Add students who have attendance recorded for selected services in the period
    final from = _dateKeyFormat.format(safeStart);
    final to = _dateKeyFormat.format(safeEnd);
    final comingRows =
        await (db.select(db.coming)..where(
              (t) =>
                  t.serviceId.isIn(selectedIds) &
                  t.dateWeek.isBiggerOrEqualValue(from) &
                  t.dateWeek.isSmallerOrEqualValue(to),
            ))
            .get();
    for (final row in comingRows) {
      final personId = row.personId;
      final serviceId = row.serviceId;
      if (personId != null &&
          serviceId != null &&
          serviceMap.containsKey(serviceId)) {
        personServices.putIfAbsent(personId, () => <int>{}).add(serviceId);
      }
    }

    if (personServices.isEmpty || meetings.isEmpty) {
      return TermAttendanceReport(
        startDate: safeStart,
        endDate: safeEnd,
        maxGrade: maxGrade,
        dayMaxGrade: dayMaxGrade,
        addBehavior: addBehavior,
        services: services,
        meetings: meetings,
        students: const [],
      );
    }

    final visiblePersonIds = await _visiblePersonIds(
      db,
      personServices.keys.toList(),
    );
    final attendanceDetailsByPerson = await _attendanceDetailsByPerson(
      db,
      visiblePersonIds,
      selectedIds,
      safeStart,
      safeEnd,
    );
    final behaviorAveragesByPerson = await _behaviorAveragesByPerson(
      db,
      visiblePersonIds,
      selectedIds,
      safeStart,
      safeEnd,
    );

    final khoroses = await db.select(db.khoroses).get();
    final khorosMap = {for (final k in khoroses) k.khorosId: k.khorosName};

    final stages = await db.select(db.stages).get();
    final stageMap = {for (final s in stages) s.stageId: s.stageName};

    final persons = await (db.select(
      db.persons,
    )..where((t) => t.personId.isIn(visiblePersonIds))).get();
    persons.sort((a, b) => (a.personName ?? '').compareTo(b.personName ?? ''));

    final students = <TermAttendanceStudent>[];
    for (final person in persons) {
      final studentServiceIds =
          personServices[person.personId] ?? const <int>{};
      final possibleMeetings = meetings
          .where((meeting) => studentServiceIds.contains(meeting.serviceId))
          .toList();
      final possibleKeys = possibleMeetings
          .map((meeting) => meeting.key)
          .toSet();

      final studentDetails =
          attendanceDetailsByPerson[person.personId] ??
          const <String, ComingData>{};
      final attendedKeys = studentDetails.keys.toSet().intersection(
        possibleKeys,
      );

      final possibleCount = possibleKeys.length;
      final attendedCount = attendedKeys.length;

      final dailyPoints = <String, int>{};
      double weightedAttendance = 0.0;

      for (final meetingKey in possibleKeys) {
        final comingRow = studentDetails[meetingKey];
        if (comingRow != null) {
          final pt = comingRow.point ?? 0;
          dailyPoints[meetingKey] = pt;

          double dailyRatio = dayMaxGrade <= 0 ? 0.0 : (pt / dayMaxGrade);
          if (dailyRatio > 1.0) dailyRatio = 1.0;
          if (dailyRatio < 0.0) dailyRatio = 0.0;

          weightedAttendance += dailyRatio;
        }
      }

      final attendancePercentage = possibleCount == 0
          ? 0.0
          : (weightedAttendance / possibleCount) * 100;

      final attendanceGrade = possibleCount == 0
          ? 0.0
          : (weightedAttendance / possibleCount) * maxGrade;

      final sumDailyPoints = dailyPoints.values.fold<int>(
        0,
        (sum, v) => sum + v,
      );

      final averageBehavior = behaviorAveragesByPerson[person.personId] ?? 0.0;

      final finalGrade = addBehavior
          ? (attendanceGrade + averageBehavior)
          : attendanceGrade;

      students.add(
        TermAttendanceStudent(
          personId: person.personId,
          personName: person.personName ?? '',
          khorosName: khorosMap[person.khorosId] ?? '',
          khorosId: person.khorosId,
          stageId: person.stageId,
          stageName: stageMap[person.stageId] ?? '',
          serviceIds: studentServiceIds,
          attendedKeys: attendedKeys,
          attendedCount: attendedCount,
          possibleCount: possibleCount,
          grade: finalGrade,
          attendanceGrade: attendanceGrade,
          attendancePercentage: attendancePercentage,
          totalDailyPoints: sumDailyPoints,
          averageBehavior: averageBehavior,
          dailyPoints: dailyPoints,
        ),
      );
    }

    students.sort((a, b) => b.grade.compareTo(a.grade));

    return TermAttendanceReport(
      startDate: safeStart,
      endDate: safeEnd,
      maxGrade: maxGrade,
      dayMaxGrade: dayMaxGrade,
      addBehavior: addBehavior,
      services: services,
      meetings: meetings,
      students: students,
    );
  }

  Future<List<int>> _visiblePersonIds(
    AppDatabase db,
    List<int> personIds,
  ) async {
    if (personIds.isEmpty) return [];

    final auth = _ref.read(authServiceProvider).value;
    var query = db.select(db.persons)..where((t) => t.personId.isIn(personIds));

    if (auth != null &&
        auth.isAdvanced &&
        !(auth.canPersons || auth.canAbsence)) {
      final filters = auth.visibilityFilters;

      final stageIds = filters['stage'];
      if (stageIds != null) {
        if (stageIds.isEmpty) return [];
        query.where((t) => t.stageId.isIn(stageIds));
      }

      final khorosIds = filters['khoros'];
      if (khorosIds != null) {
        if (khorosIds.isEmpty) return [];
        query.where((t) => t.khorosId.isIn(khorosIds));
      }

      final fatherIds = filters['father'];
      if (fatherIds != null) {
        if (fatherIds.isEmpty) return [];
        query.where((t) => t.fatherId.isIn(fatherIds));
      }

      final genderIds = filters['gender'];
      if (genderIds != null) {
        if (genderIds.isEmpty) return [];
        final genders = genderIds.expand((id) {
          if (id == 1) return const ['ذكر', 'ذكر'];
          return const ['أنثى', 'أنثى'];
        }).toList();
        query.where((t) => t.jenderName.isIn(genders));
      }

      final areaIds = filters['area'];
      if (areaIds != null) {
        if (areaIds.isEmpty) return [];
        final descendantIds = await db.getMultipleAreasAndDescendantIds(
          areaIds,
        );
        query.where((t) => t.areaId.isIn(descendantIds));
      }

      final serviceIds = filters['service'];
      if (serviceIds != null) {
        if (serviceIds.isEmpty) return [];
        final rows = await (db.select(
          db.personServices,
        )..where((t) => t.serviceId.isIn(serviceIds))).get();
        final allowed = rows.map((row) => row.personId).toSet();
        query.where((t) => t.personId.isIn(allowed.toList()));
      }
    }

    final persons = await query.get();
    return persons.map((person) => person.personId).toList();
  }

  Future<Map<int, Map<String, ComingData>>> _attendanceDetailsByPerson(
    AppDatabase db,
    List<int> personIds,
    List<int> serviceIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (personIds.isEmpty || serviceIds.isEmpty) return {};

    final from = _dateKeyFormat.format(startDate);
    final to = _dateKeyFormat.format(endDate);
    final rows =
        await (db.select(db.coming)..where(
              (t) =>
                  t.personId.isIn(personIds) &
                  t.serviceId.isIn(serviceIds) &
                  t.dateWeek.isBiggerOrEqualValue(from) &
                  t.dateWeek.isSmallerOrEqualValue(to),
            ))
            .get();

    final result = <int, Map<String, ComingData>>{};
    for (final row in rows) {
      final personId = row.personId;
      final serviceId = row.serviceId;
      final date = _parseDate(row.dateWeek);
      if (personId == null || serviceId == null || date == null) continue;
      if (row.attendTime == null && (row.point ?? 0) == 0) continue;

      final personMap = result.putIfAbsent(
        personId,
        () => <String, ComingData>{},
      );
      personMap[attendanceKey(serviceId, date)] = row;
    }
    return result;
  }

  Future<Map<int, double>> _behaviorAveragesByPerson(
    AppDatabase db,
    List<int> personIds,
    List<int> serviceIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (personIds.isEmpty || serviceIds.isEmpty) return {};

    final from = _dateKeyFormat.format(startDate);
    final to = _dateKeyFormat.format(endDate);
    final rows =
        await (db.select(db.coming)..where(
              (t) =>
                  t.personId.isIn(personIds) &
                  t.serviceId.isIn(serviceIds) &
                  t.dateWeek.isBiggerOrEqualValue(from) &
                  t.dateWeek.isSmallerOrEqualValue(to),
            ))
            .get();

    final totals = <int, double>{};
    final counts = <int, int>{};
    for (final row in rows) {
      final personId = row.personId;
      if (personId == null) continue;

      totals[personId] = (totals[personId] ?? 0.0) + (row.behavior ?? 5);
      counts[personId] = (counts[personId] ?? 0) + 1;
    }

    return {
      for (final entry in totals.entries)
        entry.key: entry.value / counts[entry.key]!,
    };
  }

  List<TermAttendanceMeeting> _buildMeetings(
    List<ServiceData> services,
    DateTime startDate,
    DateTime endDate,
  ) {
    final meetings = <TermAttendanceMeeting>[];
    for (final service in services) {
      final weekday = service.dayOfWeek;
      if (weekday == null ||
          weekday < DateTime.monday ||
          weekday > DateTime.sunday) {
        continue;
      }

      var date = startDate.add(
        Duration(days: (weekday - startDate.weekday) % 7),
      );
      while (!date.isAfter(endDate)) {
        meetings.add(
          TermAttendanceMeeting(
            date: date,
            serviceId: service.serviceId,
            serviceName: service.serviceName ?? '',
          ),
        );
        date = date.add(const Duration(days: 7));
      }
    }

    meetings.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.serviceName.compareTo(b.serviceName);
    });
    return meetings;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return _dateOnly(parsed);

    final parts = value
        .split(RegExp(r'[/|-]'))
        .map((part) => int.tryParse(part))
        .toList();
    if (parts.length < 3 || parts.any((part) => part == null)) return null;
    final first = parts[0]!;
    final second = parts[1]!;
    final third = parts[2]!;
    if (first > 31) return DateTime(first, second, third);
    if (third > 31) return DateTime(third, second, first);
    return null;
  }
}
