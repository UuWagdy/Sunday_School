import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/auth_service.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'reports_repository.g.dart';

/// DTO for person report data (joins Persons + Stages + Areas)
class PersonReportDTO {
  final int? personId;
  final String? personName;
  final String? stageName;
  final String? areaName;
  final String? streetName;
  final String? phone;
  final String? mobile;
  final String? jenderName;

  PersonReportDTO({
    this.personId,
    this.personName,
    this.stageName,
    this.areaName,
    this.streetName,
    this.phone,
    this.mobile,
    this.jenderName,
  });
}

/// DTO for attendance report data
class AttendanceReportDTO {
  final int? personId;
  final String? personName;
  final String? dateWeek;
  final int? point;
  final int? month;
  final int? year;
  final int? behavior;

  AttendanceReportDTO({
    this.personId,
    this.personName,
    this.dateWeek,
    this.point,
    this.month,
    this.year,
    this.behavior,
  });
}

/// DTO for statistics
class StageStatDTO {
  final String? stageName;
  final int count;

  StageStatDTO({this.stageName, required this.count});
}

@Riverpod(keepAlive: true)
Future<List<PersonReportDTO>> personsReport(Ref ref, {int? stageId, int? areaId}) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  final user = auth.value;


  final query = db.select(db.persons).join([
    leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
    leftOuterJoin(db.areas, db.areas.areaId.equalsExp(db.persons.areaId)),
  ]);

  if (stageId != null) {
    query.where(db.persons.stageId.equals(stageId));
  }
  if (areaId != null) {
    final descendantIds = await db.getAreaAndDescendantIds(areaId);
    if (!isMounted) return [];
    query.where(db.persons.areaId.isIn(descendantIds));
  }

  // Apply visibility filters
  if (user != null && user.isAdvanced) {
    for (final type in user.visibilityFilters.keys) {
      final values = user.visibilityFilters[type]!;
      switch (type) {
        case 'stage':
          if (values.isEmpty) query.where(db.persons.stageId.isNull() & db.persons.stageId.isNotNull());
          else query.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty) query.where(db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull());
          else query.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            query.where(db.persons.areaId.isNull() & db.persons.areaId.isNotNull());
          } else {
            final descendants = await db.getMultipleAreasAndDescendantIds(values);
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
          }
          break;
        case 'father':
          if (values.isEmpty) query.where(db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull());
          else query.where(db.persons.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            query.where(db.persons.jenderName.isNull() & db.persons.jenderName.isNotNull());
          } else {
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
        case 'service':
          if (values.isEmpty) {
            query.where(Constant(false));
          } else {
            final sub = db.selectOnly(db.personServices)..addColumns([db.personServices.personId]);
            sub.where(db.personServices.serviceId.isIn(values));
            query.where(existsQuery(sub..where(db.personServices.personId.equalsExp(db.persons.personId))));
          }
          break;
      }
    }
  }

  final rows = await query.get();
  if (!isMounted) return [];

  return rows.map((row) {
    final person = row.readTable(db.persons);
    final stage = row.readTableOrNull(db.stages);
    final area = row.readTableOrNull(db.areas);
    return PersonReportDTO(
      personId: person.personId,
      personName: person.personName,
      stageName: stage?.stageName,
      areaName: area?.areaName,
      streetName: person.streetName,
      phone: person.phone,
      mobile: person.mobile,
      jenderName: person.jenderName,
    );
  }).toList();
}

@Riverpod(keepAlive: true)
Future<List<AttendanceReportDTO>> attendanceReport(Ref ref, {int? month, int? year, String? status}) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  final user = auth.value;

  final query = db.select(db.coming).join([
    leftOuterJoin(db.persons, db.persons.personId.equalsExp(db.coming.personId)),
  ]);

  if (month != null) {
    query.where(db.coming.mont1.equals(month));
  }
  if (year != null) {
    query.where(db.coming.year1.equals(year));
  }
  
  if (status != null && status.isNotEmpty && status != 'all' && status != 'present') {
    if (status == 'checked_out') {
      query.where(db.coming.checkoutTime.isNotNull());
    } else if (status == 'complete') {
      query.where(db.coming.checkoutTime.isNotNull() & db.coming.attendTime.isNotNull());
    }
  }

  // Apply visibility filters
  if (user != null && user.isAdvanced) {
    for (final type in user.visibilityFilters.keys) {
      final values = user.visibilityFilters[type]!;
      switch (type) {
        case 'stage':
          if (values.isEmpty) query.where(db.persons.stageId.isNull() & db.persons.stageId.isNotNull());
          else query.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty) query.where(db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull());
          else query.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            query.where(db.persons.areaId.isNull() & db.persons.areaId.isNotNull());
          } else {
            final descendants = await db.getMultipleAreasAndDescendantIds(values);
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
          }
          break;
        case 'father':
          if (values.isEmpty) query.where(db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull());
          else query.where(db.persons.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            query.where(db.persons.jenderName.isNull() & db.persons.jenderName.isNotNull());
          } else {
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
        case 'service':
          if (values.isEmpty) {
            query.where(existsQuery(db.selectOnly(db.personServices)..addColumns([db.personServices.personId])..where(Constant(false))));
          } else {
            final sub = db.selectOnly(db.personServices)..addColumns([db.personServices.personId]);
            sub.where(db.personServices.serviceId.isIn(values));
            query.where(existsQuery(sub..where(db.personServices.personId.equalsExp(db.persons.personId))));
          }
          break;
      }
    }
  }

  final rows = await query.get();
  if (!isMounted) return [];

  return rows.map((row) {
    final coming = row.readTable(db.coming);
    final person = row.readTableOrNull(db.persons);
    return AttendanceReportDTO(
      personId: coming.personId,
      personName: person?.personName,
      dateWeek: coming.dateWeek,
      point: coming.point,
      month: coming.mont1,
      year: coming.year1,
      behavior: coming.behavior,
    );
  }).toList();
}

@Riverpod(keepAlive: true)
Future<List<StageStatDTO>> stageStatistics(Ref ref) async {
  bool isMounted = true;
  ref.onDispose(() => isMounted = false);

  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authServiceProvider);
  final user = auth.value;

  final query = db.selectOnly(db.persons).join([
    leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
  ]);
  query.addColumns([
    db.stages.stageName,
    db.persons.personId.count(),
  ]);

  // Apply visibility filters
  if (user != null && user.isAdvanced) {
    for (final type in user.visibilityFilters.keys) {
      final values = user.visibilityFilters[type]!;
      switch (type) {
        case 'stage':
          if (values.isEmpty) query.where(db.persons.stageId.isNull() & db.persons.stageId.isNotNull());
          else query.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isEmpty) query.where(db.persons.khorosId.isNull() & db.persons.khorosId.isNotNull());
          else query.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isEmpty) {
            query.where(db.persons.areaId.isNull() & db.persons.areaId.isNotNull());
          } else {
            final descendants = await db.getMultipleAreasAndDescendantIds(values);
            if (!isMounted) return [];
            query.where(db.persons.areaId.isIn(descendants));
          }
          break;
        case 'father':
          if (values.isEmpty) query.where(db.persons.fatherId.isNull() & db.persons.fatherId.isNotNull());
          else query.where(db.persons.fatherId.isIn(values));
          break;
        case 'gender':
          if (values.isEmpty) {
            query.where(db.persons.jenderName.isNull() & db.persons.jenderName.isNotNull());
          } else {
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
          }
          break;
        case 'service':
          if (values.isEmpty) {
            query.where(existsQuery(db.selectOnly(db.personServices)..addColumns([db.personServices.personId])..where(Constant(false))));
          } else {
            final sub = db.selectOnly(db.personServices)..addColumns([db.personServices.personId]);
            sub.where(db.personServices.serviceId.isIn(values));
            query.where(existsQuery(sub..where(db.personServices.personId.equalsExp(db.persons.personId))));
          }
          break;
      }
    }
  }

  query.groupBy([db.stages.stageName]);

  final rows = await query.get();
  if (!isMounted) return [];

  return rows.map((row) {
    return StageStatDTO(
      stageName: row.read(db.stages.stageName),
      count: row.read(db.persons.personId.count()) ?? 0,
    );
  }).toList();
}
