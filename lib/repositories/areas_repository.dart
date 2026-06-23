import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'areas_repository.g.dart';

class Area {
  final int id;
  final String name;
  final int? parentId;
  final int level;
  final String? areaPath;

  Area({
    required this.id, 
    required this.name,
    this.parentId,
    this.level = 0,
    this.areaPath,
  });
}

@riverpod
class AreasRepository extends _$AreasRepository {
  @override
  FutureOr<List<Area>> build() async {
    return _fetchAreas();
  }

  Future<List<Area>> _fetchAreas() async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.areas);

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final allowedIds = user.visibilityFilters['area'];
      if (allowedIds != null) {
        if (allowedIds.isEmpty) {
          query.where((t) => t.areaId.isNull() & t.areaId.isNotNull());
        } else {
          // Note: In strict mode, we only show explicitly allowed areas.
          // Hierarchical parents are not shown unless explicitly included.
          query.where((t) => t.areaId.isIn(allowedIds));
        }
      }
    }

    final areas = await query.get();
    return areas.map((a) => Area(
      id: a.areaId ?? 0, 
      name: a.areaName ?? '',
      parentId: a.parentId,
      level: a.level ?? 0,
      areaPath: a.areaPath,
    )).toList();
  }

  Future<List<Area>> getAreasByParent(int? parentId) async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.areas)..where((t) => parentId == null ? t.parentId.isNull() : t.parentId.equals(parentId));
    final areas = await query.get();
    return areas.map((a) => Area(
      id: a.areaId ?? 0, 
      name: a.areaName ?? '',
      parentId: a.parentId,
      level: a.level ?? 0,
      areaPath: a.areaPath,
    )).toList();
  }

  Future<bool> addArea(String name, {int? parentId}) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if area already exists under the same parent
    final query = db.select(db.areas)..where((t) => t.areaName.equals(name));
    if (parentId != null) {
      query.where((t) => t.parentId.equals(parentId));
    } else {
      query.where((t) => t.parentId.isNull());
    }
    final exists = await query.getSingleOrNull();
    if (exists != null) return false;

    int level = 0;
    String areaPath = '';

    if (parentId != null) {
      final parent = await (db.select(db.areas)..where((t) => t.areaId.equals(parentId))).getSingleOrNull();
      if (parent != null) {
        level = (parent.level ?? 0) + 1;
        areaPath = '${parent.areaPath ?? '/${parent.areaId}/'}';
      }
    }

    final id = await db.into(db.areas).insert(AreasCompanion.insert(
      areaName: drift.Value(name),
      parentId: drift.Value(parentId),
      level: drift.Value(level),
    ));

    // Update path after insertion
    areaPath = '$areaPath$id/';
    await (db.update(db.areas)..where((t) => t.areaId.equals(id))).write(AreasCompanion(areaPath: drift.Value(areaPath)));

    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateArea(int id, String newName) async {
    final db = ref.read(appDatabaseProvider);
    
    final exists = await (db.select(db.areas)..where((t) => t.areaName.equals(newName) & t.areaId.isNotValue(id))).getSingleOrNull();
    if (exists != null) return false;

    await (db.update(db.areas)..where((t) => t.areaId.equals(id))).write(AreasCompanion(areaName: drift.Value(newName)));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> deleteArea(int id) async {
    final db = ref.read(appDatabaseProvider);
    
    final childrenCount = await (db.select(db.areas)..where((t) => t.parentId.equals(id))).get().then((v) => v.length);
    if (childrenCount > 0) return false; // Cannot delete if there are child areas

    final personsCount = await (db.select(db.persons)..where((t) => t.areaId.equals(id))).get().then((v) => v.length);
    if (personsCount > 0) return false; 

    await (db.delete(db.areas)..where((t) => t.areaId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }

  // Utility to rebuild paths, useful after migration
  Future<void> rebuildPaths() async {
    final db = ref.read(appDatabaseProvider);
    final allAreas = await db.select(db.areas).get();
    
    // Process roots
    final roots = allAreas.where((a) => a.parentId == null).toList();
    for (var root in roots) {
      await _updateDescendantsPath(db, root.areaId!, '/${root.areaId}/', 0);
    }
    ref.invalidateSelf();
  }

  Future<void> _updateDescendantsPath(AppDatabase db, int areaId, String path, int level) async {
    await (db.update(db.areas)..where((t) => t.areaId.equals(areaId))).write(AreasCompanion(
      areaPath: drift.Value(path),
      level: drift.Value(level),
    ));

    // Get children
    final children = await (db.select(db.areas)..where((t) => t.parentId.equals(areaId))).get();
    for (var child in children) {
      await _updateDescendantsPath(db, child.areaId!, '$path${child.areaId}/', level + 1);
    }
  }
}
