import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/screens/id_card_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Layers use readable theme colors in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final font = FontLoader('LayerTestArabic')
        ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
      await font.load();
      final theme = ThemeData(
        brightness: brightness,
        colorSchemeSeed: Colors.indigo,
        fontFamily: 'LayerTestArabic',
      );
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
          ],
          child: MaterialApp(
            theme: theme,
            home: RepaintBoundary(
              key: boundaryKey,
              child: const IdCardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تصميم البطاقة').first);
      await tester.pumpAndSettle();
      expect(find.text('Layers'), findsOneWidget);
      final tiles = find
          .byType(ListTile)
          .evaluate()
          .map((e) => e.widget as ListTile)
          .where((tile) => tile.title is Text && tile.textColor != null)
          .toList();
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.textColor, theme.colorScheme.onSurface);
        expect(tile.iconColor, theme.colorScheme.onSurfaceVariant);
        expect(tile.selectedColor, theme.colorScheme.onSecondaryContainer);
      }
      final title = find.text('خلفية البطاقة');
      final containers = tester.widgetList<Container>(
        find.ancestor(of: title, matching: find.byType(Container)),
      );
      expect(
        containers.any(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration! as BoxDecoration).color ==
                  theme.colorScheme.surfaceContainer,
        ),
        isTrue,
      );
      if (brightness == Brightness.dark) {
        expect(
          theme.colorScheme.surfaceContainer.computeLuminance(),
          lessThan(0.2),
        );
        expect(
          theme.colorScheme.onSurface.computeLuminance(),
          greaterThan(0.5),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final artifacts = Directory('build/card-print-verification')
          ..createSync(recursive: true);
        File(
          '${artifacts.path}/layers-${brightness.name}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
  }
}
