import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/data_visibility_scope.dart';
import '../models/scoped_settings_merge.dart';

class VisibilityContext {
  DataVisibilityScope scope = const DataVisibilityScope();
  bool applyLocally = true;
}

class VisibilityInterceptor extends QueryInterceptor {
  final VisibilityContext context;
  VisibilityInterceptor(this.context);

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final scope = context.scope;
    if (context.applyLocally &&
        scope.restricted &&
        RegExp(
          r'INSERT\s+(?:OR\s+\w+\s+)?INTO\s+"?Settings"?',
          caseSensitive: false,
        ).hasMatch(statement) &&
        args.length >= 2 &&
        (args[0] == 'monthly_fund_payments_json' ||
            args[0] == 'rohot_groups_json')) {
      final old = await executor.runSelect(
        'SELECT "Setting_Value" FROM main."Settings" WHERE "Setting_Key"=?',
        [args[0]],
      );
      final visible = await executor.runSelect(
        scope.readSql('SELECT "Person_ID" FROM "Persons"'),
        [],
      );
      final merged = mergeScopedSetting(
        args[0] as String,
        old.firstOrNull?['Setting_Value'] as String?,
        args[1] as String,
        visible.map((r) => r['Person_ID'].toString()).toSet(),
      );
      final incoming = args[1];
      // Drift binds the entity again for DO UPDATE, so replace both the INSERT
      // and conflict-update value bindings.
      args = args.map((value) => value == incoming ? merged : value).toList();
    }
    return executor.runInsert(statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final scope = context.applyLocally
        ? context.scope
        : const DataVisibilityScope();
    final rows = await executor.runSelect(scope.readSql(statement), args);
    if (!scope.restricted ||
        !RegExp('settings', caseSensitive: false).hasMatch(statement))
      return rows;
    // Settings contains legacy JSON records with embedded people. SQL row
    // filtering alone cannot protect those aggregates.
    final visible = await executor.runSelect(
      scope.readSql('SELECT "Person_ID" FROM "Persons"'),
      [],
    );
    final ids = visible.map((r) => r['Person_ID'].toString()).toSet();
    return rows.map((row) {
      final result = Map<String, Object?>.from(row);
      final keyCol = result.keys
          .where((k) => k.toLowerCase() == 'setting_key')
          .firstOrNull;
      final valueCol = result.keys
          .where((k) => k.toLowerCase() == 'setting_value')
          .firstOrNull;
      if (keyCol == null || valueCol == null || result[valueCol] is! String)
        return result;
      final key = result[keyCol];
      try {
        final raw = result[valueCol] as String;
        if (key == 'monthly_fund_payments_json') {
          final payments = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          payments.removeWhere((id, _) => !ids.contains(id));
          result[valueCol] = jsonEncode(payments);
        } else if (key == 'rohot_groups_json') {
          final groups = (jsonDecode(raw) as List)
              .whereType<Map>()
              .map((g) {
                final copy = Map<String, dynamic>.from(g);
                copy['members'] = (copy['members'] as List? ?? [])
                    .where((m) => m is Map && ids.contains(m['id'].toString()))
                    .toList();
                if (!ids.contains(copy['arifId']?.toString()))
                  copy['arifId'] = null;
                return copy;
              })
              .where((g) => (g['members'] as List).isNotEmpty)
              .toList();
          result[valueCol] = jsonEncode(groups);
        }
      } on FormatException {
        result[valueCol] = null;
      }
      return result;
    }).toList();
  }
}
