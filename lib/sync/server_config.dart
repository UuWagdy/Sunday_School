class ServerConfig {
  final bool isServerMode;
  final String serverUrl;
  final String deviceId;
  final String? jwtToken;
  final String? lastConnectedServerName;

  const ServerConfig({
    this.isServerMode = false,
    this.serverUrl = 'http://127.0.0.1:5050',
    this.deviceId = 'flutter-device',
    this.jwtToken,
    this.lastConnectedServerName,
  });

  String get normalizedBaseUrl {
    var trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return 'http://127.0.0.1:5050';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String get signalRHubHttpUrl => '$normalizedBaseUrl/hubs/sync';

  String get signalRHubWsUrl {
    final base = normalizedBaseUrl;
    if (base.startsWith('https://')) {
      return 'wss://${base.substring('https://'.length)}/hubs/sync';
    }
    if (base.startsWith('http://')) {
      return 'ws://${base.substring('http://'.length)}/hubs/sync';
    }
    return 'ws://$base/hubs/sync';
  }

  ServerConfig copyWith({
    bool? isServerMode,
    String? serverUrl,
    String? deviceId,
    String? jwtToken,
    bool clearJwtToken = false,
    String? lastConnectedServerName,
  }) {
    return ServerConfig(
      isServerMode: isServerMode ?? this.isServerMode,
      serverUrl: serverUrl ?? this.serverUrl,
      deviceId: deviceId ?? this.deviceId,
      jwtToken: clearJwtToken ? null : (jwtToken ?? this.jwtToken),
      lastConnectedServerName:
          lastConnectedServerName ?? this.lastConnectedServerName,
    );
  }
}

enum SignalRConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ServerHealthResult {
  final bool ok;
  final String service;
  final String version;
  final String database;
  final String engine;
  final int latencyMs;
  final String? errorMessage;

  const ServerHealthResult({
    required this.ok,
    this.service = '',
    this.version = '',
    this.database = '',
    this.engine = '',
    this.latencyMs = 0,
    this.errorMessage,
  });
}

class DatabaseChangedEvent {
  final List<String> tables;
  final String operation;
  final String sourceDeviceId;
  final DateTime timestampUtc;

  const DatabaseChangedEvent({
    required this.tables,
    required this.operation,
    required this.sourceDeviceId,
    required this.timestampUtc,
  });

  factory DatabaseChangedEvent.fromJson(Map<String, dynamic> json) {
    final rawTables =
        json['affectedTables'] ??
        json['AffectedTables'] ??
        json['tables'] ??
        json['Tables'];
    final tables = rawTables is List
        ? rawTables.map((e) => e.toString().toLowerCase()).toList()
        : <String>[];
    return DatabaseChangedEvent(
      tables: tables,
      operation: (json['operation'] ?? json['Operation'] ?? 'update')
          .toString(),
      sourceDeviceId: (json['sourceDeviceId'] ?? json['SourceDeviceId'] ?? '')
          .toString(),
      timestampUtc:
          DateTime.tryParse(
            (json['timestampUtc'] ?? json['TimestampUtc'] ?? '').toString(),
          ) ??
          DateTime.now().toUtc(),
    );
  }
}
