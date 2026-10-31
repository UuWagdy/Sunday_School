import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/bus_repository.dart';
import 'package:petros_pols_flutter/repositories/tayo_repository.dart';
import 'package:petros_pols_flutter/screens/buses_screen.dart';
import 'package:petros_pols_flutter/screens/tayo_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _Coordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain, int> build() => {for (final d in DataDomain.values) d: 1};
  void bump(DataDomain d) => state = {...state, d: state[d]! + 1};
}

class _Buses extends BusRepository {
  int calls = 0;
  Completer<List<BusStudentDTO>>? delayed;
  @override
  AsyncValue<List<BusDriverDTO>> build() =>
      const AsyncData([BusDriverDTO(id: 1, name: 'Fixture driver')]);
  @override
  Future<List<BusStudentDTO>> fetchStudentsForDriver(
    int id, {
    DateTime? date,
  }) async {
    calls++;
    if (delayed != null) return delayed!.future;
    return [
      BusStudentDTO(
        assignmentId: 1,
        driverId: 1,
        personId: 1,
        personName: 'Existing student',
      ),
    ];
  }
}

class _Tayo extends TayoRepository {
  int calls = 0;
  bool? lastAttendance;
  List<PersonPointsDTO> rows = [];
  @override
  FutureOr<List<TayoCardDTO>> build() => [];
  @override
  Future<List<PersonPointsDTO>> getPointsReport({
    int? stageId,
    int? areaId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool ascending = false,
    bool includeAttendance = false,
    List<int>? attendanceServiceIds,
  }) async {
    calls++;
    lastAttendance = includeAttendance;
    return rows;
  }
}

void main() {
  testWidgets(
    'bus revisions fetch once and keep the current table without a spinner',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final buses = _Buses();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
            busRepositoryProvider.overrideWith(() => buses),
          ],
          child: const MaterialApp(home: BusesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(buses.calls, 1);
      expect(find.text('Existing student'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BusesScreen)),
      );
      final pending = Completer<List<BusStudentDTO>>();
      buses.delayed = pending;
      (container.read(dataChangeCoordinatorProvider.notifier) as _Coordinator)
          .bump(DataDomain.buses);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(buses.calls, 2);
      expect(find.text('Existing student'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pending.complete([
        BusStudentDTO(
          assignmentId: 2,
          driverId: 1,
          personId: 2,
          personName: 'Refreshed student',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Refreshed student'), findsOneWidget);
      expect(buses.calls, 2);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );

  testWidgets(
    'empty Tayo report refreshes from Coming using executed attendance option',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final tayo = _Tayo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
            dataChangeCoordinatorProvider.overrideWith(_Coordinator.new),
            tayoRepositoryProvider.overrideWith(() => tayo),
          ],
          child: const MaterialApp(home: Scaffold(body: TayoScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('التقارير'));
      await tester.pumpAndSettle();
      final include = find.byType(SwitchListTile).last;
      await tester.tap(include);
      await tester.pump();
      await tester.tap(find.text('بحث').last);
      await tester.pumpAndSettle();
      expect(tayo.calls, 1);
      expect(tayo.lastAttendance, true);
      // Changing a draft option must not silently change the last executed report.
      await tester.tap(include);
      await tester.pump();
      tayo.rows = [
        PersonPointsDTO(
          personId: 1,
          personName: 'New attendance result',
          totalPoints: 4,
          tayoPoints: 0,
          attendancePoints: 4,
          redeemedPoints: 0,
          netPoints: 4,
          cardPoints: {},
        ),
      ];
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TayoScreen)),
      );
      (container.read(dataChangeCoordinatorProvider.notifier) as _Coordinator)
          .bump(DataDomain.attendance);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(tayo.calls, 2);
      expect(tayo.lastAttendance, true);
      expect(find.text('New attendance result'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );
}
