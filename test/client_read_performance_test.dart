import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/dashboard_repository.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

class _Reads extends d.QueryInterceptor {
  final statements = <String>[];
  Completer<void>? holdProfile, profileStarted;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    d.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    statements.add(statement);
    if (holdProfile != null && statement.contains('FROM "Pass"')) {
      if (!profileStarted!.isCompleted) profileStarted!.complete();
      await holdProfile!.future;
    }
    return executor.runSelect(statement, args);
  }
}

class _Auth extends AuthService {
  @override
  FutureOr<User?> build() =>
      User(id: 7, username: 'fixture', canPersons: true, canUsers: true);
}

class _QuietCoordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain, int> build() => {for (final d in DataDomain.values) d: 1};
}

void main() {
  late AppDatabase db;
  late _Reads reads;
  late ProviderContainer container;
  setUp(() async {
    reads = _Reads();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(reads));
    await db
        .into(db.pass)
        .insert(
          PassCompanion.insert(
            passId: const d.Value(7),
            personName: const d.Value('fixture'),
            canPersons: const d.Value(true),
            canUsers: const d.Value(true),
            isAdvanced: const d.Value(false),
          ),
        );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWith(_Auth.new),
        dataChangeCoordinatorProvider.overrideWith(_QuietCoordinator.new),
      ],
    );
    container.listen(authServiceProvider, (_, next) {});
    await container.read(authServiceProvider.future);
    reads.statements.clear();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'concurrent profile refreshes coalesce and unchanged data emits nothing',
    () async {
      var changes = 0;
      container.listen(authServiceProvider, (_, next) => changes++);
      final auth = container.read(authServiceProvider.notifier);
      await Future.wait([for (var i = 0; i < 30; i++) auth.refreshUser()]);
      expect(changes, 0);
      expect(
        reads.statements.where((s) => s.contains('FROM "Pass"')).length,
        lessThanOrEqualTo(2),
      );
      expect(reads.statements.length, lessThanOrEqualTo(8));
      await (db.update(db.pass)..where((p) => p.passId.equals(7))).write(
        const PassCompanion(canReports: d.Value(true)),
      );
      await auth.refreshUser();
      expect(changes, 1);
      expect(container.read(authServiceProvider).value!.canReports, isTrue);
    },
  );

  test(
    'an in-flight profile refresh cannot restore a logged-out session',
    () async {
      reads.holdProfile = Completer<void>();
      reads.profileStarted = Completer<void>();
      final auth = container.read(authServiceProvider.notifier);
      final pending = auth.refreshUser();
      await reads.profileStarted!.future;
      auth.logout();
      reads.holdProfile!.complete();
      await pending;
      expect(container.read(authServiceProvider).value, isNull);
    },
  );

  test(
    'autocomplete uses one small query and exact codes work outside its first page',
    () async {
      await db.batch(
        (batch) => batch.insertAll(db.persons, [
          for (var id = 1; id <= 1100; id++)
            PersonsCompanion.insert(
              personId: d.Value(id),
              personName: d.Value('شخص $id'),
            ),
        ]),
      );
      reads.statements.clear();
      container.listen(personsRepositoryProvider, (_, next) {});
      final options = await container.read(personsRepositoryProvider.future);
      expect(options, hasLength(1000));
      expect(options.any((p) => p.id == 1), isFalse);
      expect(reads.statements, hasLength(1));
      expect(reads.statements.single, isNot(contains('Photo')));
      expect(reads.statements.single, isNot(contains('JOIN')));
      final exact = await container
          .read(personsRepositoryProvider.notifier)
          .fetchPersonOptions(personId: 1, limit: 1);
      expect(exact.single.name, 'شخص 1');
    },
  );

  test(
    'large attendance histories retain their counts on the worker path',
    () async {
      await db
          .into(db.persons)
          .insert(
            const PersonsCompanion(
              personId: d.Value(1),
              personName: d.Value('شخص'),
            ),
          );
      await db.batch(
        (batch) => batch.insertAll(db.coming, [
          for (var i = 0; i < 2500; i++)
            const ComingCompanion(
              personId: d.Value(1),
              dateWeek: d.Value('2026-10-17'),
            ),
        ]),
      );
      final rows = await container.read(
        generalAttendanceTrendProvider(
          groupBy: 'month',
          filterYear: 2026,
        ).future,
      );
      expect(rows.singleWhere((r) => r.date.month == 10).count, 2500);
    },
  );

  test(
    'charts preserve counts, legacy dates and rankings without selecting images',
    () async {
      final image = Uint8List(256 * 1024);
      await db
          .into(db.services)
          .insert(
            ServicesCompanion.insert(
              serviceId: const d.Value(1),
              serviceName: const d.Value('خدمة'),
              hour: const d.Value(10),
              minute: const d.Value(0),
              logo: d.Value(image),
            ),
          );
      await db.batch((batch) {
        batch.insertAll(db.persons, [
          for (var id = 1; id <= 2; id++)
            PersonsCompanion.insert(
              personId: d.Value(id),
              personName: d.Value('شخص $id'),
              photo: d.Value(image),
            ),
        ]);
        batch.insertAll(db.coming, [
          const ComingCompanion(
            personId: d.Value(1),
            serviceId: d.Value(1),
            dateWeek: d.Value('2026-10-17'),
            attendTime: d.Value('10:10 AM'),
          ),
          const ComingCompanion(
            personId: d.Value(1),
            serviceId: d.Value(1),
            dateWeek: d.Value('17/10/2026'),
            attendTime: d.Value('10:20 AM'),
          ),
          const ComingCompanion(
            personId: d.Value(2),
            serviceId: d.Value(1),
            dateWeek: d.Value('2026-10-17'),
            attendTime: d.Value('09:50 AM'),
          ),
        ]);
      });
      reads.statements.clear();
      final general = await container.read(
        generalAttendanceTrendProvider(
          groupBy: 'month',
          filterYear: 2026,
        ).future,
      );
      final individual = await container.read(
        individualAttendanceTrendProvider(
          personId: 1,
          groupBy: 'month',
          filterYear: 2026,
        ).future,
      );
      final rankings = await container.read(
        attendanceRankingsProvider(sortCriteria: 'attendance').future,
      );
      final late = await container.read(
        attendanceRankingsProvider(sortCriteria: 'most_late').future,
      );
      expect(
        general
            .singleWhere((r) => r.date.year == 2026 && r.date.month == 10)
            .count,
        3,
      );
      expect(
        individual
            .singleWhere((r) => r.date.year == 2026 && r.date.month == 10)
            .count,
        2,
      );
      expect(rankings.map((r) => r.count), [2, 1]);
      expect(late.single.count, 30);
      expect(
        reads.statements.every(
          (s) => !s.contains('Photo') && !s.contains('Logo'),
        ),
        isTrue,
      );
    },
  );
}
