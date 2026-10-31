// Opt-in checks against an existing server. All test writes are rolled back.
// flutter test --dart-define=SYNC_TEST_URL=http://127.0.0.1:5050 test/remote_database_live_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/dashboard_repository.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/services_repository.dart';
import 'package:petros_pols_flutter/repositories/term_attendance_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';
import 'package:petros_pols_flutter/sync/signalr_sync_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _ReadOnlyAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _LiveServerConfig extends ServerConfigNotifier {
  @override
  ServerConfig build() => const ServerConfig(
    isServerMode: true,
    serverUrl: String.fromEnvironment('SYNC_TEST_URL'),
    jwtToken: String.fromEnvironment('SYNC_TEST_TOKEN'),
  );
}

void main() {
  const url = String.fromEnvironment('SYNC_TEST_URL');
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(
      DotNetPostgresQueryExecutor(
        getConfig: () => const ServerConfig(serverUrl: url, jwtToken: String.fromEnvironment('SYNC_TEST_TOKEN')),
      ),
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWith(_ReadOnlyAuth.new),
        serverConfigProvider.overrideWith(_LiveServerConfig.new),
      ],
    );
    await container.read(authServiceProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'existing people, attendance, analytics and term closure load',
    () async {
      final people = await container.read(personsRepositoryProvider.future);
      final attendance = await db.select(db.coming).get();
      final services = await container.read(servicesRepositoryProvider.future);
      expect(people, isNotEmpty);
      expect(attendance, isNotEmpty);
      expect(services, isNotEmpty);
      final attendanceList = await container
          .read(attendanceRepositoryProvider.notifier)
          .fetchAttendance(status: 'all', limit: 20);
      expect(attendanceList, isNotEmpty);
      final filtered = await container
          .read(personsRepositoryProvider.notifier)
          .fetchPersons(personIds: [people.first.id]);
      expect(filtered.single.id, people.first.id);
      final trend = await container.read(
        generalAttendanceTrendProvider(groupBy: 'month').future,
      );
      expect(trend, isNotEmpty);
      final demographics = await container.read(
        demographicStagesProvider.future,
      );
      expect(demographics, isNotEmpty);
      final report = await container
          .read(termAttendanceRepositoryProvider)
          .buildReport(
            serviceIds: services.map((s) => s.id).toList(),
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            maxGrade: 10,
            dayMaxGrade: 4,
            addBehavior: true,
          );
      expect(report.students, isNotEmpty);
      print(
        'LIVE: ${people.length} people, ${attendance.length} attendance rows, '
        '${services.length} services, ${report.students.length} term students',
      );
    },
    skip: url.isEmpty,
  );

  test(
    'insert ids, updates, batches and deletes round trip with rollback',
    () async {
      final marker = 'sync-contract-${DateTime.now().microsecondsSinceEpoch}';
      final rollback = Exception('intentional test rollback');
      try {
        await db.transaction(() async {
          final id = await db
              .into(db.persons)
              .insert(PersonsCompanion.insert(personName: drift.Value(marker)));
          expect(id, greaterThan(1));
          final person = await (db.select(
            db.persons,
          )..where((p) => p.personId.equals(id))).getSingle();
          expect(person.personName, marker);
          await (db.update(
            db.persons,
          )..where((p) => p.personId.equals(id))).write(
            PersonsCompanion(personName: drift.Value('$marker-updated')),
          );
          await db.batch((batch) {
            batch.insertAll(db.settings, [
              SettingsCompanion.insert(
                settingKey: '$marker-a',
                settingValue: const drift.Value('أ'),
              ),
              SettingsCompanion.insert(
                settingKey: '$marker-b',
                settingValue: const drift.Value('ب'),
              ),
            ]);
          });
          final rows = await (db.select(
            db.settings,
          )..where((s) => s.settingKey.isIn(['$marker-a', '$marker-b']))).get();
          expect(rows, hasLength(2));
          expect(
            await (db.delete(
              db.persons,
            )..where((p) => p.personId.equals(id))).go(),
            1,
          );
          throw rollback;
        });
      } catch (error) {
        if (!identical(error, rollback)) rethrow;
      }
      expect(
        await (db.select(
          db.settings,
        )..where((s) => s.settingKey.equals('$marker-a'))).get(),
        isEmpty,
      );
    },
    skip: url.isEmpty,
  );

  test('committed setting reaches the production sync notifier and watched reader', () async {
    final key = '_sync_probe_${DateTime.now().microsecondsSinceEpoch}';
    final writer = AppDatabase.forTesting(DotNetPostgresQueryExecutor(
      getConfig: () => const ServerConfig(serverUrl: url,
        jwtToken: String.fromEnvironment('SYNC_TEST_TOKEN')),
    ));
    final connected = Completer<void>();
    final refreshed = Completer<void>();
    final sync = container.listen(signalRSyncProvider, (_, next) {
      if (next == SignalRConnectionStatus.connected && !connected.isCompleted) connected.complete();
    }, fireImmediately: true);
    final watcher = (db.select(db.settings)..where((s) => s.settingKey.equals(key)))
        .watch().listen((rows) {
      if (rows.any((r) => r.settingValue == 'probe') && !refreshed.isCompleted) refreshed.complete();
    });
    try {
      await connected.future.timeout(const Duration(seconds: 12));
      await writer.into(writer.settings).insert(SettingsCompanion.insert(
        settingKey: key, settingValue: const drift.Value('probe')));
      await refreshed.future.timeout(const Duration(seconds: 10));
      expect(container.read(signalRSyncProvider), SignalRConnectionStatus.connected);
    } finally {
      await (writer.delete(writer.settings)..where((s) => s.settingKey.equals(key))).go();
      sync.close(); container.invalidate(signalRSyncProvider);
      await watcher.cancel(); await writer.close();
    }
  }, skip: url.isEmpty);

  test('SignalR broadcasts table names between two clients', () async {
    final config = const ServerConfig(serverUrl: url, jwtToken: String.fromEnvironment('SYNC_TEST_TOKEN'));
    final first = WebSocketChannel.connect(Uri.parse('${config.signalRHubWsUrl}?access_token=${config.jwtToken}'));
    final second = WebSocketChannel.connect(Uri.parse('${config.signalRHubWsUrl}?access_token=${config.jwtToken}'));
    final received = Completer<DatabaseChangedEvent>();
    final handshake = Completer<void>();
    final subscription = second.stream.listen((raw) {
      for (final frame in raw.toString().split('\u001e')) {
        if (frame.trim().isEmpty) continue;
        final data = jsonDecode(frame) as Map<String, dynamic>;
        if (data.isEmpty && !handshake.isCompleted) handshake.complete();
        if (data['target'] == 'DatabaseChanged' && !received.isCompleted) {
          received.complete(
            DatabaseChangedEvent.fromJson(
              Map<String, dynamic>.from(
                (data['arguments'] as List).first as Map,
              ),
            ),
          );
        }
      }
    });
    final firstHandshake = Completer<void>();
    final firstSub = first.stream.listen((raw) {
      if (raw.toString().contains('{}') && !firstHandshake.isCompleted) {
        firstHandshake.complete();
      }
    });
    try {
      await Future.wait([first.ready, second.ready]);
      for (final socket in [first, second]) {
        socket.sink.add(
          '${jsonEncode({'protocol': 'json', 'version': 1})}\u001e',
        );
      }
      await Future.wait([
        handshake.future,
        firstHandshake.future,
      ]).timeout(const Duration(seconds: 8));
      first.sink.add(
        '${jsonEncode({
          'type': 1,
          'target': 'NotifyTablesChanged',
          'arguments': [
            ['Persons', 'Coming'],
            'contract-test',
          ],
        })}\u001e',
      );
      final event = await received.future.timeout(const Duration(seconds: 8));
      expect(event.tables, ['persons', 'coming']);
      expect(event.sourceDeviceId, 'contract-test');
    } finally {
      await firstSub.cancel();
      await subscription.cancel();
      await first.sink.close();
      await second.sink.close();
    }
  }, skip: url.isEmpty);
}
