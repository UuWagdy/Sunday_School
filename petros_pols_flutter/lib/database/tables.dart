import 'package:drift/drift.dart';

class AbsentPersons extends Table {
  IntColumn get id => integer().nullable()();
  IntColumn get personId => integer().nullable()();
  TextColumn get personName => text().nullable()();
  TextColumn get stage => text().nullable()();
  TextColumn get month1 => text().nullable()();
  TextColumn get first => text().nullable()();
  TextColumn get second => text().nullable()();
  TextColumn get third => text().nullable()();
  TextColumn get forth => text().nullable()();
  TextColumn get fife => text().nullable()();
}

class AbsentPrint extends Table {
  IntColumn get id => integer().nullable()();
  IntColumn get personId => integer().nullable()();
  TextColumn get personName => text().nullable()();
  IntColumn get stageId => integer().nullable()();
  TextColumn get stageName => text().nullable()();
  IntColumn get areaId => integer().nullable()();
  TextColumn get areaName => text().nullable()();
  TextColumn get streetName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get dateFrom => text().nullable()();
  TextColumn get dateTo => text().nullable()();
}

class Adding extends Table {
  IntColumn get dateId => integer().nullable()();
  TextColumn get date => text().nullable()();
}

class Areas extends Table {
  IntColumn get areaId => integer().nullable()();
  TextColumn get areaName => text().nullable()();
}

class Coming extends Table {
  IntColumn get id => integer().nullable()();
  IntColumn get personId => integer().nullable()();
  TextColumn get dateWeek => text().nullable()();
  IntColumn get point => integer().nullable()();
  IntColumn get mont1 => integer().nullable()();
  IntColumn get year1 => integer().nullable()();
}

class Credit extends Table {
  IntColumn get id => integer().nullable()();
  IntColumn get personId => integer().nullable()();
  TextColumn get personName => text().nullable()();
  TextColumn get stageName => text().nullable()();
  TextColumn get areaName => text().nullable()();
  TextColumn get street => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  IntColumn get day => integer().nullable()();
  IntColumn get month => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get jender => text().nullable()();
  BlobColumn get photo => blob().nullable()();
  BlobColumn get parcode => blob().nullable()();
}

class Fathers extends Table {
  IntColumn get fatherId => integer().nullable()();
  TextColumn get fatherName => text().nullable()();
}

class Jender extends Table {
  IntColumn get jenderId => integer().nullable()();
  TextColumn get jenderName => text().nullable()();
}

class Pass extends Table {
  IntColumn get passId => integer().nullable()();
  TextColumn get passWord => text().nullable()();
  TextColumn get personName => text().nullable()();
}

class Persons extends Table {
  IntColumn get personId => integer().nullable()();
  TextColumn get personName => text().nullable()();
  IntColumn get stageId => integer().nullable()();
  IntColumn get areaId => integer().nullable()();
  TextColumn get streetName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  IntColumn get day => integer().nullable()();
  IntColumn get month => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get jenderName => text().nullable()();
  IntColumn get fatherId => integer().nullable()();
  BlobColumn get photo => blob().nullable()();
}

class Stages extends Table {
  IntColumn get stageId => integer().nullable()();
  TextColumn get stageName => text().nullable()();
}
