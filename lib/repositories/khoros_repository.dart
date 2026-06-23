import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import 'service_eligibility_repository.dart';

part 'khoros_repository.g.dart';

class KhorosModel {
  final int id;
  final String name;
  final Uint8List? logo;
  final int? serviceId;
  final List<int> serviceIds;

  KhorosModel({
    required this.id,
    required this.name,
    this.logo,
    this.serviceId,
    this.serviceIds = const [],
  });

  @override
  String toString() => name;
}

@riverpod
class KhorosRepository extends _$KhorosRepository {
  @override
  FutureOr<List<KhorosModel>> build() async {
    return _fetch();
  }

  Future<List<KhorosModel>> _fetch() async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.khoroses);

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final allowedIds = user.visibilityFilters['khoros'];
      if (allowedIds != null) {
        if (allowedIds.isEmpty) {
          query.where((t) => t.khorosId.isNull() & t.khorosId.isNotNull());
        } else {
          query.where((t) => t.khorosId.isIn(allowedIds));
        }
      }
    }

    final results = await query.get();
    final linkRows = await db
        .customSelect(
          'SELECT "Khoros_ID" AS khoros_id, "Service_ID" AS service_id FROM "Khoros_Services"',
        )
        .get();
    final serviceMap = <int, Set<int>>{};
    for (final row in linkRows) {
      serviceMap
          .putIfAbsent(row.read<int>('khoros_id'), () => <int>{})
          .add(row.read<int>('service_id'));
    }
    return results.map((r) {
      final linkedServiceIds = serviceMap[r.khorosId] ?? <int>{};
      return KhorosModel(
        id: r.khorosId,
        name: r.khorosName ?? '',
        logo: r.logo,
        serviceId: r.serviceId,
        serviceIds: [
          ...{if (r.serviceId != null) r.serviceId!, ...linkedServiceIds},
        ],
      );
    }).toList();
  }

  Future<bool> addKhoros(
    String name, {
    Uint8List? logo,
    int? serviceId,
    List<int> serviceIds = const [],
  }) async {
    final db = ref.read(appDatabaseProvider);
    final exists = await (db.select(
      db.khoroses,
    )..where((t) => t.khorosName.equals(name))).getSingleOrNull();
    if (exists != null) return false;

    final resolvedServiceIds = {
      if (serviceId != null) serviceId,
      ...serviceIds,
    };
    final legacyServiceId = resolvedServiceIds.isEmpty
        ? null
        : resolvedServiceIds.first;

    final khorosId = await db
        .into(db.khoroses)
        .insert(
          KhorosesCompanion.insert(
            khorosName: drift.Value(name),
            logo: drift.Value(logo),
            serviceId: drift.Value(legacyServiceId),
          ),
        );
    await _replaceKhorosServiceLinks(db, khorosId, resolvedServiceIds);
    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateKhoros(
    int id,
    String name, {
    Uint8List? logo,
    int? serviceId,
    List<int> serviceIds = const [],
  }) async {
    final db = ref.read(appDatabaseProvider);

    final exists =
        await (db.select(db.khoroses)..where(
              (t) => t.khorosName.equals(name) & t.khorosId.isNotValue(id),
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

    await (db.update(db.khoroses)..where((t) => t.khorosId.equals(id))).write(
      KhorosesCompanion(
        khorosName: drift.Value(name),
        logo: drift.Value(logo),
        serviceId: drift.Value(legacyServiceId),
      ),
    );
    await _replaceKhorosServiceLinks(db, id, resolvedServiceIds);

    final persons = await (db.select(
      db.persons,
    )..where((t) => t.khorosId.equals(id))).get();
    await ServiceEligibilityRepository(
      db,
    ).syncResolvedServicesForPeople(persons.map((person) => person.personId));

    ref.invalidateSelf();
    return true;
  }

  Future<void> _replaceKhorosServiceLinks(
    AppDatabase db,
    int khorosId,
    Iterable<int> serviceIds,
  ) async {
    await db.customStatement(
      'DELETE FROM "Khoros_Services" WHERE "Khoros_ID" = ?',
      [khorosId],
    );
    for (final serviceId in serviceIds.toSet()) {
      await db.customStatement(
        'INSERT OR IGNORE INTO "Khoros_Services" ("Khoros_ID", "Service_ID") VALUES (?, ?)',
        [khorosId, serviceId],
      );
    }
  }

  Future<bool> deleteKhoros(int id) async {
    final db = ref.read(appDatabaseProvider);
    // Check if used by persons before deleting
    final personCountExp = db.persons.personId.count();
    final personQuery = db.selectOnly(db.persons)
      ..addColumns([personCountExp])
      ..where(db.persons.khorosId.equals(id));
    final personResult = await personQuery.getSingle();
    final count = personResult.read(personCountExp) ?? 0;
    if (count > 0) return false;

    await (db.delete(db.khoroses)..where((t) => t.khorosId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }
}
