import 'dart:convert';
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/models/data_visibility_scope.dart';
import 'package:petros_pols_flutter/screens/users_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/ui/widgets/multi_select_filter.dart';

class ScopeAdmin extends AuthService {
  @override Future<User?> build() async=>User(id:1,username:'admin',canUsers:true);
  @override Future<void> refreshUser() async {}
}
void main() {
  testWidgets('seven default-all controls persist a non-advanced user scope', (tester) async {
    final db=AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.services).insert(ServicesCompanion.insert(serviceId:const d.Value(1),serviceName:const d.Value('الخدمة أ')));
    await db.into(db.stages).insert(StagesCompanion.insert(stageId:const d.Value(5),stageName:const d.Value('5ب')));
    await tester.pumpWidget(ProviderScope(overrides:[appDatabaseProvider.overrideWithValue(db),authServiceProvider.overrideWith(ScopeAdmin.new)],child:const MaterialApp(home:Scaffold(body:UsersScreen()))));
    await tester.pumpAndSettle();
    final switches=find.byType(SwitchListTile);
    expect(switches,findsNWidgets(7));
    expect(tester.widgetList<SwitchListTile>(switches).every((s)=>s.value),true);
    for(final label in ['الخدمة','النوع','المرحلة']) {
      final control=find.widgetWithText(SwitchListTile,'$label: الكل');
      tester.widget<SwitchListTile>(control).onChanged!(false);
      await tester.pump();
      final picker=find.byWidgetPredicate((w)=>w is MultiSelectFilter && w.label==label);
      final selected=label=='الخدمة' ? '1' : label=='النوع' ? 'ذكر' : '5';
      tester.widget<MultiSelectFilter>(picker).onChanged([selected]);
      await tester.pump();
    }
    final fields=find.byType(TextField);
    await tester.enterText(fields.at(0),'خادم 5ب');
    await tester.enterText(fields.at(1),'scope-test-only');
    final save=find.widgetWithText(ElevatedButton,'إنشاء المستخدم');
    await tester.drag(find.byType(ListView).first,const Offset(0,-900));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first,const Offset(0,-900));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final user=await (db.select(db.pass)..where((p)=>p.personName.equals('خادم 5ب'))).getSingle();
    expect(user.isAdvanced,false);
    final scope=await (db.select(db.settings)..where((t)=>t.settingKey.equals(DataVisibilityScope.storageKey(user.passId)))).getSingle();
    expect(jsonDecode(scope.settingValue!),{'service':['1'],'gender':['ذكر'],'stage':['5']});
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
