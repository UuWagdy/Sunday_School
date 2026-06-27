import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';

part 'areas_repository.g.dart';

class Area {
  final int id;
  final String name;

  Area({required this.id, required this.name});
}

@riverpod
class AreasRepository extends _$AreasRepository {
  @override
  FutureOr<List<Area>> build() async {
    return _fetchAreas();
  }

  Future<List<Area>> _fetchAreas() async {
    final db = ref.read(appDatabaseProvider);
    final areas = await db.select(db.areas).get();
    return areas.map((a) => Area(id: a.areaId ?? 0, name: a.areaName ?? '')).toList();
  }

  Future<bool> addArea(String name) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if area already exists
    final exists = await (db.select(db.areas)..where((t) => t.areaName.equals(name))).getSingleOrNull();
    if (exists != null) return false;

    await db.into(db.areas).insert(AreasCompanion.insert(areaName: drift.Value(name)));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateArea(int id, String newName) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if new name already exists for a different ID
    final exists = await (db.select(db.areas)..where((t) => t.areaName.equals(newName) & t.areaId.isNotValue(id))).getSingleOrNull();
    if (exists != null) return false;

    await (db.update(db.areas)..where((t) => t.areaId.equals(id))).write(AreasCompanion(areaName: drift.Value(newName)));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> deleteArea(int id) async {
    final db = ref.read(appDatabaseProvider);
    
    // Depending on logic, Persons may depend on Area_ID, should check foreign keys
    final personsCount = await (db.select(db.persons)..where((t) => t.areaId.equals(id))).get().then((v) => v.length);
    if (personsCount > 0) return false; // Cannot delete if there are persons

    await (db.delete(db.areas)..where((t) => t.areaId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }
}
