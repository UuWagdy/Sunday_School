import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import 'data_change_domains.dart';
import '../models/data_visibility_scope.dart';

/// Central coordinator that tracks table updates from both local Drift writes and
/// remote SignalR sync events, batches them, and increments monotonically increasing
/// revisions for affected DataDomains.
class DataChangeCoordinator {
  DataChangeCoordinator({
    Duration debounceDuration = const Duration(milliseconds: 80),
    Duration maxDebounceWait = const Duration(milliseconds: 400),
  })  : _debounceDuration = debounceDuration,
        _maxDebounceWait = maxDebounceWait {
    for (final domain in DataDomain.values) {
      _domainRevisions[domain] = 1;
    }
  }

  final Duration _debounceDuration;
  final Duration _maxDebounceWait;

  int _sourceEpoch = 1;
  final Map<DataDomain, int> _domainRevisions = {};
  final Set<String> _pendingChangedTables = {};

  Timer? _debounceTimer;
  DateTime? _firstPendingTime;
  StreamSubscription<Set<TableUpdate>>? _driftUpdatesSub;
  AppDatabase? _attachedDb;
  bool _disposed = false;

  void Function(DataDomain domain, int newRevision)? onDomainRevisionChanged;
  void Function(int newEpoch)? onEpochChanged;

  int get sourceEpoch => _sourceEpoch;
  bool get disposed => _disposed;

  int revisionFor(DataDomain domain) => _domainRevisions[domain] ?? 1;

  /// Attaches to an active Drift AppDatabase instance and subscribes to its `tableUpdates()`.
  void attachDatabase(AppDatabase db) {
    if (_disposed) return;
    if (identical(_attachedDb, db)) return;

    _driftUpdatesSub?.cancel();
    _attachedDb = db;
    incrementEpoch();

    _driftUpdatesSub = db.tableUpdates().listen(
      (updates) {
        if (_disposed) return;
        final tableNames = updates.map((u) => u.table).toSet();
        notifyTablesChanged(tableNames, notifyDrift: false);
      },
      onError: (e) {
        debugPrint('[DataChangeCoordinator] Drift tableUpdates stream error: $e');
      },
    );
  }

  /// Increments source epoch (e.g. database switch, reconnect, user auth change).
  void incrementEpoch() {
    if (_disposed) return;
    _sourceEpoch++;
    onEpochChanged?.call(_sourceEpoch);
  }

  /// Ingests table changes from any source (SignalR event, local transaction, direct call).
  /// [notifyDrift] dictates whether Drift's `markTablesUpdated` should also be notified
  /// so that any existing `watch()` queries in the app remain updated.
  void notifyTablesChanged(Iterable<String> rawTableNames, {bool notifyDrift = true}) {
    if (_disposed) return;

    if (rawTableNames.isEmpty) {
      _pendingChangedTables.add('*');
    } else {
      for (final t in rawTableNames) {
        _pendingChangedTables.add(normalizeTableName(t));
      }
    }

    if (notifyDrift && _attachedDb != null) {
      _notifyDriftInternal(rawTableNames);
    }

    _scheduleBatchFlush();
  }

  /// Marks all domains stale immediately (used on reconnect or full recovery).
  void notifyAllStale() {
    if (_disposed) return;
    _notifyDriftInternal(const ['*']);
    _pendingChangedTables.add('*');
    _scheduleBatchFlush(immediate: true);
  }

  void _notifyDriftInternal(Iterable<String> rawTableNames) {
    try {
      final db = _attachedDb;
      if (db == null) return;

      final isAll = rawTableNames.isEmpty || rawTableNames.contains('*');
      final matchedTables = db.allTables.where((t) {
        if (isAll) return true;
        final normalized = normalizeTableName(t.actualTableName);
        return rawTableNames.any((r) => normalizeTableName(r) == normalized);
      }).toList();

      if (matchedTables.isNotEmpty) {
        db.markTablesUpdated(matchedTables);
      }
    } catch (e) {
      debugPrint('[DataChangeCoordinator] Drift markTablesUpdated error: $e');
    }
  }

  void _scheduleBatchFlush({bool immediate = false}) {
    if (immediate) {
      _cancelDebounce();
      _flushPendingTables();
      return;
    }

    _firstPendingTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_firstPendingTime!);

    if (elapsed >= _maxDebounceWait) {
      _cancelDebounce();
      _flushPendingTables();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _cancelDebounce();
      _flushPendingTables();
    });
  }

  void _flushPendingTables() {
    if (_disposed || _pendingChangedTables.isEmpty) return;

    final batch = Set<String>.from(_pendingChangedTables);
    _pendingChangedTables.clear();

    final affectedDomains = resolveDomainsForTables(batch);
    for (final domain in affectedDomains) {
      final nextRev = (_domainRevisions[domain] ?? 1) + 1;
      _domainRevisions[domain] = nextRev;
      onDomainRevisionChanged?.call(domain, nextRev);
    }
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _firstPendingTime = null;
  }

  void dispose() {
    _disposed = true;
    _cancelDebounce();
    _driftUpdatesSub?.cancel();
    _driftUpdatesSub = null;
    _attachedDb = null;
  }
}

/// Riverpod notifier exposing the active map of domain revisions.
class DataChangeCoordinatorNotifier extends Notifier<Map<DataDomain, int>> {
  late DataChangeCoordinator coordinator;

  @override
  Map<DataDomain, int> build() {
    final current = DataChangeCoordinator();
    coordinator = current;
    ref.onDispose(current.dispose);

    // Watch the active AppDatabase. When database instance swaps or restarts,
    // attach the coordinator to it.
    final db = ref.watch(appDatabaseProvider);

    coordinator.onDomainRevisionChanged = (domain, newRevision) {
      // Trigger update of state map
      state = Map<DataDomain, int>.from(coordinator._domainRevisions);
      if (domain == DataDomain.access || domain == DataDomain.settings) {
        try {
          ref.read(authServiceProvider.notifier).refreshUser();
        } catch (_) {}
      }
    };

    coordinator.onEpochChanged = (newEpoch) {
      scheduleMicrotask(() {
        if (ref.mounted && !current.disposed) {
          ref.read(sourceEpochProvider.notifier).advance();
        }
      });
    };

    coordinator.attachDatabase(db);
    ref.listen(authServiceProvider, (previous, next) {
      final user = next.value;
      final oldUser = previous?.value;
      db.setVisibilityScope(user?.dataVisibilityScope ?? const DataVisibilityScope());
      if (oldUser?.id != user?.id || oldUser?.dataVisibilityScope.fingerprint != user?.dataVisibilityScope.fingerprint) {
        current.incrementEpoch();
        scheduleMicrotask(() { if (!current.disposed) current.notifyAllStale(); });
      }
    }, fireImmediately: true);

    return Map<DataDomain, int>.from(coordinator._domainRevisions);
  }
}

final dataChangeCoordinatorProvider =
    NotifierProvider<DataChangeCoordinatorNotifier, Map<DataDomain, int>>(
  DataChangeCoordinatorNotifier.new,
);

/// Provider exposing the underlying coordinator instance.
final coordinatorInstanceProvider = Provider<DataChangeCoordinator>((ref) {
  ref.watch(dataChangeCoordinatorProvider);
  return ref.read(dataChangeCoordinatorProvider.notifier).coordinator;
});

/// Individual domain revision provider. Widgets or repositories watching this
/// will only be notified when THIS specific domain's revision increments.
final domainRevisionProvider = Provider.family<int, DataDomain>((ref, domain) {
  return ref.watch(
    dataChangeCoordinatorProvider.select((map) => map[domain] ?? 1),
  );
});

/// State notifier for tracking source epoch numbers.
class SourceEpochNotifier extends Notifier<int> {
  @override
  int build() {
    return 1;
  }

  void updateEpoch(int epoch) {
    state = epoch;
  }

  void advance() => state++;
}

final sourceEpochProvider = NotifierProvider<SourceEpochNotifier, int>(
  SourceEpochNotifier.new,
);
