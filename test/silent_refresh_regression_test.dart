import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/bus_repository.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';
import 'package:petros_pols_flutter/utils/silent_refresh_controller.dart';

class ReviewAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  test('review: queued refresh after generation change must run', () async {
    final first = Completer<void>();
    var calls = 0;
    final controller = SilentRefreshController(onRefresh: () {
      calls++;
      return calls == 1 ? first.future : Future<void>.value();
    });
    addTearDown(controller.dispose);
    controller.requestRefresh(immediate: true);
    controller.bumpGeneration();
    controller.requestRefresh(immediate: true);
    first.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 2, reason: 'new query request must survive old fetch completing');
  });

  test('review: coordinator survives database provider replacement', () async {
    final firstDb = AppDatabase.forTesting(NativeDatabase.memory());
    final secondDb = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(firstDb),
      authServiceProvider.overrideWith(ReviewAuth.new),
    ]);
    addTearDown(() async { container.dispose(); await firstDb.close(); await secondDb.close(); });
    container.read(dataChangeCoordinatorProvider);
    container.updateOverrides([
      appDatabaseProvider.overrideWithValue(secondDb),
      authServiceProvider.overrideWith(ReviewAuth.new),
    ]);
    expect(() => container.read(dataChangeCoordinatorProvider), returnsNormally);
  });

  test('review: bus provider supports its initial build', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authServiceProvider.overrideWith(ReviewAuth.new),
    ]);
    addTearDown(() async { container.dispose(); await db.close(); });
    expect(() => container.read(busRepositoryProvider), returnsNormally);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(container.read(busRepositoryProvider).hasError, false);
  });

  test('review: local settings change refreshes the program name', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authServiceProvider.overrideWith(ReviewAuth.new),
    ]);
    addTearDown(() async { container.dispose(); await db.close(); });
    final coordinator = container.read(coordinatorInstanceProvider);
    final initial = await container.read(programNameProvider.future);
    await container.read(settingsRepositoryProvider).saveSetting('program_name', 'Review updated name');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(coordinator.revisionFor(DataDomain.settings), greaterThan(1));
    expect(await container.read(programNameProvider.future), 'Review updated name', reason: 'old name was $initial');
  });
}
