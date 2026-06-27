import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';

part 'persons_repository.g.dart';

class PersonListDTO {
  final int id;
  final String name;
  final String stageName;
  final String areaName;
  final String phone;
  final String mobile;
  final String streetName;
  final String fatherName;
  
  PersonListDTO({
     required this.id,
     required this.name,
     required this.stageName,
     required this.areaName,
     required this.phone,
     required this.mobile,
     required this.streetName,
     required this.fatherName,
  });
}

@riverpod
class PersonsRepository extends _$PersonsRepository {
  @override
  FutureOr<List<PersonListDTO>> build() async {
    return _fetchPersons();
  }

  Future<List<PersonListDTO>> _fetchPersons() async {
    final db = ref.read(appDatabaseProvider);
    
    // We need to perform left outer joins to get the string names for IDs
    final query = db.select(db.persons).join([
      drift.leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
      drift.leftOuterJoin(db.areas, db.areas.areaId.equalsExp(db.persons.areaId)),
      drift.leftOuterJoin(db.fathers, db.fathers.fatherId.equalsExp(db.persons.fatherId)),
    ]);

    final results = await query.get();

    return results.map((row) {
      final person = row.readTable(db.persons);
      final stage = row.readTableOrNull(db.stages);
      final area = row.readTableOrNull(db.areas);
      final father = row.readTableOrNull(db.fathers);

      return PersonListDTO(
        id: person.personId ?? 0,
        name: person.personName ?? 'Unknown',
        stageName: stage?.stageName ?? 'Unknown',
        areaName: area?.areaName ?? 'Unknown',
        phone: person.phone ?? '',
        mobile: person.mobile ?? '',
        streetName: person.streetName ?? '',
        fatherName: father?.fatherName ?? 'Unknown',
      );
    }).toList();
  }

  Future<bool> deletePerson(int id) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.persons)..where((t) => t.personId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }
}
