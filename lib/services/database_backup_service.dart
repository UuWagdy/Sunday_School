import 'package:universal_io/io.dart';
import 'package:drift/drift.dart'
    show StringExpressionOperators, BooleanExpressionOperators;
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../sync/server_connection_service.dart';
import 'auth_service.dart';
import 'automatic_backup_service.dart';
import 'backup/sqlite_snapshot.dart';

class DatabaseBackupService {
  static Map<String, String> get serverHeaders {
    final cfg = ServerBootstrap.initialConfig;
    return {
      'X-Device-Id': cfg.deviceId,
      if (cfg.jwtToken != null) 'Authorization': 'Bearer ${cfg.jwtToken}',
    };
  }

  static final automatic = AutomaticBackupService(
    prefix: 'SundaySchool',
    isServerMode: () => ServerBootstrap.initialConfig.isServerMode,
    serverUrl: () => ServerBootstrap.initialConfig.normalizedBaseUrl,
    headers: () => serverHeaders,
    snapshot: (target) async =>
        createSqliteBackup((await _getDbFile()).path, target),
  );
  static Future<File> _getDbFile() async {
    final dbFolder = await getAppDatabaseDirectory();
    final pointerFile = File(p.join(dbFolder.path, 'current_db.txt'));
    String dbName = 'Betros_Bols.db';
    if (await pointerFile.exists()) {
      dbName = (await pointerFile.readAsString()).trim();
    }
    return File(p.join(dbFolder.path, dbName));
  }

  static void _requireFullMaintenance(WidgetRef ref) {
    final user = ref.read(authServiceProvider).value;
    if (user == null ||
        !user.canMaintenance ||
        user.dataVisibilityScope.restricted) {
      throw StateError(
        'النسخ الكامل والاستعادة ومسح القاعدة يحتاجون صلاحية الصيانة ورؤية كل البيانات. استخدم تصدير التبويب للبيانات المسموحة لك.',
      );
    }
  }

  static Future<String?> backupDatabase(WidgetRef ref) async {
    _requireFullMaintenance(ref);
    try {
      Uint8List bytes;
      File? dbFile;

      final cfg = ServerBootstrap.initialConfig;
      if (cfg.isServerMode) {
        final uri = Uri.parse('${cfg.normalizedBaseUrl}/api/backups/download');
        final response = await http
            .get(
              uri,
              headers: {
                'X-Device-Id': cfg.deviceId,
                if (cfg.jwtToken != null)
                  'Authorization': 'Bearer ${cfg.jwtToken}',
              },
            )
            .timeout(const Duration(minutes: 30));
        if (response.statusCode != 200) {
          throw Exception(
            'فشل تحميل النسخة الاحتياطية من السيرفر: ${response.body}',
          );
        }
        bytes = response.bodyBytes;
      } else {
        dbFile = await _getDbFile();
        if (!await dbFile.exists()) {
          throw Exception('قاعدة البيانات غير موجودة');
        }
        final temp = await Directory.systemTemp.createTemp(
          'sunday-school-backup-',
        );
        try {
          final snapshot = File(p.join(temp.path, 'snapshot.db'));
          await createSqliteBackup(dbFile.path, snapshot.path);
          bytes = await snapshot.readAsBytes();
        } finally {
          await temp.delete(recursive: true);
        }
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
        fileName:
            'SundaySchool_${cfg.isServerMode ? 'postgresql' : 'sqlite'}_${DateTime.now().millisecondsSinceEpoch}.${cfg.isServerMode ? 'dump' : 'db'}',
        type: FileType.any,
        bytes: bytes,
      );

      if (outputFile != null) {
        if (!kIsWeb &&
            (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
          final target = File(outputFile);
          if (!cfg.isServerMode &&
              p.equals(
                p.normalize(target.absolute.path),
                p.normalize(dbFile!.absolute.path),
              ))
            throw StateError('اختر ملفًا مختلفًا عن قاعدة البيانات الحالية.');
          await target.writeAsBytes(bytes, flush: true);
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
  static Future<void> _ensureSchemaCompatibility(String dbPath) =>
      ensureSchemaCompatibility(dbPath);

  static Future<bool> restoreDatabase(WidgetRef ref) async {
    _requireFullMaintenance(ref);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف قاعدة البيانات للاستعادة',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final cfg = ref.read(serverConfigProvider);

        final magic = await backupFile
            .openRead(0, 16)
            .fold<List<int>>([], (a, b) => a..addAll(b));
        final isDump = String.fromCharCodes(magic.take(5)) == 'PGDMP';
        if (isDump) {
          if (!cfg.isServerMode)
            throw StateError(
              'نسخة PostgreSQL تُستعاد في وضع السيرفر. فعّل وضع السيرفر أولاً.',
            );
          final response = await http
              .post(
                Uri.parse('${cfg.normalizedBaseUrl}/api/backups/restore'),
                headers: {
                  ...serverHeaders,
                  'Content-Type': 'application/octet-stream',
                },
                body: await backupFile.readAsBytes(),
              )
              .timeout(const Duration(minutes: 30));
          if (response.statusCode != 200)
            throw StateError('فشل استعادة PostgreSQL: ${response.body}');
          ref.invalidate(appDatabaseProvider);
          return true;
        }
        if (String.fromCharCodes(magic.take(15)) != 'SQLite format 3')
          throw StateError('اختر نسخة SQLite أو PostgreSQL صحيحة.');

        if (cfg.isServerMode) {
          final uri = Uri.parse(
            '${cfg.normalizedBaseUrl}/api/storage/import-sqlite?overwrite=true',
          );
          final req = http.MultipartRequest('POST', uri);
          req.headers['X-Device-Id'] = cfg.deviceId;
          if (cfg.jwtToken != null)
            req.headers['Authorization'] = 'Bearer ${cfg.jwtToken}';
          req.files.add(
            await http.MultipartFile.fromPath('file', backupFile.path),
          );
          final streamed = await req.send().timeout(const Duration(minutes: 2));
          final resp = await http.Response.fromStream(streamed);
          if (resp.statusCode != 200) {
            throw Exception(
              'فشل استعادة قاعدة البيانات على السيرفر: ${resp.body}',
            );
          }
          ref.invalidate(appDatabaseProvider);
          return true;
        }

        final dbFolder = await getAppDatabaseDirectory();

        // Generate new db filename
        final newDbName =
            'Betros_Bols_${DateTime.now().millisecondsSinceEpoch}.db';
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
    final cfg = ServerBootstrap.initialConfig;
    if (cfg.isServerMode) {
      return 'PostgreSQL Server (${cfg.normalizedBaseUrl})';
    }
    final file = await _getDbFile();
    return file.path;
  }

  /// Clears all tables except the Pass (users) table.
  static Future<bool> factoryReset(WidgetRef ref) async {
    _requireFullMaintenance(ref);
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
        await (db.delete(
          db.settings,
        )..where((t) => t.settingKey.like('user_data_scope_%').not())).go();
      });
      return true;
    } catch (e) {
      debugPrint('Factory reset error: $e');
      rethrow;
    }
  }
}
