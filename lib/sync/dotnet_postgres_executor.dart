import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:drift/backends.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'server_config.dart';

/// Case-insensitive row map so that any column access (e.g. `row['Person_ID']`,
/// `row['person_id']`, `row['ID']`, `row['Id']`, `row['id']`) resolves in O(1)
/// regardless of how PostgreSQL or SQLite cased the column identifier.
class CaseInsensitiveRowMap extends MapBase<String, Object?> {
  final Map<String, Object?> _original = {};
  final Map<String, String> _lowerToCanonical = {};

  CaseInsensitiveRowMap(Map<String, dynamic> source) {
    source.forEach((key, value) {
      final decoded = _decodeValue(value);
      _original[key] = decoded;
      _lowerToCanonical.putIfAbsent(key.toLowerCase(), () => key);
    });
  }

  static Object? _decodeValue(Object? val) {
    if (val == null) return null;
    if (val is bool) return val ? 1 : 0;
    if (val is Map) {
      if (val['__type'] == 'bytes' && val['base64'] is String) {
        return base64Decode(val['base64'] as String);
      }
    }
    return val;
  }

  @override
  Object? operator [](Object? key) {
    if (key is! String) return null;
    if (_original.containsKey(key)) return _original[key];
    final canonical = _lowerToCanonical[key.toLowerCase()];
    if (canonical != null) return _original[canonical];
    return null;
  }

  @override
  void operator []=(String key, Object? value) {
    _original[key] = value;
    _lowerToCanonical[key.toLowerCase()] = key;
  }

  @override
  void clear() {
    _original.clear();
    _lowerToCanonical.clear();
  }

  @override
  Iterable<String> get keys => _original.keys;

  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final canonical = _lowerToCanonical.remove(key.toLowerCase()) ?? key;
    return _original.remove(canonical);
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    return _original.containsKey(key) ||
        _lowerToCanonical.containsKey(key.toLowerCase());
  }
}

/// Drift [QueryExecutor] that sends all SQL operations directly to the
/// `.NET 8` backend (`SundaySchool.SyncServer`), which executes them on
/// `PostgreSQL` and broadcasts real-time updates via `SignalR` to this device
/// and all other connected devices.
///
/// Pipeline:
/// `Flutter UI -> Dart Logic -> .NET 8 (Storage, Sync, Login) -> PostgreSQL -> SignalR -> This Device & Other Devices`
class DotNetPostgresQueryExecutor extends QueryExecutor {
  static const _maxReadCacheBytes = 32 * 1024 * 1024;
  final _readCache =
      <String, ({String tag, List<Map<String, dynamic>> rows, int bytes})>{};
  final _pendingReads = <String, Future<Map<String, dynamic>>>{};
  int _readCacheBytes = 0;
  (String, String?)? _readCacheIdentity;
  final ServerConfig Function() _getConfig;
  final void Function(bool isBusy)? onSyncActivity;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final void Function()? onUnauthorized;
  final String? _transactionId;

  DotNetPostgresQueryExecutor({
    required ServerConfig Function() getConfig,
    this.onSyncActivity,
    String? transactionId,
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _transactionId = transactionId,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = true,
       _getConfig = getConfig;

  DotNetPostgresQueryExecutor._transaction(
    DotNetPostgresQueryExecutor parent,
    String transactionId,
  ) : _getConfig = parent._getConfig,
      onUnauthorized = parent.onUnauthorized,
      onSyncActivity = parent.onSyncActivity,
      _httpClient = parent._httpClient,
      _ownsHttpClient = false,
      _transactionId = transactionId;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  Map<String, String> _buildHeaders(ServerConfig cfg) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'X-Device-Id': cfg.deviceId,
    };
    if (cfg.jwtToken != null && cfg.jwtToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${cfg.jwtToken}';
    }
    return headers;
  }

  static List<Map<String, Object?>> _encodeArgs(List<Object?>? args) {
    if (args == null || args.isEmpty) return const [];
    return args.map((arg) {
      // Match SqlParamDto on the server. Raw `args` are silently ignored by
      // ASP.NET, leaving translated @p0 parameters unbound in PostgreSQL.
      return switch (arg) {
        null => {'type': 'null', 'value': null},
        Uint8List bytes => {'type': 'bytes', 'value': base64Encode(bytes)},
        List<int> bytes => {
          'type': 'bytes',
          'value': base64Encode(Uint8List.fromList(bytes)),
        },
        bool value => {'type': 'int', 'value': value ? 1 : 0},
        int value => {'type': 'int', 'value': value},
        double value => {'type': 'double', 'value': value},
        DateTime value => {'type': 'string', 'value': value.toIso8601String()},
        String value => {'type': 'string', 'value': value},
        _ => throw ArgumentError.value(arg, 'arg', 'Unsupported SQL value'),
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final cfg = _getConfig();
    final uri = Uri.parse('${cfg.normalizedBaseUrl}$path');
    onSyncActivity?.call(true);
    try {
      final response = await _httpClient
          .post(uri, headers: _buildHeaders(cfg), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));

      final bodyText = utf8.decode(response.bodyBytes);
      if (response.statusCode == 401) {
        onUnauthorized?.call();
        throw Exception('انتهت جلسة الاتصال بالسيرفر. سجّل الدخول مرة أخرى.');
      }
      if (response.statusCode == 403) {
        throw Exception('السيرفر رفض العملية بسبب صلاحيات المستخدم.');
      }
      final decoded = bodyText.isNotEmpty
          ? jsonDecode(bodyText)
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          if (decoded['ok'] == false) {
            throw Exception(decoded['error'] ?? 'Database operation failed');
          }
          decoded['__clientResponseBytes'] = response.bodyBytes.length;
          return decoded;
        }
        return <String, dynamic>{'ok': true};
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['error'] ?? bodyText)
          : bodyText;
      throw Exception('HTTP ${response.statusCode}: $errorMsg');
    } finally {
      onSyncActivity?.call(false);
    }
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    // PostgreSQL schema and seed data are managed centrally by
    // SundaySchool.SyncServer (PostgresSchemaInitializer.cs).
    return true;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async {
    final cfg = _getConfig();
    final identity = (cfg.normalizedBaseUrl, cfg.jwtToken);
    if (_readCacheIdentity != identity) {
      _readCache.clear();
      _readCacheBytes = 0;
      _readCacheIdentity = identity;
    }
    final parameters = _encodeArgs(args);
    final key = jsonEncode([statement, parameters]);
    final cached = _transactionId == null ? _readCache.remove(key) : null;
    if (cached != null) _readCache[key] = cached;
    final payload = <String, dynamic>{
      'sql': statement,
      'params': parameters,
      'transactionId': _transactionId,
      if (_transactionId == null) 'acceptCache': true,
      if (cached != null) 'cacheTag': cached.tag,
    };
    final pendingKey = jsonEncode([identity.$1, identity.$2, key, cached?.tag]);
    final request = _transactionId == null
        ? _pendingReads.putIfAbsent(
            pendingKey,
            () => _postJson('/api/storage/query', payload),
          )
        : _postJson('/api/storage/query', payload);
    late final Map<String, dynamic> res;
    try {
      res = await request;
    } finally {
      if (identical(_pendingReads[pendingKey], request)) {
        _pendingReads.remove(pendingKey);
      }
    }

    final List<Map<String, dynamic>> rows;
    if (res['notModified'] == true) {
      if (cached == null) {
        throw StateError('Server returned an unknown read cache tag');
      }
      rows = cached.rows;
    } else {
      rows = (res['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    }
    final tag = res['cacheTag'];
    if (_transactionId == null &&
        tag is String &&
        _readCacheIdentity == identity) {
      final bytes = res['notModified'] == true
          ? cached!.bytes
          : res['__clientResponseBytes'] as int;
      final old = _readCache.remove(key);
      if (old != null) _readCacheBytes -= old.bytes;
      if (bytes <= 8 * 1024 * 1024) {
        _readCache[key] = (tag: tag, rows: rows, bytes: bytes);
        _readCacheBytes += bytes;
      }
      while (_readCache.isNotEmpty &&
          (_readCacheBytes > _maxReadCacheBytes || _readCache.length > 256)) {
        final removed = _readCache.remove(_readCache.keys.first)!;
        _readCacheBytes -= removed.bytes;
      }
    }
    // Fresh row maps protect the stored snapshot from callers modifying results.
    return rows.map((r) => CaseInsensitiveRowMap(r)).toList();
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final cfg = _getConfig();
    final res = await _postJson('/api/storage/insert', {
      'sql': statement,
      'params': _encodeArgs(args),
      'transactionId': _transactionId,
      'deviceId': cfg.deviceId,
    });
    final lastId = res['lastInsertId'] ?? res['lastInsertRowId'] ?? 0;
    if (lastId is int) return lastId;
    if (lastId is num) return lastId.toInt();
    return int.tryParse(lastId.toString()) ?? 0;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final cfg = _getConfig();
    final res = await _postJson('/api/storage/execute', {
      'sql': statement,
      'params': _encodeArgs(args),
      'transactionId': _transactionId,
      'deviceId': cfg.deviceId,
    });
    final affected = res['rowsAffected'] ?? 0;
    if (affected is int) return affected;
    if (affected is num) return affected.toInt();
    return int.tryParse(affected.toString()) ?? 0;
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) async {
    return runUpdate(statement, args);
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {
    final cfg = _getConfig();
    await _postJson('/api/storage/execute', {
      'sql': statement,
      'params': _encodeArgs(args),
      'transactionId': _transactionId,
      'deviceId': cfg.deviceId,
    });
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final cfg = _getConfig();
    final items = <Map<String, dynamic>>[];
    for (final argSet in statements.arguments) {
      final sql = statements.statements[argSet.statementIndex];
      items.add({
        'sql': sql,
        'argSets': [_encodeArgs(argSet.arguments)],
      });
    }
    if (items.isEmpty) return;

    await _postJson('/api/storage/batch', {
      'statements': items,
      'transactionId': _transactionId,
      'deviceId': cfg.deviceId,
    });
  }

  @override
  TransactionExecutor beginTransaction() {
    return _DotNetPostgresTransactionExecutor(
      parent: this,
      getConfig: _getConfig,
      onSyncActivity: onSyncActivity,
    );
  }

  @override
  QueryExecutor beginExclusive() {
    return this;
  }

  @override
  Future<void> close() async {
    _readCache.clear();
    _pendingReads.clear();
    _readCacheBytes = 0;
    if (_ownsHttpClient) _httpClient.close();
  }
}

class _DotNetPostgresTransactionExecutor extends TransactionExecutor {
  final DotNetPostgresQueryExecutor parent;
  final ServerConfig Function() getConfig;
  final void Function(bool isBusy)? onSyncActivity;
  String? _txId;
  late DotNetPostgresQueryExecutor _delegate;

  _DotNetPostgresTransactionExecutor({
    required this.parent,
    required this.getConfig,
    this.onSyncActivity,
  });

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  bool get supportsNestedTransactions => false;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    if (_txId != null) return true;
    final cfg = getConfig();
    final res = await parent._postJson('/api/storage/tx/begin', {
      'deviceId': cfg.deviceId,
    });
    _txId = (res['transactionId'] ?? '').toString();
    _delegate = DotNetPostgresQueryExecutor._transaction(parent, _txId!);
    return true;
  }

  @override
  Future<void> send() async {
    final txId = _txId;
    if (txId == null || txId.isEmpty) return;
    _txId = null;
    final cfg = getConfig();
    try {
      await parent._postJson('/api/storage/tx/commit', {
        'transactionId': txId,
        'deviceId': cfg.deviceId,
      });
    } finally {
      await _delegate.close();
    }
  }

  @override
  Future<void> rollback() async {
    final txId = _txId;
    if (txId == null || txId.isEmpty) return;
    _txId = null;
    final cfg = getConfig();
    try {
      await parent._postJson('/api/storage/tx/rollback', {
        'transactionId': txId,
        'deviceId': cfg.deviceId,
      });
    } catch (e) {
      debugPrint('Transaction rollback warning: $e');
    } finally {
      await _delegate.close();
    }
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Nested transactions are not supported');
  }

  @override
  QueryExecutor beginExclusive() => _delegate;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _delegate.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _delegate.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _delegate.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _delegate.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _delegate.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _delegate.runBatched(statements);

  @override
  Future<void> close() async {}
}
