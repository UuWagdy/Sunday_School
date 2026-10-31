import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/screens/persons_screen.dart';
import 'package:petros_pols_flutter/screens/person_dialog.dart';
import 'package:petros_pols_flutter/ui/dialogs/bulk_edit_dialog.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/sync/dotnet_postgres_executor.dart';
import 'package:petros_pols_flutter/sync/server_config.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

class _NativeHttp extends HttpOverrides {}

class _LiveClient extends http.BaseClient {
  final _delegate = IOClient(_NativeHttp().createHttpClient(null));
  int pending = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    pending++;
    try {
      return await _delegate.send(request);
    } finally {
      pending--;
    }
  }

  @override
  void close() => _delegate.close();
}

const _captureKey = ValueKey('bulk-ui-capture');
Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final picture = await boundary.toImage();
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/test_artifacts')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Arial',
    )..addFont(rootBundle.load('assets/fonts/arial.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'two selected people keep all four services after bulk dialog save and reopening',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const url = String.fromEnvironment('SERVICE_TEST_URL');
      final client = url.isEmpty ? null : _LiveClient();
      addTearDown(() => client?.close());
      Future<void> settle() async {
        if (client == null) {
          await tester.pumpAndSettle();
          return;
        }
        var quiet = 0;
        for (var i = 0; i < 300; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          quiet = client.pending == 0 && !tester.binding.hasScheduledFrame
              ? quiet + 1
              : 0;
          if (quiet >= 5) return;
        }
        throw StateError('Live server UI did not settle');
      }

      Future<T> read<T>(Future<T> Function() query) async {
        if (client == null) return query();
        T? value;
        Object? failure;
        var completed = false;
        query().then(
          (result) {
            value = result;
            completed = true;
          },
          onError: (Object error) {
            failure = error;
            completed = true;
          },
        );
        for (var i = 0; i < 10 && !completed; i++) {
          await settle();
        }
        if (failure != null) throw failure!;
        if (!completed)
          throw StateError('Live database check did not complete');
        return value as T;
      }

      if (url.isNotEmpty &&
          !const bool.fromEnvironment('SERVICE_TEST_DISPOSABLE')) {
        throw StateError('Use the isolated service test runner.');
      }
      final db = AppDatabase.forTesting(
        url.isEmpty
            ? NativeDatabase.memory()
            : DotNetPostgresQueryExecutor(
                httpClient: client,
                getConfig: () => const ServerConfig(
                  serverUrl: url,
                  jwtToken: String.fromEnvironment('SERVICE_TEST_TOKEN'),
                ),
              ),
      );
      await tester.runAsync(() async {
        for (final id in [11, 12, 13, 14]) {
          await db
              .into(db.services)
              .insert(
                ServicesCompanion.insert(
                  serviceId: d.Value(id),
                  serviceName: d.Value('خدمة اختبار $id'),
                ),
              );
        }
        for (final id in [2090, 2091, 2092]) {
          await db
              .into(db.persons)
              .insert(
                PersonsCompanion.insert(
                  personId: d.Value(id),
                  personName: d.Value('مخدوم اختبار $id'),
                  phone: d.Value('02-$id'),
                ),
              );
          await db
              .into(db.personServices)
              .insert(
                PersonServicesCompanion.insert(personId: id, serviceId: 11),
              );
        }
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
          ],
          child: RepaintBoundary(
            key: _captureKey,
            child: MaterialApp(
              theme: ThemeData(
                brightness: Brightness.dark,
                fontFamily: 'Arial',
              ),
              home: const PersonsScreen(),
            ),
          ),
        ),
      );
      await settle();
      expect(find.byType(Checkbox), findsNWidgets(4));
      await tester.tap(find.byType(Checkbox).at(1));
      await settle();
      await tester.tap(find.byType(Checkbox).at(2));
      await settle();
      final bulkButton = find.byTooltip('تعديل جماعي');
      await tester.tap(
        bulkButton.evaluate().isNotEmpty
            ? bulkButton
            : find.text('تعديل جماعي'),
      );
      await settle();
      expect(find.text('تعديل جماعي لعدد 2 شخص'), findsOneWidget);
      final servicesCheckbox = find
          .descendant(
            of: find.byType(BulkEditDialog),
            matching: find.byType(Checkbox),
          )
          .at(7);
      await tester.ensureVisible(servicesCheckbox);
      await tester.tap(servicesCheckbox);
      await settle();
      await tester.ensureVisible(find.text('تعديل الخدمات'));
      await tester.tap(find.text('تعديل الخدمات'));
      await settle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField && w.decoration?.labelText == 'بحث في الخدمات...',
        ),
        'خدمة اختبار',
      );
      await settle();
      for (final id in [11, 12, 13, 14]) {
        await tester.tap(
          find.widgetWithText(CheckboxListTile, 'خدمة اختبار $id'),
        );
        await settle();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'موافق'));
      await settle();
      expect(find.text('الخدمات: 4'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ التعديلات'));
      await settle();
      expect(tester.takeException(), isNull);
      expect(find.text('تم تعديل البيانات بنجاح'), findsOneWidget);
      for (final id in [2091, 2092]) {
        final links = await read(
          () => (db.select(
            db.personServices,
          )..where((t) => t.personId.equals(id))).get(),
        );
        expect(links.map((link) => link.serviceId).toSet(), {11, 12, 13, 14});
        final card = find
            .ancestor(
              of: find.text('مخدوم اختبار $id'),
              matching: find.byType(Card),
            )
            .first;
        await tester.tap(
          find.descendant(of: card, matching: find.byTooltip('تعديل')),
        );
        await settle();
        expect(find.byType(PersonDialog), findsOneWidget);
        final servicesButton = find.text('إضافة / تعديل الخدمات');
        await tester.ensureVisible(servicesButton);
        await tester.tap(servicesButton);
        await settle();
        await tester.enterText(
          find.byWidgetPredicate(
            (w) =>
                w is TextField && w.decoration?.hintText == 'ابحث عن خدمة...',
          ),
          'خدمة اختبار',
        );
        await settle();
        for (final serviceId in [11, 12, 13, 14]) {
          expect(
            tester
                .widget<CheckboxListTile>(
                  find.widgetWithText(
                    CheckboxListTile,
                    'خدمة اختبار $serviceId',
                  ),
                )
                .value,
            isTrue,
          );
        }
        await tester.tap(find.widgetWithText(TextButton, 'إلغاء').last);
        await settle();
        if (id == 2091)
          await capture(
            tester,
            'bulk-four-services-${url.isEmpty ? 'local' : 'remote'}',
          );
        await tester.tap(
          find
              .descendant(
                of: find.byType(PersonDialog),
                matching: find.byIcon(Icons.close),
              )
              .first,
        );
        await settle();
      }
      expect(
        (await read(
          () => (db.select(
            db.personServices,
          )..where((t) => t.personId.equals(2090))).get(),
        )).map((link) => link.serviceId),
        [11],
      );
      expect(
        (await read(
          () => db.select(db.persons).get(),
        )).every((p) => p.phone == '02-${p.personId}'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'load size labels and 500 selection are visible in $brightness',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(1800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              authServiceProvider.overrideWith(_Auth.new),
            ],
            child: RepaintBoundary(
              key: _captureKey,
              child: MaterialApp(
                theme: ThemeData(brightness: brightness, fontFamily: 'Arial'),
                home: const PersonsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['50', '100', '200', '500', 'الكل']) {
          expect(find.text(label), findsOneWidget);
        }
        await tester.tap(find.text('500'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.text('500')).style!.fontWeight,
          FontWeight.bold,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, 'people-load-sizes-${brightness.name}');
        await tester.pumpWidget(const SizedBox());
        await db.close();
      },
    );
  }
}
