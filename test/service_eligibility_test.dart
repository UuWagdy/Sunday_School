import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/repositories/service_eligibility_repository.dart';

void main() {
  late AppDatabase db;
  late ServiceEligibilityRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ServiceEligibilityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addService(String name) {
    return db
        .into(db.services)
        .insert(ServicesCompanion.insert(serviceName: drift.Value(name)));
  }

  test('resolves union of direct, stage, and khoros service links', () async {
    final directService = await addService('Direct');
    final stageService = await addService('Stage');
    final khorosService = await addService('Khoros');

    final stageId = await db
        .into(db.stages)
        .insert(StagesCompanion.insert(stageName: const drift.Value('Stage')));
    final khorosId = await db
        .into(db.khoroses)
        .insert(
          KhorosesCompanion.insert(khorosName: const drift.Value('Khoros')),
        );
    final personId = await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            personName: const drift.Value('Person'),
            stageId: drift.Value(stageId),
            khorosId: drift.Value(khorosId),
          ),
        );

    await db
        .into(db.personServices)
        .insert(
          PersonServicesCompanion.insert(
            personId: personId,
            serviceId: directService,
          ),
        );
    await db.customStatement(
      'INSERT INTO "Stage_Services" ("Stage_ID", "Service_ID") VALUES (?, ?)',
      [stageId, stageService],
    );
    await db.customStatement(
      'INSERT INTO "Khoros_Services" ("Khoros_ID", "Service_ID") VALUES (?, ?)',
      [khorosId, khorosService],
    );

    final resolved = await repository.resolvedPersonServiceIds(
      personId: personId,
    );

    expect(resolved, containsAll([directService, stageService, khorosService]));
    expect(
      await repository.isPersonEligibleForService(
        personId: personId,
        serviceId: stageService,
      ),
      isTrue,
    );
  });

  test(
    'replacePersonServiceLinks preserves inherited stage and khoros links',
    () async {
      final explicitService = await addService('Explicit');
      final stageService = await addService('Stage');
      final khorosService = await addService('Khoros');
      final stageId = await db
          .into(db.stages)
          .insert(
            StagesCompanion.insert(stageName: const drift.Value('Stage')),
          );
      final khorosId = await db
          .into(db.khoroses)
          .insert(
            KhorosesCompanion.insert(khorosName: const drift.Value('Khoros')),
          );
      final personId = await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(personName: const drift.Value('Person')),
          );

      await db.customStatement(
        'INSERT INTO "Stage_Services" ("Stage_ID", "Service_ID") VALUES (?, ?)',
        [stageId, stageService],
      );
      await db.customStatement(
        'INSERT INTO "Khoros_Services" ("Khoros_ID", "Service_ID") VALUES (?, ?)',
        [khorosId, khorosService],
      );

      await repository.replacePersonServiceLinks(
        personId: personId,
        explicitServiceIds: [explicitService],
        stageId: stageId,
        khorosId: khorosId,
      );

      final saved = await repository.directPersonServiceIds(personId);
      expect(
        saved,
        containsAll([explicitService, stageService, khorosService]),
      );
    },
  );

  test(
    'syncResolvedServicesForPeople adds linked khoros services to members',
    () async {
      final khorosService = await addService('Khoros');
      final khorosId = await db
          .into(db.khoroses)
          .insert(
            KhorosesCompanion.insert(khorosName: const drift.Value('Khoros')),
          );
      final personId = await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personName: const drift.Value('Person'),
              khorosId: drift.Value(khorosId),
            ),
          );

      await db.customStatement(
        'INSERT INTO "Khoros_Services" ("Khoros_ID", "Service_ID") VALUES (?, ?)',
        [khorosId, khorosService],
      );

      await repository.syncResolvedServicesForPeople([personId]);

      final saved = await repository.directPersonServiceIds(personId);
      expect(saved, contains(khorosService));
    },
  );
}
