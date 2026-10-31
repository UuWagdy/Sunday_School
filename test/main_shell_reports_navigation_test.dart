import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/main.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _ReportsUser extends AuthService {
  @override
  Future<User?> build() async =>
      User(id: 1, username: 'test', canReports: true, canPersons: true);
}

void main() {
  testWidgets(
    'desktop navigation keeps analytics and removes duplicate reports',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_ReportsUser.new),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      final labels = rail.destinations
          .map((d) => (d.label as Text).data)
          .toList();
      expect(labels.first, 'التقارير والتحليلات');
      expect(labels, isNot(contains('التقارير')));
      expect(labels, contains('الأشخاص'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
