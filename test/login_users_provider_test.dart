import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';

class _Config extends ServerConfigNotifier {
  _Config(this.initial);
  final ServerConfig initial;
  @override
  ServerConfig build() => initial;
  void replace(ServerConfig config) => state = config;
}

void main() {
  test(
    'login users ignore JWT changes and reload when the server changes',
    () async {
      final servers = <HttpServer>[];
      final counts = [0, 0];
      for (var i = 0; i < 2; i++) {
        final index = i;
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        servers.add(server);
        server.listen((request) async {
          counts[index]++;
          expect(request.uri.path, '/api/auth/users');
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode([
              {'id': index + 1, 'username': 'user$index'},
            ]),
          );
          await request.response.close();
        });
      }
      final config = _Config(
        ServerConfig(
          isServerMode: true,
          serverUrl: 'http://127.0.0.1:${servers[0].port}',
        ),
      );
      final container = ProviderContainer(
        overrides: [serverConfigProvider.overrideWith(() => config)],
      );
      final subscription = container.listen(allUsersProvider, (_, _) {});
      try {
        expect(
          (await container.read(allUsersProvider.future)).single.username,
          'user0',
        );
        config.replace(
          container.read(serverConfigProvider).copyWith(jwtToken: 'new-token'),
        );
        await container.pump();
        await container.read(allUsersProvider.future);
        expect(counts, [1, 0]);
        config.replace(
          container
              .read(serverConfigProvider)
              .copyWith(serverUrl: 'http://127.0.0.1:${servers[1].port}'),
        );
        expect(
          (await container.read(allUsersProvider.future)).single.username,
          'user1',
        );
        expect(counts, [1, 1]);
      } finally {
        subscription.close();
        container.dispose();
        for (final server in servers) {
          await server.close(force: true);
        }
      }
    },
  );
}
