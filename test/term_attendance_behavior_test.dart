import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/term_attendance_repository.dart';
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

  test(
    'term closure averages behavior rows without requiring attendance',
    () async {
      final serviceId = await db
          .into(db.services)
          .insert(
            ServicesCompanion.insert(
              serviceName: const drift.Value('Service'),
              dayOfWeek: const drift.Value(DateTime.sunday),
            ),
          );
      final personId = await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(personName: const drift.Value('Person')),
          );

      final attendanceRepo = container.read(
        attendanceRepositoryProvider.notifier,
      );
      await attendanceRepo.saveBehaviorScores(
        scores: {personId: 5},
        dateWeek: '2026-06-21',
        month: 6,
        year: 2026,
        serviceIds: [serviceId],
      );
      await attendanceRepo.saveBehaviorScores(
        scores: {personId: 7},
        dateWeek: '2026-06-19',
        month: 6,
        year: 2026,
        serviceIds: [serviceId],
      );

      final report = await container
          .read(termAttendanceRepositoryProvider)
          .buildReport(
            serviceIds: [serviceId],
            startDate: DateTime(2026, 6),
            endDate: DateTime(2026, 6, 30),
            maxGrade: 10,
            dayMaxGrade: 4,
            addBehavior: true,
          );

      expect(report.students, hasLength(1));
      expect(report.students.single.attendedCount, 0);
      expect(report.students.single.attendanceGrade, 0);
      expect(report.students.single.averageBehavior, 6);
      expect(report.students.single.grade, 6);
    },
  );
}
