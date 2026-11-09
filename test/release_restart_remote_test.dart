// Run only through tool/ReleaseRestartTests against its disposable installation.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';
import 'package:petros_pols_flutter/sync/signalr_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _Config extends ServerConfigNotifier {
  _Config(this.config);
  final ServerConfig config;
  @override
  ServerConfig build() => config;
}

Future<void> until(
  FutureOr<bool> Function() predicate,
  String description,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    if (await predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out: $description');
}

void main() {
  const url = String.fromEnvironment('SYNC_TEST_URL');
  const control = String.fromEnvironment('SYNC_RESTART_CONTROL');
  test(
    'two real clients retain cards and attendance through abrupt server restart',
    () async {
      expect(Uri.parse(url).host, '127.0.0.1');
      expect(
        control.replaceAll('\\', '/'),
        contains('/build/restart-verification/'),
      );
      final response = await http.post(
        Uri.parse('$url/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': 'admin', 'password': '1234'}),
      );
      final login = jsonDecode(response.body) as Map<String, dynamic>;
      expect(login['success'], isTrue);
      final token = login['token'] as String;
      SharedPreferences.setMockInitialValues({
        'sync_is_server_mode': true,
        'sync_server_url': url,
        'sync_device_id': 'restart-client-a',
        'sync_jwt_token': token,
      });
      await ServerBootstrap.ensureInitialized();
      final savedConfig = ServerBootstrap.initialConfig;
      ProviderContainer client(ServerConfig config) => ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWith(() => _Config(config)),
          authServiceProvider.overrideWith(_Auth.new),
        ],
      );
      final a = client(savedConfig);
      final b = client(savedConfig.copyWith(deviceId: 'restart-client-b'));
      final subscription = b.listen(
        signalRSyncProvider,
        (_, next) {},
        fireImmediately: true,
      );
      final dbA = a.read(appDatabaseProvider);
      final dbB = b.read(appDatabaseProvider);
      try {
        await until(
          () =>
              a.read(signalRSyncProvider) ==
                  SignalRConnectionStatus.connected &&
              b.read(signalRSyncProvider) == SignalRConnectionStatus.connected,
          'both SignalR clients connect',
        );
        final personId = await dbA
            .into(dbA.persons)
            .insert(
              const PersonsCompanion(
                personName: d.Value('شخص اختبار إعادة التشغيل'),
              ),
            );
        final serviceId = await dbA
            .into(dbA.services)
            .insert(
              const ServicesCompanion(serviceName: d.Value('خدمة الاختبار')),
            );
        await dbA
            .into(dbA.personServices)
            .insert(
              PersonServicesCompanion.insert(
                personId: personId,
                serviceId: serviceId,
              ),
            );
        final error = await a
            .read(attendanceRepositoryProvider.notifier)
            .addAttendance(
              personId: personId,
              dateWeek: '2026-11-06',
              month: 11,
              year: 2026,
              serviceId: serviceId,
              attendTime: '10:00',
              point: 4,
            );
        expect(error, isNull);
        final front = CardTemplate.defaults().copyWith(
          fixedTexts: const [
            CardFixedTextElement(
              text: 'وجه اختبار المزامنة',
              x: .1,
              y: .1,
              width: .5,
            ),
          ],
        );
        final back = front.copyWith(
          fixedTexts: const [
            CardFixedTextElement(
              text: 'ظهر اختبار المزامنة',
              x: .1,
              y: .1,
              width: .5,
            ),
          ],
        );
        final revision = b.read(domainRevisionProvider(DataDomain.settings));
        await a
            .read(settingsRepositoryProvider)
            .saveCardDesign(front: front, back: back, printBack: true);
        await until(
          () => b.read(domainRevisionProvider(DataDomain.settings)) > revision,
          'other device receives committed settings event',
        );
        expect(
          (await b.read(settingsRepositoryProvider).getActiveCardTemplate())
              .toJsonString(),
          front.toJsonString(),
        );
        expect((await dbB.select(dbB.coming).get()).single.attendancePoint, 4);
        var disconnected = false;
        final disconnectSub = b.listen(signalRSyncProvider, (_, state) {
          if (state != SignalRConnectionStatus.connected) disconnected = true;
        });
        await File(control).writeAsString('restart disposable installation');
        await until(
          () =>
              disconnected &&
              b.read(signalRSyncProvider) == SignalRConnectionStatus.connected,
          'automatic reconnect after abrupt process termination',
        );
        disconnectSub.close();
        expect(
          (await b.read(settingsRepositoryProvider).getActiveCardTemplate())
              .toJsonString(),
          front.toJsonString(),
        );
        expect(
          CardTemplate.fromJsonString(
            (await b
                .read(settingsRepositoryProvider)
                .getSetting('id_card_back_template'))!,
          ).toJsonString(),
          back.toJsonString(),
        );
        expect((await dbB.select(dbB.coming).get()).single.attendancePoint, 4);
        expect(
          await b
              .read(settingsRepositoryProvider)
              .getSetting('id_card_print_back'),
          'true',
        );
        await ServerBootstrap.ensureInitialized();
        expect(ServerBootstrap.initialConfig.jwtToken, token);
        expect(ServerBootstrap.initialConfig.serverUrl, url);
        final reopened = client(ServerBootstrap.initialConfig);
        try {
          expect(
            (await reopened
                    .read(settingsRepositoryProvider)
                    .getActiveCardTemplate())
                .toJsonString(),
            front.toJsonString(),
          );
        } finally {
          reopened.dispose();
        }
        final postRestartRevision = a.read(
          domainRevisionProvider(DataDomain.settings),
        );
        await b
            .read(settingsRepositoryProvider)
            .saveCardDesign(front: back, back: front, printBack: false);
        await until(
          () =>
              a.read(domainRevisionProvider(DataDomain.settings)) >
              postRestartRevision,
          'writes still broadcast after recovery',
        );
        expect(
          (await a.read(settingsRepositoryProvider).getActiveCardTemplate())
              .toJsonString(),
          back.toJsonString(),
        );
        final duplicate = await a
            .read(attendanceRepositoryProvider.notifier)
            .addAttendance(
              personId: personId,
              dateWeek: '2026-11-06',
              month: 11,
              year: 2026,
              serviceId: serviceId,
              attendTime: '10:00',
            );
        expect(duplicate, isNotNull);
        expect((await dbB.select(dbB.coming).get()).length, 1);
      } finally {
        subscription.close();
        a.dispose();
        b.dispose();
      }
    },
    skip: url.isEmpty || control.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
