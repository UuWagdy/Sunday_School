import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _ReadFailure extends QueryInterceptor {
  bool fail = false;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String sql,
    List<Object?> args,
  ) {
    if (fail) throw StateError('simulated disconnected data source');
    return executor.runSelect(sql, args);
  }
}

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  test(
    'read failures propagate instead of replacing the visible snapshot with empty success',
    () async {
      final faults = _ReadFailure();
      final db = AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(faults),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await container.read(authServiceProvider.future);
      await db.customSelect('SELECT 1').get();
      final people = container.read(personsRepositoryProvider.notifier);
      final attendance = container.read(attendanceRepositoryProvider.notifier);
      // Let provider initialization finish before injecting a transport failure.
      await container.read(personsRepositoryProvider.future);
      await container.read(attendanceRepositoryProvider.future);
      faults.fail = true;
      await expectLater(people.fetchTotalCount(), throwsStateError);
      await expectLater(people.fetchPersons(), throwsStateError);
      await expectLater(
        attendance.fetchAttendance(status: 'all'),
        throwsStateError,
      );
      await expectLater(
        attendance.fetchAttendanceSummary(status: 'all'),
        throwsStateError,
      );
    },
  );
}
