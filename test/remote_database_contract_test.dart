import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:drift/backends.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';

void main() {
  late DotNetPostgresQueryExecutor executor;
  late List<http.Request> requests;
  late Map<String, dynamic> response;

  setUp(() {
    requests = [];
    response = {'rows': []};
    executor = DotNetPostgresQueryExecutor(
      getConfig: () => const ServerConfig(),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
  });
  tearDown(() => executor.close());

  test('query parameters follow the server typed params contract', () async {
    await executor.runSelect('SELECT ?, ?, ?, ?, ?, ?, ?', [
      42,
      'اسم عربي',
      null,
      true,
      1.5,
      Uint8List.fromList([1, 2, 3]),
      DateTime(2026, 10, 16),
    ]);
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body.containsKey('args'), isFalse);
    expect(body['params'], [
      {'type': 'int', 'value': 42},
      {'type': 'string', 'value': 'اسم عربي'},
      {'type': 'null', 'value': null},
      {'type': 'int', 'value': 1},
      {'type': 'double', 'value': 1.5},
      {'type': 'bytes', 'value': 'AQID'},
      {'type': 'string', 'value': '2026-10-16T00:00:00.000'},
    ]);
  });

  test(
    'insert returns the generated server id, not the affected row count',
    () async {
      response = {'lastInsertId': 125, 'rowsAffected': 1};
      expect(
        await executor.runInsert('INSERT INTO Persons DEFAULT VALUES', []),
        125,
      );
    },
  );

  test('all write methods bind parameters', () async {
    response = {'lastInsertId': 12, 'rowsAffected': 1};
    await executor.runInsert('INSERT INTO Settings VALUES (?, ?)', [
      'key',
      'value',
    ]);
    await executor.runUpdate('UPDATE Settings SET Value = ?', ['value']);
    await executor.runDelete('DELETE FROM Settings WHERE Key = ?', ['key']);
    await executor.runCustom('SELECT ?', [1]);
    for (final request in requests) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['params'], isNotEmpty);
      expect(body.containsKey('args'), isFalse);
    }
  });

  test(
    'batch sends every argument set in the shape the server executes',
    () async {
      await executor.runBatched(
        BatchedStatements(
          ['INSERT INTO Settings VALUES (?, ?)'],
          [
            ArgumentsForBatchedStatement(0, ['one', '1']),
            ArgumentsForBatchedStatement(0, ['two', '2']),
          ],
        ),
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      final statements = body['statements'] as List;
      expect(statements, hasLength(2));
      expect(statements[0]['argSets'], [
        [
          {'type': 'string', 'value': 'one'},
          {'type': 'string', 'value': '1'},
        ],
      ]);
      expect(statements[1]['argSets'], [
        [
          {'type': 'string', 'value': 'two'},
          {'type': 'string', 'value': '2'},
        ],
      ]);
    },
  );

  test(
    'server rows preserve aliases, binary fields and SQLite boolean values',
    () async {
      response = {
        'rows': [
          {
            'Person_ID': 12,
            'Persons.Person_Name': 'اسم',
            'Photo': {'__type': 'bytes', 'base64': 'AQID'},
            'Enabled': true,
          },
        ],
      };
      final row = (await executor.runSelect(
        'SELECT * FROM Persons',
        [],
      )).single;
      expect(row['person_id'], 12);
      expect(row['persons.person_name'], 'اسم');
      expect(row['photo'], [1, 2, 3]);
      expect(row['enabled'], 1);
    },
  );

  test('sync events use affectedTables from the server', () {
    final event = DatabaseChangedEvent.fromJson({
      'affectedTables': ['Persons', 'Coming'],
      'sourceDeviceId': 'another-device',
      'operation': 'INSERT',
      'timestampUtc': '2026-10-16T12:00:00Z',
    });
    expect(event.tables, ['persons', 'coming']);
    expect(event.sourceDeviceId, 'another-device');
  });

  test(
    'the read cache evicts old queries after reaching its entry limit',
    () async {
      response = {'cacheTag': 'tag', 'rows': []};
      for (var id = 0; id < 257; id++) {
        await executor.runSelect('SELECT * FROM Persons WHERE Person_ID=?', [
          id,
        ]);
      }
      await executor.runSelect('SELECT * FROM Persons WHERE Person_ID=?', [
        256,
      ]);
      expect(jsonDecode(requests.last.body)['cacheTag'], 'tag');
      await executor.runSelect('SELECT * FROM Persons WHERE Person_ID=?', [0]);
      expect(jsonDecode(requests.last.body).containsKey('cacheTag'), isFalse);
    },
  );

  test('transaction reads never send or reuse a read cache tag', () async {
    final bodies = <Map<String, dynamic>>[];
    final remote = DotNetPostgresQueryExecutor(
      getConfig: () => const ServerConfig(),
      transactionId: 'fixture-transaction',
      httpClient: MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({'cacheTag': 'ignored', 'rows': []}),
          200,
        );
      }),
    );
    addTearDown(remote.close);
    await remote.runSelect('SELECT * FROM Persons', []);
    await remote.runSelect('SELECT * FROM Persons', []);
    expect(
      bodies.every(
        (b) => !b.containsKey('acceptCache') && !b.containsKey('cacheTag'),
      ),
      isTrue,
    );
  });

  test(
    'unchanged reads use the verified cache and callers cannot corrupt its rows',
    () async {
      response = {
        'cacheTag': 'snapshot-1',
        'rows': [
          {
            'Person_ID': 12,
            'Photo': {'__type': 'bytes', 'base64': 'AQID'},
          },
        ],
      };
      final first = await executor.runSelect('SELECT * FROM Persons', []);
      first.single['person_id'] = 999;
      (first.single['photo'] as Uint8List)[0] = 99;
      response = {'cacheTag': 'snapshot-1', 'notModified': true, 'rows': []};
      final cached = await executor.runSelect('SELECT * FROM Persons', []);
      expect(cached.single['person_id'], 12);
      expect(cached.single['photo'], [1, 2, 3]);
      expect(jsonDecode(requests.last.body)['cacheTag'], 'snapshot-1');
      response = {
        'cacheTag': 'snapshot-2',
        'rows': [
          {'Person_ID': 13},
        ],
      };
      expect(
        (await executor.runSelect(
          'SELECT * FROM Persons',
          [],
        )).single['person_id'],
        13,
      );
    },
  );

  test('a changed account starts with an empty read cache', () async {
    var config = const ServerConfig(jwtToken: 'first-account');
    final bodies = <Map<String, dynamic>>[];
    final remote = DotNetPostgresQueryExecutor(
      getConfig: () => config,
      httpClient: MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(jsonEncode({'cacheTag': 'tag', 'rows': []}), 200);
      }),
    );
    addTearDown(remote.close);
    await remote.runSelect('SELECT * FROM Persons', []);
    await remote.runSelect('SELECT * FROM Persons', []);
    config = config.copyWith(jwtToken: 'second-account');
    await remote.runSelect('SELECT * FROM Persons', []);
    expect(bodies[1]['cacheTag'], 'tag');
    expect(bodies[2].containsKey('cacheTag'), isFalse);
  });

  test(
    'simultaneous identical reads share one request but have separate row maps',
    () async {
      final hold = Completer<void>();
      var count = 0;
      final remote = DotNetPostgresQueryExecutor(
        getConfig: () => const ServerConfig(),
        httpClient: MockClient((request) async {
          count++;
          await hold.future;
          return http.Response(
            jsonEncode({
              'cacheTag': 'tag',
              'rows': [
                {'id': 1},
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(remote.close);
      final reads = [
        for (var i = 0; i < 10; i++)
          remote.runSelect('SELECT * FROM Persons', []),
      ];
      hold.complete();
      final values = await Future.wait(reads);
      expect(count, 1);
      values.first.single['id'] = 5;
      expect(values.last.single['id'], 1);
    },
  );
}
