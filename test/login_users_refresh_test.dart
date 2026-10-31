import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/screens/login_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';
import 'package:petros_pols_flutter/sync/signalr_sync_service.dart';

class _LoggedOut extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _Disconnected extends SignalRSyncNotifier {
  @override
  SignalRConnectionStatus build() => SignalRConnectionStatus.disconnected;
}

class _Revision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final _revision = NotifierProvider<_Revision, int>(_Revision.new);

void main() {
  testWidgets('failed initial load stays on retry until the user retries', (
    tester,
  ) async {
    var requests = 0;
    var available = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_LoggedOut.new),
          signalRSyncProvider.overrideWith(_Disconnected.new),
          programNameProvider.overrideWith((ref) async => 'البرنامج'),
          allUsersProvider.overrideWith((ref) async {
            requests++;
            if (!available) throw Exception('السيرفر غير متاح');
            return [User(id: 1, username: 'admin')];
          }),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 10));
    }
    expect(requests, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    available = true;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('background reload and failure preserve login input and dropdown', (
    tester,
  ) async {
    Completer<List<User>>? pending;
    final users = [
      User(id: 1, username: 'admin'),
      User(id: 2, username: 'other'),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith(_LoggedOut.new),
          signalRSyncProvider.overrideWith(_Disconnected.new),
          programNameProvider.overrideWith((ref) async => 'البرنامج'),
          allUsersProvider.overrideWith((ref) {
            ref.watch(_revision);
            return pending?.future ?? Future.value(users);
          }),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('admin').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    );
    final originalState = tester.state(dropdown);
    pending = Completer<List<User>>();
    container.read(_revision.notifier).bump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.state(dropdown), same(originalState));
    expect(tester.state<FormFieldState<String>>(dropdown).value, 'admin');
    pending!.completeError(Exception('انقطع الاتصال'));
    await tester.pumpAndSettle();
    expect(tester.state(dropdown), same(originalState));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'secret',
    );

    // A successful update removing the selected user clears it without a
    // DropdownButton assertion or submitting an account that is no longer listed.
    pending = Completer<List<User>>();
    container.read(_revision.notifier).bump();
    await tester.pump();
    pending!.complete([users.last]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.state<FormFieldState<String>>(dropdown).value, isNull);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    expect(find.text('other').last, findsOneWidget);
    await tester.tap(find.text('other').last);
    await tester.pumpAndSettle();
    expect(tester.state<FormFieldState<String>>(dropdown).value, 'other');
  });
}
