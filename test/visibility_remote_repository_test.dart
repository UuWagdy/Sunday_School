// Executed only by tool/test_visibility_server.py against its disposable server.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/dashboard_repository.dart';
import 'package:petros_pols_flutter/repositories/term_attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/stages_repository.dart';
import 'package:petros_pols_flutter/repositories/khoros_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';
import 'package:petros_pols_flutter/sync/signalr_sync_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

class _RemoteConfig extends ServerConfigNotifier {
  @override
  ServerConfig build() => const ServerConfig(
    isServerMode: true,
    serverUrl: String.fromEnvironment('SCOPE_TEST_URL'),
    jwtToken: String.fromEnvironment('SCOPE_TEST_TOKEN'),
  );
}

class _FixtureAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  const url = String.fromEnvironment('SCOPE_TEST_URL');
  const token = String.fromEnvironment('SCOPE_TEST_TOKEN');
  const adminToken = String.fromEnvironment('SCOPE_TEST_ADMIN_TOKEN');
  test(
    'real Drift repository SQL respects remote scope across reports and links',
    () async {
      final db = AppDatabase.forTesting(
        DotNetPostgresQueryExecutor(
          getConfig: () => const ServerConfig(serverUrl: url, jwtToken: token),
        ),
      );
      db.visibilityContext.applyLocally = false;
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_FixtureAuth.new),
          serverConfigProvider.overrideWith(_RemoteConfig.new),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final people = container.read(personsRepositoryProvider.notifier);
      expect((await people.fetchPersons()).map((p) => p.id), [201]);
      expect(await people.fetchTotalCount(), 1);
      expect(await people.findSimilarNames('Hidden'), isEmpty);
      final attendance = await container
          .read(attendanceRepositoryProvider.notifier)
          .fetchAttendance(status: 'all', limit: 20);
      expect(attendance.map((r) => r.personId).toSet(), {201});
      final summary = await container
          .read(attendanceRepositoryProvider.notifier)
          .fetchAttendanceSummary(status: 'all');
      expect(summary['total'], 1);
      expect(
        await container.read(demographicStagesProvider.future),
        isNotEmpty,
      );
      expect(
        await container.read(
          generalAttendanceTrendProvider(groupBy: 'month').future,
        ),
        isNotEmpty,
      );
      final term = await container
          .read(termAttendanceRepositoryProvider)
          .buildReport(
            serviceIds: [101],
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            maxGrade: 10,
            dayMaxGrade: 4,
            addBehavior: false,
          );
      expect(term, isNotNull);
      final adminDb = AppDatabase.forTesting(
        DotNetPostgresQueryExecutor(
          getConfig: () =>
              const ServerConfig(serverUrl: url, jwtToken: adminToken),
        ),
      );
      adminDb.visibilityContext.applyLocally = false;
      final admin = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(adminDb),
          authServiceProvider.overrideWith(_FixtureAuth.new),
        ],
      );
      addTearDown(() async {
        admin.dispose();
        await adminDb.close();
      });
      // Real authenticated SignalR handshake and a write from a second client.
      final connection = container.listen(signalRSyncProvider, (_, __) {});
      addTearDown(connection.close);
      for (
        var i = 0;
        i < 150 &&
            container.read(signalRSyncProvider) !=
                SignalRConnectionStatus.connected;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        container.read(signalRSyncProvider),
        SignalRConnectionStatus.connected,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final before = container.read(domainRevisionProvider(DataDomain.people));
      await adminDb.customStatement(
        'UPDATE "Persons" SET "Person_Name"=? WHERE "Person_ID"=?',
        ['Visible boy updated', 201],
      );
      for (
        var i = 0;
        i < 150 &&
            container.read(domainRevisionProvider(DataDomain.people)) <= before;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        container.read(domainRevisionProvider(DataDomain.people)),
        greaterThan(before),
      );
      expect((await people.fetchPersons()).single.name, 'Visible boy updated');
      expect(
        await admin
            .read(stagesRepositoryProvider.notifier)
            .updateStage(105, '5ب', serviceIds: [101, 102]),
        true,
      );
      final links = await adminDb
          .customSelect('SELECT * FROM "Stage_Services" WHERE "Stage_ID"=105')
          .get();
      expect(links.length, 2);
      expect(
        await admin
            .read(khorosRepositoryProvider.notifier)
            .updateKhorosServicesForIds([107], [101, 102]),
        1,
      );
      expect(
        (await adminDb
                .customSelect(
                  'SELECT * FROM "Khoros_Services" WHERE "Khoros_ID"=107',
                )
                .get())
            .length,
        2,
      );
    },
    skip: url.isEmpty,
  );
}
