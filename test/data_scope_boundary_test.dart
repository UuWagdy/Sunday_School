import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/models/data_visibility_scope.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/widgets/data_scope_boundary.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => User(id: 1, username: 'fixture');
  @override
  Future<void> refreshUser() async {}
  void restrict() => state = AsyncData(
    User(
      id: 1,
      username: 'fixture',
      dataVisibilityScope: const DataVisibilityScope({
        'gender': ['ذكر'],
      }),
    ),
  );
}

class _Content extends ConsumerWidget {
  const _Content();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(personsRepositoryProvider).value ?? [];
    return Column(
      children: [
        const TextField(key: ValueKey('draft')),
        for (final p in rows) Text(p.name),
      ],
    );
  }
}

void main() {
  testWidgets('changing the data scope removes open Navigator dialogs too', (tester) async {
    final db=AppDatabase.forTesting(NativeDatabase.memory());
    final parent=ProviderContainer(overrides:[appDatabaseProvider.overrideWithValue(db),authServiceProvider.overrideWith(_Auth.new)]);
    await parent.read(authServiceProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(container:parent,child:DataScopeBoundary(child:MaterialApp(home:Builder(builder:(context)=>Scaffold(body:TextButton(onPressed:()=>showDialog<void>(context:context,builder:(_)=>const AlertDialog(content:Text('Previous wider-scope editor'))),child:const Text('open'))))))));
    await tester.pumpAndSettle();await tester.tap(find.text('open'));await tester.pumpAndSettle();
    expect(find.text('Previous wider-scope editor'),findsOneWidget);
    (parent.read(authServiceProvider.notifier) as _Auth).restrict();
    await tester.pumpAndSettle();
    expect(find.text('Previous wider-scope editor'),findsNothing);
    expect(find.text('open'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());parent.dispose();await db.close();
  });
  testWidgets(
    'scope change removes wider snapshots; ordinary data changes preserve drafts',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      for (final (id, name, gender) in [
        (1, 'Visible boy', 'ذكر'),
        (2, 'Hidden girl', 'أنثى'),
      ]) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value(name),
                jenderName: d.Value(gender),
              ),
            );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(dataChangeCoordinatorProvider);
                return const Scaffold(
                  body: DataScopeBoundary(child: _Content()),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hidden girl'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DataScopeBoundary)),
      );
      await tester.enterText(find.byKey(const ValueKey('draft')), 'unsaved');
      await (db.update(db.persons)..where((p) => p.personId.equals(1))).write(
        const PersonsCompanion(personName: d.Value('Updated boy')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Updated boy'), findsOneWidget);
      expect(find.text('unsaved'), findsOneWidget);
      (container.read(authServiceProvider.notifier) as _Auth).restrict();
      await tester.pump();
      // The old cached wider list is absent even before the new read completes.
      expect(find.text('Hidden girl'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Updated boy'), findsOneWidget);
      expect(find.text('Hidden girl'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );
}
