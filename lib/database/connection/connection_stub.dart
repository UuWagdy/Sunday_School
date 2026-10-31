import 'package:drift/drift.dart';
import 'package:universal_io/io.dart';

LazyDatabase openAppConnection() => throw UnsupportedError(
      'Cannot open SQLite database directly on this platform. Use Server Mode.',
    );

Future<Directory> getAppDatabaseDirectory() async => Directory('/database');
