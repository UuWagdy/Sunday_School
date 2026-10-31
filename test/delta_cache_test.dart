import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/screens/attendance_screen.dart';
import 'package:petros_pols_flutter/screens/persons_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';
import 'package:petros_pols_flutter/sync/person_change_source.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/ui/widgets/multi_select_filter.dart';
import 'package:petros_pols_flutter/utils/delta_page_cache.dart';

class _Auth extends AuthService {
  @override
  FutureOr<User?> build() => null;
}

class _Coordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain, int> build() => {for (final d in DataDomain.values) d: 1};
  void bump(DataDomain d) => state = {...state, d: state[d]! + 1};
}

class _Changes extends PersonChangeSource {
  _Changes() : super(const ServerConfig());
  final history = <Set<int>>[];
  Completer<void>? hold;
  bool fail = false;
  bool resetRequired = false;
  @override
  Future<PersonChanges> read({
    required String? cursor,
    required Iterable<int> knownIds,
    required String domain,
  }) async {
    if (cursor == null) return PersonChanges('${history.length}', null);
    await hold?.future;
    if (fail) throw StateError('temporary disconnect');
    if (resetRequired) return PersonChanges('${history.length}', null);
    return PersonChanges(
      '${history.length}',
      history.skip(int.parse(cursor)).expand((ids) => ids).toSet(),
    );
  }
}

class _Reads extends d.QueryInterceptor {
  void Function()? onComingInsert;
  final rows = <({String sql, List<Object?> args})>[];
  @override
  Future<int> runInsert(
    d.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runInsert(statement, args);
    if (statement.contains('INTO "Coming"')) onComingInsert?.call();
    return result;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    d.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    rows.add((sql: statement, args: List.of(args)));
    return executor.runSelect(statement, args);
  }
}

void main() {
  testWidgets(
    'a deletion fills only the gap at the end of a cached people page',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reads = _Reads();
      final changes = _Changes();
      final db = AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(reads),
      );
      for (var id = 1; id <= 60; id++) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value('Person $id'),
              ),
            );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
            personChangeSourceProvider.overrideWithValue(changes),
          ],
          child: const MaterialApp(home: PersonsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PersonsScreen)),
      );
      reads.rows.clear();
      await (db.delete(db.persons)..where((p) => p.personId.equals(60))).go();
      changes.history.add({60});
      (container.read(dataChangeCoordinatorProvider.notifier) as _Coordinator)
          .bump(DataDomain.people);
      await tester.pumpAndSettle();
      expect(find.text('Person 60'), findsNothing);
      expect(find.text('Person 59'), findsOneWidget);
      final queries = reads.rows
          .where(
            (r) =>
                r.sql.contains('"Persons"."Person_Name"') &&
                r.sql.contains('JOIN'),
          )
          .toList();
      expect(queries.length, 2);
      expect(queries.first.sql, contains('"Persons"."Person_ID" IN'));
      expect(queries.first.args, contains(60));
      expect(queries.last.sql, contains('OFFSET'));
      expect(
        queries.last.sql,
        contains('LIMIT 1 OFFSET 49'),
        reason: 'only one replacement row should be read',
      );
      await tester.pumpWidget(const SizedBox());
      changes.close();
      await db.close();
    },
  );
  testWidgets(
    'saving a code keeps the current page and patches its cached attendance',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reads = _Reads();
      final changes = _Changes();
      final db = AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(reads),
      );
      await db.customStatement(
        'INSERT INTO "Services" ("Service_ID","Service_Name","Day_Of_Week") VALUES (101,?,?)',
        ['Fixture service', DateTime.now().weekday],
      );
      for (final id in [1, 2]) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value('Cached person $id'),
              ),
            );
        await db.customStatement(
          'INSERT INTO "Person_Services" ("Person_ID","Service_ID") VALUES (?,101)',
          [id],
        );
      }
      await db
          .into(db.coming)
          .insert(
            ComingCompanion.insert(
              id: const d.Value(1),
              personId: const d.Value(1),
              serviceId: const d.Value(101),
              dateWeek: d.Value(
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
              ),
              attendTime: const d.Value('09:00'),
            ),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
            personChangeSourceProvider.overrideWithValue(changes),
          ],
          child: const MaterialApp(home: AttendanceScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final service = find.byWidgetPredicate(
        (w) => w is MultiSelectFilter && w.label == 'الخدمات للتحضير والفلترة',
      );
      tester.widget<MultiSelectFilter>(service).onChanged([101]);
      await tester.pumpAndSettle();
      expect(find.text('Cached person 1'), findsOneWidget);
      reads.rows.clear();
      changes.hold = Completer<void>();
      reads.onComingInsert = () => changes.history.add({2});
      final code = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'اكتب الكود أو الاسم...',
      );
      tester.widget<TextField>(code).onSubmitted!('2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        changes.history,
        isNotEmpty,
        reason: 'the code must actually be saved',
      );
      expect(find.text('Cached person 1'), findsOneWidget);
      for (final indicator
          in find.byType(CircularProgressIndicator).evaluate()) {
        expect(
          tester.getSize(find.byWidget(indicator.widget)).width,
          lessThanOrEqualTo(20),
          reason: 'only the small save-button indicator may be visible',
        );
      }
      changes.hold!.complete();
      changes.hold = null;
      await tester.pumpAndSettle();
      expect(find.text('Cached person 1'), findsOneWidget);
      expect(find.text('Cached person 2'), findsOneWidget);
      final data = reads.rows.where(
        (r) =>
            r.sql.contains('LEFT OUTER JOIN "Coming"') &&
            r.sql.contains('"Persons"."Person_Name"'),
      );
      expect(data, isNotEmpty);
      expect(
        data.every(
          (r) =>
              r.sql.contains('"Persons"."Person_ID" IN') && r.args.contains(2),
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      changes.close();
      await db.close();
    },
  );
  test(
    'sorted delta retains unchanged identities and excludes unseen later pages',
    () {
      final first = (id: 9, name: 'first');
      final next = mergeChangedPrefix(
        cached: [first, (id: 8, name: 'old'), (id: 7, name: 'deleted')],
        changed: [
          (id: 10, name: 'new'),
          (id: 8, name: 'updated'),
          (id: 1, name: 'later'),
        ],
        changedIds: {10, 8, 7, 1},
        idOf: (p) => p.id,
        compare: (a, b) => b.id.compareTo(a.id),
        hasMore: true,
      );
      expect(next.map((p) => p.id), [10, 9, 8]);
      expect(identical(next[1], first), isTrue);
      expect(next.last.name, 'updated');
    },
  );

  test(
    'change transport sends its cursor; errors keep retry possible; old servers fall back once',
    () async {
      final requests = <Map<String, dynamic>>[];
      var status = 200;
      final source = PersonChangeSource(
        const ServerConfig(isServerMode: true, jwtToken: 'fixture'),
        client: MockClient((request) async {
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          expect(request.headers['Authorization'], 'Bearer fixture');
          return http.Response(
            jsonEncode({
              'cursor': 'next',
              'personIds': [2],
              'resetRequired': false,
            }),
            status,
          );
        }),
      );
      addTearDown(source.close);
      final response = await source.read(
        cursor: 'previous',
        knownIds: [1, 2],
        domain: 'attendance',
      );
      expect(response.personIds, {2});
      expect(requests.single['cursor'], 'previous');
      expect(requests.single['knownPersonIds'], [1, 2]);
      status = 503;
      await expectLater(
        source.read(cursor: 'previous', knownIds: [1], domain: 'people'),
        throwsA(isA<http.ClientException>()),
      );
      status = 200;
      expect(
        (await source.read(
          cursor: 'previous',
          knownIds: [1],
          domain: 'people',
        )).personIds,
        {2},
      );
      status = 404;
      expect(
        (await source.read(
          cursor: null,
          knownIds: [],
          domain: 'people',
        )).personIds,
        isNull,
      );
      final count = requests.length;
      await source.read(cursor: null, knownIds: [], domain: 'people');
      expect(requests.length, count);
    },
  );

  for (final attendance in [false, true]) {
    testWidgets(
      '${attendance ? 'attendance' : 'people'} keeps rows during sync, applies only delta and recovers a failed refresh',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reads = _Reads();
        final changes = _Changes();
        final db = AppDatabase.forTesting(
          NativeDatabase.memory().interceptWith(reads),
        );
        for (final id in [1, 2]) {
          await db
              .into(db.persons)
              .insert(
                PersonsCompanion.insert(
                  personId: d.Value(id),
                  personName: d.Value('Cached person $id'),
                ),
              );
          if (attendance) {
            await db
                .into(db.coming)
                .insert(
                  ComingCompanion.insert(
                    id: d.Value(id),
                    personId: d.Value(id),
                    dateWeek: d.Value(
                      DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    ),
                    attendTime: const d.Value('09:00'),
                  ),
                );
          }
        }
        final screen = attendance
            ? const AttendanceScreen()
            : const PersonsScreen();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              authServiceProvider.overrideWith(_Auth.new),
              dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
              personChangeSourceProvider.overrideWithValue(changes),
            ],
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byWidget(screen)),
        );
        final coordinator =
            container.read(dataChangeCoordinatorProvider.notifier)
                as _Coordinator;
        final domain = attendance ? DataDomain.attendance : DataDomain.people;
        expect(find.text('Cached person 1'), findsOneWidget);
        expect(find.text('Cached person 2'), findsOneWidget);
        reads.rows.clear();
        changes.hold = Completer<void>();
        await (db.update(db.persons)..where((p) => p.personId.equals(1))).write(
          const PersonsCompanion(personName: d.Value('Delta person 1')),
        );
        changes.history.add({1});
        coordinator.bump(domain);
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('Cached person 1'), findsOneWidget);
        expect(find.text('Cached person 2'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        changes.hold!.complete();
        changes.hold = null;
        await tester.pumpAndSettle();
        expect(find.text('Delta person 1'), findsOneWidget);
        expect(find.text('Cached person 2'), findsOneWidget);
        final dataQueries = reads.rows.where(
          (r) =>
              r.sql.contains('"Persons"."Person_Name"') &&
              r.sql.contains('JOIN'),
        );
        expect(dataQueries, isNotEmpty);
        expect(
          dataQueries.every(
            (r) =>
                r.sql.contains('"Persons"."Person_ID" IN') &&
                r.args.contains(1),
          ),
          isTrue,
          reason:
              'row fetches must be restricted to changed people: ${dataQueries.map((r) => r.sql)}',
        );
        reads.rows.clear();
        coordinator.bump(domain);
        await tester.pumpAndSettle();
        expect(
          reads.rows.where(
            (r) =>
                r.sql.contains('"Persons"."Person_Name"') &&
                r.sql.contains('JOIN'),
          ),
          isEmpty,
        );
        changes.fail = true;
        changes.history.add({1});
        coordinator.bump(domain);
        await tester.pumpAndSettle();
        expect(find.text('Delta person 1'), findsOneWidget);
        changes.fail = false;
        if (attendance) {
          await (db.delete(db.coming)..where((p) => p.personId.equals(1))).go();
        } else {
          await (db.delete(
            db.persons,
          )..where((p) => p.personId.equals(1))).go();
        }
        coordinator.bump(domain);
        await tester.pumpAndSettle();
        expect(find.text('Delta person 1'), findsNothing);
        expect(find.text('Cached person 2'), findsOneWidget);
        changes.resetRequired = true;
        changes.hold = Completer<void>();
        await (db.update(db.persons)..where((p) => p.personId.equals(2))).write(
          const PersonsCompanion(personName: d.Value('After reconnect')),
        );
        coordinator.bump(domain);
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('Cached person 2'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        changes.hold!.complete();
        changes.hold = null;
        await tester.pumpAndSettle();
        expect(find.text('After reconnect'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        changes.close();
        await db.close();
      },
    );
  }

  test(
    'autocomplete reuses its index and fetches only changed codes',
    () async {
      final reads = _Reads();
      final db = AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(reads),
      );
      final source = _Changes();
      for (var id = 1; id <= 3; id++) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value('Person $id'),
              ),
            );
      }
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
          dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
          personChangeSourceProvider.overrideWithValue(source),
        ],
      );
      final subscription = container.listen(
        personsRepositoryProvider,
        (_, _) {},
      );
      final before = await container.read(personsRepositoryProvider.future);
      await (db.update(db.persons)..where((p) => p.personId.equals(2))).write(
        const PersonsCompanion(personName: d.Value('Changed')),
      );
      source.history.add({2});
      reads.rows.clear();
      (container.read(dataChangeCoordinatorProvider.notifier) as _Coordinator)
          .bump(DataDomain.people);
      await container.pump();
      final after = await container.read(personsRepositoryProvider.future);
      expect(after.map((p) => p.name), ['Person 3', 'Changed', 'Person 1']);
      expect(identical(before.first, after.first), isTrue);
      expect(reads.rows.single.sql, contains('IN (?)'));
      expect(reads.rows.single.args, contains(2));
      subscription.close();
      container.dispose();
      source.close();
      await db.close();
    },
  );
}
