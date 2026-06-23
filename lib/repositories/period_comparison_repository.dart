import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'period_comparison_repository.g.dart';

/// Represents a single date-range period for comparison
class ComparePeriod {
  final DateTime from;
  final DateTime to;
  final String label;

  ComparePeriod({required this.from, required this.to, required this.label});

  String get fromStr => DateFormat('yyyy-MM-dd').format(from);
  String get toStr => DateFormat('yyyy-MM-dd').format(to);
}

/// Result for one person across all periods
class PersonComparisonResult {
  final int personId;
  final String personName;
  final List<PeriodAttendanceResult> periodResults;

  PersonComparisonResult({
    required this.personId,
    required this.personName,
    required this.periodResults,
  });
}

/// Attendance stats for one person in one period
class PeriodAttendanceResult {
  final String periodLabel;
  final int totalPossibleAttendances; // personCount * meetingDays
  final int attendedCount;
  final double attendancePercent;

  // Change vs previous period
  final double? attendanceChange; // positive = improvement
  final String? attendanceDirection; // 'increase', 'decrease', 'same'

  PeriodAttendanceResult({
    required this.periodLabel,
    required this.totalPossibleAttendances,
    required this.attendedCount,
    required this.attendancePercent,
    this.attendanceChange,
    this.attendanceDirection,
  });
}

@riverpod
class PeriodComparisonRepository extends _$PeriodComparisonRepository {
  @override
  FutureOr<void> build() async {}

  /// Fetch all persons, optionally filtered
  Future<List<Person>> fetchPersons({
    int? stageId,
    int? areaId,
    String? gender,
    String? search,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.persons);

    if (stageId != null) query.where((t) => t.stageId.equals(stageId));
    if (areaId != null) {
      final descendantIds = await db.getAreaAndDescendantIds(areaId);
      query.where((t) => t.areaId.isIn(descendantIds));
    }
    if (gender != null) query.where((t) => t.jenderName.equals(gender));
    if (search != null && search.isNotEmpty) {
      query.where((t) =>
          t.personName.like('%$search%') |
          t.personId.cast<String>().like('%$search%'));
    }

    return query.get();
  }

  /// Main comparison method
  Future<List<PersonComparisonResult>> compareAttendance({
    required List<ComparePeriod> periods,
    required List<int> personIds,
    bool isAggregate = false,
  }) async {
    if (periods.length < 2 || personIds.isEmpty) return [];

    final db = ref.read(appDatabaseProvider);
    final results = <PersonComparisonResult>[];

    // 1. Get total meeting days per period (distinct dateWeek values)
    final totalMeetingDaysPerPeriod = <int, int>{};
    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      final countQuery = db.selectOnly(db.coming, distinct: true)
        ..addColumns([db.coming.dateWeek])
        ..where(db.coming.dateWeek.isBiggerOrEqualValue(period.fromStr))
        ..where(db.coming.dateWeek.isSmallerOrEqualValue(period.toStr));
      final rows = await countQuery.get();
      totalMeetingDaysPerPeriod[i] = rows.length;
    }

    if (isAggregate) {
      // ══════════════ AGGREGATE MODE ══════════════
      final periodResults = <PeriodAttendanceResult>[];
      final personCount = personIds.length;

      for (int i = 0; i < periods.length; i++) {
        final period = periods[i];
        final meetingDays = totalMeetingDaysPerPeriod[i] ?? 0;
        final totalPossible = meetingDays * personCount;

        // Count total attendances for ALL selected persons in this period
        final attendedQuery = db.selectOnly(db.coming)
          ..addColumns([db.coming.id.count()])
          ..where(db.coming.personId.isIn(personIds))
          ..where(db.coming.dateWeek.isBiggerOrEqualValue(period.fromStr))
          ..where(db.coming.dateWeek.isSmallerOrEqualValue(period.toStr));
        
        final attendedResult = await attendedQuery.getSingle();
        final attended = attendedResult.read(db.coming.id.count()) ?? 0;

        final attendPct = totalPossible > 0 ? (attended / totalPossible * 100) : 0.0;

        double? attChange;
        String? attDir;

        if (i > 0) {
          final prev = periodResults[i - 1];
          attChange = attendPct - prev.attendancePercent;
          attDir = attChange > 0.01 ? 'increase' : (attChange < -0.01 ? 'decrease' : 'same');
        }

        periodResults.add(PeriodAttendanceResult(
          periodLabel: period.label,
          totalPossibleAttendances: totalPossible,
          attendedCount: attended,
          attendancePercent: attendPct,
          attendanceChange: attChange,
          attendanceDirection: attDir,
        ));
      }

      results.add(PersonComparisonResult(
        personId: 0,
        personName: "إجمالي الحضور لجميع المختارين (${personIds.length} شخص)",
        periodResults: periodResults,
      ));
      return results;
    }

    // ══════════════ INDIVIDUAL MODE ══════════════
    // 2. Get person names
    final personQuery = db.select(db.persons)
      ..where((t) => t.personId.isIn(personIds));
    final personsList = await personQuery.get();

    // 3. For each person, count attendance in each period
    for (final person in personsList) {
      final periodResults = <PeriodAttendanceResult>[];

      for (int i = 0; i < periods.length; i++) {
        final period = periods[i];
        final meetingDays = totalMeetingDaysPerPeriod[i] ?? 0;

        // Count attended days for this specific person in this period
        final attendedQuery = db.selectOnly(db.coming)
          ..addColumns([db.coming.id.count()])
          ..where(db.coming.personId.equals(person.personId))
          ..where(db.coming.dateWeek.isBiggerOrEqualValue(period.fromStr))
          ..where(db.coming.dateWeek.isSmallerOrEqualValue(period.toStr));
        
        final attendedResult = await attendedQuery.getSingle();
        final attended = attendedResult.read(db.coming.id.count()) ?? 0;

        final attendPct = meetingDays > 0 ? (attended / meetingDays * 100) : 0.0;

        double? attChange;
        String? attDir;

        if (i > 0) {
          final prev = periodResults[i - 1];
          attChange = attendPct - prev.attendancePercent;
          attDir = attChange > 0.01 ? 'increase' : (attChange < -0.01 ? 'decrease' : 'same');
        }

        periodResults.add(PeriodAttendanceResult(
          periodLabel: period.label,
          totalPossibleAttendances: meetingDays,
          attendedCount: attended,
          attendancePercent: attendPct,
          attendanceChange: attChange,
          attendanceDirection: attDir,
        ));
      }

      results.add(PersonComparisonResult(
        personId: person.personId,
        personName: person.personName ?? 'مجهول',
        periodResults: periodResults,
      ));
    }

    return results;
  }
}
