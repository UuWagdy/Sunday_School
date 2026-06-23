import 'package:drift/drift.dart' show Variable;
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
      return ServiceEligibilityRepository(ref.read(appDatabaseProvider));
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
    final services = await resolvedPersonServiceIds(personId: personId);
    return services.contains(serviceId);
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

    await (db.delete(
      db.personServices,
    )..where((table) => table.personId.equals(personId))).go();
    for (final serviceId in resolved) {
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
