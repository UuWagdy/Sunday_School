import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

Future<void> createSqliteBackup(String source, String target) =>
    compute(_snapshot, (source, target));

void _snapshot((String, String) paths) {
  if (!File(paths.$1).existsSync()) {
    throw StateError('قاعدة البيانات المحلية غير موجودة.');
  }
  final source = sqlite3.sqlite3.open(paths.$1, mode: sqlite3.OpenMode.readWrite);
  try {
    source.execute('PRAGMA busy_timeout = 10000');
    source.execute('VACUUM INTO ?', [paths.$2]);
  } finally {
    source.dispose();
  }
  final copy = sqlite3.sqlite3.open(paths.$2, mode: sqlite3.OpenMode.readOnly);
  try {
    if (copy.select('PRAGMA quick_check').first.values.first != 'ok') {
      throw StateError('فشل التحقق من سلامة النسخة.');
    }
  } finally {
    copy.dispose();
  }
}

Future<void> ensureSchemaCompatibility(String dbPath) async {
  final db = sqlite3.sqlite3.open(dbPath);
  try {
    final versionResult = db.select('PRAGMA user_version');
    final currentVersion = versionResult.isNotEmpty
        ? (versionResult.first.values.first as int)
        : 0;
    debugPrint('Restored DB schema version: $currentVersion');

    bool tableExists(String tableName) {
      final r = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
      );
      return r.isNotEmpty;
    }

    bool columnExists(String tableName, String columnName) {
      try {
        final r = db.select("PRAGMA table_info('$tableName')");
        return r.any(
          (row) =>
              row['name'].toString().toLowerCase() ==
              columnName.toLowerCase(),
        );
      } catch (_) {
        return false;
      }
    }

    if (!tableExists('Credit')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS Credit (
          ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          Person_ID INTEGER NOT NULL,
          P_Points INTEGER,
          N_Points INTEGER,
          Credit_Date TEXT,
          Reasone TEXT,
          Notes TEXT
        )
      ''');
    }

    if (!tableExists('Visitations')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS Visitations (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          person_id INTEGER NOT NULL,
          visitation_date TEXT NOT NULL,
          servant_name TEXT,
          notes TEXT
        )
      ''');
    }

    if (!tableExists('Settings')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS Settings (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }

    if (!tableExists('TayoCards')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS TayoCards (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          card_number TEXT NOT NULL UNIQUE,
          points INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          is_redeemed INTEGER NOT NULL DEFAULT 0,
          redeemed_at TEXT,
          redeemed_by_person_id INTEGER,
          barcode_path TEXT
        )
      ''');
    }

    if (!tableExists('PersonTayoPoints')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS PersonTayoPoints (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          person_id INTEGER NOT NULL UNIQUE,
          total_points INTEGER NOT NULL DEFAULT 0,
          last_updated TEXT NOT NULL
        )
      ''');
    }

    if (!tableExists('Services')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS Services (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          color TEXT,
          notes TEXT
        )
      ''');
    }

    if (!tableExists('Khoroses')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS Khoroses (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color TEXT,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (!tableExists('KhorosServices')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS KhorosServices (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          khoros_id INTEGER NOT NULL,
          service_id INTEGER NOT NULL
        )
      ''');
    }

    if (!tableExists('StageServices')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS StageServices (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          stage_id INTEGER NOT NULL,
          service_id INTEGER NOT NULL
        )
      ''');
    }

    if (!tableExists('PersonServices')) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS PersonServices (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          person_id INTEGER NOT NULL,
          service_id INTEGER NOT NULL
        )
      ''');
    }

    if (tableExists('Persons')) {
      if (!columnExists('Persons', 'khoros_id')) {
        db.execute('ALTER TABLE Persons ADD COLUMN khoros_id INTEGER');
      }
      if (!columnExists('Persons', 'is_khoros_active')) {
        db.execute('ALTER TABLE Persons ADD COLUMN is_khoros_active INTEGER');
      }
      if (!columnExists('Persons', 'birth_date')) {
        db.execute('ALTER TABLE Persons ADD COLUMN birth_date TEXT');
      }
      if (!columnExists('Persons', 'blood_type')) {
        db.execute('ALTER TABLE Persons ADD COLUMN blood_type TEXT');
      }
      if (!columnExists('Persons', 'national_id')) {
        db.execute('ALTER TABLE Persons ADD COLUMN national_id TEXT');
      }
    }

    if (tableExists('Pass')) {
      final permCols = [
        'can_areas',
        'can_stages',
        'can_persons',
        'can_attendance',
        'can_reports',
        'can_users',
        'can_fathers',
        'can_behavior',
        'can_credit',
        'can_visitation',
        'can_absence',
        'can_maintenance',
        'can_id_card',
        'can_tayo',
        'can_transfer',
        'can_services',
        'can_khoros',
      ];
      for (final col in permCols) {
        if (!columnExists('Pass', col)) {
          db.execute('ALTER TABLE Pass ADD COLUMN $col INTEGER');
        }
      }
    }

    if (tableExists('Persons') && columnExists('Persons', 'Jender_Name')) {
      db.execute(
        "UPDATE Persons SET Jender_Name = 'ذكر' WHERE Jender_Name = 'ولد'",
      );
      db.execute(
        "UPDATE Persons SET Jender_Name = 'أنثى' WHERE Jender_Name = 'بنت'",
      );
    }
    if (tableExists('Jender') && columnExists('Jender', 'Jender_Name')) {
      db.execute(
        "UPDATE Jender SET Jender_Name = 'ذكر' WHERE Jender_Name = 'ولد'",
      );
      db.execute(
        "UPDATE Jender SET Jender_Name = 'أنثى' WHERE Jender_Name = 'بنت'",
      );
    }

    db.execute('PRAGMA user_version = 18');
    debugPrint('Schema compatibility ensured. Set user_version to 18.');
  } catch (e) {
    debugPrint('Schema compatibility error: $e');
  } finally {
    db.dispose();
  }
}
