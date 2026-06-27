import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/service_eligibility_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _TestAuthService extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWith(_TestAuthService.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> addService(String name) {
    return db
        .into(db.services)
        .insert(ServicesCompanion.insert(serviceName: drift.Value(name)));
  }

  Future<void> insertAttendance({
    required int id,
    required int points,
    String? checkoutTime,
  }) async {
    await db
        .into(db.coming)
        .insert(
          ComingCompanion.insert(
            id: drift.Value(id),
            personId: const drift.Value(1),
            dateWeek: const drift.Value('2026-06-18'),
            point: drift.Value(points),
            mont1: const drift.Value(6),
            year1: const drift.Value(2026),
            attendTime: const drift.Value('10:00 AM'),
            checkoutTime: drift.Value(checkoutTime),
          ),
        );
  }

  Future<int?> pointFor(int id) async {
    final row = await (db.select(
      db.coming,
    )..where((t) => t.id.equals(id))).getSingle();
    return row.point;
  }

  test(
    'addAttendance rejects a person outside the selected service with names',
    () async {
      final serviceId = await addService('Service');
      final personId = await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(personName: const drift.Value('Person')),
          );

      final error = await container
          .read(attendanceRepositoryProvider.notifier)
          .addAttendance(
            personId: personId,
            dateWeek: '2026-06-18',
            month: 6,
            year: 2026,
            serviceId: serviceId,
          );

      expect(error, 'Person مش مسجل في خدمة Service');
      final rows = await db.select(db.coming).get();
      expect(rows, isEmpty);
    },
  );

  test('service eligibility message falls back when names are missing', () {
    expect(serviceEligibilityErrorMessageFor(), serviceEligibilityErrorMessage);
  });

  test(
    'addAttendance saves when person has direct service eligibility',
    () async {
      final serviceId = await addService('Service');
      final personId = await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(personName: const drift.Value('Person')),
          );
      await db
          .into(db.personServices)
          .insert(
            PersonServicesCompanion.insert(
              personId: personId,
              serviceId: serviceId,
            ),
          );

      final error = await container
          .read(attendanceRepositoryProvider.notifier)
          .addAttendance(
            personId: personId,
            dateWeek: '2026-06-18',
            month: 6,
            year: 2026,
            serviceId: serviceId,
          );

      expect(error, isNull);
      final rows = await db.select(db.coming).get();
      expect(rows, hasLength(1));
    },
  );

  test('updating attendance points preserves checkout points', () async {
    await insertAttendance(id: 1, points: 4, checkoutTime: '11:00 AM');

    final count = await container
        .read(attendanceRepositoryProvider.notifier)
        .updateAttendancePointsForIds(ids: [1], points: 3);

    expect(count, 1);
    expect(await pointFor(1), 5);
  });

  test('updating checkout points preserves attendance points', () async {
    await insertAttendance(id: 1, points: 4, checkoutTime: '11:00 AM');

    final count = await container
        .read(attendanceRepositoryProvider.notifier)
        .updateAttendancePointsForIds(
          ids: [1],
          points: 4,
          isCheckoutMode: true,
        );

    expect(count, 1);
    expect(await pointFor(1), 6);
  });

  test(
    'checkout point update adds to existing attendance-only points',
    () async {
      await insertAttendance(id: 1, points: 2);

      final count = await container
          .read(attendanceRepositoryProvider.notifier)
          .updateAttendancePointsForIds(
            ids: [1],
            points: 2,
            isCheckoutMode: true,
          );

      expect(count, 1);
      expect(await pointFor(1), 4);
    },
  );
}
