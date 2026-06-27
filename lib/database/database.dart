import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    AbsentPersons,
    AbsentPrint,
    Adding,
    Areas,
    Coming,
    Visitations,
    Credit,
    Fathers,
    Jender,
    Pass,
    Persons,
    Stages,
    Settings,
    TayoCards,
    PersonTayoPoints,
    Services,
    Khoroses,
    KhorosServices,
    StageServices,
    PersonServices,
    UserPermissionsExt,
    UserVisibilityFilters,
    CustomFieldDefinitions,
    PersonCustomFieldValues,
    PersonDocuments,
    FamilyRelationships,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 36;

  Future<void> _createTableSafely(Migrator m, TableInfo table) async {
    try {
      await m.createTable(table);
    } catch (e) {
      if (e.toString().contains('already exists')) {
        print(
          'FLUTTER DB: Table ${table.actualTableName} already exists, skipping create.',
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureServiceLinkTablesExist();
      await _seedLegacyServiceLinks();
      await _seedNativeFields();
      await _seedAdminUser();
    },
    onUpgrade: (m, from, to) async {
      print('FLUTTER DB: Upgrading from $from to $to');

      if (from < 14) {
        await _createTableSafely(m, personTayoPoints);
        await _createTableSafely(m, tayoCards);
        await _addColumnSafely(m, personTayoPoints, personTayoPoints.serviceId);
      }
      if (from < 15) {
        await _addColumnSafely(m, pass, pass.canServices);
      }
      if (from < 16) {
        await _createTableSafely(m, khoroses);
        await _addColumnSafely(m, persons, persons.khorosId);
        await _addColumnSafely(m, absentPrint, absentPrint.khorosId);
        await _addColumnSafely(m, pass, pass.canKhoros);
      }
      if (from < 19) {
        await _createTableSafely(m, personServices);
        await _createTableSafely(m, userPermissionsExt);
        await _createTableSafely(m, userVisibilityFilters);
        await _addColumnSafely(m, pass, pass.isAdvanced);
      }
      if (from < 20) {
        await _addColumnSafely(m, coming, coming.checkoutTime);
        await _addColumnSafely(m, services, services.endHour);
        await _addColumnSafely(m, services, services.endMinute);
      }
      if (from < 21) {
        await _createTableSafely(m, customFieldDefinitions);
        await _createTableSafely(m, personCustomFieldValues);
        await _seedNativeFields();
      }

      if (from < 22) {
        await _createTableSafely(m, personDocuments);
      }

      if (from < 23) {
        await _createTableSafely(m, familyRelationships);
      }

      if (from < 24) {
        await _addColumnSafely(m, areas, areas.parentId);
        await _addColumnSafely(m, areas, areas.level);
        await _addColumnSafely(m, areas, areas.areaPath);
        await customStatement(
          "UPDATE Areas SET Parent_ID = NULL, Level = 0, Area_Path = '/' || Area_ID || '/';",
        ).catchError((_) => null);
      }

      if (from < 29) {
        // Version 29: Final Ultra Repair
        await _repairPassTableRaw();
        await _ensureAllColumnsAndTablesExist(m);
      }

      if (from < 30) {
        await _addColumnSafely(m, stages, stages.serviceId);
        await _addColumnSafely(m, khoroses, khoroses.serviceId);
        await _addColumnSafely(m, stages, stages.nextStageId);
        await _addColumnSafely(m, coming, coming.behavior);
      }

      if (from < 31) {
        await _addColumnSafely(m, pass, pass.canBehavior);
      }

      if (from < 32) {
        await _ensureServiceLinkTablesExist();
        await _seedLegacyServiceLinks();
      }

      if (from < 33) {
        await _addColumnSafely(m, persons, persons.rohot);
        await _ensureCustomFieldDefinitionTableExists();
        await _seedNativeFields();
      }

      if (from < 34) {
        await _addColumnSafely(
          m,
          persons,
          persons.leader as GeneratedColumn<Object>,
        );
        await _ensureCustomFieldDefinitionTableExists();
        await _seedNativeFields();
      }

      if (from < 35) {
        await _createTableSafely(m, visitations);
        await _ensureAdminExtendedPermissions();
      }
      if (from < 36) {
        await _ensureCustomFieldDefinitionTableExists();
        await _addColumnSafely(
          m,
          customFieldDefinitions,
          customFieldDefinitions.isPhone,
        );
      }
      // Repair phase: Fix any null IDs that might cause crashes during mapping
      await _repairBrokenIds();
    },
    beforeOpen: (details) async {
      // Extra safety: Every time we open, we check the Pass table specifically
      // using RAW SQL because Drift Migrator might fail if the schema is too old.
      await _repairPassTableRaw();
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureServiceLinkTablesExist();
      await _seedLegacyServiceLinks();
      await _ensureCustomFieldDefinitionTableExists();
      await _seedNativeFields();
      await _ensureVisitationTablesExist();
      await _ensureAdminExtendedPermissions();
    },
  );

  Future<void> _repairPassTableRaw() async {
    print('FLUTTER DB: Verifying Pass table schema...');
    try {
      // 1. Get existing columns via PRAGMA
      final result = await customSelect('PRAGMA table_info("Pass")').get();
      final existingColumns = result
          .map((row) => (row.data['name'] as String).toLowerCase())
          .toList();

      final columnsToAdd = [
        'can_persons',
        'can_stages',
        'can_areas',
        'can_fathers',
        'can_reports',
        'can_users',
        'can_absence',
        'can_maintenance',
        'can_id_card',
        'can_tayo',
        'can_transfer',
        'can_services',
        'can_khoros',
        'can_behavior',
        'is_advanced',
      ];

      for (final col in columnsToAdd) {
        if (!existingColumns.contains(col.toLowerCase())) {
          try {
            await customStatement(
              'ALTER TABLE "Pass" ADD COLUMN "$col" INTEGER DEFAULT 0;',
            );
            print('FLUTTER DB: Safely added missing column: $col');
          } catch (_) {}
        }
      }

      // 2. Force refresh admin permissions to "Regular" with all flags
      await customStatement('''
        UPDATE "Pass" SET 
          can_persons = 1, can_stages = 1, can_areas = 1, can_fathers = 1, 
          can_reports = 1, can_users = 1, can_absence = 1, can_maintenance = 1, 
          can_id_card = 1, can_tayo = 1, can_transfer = 1, can_services = 1, 
          can_khoros = 1, can_behavior = 1, is_advanced = 0
        WHERE Person_Name = 'admin';
      ''');
    } catch (e) {
      print('FLUTTER DB IRRECOVERABLE REPAIR ERROR: $e');
    }
  }

  Future<void> _ensureAllColumnsAndTablesExist(Migrator m) async {
    final List<TableInfo> tables = [
      personTayoPoints,
      tayoCards,
      khoroses,
      personServices,
      userPermissionsExt,
      userVisibilityFilters,
      customFieldDefinitions,
      personCustomFieldValues,
      personDocuments,
      familyRelationships,
      visitations,
      absentPersons,
      absentPrint,
      credit,
      jender,
      stages,
      areas,
      fathers,
      persons,
      coming,
      pass,
      services,
      adding,
      settings,
    ];
    for (final table in tables) {
      await _createTableSafely(m, table);
    }

    try {
      await _addColumnSafely(m, pass, pass.canPersons);
      await _addColumnSafely(m, pass, pass.canStages);
      await _addColumnSafely(m, pass, pass.canAreas);
      await _addColumnSafely(m, pass, pass.canFathers);
      await _addColumnSafely(m, pass, pass.canReports);
      await _addColumnSafely(m, pass, pass.canUsers);
      await _addColumnSafely(m, pass, pass.canAbsence);
      await _addColumnSafely(m, pass, pass.canMaintenance);
      await _addColumnSafely(m, pass, pass.canIdCard);
      await _addColumnSafely(m, pass, pass.canTayo);
      await _addColumnSafely(m, pass, pass.canTransfer);
      await _addColumnSafely(m, pass, pass.canServices);
      await _addColumnSafely(m, pass, pass.canKhoros);
      await _addColumnSafely(m, pass, pass.canBehavior);
      await _addColumnSafely(m, pass, pass.isAdvanced);
    } catch (_) {}

    // Other tables
    await _addColumnSafely(m, areas, areas.parentId);
    await _addColumnSafely(m, areas, areas.level);
    await _addColumnSafely(m, areas, areas.areaPath);
    await _addColumnSafely(m, personTayoPoints, personTayoPoints.notes);
    await _addColumnSafely(m, personTayoPoints, personTayoPoints.serviceId);
    await _addColumnSafely(m, coming, coming.serviceId);
    await _addColumnSafely(m, coming, coming.attendTime);
    await _addColumnSafely(m, coming, coming.visited);
    await _addColumnSafely(m, coming, coming.visitNotes);
    await _addColumnSafely(m, persons, persons.khorosId);
    await _addColumnSafely(m, absentPrint, absentPrint.khorosId);
    await _addColumnSafely(m, services, services.logo);
    await _addColumnSafely(m, khoroses, khoroses.logo);
    await _addColumnSafely(m, coming, coming.checkoutTime);
    await _addColumnSafely(m, services, services.endHour);
    await _addColumnSafely(m, services, services.endMinute);
    await _addColumnSafely(m, stages, stages.serviceId);
    await _addColumnSafely(m, khoroses, khoroses.serviceId);
    await _addColumnSafely(m, stages, stages.nextStageId);
    await _addColumnSafely(m, coming, coming.behavior);
    await _addColumnSafely(m, persons, persons.rohot);
    await _addColumnSafely(
      m,
      persons,
      persons.leader as GeneratedColumn<Object>,
    );
    await _ensureServiceLinkTablesExist();
    await _ensureVisitationTablesExist();
    await _ensureAdminExtendedPermissions();
    await _seedLegacyServiceLinks();
  }

  Future<void> _ensureVisitationTablesExist() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS "Visitations" (
        "ID" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "Person_ID" INTEGER NOT NULL,
        "Service_ID" INTEGER NULL,
        "Visit_Date" TEXT NOT NULL,
        "Is_Visited" INTEGER NOT NULL DEFAULT 0,
        "Visit_Type" TEXT NOT NULL DEFAULT 'تليفون',
        "Notes" TEXT NULL,
        "Created_At" INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        "Updated_At" INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY ("Person_ID") REFERENCES "Persons" ("Person_ID") ON DELETE CASCADE,
        FOREIGN KEY ("Service_ID") REFERENCES "Services" ("Service_ID") ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _ensureCustomFieldDefinitionTableExists() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS "custom_field_definitions" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "Field_Key" TEXT NULL UNIQUE,
        "Name" TEXT NOT NULL,
        "Type" TEXT NOT NULL,
        "Options" TEXT NULL,
        "Field_Order" INTEGER NOT NULL,
        "Is_Visible" INTEGER NOT NULL DEFAULT 1,
        "Is_Filter" INTEGER NOT NULL DEFAULT 0,
        "Is_Phone" INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await _ensureColumnExists(
      tableName: 'custom_field_definitions',
      columnName: 'Is_Phone',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _ensureColumnExists({
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await customSelect('PRAGMA table_info("$tableName")').get();
    final exists = columns.any(
      (row) =>
          (row.data['name'] as String?)?.toLowerCase() ==
          columnName.toLowerCase(),
    );
    if (!exists) {
      await customStatement(
        'ALTER TABLE "$tableName" ADD COLUMN "$columnName" $definition;',
      );
    }
  }

  Future<void> _ensureAdminExtendedPermissions() async {
    try {
      final existingTables = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('Pass', 'User_Permissions_Ext')",
      ).get();
      final tableNames = existingTables
          .map((row) => row.data['name'] as String?)
          .whereType<String>()
          .toSet();
      if (!tableNames.contains('Pass') ||
          !tableNames.contains('User_Permissions_Ext')) {
        return;
      }

      await customStatement('''
        INSERT OR REPLACE INTO "User_Permissions_Ext"
          ("User_ID", "Feature_Key", "can_add", "can_edit", "can_delete")
        SELECT "Pass_ID", 'visitation', 1, 1, 1
        FROM "Pass"
        WHERE "Person_Name" = 'admin';
      ''');
    } catch (e) {
      print('FLUTTER DB ERROR seeding admin extended permissions: $e');
    }
  }

  Future<void> _ensureServiceLinkTablesExist() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS "Khoros_Services" (
        "Khoros_ID" INTEGER NOT NULL,
        "Service_ID" INTEGER NOT NULL,
        PRIMARY KEY ("Khoros_ID", "Service_ID"),
        FOREIGN KEY ("Khoros_ID") REFERENCES "Khoroses" ("Khoros_ID") ON DELETE CASCADE,
        FOREIGN KEY ("Service_ID") REFERENCES "Services" ("Service_ID") ON DELETE CASCADE
      );
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS "Stage_Services" (
        "Stage_ID" INTEGER NOT NULL,
        "Service_ID" INTEGER NOT NULL,
        PRIMARY KEY ("Stage_ID", "Service_ID"),
        FOREIGN KEY ("Stage_ID") REFERENCES "Stages" ("Stage_ID") ON DELETE CASCADE,
        FOREIGN KEY ("Service_ID") REFERENCES "Services" ("Service_ID") ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _seedLegacyServiceLinks() async {
    try {
      await customStatement('''
        INSERT OR IGNORE INTO "Khoros_Services" ("Khoros_ID", "Service_ID")
        SELECT "Khoros_ID", "Service_ID"
        FROM "Khoroses"
        WHERE "Khoros_ID" IS NOT NULL AND "Service_ID" IS NOT NULL;
      ''');
      await customStatement('''
        INSERT OR IGNORE INTO "Stage_Services" ("Stage_ID", "Service_ID")
        SELECT "Stage_ID", "Service_ID"
        FROM "Stages"
        WHERE "Stage_ID" IS NOT NULL AND "Service_ID" IS NOT NULL;
      ''');
    } catch (e) {
      print('FLUTTER DB ERROR seeding legacy service links: $e');
    }
  }

  Future<void> _repairBrokenIds() async {
    try {
      final tablesToRepair = [
        ['Pass', 'Pass_ID'],
        ['Persons', 'Person_ID'],
        ['Areas', 'Area_ID'],
        ['Stages', 'Stage_ID'],
        ['Fathers', 'Father_ID'],
        ['Services', 'Service_ID'],
        ['Khoroses', 'Khoros_ID'],
        ['Tayo_Cards', 'Card_ID'],
        ['Person_Tayo_Points', 'ID'],
      ];

      for (final table in tablesToRepair) {
        final tableName = table[0];
        final idColumn = table[1];
        await customStatement(
          'UPDATE "$tableName" SET "$idColumn" = rowid WHERE "$idColumn" IS NULL OR "$idColumn" = 0;',
        );
      }
    } catch (_) {}
  }

  Future<void> _addColumnSafely(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate') || msg.contains('already exists')) {
        // Expected
      } else {
        print('FLUTTER DB ERROR adding column ${column.name}: $e');
      }
    }
  }

  Future<void> _seedNativeFields() async {
    final nativeFields = [
      {
        'key': 'name',
        'name': 'الاسم رباعي',
        'order': 0,
        'filter': false,
        'visible': true,
      },
      {
        'key': 'gender',
        'name': 'النوع',
        'order': 1,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'stage',
        'name': 'المرحلة',
        'order': 2,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'mobile',
        'name': 'الموبايل',
        'order': 3,
        'filter': false,
        'visible': true,
      },
      {
        'key': 'phone',
        'name': 'التليفون الأرضي',
        'order': 4,
        'filter': false,
        'visible': true,
      },
      {
        'key': 'area',
        'name': 'المنطقة',
        'order': 5,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'street',
        'name': 'العنوان/الشارع',
        'order': 6,
        'filter': false,
        'visible': true,
      },
      {
        'key': 'father',
        'name': 'أب الاعتراف',
        'order': 7,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'khoros',
        'name': 'الخورس',
        'order': 8,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'services',
        'name': 'الخدمات',
        'order': 9,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'birthday',
        'name': 'تاريخ الميلاد',
        'order': 10,
        'filter': true,
        'visible': true,
      },
      {
        'key': 'rohot',
        'name': 'الرهط',
        'order': 11,
        'filter': true,
        'visible': false,
      },
      {
        'key': 'leader',
        'name': 'القائد',
        'order': 12,
        'filter': true,
        'visible': false,
      },
    ];

    for (final f in nativeFields) {
      await into(customFieldDefinitions).insert(
        CustomFieldDefinitionsCompanion.insert(
          fieldKey: Value(f['key'] as String),
          name: f['name'] as String,
          type: 'native',
          fieldOrder: f['order'] as int,
          isVisible: Value(f['visible'] as bool),
          isFilter: Value(f['filter'] as bool),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    await (update(customFieldDefinitions)
          ..where((tbl) => tbl.fieldKey.isIn(['mobile', 'phone'])))
        .write(const CustomFieldDefinitionsCompanion(isPhone: Value(true)));
  }

  Future<void> _seedAdminUser() async {
    // Only seed admin if the Pass table is COMPLETELY EMPTY
    final anyUser = await (select(pass)..limit(1)).getSingleOrNull();
    if (anyUser != null) {
      print('FLUTTER DB: Pass table not empty, skipping admin seeding.');
      return;
    }

    final companion = PassCompanion.insert(
      personName: const Value('admin'),
      passWord: const Value('1234'),
      canPersons: const Value(true),
      canStages: const Value(true),
      canAreas: const Value(true),
      canFathers: const Value(true),
      canReports: const Value(true),
      canUsers: const Value(true),
      canAbsence: const Value(true),
      canMaintenance: const Value(true),
      canIdCard: const Value(true),
      canTayo: const Value(true),
      canTransfer: const Value(true),
      canServices: const Value(true),
      canKhoros: const Value(true),
      canBehavior: const Value(true),
      isAdvanced: const Value(false), // Regular user as requested
    );

    await into(pass).insert(companion);
    print('FLUTTER DB: Seeded default admin user.');
  }

  Future<Uint8List?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        if (result.files.single.bytes != null) return result.files.single.bytes;
        if (result.files.single.path != null)
          return await File(result.files.single.path!).readAsBytes();
      }
    } catch (e) {
      print('DEBUG: Error picking image: $e');
    }
    return null;
  }

  Future<List<int>> getAreaAndDescendantIds(int areaId) async {
    final area = await (select(
      areas,
    )..where((t) => t.areaId.equals(areaId))).getSingleOrNull();
    if (area == null || (area.areaPath ?? '').isEmpty) return [areaId];

    final descendants = await (select(
      areas,
    )..where((t) => t.areaPath.like('${area.areaPath}%'))).get();
    return descendants.map((e) => e.areaId).toList();
  }

  Future<List<int>> getMultipleAreasAndDescendantIds(List<int> areaIds) async {
    if (areaIds.isEmpty) return [];

    final areaList = await (select(
      areas,
    )..where((t) => t.areaId.isIn(areaIds))).get();
    if (areaList.isEmpty) return areaIds;

    final query = select(areas);

    // Construct a composite WHERE clause to match any of the paths
    Expression<bool>? composite;
    for (final area in areaList) {
      final path = area.areaPath ?? '';
      if (path.isEmpty) {
        final expr = areas.areaId.equals(area.areaId);
        composite = composite == null ? expr : (composite | expr);
      } else {
        final expr = areas.areaPath.like('$path%');
        composite = composite == null ? expr : (composite | expr);
      }
    }

    if (composite != null) {
      query.where((t) => composite!);
    } else {
      query.where((t) => t.areaId.isIn(areaIds));
    }

    final descendants = await query.get();
    return descendants.map((e) => e.areaId).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final pointerFile = File(p.join(dbFolder.path, 'current_db.txt'));
    String dbName = 'Betros_Bols.db';
    if (pointerFile.existsSync()) {
      dbName = pointerFile.readAsStringSync();
    }

    final file = File(p.join(dbFolder.path, dbName));

    // Copy from assets if it doesn't exist
    if (!file.existsSync()) {
      try {
        final data = await rootBundle.load('assets/database/Betros_Bols.db');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        file.writeAsBytesSync(bytes);
        print('FLUTTER DB: Copied from assets to ${file.path}');
      } catch (e) {
        print('FLUTTER DB ERROR: Could not copy asset database: $e');
      }
    }

    // Clean up old database files from previous restores
    try {
      final files = dbFolder.listSync();
      for (var f in files) {
        if (f is File &&
            f.path.endsWith('.db') &&
            p.basename(f.path).startsWith('Betros_Bols') &&
            p.basename(f.path) != dbName) {
          try {
            f.deleteSync();
          } catch (_) {} // Ignore locked files
        }
      }
    } catch (_) {}

    print('FLUTTER DB PATH: ${file.path}');

    return NativeDatabase.createInBackground(file);
  });
}
