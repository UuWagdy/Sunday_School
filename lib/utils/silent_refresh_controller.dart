import 'dart:async';
import 'package:flutter/foundation.dart';

/// Callback signature for executing the actual background or initial fetch.
typedef RefreshFetchAction = Future<void> Function();

/// Manages single-flight execution, pending follow-ups, query generation tracking,
/// source epoch isolation, and disposal protection for silent UI revalidations.
class SilentRefreshController {
  SilentRefreshController({
    RefreshFetchAction? onRefresh,
    int initialEpoch = 1,
    int initialRevision = 0,
    Duration debounceDuration = const Duration(milliseconds: 100),
    Duration maxDebounceWait = const Duration(milliseconds: 400),
  })  : _defaultOnRefresh = onRefresh,
        _sourceEpoch = initialEpoch,
        _requestedRevision = initialRevision,
        _appliedRevision = initialRevision,
        _debounceDuration = debounceDuration,
        _maxDebounceWait = maxDebounceWait;

  final RefreshFetchAction? _defaultOnRefresh;
  final Duration _debounceDuration;
  final Duration _maxDebounceWait;

  int _sourceEpoch;
  int _queryGeneration = 1;
  int _requestedRevision;
  int _appliedRevision;

  bool _inFlight = false;
  bool _pending = false;
  bool _disposed = false;
  bool _lastFetchFailed = false;
  RefreshFetchAction? _latestAction;

  Timer? _debounceTimer;
  DateTime? _firstPendingTime;

  int get sourceEpoch => _sourceEpoch;
  int get queryGeneration => _queryGeneration;
  int get currentGeneration => _queryGeneration;
  int get generation => _queryGeneration;
  int get requestedRevision => _requestedRevision;
  int get appliedRevision => _appliedRevision;
  bool get inFlight => _inFlight;
  bool get pending => _pending;
  bool get disposed => _disposed;
  bool get isStale => _lastFetchFailed || _requestedRevision > _appliedRevision;

  /// Updates the source epoch (e.g. server/local database swap, auth user change).
  /// Invalidates previous in-flight and applied data.
  void updateEpoch(int newEpoch) {
    if (_disposed) return;
    if (newEpoch != _sourceEpoch) {
      _sourceEpoch = newEpoch;
      _queryGeneration++;
      _appliedRevision = 0;
      _pending = false;
      _cancelDebounce();
    }
  }

  /// Increments the query generation when user explicitly changes filters/search/pagination,
  /// ensuring older in-flight responses for prior query parameters cannot overwrite newer ones.
  void bumpGeneration() {
    if (_disposed) return;
    _queryGeneration++;
    _appliedRevision = 0;
    _pending = false;
    _cancelDebounce();
  }

  /// Sets the applied revision explicitly (e.g. after a manual full load or search).
  void markApplied(int revision) {
    if (_disposed) return;
    if (revision > _appliedRevision) {
      _appliedRevision = revision;
    }
    if (revision > _requestedRevision) {
      _requestedRevision = revision;
    }
  }

  /// Notifies that a new data revision has arrived for the relevant domain.
  void markStale(int newRevision, {RefreshFetchAction? onRefresh, bool immediate = false}) {
    if (_disposed) return;
    if (newRevision > _requestedRevision) {
      _requestedRevision = newRevision;
    }
    requestRefresh(onRefresh: onRefresh, immediate: immediate);
  }

  /// Requests a background silent refresh. If [immediate] is false, batches requests
  /// using debounce up to a maximum wait time to prevent UI starvation.
  void requestRefresh({RefreshFetchAction? onRefresh, bool immediate = false}) {
    if (_disposed) return;
    final action = onRefresh ?? _defaultOnRefresh;
    if (action == null) {
      debugPrint('[SilentRefreshController] requestRefresh called with no onRefresh action');
      return;
    }

    _latestAction = action;

    if (_inFlight) {
      _pending = true;
      return;
    }

    if (immediate) {
      _cancelDebounce();
      _executeFetch(action);
      return;
    }

    _firstPendingTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_firstPendingTime!);

    if (elapsed >= _maxDebounceWait) {
      _cancelDebounce();
      _executeFetch(action);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (_disposed) return;
      _cancelDebounce();
      _executeFetch(action);
    });
  }

  Future<void> _executeFetch(RefreshFetchAction onRefresh) async {
    if (_disposed || _inFlight) return;

    _inFlight = true;
    _pending = false;

    final fetchEpoch = _sourceEpoch;
    final fetchGen = _queryGeneration;
    final targetRev = _requestedRevision;
    bool success = false;

    try {
      await onRefresh();
      success = true;
    } catch (e, st) {
      debugPrint('[SilentRefreshController] Background fetch error: $e\n$st');
      // Do not clear applied data on error — keep previous valid result
    } finally {
      if (!_disposed) {
        _inFlight = false;

        // Verify that epoch and query generation did not change while fetching,
        // and that fetch succeeded
        final isValidGeneration = (fetchEpoch == _sourceEpoch && fetchGen == _queryGeneration);
        if (!isValidGeneration) {
          if (_pending && _latestAction != null) {
            _pending = false;
            scheduleMicrotask(() {
              if (!_disposed && !_inFlight) _executeFetch(_latestAction!);
            });
          }
        } else {
          if (success) {
            _lastFetchFailed = false;
            if (targetRev > _appliedRevision) {
              _appliedRevision = targetRev;
            }

            // Only trigger immediate follow-up on success if another request was queued
            if (_pending || _requestedRevision > _appliedRevision) {
              _pending = false;
              Future.microtask(() {
                if (!_disposed && !_inFlight && fetchEpoch == _sourceEpoch && fetchGen == _queryGeneration) {
                  _executeFetch(_latestAction ?? onRefresh);
                }
              });
            }
          } else {
            _lastFetchFailed = true;
            // On failure: keep stale state and previous valid data.
            // DO NOT enter an immediate retry loop in finally due to pending itself (Section 8.2 Rule 10).
            _pending = false;
          }
        }
      }
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
  }
}
