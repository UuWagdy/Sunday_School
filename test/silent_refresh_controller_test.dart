import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/utils/silent_refresh_controller.dart';

void main() {
  group('SilentRefreshController tests', () {
    test(
      'direct requests retain stale state after an error without retry loops',
      () async {
        var calls = 0;
        final controller = SilentRefreshController(
          onRefresh: () async {
            calls++;
            throw StateError('fixture failure');
          },
        );
        addTearDown(controller.dispose);
        controller.requestRefresh(immediate: true);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(calls, 1);
        expect(controller.isStale, true);
        controller.requestRefresh(immediate: true, onRefresh: () async {});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(controller.isStale, false);
      },
    );
    test('executes immediate refresh and updates appliedRevision', () async {
      final controller = SilentRefreshController(initialRevision: 0);
      int fetchCount = 0;

      controller.markStale(
        1,
        onRefresh: () async {
          fetchCount++;
        },
        immediate: true,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(fetchCount, 1);
      expect(controller.appliedRevision, 1);
      expect(controller.isStale, false);
      expect(controller.inFlight, false);
      expect(controller.pending, false);
    });

    test(
      'single-flight executes only one fetch at a time, then triggers pending follow-up',
      () async {
        final controller = SilentRefreshController(initialRevision: 0);
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        int fetchCount = 0;

        controller.markStale(
          1,
          onRefresh: () {
            fetchCount++;
            return fetchCount == 1 ? completer1.future : completer2.future;
          },
          immediate: true,
        );

        expect(controller.inFlight, true);
        expect(fetchCount, 1);

        // Second request while first is in-flight
        controller.markStale(
          2,
          onRefresh: () {
            fetchCount++;
            return completer2.future;
          },
          immediate: true,
        );

        expect(controller.inFlight, true);
        expect(controller.pending, true);
        expect(fetchCount, 1); // Should not start immediately

        // Complete first fetch
        completer1.complete();
        await Future.delayed(const Duration(milliseconds: 10));

        // Follow-up should have run
        expect(fetchCount, 2);
        expect(controller.inFlight, true);

        // Complete second fetch
        completer2.complete();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(controller.inFlight, false);
        expect(controller.appliedRevision, 2);
        expect(controller.isStale, false);
      },
    );

    test('bumpGeneration discards result from earlier generation', () async {
      final controller = SilentRefreshController(initialRevision: 0);
      final completer = Completer<void>();

      controller.markStale(
        1,
        onRefresh: () => completer.future,
        immediate: true,
      );
      expect(controller.queryGeneration, 1);
      expect(controller.inFlight, true);

      // User modifies search/filters before fetch completes
      controller.bumpGeneration();
      expect(controller.queryGeneration, 2);

      completer.complete();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.inFlight, false);
      // Because generation changed, appliedRevision was not advanced to 1
      expect(controller.appliedRevision, 0);
    });

    test('epoch change isolates previous fetch results', () async {
      final controller = SilentRefreshController(
        initialEpoch: 1,
        initialRevision: 0,
      );
      final completer = Completer<void>();

      controller.markStale(
        1,
        onRefresh: () => completer.future,
        immediate: true,
      );
      expect(controller.inFlight, true);

      // Database switched or logged out
      controller.updateEpoch(2);

      completer.complete();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.appliedRevision, 0);
    });

    test(
      'error during fetch keeps controller stable without throwing or crashing',
      () async {
        final controller = SilentRefreshController(initialRevision: 1);

        controller.markStale(
          2,
          onRefresh: () async {
            throw Exception('Network timeout');
          },
          immediate: true,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(controller.inFlight, false);
        // Target was not marked as applied due to failure
        expect(controller.appliedRevision, 1);
        expect(controller.isStale, true);
      },
    );

    test('dispose cancels timers and prevents callbacks', () async {
      final controller = SilentRefreshController(
        debounceDuration: const Duration(milliseconds: 100),
      );
      int fetchCount = 0;

      controller.markStale(
        1,
        onRefresh: () async {
          fetchCount++;
        },
        immediate: false,
      );

      controller.dispose();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(fetchCount, 0);
      expect(controller.disposed, true);
    });
  });
}
