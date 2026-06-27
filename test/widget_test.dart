// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petros_pols_flutter/main.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  testWidgets('App shows login shell when user is not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_FakeAuthService.new),
          allUsersProvider.overrideWith((ref) async => []),
          programNameProvider.overrideWith((ref) async => SettingsRepository.defaultProgramName),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(SettingsRepository.defaultProgramName), findsWidgets);
  });

  testWidgets('Login shell shows configured program name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_FakeAuthService.new),
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
}
