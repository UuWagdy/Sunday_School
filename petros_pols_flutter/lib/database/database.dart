import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  AbsentPersons,
  AbsentPrint,
  Adding,
  Areas,
  Coming,
  Credit,
  Fathers,
  Jender,
  Pass,
  Persons,
  Stages
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'Betros_Bols.sqlite'));

    if (!await file.exists()) {
      // Extract the pre-populated database from assets
      final blob = await rootBundle.load('assets/database/Betros_Bols.sqlite');
      final buffer = blob.buffer;
      await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }

    return NativeDatabase.createInBackground(file);
  });
}
