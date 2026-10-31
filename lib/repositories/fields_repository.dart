import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';

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
  final bool isPhone;

  FieldConfigDTO({
    required this.id,
    this.fieldKey,
    required this.name,
    required this.type,
    required this.options,
    required this.order,
    required this.isVisible,
    required this.isFilter,
    required this.isPhone,
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
      isPhone: d.isPhone ||
          d.fieldKey == 'mobile' ||
          d.fieldKey == 'phone' ||
          _isMatchesSpecificPhoneFieldName(d.name),
    );
  }
}

@riverpod
class FieldsRepository extends _$FieldsRepository {
  @override
  FutureOr<List<FieldConfigDTO>> build() async {
    ref.watch(domainRevisionProvider(DataDomain.fields));
    return fetchAll();
  }

  Future<List<FieldConfigDTO>> fetchAll() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(
      db.customFieldDefinitions,
    )..orderBy([(t) => OrderingTerm.asc(t.fieldOrder)])).get();
    return rows.map((r) => FieldConfigDTO.fromDb(r)).toList();
  }

  Future<void> updateFieldVisibility(int id, bool isVisible) async {
    final db = ref.read(appDatabaseProvider);
    final field = await (db.select(
      db.customFieldDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (field != null) {
      await (db.update(db.customFieldDefinitions)
            ..where((t) => t.id.equals(id)))
          .write(CustomFieldDefinitionsCompanion(isVisible: Value(isVisible)));
      if (field.fieldKey == 'rohot' && isVisible) {
        await (db.update(
          db.customFieldDefinitions,
        )..where((t) => t.fieldKey.equals('leader'))).write(
          const CustomFieldDefinitionsCompanion(isVisible: Value(true)),
        );
      }
    }
    if (ref.mounted) ref.invalidateSelf();
  }

  Future<void> updateFieldFilter(int id, bool isFilter) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.customFieldDefinitions)..where((t) => t.id.equals(id)))
        .write(CustomFieldDefinitionsCompanion(isFilter: Value(isFilter)));
    if (ref.mounted) ref.invalidateSelf();
  }

  Future<void> reorderFields(List<FieldConfigDTO> fields) async {
    final db = ref.read(appDatabaseProvider);
    await db.batch((batch) {
      for (int i = 0; i < fields.length; i++) {
        batch.update(
          db.customFieldDefinitions,
          CustomFieldDefinitionsCompanion(fieldOrder: Value(i)),
          where: (t) => t.id.equals(fields[i].id),
        );
      }
    });
    if (ref.mounted) ref.invalidateSelf();
  }

  Future<bool> addCustomField({
    required String name,
    required String
    type, // 'text', 'dropdown', 'multi_select', 'checkbox', 'document'
    List<String>? options,
    bool isFilter = false,
    bool isPhone = false,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final all = await fetchAll();
      final nextOrder = all.isEmpty ? 0 : all.last.order + 1;

      await db
          .into(db.customFieldDefinitions)
          .insert(
            CustomFieldDefinitionsCompanion.insert(
              name: name,
              type: type,
              fieldOrder: nextOrder,
              options: Value(options != null ? jsonEncode(options) : null),
              isFilter: Value(isFilter),
              isPhone: Value(type == 'text' && isPhone),
            ),
          );
      if (ref.mounted) ref.invalidateSelf();
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
    bool? isPhone,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.update(
        db.customFieldDefinitions,
      )..where((t) => t.id.equals(id))).write(
        CustomFieldDefinitionsCompanion(
          name: Value(name),
          type: Value(type),
          options: Value(options != null ? jsonEncode(options) : null),
          isFilter: isFilter != null ? Value(isFilter) : const Value.absent(),
          isVisible: isVisible != null
              ? Value(isVisible)
              : const Value.absent(),
          isPhone: isPhone != null
              ? Value(type == 'text' && isPhone)
              : const Value.absent(),
        ),
      );
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error updating custom field: $e');
      return false;
    }
  }

  Future<bool> addOptionToCustomField(int id, String newOption) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final field = await (db.select(
        db.customFieldDefinitions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (field != null) {
        List<String> opts = [];
        if (field.options != null && field.options!.isNotEmpty) {
          try {
            opts = List<String>.from(jsonDecode(field.options!));
          } catch (_) {}
        }
        if (!opts.contains(newOption)) {
          opts.add(newOption);
          await (db.update(
            db.customFieldDefinitions,
          )..where((t) => t.id.equals(id))).write(
            CustomFieldDefinitionsCompanion(options: Value(jsonEncode(opts))),
          );
          if (ref.mounted) ref.invalidateSelf();
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
      await (db.delete(
        db.customFieldDefinitions,
      )..where((t) => t.id.equals(id))).go();
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error deleting custom field: $e');
      return false;
    }
  }
}

bool _isMatchesSpecificPhoneFieldName(String name) {
  String normalized = name.toLowerCase();

  // Normalize Alef
  normalized = normalized
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');

  // Collapse multiple Alefs (e.g., 'اامر' -> 'امر')
  while (normalized.contains('اا')) {
    normalized = normalized.replaceAll('اا', 'ا');
  }

  // Normalize other Arabic letters and digits, remove spaces/punctuation
  normalized = normalized
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(' ', '')
      .replaceAll('_', '')
      .replaceAll('-', '')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll('٠', '0');

  // Match variants of:
  // - رقم ولي الامر 1 / رقم ولي الامر 2
  // - رقم الطالب / موبايل الطالب / تليفون الطالب / هاتف الطالب
  return normalized.contains('رقموليالامر1') ||
      normalized.contains('رقموليالامر2') ||
      normalized.contains('وليالامر1') ||
      normalized.contains('وليالامر2') ||
      normalized.contains('رقمالطالب') ||
      normalized.contains('موبايلالطالب') ||
      normalized.contains('تليفونالطالب') ||
      normalized.contains('هاتفالطالب') ||
      normalized.contains('هاتفعالطالب') ||
      normalized.contains('موبايلوليالامر') ||
      normalized.contains('تليفونوليالامر');
}
