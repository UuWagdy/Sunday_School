import 'dart:async';

import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/screens/person_dialog.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _Auth extends AuthService {
  @override
  FutureOr<User?> build() => null;
}

class _FailedIdCheck extends d.QueryInterceptor {
  int checks = 0;
  @override
  Future<List<Map<String, Object?>>> runSelect(
    d.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('AS id_exists')) {
      checks++;
      throw StateError('simulated disconnected server');
    }
    return executor.runSelect(statement, args);
  }
}

void main() {
  testWidgets('a failed ID check reports the error and allows saving again', (
    tester,
  ) async {
    final failures = _FailedIdCheck();
    final db = AppDatabase.forTesting(
      NativeDatabase.memory().interceptWith(failures),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
        ],
        child: const MaterialApp(home: Scaffold(body: PersonDialog())),
      ),
    );
    await tester.pumpAndSettle();
    final name = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.prefixIcon is Icon &&
          (w.decoration!.prefixIcon! as Icon).icon == Icons.person_outline,
    );
    await tester.enterText(name, 'شخص جديد');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final add = find.widgetWithText(ElevatedButton, 'إضافة');
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('simulated disconnected server'),
      findsOneWidget,
    );
    expect(tester.widget<ElevatedButton>(add).onPressed, isNotNull);
    expect(failures.checks, 1);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(failures.checks, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
