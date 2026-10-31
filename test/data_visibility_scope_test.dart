import 'dart:convert';
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/models/data_visibility_scope.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.services)
        .insert(
          ServicesCompanion.insert(
            serviceId: const d.Value(1),
            serviceName: const d.Value('الخدمة أ'),
          ),
        );
    await db
        .into(db.services)
        .insert(
          ServicesCompanion.insert(
            serviceId: const d.Value(2),
            serviceName: const d.Value('الخدمة ب'),
          ),
        );
    await db
        .into(db.stages)
        .insert(
          StagesCompanion.insert(
            stageId: const d.Value(5),
            stageName: const d.Value('5ب'),
          ),
        );
    await db
        .into(db.stages)
        .insert(
          StagesCompanion.insert(
            stageId: const d.Value(6),
            stageName: const d.Value('6ب'),
          ),
        );
    await db
        .into(db.areas)
        .insert(
          AreasCompanion.insert(
            areaId: const d.Value(1),
            areaName: const d.Value('رئيسية'),
          ),
        );
    await db
        .into(db.areas)
        .insert(
          AreasCompanion.insert(
            areaId: const d.Value(2),
            parentId: const d.Value(1),
            areaName: const d.Value('فرعية'),
          ),
        );
    for (var id = 1; id <= 4; id++) {
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              personId: d.Value(id),
              personName: d.Value('شخص $id'),
              stageId: d.Value(id == 4 ? 6 : 5),
              jenderName: d.Value(id == 3 ? 'أنثى' : 'ذكر'),
              areaId: const d.Value(2),
              rohot: const d.Value("رهط 'أ"),
              leader: const d.Value('قائد أ'),
            ),
          );
      await db
          .into(db.personServices)
          .insert(
            PersonServicesCompanion.insert(
              personId: id,
              serviceId: id == 2 ? 2 : 1,
            ),
          );
      await db
          .into(db.coming)
          .insert(
            ComingCompanion.insert(
              id: d.Value(id),
              personId: d.Value(id),
              serviceId: d.Value(id == 2 ? 2 : 1),
              point: const d.Value(10),
            ),
          );
    }
  });
  tearDown(() async => db.close());
  Future<List<int>> ids() async =>
      (await db.select(db.persons).get()).map((p) => p.personId).toList()
        ..sort();

  test('default all, OR in a dimension, AND across dimensions', () async {
    expect(await ids(), [1, 2, 3, 4]);
    db.setVisibilityScope(
      const DataVisibilityScope({
        'service': ['1'],
        'gender': ['ذكر'],
        'stage': ['5'],
      }),
    );
    expect(await ids(), [1]);
    db.setVisibilityScope(
      const DataVisibilityScope({
        'service': ['1', '2'],
        'gender': ['ذكر'],
        'stage': ['5'],
      }),
    );
    expect(await ids(), [1, 2]);
  });
  test(
    'aggregates and raw SQL cannot count hidden people or their attendance',
    () async {
      db.setVisibilityScope(
        const DataVisibilityScope({
          'service': ['1'],
          'gender': ['ذكر'],
          'stage': ['5'],
        }),
      );
      final rows = await db
          .customSelect(
            'SELECT COUNT(*) AS n, SUM("Point") AS points FROM "Coming"',
          )
          .getSingle();
      expect(rows.data['n'], 1);
      expect(rows.data['points'], 10);
      final joined = await db
          .customSelect(
            'SELECT p."Person_ID" FROM "Persons" p JOIN "Coming" c ON c."Person_ID"=p."Person_ID"',
          )
          .get();
      expect(joined.length, 1);
    },
  );
  test(
    'area descendants, text dimensions and apostrophes remain safe',
    () async {
      db.setVisibilityScope(
        const DataVisibilityScope({
          'area': ['1'],
          'rohot': ["رهط 'أ"],
          'leader': ['قائد أ'],
        }),
      );
      expect(await ids(), [1, 2, 3, 4]);
      db.setVisibilityScope(
        const DataVisibilityScope({
          'rohot': ["x') OR 1=1 --"],
        }),
      );
      expect(await ids(), isEmpty);
    },
  );
  test('an empty restriction denies all, while missing means all', () async {
    db.setVisibilityScope(const DataVisibilityScope({'service': []}));
    expect(await ids(), isEmpty);
    db.setVisibilityScope(const DataVisibilityScope());
    expect(await ids(), hasLength(4));
  });
  test(
    'inherited service membership is visible without denormalized person links',
    () async {
      await db
          .into(db.stageServices)
          .insert(StageServicesCompanion.insert(stageId: 6, serviceId: 2));
      db.setVisibilityScope(
        const DataVisibilityScope({
          'service': ['2'],
          'stage': ['6'],
        }),
      );
      expect(await ids(), [4]);
    },
  );
  test('JSON payments are scoped before totals can be calculated', () async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            settingKey: const d.Value('monthly_fund_payments_json'),
            settingValue: d.Value(jsonEncode({'1': 10, '2': 100, '3': 1000})),
          ),
        );
    db.setVisibilityScope(
      const DataVisibilityScope({
        'service': ['1'],
        'gender': ['ذكر'],
        'stage': ['5'],
      }),
    );
    final row =
        await (db.select(db.settings)
              ..where((t) => t.settingKey.equals('monthly_fund_payments_json')))
            .getSingle();
    expect(jsonDecode(row.settingValue!), {'1': 10});
  });
  test(
    'saving scoped payments preserves hidden payments and blocks foreign IDs',
    () async {
      final repo = SettingsRepository(db);
      await repo.saveSetting(
        'monthly_fund_payments_json',
        '{"1":10,"2":100,"3":1000}',
      );
      db.setVisibilityScope(
        const DataVisibilityScope({
          'service': ['1'],
          'gender': ['ذكر'],
          'stage': ['5'],
        }),
      );
      await repo.saveSetting('monthly_fund_payments_json', '{"1":20}');
      expect(
        jsonDecode((await repo.getSetting('monthly_fund_payments_json'))!),
        {'1': 20},
      );
      await expectLater(
        repo.saveSetting('monthly_fund_payments_json', '{"2":9}'),
        throwsStateError,
      );
      db.setVisibilityScope(const DataVisibilityScope());
      expect(
        jsonDecode((await repo.getSetting('monthly_fund_payments_json'))!),
        {'1': 20, '2': 100, '3': 1000},
      );
    },
  );
  test('scope round trip and corrupt configuration fail closed', () {
    const scope = DataVisibilityScope({
      'stage': ['5'],
      'rohot': ["رهط 'أ"],
    });
    expect(
      DataVisibilityScope.decode(jsonEncode(scope.toJson())).toJson(),
      scope.toJson(),
    );
    expect(DataVisibilityScope.decode('invalid').selections, {
      'stage': <String>[],
    });
  });

  test(
    'public card-code allocation remains unique without exposing people',
    () async {
      db.setVisibilityScope(const DataVisibilityScope({'stage': []}));
      expect(await ids(), isEmpty);
      final next = await db
          .customSelect(
            'SELECT COALESCE(MAX("Person_ID"),0)+1 AS next_id FROM "Persons"',
          )
          .getSingle();
      expect(next.read<int>('next_id'), 5);
      final exists = await db
          .customSelect(
            'SELECT COUNT(*) AS id_exists FROM "Persons" WHERE "Person_ID" = ?',
            variables: [const d.Variable(4)],
          )
          .getSingle();
      expect(exists.read<int>('id_exists'), 1);
    },
  );
}
