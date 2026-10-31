import 'dart:convert';

/// Missing dimensions mean all values; a present empty dimension means none.
/// Values within a dimension are OR-ed; the seven dimensions are AND-ed.
class DataVisibilityScope {
  static const dimensions = [
    'service',
    'gender',
    'stage',
    'khoros',
    'area',
    'rohot',
    'leader',
  ];
  static String storageKey(int userId) => 'user_data_scope_$userId';
  final Map<String, List<String>> selections;
  const DataVisibilityScope([this.selections = const {}]);
  bool get restricted => selections.isNotEmpty;
  factory DataVisibilityScope.fromLegacy(Map<String, List<int>> filters) =>
      DataVisibilityScope({
        for (final key in ['service', 'gender', 'stage', 'khoros', 'area'])
          if (filters.containsKey(key))
            key: filters[key]!
                .map(
                  (v) => key == 'gender'
                      ? (v == 1
                            ? 'ذكر'
                            : v == 2
                            ? 'أنثى'
                            : '')
                      : v.toString(),
                )
                .where((v) => v.isNotEmpty)
                .toList(),
      });
  String get fingerprint => jsonEncode(toJson());

  factory DataVisibilityScope.fromJson(Object? json) {
    if (json is! Map) return const DataVisibilityScope();
    return DataVisibilityScope({
      for (final key in dimensions)
        if (json.containsKey(key))
          key: json[key] is List
              ? ((json[key] as List).map((v) => v.toString()).toSet().toList()
                  ..sort())
              : <String>[],
    });
  }
  factory DataVisibilityScope.decode(String? value) {
    if (value == null || value.isEmpty) return const DataVisibilityScope();
    // Corrupt saved restrictions must never widen access.
    try {
      final json = jsonDecode(value);
      if (json is! Map || json.keys.any((k) => !dimensions.contains(k)))
        return const DataVisibilityScope({'stage': []});
      return DataVisibilityScope.fromJson(json);
    } catch (_) {
      return const DataVisibilityScope({'stage': []});
    }
  }
  Map<String, List<String>> toJson() => {
    for (final key in dimensions)
      if (selections.containsKey(key)) key: [...selections[key]!]..sort(),
  };

  static String literal(String value) => "'${value.replaceAll("'", "''")}'";

  /// SQLite CTEs shadow the public read tables, including raw SQL, subqueries,
  /// counts and exports. Base tables are explicitly qualified to avoid recursion.
  String readSql(String sql) {
    final metadata = sql.replaceAll(RegExp(r'[\s";]'), '').toLowerCase();
    // Allocating a unique public card code is separate from viewing people.
    // Only these scalar metadata statements bypass row filtering.
    if (metadata == 'selectcoalesce(max(person_id),0)+1asnext_idfrompersons' ||
        metadata == 'selectcount(*)asid_existsfrompersonswhereperson_id=?')
      return sql;
    if (!restricted ||
        !RegExp(r'^\s*(select|with)\b', caseSensitive: false).hasMatch(sql))
      return sql;
    final clauses = <String>[];
    String values(String key) => selections[key]!.map(literal).join(',');
    for (final entry in selections.entries) {
      if (entry.value.isEmpty) {
        clauses.add('0 = 1');
        continue;
      }
      final column = {
        'stage': 'Stage_ID',
        'khoros': 'Khoros_ID',
        'gender': 'Jender_Name',
        'rohot': 'Rohot',
        'leader': 'Leader',
      }[entry.key];
      if (column != null) clauses.add('p."$column" IN (${values(entry.key)})');
      if (entry.key == 'area')
        clauses.add('p."Area_ID" IN (SELECT "Area_ID" FROM "__scope_areas")');
      if (entry.key == 'service') {
        final ids = values('service');
        clauses.add(
          '''(EXISTS (SELECT 1 FROM main."Person_Services" ps WHERE ps."Person_ID"=p."Person_ID" AND ps."Service_ID" IN ($ids))
          OR EXISTS (SELECT 1 FROM main."Stage_Services" ss WHERE ss."Stage_ID"=p."Stage_ID" AND ss."Service_ID" IN ($ids))
          OR EXISTS (SELECT 1 FROM main."Khoros_Services" ks WHERE ks."Khoros_ID"=p."Khoros_ID" AND ks."Service_ID" IN ($ids))
          OR EXISTS (SELECT 1 FROM main."Stages" s WHERE s."Stage_ID"=p."Stage_ID" AND s."Service_ID" IN ($ids))
          OR EXISTS (SELECT 1 FROM main."Khoroses" k WHERE k."Khoros_ID"=p."Khoros_ID" AND k."Service_ID" IN ($ids)))''',
        );
      }
    }
    final areaIds = selections['area'];
    final ctes = <String>[
      if (areaIds != null && areaIds.isNotEmpty)
        '"__scope_areas" AS (SELECT "Area_ID" FROM main."Areas" WHERE "Area_ID" IN (${values('area')}) UNION SELECT a."Area_ID" FROM main."Areas" a JOIN "__scope_areas" b ON a."Parent_ID"=b."Area_ID")',
      '"__visible_persons" AS (SELECT p.* FROM main."Persons" p WHERE ${clauses.isEmpty ? '1=1' : clauses.join(' AND ')})',
      '"Persons" AS (SELECT * FROM "__visible_persons")',
      for (final table in [
        'Coming',
        'Visitations',
        'Absent_Persons',
        'Absent_Print',
        'Credit',
        'Person_Services',
        'Person_Tayo_Points',
        'person_custom_field_values',
        'person_documents',
        'Bus_Assignments',
      ])
        '"$table" AS (SELECT * FROM main."$table" WHERE "Person_ID" IN (SELECT "Person_ID" FROM "__visible_persons")${(table == 'Coming' || table == 'Visitations' || table == 'Person_Services') && selections.containsKey('service') ? ' AND "Service_ID" IN (${selections['service']!.isEmpty ? 'NULL' : values('service')})' : ''})',
      // Both sides of a relationship must be visible; otherwise even its label
      // or linked name could disclose another person's existence.
      '"Family_Relationships" AS (SELECT * FROM main."Family_Relationships" WHERE "Person_ID" IN (SELECT "Person_ID" FROM "__visible_persons") AND "Related_Person_ID" IN (SELECT "Person_ID" FROM "__visible_persons"))',
      for (final entry in {
        'stage': ['Stages', 'Stage_ID'],
        'khoros': ['Khoroses', 'Khoros_ID'],
      }.entries)
        '"${entry.value[0]}" AS (SELECT * FROM main."${entry.value[0]}" WHERE "${entry.value[1]}" IN (SELECT "${entry.value[1]}" FROM "__visible_persons")${selections.containsKey(entry.key) && selections[entry.key]!.isNotEmpty ? ' OR "${entry.value[1]}" IN (${values(entry.key)})' : ''})',
      '"Fathers" AS (SELECT * FROM main."Fathers" WHERE "Father_ID" IN (SELECT "Father_ID" FROM "__visible_persons"))',
      for (final entry in {
        'Stage_Services': ['Stage_ID', 'Stages'],
        'Khoros_Services': ['Khoros_ID', 'Khoroses'],
      }.entries)
        '"${entry.key}" AS (SELECT * FROM main."${entry.key}" WHERE "${entry.value[0]}" IN (SELECT "${entry.value[0]}" FROM "${entry.value[1]}")${selections.containsKey('service') ? ' AND "Service_ID" IN (${selections['service']!.isEmpty ? 'NULL' : values('service')})' : ''})',
      '"Bus_Drivers" AS (SELECT * FROM main."Bus_Drivers" WHERE "ID" IN (SELECT "Driver_ID" FROM "Bus_Assignments"))',
      '"__visible_area_tree" AS (SELECT "Area_ID","Parent_ID" FROM main."Areas" WHERE "Area_ID" IN (SELECT "Area_ID" FROM "__visible_persons") UNION SELECT a."Area_ID",a."Parent_ID" FROM main."Areas" a JOIN "__visible_area_tree" c ON a."Area_ID"=c."Parent_ID")',
      '"Areas" AS (SELECT * FROM main."Areas" WHERE "Area_ID" IN (SELECT "Area_ID" FROM "__visible_area_tree"))',
      '"Services" AS (SELECT * FROM main."Services" WHERE "Service_ID" IN (${selections.containsKey('service') ? (selections['service']!.isEmpty ? 'NULL' : values('service')) : 'SELECT "Service_ID" FROM "Person_Services" UNION SELECT s."Service_ID" FROM main."Stage_Services" s WHERE s."Stage_ID" IN (SELECT "Stage_ID" FROM "__visible_persons") UNION SELECT k."Service_ID" FROM main."Khoros_Services" k WHERE k."Khoros_ID" IN (SELECT "Khoros_ID" FROM "__visible_persons")'}))',
    ].join(', ');
    final existing = RegExp(
      r'^\s*WITH\s+(?:RECURSIVE\s+)?',
      caseSensitive: false,
    );
    return existing.hasMatch(sql)
        ? sql.replaceFirst(existing, 'WITH RECURSIVE $ctes, ')
        : 'WITH RECURSIVE $ctes $sql';
  }
}
