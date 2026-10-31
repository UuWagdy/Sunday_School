import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/sync/server_connection_service.dart';

void main() {
  for (final service in ['SundaySchool.SyncServer', 'AbonaFlemoon.SyncServer']) {
    test('connection test checks server identity: $service', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true, 'service': service,
          'status': 'ok', 'database': 'connected'}));
        await request.response.close();
      });
      final container = ProviderContainer();
      try {
        final result = await container.read(serverConfigProvider.notifier)
            .testConnection('http://127.0.0.1:${server.port}');
        expect(result.ok, service == 'SundaySchool.SyncServer');
      } finally {
        container.dispose(); await requests.cancel(); await server.close(force: true);
      }
    });
  }
}
