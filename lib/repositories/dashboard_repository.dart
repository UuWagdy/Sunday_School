import 'package:flutter/foundation.dart' show compute;
import '../database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database_provider.dart';
import '../sync/data_change_domains.dart';
import '../sync/data_change_coordinator.dart';

part 'dashboard_repository.g.dart';

class AttendanceTrendData {
  final DateTime date;
  final int count;
  AttendanceTrendData(this.date, this.count);
}

class DemographicStatData {
  final String label;
  final int count;
  final double? percentage;
  DemographicStatData(this.label, this.count, {this.percentage});
}

typedef _TrendInput = ({
  List<ComingData> rows,
  String groupBy,
  int? year,
  int? month,
  String? status,
});

Future<Map<String, int>> _trendCounts(
  List<ComingData> rows,
  String groupBy,
  int? year,
  int? month,
  String? status,
) {
  final input = (
    rows: rows,
    groupBy: groupBy,
    year: year,
    month: month,
    status: status,
  );
  return rows.length >= 2000
      ? compute(_countTrendRows, input)
      : Future.value(_countTrendRows(input));
}

Map<String, int> _countTrendRows(_TrendInput input) {
  final counts = <String, int>{};
  for (final row in input.rows) {
    final raw = row.dateWeek;
    if (raw == null || raw.isEmpty) continue;
    try {
      var date = DateTime.tryParse(raw);
      if (date == null) {
        final parts = raw.split(RegExp(r'[/|-]'));
        if (parts.length >= 3) {
          final first = int.tryParse(parts[0]) ?? 0;
          final middle = int.tryParse(parts[1]) ?? 0;
          final last = int.tryParse(parts[2]) ?? 0;
          if (first > 31)
            date = DateTime(first, middle, last);
          else if (last > 31)
            date = DateTime(last, middle, first);
        }
      }
      if (date == null ||
          (input.year != null && date.year != input.year) ||
          (input.month != null && date.month != input.month))
        continue;
      if (input.status == 'checked_out' && row.checkoutTime == null) continue;
      if (input.status == 'complete' &&
          (row.checkoutTime == null || row.attendTime == null))
        continue;
      final key = switch (input.groupBy) {
        'day' =>
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'month' => '${date.year}-${date.month.toString().padLeft(2, '0')}',
        'year' => '${date.year}',
        _ => '',
      };
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    } catch (_) {
      // Imported legacy rows with an unreadable date cannot form a chart point.
    }
  }
  return counts;
}

@Riverpod(keepAlive: true)
Future<List<AttendanceTrendData>> generalAttendanceTrend(
  Ref ref, {
  required String groupBy,
  int? filterYear,
  int? filterMonth,
  int? serviceId,
  String? status,
}) async {
  bool isMounted = true;
  ref.onDispose(() {
    isMounted = false;
  });

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.attendance));
  ref.watch(domainRevisionProvider(DataDomain.people));

  if (auth.isLoading && !auth.hasValue) return [];

  final user = auth.value;

  final query = db.selectOnly(db.coming)
    ..addColumns([
      db.coming.personId,
      db.coming.dateWeek,
      db.coming.attendTime,
      db.coming.checkoutTime,
    ])
    ..join([
      drift.innerJoin(
        db.persons,
        db.persons.personId.equalsExp(db.coming.personId),
        useColumns: false,
      ),
    ]);

  if (serviceId != null) {
    query.where(db.coming.serviceId.equals(serviceId));
  }

  // Apply visibility filters
  if (user != null && user.isAdvanced) {
    if (user.visibilityFilters.isNotEmpty) {
      for (final type in user.visibilityFilters.keys) {
        final values = user.visibilityFilters[type]!;
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
              final descendants = await db.getMultipleAreasAndDescendantIds(
                values,
              );
              if (!isMounted) return [];
              query.where(db.persons.areaId.isIn(descendants));
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
              final genders = values
                  .map((v) => v == 1 ? 'ذكر' : 'أنثى')
                  .toList();
              query.where(db.persons.jenderName.isIn(genders));
            }
            break;
        }
      }
    }
  }

  final rows = await query.get();
  if (!isMounted) return [];

  // Map rows to coming records
  final comingList = rows
      .map(
        (r) =>
            db.coming.map(r.rawData.data, tablePrefix: db.coming.aliasedName),
      )
      .toList();

  final counts = await _trendCounts(
    comingList,
    groupBy,
    filterYear,
    filterMonth,
    status,
  );
  if (!isMounted) return [];

  List<AttendanceTrendData> result = [];

  if (groupBy == 'day' && filterYear != null && filterMonth != null) {
    int daysInMonth = 31;
    try {
      daysInMonth = DateTime(filterYear, filterMonth + 1, 0).day;
    } catch (_) {}
    for (int i = 1; i <= daysInMonth; i++) {
      String key =
          "$filterYear-${filterMonth.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      result.add(
        AttendanceTrendData(
          DateTime(filterYear, filterMonth, i),
          counts[key] ?? 0,
        ),
      );
    }
  } else if (groupBy == 'month' && filterYear != null) {
    for (int i = 1; i <= 12; i++) {
      String key = "$filterYear-${i.toString().padLeft(2, '0')}";
      result.add(
        AttendanceTrendData(DateTime(filterYear, i, 1), counts[key] ?? 0),
      );
    }
  } else if (groupBy == 'year') {
    int minYear = filterYear ?? DateTime.now().year - 4;
    int maxYear = filterYear ?? DateTime.now().year;
    for (String k in counts.keys) {
      try {
        int y = int.parse(k);
        if (y < minYear) minYear = y;
        if (y > maxYear) maxYear = y;
      } catch (_) {}
    }
    for (int i = minYear; i <= maxYear; i++) {
      result.add(AttendanceTrendData(DateTime(i, 1, 1), counts["$i"] ?? 0));
    }
  } else {
    counts.forEach((key, val) {
      List<String> p = key.split('-');
      int y = int.parse(p[0]);
      int m = p.length > 1 ? int.parse(p[1]) : 1;
      int d = p.length > 2 ? int.parse(p[2]) : 1;
      result.add(AttendanceTrendData(DateTime(y, m, d), val));
    });
  }

  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

@Riverpod(keepAlive: true)
Future<List<AttendanceTrendData>> individualAttendanceTrend(
  Ref ref, {
  required int personId,
  required String groupBy,
  int? filterYear,
  int? filterMonth,
  int? serviceId,
  String? status,
}) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.attendance));
  ref.watch(domainRevisionProvider(DataDomain.people));

  if (auth.isLoading && !auth.hasValue) return [];

  final user = auth.value;

  final query = db.selectOnly(db.coming)
    ..addColumns([
      db.coming.personId,
      db.coming.dateWeek,
      db.coming.attendTime,
      db.coming.checkoutTime,
    ])
    ..where(db.coming.personId.equals(personId));
  if (serviceId != null) {
    query.where(db.coming.serviceId.equals(serviceId));
  }

  final rows = (await query.get())
      .map(
        (row) =>
            db.coming.map(row.rawData.data, tablePrefix: db.coming.aliasedName),
      )
      .toList();
  if (!isMounted) return [];

  final counts = await _trendCounts(
    rows,
    groupBy,
    filterYear,
    filterMonth,
    status,
  );
  if (!isMounted) return [];

  // Strict visibility check for the personId itself
  if (user != null && user.isAdvanced) {
    final personQuery = db.selectOnly(db.persons)
      ..addColumns([db.persons.personId])
      ..where(db.persons.personId.equals(personId));
    final filters = user.visibilityFilters;
    if (filters.isNotEmpty) {
      for (final type in filters.keys) {
        final values = filters[type] ?? [];
        switch (type) {
          case 'stage':
            if (values.isEmpty)
              personQuery.where(
                db.persons.stageId.isNull() & db.persons.stageId.isNotNull(),
              );
            else
              personQuery.where(db.persons.stageId.isIn(values));
            break;
          case 'khoros':
            if (values.isEmpty)
              personQuery.where(
                db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull(),
              );
            else
              personQuery.where(db.persons.khorosId.isIn(values));
            break;
          case 'area':
            if (values.isEmpty) {
              personQuery.where(
                db.persons.areaId.isNull() & db.persons.areaId.isNotNull(),
              );
            } else {
              final descendants = await db.getMultipleAreasAndDescendantIds(
                values,
              );
              if (!isMounted) return [];
              personQuery.where(db.persons.areaId.isIn(descendants));
            }
            break;
          case 'father':
            if (values.isEmpty)
              personQuery.where(
                db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull(),
              );
            else
              personQuery.where(db.persons.fatherId.isIn(values));
            break;
          case 'gender':
            if (values.isEmpty) {
              personQuery.where(
                db.persons.jenderName.isNull() &
                    db.persons.jenderName.isNotNull(),
              );
            } else {
              final genders = values
                  .map((v) => v == 1 ? 'ذكر' : 'أنثى')
                  .toList();
              personQuery.where(db.persons.jenderName.isIn(genders));
            }
            break;
        }
      }
    }
    final allowed = await personQuery.get();
    if (!isMounted) return [];
    if (allowed.isEmpty) return []; // Not authorized to see this person
  }

  List<AttendanceTrendData> result = [];

  if (groupBy == 'day' && filterYear != null && filterMonth != null) {
    int daysInMonth = 31;
    try {
      daysInMonth = DateTime(filterYear, filterMonth + 1, 0).day;
    } catch (_) {}
    for (int i = 1; i <= daysInMonth; i++) {
      String key =
          "$filterYear-${filterMonth.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      result.add(
        AttendanceTrendData(
          DateTime(filterYear, filterMonth, i),
          counts[key] ?? 0,
        ),
      );
    }
  } else if (groupBy == 'month' && filterYear != null) {
    for (int i = 1; i <= 12; i++) {
      String key = "$filterYear-${i.toString().padLeft(2, '0')}";
      result.add(
        AttendanceTrendData(DateTime(filterYear, i, 1), counts[key] ?? 0),
      );
    }
  } else if (groupBy == 'year') {
    int minYear = filterYear ?? DateTime.now().year - 4;
    int maxYear = filterYear ?? DateTime.now().year;
    for (String k in counts.keys) {
      try {
        int y = int.parse(k);
        if (y < minYear) minYear = y;
        if (y > maxYear) maxYear = y;
      } catch (_) {}
    }
    for (int i = minYear; i <= maxYear; i++) {
      result.add(AttendanceTrendData(DateTime(i, 1, 1), counts["$i"] ?? 0));
    }
  } else {
    counts.forEach((key, val) {
      List<String> p = key.split('-');
      int y = int.parse(p[0]);
      int m = p.length > 1 ? int.parse(p[1]) : 1;
      int d = p.length > 2 ? int.parse(p[2]) : 1;
      result.add(AttendanceTrendData(DateTime(y, m, d), val));
    });
  }

  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> demographicAreas(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.people));
  ref.watch(domainRevisionProvider(DataDomain.areas));
  if (auth.isLoading && !auth.hasValue) return [];
  final user = auth.value;
  final filters = user?.visibilityFilters ?? {};

  final query = db.selectOnly(db.persons);

  // Strict visibility
  if (user != null && user.isAdvanced && filters.isNotEmpty) {
    for (final type in filters.keys) {
      final values = filters[type] ?? [];
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
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
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
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  query.join([
    drift.leftOuterJoin(db.areas, db.areas.areaId.equalsExp(db.persons.areaId)),
  ]);
  query.addColumns([db.areas.areaName, db.persons.personId.count()]);
  query.groupBy([db.areas.areaId, db.areas.areaName]);

  final rows = await query.get();
  if (!isMounted) return [];
  return rows
      .map(
        (r) => DemographicStatData(
          r.read(db.areas.areaName) ?? 'بدون منطقة',
          r.read(db.persons.personId.count()) ?? 0,
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> demographicStages(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.people));
  ref.watch(domainRevisionProvider(DataDomain.stages));
  if (auth.isLoading && !auth.hasValue) return [];
  final user = auth.value;
  final filters = user?.visibilityFilters ?? {};

  final query = db.selectOnly(db.persons);

  // Strict visibility
  if (user != null && user.isAdvanced && filters.isNotEmpty) {
    for (final type in filters.keys) {
      final values = filters[type] ?? [];
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
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
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
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  query.join([
    drift.leftOuterJoin(
      db.stages,
      db.stages.stageId.equalsExp(db.persons.stageId),
    ),
  ]);
  query.addColumns([db.stages.stageName, db.persons.personId.count()]);
  query.groupBy([db.stages.stageId, db.stages.stageName]);

  final rows = await query.get();
  if (!isMounted) return [];
  return rows
      .map(
        (r) => DemographicStatData(
          r.read(db.stages.stageName) ?? 'بدون مرحلة',
          r.read(db.persons.personId.count()) ?? 0,
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> demographicFathers(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.people));
  ref.watch(domainRevisionProvider(DataDomain.fathers));
  if (auth.isLoading && !auth.hasValue) return [];
  final user = auth.value;
  final filters = user?.visibilityFilters ?? {};

  final query = db.selectOnly(db.persons);

  // Strict visibility
  if (user != null && user.isAdvanced && filters.isNotEmpty) {
    for (final type in filters.keys) {
      final values = filters[type] ?? [];
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
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
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
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  query.join([
    drift.leftOuterJoin(
      db.fathers,
      db.fathers.fatherId.equalsExp(db.persons.fatherId),
    ),
  ]);
  query.addColumns([db.fathers.fatherName, db.persons.personId.count()]);
  query.groupBy([db.fathers.fatherId, db.fathers.fatherName]);

  final rows = await query.get();
  if (!isMounted) return [];
  return rows
      .map(
        (r) => DemographicStatData(
          r.read(db.fathers.fatherName) ?? 'بدون أب اعتراف',
          r.read(db.persons.personId.count()) ?? 0,
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> demographicGender(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.people));
  if (auth.isLoading && !auth.hasValue) return [];
  final user = auth.value;
  final filters = user?.visibilityFilters ?? {};

  final query = db.selectOnly(db.persons);

  // Strict visibility
  if (user != null && user.isAdvanced && filters.isNotEmpty) {
    for (final type in filters.keys) {
      final values = filters[type] ?? [];
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
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
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
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  query.addColumns([db.persons.jenderName, db.persons.personId.count()]);
  query.groupBy([db.persons.jenderName]);

  final rows = await query.get();
  if (!isMounted) return [];
  return rows
      .map(
        (r) => DemographicStatData(
          r.read(db.persons.jenderName) ?? 'غير محدد',
          r.read(db.persons.personId.count()) ?? 0,
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> demographicFirstNames(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.people));
  if (auth.isLoading && !auth.hasValue) return [];
  final user = auth.value;
  final filters = user?.visibilityFilters ?? {};

  var query = db.select(db.persons);

  // Strict visibility
  if (user != null && user.isAdvanced && filters.isNotEmpty) {
    for (final type in filters.keys) {
      final values = filters[type] ?? [];
      switch (type) {
        case 'stage':
          if (values.isEmpty)
            query.where((t) => t.stageId.isNull() & t.stageId.isNotNull());
          else
            query.where((t) => t.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty)
            query.where((t) => t.khorosId.isNull() & t.khorosId.isNotNull());
          else
            query.where((t) => t.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            query.where((t) => t.areaId.isNull() & t.areaId.isNotNull());
          } else {
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            query.where((t) => t.areaId.isIn(descendants));
          }
          break;
        case 'father':
          if (values.isEmpty)
            query.where((t) => t.fatherId.isNull() & t.fatherId.isNotNull());
          else
            query.where((t) => t.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            query.where(
              (t) => t.jenderName.isNull() & t.jenderName.isNotNull(),
            );
          } else {
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where((t) => t.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  final rows = await query.get();
  if (!isMounted) return [];

  Map<String, int> nameCounts = {};
  for (var person in rows) {
    if (person.personName != null && person.personName!.isNotEmpty) {
      String firstName = person.personName!.trim().split(' ').first;
      if (firstName.isNotEmpty) {
        nameCounts[firstName] = (nameCounts[firstName] ?? 0) + 1;
      }
    }
  }

  var list = nameCounts.entries
      .map((e) => DemographicStatData(e.key, e.value))
      .toList();
  list.sort((a, b) => b.count.compareTo(a.count));
  return list.take(10).toList(); // Top 10 first names
}

@Riverpod(keepAlive: true)
Future<List<DemographicStatData>> attendanceRankings(
  Ref ref, {
  int? stageId,
  int? areaId,
  int? fatherId,
  DateTime? dateFrom,
  DateTime? dateTo,
  int? serviceId,
  required String
  sortCriteria, // 'attendance', 'absence', 'all', 'most_late', 'most_early'
  int? limit,
  int? offset,
}) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  ref.watch(domainRevisionProvider(DataDomain.attendance));
  ref.watch(domainRevisionProvider(DataDomain.people));
  ref.watch(domainRevisionProvider(DataDomain.services));
  final user = auth.value;

  // 1. Get persons with filters
  final personsQuery = db.selectOnly(db.persons)
    ..addColumns([db.persons.personId, db.persons.personName]);
  if (stageId != null) personsQuery.where(db.persons.stageId.equals(stageId));
  if (areaId != null) {
    final descendantIds = await db.getAreaAndDescendantIds(areaId);
    if (!isMounted) return [];
    personsQuery.where(db.persons.areaId.isIn(descendantIds));
  }
  if (fatherId != null)
    personsQuery.where(db.persons.fatherId.equals(fatherId));

  // Visibility filters
  if (user != null && user.isAdvanced && user.visibilityFilters.isNotEmpty) {
    for (final type in user.visibilityFilters.keys) {
      final values = user.visibilityFilters[type]!;
      switch (type) {
        case 'stage':
          if (values.isEmpty)
            personsQuery.where(
              db.persons.stageId.isNull() & db.persons.stageId.isNotNull(),
            );
          else
            personsQuery.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty)
            personsQuery.where(
              db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull(),
            );
          else
            personsQuery.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            personsQuery.where(
              db.persons.areaId.isNull() & db.persons.areaId.isNotNull(),
            );
          } else {
            final descendants = await db.getMultipleAreasAndDescendantIds(
              values,
            );
            if (!isMounted) return [];
            personsQuery.where(db.persons.areaId.isIn(descendants));
          }
          break;
        case 'father':
          if (values.isEmpty)
            personsQuery.where(
              db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull(),
            );
          else
            personsQuery.where(db.persons.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            personsQuery.where(
              db.persons.jenderName.isNull() &
                  db.persons.jenderName.isNotNull(),
            );
          } else {
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            personsQuery.where(db.persons.jenderName.isIn(genders));
          }
          break;
      }
    }
  }

  final persons = (await personsQuery.get())
      .map(
        (row) => db.persons.map(
          row.rawData.data,
          tablePrefix: db.persons.aliasedName,
        ),
      )
      .toList();
  if (!isMounted) return [];
  if (persons.isEmpty) return [];

  // 2. Get attendance counts
  final attendanceQuery = db.selectOnly(db.coming)
    ..addColumns([
      db.coming.personId,
      db.coming.dateWeek,
      db.coming.serviceId,
      db.coming.attendTime,
    ])
    ..where(db.coming.personId.isIn(persons.map((p) => p.personId)));
  if (serviceId != null) {
    attendanceQuery.where(db.coming.serviceId.equals(serviceId));
  }

  final attendanceRows = (await attendanceQuery.get())
      .map(
        (row) =>
            db.coming.map(row.rawData.data, tablePrefix: db.coming.aliasedName),
      )
      .toList();
  if (!isMounted) return [];
  final services =
      await (db.selectOnly(db.services)..addColumns([
            db.services.serviceId,
            db.services.hour,
            db.services.minute,
          ]))
          .get();
  if (!isMounted) return [];
  final serviceMap = {
    for (final row in services)
      row.read(db.services.serviceId)!: db.services.map(
        row.rawData.data,
        tablePrefix: db.services.aliasedName,
      ),
  };

  Map<int, int> attendanceCounts = {};
  Map<int, int> lateMinutesMap = {};
  Map<int, int> earlyMinutesMap = {};

  int parseTimeToMinutes(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    int h = 0, m = 0;
    bool isPM = timeStr.contains('PM') || timeStr.contains('م');
    bool isAM = timeStr.contains('AM') || timeStr.contains('ص');
    String cleanTime = timeStr.replaceAll(RegExp(r'[A-Zم ص]'), '').trim();
    List<String> parts = cleanTime.split(':');
    if (parts.isNotEmpty) h = int.tryParse(parts[0]) ?? 0;
    if (parts.length > 1) m = int.tryParse(parts[1]) ?? 0;
    if (isPM && h < 12) h += 12;
    if (isAM && h == 12) h = 0;
    return (h * 60) + m;
  }

  for (var row in attendanceRows) {
    if (row.personId != null) {
      bool inRange = true;
      if (dateFrom != null || dateTo != null) {
        if (row.dateWeek != null && row.dateWeek!.isNotEmpty) {
          try {
            DateTime? rowDate = DateTime.tryParse(row.dateWeek!);
            if (rowDate == null) {
              List<String> parts = row.dateWeek!.split(RegExp(r'[/|-]'));
              if (parts.length >= 3) {
                int p0 = int.tryParse(parts[0]) ?? 0;
                int p1 = int.tryParse(parts[1]) ?? 0;
                int p2 = int.tryParse(parts[2]) ?? 0;
                if (p0 > 31)
                  rowDate = DateTime(p0, p1, p2);
                else if (p2 > 31)
                  rowDate = DateTime(p2, p1, p0);
              }
            }
            if (rowDate != null) {
              final safeRowDate = DateTime(
                rowDate.year,
                rowDate.month,
                rowDate.day,
              );
              final safeDateFrom = dateFrom != null
                  ? DateTime(dateFrom.year, dateFrom.month, dateFrom.day)
                  : null;
              final safeDateTo = dateTo != null
                  ? DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59)
                  : null;

              if (safeDateFrom != null && safeRowDate.isBefore(safeDateFrom))
                inRange = false;
              if (safeDateTo != null && safeRowDate.isAfter(safeDateTo))
                inRange = false;
            } else {
              inRange = false;
            }
          } catch (_) {
            inRange = false;
          }
        } else {
          inRange = false;
        }
      }
      if (inRange) {
        attendanceCounts[row.personId!] =
            (attendanceCounts[row.personId!] ?? 0) + 1;

        if (row.serviceId != null &&
            row.attendTime != null &&
            row.attendTime!.isNotEmpty) {
          final svc = serviceMap[row.serviceId!];
          if (svc != null && svc.hour != null && svc.minute != null) {
            final serviceMins = svc.hour! * 60 + svc.minute!;
            final attendMins = parseTimeToMinutes(row.attendTime!);
            final diff = attendMins - serviceMins;

            if (diff > 0) {
              lateMinutesMap[row.personId!] =
                  (lateMinutesMap[row.personId!] ?? 0) + diff;
            } else if (diff < 0) {
              earlyMinutesMap[row.personId!] =
                  (earlyMinutesMap[row.personId!] ?? 0) + (-diff);
            }
          }
        }
      }
    }
  }

  // 3. Map to stat data based on sortCriteria
  List<DemographicStatData> rankings = persons.map((p) {
    int val = 0;
    if (sortCriteria == 'most_late') {
      val = lateMinutesMap[p.personId] ?? 0;
    } else if (sortCriteria == 'most_early') {
      val = earlyMinutesMap[p.personId] ?? 0;
    } else {
      val = attendanceCounts[p.personId] ?? 0;
    }
    return DemographicStatData(p.personName ?? 'بدون اسم', val);
  }).toList();

  // 4. Sort based on criteria
  if (sortCriteria == 'absence') {
    rankings.sort((a, b) => a.count.compareTo(b.count));
  } else {
    rankings.sort((a, b) => b.count.compareTo(a.count));
  }

  // Filter 0 counts for specific stats
  if (sortCriteria == 'most_late' ||
      sortCriteria == 'most_early' ||
      sortCriteria == 'attendance') {
    rankings = rankings.where((r) => r.count > 0).toList();
  }

  // Apply default limit if none provided for performance, or specific ones
  final effectiveLimit = limit ?? (sortCriteria == 'all' ? 1000 : 15);
  final effectiveOffset = offset ?? 0;

  if (effectiveOffset >= rankings.length) return [];

  final end = (effectiveOffset + effectiveLimit).clamp(0, rankings.length);
  return rankings.sublist(effectiveOffset, end);
}
