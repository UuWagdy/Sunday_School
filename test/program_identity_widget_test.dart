import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/main.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _LoggedOutAuthService extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _ServicesUserAuthService extends AuthService {
  @override
  Future<User?> build() async => User(
        id: 1,
        username: 'admin',
        canServices: true,
      );
}

void main() {
  testWidgets('login renders default and configured Arabic program names', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_LoggedOutAuthService.new),
          allUsersProvider.overrideWith((ref) async => []),
          programNameProvider.overrideWith((ref) async => SettingsRepository.defaultProgramName),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(SettingsRepository.defaultProgramName), findsWidgets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_LoggedOutAuthService.new),
          allUsersProvider.overrideWith((ref) async => []),
          programNameProvider.overrideWith((ref) async => 'مدرسة الشمامسة'),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مدرسة الشمامسة'), findsWidgets);
    expect(find.text(SettingsRepository.defaultProgramName), findsNothing);
  });

  testWidgets('shell and services management render configured program name', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await SettingsRepository(db).saveProgramName('مدرسة الشمامسة');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_ServicesUserAuthService.new),
          allUsersProvider.overrideWith((ref) async => []),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مدرسة الشمامسة'), findsWidgets);
    expect(find.text('اسم البرنامج'), findsOneWidget);
  });
}
