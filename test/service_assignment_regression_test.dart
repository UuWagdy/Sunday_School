import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/repositories/stages_repository.dart';
import 'package:petros_pols_flutter/repositories/khoros_repository.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';

class TestAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  setUp(() async {
    const url = String.fromEnvironment('SERVICE_TEST_URL');
    if (url.isNotEmpty &&
        !const bool.fromEnvironment('SERVICE_TEST_DISPOSABLE')) {
      throw StateError(
        'Use tool/test_service_assignments.py with a disposable database.',
      );
    }
    db = AppDatabase.forTesting(
      url.isEmpty
          ? NativeDatabase.memory()
          : DotNetPostgresQueryExecutor(
              getConfig: () => const ServerConfig(
                serverUrl: url,
                jwtToken: String.fromEnvironment('SERVICE_TEST_TOKEN'),
              ),
            ),
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWith(TestAuth.new),
      ],
    );
    for (var id = 1; id <= 3; id++) {
      await db
          .into(db.services)
          .insertOnConflictUpdate(
            ServicesCompanion.insert(
              serviceId: d.Value(id),
              serviceName: d.Value('خدمة $id'),
            ),
          );
    }
  });
  tearDown(() async {
    container.dispose();
    // The remote variant must target only the disposable database created by
    // tool/test_service_assignments.py. Reset fixtures between test cases.
    if (const String.fromEnvironment('SERVICE_TEST_URL') != '') {
      for (final table in <d.TableInfo>[
        db.personServices,
        db.stageServices,
        db.khorosServices,
        db.personCustomFieldValues,
        db.persons,
        db.stages,
        db.khoroses,
      ]) {
        await db.delete(table).go();
      }
    }
    await db.close();
  });
  Future<Set<int>> services(int personId) async =>
      (await (db.select(
            db.personServices,
          )..where((t) => t.personId.equals(personId))).get())
          .map((s) => s.serviceId)
          .toSet();
  test(
    'stage save persists every selected link and updates existing members',
    () async {
      final subscription = container.listen(
        stagesRepositoryProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      await container.read(stagesRepositoryProvider.future);
      final repo = container.read(stagesRepositoryProvider.notifier);
      expect(await repo.addStage('5ب', serviceIds: [1, 2]), true);
      final stage = (await db.select(db.stages).get()).single;
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: const d.Value(1),
              personName: const d.Value('شخص'),
              stageId: d.Value(stage.stageId),
            ),
          );
      expect(
        await repo.updateStage(stage.stageId, '5ب', serviceIds: [2, 3]),
        true,
      );
      final links = await db.select(db.stageServices).get();
      expect(links.map((r) => r.serviceId).toSet(), {2, 3});
      expect(await services(1), {2, 3});
    },
  );
  test(
    'khoros individual and bulk saves persist links and inherited memberships',
    () async {
      final sub = container.listen(khorosRepositoryProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(khorosRepositoryProvider.future);
      final repo = container.read(khorosRepositoryProvider.notifier);
      expect(await repo.addKhoros('خورس أ', serviceIds: [1, 2]), true);
      final khoros = (await db.select(db.khoroses).get()).single;
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: const d.Value(1),
              personName: const d.Value('شخص'),
              khorosId: d.Value(khoros.khorosId),
            ),
          );
      expect(
        await repo.updateKhorosServicesForIds([khoros.khorosId], [2, 3]),
        1,
      );
      expect(
        (await db.select(db.khorosServices).get())
            .map((r) => r.serviceId)
            .toSet(),
        {2, 3},
      );
      expect(await services(1), {2, 3});
    },
  );
  test(
    'bulk person service edit preserves inheritance and applies all explicit links',
    () async {
      await db
          .into(db.stages)
          .insert(
            StagesCompanion.insert(
              stageId: const d.Value(5),
              stageName: const d.Value('5ب'),
            ),
          );
      await db
          .into(db.stageServices)
          .insert(StageServicesCompanion.insert(stageId: 5, serviceId: 1));
      for (var id = 1; id <= 2; id++) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value('شخص $id'),
                stageId: const d.Value(5),
              ),
            );
      }
      final repo = container.read(personsRepositoryProvider.notifier);
      expect(
        await repo.bulkUpdatePersons(ids: [1, 2], serviceIds: [2, 3]),
        true,
      );
      expect(await services(1), {1, 2, 3});
      expect(await services(2), {1, 2, 3});
    },
  );
  test(
    'similar names normalize Arabic and exclude the edited person',
    () async {
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: const d.Value(1),
              personName: const d.Value('أحمد إبراهيم علي'),
            ),
          );
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: const d.Value(2),
              personName: const d.Value('احمد ابراهيم بطرس'),
            ),
          );
      final matches = await container
          .read(personsRepositoryProvider.notifier)
          .findSimilarNames('احمد ابراهيم', excludeId: 1);
      expect(matches.map((p) => p.id), [2]);
    },
  );
  test(
    'person list and edit details show inherited services on old data',
    () async {
      await db
          .into(db.stages)
          .insert(
            StagesCompanion.insert(
              stageId: const d.Value(5),
              stageName: const d.Value('5ب'),
              serviceId: const d.Value(1),
            ),
          );
      await db
          .into(db.stageServices)
          .insert(StageServicesCompanion.insert(stageId: 5, serviceId: 2));
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: const d.Value(1),
              personName: const d.Value('شخص'),
              stageId: const d.Value(5),
            ),
          );
      final repo = container.read(personsRepositoryProvider.notifier);
      final detail = await repo.fetchPersonById(1);
      expect(detail!.serviceIds.toSet(), {1, 2});
      expect(detail.services, contains('خدمة 1'));
      expect(detail.services, contains('خدمة 2'));
      final listed = (await repo.fetchPersons(personIds: [1])).single;
      expect(listed.serviceIds.toSet(), {1, 2});
      expect(listed.services, contains('خدمة 2'));
    },
  );
  test(
    'individual save reopens with explicit and inherited services',
    () async {
      final repo = container.read(personsRepositoryProvider.notifier);
      final id = await repo.addPerson(name: 'مخدوم', serviceIds: [1, 2]);
      expect(id, isNotNull);
      expect((await repo.fetchPersonById(id!))!.serviceIds.toSet(), {1, 2});
      expect(
        await repo.updatePerson(id: id, name: 'مخدوم', serviceIds: [2, 3]),
        true,
      );
      expect((await repo.fetchPersonById(id))!.serviceIds.toSet(), {2, 3});
    },
  );
  test(
    'person saves without services and can remove their last service',
    () async {
      final repo = container.read(personsRepositoryProvider.notifier);
      final id = await repo.addPerson(name: 'بدون خدمة');
      expect(id, isNotNull);
      expect(await repo.updatePerson(id: id!, name: 'تعديل بدون خدمة'), true);
      expect((await repo.fetchPersonById(id))!.name, 'تعديل بدون خدمة');
      expect(await services(id), isEmpty);
      expect(
        await repo.updatePerson(id: id, name: 'خدمة واحدة', serviceIds: [1]),
        true,
      );
      expect(await services(id), {1});
      expect(await repo.updatePerson(id: id, name: 'إزالة آخر خدمة'), true);
      expect((await repo.fetchPersonById(id))!.name, 'إزالة آخر خدمة');
      expect(await services(id), isEmpty);
    },
  );
  test(
    'service scoped individual and bulk edits retain visibility and hidden links',
    () async {
      for (final id in [1, 2]) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: d.Value(id),
                personName: d.Value('مخدوم $id'),
              ),
            );
        for (final serviceId in [1, 3]) {
          await db
              .into(db.personServices)
              .insert(
                PersonServicesCompanion.insert(
                  personId: id,
                  serviceId: serviceId,
                ),
              );
        }
      }
      final scopedDb = AppDatabase.forTesting(
        DotNetPostgresQueryExecutor(
          getConfig: () => const ServerConfig(
            serverUrl: String.fromEnvironment('SERVICE_TEST_URL'),
            jwtToken: String.fromEnvironment('SERVICE_TEST_WORKER_TOKEN'),
          ),
        ),
      );
      scopedDb.visibilityContext.applyLocally = false;
      final scoped = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(scopedDb),
          authServiceProvider.overrideWith(TestAuth.new),
        ],
      );
      addTearDown(() async {
        scoped.dispose();
        await scopedDb.close();
      });
      final repo = scoped.read(personsRepositoryProvider.notifier);
      expect(
        await repo.updatePerson(id: 1, name: 'مخدوم 1', serviceIds: [1, 2]),
        true,
      );
      expect(
        await repo.bulkUpdatePersons(ids: [1, 2], serviceIds: [1, 2]),
        true,
      );
      expect((await repo.fetchPersonById(1))!.serviceIds.toSet(), {1, 2});
      expect(await services(1), {1, 2, 3});
      expect(await services(2), {1, 2, 3});
    },
    skip: const String.fromEnvironment('SERVICE_TEST_URL').isEmpty,
  );
}
