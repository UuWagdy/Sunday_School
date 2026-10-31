import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../ui/ribbon/ribbon_controller.dart';
import '../ui/ribbon/ribbon_models.dart';
import 'data_change_coordinator.dart';
import 'server_config.dart';
import 'server_connection_service.dart';

/// Manages the real-time SignalR WebSocket connection to `SundaySchool.SyncServer`
/// (`/hubs/sync`). Whenever any device (including this device or another device)
/// writes to PostgreSQL through the `.NET 8` API, the hub broadcasts
/// `DatabaseChanged` and this service refreshes both Drift table streams and
/// Riverpod providers immediately.
class SignalRSyncNotifier extends Notifier<SignalRConnectionStatus> {
  static const String _recordSeparator = '\u001e';

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _connectGeneration = 0;
  Completer<void>? _handshake;
  String _receiveBuffer = '';
  bool _disposed = false;
  DateTime? lastSyncTime;
  String? lastError;

  @override
  SignalRConnectionStatus build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _disconnectInternal();
    });

    final cfg = ref.watch(serverConfigProvider);
    if (cfg.isServerMode && (cfg.jwtToken?.isNotEmpty ?? false)) {
      Future.microtask(() => connect());
      return SignalRConnectionStatus.connecting;
    } else {
      _disconnectInternal();
      Future.microtask(() {
        ref
            .read(ribbonSyncStatusProvider.notifier)
            .setStatus(RibbonSyncState.synced);
      });
      return SignalRConnectionStatus.disconnected;
    }
  }

  Future<void> connect() async {
    if (_disposed) return;
    final cfg = ref.read(serverConfigProvider);
    if (!cfg.isServerMode) {
      _disconnectInternal();
      state = SignalRConnectionStatus.disconnected;
      return;
    }

    _disconnectInternal();
    final generation = _connectGeneration;
    state = SignalRConnectionStatus.connecting;
    _setRibbonStatus(RibbonSyncState.syncing);

    try {
      // Step 1: SignalR Negotiate (POST /hubs/sync/negotiate?negotiateVersion=1)
      final negotiateUri = Uri.parse(
        '${cfg.signalRHubHttpUrl}/negotiate?negotiateVersion=1',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Device-Id': cfg.deviceId,
      };
      if (cfg.jwtToken != null && cfg.jwtToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${cfg.jwtToken}';
      }

      String? connectionToken;
      try {
        final negResp = await http
            .post(negotiateUri, headers: headers)
            .timeout(const Duration(seconds: 6));
        if (_disposed || generation != _connectGeneration) return;
        if (negResp.statusCode == 401) {
          await ref.read(serverConfigProvider.notifier).setJwtToken(null);
          return;
        }
        if (negResp.statusCode == 200) {
          final negJson = jsonDecode(utf8.decode(negResp.bodyBytes));
          if (negJson is Map<String, dynamic>) {
            connectionToken =
                (negJson['connectionToken'] ?? negJson['connectionId'])
                    ?.toString();
          }
        }
      } catch (e) {
        debugPrint('SignalR negotiate fallback to direct WS: $e');
      }

      if (_disposed || generation != _connectGeneration) return;
      // Step 2: Open WebSocket to /hubs/sync
      final wsUrl = connectionToken != null && connectionToken.isNotEmpty
          ? '${cfg.signalRHubWsUrl}?id=${Uri.encodeQueryComponent(connectionToken)}'
          : cfg.signalRHubWsUrl;

      final token = cfg.jwtToken;
      final authenticatedUrl = token == null || token.isEmpty
          ? wsUrl
          : '$wsUrl${wsUrl.contains('?') ? '&' : '?'}access_token=${Uri.encodeQueryComponent(token)}';
      final channel = WebSocketChannel.connect(Uri.parse(authenticatedUrl));
      await channel.ready.timeout(const Duration(seconds: 8));
      if (_disposed || generation != _connectGeneration) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      final handshake = Completer<void>();
      _handshake = handshake;

      // Step 3: Send SignalR JSON protocol handshake

      // Step 4: Listen to incoming frames
      _socketSub = channel.stream.listen(
        (data) {
          if (generation == _connectGeneration && !_disposed)
            _onSocketData(data);
        },
        onError: (Object err) {
          if (_disposed || generation != _connectGeneration) return;
          lastError = err.toString();
          debugPrint('SignalR WebSocket error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          if (_disposed || generation != _connectGeneration) return;
          debugPrint('SignalR WebSocket closed.');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _sendRawFrame({'protocol': 'json', 'version': 1});
      await handshake.future.timeout(const Duration(seconds: 8));
      if (_disposed || generation != _connectGeneration) return;
      _handshake = null;

      // SyncHub broadcasts to all connected clients; no group join is needed.
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _sendRawFrame({'type': 6}); // SignalR Ping
      });

      lastError = null;
      lastSyncTime = DateTime.now();
      state = SignalRConnectionStatus.connected;
      // Reload after connecting so changes made while offline are visible too.
      ref.read(coordinatorInstanceProvider).notifyAllStale();

      _setRibbonStatus(RibbonSyncState.synced);
    } catch (e) {
      if (_disposed || generation != _connectGeneration) return;
      lastError = e.toString();
      debugPrint('SignalR connect failed: $e');
      state = SignalRConnectionStatus.error;
      _setRibbonStatus(RibbonSyncState.offline);
      _scheduleReconnect();
    }
  }

  void _sendRawFrame(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add('${jsonEncode(payload)}$_recordSeparator');
    } catch (_) {}
  }

  void _onSocketData(dynamic rawData) {
    if (rawData == null) return;
    _receiveBuffer += rawData.toString();
    final frames = _receiveBuffer.split(_recordSeparator);
    _receiveBuffer = frames.removeLast();

    for (final frame in frames) {
      final trimmed = frame.trim();
      if (trimmed.isEmpty) continue;

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map<String, dynamic>) continue;

        if (!decoded.containsKey('type') && _handshake != null) {
          final handshake = _handshake!;
          if (!handshake.isCompleted) {
            if (decoded['error'] != null)
              handshake.completeError(StateError(decoded['error'].toString()));
            else
              handshake.complete();
          }
          continue;
        }
        final msgType = decoded['type'];
        if (msgType == 6) {
          // Ping from server -> reply with Ping
          _sendRawFrame({'type': 6});
          continue;
        }

        if (msgType == 1) {
          // Invocation
          final target = (decoded['target'] ?? '').toString();
          final args = decoded['arguments'];
          if (target.toLowerCase() == 'databasechanged' &&
              args is List &&
              args.isNotEmpty) {
            final firstArg = args.first;
            if (firstArg is Map) {
              final evt = DatabaseChangedEvent.fromJson(
                Map<String, dynamic>.from(firstArg),
              );
              _handleDatabaseChanged(evt);
            }
          }
        }
      } catch (e) {
        debugPrint('SignalR frame parse error: $e');
      }
    }
  }

  void _handleDatabaseChanged(DatabaseChangedEvent event) {
    if (_disposed) return;
    lastSyncTime = DateTime.now();

    final tables = event.tables.isEmpty ? <String>['*'] : event.tables;
    ref.read(coordinatorInstanceProvider).notifyTablesChanged(tables);
    _setRibbonStatus(RibbonSyncState.synced);
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final cfg = ref.read(serverConfigProvider);
    if (!cfg.isServerMode) return;

    _disconnectInternal();

    state = SignalRConnectionStatus.reconnecting;
    _setRibbonStatus(RibbonSyncState.offline);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!_disposed && ref.read(serverConfigProvider).isServerMode) {
        connect();
      }
    });
  }

  void _disconnectInternal() {
    _connectGeneration++;
    final handshake = _handshake;
    _handshake = null;
    if (handshake != null && !handshake.isCompleted)
      handshake.completeError(
        StateError('SignalR disconnected before handshake'),
      );
    _receiveBuffer = '';
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _socketSub?.cancel();
    _socketSub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _setRibbonStatus(RibbonSyncState status) {
    try {
      ref.read(ribbonSyncStatusProvider.notifier).setStatus(status);
    } catch (_) {}
  }
}

final signalRSyncProvider =
    NotifierProvider<SignalRSyncNotifier, SignalRConnectionStatus>(
      SignalRSyncNotifier.new,
    );
