import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/screens/attendance_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  testWidgets('code attendance and checkout all work without any services', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            personId: const d.Value(101),
            personName: const d.Value('مخدوم للاختبار'),
          ),
        );
    await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            personId: const d.Value(102),
            personName: const d.Value('مخدوم غائب'),
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
        ],
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final code = find.byWidgetPredicate(
      (w) =>
          w is TextField && w.decoration?.hintText == 'اكتب الكود أو الاسم...',
    );
    await tester.enterText(code, '101');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final rows = await db.select(db.coming).get();
    expect(
      rows,
      hasLength(1),
      reason: 'Success must represent a saved attendance row',
    );
    expect(rows.single.personId, 101);
    expect(rows.single.serviceId, isNull);
    expect(rows.single.attendTime, isNotEmpty);
    expect(rows.single.checkoutTime, isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AttendanceScreen)),
    );
    final repo = container.read(attendanceRepositoryProvider.notifier);
    final summary = await repo.fetchAttendanceSummary(
      dateFrom: DateTime.now(),
      dateTo: DateTime.now(),
    );
    expect(summary, {'total': 2, 'present': 1, 'absent': 1});
    final absent = await repo.fetchAttendance(
      status: 'absent',
      dateFrom: DateTime.now(),
      dateTo: DateTime.now(),
    );
    expect(absent.map((person) => person.personId), [102]);
    await tester.tap(find.text('انصراف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'انصراف الكل'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'انصراف الكل'));
    await tester.pumpAndSettle();
    expect((await db.select(db.coming).get()).single.checkoutTime, isNotEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 250));
    await db.close();
  });
}
