import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/screens/persons_screen.dart';
import 'package:petros_pols_flutter/screens/monthly_fund_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

class ReviewAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}
class ReviewCoordinator extends DataChangeCoordinatorNotifier {
  @override
  Map<DataDomain,int> build() => {for (final d in DataDomain.values) d: 1};
  void bump(DataDomain d) { state = {...state, d: state[d]! + 1}; }
}
class ReviewSettings extends SettingsRepository {
  ReviewSettings(super.db);
  final values = <String,String>{'monthly_fund_annual_amount':'100'};
  @override
  Future<String?> getSetting(String key) async => values[key];
}
PersonListDTO person(int id,String name) => PersonListDTO(id:id,name:name,
  stageName:'', khorosName:'',areaName:'',phone:'',mobile:'',streetName:'',fatherName:'');
class ReviewPersons extends PersonsRepository {
  Completer<List<PersonListDTO>>? oldRequest;
  bool silentStarted = false;
  bool empty = false;
  @override
  FutureOr<List<PersonListDTO>> build() => [];
  @override
  Future<int> fetchTotalCount({String? search,List<int>? stageIds,List<int>? khorosIds,
    List<int>? areaIds,List<int>? fatherIds,List<String>? genders,List<int>? birthdayDay,
    List<int>? birthdayMonth,List<int>? birthdayYear,List<String>? rohots,List<String>? leaders}) async => empty ? 0 : 1;
  @override
  Future<List<PersonListDTO>> fetchPersons({String? search,int? limit,int? offset,
    List<int>? stageIds,List<int>? khorosIds,List<int>? areaIds,List<int>? fatherIds,
    List<String>? genders,List<int>? birthdayDay,List<int>? birthdayMonth,List<int>? birthdayYear,
    List<String>? rohots,List<String>? leaders,List<int>? personIds,bool includeServices = true, bool includePhotos = true}) async {
      if (empty) return [];
      if (search == 'new') return [person(2,'New filtered person')];
      if (oldRequest != null) { silentStarted = true; return oldRequest!.future; }
      return [person(1,'Original person')];
    }
}
void main() {
  testWidgets('review widget: annual amount follows remote changes while not edited', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final settings = ReviewSettings(db);
    final people = ReviewPersons()..empty = true;
    await tester.pumpWidget(ProviderScope(overrides:[
      appDatabaseProvider.overrideWithValue(db),authServiceProvider.overrideWith(ReviewAuth.new),
      personsRepositoryProvider.overrideWith(() => people),settingsRepositoryProvider.overrideWithValue(settings),
      dataChangeCoordinatorProvider.overrideWith(ReviewCoordinator.new),
    ],child: const MaterialApp(home: MonthlyFundScreen())));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(MonthlyFundScreen)));
    final amount = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'المبلغ السنوي');
    expect(tester.widget<TextField>(amount).controller!.text,'100');
    settings.values['monthly_fund_annual_amount'] = '200';
    (container.read(dataChangeCoordinatorProvider.notifier) as ReviewCoordinator).bump(DataDomain.settings);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    final actual = tester.widget<TextField>(amount).controller!.text;
    await tester.pumpWidget(const SizedBox());
    await db.close();
    expect(actual,'200',reason:'programmatic loading must not mark the field dirty');
  });
  testWidgets('review widget: old persons refresh cannot overwrite a new search', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    final people = ReviewPersons();
    await tester.pumpWidget(ProviderScope(overrides:[
      appDatabaseProvider.overrideWithValue(db),authServiceProvider.overrideWith(ReviewAuth.new),
      personsRepositoryProvider.overrideWith(() => people),
      dataChangeCoordinatorProvider.overrideWith(ReviewCoordinator.new),
    ],child: const MaterialApp(home: PersonsScreen())));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(PersonsScreen)));
    final delayed = Completer<List<PersonListDTO>>();
    people.oldRequest = delayed;
    (container.read(dataChangeCoordinatorProvider.notifier) as ReviewCoordinator).bump(DataDomain.people);
    await tester.pump(const Duration(milliseconds: 120));
    expect(people.silentStarted,true);
    final search = find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText?.contains('الموبايل') ?? false));
    tester.widget<TextField>(search).onSubmitted!('new');
    await tester.pumpAndSettle();
    expect(find.text('New filtered person'),findsOneWidget);
    delayed.complete([person(1,'Stale previous person')]);
    await tester.pumpAndSettle();
    final retained = find.text('New filtered person').evaluate().length;
    final stale = find.text('Stale previous person').evaluate().length;
    await tester.pumpWidget(const SizedBox());
    await db.close();
    expect(retained,1,reason:'new search row disappeared; stale old rows shown: $stale');
  });
}
