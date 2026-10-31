import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/database_provider.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';

class BusDriverDTO {
  final int id;
  final String name;
  final String? phone;
  final String? busNumber;
  final String? notes;
  final int assignedCount;

  const BusDriverDTO({
    required this.id,
    required this.name,
    this.phone,
    this.busNumber,
    this.notes,
    this.assignedCount = 0,
  });

  BusDriverDTO copyWith({
    int? id,
    String? name,
    String? phone,
    String? busNumber,
    String? notes,
    int? assignedCount,
  }) {
    return BusDriverDTO(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      busNumber: busNumber ?? this.busNumber,
      notes: notes ?? this.notes,
      assignedCount: assignedCount ?? this.assignedCount,
    );
  }
}

class BusStudentDTO {
  final int assignmentId;
  final int driverId;
  final int personId;
  final String personName;
  final String? stageName;
  final String? khorosName;
  final String? areaName;
  final String? street;
  final String? phone;
  final String? mobile;
  final String? notes;
  final String? checkoutTypeToday;
  final String? checkoutNotesToday;
  bool isDelivered;

  BusStudentDTO({
    required this.assignmentId,
    required this.driverId,
    required this.personId,
    required this.personName,
    this.stageName,
    this.khorosName,
    this.areaName,
    this.street,
    this.phone,
    this.mobile,
    this.notes,
    this.checkoutTypeToday,
    this.checkoutNotesToday,
    this.isDelivered = false,
  });

  bool get isExcludedFromBusToday =>
      checkoutTypeToday == 'alone' ||
      checkoutTypeToday == 'parent' ||
      checkoutTypeToday == 'other';

  bool get hasLeftAloneToday => checkoutTypeToday == 'alone';

  bool get hasLeftWithParentToday => checkoutTypeToday == 'parent';

  bool get hasLeftOtherReasonToday => checkoutTypeToday == 'other';
}

class StudentSearchResult {
  final int personId;
  final String personName;
  final String? stageName;
  final String? currentDriverName;
  final int? currentDriverId;

  const StudentSearchResult({
    required this.personId,
    required this.personName,
    this.stageName,
    this.currentDriverName,
    this.currentDriverId,
  });
}

class BusRepository extends Notifier<AsyncValue<List<BusDriverDTO>>> {
  int _driversGeneration = 0;
  Object? lastDriversError;
  @override
  AsyncValue<List<BusDriverDTO>> build() {
    ref.watch(domainRevisionProvider(DataDomain.buses));
    _loadDrivers();
    return ref.isFirstBuild ? const AsyncValue.loading() : state;
  }

  Future<void> _loadDrivers() async {
    final generation = ++_driversGeneration;
    try {
      final db = ref.read(appDatabaseProvider);
      final rows = await db.customSelect('''
        SELECT d."ID", d."Name", d."Phone", d."Bus_Number", d."Notes",
               COUNT(a."ID") as assigned_count
        FROM "Bus_Drivers" d
        LEFT JOIN "Bus_Assignments" a ON a."Driver_ID" = d."ID"
        GROUP BY d."ID", d."Name", d."Phone", d."Bus_Number", d."Notes"
        ORDER BY d."Name" ASC;
      ''').get();

      final list = rows.map((row) {
        return BusDriverDTO(
          id: row.data['ID'] as int,
          name: (row.data['Name'] as String?) ?? '',
          phone: row.data['Phone'] as String?,
          busNumber: row.data['Bus_Number'] as String?,
          notes: row.data['Notes'] as String?,
          assignedCount: (row.data['assigned_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      if (ref.mounted && generation == _driversGeneration) {
        lastDriversError = null;
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      if (ref.mounted && generation == _driversGeneration) {
        lastDriversError = e;
        debugPrint('تعذر تحديث قائمة السائقين: $e');
        if (!state.hasValue) state = AsyncError<List<BusDriverDTO>>(e, st);
      }
    }
  }

  Future<void> refreshDrivers() async {
    await _loadDrivers();
  }

  Future<bool> addDriver({
    required String name,
    String? phone,
    String? busNumber,
    String? notes,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.customStatement(
        '''
        INSERT INTO "Bus_Drivers" ("Name", "Phone", "Bus_Number", "Notes")
        VALUES (?, ?, ?, ?);
      ''',
        [name.trim(), phone?.trim(), busNumber?.trim(), notes?.trim()],
      );
      await refreshDrivers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDriver({
    required int id,
    required String name,
    String? phone,
    String? busNumber,
    String? notes,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.customStatement(
        '''
        UPDATE "Bus_Drivers"
        SET "Name" = ?, "Phone" = ?, "Bus_Number" = ?, "Notes" = ?
        WHERE "ID" = ?;
      ''',
        [name.trim(), phone?.trim(), busNumber?.trim(), notes?.trim(), id],
      );
      await refreshDrivers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDriver(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.customStatement('DELETE FROM "Bus_Drivers" WHERE "ID" = ?;', [
        id,
      ]);
      await refreshDrivers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all students assigned to a specific driver.
  /// Checks whether each student has a checkout record with type 'parent' on the specified [date].
  Future<List<BusStudentDTO>> fetchStudentsForDriver(
    int driverId, {
    DateTime? date,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final targetDate = date ?? DateTime.now();
    final dateFormatted = DateFormat('yyyy-MM-dd').format(targetDate);

    final rows = await db
        .customSelect(
          '''
      SELECT
        a."ID" AS assignment_id,
        a."Driver_ID" AS driver_id,
        p."Person_ID" AS person_id,
        p."Person_Name" AS person_name,
        s."Stage_Name" AS stage_name,
        k."Khoros_Name" AS khoros_name,
        ar."Area_Name" AS area_name,
        p."Street_Name" AS street_name,
        p."Phone" AS phone,
        p."Mobile" AS mobile,
        a."Notes" AS assignment_notes,
        (
          SELECT LOWER(COALESCE(c."Checkout_Type", ''))
          FROM "Coming" c
          WHERE c."Person_ID" = p."Person_ID"
            AND (c."date_Week" = ? OR c."date_Week" LIKE ?)
          ORDER BY c."ID" DESC
          LIMIT 1
        ) AS checkout_type_today,
        (
          SELECT COALESCE(c."Checkout_Notes", '')
          FROM "Coming" c
          WHERE c."Person_ID" = p."Person_ID"
            AND (c."date_Week" = ? OR c."date_Week" LIKE ?)
          ORDER BY c."ID" DESC
          LIMIT 1
        ) AS checkout_notes_today
      FROM "Bus_Assignments" a
      INNER JOIN "Persons" p ON p."Person_ID" = a."Person_ID"
      LEFT JOIN "Stages" s ON s."Stage_ID" = p."Stage_ID"
      LEFT JOIN "Khoroses" k ON k."Khoros_ID" = p."Khoros_ID"
      LEFT JOIN "Areas" ar ON ar."Area_ID" = p."Area_ID"
      WHERE a."Driver_ID" = ?
      ORDER BY p."Person_Name" ASC;
      ''',
          variables: [
            Variable<String>(dateFormatted),
            Variable<String>('$dateFormatted%'),
            Variable<String>(dateFormatted),
            Variable<String>('$dateFormatted%'),
            Variable<int>(driverId),
          ],
        )
        .get();

    return rows.map((row) {
      return BusStudentDTO(
        assignmentId: row.data['assignment_id'] as int,
        driverId: row.data['driver_id'] as int,
        personId: row.data['person_id'] as int,
        personName: (row.data['person_name'] as String?) ?? '',
        stageName: row.data['stage_name'] as String?,
        khorosName: row.data['khoros_name'] as String?,
        areaName: row.data['area_name'] as String?,
        street: row.data['street_name'] as String?,
        phone: row.data['phone'] as String?,
        mobile: row.data['mobile'] as String?,
        notes: row.data['assignment_notes'] as String?,
        checkoutTypeToday: row.data['checkout_type_today'] as String?,
        checkoutNotesToday: row.data['checkout_notes_today'] as String?,
      );
    }).toList();
  }

  /// Assign a student to a driver. If student is already assigned to someone else, reassigns.
  Future<bool> assignStudentToDriver({
    required int driverId,
    required int personId,
    String? notes,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.customStatement(
        '''
        INSERT INTO "Bus_Assignments" ("Driver_ID", "Person_ID", "Notes")
        VALUES (?, ?, ?)
        ON CONFLICT("Person_ID") DO UPDATE SET
          "Driver_ID" = excluded."Driver_ID",
          "Notes" = excluded."Notes";
      ''',
        [driverId, personId, notes?.trim()],
      );
      await refreshDrivers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove student assignment from bus.
  Future<bool> removeStudentFromDriver(int personId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.customStatement(
        'DELETE FROM "Bus_Assignments" WHERE "Person_ID" = ?;',
        [personId],
      );
      await refreshDrivers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search available students by name or code to link to bus.
  Future<List<StudentSearchResult>> searchAvailableStudents(
    String query,
  ) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final db = ref.read(appDatabaseProvider);
    final isNumber = int.tryParse(clean) != null;

    final rows = await db
        .customSelect(
          '''
      SELECT
        p."Person_ID" AS person_id,
        p."Person_Name" AS person_name,
        s."Stage_Name" AS stage_name,
        d."Name" AS current_driver_name,
        d."ID" AS current_driver_id
      FROM "Persons" p
      LEFT JOIN "Stages" s ON s."Stage_ID" = p."Stage_ID"
      LEFT JOIN "Bus_Assignments" a ON a."Person_ID" = p."Person_ID"
      LEFT JOIN "Bus_Drivers" d ON d."ID" = a."Driver_ID"
      WHERE p."Person_Name" LIKE ? ${isNumber ? 'OR p."Person_ID" = ?' : ''}
      ORDER BY p."Person_Name" ASC
      LIMIT 25;
      ''',
          variables: [
            Variable<String>('%$clean%'),
            if (isNumber) Variable<int>(int.parse(clean)),
          ],
        )
        .get();

    return rows.map((row) {
      return StudentSearchResult(
        personId: row.data['person_id'] as int,
        personName: (row.data['person_name'] as String?) ?? '',
        stageName: row.data['stage_name'] as String?,
        currentDriverName: row.data['current_driver_name'] as String?,
        currentDriverId: row.data['current_driver_id'] as int?,
      );
    }).toList();
  }

  /// Fetches all drivers and their assigned students for PDF batch export.
  Future<Map<BusDriverDTO, List<BusStudentDTO>>> fetchAllDriversWithStudents({
    DateTime? date,
  }) async {
    final drivers = state.value ?? [];
    final map = <BusDriverDTO, List<BusStudentDTO>>{};
    for (final driver in drivers) {
      final students = await fetchStudentsForDriver(driver.id, date: date);
      map[driver] = students;
    }
    return map;
  }
}

final busRepositoryProvider =
    NotifierProvider<BusRepository, AsyncValue<List<BusDriverDTO>>>(
      BusRepository.new,
    );

class BusRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() {
    state++;
  }
}

final busRefreshTriggerProvider = NotifierProvider<BusRefreshNotifier, int>(
  BusRefreshNotifier.new,
);
