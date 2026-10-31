import 'dart:async';

import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/main.dart';
import 'package:petros_pols_flutter/repositories/fields_repository.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/screens/attendance_screen.dart';
import 'package:petros_pols_flutter/screens/buses_screen.dart';
import 'package:petros_pols_flutter/screens/persons_screen.dart';
import 'package:petros_pols_flutter/screens/users_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';
import 'package:petros_pols_flutter/widgets/dashboard/stat_cards_grid.dart';

class _Auth extends AuthService {
  User user({bool buses = false}) => User(
    id: 7,
    username: 'fixture',
    canPersons: true,
    canUsers: true,
    canAbsence: true,
    canReports: true,
    isAdvanced: true,
    granularPermissions: buses
        ? {
            'buses': {'add': true},
          }
        : {},
  );
  @override
  FutureOr<User?> build() => user();
  @override
  Future<void> refreshUser() async {}
  void allowBuses() => state = AsyncData(user(buses: true));
}

class _Coordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain, int> build() => {for (final d in DataDomain.values) d: 1};
}

class _Settings extends SettingsRepository {
  _Settings(super.db);
  Completer<String>? pending;
  @override
  Future<String> getProgramName() async =>
      pending == null ? 'مدرسة الاختبار' : pending!.future;
}

class _Fields extends FieldsRepository {
  Completer<List<FieldConfigDTO>>? pending;
  final rows = [
    FieldConfigDTO(
      id: 1,
      fieldKey: 'khoros',
      name: 'الخورس',
      type: 'native',
      options: [],
      order: 0,
      isVisible: true,
      isFilter: false,
      isPhone: false,
    ),
  ];
  @override
  FutureOr<List<FieldConfigDTO>> build() => pending?.future ?? rows;
}

class _Reads extends d.QueryInterceptor {
  final sql = <String>[];
  @override
  Future<List<Map<String, Object?>>> runSelect(
    d.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    sql.add(statement);
    return executor.runSelect(statement, args);
  }
}

void main() {
  late AppDatabase db;
  late _Reads reads;
  setUp(() async {
    reads = _Reads();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(reads));
    await db
        .into(db.pass)
        .insert(
          PassCompanion.insert(
            passId: const d.Value(7),
            personName: const d.Value('fixture'),
            passWord: const d.Value('fixture-only'),
            canPersons: const d.Value(true),
            canUsers: const d.Value(true),
          ),
        );
  });
  tearDown(() async => db.close());

  testWidgets(
    'startup mounts only the selected tab; bus access is explicit and title stays stable',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = _Settings(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            settingsRepositoryProvider.overrideWithValue(settings),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      List<String?> labels() => tester
          .widget<NavigationRail>(find.byType(NavigationRail))
          .destinations
          .map((d) => (d.label as Text).data)
          .toList();
      expect(labels(), isNot(contains('الاتوبيسات')));
      expect(find.byType(PersonsScreen, skipOffstage: false), findsNothing);
      expect(find.byType(UsersScreen, skipOffstage: false), findsNothing);
      expect(find.byType(AttendanceScreen, skipOffstage: false), findsNothing);
      expect(find.byType(StatCardsGrid, skipOffstage: false), findsNothing);
      final root = ProviderScope.containerOf(
        tester.element(find.byType(MyApp)),
      );
      settings.pending = Completer<String>();
      root.invalidate(programNameProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('مدرسة الاختبار'), findsWidgets);
      expect(find.text(SettingsRepository.defaultProgramName), findsNothing);
      settings.pending!.complete('الاسم المحدث');
      await tester.pumpAndSettle();
      expect(find.text('الاسم المحدث'), findsWidgets);
      (root.read(authServiceProvider.notifier) as _Auth).allowBuses();
      await tester.pumpAndSettle();
      expect(labels(), contains('الاتوبيسات'));
      expect(find.byType(BusesScreen, skipOffstage: false), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      rail.onDestinationSelected!(labels().indexOf('الأشخاص'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonsScreen), findsOneWidget);
      expect(find.byType(UsersScreen, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('khoros stays visible while field settings refresh', (
    tester,
  ) async {
    final fields = _Fields();
    await db
        .into(db.khoroses)
        .insert(
          KhorosesCompanion.insert(
            khorosId: const d.Value(5),
            khorosName: const d.Value('خورس الاختبار'),
          ),
        );
    await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            personId: const d.Value(1),
            personName: const d.Value('شخص الاختبار'),
            khorosId: const d.Value(5),
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
          fieldsRepositoryProvider.overrideWith(() => fields),
          dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
        ],
        child: const MaterialApp(home: PersonsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('خورس الاختبار'), findsOneWidget);
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(PersonsScreen)),
    );
    fields.pending = Completer<List<FieldConfigDTO>>();
    scope.invalidate(fieldsRepositoryProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('خورس الاختبار'), findsOneWidget);
    fields.pending!.complete(fields.rows);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'editing permission chips does no reads and buses round-trip through save and revoke',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
          ],
          child: const MaterialApp(home: Scaffold(body: UsersScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads.sql.where((s) => s.contains('AS scope_type')), hasLength(1));
      reads.sql.clear();
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      final buses = find.widgetWithText(FilterChip, 'الاتوبيسات');
      expect(tester.widget<FilterChip>(buses).selected, isFalse);
      tester.widget<FilterChip>(buses).onSelected!(true);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(buses).selected, isTrue);
      expect(reads.sql, isEmpty);
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'حفظ التعديلات'),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      var permission =
          await (db.select(db.userPermissionsExt)..where(
                (p) => p.userId.equals(7) & p.featureKey.equals('buses'),
              ))
              .getSingleOrNull();
      expect(permission?.canAdd, isTrue);
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(buses).selected, isTrue);
      tester.widget<FilterChip>(buses).onSelected!(false);
      await tester.pump();
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'حفظ التعديلات'),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      permission =
          await (db.select(db.userPermissionsExt)..where(
                (p) => p.userId.equals(7) & p.featureKey.equals('buses'),
              ))
              .getSingleOrNull();
      expect(permission, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
