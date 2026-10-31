import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

Future<Directory> getAppDatabaseDirectory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final appDbDir = Directory(p.join(exeDir.path, 'database'));
      if (!appDbDir.existsSync()) {
        appDbDir.createSync(recursive: true);
      }
      final testFile = File(p.join(appDbDir.path, '.write_test'));
      testFile.writeAsStringSync('test');
      testFile.deleteSync();

      // Check for legacy migration from Documents
      if (Platform.isWindows) {
        final legacyDir = await getApplicationDocumentsDirectory();
        final legacyPointer = File(p.join(legacyDir.path, 'current_db.txt'));
        String legacyDbName = 'Betros_Bols.db';
        if (legacyPointer.existsSync()) {
          legacyDbName = legacyPointer.readAsStringSync().trim();
        }
        final legacyDbFile = File(p.join(legacyDir.path, legacyDbName));
        final targetDbFile = File(p.join(appDbDir.path, legacyDbName));

        // If app directory doesn't have the database yet, but legacy Documents does:
        if (!targetDbFile.existsSync() && legacyDbFile.existsSync()) {
          print('FLUTTER DB MIGRATION: Copying legacy database from ${legacyDbFile.path} to ${targetDbFile.path}');
          legacyDbFile.copySync(targetDbFile.path);

          if (legacyPointer.existsSync()) {
            final targetPointer = File(p.join(appDbDir.path, 'current_db.txt'));
            legacyPointer.copySync(targetPointer.path);
          }
        }
      }

      return appDbDir;
    } catch (e) {
      print('FLUTTER DB WARNING: Cannot use executable directory for DB ($e). Falling back to Documents.');
    }
  }

  return await getApplicationDocumentsDirectory();
}

LazyDatabase openAppConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getAppDatabaseDirectory();
    final pointerFile = File(p.join(dbFolder.path, 'current_db.txt'));
    String dbName = 'Betros_Bols.db';
    if (pointerFile.existsSync()) {
      dbName = pointerFile.readAsStringSync().trim();
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
            print('FLUTTER DB: Cleaned up old database file ${f.path}');
          } catch (_) {} // Ignore locked files
        }
      }
    } catch (e) {
      print('FLUTTER DB: Error cleaning old databases: $e');
    }

    print('FLUTTER DB PATH: ${file.path}');

    return NativeDatabase.createInBackground(file);
  });
}
