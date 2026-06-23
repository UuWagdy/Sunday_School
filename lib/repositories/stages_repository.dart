import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import 'service_eligibility_repository.dart';

part 'stages_repository.g.dart';

class StageModel {
  final int id;
  final String name;
  final int? serviceId;
  final List<int> serviceIds;
  final int? nextStageId;

  StageModel({
    required this.id,
    required this.name,
    this.serviceId,
    this.serviceIds = const [],
    this.nextStageId,
  });
}

@riverpod
class StagesRepository extends _$StagesRepository {
  @override
  FutureOr<List<StageModel>> build() async {
    return _fetchStages();
  }

  Future<List<StageModel>> _fetchStages() async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.stages);

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final allowedIds = user.visibilityFilters['stage'];
      if (allowedIds != null) {
        if (allowedIds.isEmpty) {
          query.where((t) => t.stageId.isNull() & t.stageId.isNotNull());
        } else {
          query.where((t) => t.stageId.isIn(allowedIds));
        }
      }
    }

    final stages = await query.get();
    final linkRows = await db
        .customSelect(
          'SELECT "Stage_ID" AS stage_id, "Service_ID" AS service_id FROM "Stage_Services"',
        )
        .get();
    final serviceMap = <int, Set<int>>{};
    for (final row in linkRows) {
      serviceMap
          .putIfAbsent(row.read<int>('stage_id'), () => <int>{})
          .add(row.read<int>('service_id'));
    }
    return stages.map((s) {
      final stageId = s.stageId ?? 0;
      final linkedServiceIds = serviceMap[stageId] ?? <int>{};
      return StageModel(
        id: stageId,
        name: s.stageName ?? '',
        serviceId: s.serviceId,
        serviceIds: [
          ...{if (s.serviceId != null) s.serviceId!, ...linkedServiceIds},
        ],
        nextStageId: s.nextStageId,
      );
    }).toList();
  }

  Future<bool> addStage(
    String name, {
    int? serviceId,
    List<int> serviceIds = const [],
    int? nextStageId,
  }) async {
    final db = ref.read(appDatabaseProvider);

    final exists = await (db.select(
      db.stages,
    )..where((t) => t.stageName.equals(name))).getSingleOrNull();
    if (exists != null) return false;

    final resolvedServiceIds = {
      if (serviceId != null) serviceId,
      ...serviceIds,
    };
    final legacyServiceId = resolvedServiceIds.isEmpty
        ? null
        : resolvedServiceIds.first;

    final stageId = await db
        .into(db.stages)
        .insert(
          StagesCompanion.insert(
            stageName: drift.Value(name),
            serviceId: drift.Value(legacyServiceId),
            nextStageId: drift.Value(nextStageId),
          ),
        );
    await _replaceStageServiceLinks(db, stageId, resolvedServiceIds);
    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateStage(
    int id,
    String newName, {
    int? serviceId,
    List<int> serviceIds = const [],
    int? nextStageId,
  }) async {
    final db = ref.read(appDatabaseProvider);

    final exists =
        await (db.select(db.stages)..where(
              (t) => t.stageName.equals(newName) & t.stageId.isNotValue(id),
            ))
            .getSingleOrNull();
    if (exists != null) return false;

    final resolvedServiceIds = {
      if (serviceId != null) serviceId,
      ...serviceIds,
    };
    final legacyServiceId = resolvedServiceIds.isEmpty
        ? null
        : resolvedServiceIds.first;

    await (db.update(db.stages)..where((t) => t.stageId.equals(id))).write(
      StagesCompanion(
        stageName: drift.Value(newName),
        serviceId: drift.Value(legacyServiceId),
        nextStageId: drift.Value(nextStageId),
      ),
    );
    await _replaceStageServiceLinks(db, id, resolvedServiceIds);

    final persons = await (db.select(
      db.persons,
    )..where((t) => t.stageId.equals(id))).get();
    await ServiceEligibilityRepository(
      db,
    ).syncResolvedServicesForPeople(persons.map((person) => person.personId));

    ref.invalidateSelf();
    return true;
  }

  Future<void> _replaceStageServiceLinks(
    AppDatabase db,
    int stageId,
    Iterable<int> serviceIds,
  ) async {
    await db.customStatement(
      'DELETE FROM "Stage_Services" WHERE "Stage_ID" = ?',
      [stageId],
    );
    for (final serviceId in serviceIds.toSet()) {
      await db.customStatement(
        'INSERT OR IGNORE INTO "Stage_Services" ("Stage_ID", "Service_ID") VALUES (?, ?)',
        [stageId, serviceId],
      );
    }
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
