import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('consolidates duplicate imported guardian phone fields', () async {
    await database.customStatement('''
      INSERT INTO "Persons" ("Person_ID", "Person_Name", "Phone", "Mobile")
      VALUES (1384, 'Test Person', '01221128289', '01282310831');
    ''');
    await database.customStatement('''
      INSERT INTO "custom_field_definitions"
        ("id", "Field_Key", "Name", "Type", "Field_Order")
      VALUES
        (353, 'excel_guardian_phone_1', 'Guardian 1', 'text', 20),
        (354, 'excel_guardian_phone_2', 'Guardian 2', 'text', 21);
    ''');
    await database.customStatement('''
      INSERT INTO "person_custom_field_values"
        ("Person_ID", "Field_ID", "Value")
      VALUES
        (1384, 353, '01221128289'),
        (1384, 354, '01282310831');
    ''');

    await database.consolidateImportedGuardianPhoneFields();

    final person = await database.customSelect('''
      SELECT "Phone", "Mobile" FROM "Persons" WHERE "Person_ID" = 1384;
    ''').getSingle();
    final duplicateDefinitions = await database.customSelect('''
      SELECT COUNT(*) AS item_count
      FROM "custom_field_definitions"
      WHERE "Field_Key" IN (
        'excel_guardian_phone_1',
        'excel_guardian_phone_2'
      );
    ''').getSingle();

    expect(person.read<String>('Phone'), '01221128289');
    expect(person.read<String>('Mobile'), '01282310831');
    expect(duplicateDefinitions.read<int>('item_count'), 0);
  });

  test('moves an imported number when the native field is empty', () async {
    await database.customStatement('''
      INSERT INTO "Persons" ("Person_ID", "Person_Name", "Phone")
      VALUES (1384, 'Test Person', '');
    ''');
    await database.customStatement('''
      INSERT INTO "custom_field_definitions"
        ("id", "Field_Key", "Name", "Type", "Field_Order")
      VALUES (353, 'excel_guardian_phone_1', 'Guardian 1', 'text', 20);
    ''');
    await database.customStatement('''
      INSERT INTO "person_custom_field_values"
        ("Person_ID", "Field_ID", "Value")
      VALUES (1384, 353, '01221128289');
    ''');

    await database.consolidateImportedGuardianPhoneFields();

    final person = await database.customSelect('''
      SELECT "Phone" FROM "Persons" WHERE "Person_ID" = 1384;
    ''').getSingle();
    expect(person.read<String>('Phone'), '01221128289');
  });

  test('runs the consolidation while upgrading schema 36 to 37', () async {
    await database.close();
    final tempDirectory = Directory.systemTemp.createTempSync(
      'guardian_phone_migration_',
    );
    final databaseFile = File('${tempDirectory.path}/migration.db');
    AppDatabase? migratedDatabase;

    try {
      final oldDatabase = AppDatabase.forTesting(NativeDatabase(databaseFile));
      await oldDatabase.customStatement('''
        INSERT INTO "Persons" ("Person_ID", "Person_Name", "Phone")
        VALUES (1384, 'Test Person', '01221128289');
      ''');
      await oldDatabase.customStatement('''
        INSERT INTO "custom_field_definitions"
          ("id", "Field_Key", "Name", "Type", "Field_Order")
        VALUES (353, 'excel_guardian_phone_1', 'Guardian 1', 'text', 20);
      ''');
      await oldDatabase.customStatement('''
        INSERT INTO "person_custom_field_values"
          ("Person_ID", "Field_ID", "Value")
        VALUES (1384, 353, '01221128289');
      ''');
      await oldDatabase.customStatement('PRAGMA user_version = 36;');
      await oldDatabase.close();

      migratedDatabase = AppDatabase.forTesting(NativeDatabase(databaseFile));
      final duplicateDefinitions = await migratedDatabase.customSelect('''
        SELECT COUNT(*) AS item_count
        FROM "custom_field_definitions"
        WHERE "Field_Key" = 'excel_guardian_phone_1';
      ''').getSingle();

      expect(duplicateDefinitions.read<int>('item_count'), 0);
    } finally {
      await migratedDatabase?.close();
      tempDirectory.deleteSync(recursive: true);
    }
  });
}
