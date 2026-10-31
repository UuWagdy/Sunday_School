import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/services/designer_card_print_service.dart';
import 'package:petros_pols_flutter/services/pdf_generation_task.dart';
import 'package:petros_pols_flutter/widgets/card_designer_preview.dart';

final person = PersonListDTO(
  id: 2086,
  name: 'أوديليا باسم زكريا رياض',
  stageName: 'أولى ابتدائي',
  khorosName: 'خورس أ',
  areaName: 'المنطقة الأولى',
  phone: '01234567890',
  mobile: '',
  streetName: 'عنوان تجريبي طويل لاختبار التفاف النص والمسافات',
  fatherName: 'أب الاعتراف',
);

Future<Uint8List> rawPng(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  try {
    return (await frame.image.toByteData())!.buffer.asUint8List();
  } finally {
    frame.image.dispose();
    codec.dispose();
  }
}

void main() {
  test('designer layout keeps millimetres and reduces an oversized grid', () {
    final layout = DesignerCardPageLayout(CardTemplate.defaults(), 2, 5);
    expect(layout.width / (72 / 25.4), closeTo(86, 0.0001));
    expect(layout.height / (72 / 25.4), closeTo(54, 0.0001));
    expect(layout.columns, 2);
    expect(layout.rows, 4);
    expect(layout.capacity, 8);
    final one = DesignerCardPageLayout(CardTemplate.defaults(), 1, 1);
    expect(one.width, layout.width);
    expect(one.height, layout.height);
  });

  for (final fit in CardBackgroundFit.values) {
    testWidgets(
      'printed pixels match the designer including Arabic and ${fit.name} images',
      (tester) async {
        final font = FontLoader('CardTestArabic')
          ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
        await font.load();
        late Uint8List background;
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawColor(const Color(0xFFD7C39B), BlendMode.src);
          canvas.drawRect(
            const Rect.fromLTWH(12, 8, 90, 50),
            Paint()..color = const Color(0xFF993350),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(120, 80);
          background = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          image.dispose();
          picture.dispose();
        });
        final template = CardTemplate.defaults().copyWith(
          backgroundImageBase64: base64Encode(background),
          backgroundFit: fit,
          backgroundOpacity: 0.6,
          fixedTexts: const [
            CardFixedTextElement(
              text: 'خدمة الشمامسة',
              x: 0.1,
              y: 0.02,
              width: 0.6,
              height: 0.1,
              fontSize: 25,
            ),
          ],
          imageElements: [
            CardImageElement(
              imageBase64: base64Encode(background),
              x: 0.72,
              y: 0.04,
              width: 0.2,
              height: 0.18,
              opacity: 0.7,
            ),
          ],
        );
        final boundaryKey = GlobalKey();
        late BuildContext renderContext;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'CardTestArabic',
              ),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  renderContext = context;
                  return Center(
                    child: SizedBox(
                      width: 400,
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: CardDesignerPreview(
                          template: template,
                          person: person,
                          showTransparencyGrid: false,
                          decodedImages: {
                            'background': background,
                            'image:0': background,
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(MemoryImage(background), renderContext),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final shown = await boundary.toImage();
          final shownBytes = (await shown.toByteData())!.buffer.asUint8List();
          shown.dispose();
          final printed = await DesignerCardPrintService.renderCard(
            context: renderContext,
            template: template,
            person: person,
            logicalWidth: 400,
            dpi: 400 / template.width * 25.4,
          );
          expect(await rawPng(printed), orderedEquals(shownBytes));
          final artifact = Directory('build/card-print-verification')
            ..createSync(recursive: true);
          File(
            '${artifact.path}/designer-${fit.name}.png',
          ).writeAsBytesSync(printed);
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'designer PDF supports both sides, per-person codes and cancellation',
    (tester) async {
      final font = FontLoader('CardTestArabic')
        ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
      await font.load();
      late BuildContext renderContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'CardTestArabic'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                renderContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final template = CardTemplate.defaults();
      final updates = <int>[];
      await tester.runAsync(() async {
        final task = await DesignerCardPrintService.startGeneration(
          context: renderContext,
          persons: [
            person,
            PersonListDTO(
              id: 2092,
              name: 'يوساب وجدي',
              stageName: '',
              khorosName: '',
              areaName: '',
              phone: '',
              mobile: '',
              streetName: '',
              fatherName: '',
            ),
          ],
          template: template,
          backTemplate: template,
          cardsPerRow: 2,
          cardsPerCol: 5,
          isCancelled: () => false,
          onRendered: (current, total) => updates.add(current),
        );
        final bytes = await task.result;
        expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
        expect(updates, [1, 2]);
        File(
          'build/card-print-verification/designed-cards.pdf',
        ).writeAsBytesSync(bytes);
        final qr = await DesignerCardPrintService.renderCard(
          context: renderContext,
          template: template.copyWith(
            barcode: template.barcode.copyWith(type: CardCodeType.qr),
          ),
          person: person,
        );
        File('build/card-print-verification/qr-card.png').writeAsBytesSync(qr);
        await expectLater(
          DesignerCardPrintService.startGeneration(
            context: renderContext,
            persons: [person],
            template: template,
            cardsPerRow: 2,
            cardsPerCol: 5,
            isCancelled: () => true,
            onRendered: (_, __) {},
          ),
          throwsA(isA<PdfGenerationCancelledException>()),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
