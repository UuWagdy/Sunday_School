import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/sync/data_change_coordinator.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

void main() {
  group('DataChangeCoordinator tests', () {
    test('increments revisions only for affected domains after debounce', () async {
      final coordinator = DataChangeCoordinator(
        debounceDuration: const Duration(milliseconds: 50),
      );

      final changedDomains = <DataDomain, int>{};
      coordinator.onDomainRevisionChanged = (domain, rev) {
        changedDomains[domain] = rev;
      };

      // Notify that areas table changed
      coordinator.notifyTablesChanged(['areas'], notifyDrift: false);

      expect(changedDomains.isEmpty, true); // debouncing

      await Future.delayed(const Duration(milliseconds: 80));

      // Areas should be incremented (started at 1, now 2)
      expect(changedDomains.containsKey(DataDomain.areas), true);
      expect(changedDomains[DataDomain.areas], 2);
      expect(coordinator.revisionFor(DataDomain.areas), 2);

      // People and attendance depend on areas as well
      expect(changedDomains.containsKey(DataDomain.people), true);
      expect(changedDomains.containsKey(DataDomain.attendance), true);

      // Unrelated domains like fathers or tayo should NOT have been incremented
      expect(changedDomains.containsKey(DataDomain.fathers), false);
      expect(coordinator.revisionFor(DataDomain.fathers), 1);
    });

    test('batches 100 rapid events into a single debounce flush', () async {
      final coordinator = DataChangeCoordinator(
        debounceDuration: const Duration(milliseconds: 50),
      );

      int flushCount = 0;
      coordinator.onDomainRevisionChanged = (domain, rev) {
        if (domain == DataDomain.attendance) {
          flushCount++;
        }
      };

      for (int i = 0; i < 100; i++) {
        coordinator.notifyTablesChanged(['coming'], notifyDrift: false);
      }

      await Future.delayed(const Duration(milliseconds: 80));

      // Should only flush once
      expect(flushCount, 1);
      expect(coordinator.revisionFor(DataDomain.attendance), 2);
    });

    test('wildcard updates all domains immediately', () {
      final coordinator = DataChangeCoordinator();
      final updated = <DataDomain>{};
      coordinator.onDomainRevisionChanged = (domain, rev) {
        updated.add(domain);
      };

      coordinator.notifyAllStale();

      expect(updated.length, DataDomain.values.length);
      for (final domain in DataDomain.values) {
        expect(coordinator.revisionFor(domain), 2);
      }
    });

    test('maxDebounceWait prevents starvation during continuous event streams', () async {
      final coordinator = DataChangeCoordinator(
        debounceDuration: const Duration(milliseconds: 60),
        maxDebounceWait: const Duration(milliseconds: 150),
      );

      int attendanceFlushes = 0;
      coordinator.onDomainRevisionChanged = (domain, rev) {
        if (domain == DataDomain.attendance) {
          attendanceFlushes++;
        }
      };

      // Fire events every 20ms for 220ms (which is less than the 60ms debounce window)
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsedMilliseconds < 220) {
        coordinator.notifyTablesChanged(['coming'], notifyDrift: false);
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Max wait should have forced at least one flush despite continuous events
      expect(attendanceFlushes, greaterThanOrEqualTo(1));
    });

    test('epoch increments when explicitly requested', () {
      final coordinator = DataChangeCoordinator();
      expect(coordinator.sourceEpoch, 1);

      int observedEpoch = 0;
      coordinator.onEpochChanged = (ep) {
        observedEpoch = ep;
      };

      coordinator.incrementEpoch();
      expect(coordinator.sourceEpoch, 2);
      expect(observedEpoch, 2);
    });
  });
}
