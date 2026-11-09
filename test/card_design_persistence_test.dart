import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';
import 'package:petros_pols_flutter/screens/id_card_screen.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';
import 'package:petros_pols_flutter/widgets/card_designer_preview.dart';

class _Auth extends AuthService {
  @override
  Future<User?> build() async => null;
}

CardTemplate design(String text) => CardTemplate.defaults().copyWith(
  fixedTexts: [CardFixedTextElement(text: text, x: .1, y: .1, width: .5)],
);

void main() {
  test(
    'both faces survive closing and reopening the physical database',
    () async {
      final directory = await Directory.systemTemp.createTemp('card-restart-');
      final file = File('${directory.path}/cards.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var repo = SettingsRepository(db);
        await repo.saveCardDesign(
          front: design('الوجه المحفوظ'),
          back: design('الظهر المحفوظ'),
          printBack: true,
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = SettingsRepository(db);
        expect(
          (await repo.getActiveCardTemplate()).fixedTexts.single.text,
          'الوجه المحفوظ',
        );
        expect(
          CardTemplate.fromJsonString(
            (await repo.getSetting('id_card_back_template'))!,
          ).fixedTexts.single.text,
          'الظهر المحفوظ',
        );
        expect(await repo.getSetting('id_card_print_back'), 'true');
        expect(await repo.getSetting('id_card_designer_mode'), 'true');
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('a failed back-face write rolls back the entire saved design', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = SettingsRepository(db);
    try {
      await repo.saveCardDesign(
        front: design('قديم'),
        back: design('قديم ظهر'),
        printBack: false,
      );
      await db.customStatement('''
        CREATE TRIGGER reject_back BEFORE UPDATE ON Settings
        WHEN NEW.Setting_Key = 'id_card_back_template'
        BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;
      ''');
      await expectLater(
        repo.saveCardDesign(
          front: design('جديد'),
          back: design('جديد ظهر'),
          printBack: true,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        (await repo.getActiveCardTemplate()).fixedTexts.single.text,
        'قديم',
      );
      expect(await repo.getSetting('id_card_print_back'), 'false');
    } finally {
      await db.close();
    }
  });

  testWidgets('saving in the designer reopens both faces in design mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWith(_Auth.new),
          ],
          child: const MaterialApp(home: IdCardScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> addText(String text) async {
      await tester.tap(find.byTooltip('إضافة نص').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        text,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('تصميم البطاقة').first);
    await tester.pumpAndSettle();
    await addText('وجه محفوظ بعد إعادة التشغيل');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الظهر').first);
    await tester.pumpAndSettle();
    await addText('ظهر محفوظ بعد إعادة التشغيل');
    await tester.tap(find.byTooltip('حفظ القالب').first);
    await tester.pumpAndSettle();
    expect(find.text('تم حفظ قالب الكارنيه'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await open();
    expect(find.text('Layers'), findsOneWidget);
    CardTemplate preview() => tester
        .widget<CardDesignerPreview>(find.byType(CardDesignerPreview).first)
        .template;
    expect(
      preview().fixedTexts.any((e) => e.text == 'وجه محفوظ بعد إعادة التشغيل'),
      isTrue,
    );
    await tester.tap(find.text('الظهر').first);
    await tester.pumpAndSettle();
    expect(
      preview().fixedTexts.any((e) => e.text == 'ظهر محفوظ بعد إعادة التشغيل'),
      isTrue,
    );
    // Some inspector controls update the active face directly. An incoming
    // settings event must still recognize and preserve that unsaved draft.
    final draftLabels = !preview().showLabels;
    await tester.scrollUntilVisible(
      find.text('إظهار عناوين الحقول افتراضيًا'),
      250,
      scrollable: find
          .descendant(
            of: find.widgetWithText(ListView, 'الأدوات').first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    tester
        .widget<SwitchListTile>(
          find
              .widgetWithText(SwitchListTile, 'إظهار عناوين الحقول افتراضيًا')
              .first,
        )
        .onChanged!(draftLabels);
    await tester.pumpAndSettle();
    await SettingsRepository(db).saveSetting('id_card_cols', '3');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
    expect(preview().showLabels, draftLabels);
    expect(
      find.text('توجد إعدادات كارنيه أحدث؛ مسودتك محفوظة أمامك.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('a saved template cannot inherit a deleted legacy background', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = SettingsRepository(db);
    await repo.saveActiveCardTemplate(design('بلا خلفية'));
    await repo.saveSetting('id_card_background', 'AQID');
    await repo.saveSetting('id_card_designer_mode', 'true');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWith(_Auth.new),
        ],
        child: const MaterialApp(home: IdCardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CardDesignerPreview>(find.byType(CardDesignerPreview).first)
          .template
          .backgroundImageBase64,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
