
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'lib/database/database.dart';

void main() async {
  final file = File('e:/Final/petros_pols_flutter/sunday_school_db.sqlite');
  if (!file.existsSync()) {
    print('Database file NOT FOUND at ${file.absolute.path}');
    return;
  }
  
  final db = AppDatabase();
  try {
    final count = await db.select(db.persons).get().then((rows) => rows.length);
    print('TOTAL PERSONS IN DB: $count');
    
    final userCount = await db.select(db.pass).get().then((rows) => rows.length);
    print('TOTAL USERS IN DB: $userCount');

    final visibilityFilters = await db.select(db.userVisibilityFilters).get();
    print('TOTAL VISIBILITY FILTERS: ${visibilityFilters.length}');
    for (var f in visibilityFilters) {
      print('Filter: User=${f.userId}, Type=${f.filterType}, Value=${f.valueId}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}
