import 'dart:convert';

/// Preserve records outside the caller's scope when saving legacy JSON values.
/// Reject submitted IDs outside the scope instead of silently widening it.
String mergeScopedSetting(
  String key,
  String? previous,
  String incoming,
  Set<String> visibleIds,
) {
  if (key == 'monthly_fund_payments_json') {
    final old = previous == null || previous.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(previous) as Map);
    final next = Map<String, dynamic>.from(jsonDecode(incoming) as Map);
    if (next.keys.any((id) => !visibleIds.contains(id)))
      throw StateError('المدفوعات خارج نطاق رؤية المستخدم');
    return jsonEncode({
      ...(old..removeWhere((id, _) => visibleIds.contains(id))),
      ...next,
    });
  }
  if (key == 'rohot_groups_json') {
    final old = previous == null || previous.isEmpty
        ? <dynamic>[]
        : jsonDecode(previous) as List;
    final next = jsonDecode(incoming) as List;
    final groups = <String, Map<String, dynamic>>{};
    for (final item in old.whereType<Map>()) {
      final group = Map<String, dynamic>.from(item);
      final hidden = (group['members'] as List? ?? [])
          .where((m) => m is Map && !visibleIds.contains(m['id'].toString()))
          .toList();
      if (hidden.isNotEmpty)
        groups[group['name'].toString()] = {...group, 'members': hidden};
    }
    final names = <String>{};
    for (final item in next.whereType<Map>()) {
      final group = Map<String, dynamic>.from(item);
      final name = group['name'].toString();
      if (!names.add(name)) throw StateError('اسم رهط مكرر');
      final members = group['members'] as List? ?? [];
      if (members.any(
        (m) => m is! Map || !visibleIds.contains(m['id'].toString()),
      ))
        throw StateError('أعضاء الرهط خارج نطاق المستخدم');
      final protected = groups[name];
      groups[name] = protected == null
          ? group
          : {
              ...protected,
              'members': [...(protected['members'] as List), ...members],
            };
    }
    return jsonEncode(groups.values.toList());
  }
  return incoming;
}
