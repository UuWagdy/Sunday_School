import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('migration copies legacy stage and khoros Service_ID links', () async {
    final dir = await Directory.systemTemp.createTemp('service_links_migration_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/old.db');

    final raw = sqlite3.sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE Services (
          Service_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          Service_Name TEXT
        );
      ''')
      ..execute('''
        CREATE TABLE Khoroses (
          Khoros_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          Khoros_Name TEXT,
          Service_ID INTEGER
        );
      ''')
      ..execute('''
        CREATE TABLE Stages (
          Stage_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          Stage_Name TEXT,
          Service_ID INTEGER
        );
      ''')
      ..execute("INSERT INTO Services (Service_ID, Service_Name) VALUES (1, 'A'), (2, 'B')")
      ..execute("INSERT INTO Khoroses (Khoros_ID, Khoros_Name, Service_ID) VALUES (10, 'K', 1)")
      ..execute("INSERT INTO Stages (Stage_ID, Stage_Name, Service_ID) VALUES (20, 'S', 2)")
      ..execute('PRAGMA user_version = 31')
      ..dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final khorosLinks = await db
        .customSelect('SELECT "Khoros_ID", "Service_ID" FROM "Khoros_Services"')
        .get();
    final stageLinks = await db
        .customSelect('SELECT "Stage_ID", "Service_ID" FROM "Stage_Services"')
        .get();

    expect(khorosLinks.single.data, containsPair('Khoros_ID', 10));
    expect(khorosLinks.single.data, containsPair('Service_ID', 1));
    expect(stageLinks.single.data, containsPair('Stage_ID', 20));
    expect(stageLinks.single.data, containsPair('Service_ID', 2));
  });
}
