import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/person_change_source.dart';

void main() {
  for (final status in [401, 403]) {
    test('HTTP $status clears a session only when authentication expired', () async {
      var expired = false;
      final executor = DotNetPostgresQueryExecutor(
        getConfig: () => const ServerConfig(),
        onUnauthorized: () => expired = true,
        httpClient: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(executor.close);
      await expectLater(executor.runSelect('SELECT 1', []), throwsException);
      expect(expired, status == 401);
    });
    test('change feed HTTP $status preserves permission failures', () async {
      var expired = false;
      final source = PersonChangeSource(
        const ServerConfig(isServerMode: true),
        onUnauthorized: () => expired = true,
        client: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(source.close);
      await expectLater(source.read(cursor: null, knownIds: [], domain: 'people'), throwsException);
      expect(expired, status == 401);
    });
  }
}
