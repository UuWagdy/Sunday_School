import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/repositories/settings_repository.dart';

void main() {
  test('default template includes khoros and legacy card fields', () {
    final template = CardTemplate.defaults();

    expect(
      template.fields.map((field) => field.fieldKey),
      contains(CardFieldKeys.khoros),
    );
    expect(
      template.fields.map((field) => field.fieldKey),
      contains(CardFieldKeys.name),
    );
    expect(
      template.fields.map((field) => field.fieldKey),
      contains(CardFieldKeys.photo),
    );
    expect(template.validate(), isEmpty);
  });

  test('serializes and parses active template settings data', () {
    final template = CardTemplate.defaults().copyWith(
      showLabels: false,
      backgroundFit: CardBackgroundFit.zoomToFit,
      fixedTexts: const [
        CardFixedTextElement(
          text: 'خدمة ابتدائي',
          x: 0.1,
          y: 0.1,
          width: 0.5,
          height: 0.1,
          color: 0xFF1A237E,
        ),
      ],
    );

    final parsed = CardTemplate.fromJsonString(template.toJsonString());

    expect(parsed.showLabels, isFalse);
    expect(parsed.backgroundFit, CardBackgroundFit.zoomToFit);
    expect(parsed.fixedTexts.single.text, 'خدمة ابتدائي');
    expect(parsed.fixedTexts.single.color, 0xFF1A237E);
  });

  test('serializes barcode options and image elements', () {
    final imageBytes = base64Encode([1, 2, 3, 4]);
    final template = CardTemplate.defaults().copyWith(
      barcode: const CardBarcodeElement(
        type: CardCodeType.qr,
        x: 0.40,
        y: 0.70,
        width: 0.18,
        height: 0.18,
        backgroundMode: CardBarcodeBackgroundMode.transparent,
      ),
      imageElements: [
        CardImageElement(
          imageBase64: imageBytes,
          x: 0.10,
          y: 0.10,
          width: 0.20,
          height: 0.20,
          opacity: 0.35,
          fit: CardBackgroundFit.zoomToFit,
        ),
      ],
    );

    final parsed = CardTemplate.fromJsonString(template.toJsonString());

    expect(parsed.barcode.type, CardCodeType.qr);
    expect(
      parsed.barcode.backgroundMode,
      CardBarcodeBackgroundMode.transparent,
    );
    expect(parsed.imageElements.single.fit, CardBackgroundFit.zoomToFit);
    expect(parsed.imageElements.single.opacity, 0.35);
    expect(parsed.imageElements.single.imageBytes, isNotNull);
  });

  test(
    'default designer barcode is smaller than legacy full-width barcode',
    () {
      final barcode = CardTemplate.defaults().barcode;

      expect(barcode.width, lessThan(0.8));
      expect(barcode.height, lessThan(0.20));
    },
  );

  test('falls back to default template when stored json is malformed', () {
    final parsed = CardTemplate.fromJsonString('{bad json');

    expect(
      parsed.fields.map((field) => field.fieldKey),
      contains(CardFieldKeys.name),
    );
    expect(parsed.backgroundFit, CardBackgroundFit.shrinkToFit);
  });

  test('validates text size and normalized element bounds', () {
    final template = CardTemplate(
      fields: const [
        CardDataFieldElement(
          fieldKey: CardFieldKeys.name,
          x: 0.90,
          y: 0.10,
          width: 0.30,
          height: 0.10,
          fontSize: 600,
        ),
      ],
    );

    final errors = template.validate();

    expect(errors, isNotEmpty);
    expect(errors.any((error) => error.contains('خارج حدود البطاقة')), isTrue);
    expect(errors.any((error) => error.contains('حجم خط')), isTrue);
  });

  test('validates empty fixed text', () {
    final template = CardTemplate.defaults().copyWith(
      fixedTexts: const [CardFixedTextElement(text: '   ', x: 0.1, y: 0.1)],
    );

    expect(
      template.validate().any((error) => error.contains('نص ثابت فارغ')),
      isTrue,
    );
  });

  test('validates barcode minimum size', () {
    final template = CardTemplate.defaults().copyWith(
      barcode: const CardBarcodeElement(
        type: CardCodeType.barcode,
        width: 0.10,
        height: 0.04,
      ),
    );

    expect(
      template.validate().any((error) => error.contains('الباركود صغير')),
      isTrue,
    );
  });

  test('settings repository persists active card template', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = SettingsRepository(db);
    final template = CardTemplate.defaults().copyWith(showLabels: false);

    await repository.saveActiveCardTemplate(template);

    expect((await repository.getActiveCardTemplate()).showLabels, isFalse);
  });

  test(
    'settings repository persists barcode and image element options',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = SettingsRepository(db);
      final template = CardTemplate.defaults().copyWith(
        barcode: const CardBarcodeElement(
          type: CardCodeType.qr,
          backgroundMode: CardBarcodeBackgroundMode.transparent,
          width: 0.18,
          height: 0.18,
        ),
        imageElements: [
          CardImageElement(
            imageBase64: base64Encode([1, 2, 3]),
            x: 0.2,
            y: 0.2,
            opacity: 0.5,
          ),
        ],
      );

      await repository.saveActiveCardTemplate(template);
      final reloaded = await repository.getActiveCardTemplate();

      expect(reloaded.barcode.type, CardCodeType.qr);
      expect(
        reloaded.barcode.backgroundMode,
        CardBarcodeBackgroundMode.transparent,
      );
      expect(reloaded.imageElements.single.imageBytes, isNotNull);
      expect(reloaded.imageElements.single.opacity, 0.5);
    },
  );

  test(
    'settings repository falls back when active card template is invalid',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = SettingsRepository(db);
      await repository.saveSetting(
        SettingsRepository.idCardActiveTemplateKey,
        '{bad json',
      );

      expect((await repository.getActiveCardTemplate()).fields, isNotEmpty);
    },
  );
}
