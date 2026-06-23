import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'fields_repository.g.dart';

class FieldConfigDTO {
  final int id;
  final String? fieldKey;
  final String name;
  final String type;
  final List<String> options;
  final int order;
  final bool isVisible;
  final bool isFilter;

  FieldConfigDTO({
    required this.id,
    this.fieldKey,
    required this.name,
    required this.type,
    required this.options,
    required this.order,
    required this.isVisible,
    required this.isFilter,
  });

  factory FieldConfigDTO.fromDb(CustomFieldDefinition d) {
    List<String> opts = [];
    if (d.options != null && d.options!.isNotEmpty) {
      try {
        opts = List<String>.from(jsonDecode(d.options!));
      } catch (_) {}
    }
    return FieldConfigDTO(
      id: d.id,
      fieldKey: d.fieldKey,
      name: d.name,
      type: d.type,
      options: opts,
      order: d.fieldOrder,
      isVisible: d.isVisible,
      isFilter: d.isFilter,
    );
  }
}

@riverpod
class FieldsRepository extends _$FieldsRepository {
  @override
  FutureOr<List<FieldConfigDTO>> build() async {
    return fetchAll();
  }

  Future<List<FieldConfigDTO>> fetchAll() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.customFieldDefinitions)
      ..orderBy([(t) => OrderingTerm.asc(t.fieldOrder)])).get();
    return rows.map((r) => FieldConfigDTO.fromDb(r)).toList();
  }

  Future<void> updateFieldVisibility(int id, bool isVisible) async {
    final db = ref.read(appDatabaseProvider);
    final field = await (db.select(db.customFieldDefinitions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (field != null) {
      await (db.update(db.customFieldDefinitions)..where((t) => t.id.equals(id)))
          .write(CustomFieldDefinitionsCompanion(isVisible: Value(isVisible)));
      if (field.fieldKey == 'rohot' && isVisible) {
        await (db.update(db.customFieldDefinitions)..where((t) => t.fieldKey.equals('leader')))
            .write(const CustomFieldDefinitionsCompanion(isVisible: Value(true)));
      }
    }
    ref.invalidateSelf();
  }

  Future<void> updateFieldFilter(int id, bool isFilter) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.customFieldDefinitions)..where((t) => t.id.equals(id)))
        .write(CustomFieldDefinitionsCompanion(isFilter: Value(isFilter)));
    ref.invalidateSelf();
  }

  Future<void> reorderFields(List<FieldConfigDTO> fields) async {
    final db = ref.read(appDatabaseProvider);
    await db.batch((batch) {
      for (int i = 0; i < fields.length; i++) {
        batch.update(db.customFieldDefinitions,
            CustomFieldDefinitionsCompanion(fieldOrder: Value(i)),
            where: (t) => t.id.equals(fields[i].id));
      }
    });
    ref.invalidateSelf();
  }

  Future<bool> addCustomField({
    required String name,
    required String type, // 'text', 'dropdown', 'multi_select', 'checkbox', 'document'
    List<String>? options,
    bool isFilter = false,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final all = await fetchAll();
      final nextOrder = all.isEmpty ? 0 : all.last.order + 1;
      
      await db.into(db.customFieldDefinitions).insert(CustomFieldDefinitionsCompanion.insert(
        name: name,
        type: type,
        fieldOrder: nextOrder,
        options: Value(options != null ? jsonEncode(options) : null),
        isFilter: Value(isFilter),
      ));
      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error adding custom field: $e');
      return false;
    }
  }
  
  Future<bool> updateCustomField({
    required int id,
    required String name,
    required String type,
    List<String>? options,
    bool? isFilter,
    bool? isVisible,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.customFieldDefinitions)..where((t) => t.id.equals(id))).write(
        CustomFieldDefinitionsCompanion(
          name: Value(name),
          type: Value(type),
          options: Value(options != null ? jsonEncode(options) : null),
          isFilter: isFilter != null ? Value(isFilter) : const Value.absent(),
          isVisible: isVisible != null ? Value(isVisible) : const Value.absent(),
        ),
      );
      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error updating custom field: $e');
      return false;
    }
  }

  Future<bool> addOptionToCustomField(int id, String newOption) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final field = await (db.select(db.customFieldDefinitions)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (field != null) {
        List<String> opts = [];
        if (field.options != null && field.options!.isNotEmpty) {
          try {
            opts = List<String>.from(jsonDecode(field.options!));
          } catch (_) {}
        }
        if (!opts.contains(newOption)) {
          opts.add(newOption);
          await (db.update(db.customFieldDefinitions)..where((t) => t.id.equals(id)))
              .write(CustomFieldDefinitionsCompanion(options: Value(jsonEncode(opts))));
          ref.invalidateSelf();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error adding option to custom field: $e');
      return false;
    }
  }

  Future<bool> deleteCustomField(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.customFieldDefinitions)..where((t) => t.id.equals(id))).go();
      ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error deleting custom field: $e');
      return false;
    }
  }
}
