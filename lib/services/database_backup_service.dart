import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../database/database.dart';
import '../database/database_provider.dart';

class DatabaseBackupService {
  static Future<File> _getDbFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final pointerFile = File(p.join(dbFolder.path, 'current_db.txt'));
    String dbName = 'Betros_Bols.db';
    if (await pointerFile.exists()) {
      dbName = await pointerFile.readAsString();
    }
    return File(p.join(dbFolder.path, dbName));
  }

  static Future<String?> backupDatabase() async {
    try {
      final dbFile = await _getDbFile();

      if (!await dbFile.exists()) {
        throw Exception('قاعدة البيانات غير موجودة');
      }

      final bytes = await dbFile.readAsBytes();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
        fileName: 'Backup_${DateTime.now().millisecondsSinceEpoch}.db',
        type: FileType.any,
        bytes: bytes,
      );

      if (outputFile != null) {
        // On Desktop, if the file doesn't exist yet, we still need to copy it
        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          if (!await File(outputFile).exists()) {
            await dbFile.copy(outputFile);
          }
        }
        return outputFile;
      }
    } catch (e) {
      debugPrint('Backup error: $e');
      rethrow;
    }
    return null;
  }

  /// Ensures the restored database has all required tables and columns.
  /// This handles old backups that don't have newer tables/columns.
  static Future<void> _ensureSchemaCompatibility(String dbPath) async {
    final db = sqlite3.sqlite3.open(dbPath);
    try {
      // Get current user_version (schema version)
      final versionResult = db.select('PRAGMA user_version');
      final currentVersion = versionResult.isNotEmpty ? (versionResult.first.values.first as int) : 0;
      debugPrint('Restored DB schema version: $currentVersion');

      // If version is 0, it's likely an old C# database or a raw backup.
      // We need to ensure all tables exist. Instead of running Drift migrations manually,
      // we create any missing tables/columns directly.
      
      // Helper to check if a table exists
      bool tableExists(String tableName) {
        final r = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
        return r.isNotEmpty;
      }

      // Helper to check if a column exists in a table
      bool columnExists(String tableName, String columnName) {
        try {
          final r = db.select("PRAGMA table_info('$tableName')");
          return r.any((row) => row['name'].toString().toLowerCase() == columnName.toLowerCase());
        } catch (_) {
          return false;
        }
      }

      // Ensure Settings table exists
      if (!tableExists('Settings')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Settings (
            Setting_Key TEXT NOT NULL PRIMARY KEY,
            Setting_Value TEXT
          )
        ''');
      }

      // Ensure Services table exists
      if (!tableExists('Services')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Services (
            Service_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            Service_Name TEXT,
            Day_Of_Week INTEGER,
            Hour INTEGER,
            Minute INTEGER,
            Logo BLOB
          )
        ''');
      } else {
        if (!columnExists('Services', 'Logo')) {
          db.execute('ALTER TABLE Services ADD COLUMN Logo BLOB');
        }
      }

      // Ensure Khoroses table exists
      if (!tableExists('Khoroses')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Khoroses (
            Khoros_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            Khoros_Name TEXT,
            Logo BLOB,
            Service_ID INTEGER
          )
        ''');
      } else {
        if (!columnExists('Khoroses', 'Logo')) {
          db.execute('ALTER TABLE Khoroses ADD COLUMN Logo BLOB');
        }
        if (!columnExists('Khoroses', 'Service_ID')) {
          db.execute('ALTER TABLE Khoroses ADD COLUMN Service_ID INTEGER');
        }
      }

      if (tableExists('Stages')) {
        if (!columnExists('Stages', 'Service_ID')) {
          db.execute('ALTER TABLE Stages ADD COLUMN Service_ID INTEGER');
        }
        if (!columnExists('Stages', 'Next_Stage_ID')) {
          db.execute('ALTER TABLE Stages ADD COLUMN Next_Stage_ID INTEGER');
        }
      }

      if (!tableExists('Khoros_Services')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Khoros_Services (
            Khoros_ID INTEGER NOT NULL,
            Service_ID INTEGER NOT NULL,
            PRIMARY KEY (Khoros_ID, Service_ID)
          )
        ''');
      }

      if (!tableExists('Stage_Services')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Stage_Services (
            Stage_ID INTEGER NOT NULL,
            Service_ID INTEGER NOT NULL,
            PRIMARY KEY (Stage_ID, Service_ID)
          )
        ''');
      }

      if (tableExists('Khoroses') && tableExists('Khoros_Services')) {
        db.execute('''
          INSERT OR IGNORE INTO Khoros_Services (Khoros_ID, Service_ID)
          SELECT Khoros_ID, Service_ID FROM Khoroses
          WHERE Khoros_ID IS NOT NULL AND Service_ID IS NOT NULL
        ''');
      }

      if (tableExists('Stages') && tableExists('Stage_Services')) {
        db.execute('''
          INSERT OR IGNORE INTO Stage_Services (Stage_ID, Service_ID)
          SELECT Stage_ID, Service_ID FROM Stages
          WHERE Stage_ID IS NOT NULL AND Service_ID IS NOT NULL
        ''');
      }

      // Ensure Tayo_Cards table exists
      if (!tableExists('Tayo_Cards')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Tayo_Cards (
            Card_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            Card_Name TEXT,
            Card_Points INTEGER,
            Card_Image BLOB
          )
        ''');
      }

      // Ensure Person_Tayo_Points table exists
      if (!tableExists('Person_Tayo_Points')) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS Person_Tayo_Points (
            ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            Person_ID INTEGER,
            Card_ID INTEGER,
            Points INTEGER,
            Award_Date TEXT,
            Is_Attendance INTEGER,
            Notes TEXT,
            Service_ID INTEGER
          )
        ''');
      } else {
        if (!columnExists('Person_Tayo_Points', 'Notes')) {
          db.execute('ALTER TABLE Person_Tayo_Points ADD COLUMN Notes TEXT');
        }
        if (!columnExists('Person_Tayo_Points', 'Service_ID')) {
          db.execute('ALTER TABLE Person_Tayo_Points ADD COLUMN Service_ID INTEGER');
        }
      }

      // Ensure Coming table has new columns
      if (tableExists('Coming')) {
        if (!columnExists('Coming', 'Service_ID')) {
          db.execute('ALTER TABLE Coming ADD COLUMN Service_ID INTEGER');
        }
        if (!columnExists('Coming', 'Attend_Time')) {
          db.execute('ALTER TABLE Coming ADD COLUMN Attend_Time TEXT');
        }
        if (!columnExists('Coming', 'Visited')) {
          db.execute('ALTER TABLE Coming ADD COLUMN Visited INTEGER');
        }
        if (!columnExists('Coming', 'Visit_Notes')) {
          db.execute('ALTER TABLE Coming ADD COLUMN Visit_Notes TEXT');
        }
      }

      // Ensure Persons table has Khoros_ID
      if (tableExists('Persons')) {
        if (!columnExists('Persons', 'Khoros_ID')) {
          db.execute('ALTER TABLE Persons ADD COLUMN Khoros_ID INTEGER');
        }
      }

      // Ensure Absent_Print has Khoros columns
      if (tableExists('Absent_Print')) {
        if (!columnExists('Absent_Print', 'Khoros_ID')) {
          db.execute('ALTER TABLE Absent_Print ADD COLUMN Khoros_ID INTEGER');
        }
        if (!columnExists('Absent_Print', 'Khoros_Name')) {
          db.execute('ALTER TABLE Absent_Print ADD COLUMN Khoros_Name TEXT');
        }
      }

      // Ensure Pass table has all permission columns
      if (tableExists('Pass')) {
        final permCols = [
          'can_persons', 'can_stages', 'can_areas', 'can_fathers',
          'can_reports', 'can_users', 'can_absence', 'can_maintenance',
          'can_id_card', 'can_tayo', 'can_transfer', 'can_services', 'can_khoros'
        ];
        for (final col in permCols) {
          if (!columnExists('Pass', col)) {
            db.execute('ALTER TABLE Pass ADD COLUMN $col INTEGER');
          }
        }
      }

      // --- Normalization for Gender labels (Legacy DB fix) ---
      if (tableExists('Persons') && columnExists('Persons', 'Jender_Name')) {
        db.execute("UPDATE Persons SET Jender_Name = 'ذكر' WHERE Jender_Name = 'ولد'");
        db.execute("UPDATE Persons SET Jender_Name = 'أنثى' WHERE Jender_Name = 'بنت'");
      }
      if (tableExists('Jender') && columnExists('Jender', 'Jender_Name')) {
        db.execute("UPDATE Jender SET Jender_Name = 'ذكر' WHERE Jender_Name = 'ولد'");
        db.execute("UPDATE Jender SET Jender_Name = 'أنثى' WHERE Jender_Name = 'بنت'");
      }

      // Set schema version to 18 so Drift can handle newer migrations (19+)
      db.execute('PRAGMA user_version = 18');
      debugPrint('Schema compatibility ensured. Set user_version to 18.');
    } catch (e) {
      debugPrint('Schema compatibility error: $e');
      // Don't rethrow - let Drift handle any remaining issues
    } finally {
      db.dispose();
    }
  }

  /// Restores the database from a user-selected file.
  /// [ref] is needed to close and re-create the database connection.
  static Future<bool> restoreDatabase(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف قاعدة البيانات للاستعادة',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final dbFolder = await getApplicationDocumentsDirectory();
        
        // Generate new db filename
        final newDbName = 'Betros_Bols_${DateTime.now().millisecondsSinceEpoch}.db';
        final newDbFile = File(p.join(dbFolder.path, newDbName));

        // Step 1: Copy backup file to new filename
        await backupFile.copy(newDbFile.path);

        // Step 2: Ensure schema compatibility BEFORE opening with Drift
        await _ensureSchemaCompatibility(newDbFile.path);

        // Step 3: Update database pointer
        final pointerFile = File(p.join(dbFolder.path, 'current_db.txt'));
        await pointerFile.writeAsString(newDbName);

        // Step 4: Close current database connection
        final db = ref.read(appDatabaseProvider);
        await db.close();

        // Step 5: Invalidate the database provider so it creates a fresh connection to the new file
        ref.invalidate(appDatabaseProvider);

        return true;
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      rethrow;
    }
    return false;
  }

  static Future<String> getDatabasePath() async {
    final file = await _getDbFile();
    return file.path;
  }

  /// Clears all tables except the Pass (users) table.
  static Future<bool> factoryReset(WidgetRef ref) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await db.delete(db.persons).go();
        await db.delete(db.coming).go();
        await db.delete(db.fathers).go();
        await db.delete(db.areas).go();
        await db.delete(db.stages).go();
        await db.delete(db.absentPersons).go();
        await db.delete(db.absentPrint).go();
        await db.delete(db.credit).go();
        await db.delete(db.adding).go();
        await db.delete(db.jender).go();
        await db.delete(db.services).go();
        await db.delete(db.khoroses).go();
        await db.customStatement('DELETE FROM "Khoros_Services"');
        await db.customStatement('DELETE FROM "Stage_Services"');
        await db.delete(db.tayoCards).go();
        await db.delete(db.personTayoPoints).go();
        await db.delete(db.settings).go();
      });
      return true;
    } catch (e) {
      debugPrint('Factory reset error: $e');
      rethrow;
    }
  }
}
