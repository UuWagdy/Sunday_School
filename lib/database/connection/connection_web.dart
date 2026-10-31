import 'package:drift/drift.dart';
import 'package:universal_io/io.dart';

LazyDatabase openAppConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'SQLite native database is not available on Web. The web client must run in Server Mode (SundaySchool.SyncServer).',
    );
  });
}

Future<Directory> getAppDatabaseDirectory() async => Directory('/database');
