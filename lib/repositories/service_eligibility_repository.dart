import 'package:drift/drift.dart' show Variable, BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../database/database_provider.dart';

const serviceEligibilityErrorMessage =
    'هذا الشخص غير مرتبط بالخدمة المحددة ولا يمكن تسجيل حضوره فيها.';

String serviceEligibilityErrorMessageFor({
  String? personName,
  String? serviceName,
}) {
  final cleanPersonName = personName?.trim();
  final cleanServiceName = serviceName?.trim();
  final hasPersonName = cleanPersonName != null && cleanPersonName.isNotEmpty;
  final hasServiceName =
      cleanServiceName != null && cleanServiceName.isNotEmpty;

  if (hasPersonName && hasServiceName) {
    return '$cleanPersonName مش مسجل في خدمة $cleanServiceName';
  }
  if (hasPersonName) return '$cleanPersonName مش مسجل في الخدمة المحددة';
  if (hasServiceName) return 'هذا الشخص مش مسجل في خدمة $cleanServiceName';
  return serviceEligibilityErrorMessage;
}

final serviceEligibilityRepositoryProvider =
    Provider<ServiceEligibilityRepository>((ref) {
      return ServiceEligibilityRepository(ref.watch(appDatabaseProvider));
    });

class ServiceEligibilityRepository {
  const ServiceEligibilityRepository(this.db);

  final AppDatabase db;

  Future<Set<int>> stageServiceIds(int? stageId) async {
    if (stageId == null) return {};
    final rows = await db
        .customSelect(
          '''
      SELECT "Service_ID" AS service_id
      FROM "Stage_Services"
      WHERE "Stage_ID" = ?
      UNION
      SELECT "Service_ID" AS service_id
      FROM "Stages"
      WHERE "Stage_ID" = ? AND "Service_ID" IS NOT NULL
      ''',
          variables: [Variable<int>(stageId), Variable<int>(stageId)],
        )
        .get();
    return rows.map((row) => row.read<int>('service_id')).toSet();
  }

  Future<Set<int>> khorosServiceIds(int? khorosId) async {
    if (khorosId == null) return {};
    final rows = await db
        .customSelect(
          '''
      SELECT "Service_ID" AS service_id
      FROM "Khoros_Services"
      WHERE "Khoros_ID" = ?
      UNION
      SELECT "Service_ID" AS service_id
      FROM "Khoroses"
      WHERE "Khoros_ID" = ? AND "Service_ID" IS NOT NULL
      ''',
          variables: [Variable<int>(khorosId), Variable<int>(khorosId)],
        )
        .get();
    return rows.map((row) => row.read<int>('service_id')).toSet();
  }

  Future<Set<int>> directPersonServiceIds(int personId) async {
    final rows = await (db.select(
      db.personServices,
    )..where((table) => table.personId.equals(personId))).get();
    return rows.map((row) => row.serviceId).toSet();
  }

  /// Resolve the same service union for list rows and edit details, including
  /// older databases whose inherited links were never copied to Person_Services.
  Future<Map<int, Map<int, String>>> personServiceNames(
    Iterable<int> personIds,
  ) async {
    final ids = personIds.toSet().toList();
    if (ids.isEmpty) return {};
    final rows = await db
        .customSelect(
          '''
      WITH selected_people AS (
        SELECT "Person_ID", "Stage_ID", "Khoros_ID" FROM "Persons"
        WHERE "Person_ID" IN (${List.filled(ids.length, '?').join(', ')})
      ), resolved_services AS (
        SELECT p."Person_ID" AS person_id, ps."Service_ID" AS service_id
        FROM selected_people p JOIN "Person_Services" ps ON ps."Person_ID" = p."Person_ID"
        UNION
        SELECT p."Person_ID", ss."Service_ID"
        FROM selected_people p JOIN "Stage_Services" ss ON ss."Stage_ID" = p."Stage_ID"
        UNION
        SELECT p."Person_ID", s."Service_ID"
        FROM selected_people p JOIN "Stages" s ON s."Stage_ID" = p."Stage_ID"
        WHERE s."Service_ID" IS NOT NULL
        UNION
        SELECT p."Person_ID", ks."Service_ID"
        FROM selected_people p JOIN "Khoros_Services" ks ON ks."Khoros_ID" = p."Khoros_ID"
        UNION
        SELECT p."Person_ID", k."Service_ID"
        FROM selected_people p JOIN "Khoroses" k ON k."Khoros_ID" = p."Khoros_ID"
        WHERE k."Service_ID" IS NOT NULL
      )
      SELECT r.person_id AS resolved_person_id, r.service_id AS resolved_service_id,
             s."Service_Name" AS resolved_service_name
      FROM resolved_services r JOIN "Services" s ON s."Service_ID" = r.service_id
      ORDER BY r.person_id, r.service_id
      ''',
          variables: [for (final id in ids) Variable<int>(id)],
        )
        .get();
    final result = <int, Map<int, String>>{};
    for (final row in rows) {
      result.putIfAbsent(row.read<int>('resolved_person_id'), () => {})[row
              .read<int>('resolved_service_id')] =
          row.readNullable<String>('resolved_service_name') ?? '';
    }
    return result;
  }

  Future<Set<int>> resolvedPersonServiceIds({
    required int personId,
    int? stageId,
    int? khorosId,
    Iterable<int> explicitServiceIds = const [],
  }) async {
    var resolvedStageId = stageId;
    var resolvedKhorosId = khorosId;
    if (resolvedStageId == null || resolvedKhorosId == null) {
      final person = await (db.select(
        db.persons,
      )..where((table) => table.personId.equals(personId))).getSingleOrNull();
      resolvedStageId ??= person?.stageId;
      resolvedKhorosId ??= person?.khorosId;
    }

    return {
      ...explicitServiceIds,
      ...await directPersonServiceIds(personId),
      ...await stageServiceIds(resolvedStageId),
      ...await khorosServiceIds(resolvedKhorosId),
    };
  }

  Future<bool> isPersonEligibleForService({
    required int personId,
    required int? serviceId,
  }) async {
    if (serviceId == null) return true;
    // Resolve membership in one round trip, without downloading the person's
    // photo or separately reading the person, stage, khoros and link tables.
    final row = await db
        .customSelect(
          '''
      SELECT "Person_ID" FROM "Persons" p
      WHERE p."Person_ID" = ? AND (
        EXISTS (SELECT 1 FROM "Person_Services" ps
          WHERE ps."Person_ID" = p."Person_ID" AND ps."Service_ID" = ?)
        OR EXISTS (SELECT 1 FROM "Stage_Services" ss
          WHERE ss."Stage_ID" = p."Stage_ID" AND ss."Service_ID" = ?)
        OR EXISTS (SELECT 1 FROM "Stages" s
          WHERE s."Stage_ID" = p."Stage_ID" AND s."Service_ID" = ?)
        OR EXISTS (SELECT 1 FROM "Khoros_Services" ks
          WHERE ks."Khoros_ID" = p."Khoros_ID" AND ks."Service_ID" = ?)
        OR EXISTS (SELECT 1 FROM "Khoroses" k
          WHERE k."Khoros_ID" = p."Khoros_ID" AND k."Service_ID" = ?)
      ) LIMIT 1
      ''',
          variables: [
            Variable<int>(personId),
            for (var i = 0; i < 5; i++) Variable<int>(serviceId),
          ],
        )
        .getSingleOrNull();
    return row != null;
  }

  Future<String> serviceEligibilityErrorFor({
    required int personId,
    required int? serviceId,
    String? personName,
    String? serviceName,
  }) async {
    var resolvedPersonName = personName;
    var resolvedServiceName = serviceName;

    if (resolvedPersonName == null || resolvedPersonName.trim().isEmpty) {
      final person = await (db.select(
        db.persons,
      )..where((table) => table.personId.equals(personId))).getSingleOrNull();
      resolvedPersonName = person?.personName;
    }

    if (serviceId != null &&
        (resolvedServiceName == null || resolvedServiceName.trim().isEmpty)) {
      final service = await (db.select(
        db.services,
      )..where((table) => table.serviceId.equals(serviceId))).getSingleOrNull();
      resolvedServiceName = service?.serviceName;
    }

    return serviceEligibilityErrorMessageFor(
      personName: resolvedPersonName,
      serviceName: resolvedServiceName,
    );
  }

  Future<void> replacePersonServiceLinks({
    required int personId,
    required Iterable<int> explicitServiceIds,
    int? stageId,
    int? khorosId,
  }) async {
    final resolved = {
      ...explicitServiceIds,
      ...await stageServiceIds(stageId),
      ...await khorosServiceIds(khorosId),
    };

    await db.transaction(() async {
      // Keep retained memberships in place. Deleting them first can remove the
      // person from a service-scoped user's visibility before reinsertion.
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.personServices, [
          for (final serviceId in resolved)
            PersonServicesCompanion.insert(
              personId: personId,
              serviceId: serviceId,
            ),
        ]);
      });
      await (db.delete(db.personServices)..where(
            (table) => resolved.isEmpty
                ? table.personId.equals(personId)
                : table.personId.equals(personId) &
                      table.serviceId.isNotIn(resolved),
          ))
          .go();
    });
  }

  Future<void> syncResolvedServicesForPerson(int personId) async {
    final person = await (db.select(
      db.persons,
    )..where((table) => table.personId.equals(personId))).getSingleOrNull();
    if (person == null) return;

    await replacePersonServiceLinks(
      personId: personId,
      explicitServiceIds: await directPersonServiceIds(personId),
      stageId: person.stageId,
      khorosId: person.khorosId,
    );
  }

  Future<void> syncResolvedServicesForPeople(Iterable<int> personIds) async {
    for (final personId in personIds.toSet()) {
      await syncResolvedServicesForPerson(personId);
    }
  }

  Future<void> addInheritedServicesForPeople({
    required Iterable<int> personIds,
    required Iterable<int> serviceIds,
  }) async {
    final uniqueServices = serviceIds.toSet();
    if (uniqueServices.isEmpty) return;
    for (final personId in personIds) {
      for (final serviceId in uniqueServices) {
        await db
            .into(db.personServices)
            .insertOnConflictUpdate(
              PersonServicesCompanion.insert(
                personId: personId,
                serviceId: serviceId,
              ),
            );
      }
    }
  }
}
