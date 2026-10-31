import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final local in [false, true]) {
    test(
      'switching ${local ? "to local storage" : "servers"} clears the old session',
      () async {
        SharedPreferences.setMockInitialValues({
          'sync_jwt_token': 'old-session',
        });
        ServerBootstrap.initialConfig = const ServerConfig(
          isServerMode: true,
          serverUrl: 'http://old-server:5050',
          jwtToken: 'old-session',
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(serverConfigProvider.notifier)
            .updateSettings(
              isServerMode: !local,
              serverUrl: 'http://new-server:5050',
            );
        expect(container.read(serverConfigProvider).jwtToken, isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('sync_jwt_token'),
          isNull,
        );
      },
    );
  }
  test(
    'saving the same normalized server retains its current session',
    () async {
      SharedPreferences.setMockInitialValues({});
      ServerBootstrap.initialConfig = const ServerConfig(
        isServerMode: true,
        serverUrl: 'http://same-server:5050',
        jwtToken: 'current-session',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(serverConfigProvider.notifier)
          .updateSettings(isServerMode: true, serverUrl: 'same-server:5050/');
      expect(container.read(serverConfigProvider).jwtToken, 'current-session');
    },
  );
  test('fresh install uses the configured server default', () async {
    SharedPreferences.setMockInitialValues({});
    await ServerBootstrap.ensureInitialized();
    final config = ServerBootstrap.initialConfig;
    expect(config.isServerMode, ServerBootstrap.defaultServerUrl.isNotEmpty);
    if (ServerBootstrap.defaultServerUrl.isNotEmpty) {
      expect(config.normalizedBaseUrl, ServerBootstrap.defaultServerUrl);
    }
    expect(config.deviceId, isNotEmpty);
  });

  test(
    'saved connection settings take precedence over installation defaults',
    () async {
      SharedPreferences.setMockInitialValues({
        'sync_is_server_mode': false,
        'sync_server_url': 'https://existing-server.example',
        'sync_device_id': 'saved-device',
      });
      await ServerBootstrap.ensureInitialized();
      expect(ServerBootstrap.initialConfig.isServerMode, isFalse);
      expect(
        ServerBootstrap.initialConfig.serverUrl,
        'https://existing-server.example',
      );
      expect(ServerBootstrap.initialConfig.deviceId, 'saved-device');
    },
  );
}
