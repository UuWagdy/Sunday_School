import 'package:flutter/material.dart';
import 'package:petros_pols_flutter/widgets/backup_settings_card.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:petros_pols_flutter/services/automatic_backup_service.dart';
import 'package:petros_pols_flutter/services/sqlite_backup_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sqlite-backup-test-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test(
    'SQLite snapshot includes committed WAL pages, Arabic and blobs',
    () async {
      final path = '${root.path}/live.db';
      final db = sqlite3.open(path);
      try {
        db.execute('PRAGMA journal_mode=WAL');
        db.execute('PRAGMA wal_autocheckpoint=0');
        db.execute(
          'CREATE TABLE probe (id INTEGER PRIMARY KEY, name TEXT, payload BLOB)',
        );
        db.execute('PRAGMA user_version=32');
        db.execute('INSERT INTO probe VALUES (?, ?, ?)', [
          1,
          'اختبار النسخ',
          [0, 17, 255],
        ]);
        expect(await File('$path-wal').exists(), isTrue);
        await createSqliteBackup(path, '${root.path}/snapshot.db');
        final restored = sqlite3.open('${root.path}/snapshot.db');
        try {
          expect(
            restored.select('SELECT name FROM probe').single['name'],
            'اختبار النسخ',
          );
          expect(
            restored.select('SELECT payload FROM probe').single['payload'],
            [0, 17, 255],
          );
          expect(
            restored.select('PRAGMA user_version').single.values.single,
            32,
          );
          expect(
            restored.select('PRAGMA quick_check').single.values.single,
            'ok',
          );
        } finally {
          restored.dispose();
        }
      } finally {
        db.dispose();
      }
    },
  );
  test(
    'automatic retention only prunes successful managed backups; failures retain history',
    () async {
      final folder = Directory('${root.path}/chosen folder');
      await folder.create();
      final source = '${root.path}/source.db';
      final db = sqlite3.open(source)
        ..execute('CREATE TABLE probe (id INTEGER)');
      db.dispose();
      SharedPreferences.setMockInitialValues({
        'automatic_database_backup_v1': jsonEncode({
          'enabled': true,
          'directory': folder.path,
          'retention': 2,
        }),
      });
      final unrelated = File('${folder.path}/manual.db');
      await unrelated.writeAsString('keep');
      var fail = false;
      final service = AutomaticBackupService(
        prefix: 'SundaySchool',
        isServerMode: () => false,
        serverUrl: () => '',
        headers: () => {},
        snapshot: (target) async {
          if (fail) {
            await File(target).writeAsString('partial');
            throw StateError('disk unavailable');
          }
          await createSqliteBackup(source, target);
        },
      );
      for (var i = 0; i < 3; i++) {
        await service.runNow();
      }
      final before = await service.load();
      expect(
        (await folder.list().toList()).length,
        3,
      ); // two automatic + manual
      expect(await unrelated.readAsString(), 'keep');
      fail = true;
      await expectLater(service.runNow(), throwsStateError);
      final after = await service.load();
      expect(after['lastSuccessUtc'], before['lastSuccessUtc']);
      expect(after['lastError'], contains('disk unavailable'));
      expect((await folder.list().toList()).length, 3);
    },
  );
  test(
    'server mode routes settings and run to server without touching SQLite',
    () async {
      var snapshots = 0;
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(
          jsonEncode({
            'enabled': true,
            'directory': 'server-folder',
            'retention': 30,
            'lastPath': 'server-folder/native.dump',
          }),
          200,
        );
      });
      final service = AutomaticBackupService(
        prefix: 'SundaySchool',
        isServerMode: () => true,
        serverUrl: () => 'http://backup-server',
        headers: () => {'Authorization': 'Bearer test'},
        client: client,
        snapshot: (_) async {
          snapshots++;
        },
      );
      try {
        expect((await service.load())['directory'], 'server-folder');
        expect(await service.runNow(), endsWith('.dump'));
        expect(paths, ['/api/backups/settings', '/api/backups/run']);
        expect(snapshots, 0);
      } finally {
        client.close();
      }
    },
  );
  testWidgets('backup settings show engine and persist the daily toggle', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'automatic_database_backup_v1': jsonEncode({
        'enabled': true,
        'directory': root.path,
        'retention': 30,
      }),
    });
    final service = AutomaticBackupService(
      prefix: 'test',
      isServerMode: () => false,
      serverUrl: () => '',
      headers: () => {},
      snapshot: (_) async {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BackupSettingsCard(service: service),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('SQLite'), findsOneWidget);
    expect(find.text('اختيار مجلد الحفظ'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byType(SwitchListTile));
      // The real directory write probe must complete outside the fake test clock.
      for (var i = 0; i < 100; i++) {
        if ((await service.load())['enabled'] == false) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect((await service.load())['enabled'], false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
