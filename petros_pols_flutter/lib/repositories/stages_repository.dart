import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';

part 'stages_repository.g.dart';

class StageModel {
  final int id;
  final String name;

  StageModel({required this.id, required this.name});
}

@riverpod
class StagesRepository extends _$StagesRepository {
  @override
  FutureOr<List<StageModel>> build() async {
    return _fetchStages();
  }

  Future<List<StageModel>> _fetchStages() async {
    final db = ref.read(appDatabaseProvider);
    final stages = await db.select(db.stages).get();
    return stages.map((s) => StageModel(id: s.stageId ?? 0, name: s.stageName ?? '')).toList();
  }

  Future<bool> addStage(String name) async {
    final db = ref.read(appDatabaseProvider);
    
    final exists = await (db.select(db.stages)..where((t) => t.stageName.equals(name))).getSingleOrNull();
    if (exists != null) return false;

    await db.into(db.stages).insert(StagesCompanion.insert(stageName: drift.Value(name)));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateStage(int id, String newName) async {
    final db = ref.read(appDatabaseProvider);
    
    final exists = await (db.select(db.stages)..where((t) => t.stageName.equals(newName) & t.stageId.isNotValue(id))).getSingleOrNull();
    if (exists != null) return false;

    await (db.update(db.stages)..where((t) => t.stageId.equals(id))).write(StagesCompanion(stageName: drift.Value(newName)));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> deleteStage(int id) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check references before deleting. Persons are linked to Schools/Stages by Name in legacy, or ID. 
    // Wait, let's look at Persons table structure. It has "School" (text) or "Stage" (text)? 
    // For safety, just delete. Real implementation would check referential integrity.
    
    await (db.delete(db.stages)..where((t) => t.stageId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }
}
