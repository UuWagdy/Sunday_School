import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../models/card_template.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(appDatabaseProvider));
});

final programNameProvider = FutureProvider<String>((ref) {
  return ref.watch(settingsRepositoryProvider).getProgramName();
});

class SettingsRepository {
  static const String programNameKey = 'program_name';
  static const String idCardActiveTemplateKey = 'id_card_active_template';
  static const String defaultProgramName = 'برنامج مدارس الأحد';
  static const int maxProgramNameLength = 80;

  final AppDatabase _db;

  SettingsRepository(this._db);

  Future<String?> getSetting(String key) async {
    final query = _db.select(_db.settings)..where((t) => t.settingKey.equals(key));
    final result = await query.getSingleOrNull();
    return result?.settingValue;
  }

  Future<void> saveSetting(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingsCompanion(
        settingKey: drift.Value(key),
        settingValue: drift.Value(value),
      ),
    );
  }

  Future<void> deleteSetting(String key) async {
    await (_db.delete(_db.settings)..where((t) => t.settingKey.equals(key))).go();
  }

  Future<String> getProgramName() async {
    final value = await getSetting(programNameKey);
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return defaultProgramName;
    }
    return trimmed;
  }

  Future<void> saveProgramName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'اسم البرنامج مطلوب');
    }
    if (trimmed.length > maxProgramNameLength) {
      throw ArgumentError.value(value, 'value', 'اسم البرنامج طويل جدًا');
    }
    await saveSetting(programNameKey, trimmed);
  }

  Future<void> deleteProgramName() async {
    await deleteSetting(programNameKey);
  }

  Future<CardTemplate> getActiveCardTemplate() async {
    final value = await getSetting(idCardActiveTemplateKey);
    if (value == null || value.trim().isEmpty) {
      return CardTemplate.defaults();
    }
    final template = CardTemplate.fromJsonString(value);
    return template.validate().isEmpty ? template : CardTemplate.defaults();
  }

  Future<void> saveActiveCardTemplate(CardTemplate template) async {
    final errors = template.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError.value(template, 'template', errors.join('\n'));
    }
    await saveSetting(idCardActiveTemplateKey, template.toJsonString());
  }

  Future<void> deleteActiveCardTemplate() async {
    await deleteSetting(idCardActiveTemplateKey);
  }

  Future<Uint8List?> getChurchLogo() async {
    final base64Str = await getSetting('church_logo');
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        return base64Decode(base64Str);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> setChurchLogo(Uint8List bytes) async {
    final base64Str = base64Encode(bytes);
    await saveSetting('church_logo', base64Str);
  }
}
