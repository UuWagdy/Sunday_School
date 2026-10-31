// Runs only against the disposable PostgreSQL server in
// tool/test_visibility_server.py. Never point this test at an installed server.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/models/data_visibility_scope.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/dashboard_repository.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/users_repository.dart';
import 'package:petros_pols_flutter/repositories/visitation_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';

class _FixtureAuth extends AuthService {
  @override
  FutureOr<User?> build() => null;
}

class _QuietCoordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain, int> build() => {for (final d in DataDomain.values) d: 1};
}

class _RecordingClient extends http.BaseClient {
  final _inner = http.Client();
  final requests = <Map<String, dynamic>>[];
  int responseBytes = 0;

  void reset() {
    requests.clear();
    responseBytes = 0;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      requests.add({
        'path': request.url.path,
        ...jsonDecode(request.body) as Map<String, dynamic>,
      });
    }
    final response = await _inner.send(request);
    return http.StreamedResponse(
      response.stream.map((chunk) {
        responseBytes += chunk.length;
        return chunk;
      }),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() => _inner.close();
}

void main() {
  const url = String.fromEnvironment('SCOPE_TEST_URL');
  const token = String.fromEnvironment('SCOPE_TEST_ADMIN_TOKEN');
  const workerToken = String.fromEnvironment('SCOPE_TEST_TOKEN');
  final enabled = url.isNotEmpty && token.isNotEmpty;

  AppDatabase database({http.Client? client, bool scoped = false}) {
    return AppDatabase.forTesting(
      DotNetPostgresQueryExecutor(
        getConfig: () => ServerConfig(
          serverUrl: url,
          jwtToken: scoped ? workerToken : token,
        ),
        httpClient: client,
      ),
    )..visibilityContext.applyLocally = false;
  }

  ProviderContainer container(AppDatabase db) => ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authServiceProvider.overrideWith(_FixtureAuth.new),
      dataChangeCoordinatorProvider.overrideWith(_QuietCoordinator.new),
    ],
  );

  test(
    'list reads omit unused images while full person data keeps its photo',
    () async {
      final admin = database();
      final client = _RecordingClient();
      final db = database(client: client, scoped: true);
      final providers = container(db);
      providers.listen(personsRepositoryProvider, (_, next) {});
      addTearDown(() async {
        providers.dispose();
        await db.close();
        await admin.close();
      });
      final image = Uint8List(256 * 1024)..fillRange(0, 256 * 1024, 65);
      await admin.customStatement(
        'UPDATE "Persons" SET "Photo"=? WHERE "Person_ID"=?',
        [image, 201],
      );
      await admin.customStatement(
        'UPDATE "Khoroses" SET "Logo"=? WHERE "Khoros_ID"=?',
        [image, 107],
      );
      await admin.customStatement(
        'UPDATE "Services" SET "Logo"=? WHERE "Service_ID"=?',
        [image, 101],
      );

      final suggestions = await providers.read(
        personsRepositoryProvider.future,
      );
      expect(suggestions.map((p) => p.id), contains(201));
      expect(suggestions.every((p) => p.photo == null), isTrue);
      final suggestionBytes = client.responseBytes;
      expect(suggestionBytes, lessThan(10000));
      client.reset();
      final full = await providers
          .read(personsRepositoryProvider.notifier)
          .fetchPersons(personIds: [201]);
      expect(full.single.photo, image);
      final fullBytes = client.responseBytes;
      expect(fullBytes, greaterThan(256 * 1024));
      expect(full.single.stageName, '5ب');
      expect(full.single.areaName, 'Child');

      await providers.read(attendanceRepositoryProvider.future);
      client.reset();
      final attendance = await providers
          .read(attendanceRepositoryProvider.notifier)
          .fetchAttendance(
            search: '201',
            dateFrom: DateTime(2026, 10, 16),
            dateTo: DateTime(2026, 10, 16),
          );
      expect(attendance.single.personId, 201);
      expect(attendance.single.khorosName, 'K');
      expect(attendance.single.stageName, '5ب');
      final attendanceBytes = client.responseBytes;
      expect(attendanceBytes, lessThan(15000));
      client.reset();
      final visits = await providers
          .read(visitationRepositoryProvider)
          .fetchVisitations(
            search: '201',
            dateFrom: DateTime(2026, 10, 16),
            dateTo: DateTime(2026, 10, 16),
          );
      expect(visits.single.personId, 201);
      expect(visits.single.khorosName, 'K');
      expect(visits.single.stageName, '5ب');
      expect(client.responseBytes, lessThan(15000));
      final visitationBytes = client.responseBytes;
      client.reset();
      final trend = await providers.read(
        generalAttendanceTrendProvider(
          groupBy: 'month',
          filterYear: 2026,
        ).future,
      );
      expect(trend.fold<int>(0, (n, row) => n + row.count), greaterThan(0));
      final trendBytes = client.responseBytes;
      expect(trendBytes, lessThan(5000));
      client.reset();
      final rankings = await providers.read(
        attendanceRankingsProvider(sortCriteria: 'attendance').future,
      );
      expect(rankings, isNotEmpty);
      expect(client.responseBytes, lessThan(5000));
      print(
        'PAYLOAD_BYTES suggestions=$suggestionBytes full_person=$fullBytes '
        'attendance=$attendanceBytes visitation=$visitationBytes '
        'trend=$trendBytes rankings=${client.responseBytes}',
      );
    },
    skip: !enabled,
  );

  test(
    'user list has four reads and permission replacement has one batch',
    () async {
      final client = _RecordingClient();
      final db = database(client: client);
      final providers = container(db);
      providers.listen(usersRepositoryProvider, (_, next) {});
      addTearDown(() async {
        providers.dispose();
        await db.close();
      });
      final users = providers.read(usersRepositoryProvider.notifier);
      await providers.read(usersRepositoryProvider.future);
      final permissions = {
        for (var i = 0; i < 30; i++)
          'fixture-$i': {'add': true, 'edit': false, 'delete': true},
      };
      client.reset();
      expect(
        await users.addUser(
          'performance-fixture',
          'fixture-only',
          granularPermissions: permissions,
          visibilityFilters: {
            'stage': [105, 106],
          },
          dataVisibilityScope: DataVisibilityScope.decode('{"stage":["105"]}'),
        ),
        isTrue,
      );
      expect(
        client.requests.where((r) => r['path'] == '/api/storage/batch'),
        hasLength(1),
      );
      // The explicit invalidate starts a fresh list read. Await it before counting.
      final updated = await providers.read(usersRepositoryProvider.future);
      final user = updated.singleWhere(
        (u) => u.username == 'performance-fixture',
      );
      expect(user.granularPermissions, permissions);
      expect(user.visibilityFilters['stage'], [105, 106]);
      expect(user.dataVisibilityScope.toJson(), {
        'stage': ['105'],
      });
      client.reset();
      providers.invalidate(usersRepositoryProvider);
      await providers.read(usersRepositoryProvider.future);
      expect(client.requests, hasLength(4));
      expect(
        client.requests.every((r) => r['path'] == '/api/storage/query'),
        isTrue,
      );
      client.reset();
      expect(
        await users.updateUser(
          user.id,
          user.username,
          'fixture-only',
          granularPermissions: {
            'attendance': {'add': false, 'edit': true},
          },
          visibilityFilters: {},
        ),
        isTrue,
      );
      expect(
        client.requests.where((r) => r['path'] == '/api/storage/batch'),
        hasLength(1),
      );
      final saved = (await providers.read(
        usersRepositoryProvider.future,
      )).singleWhere((u) => u.id == user.id);
      expect(saved.granularPermissions.keys, ['attendance']);
      expect(saved.granularPermissions['attendance']!['edit'], isTrue);
      expect(saved.visibilityFilters, isEmpty);
    },
    skip: !enabled,
  );

  test(
    'person edits preserve links and batch fields; deletion batches dependent rows',
    () async {
      final client = _RecordingClient();
      final db = database(client: client);
      final providers = container(db);
      providers.listen(personsRepositoryProvider, (_, next) {});
      addTearDown(() async {
        providers.dispose();
        await db.close();
      });
      final people = providers.read(personsRepositoryProvider.notifier);
      await providers.read(personsRepositoryProvider.future);
      final definitions = await (db.select(
        db.customFieldDefinitions,
      )..limit(3)).get();
      final values = {for (final f in definitions) f.id: 'value-${f.id}'};
      client.reset();
      final id = await people.addPerson(
        name: 'mutation-fixture',
        stageId: 105,
        serviceIds: [101],
        customValues: values,
      );
      expect(id, isNotNull);
      expect(
        client.requests.where((r) => r['path'] == '/api/storage/batch'),
        hasLength(2),
      );
      await providers.read(personsRepositoryProvider.future);
      final updatedValues = {definitions.first.id: 'changed'};
      client.reset();
      expect(
        await people.updatePerson(
          id: id!,
          name: 'mutation-updated',
          stageId: 105,
          serviceIds: [101],
          customValues: updatedValues,
        ),
        isTrue,
      );
      expect(
        client.requests.where((r) => r['path'] == '/api/storage/batch'),
        hasLength(2),
      );
      expect(await people.fetchCustomFieldValues(id), updatedValues);
      final updated = await people.fetchPersonById(id);
      expect(updated!.name, 'mutation-updated');
      expect(updated.serviceIds.toSet(), {101, 102});
      await providers.read(personsRepositoryProvider.future);
      client.reset();
      expect(await people.deletePerson(id), isTrue);
      expect(
        client.requests.where((r) => r['path'] == '/api/storage/batch'),
        hasLength(1),
      );
      expect(await people.fetchPersonById(id), isNull);
      expect(await people.fetchCustomFieldValues(id), isEmpty);
      expect(
        await (db.select(
          db.personServices,
        )..where((t) => t.personId.equals(id))).get(),
        isEmpty,
      );
    },
    skip: !enabled,
  );

  test(
    'two devices reserve attendance IDs without a commit rewinding the sequence',
    () async {
      final a = database(), b = database(), c = database();
      addTearDown(() async {
        await a.close();
        await b.close();
        await c.close();
      });
      final reservedA = Completer<int>(), reservedB = Completer<int>();
      final releaseA = Completer<void>(), releaseB = Completer<void>();
      Future<void> reserve(
        AppDatabase db,
        Completer<int> reserved,
        Completer<void> release,
      ) => db.transaction(() async {
        reserved.complete(
          await db
              .into(db.coming)
              .insert(const ComingCompanion(personId: d.Value(201))),
        );
        await release.future;
      });
      final transactionA = reserve(a, reservedA, releaseA);
      final transactionB = reserve(b, reservedB, releaseB);
      try {
        final ids = await Future.wait([reservedA.future, reservedB.future]);
        expect(ids.toSet(), hasLength(2));
        releaseA.complete();
        await transactionA;
        final third = await c
            .into(c.coming)
            .insert(const ComingCompanion(personId: d.Value(201)));
        expect(third, greaterThan(ids.reduce((a, b) => a > b ? a : b)));
      } finally {
        if (!releaseA.isCompleted) releaseA.complete();
        releaseB.complete();
        await Future.wait([transactionA, transactionB]);
      }
      // An explicit smaller ID must not rewind a previously advanced sequence.
      await c.customStatement(
        'INSERT INTO "Persons" ("Person_ID","Person_Name") VALUES (?,?)',
        [30000, 'fixture-high'],
      );
      await c.customStatement('DELETE FROM "Persons" WHERE "Person_ID"=?', [
        30000,
      ]);
      await c.customStatement(
        'INSERT INTO "Persons" ("Person_ID","Person_Name") VALUES (?,?)',
        [29999, 'fixture-low'],
      );
      final next = await c
          .into(c.persons)
          .insert(const PersonsCompanion(personName: d.Value('fixture-next')));
      expect(next, greaterThan(30000));
    },
    skip: !enabled,
  );

  test(
    'attendance saves from two clients use server IDs and one membership read',
    () async {
      final clientA = _RecordingClient(), clientB = _RecordingClient();
      final dbA = database(client: clientA), dbB = database(client: clientB);
      final a = container(dbA), b = container(dbB);
      a.listen(attendanceRepositoryProvider, (_, next) {});
      b.listen(attendanceRepositoryProvider, (_, next) {});
      addTearDown(() async {
        a.dispose();
        b.dispose();
        await dbA.close();
        await dbB.close();
      });
      await Future.wait([
        a.read(attendanceRepositoryProvider.future),
        b.read(attendanceRepositoryProvider.future),
      ]);
      clientA.reset();
      clientB.reset();
      final watch = Stopwatch()..start();
      final results = await Future.wait([
        for (var day = 1; day <= 12; day++) ...[
          a
              .read(attendanceRepositoryProvider.notifier)
              .addAttendance(
                personId: 201,
                serviceId: 101,
                dateWeek: '2099-01-${day.toString().padLeft(2, '0')}',
                month: 1,
                year: 2099,
                attendTime: '10:00',
              ),
          b
              .read(attendanceRepositoryProvider.notifier)
              .addAttendance(
                personId: 204,
                serviceId: 102,
                dateWeek: '2099-01-${day.toString().padLeft(2, '0')}',
                month: 1,
                year: 2099,
                attendTime: '10:00',
              ),
        ],
      ]);
      expect(results.every((r) => r == null), isTrue, reason: '$results');
      final requests = [...clientA.requests, ...clientB.requests];
      expect(requests.length, lessThanOrEqualTo(24 * 3));
      expect(
        requests.where((r) => r['path'] == '/api/storage/insert'),
        hasLength(24),
      );
      expect(
        requests.any((r) => (r['sql'] as String? ?? '').contains('max_id')),
        isFalse,
      );
      final rows = await (dbA.select(
        dbA.coming,
      )..where((t) => t.year1.equals(2099))).get();
      expect(rows, hasLength(24));
      expect(rows.map((r) => r.id).toSet(), hasLength(24));
      print(
        'CONCURRENT_ATTENDANCE saves=24 requests=${requests.length} elapsed_ms=${watch.elapsedMilliseconds}',
      );
    },
    skip: !enabled,
  );
}
