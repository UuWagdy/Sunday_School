import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/screens/person_dialog.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class NameTestAuth extends AuthService { @override Future<User?> build() async=>null; }
void main() {
  testWidgets('typing a new name shows existing similar names without replacing the draft', (tester) async {
    final db=AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.persons).insert(PersonsCompanion.insert(personId:const d.Value(7),personName:const d.Value('أحمد إبراهيم بطرس')));
    await tester.pumpWidget(ProviderScope(overrides:[appDatabaseProvider.overrideWithValue(db),authServiceProvider.overrideWith(NameTestAuth.new)],child:const MaterialApp(home:Scaffold(body:PersonDialog()))));
    await tester.pumpAndSettle();
    final name=find.byWidgetPredicate((w)=>w is TextField && w.decoration?.prefixIcon is Icon && ((w.decoration?.prefixIcon as Icon).icon==Icons.person_outline));
    expect(name,findsOneWidget);
    await tester.enterText(name,'احمد ابراهيم');
    await tester.pump(const Duration(milliseconds:300));
    await tester.pumpAndSettle();
    expect(find.text('أحمد إبراهيم بطرس'),findsOneWidget);
    expect(find.textContaining('أسماء مشابهة مسجلة بالفعل'),findsOneWidget);
    final controller=tester.widget<TextField>(name).controller!;
    expect(controller.text,'احمد ابراهيم');
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
