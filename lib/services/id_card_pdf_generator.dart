import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import '../models/card_template.dart';
import '../repositories/persons_repository.dart';
import 'pdf_generation_task.dart';

class _IdCardPdfRequest {
  const _IdCardPdfRequest({
    required this.persons,
    required this.logoBytes,
    required this.visibleFields,
    required this.codeType,
    required this.showFieldLabels,
    required this.codeBackgroundMode,
    required this.cardsPerRow,
    required this.cardsPerCol,
    required this.printBackSide,
    required this.backLogoBytes,
    required this.backTopText,
    required this.backBottomText,
    required this.backgroundBytes,
    required this.backgroundOpacity,
    required this.backBackgroundBytes,
    required this.backBackgroundOpacity,
    required this.templateJson,
    required this.backTemplateJson,
    required this.regularBytes,
    required this.boldBytes,
  });

  final List<PersonListDTO> persons;
  final Uint8List? logoBytes;
  final Map<String, bool> visibleFields;
  final String codeType;
  final bool showFieldLabels;
  final CardBarcodeBackgroundMode codeBackgroundMode;
  final int cardsPerRow;
  final int cardsPerCol;
  final bool printBackSide;
  final Uint8List? backLogoBytes;
  final String backTopText;
  final String backBottomText;
  final Uint8List? backgroundBytes;
  final double backgroundOpacity;
  final Uint8List? backBackgroundBytes;
  final double backBackgroundOpacity;
  final String? templateJson;
  final String? backTemplateJson;
  final Uint8List regularBytes;
  final Uint8List boldBytes;
}

Future<void> _idCardPdfEntryPoint(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  final request = message[1] as _IdCardPdfRequest;
  try {
    final bytes = await IdCardPdfGenerator._buildCards(
      persons: request.persons,
      logoBytes: request.logoBytes,
      visibleFields: request.visibleFields,
      codeType: request.codeType,
      showFieldLabels: request.showFieldLabels,
      codeBackgroundMode: request.codeBackgroundMode,
      cardsPerRow: request.cardsPerRow,
      cardsPerCol: request.cardsPerCol,
      printBackSide: request.printBackSide,
      backLogoBytes: request.backLogoBytes,
      backTopText: request.backTopText,
      backBottomText: request.backBottomText,
      backgroundBytes: request.backgroundBytes,
      backgroundOpacity: request.backgroundOpacity,
      backBackgroundBytes: request.backBackgroundBytes,
      backBackgroundOpacity: request.backBackgroundOpacity,
      template: request.templateJson == null
          ? null
          : CardTemplate.fromJsonString(request.templateJson!),
      backTemplate: request.backTemplateJson == null
          ? null
          : CardTemplate.fromJsonString(request.backTemplateJson!),
      regularBytes: request.regularBytes,
      boldBytes: request.boldBytes,
      reporter: reporter,
    );
    reporter.complete(bytes);
  } catch (error, stackTrace) {
    reporter.fail(error, stackTrace);
  }
}

class IdCardPdfGenerator {
  static Future<Uint8List> generateCards({
    required List<PersonListDTO> persons,
    Uint8List? logoBytes,
    required Map<String, bool> visibleFields,
    required String codeType,
    bool showFieldLabels = true,
    CardBarcodeBackgroundMode codeBackgroundMode =
        CardBarcodeBackgroundMode.white,
    required int cardsPerRow,
    required int cardsPerCol,
    bool printBackSide = false,
    Uint8List? backLogoBytes,
    String backTopText = '',
    String backBottomText = '',
    Uint8List? backgroundBytes,
    double backgroundOpacity = 0.15,
    Uint8List? backBackgroundBytes,
    double backBackgroundOpacity = 0.15,
    CardTemplate? template,
    CardTemplate? backTemplate,
  }) async {
    final task = await startCardGeneration(
      persons: persons,
      logoBytes: logoBytes,
      visibleFields: visibleFields,
      codeType: codeType,
      showFieldLabels: showFieldLabels,
      codeBackgroundMode: codeBackgroundMode,
      cardsPerRow: cardsPerRow,
      cardsPerCol: cardsPerCol,
      printBackSide: printBackSide,
      backLogoBytes: backLogoBytes,
      backTopText: backTopText,
      backBottomText: backBottomText,
      backgroundBytes: backgroundBytes,
      backgroundOpacity: backgroundOpacity,
      backBackgroundBytes: backBackgroundBytes,
      backBackgroundOpacity: backBackgroundOpacity,
      template: template,
      backTemplate: backTemplate,
    );
    return task.result;
  }

  static Future<PdfGenerationTask> startCardGeneration({
    required List<PersonListDTO> persons,
    Uint8List? logoBytes,
    required Map<String, bool> visibleFields,
    required String codeType,
    bool showFieldLabels = true,
    CardBarcodeBackgroundMode codeBackgroundMode =
        CardBarcodeBackgroundMode.white,
    required int cardsPerRow,
    required int cardsPerCol,
    bool printBackSide = false,
    Uint8List? backLogoBytes,
    String backTopText = '',
    String backBottomText = '',
    Uint8List? backgroundBytes,
    double backgroundOpacity = 0.15,
    Uint8List? backBackgroundBytes,
    double backBackgroundOpacity = 0.15,
    CardTemplate? template,
    CardTemplate? backTemplate,
  }) async {
    final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularBytes = regularData.buffer.asUint8List(
      regularData.offsetInBytes,
      regularData.lengthInBytes,
    );
    final boldBytes = boldData.buffer.asUint8List(
      boldData.offsetInBytes,
      boldData.lengthInBytes,
    );

    return PdfGenerationTask.start(
      _idCardPdfEntryPoint,
      _IdCardPdfRequest(
        persons: persons,
        logoBytes: logoBytes,
        visibleFields: visibleFields,
        codeType: codeType,
        showFieldLabels: showFieldLabels,
        codeBackgroundMode: codeBackgroundMode,
        cardsPerRow: cardsPerRow,
        cardsPerCol: cardsPerCol,
        printBackSide: printBackSide,
        backLogoBytes: backLogoBytes,
        backTopText: backTopText,
        backBottomText: backBottomText,
        backgroundBytes: backgroundBytes,
        backgroundOpacity: backgroundOpacity,
        backBackgroundBytes: backBackgroundBytes,
        backBackgroundOpacity: backBackgroundOpacity,
        templateJson: template?.toJsonString(),
        backTemplateJson: backTemplate?.toJsonString(),
        regularBytes: regularBytes,
        boldBytes: boldBytes,
      ),
    );
  }

  static Future<Uint8List> _buildCards({
    required List<PersonListDTO> persons,
    Uint8List? logoBytes,
    required Map<String, bool> visibleFields,
    required String codeType,
    required bool showFieldLabels,
    required CardBarcodeBackgroundMode codeBackgroundMode,
    required int cardsPerRow,
    required int cardsPerCol,
    required bool printBackSide,
    Uint8List? backLogoBytes,
    required String backTopText,
    required String backBottomText,
    Uint8List? backgroundBytes,
    required double backgroundOpacity,
    Uint8List? backBackgroundBytes,
    required double backBackgroundOpacity,
    CardTemplate? template,
    CardTemplate? backTemplate,
    required Uint8List regularBytes,
    required Uint8List boldBytes,
    required PdfGenerationReporter reporter,
  }) async {
    final pdf = pw.Document();

    final regularFont = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final boldFont = pw.Font.ttf(ByteData.sublistView(boldBytes));

    // Premium accent colors
    const accentGold = PdfColor.fromInt(0xFFB8860B); // Dark goldenrod
    const accentNavy = PdfColor.fromInt(0xFF1A237E); // Deep navy
    const lightBg = PdfColor.fromInt(0xFFFAFAFA); // Off-white card bg
    const subtleGrey = PdfColor.fromInt(0xFF757575); // Muted grey

    // Layout constants
    const double pageMargin = 10 * PdfPageFormat.mm; // هامش الصفحة الخارجي
    const double cardGapH =
        4 * PdfPageFormat.mm; // المسافة الأفقية بين الكارنيهات
    const double cardGapV =
        4 * PdfPageFormat.mm; // المسافة الرأسية بين الكارنيهات

    // Calculate usable area
    final double usableWidth = PdfPageFormat.a4.width - (pageMargin * 2);
    final double usableHeight = PdfPageFormat.a4.height - (pageMargin * 2);

    final safeCardsPerRow = cardsPerRow.clamp(1, 10).toInt();
    final safeCardsPerCol = cardsPerCol.clamp(1, 20).toInt();
    final double totalHGaps = cardGapH * (safeCardsPerRow - 1);
    final double totalVGaps = cardGapV * (safeCardsPerCol - 1);

    final double cardWidth = (usableWidth - totalHGaps) / safeCardsPerRow;
    final double cardHeight = (usableHeight - totalVGaps) / safeCardsPerCol;
    final maxCardsPerPage = safeCardsPerRow * safeCardsPerCol;
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    for (int i = 0; i < persons.length; i += maxCardsPerPage) {
      final pagePersons = persons.skip(i).take(maxCardsPerPage).toList();
      final frontRows = <pw.Widget>[];

      for (int row = 0; row < safeCardsPerCol; row++) {
        final rowCards = <pw.Widget>[];
        for (int col = 0; col < safeCardsPerRow; col++) {
          final idx = row * safeCardsPerRow + col;
          final personNumber = i + idx + 1;
          rowCards.add(
            pw.SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: idx < pagePersons.length
                  ? PdfProgressMarker(
                      child: _buildCard(
                        person: pagePersons[idx],
                        logoBytes: logoBytes,
                        visibleFields: visibleFields,
                        codeType: codeType,
                        showFieldLabels: showFieldLabels,
                        codeBackgroundMode: codeBackgroundMode,
                        width: cardWidth,
                        height: cardHeight,
                        regularFont: regularFont,
                        boldFont: boldFont,
                        accentGold: accentGold,
                        accentNavy: accentNavy,
                        lightBg: lightBg,
                        subtleGrey: subtleGrey,
                        backgroundBytes: backgroundBytes,
                        backgroundOpacity: backgroundOpacity,
                        template: template,
                      ),
                      onPaint: () => reporter.update(
                        personNumber,
                        persons.length,
                        'جاري رسم الكارنيهات داخل ملف PDF...',
                      ),
                    )
                  : null,
            ),
          );
          if (col < safeCardsPerRow - 1) {
            rowCards.add(pw.SizedBox(width: cardGapH));
          }
        }
        frontRows.add(pw.Row(children: rowCards));
        if (row < safeCardsPerCol - 1) {
          frontRows.add(pw.SizedBox(height: cardGapV));
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(pageMargin),
          textDirection: pw.TextDirection.rtl,
          theme: theme,
          build: (_) => pw.Column(children: frontRows),
        ),
      );

      if (!printBackSide) continue;

      final backRows = <pw.Widget>[];
      for (int row = 0; row < safeCardsPerCol; row++) {
        final rowCards = <pw.Widget>[];
        for (int col = 0; col < safeCardsPerRow; col++) {
          // Reverse columns so front and back align during duplex printing.
          final reversedCol = (safeCardsPerRow - 1) - col;
          final idx = row * safeCardsPerRow + reversedCol;
          rowCards.add(
            pw.SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: idx < pagePersons.length
                  ? backTemplate != null
                        ? _buildTemplateCard(
                            person: pagePersons[idx],
                            template: backTemplate,
                            width: cardWidth,
                            height: cardHeight,
                            regularFont: regularFont,
                            boldFont: boldFont,
                            accentNavy: accentNavy,
                            lightBg: lightBg,
                          )
                        : _buildBackCard(
                            width: cardWidth,
                            height: cardHeight,
                            logoBytes: backLogoBytes,
                            topText: backTopText,
                            bottomText: backBottomText,
                            regularFont: regularFont,
                            boldFont: boldFont,
                            accentGold: accentGold,
                            accentNavy: accentNavy,
                            lightBg: lightBg,
                            backgroundBytes: backBackgroundBytes,
                            backgroundOpacity: backBackgroundOpacity,
                          )
                  : null,
            ),
          );
          if (col < safeCardsPerRow - 1) {
            rowCards.add(pw.SizedBox(width: cardGapH));
          }
        }
        backRows.add(pw.Row(children: rowCards));
        if (row < safeCardsPerCol - 1) {
          backRows.add(pw.SizedBox(height: cardGapV));
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(pageMargin),
          textDirection: pw.TextDirection.rtl,
          theme: theme,
          build: (_) => pw.Column(children: backRows),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildCard({
    required PersonListDTO person,
    Uint8List? logoBytes,
    required Map<String, bool> visibleFields,
    required String codeType,
    required bool showFieldLabels,
    required CardBarcodeBackgroundMode codeBackgroundMode,
    required double width,
    required double height,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor accentGold,
    required PdfColor accentNavy,
    required PdfColor lightBg,
    required PdfColor subtleGrey,
    Uint8List? backgroundBytes,
    required double backgroundOpacity,
    CardTemplate? template,
  }) {
    if (template != null) {
      return _buildTemplateCard(
        person: person,
        template: template,
        width: width,
        height: height,
        regularFont: regularFont,
        boldFont: boldFont,
        accentNavy: accentNavy,
        lightBg: lightBg,
      );
    }

    // Logo or Person Photo
    pw.Widget? logoOrPhotoWidget;

    if (visibleFields['photo'] == true && person.photo != null) {
      final image = pw.MemoryImage(person.photo!);
      logoOrPhotoWidget = pw.Container(
        width: 45,
        height: 60, // Slightly taller for portrait photos
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: accentGold, width: 1.5),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 5,
          verticalRadius: 5,
          child: pw.Image(image, fit: pw.BoxFit.cover),
        ),
      );
    } else if (logoBytes != null) {
      final image = pw.MemoryImage(logoBytes);
      logoOrPhotoWidget = pw.Container(
        width: 45,
        height: 45,
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: accentGold, width: 1.5),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      );
    }

    // Build info rows
    final infoRows = <pw.Widget>[];

    if (visibleFields['name'] == true) {
      infoRows.add(
        showFieldLabels
            ? _buildLabelValue(
                'الاسم',
                person.name,
                regularFont,
                boldFont,
                accentNavy,
                subtleGrey,
                showLabel: true,
                valueFontSize: 11,
              )
            : _buildInfoLine(
                person.name,
                accentNavy,
                boldFont,
                11,
                isTitle: true,
              ),
      );
    }
    if (visibleFields['code'] == true) {
      infoRows.add(
        _buildLabelValue(
          'الكود',
          person.id.toString(),
          regularFont,
          boldFont,
          accentGold,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['stage'] == true && person.stageName.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'المرحلة',
          person.stageName,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['khoros'] == true && person.khorosName.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'الخورس',
          person.khorosName,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['area'] == true && person.areaName.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'المنطقة',
          person.areaName,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['father'] == true && person.fatherName.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'أب الاعتراف',
          person.fatherName,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['phone'] == true && person.phone.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'تليفون',
          person.phone,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['mobile'] == true && person.mobile.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'موبايل',
          person.mobile,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['street'] == true && person.streetName.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'العنوان',
          person.streetName,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }
    if (visibleFields['rohot'] == true && person.rohot != null && person.rohot!.isNotEmpty) {
      infoRows.add(
        _buildLabelValue(
          'الرهط',
          person.rohot!,
          regularFont,
          boldFont,
          accentNavy,
          subtleGrey,
          showLabel: showFieldLabels,
        ),
      );
    }

    // Barcode at bottom
    pw.Widget codeWidget;
    final codeData = person.id.toString();
    if (codeType == 'qr') {
      codeWidget = pw.BarcodeWidget(
        barcode: Barcode.qrCode(),
        data: codeData,
        width: 50,
        height: 50,
      );
    } else {
      codeWidget = pw.BarcodeWidget(
        barcode: Barcode.code128(),
        data: codeData,
        width: width * 0.8,
        height: 35,
        drawText: false,
      );
    }
    if (codeBackgroundMode == CardBarcodeBackgroundMode.white) {
      codeWidget = pw.Container(
        color: PdfColors.white,
        padding: const pw.EdgeInsets.all(3),
        child: codeWidget,
      );
    }

    final cardContent = pw.Column(
      children: [
        // ── Top accent bar ──
        pw.Container(
          width: width,
          height: 6,
          decoration: pw.BoxDecoration(
            color: accentNavy,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(9),
              topRight: pw.Radius.circular(9),
            ),
          ),
        ),
        // ── Card body ──
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoOrPhotoWidget != null) ...[
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [logoOrPhotoWidget],
                  ),
                  pw.SizedBox(width: 8),
                ],
                // Left: Info column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: infoRows,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Divider line ──
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
          height: 0.5,
          color: PdfColors.grey300,
        ),
        // ── Bottom barcode section ──
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Center(child: codeWidget),
        ),
        // ── Bottom accent bar ──
        pw.Container(
          width: width,
          height: 4,
          decoration: pw.BoxDecoration(
            color: accentGold,
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(9),
              bottomRight: pw.Radius.circular(9),
            ),
          ),
        ),
      ],
    );

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: accentNavy, width: 1.5),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 9,
        verticalRadius: 9,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            if (backgroundBytes != null)
              pw.Opacity(
                opacity: backgroundOpacity.clamp(0, 1).toDouble(),
                child: pw.Image(
                  pw.MemoryImage(backgroundBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            cardContent,
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplateCard({
    required PersonListDTO person,
    required CardTemplate template,
    required double width,
    required double height,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor accentNavy,
    required PdfColor lightBg,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: template.transparentBackground ? null : lightBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: accentNavy, width: 1.2),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 9,
        verticalRadius: 9,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            if (template.backgroundImageBytes != null)
              pw.Opacity(
                opacity: template.backgroundOpacity.clamp(0, 1).toDouble(),
                child: pw.Image(
                  pw.MemoryImage(template.backgroundImageBytes!),
                  fit: _pdfFit(template.backgroundFit),
                ),
              ),
            for (final layerId in template.normalizedLayerOrder)
              _buildTemplateLayer(
                layerId: layerId,
                person: person,
                template: template,
                width: width,
                height: height,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTemplateLayer({
    required String layerId,
    required PersonListDTO person,
    required CardTemplate template,
    required double width,
    required double height,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    if (layerId == 'barcode') {
      if (!template.barcode.visible) return pw.SizedBox.shrink();
      return _buildTemplateBarcode(person, template.barcode, width, height);
    }
    final parts = layerId.split(':');
    if (parts.length != 2) return pw.SizedBox.shrink();
    final index = int.tryParse(parts[1]);
    if (index == null) return pw.SizedBox.shrink();

    if (parts.first == 'image' &&
        index >= 0 &&
        index < template.imageElements.length) {
      final image = template.imageElements[index];
      if (!image.visible) return pw.SizedBox.shrink();
      if (image.imageBytes == null) return pw.SizedBox.shrink();
      return _positioned(
        image.x,
        image.y,
        image.width,
        image.height,
        width,
        height,
        pw.Opacity(
          opacity: image.opacity.clamp(0, 1).toDouble(),
          child: pw.Image(
            pw.MemoryImage(image.imageBytes!),
            fit: _pdfFit(image.fit),
          ),
        ),
      );
    }
    if (parts.first == 'field' &&
        index >= 0 &&
        index < template.fields.length &&
        template.fields[index].visible) {
      return _buildTemplateField(
        person: person,
        field: template.fields[index],
        template: template,
        cardWidth: width,
        cardHeight: height,
        regularFont: regularFont,
        boldFont: boldFont,
      );
    }
    if (parts.first == 'fixed' &&
        index >= 0 &&
        index < template.fixedTexts.length) {
      final fixedText = template.fixedTexts[index];
      if (!fixedText.visible) return pw.SizedBox.shrink();
      return _positioned(
        fixedText.x,
        fixedText.y,
        fixedText.width,
        fixedText.height,
        width,
        height,
        pw.Text(
          fixedText.text,
          textDirection: pw.TextDirection.rtl,
          textAlign: _pdfTextAlign(fixedText.textAlign),
          maxLines: 2,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: _scaledTemplateFontSize(fixedText.fontSize, width),
            color: PdfColor.fromInt(fixedText.color),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }
    return pw.SizedBox.shrink();
  }

  static pw.Widget _buildTemplateField({
    required PersonListDTO person,
    required CardDataFieldElement field,
    required CardTemplate template,
    required double cardWidth,
    required double cardHeight,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    if (field.fieldKey == CardFieldKeys.photo) {
      if (person.photo == null) {
        return pw.SizedBox.shrink();
      }
      return _positioned(
        field.x,
        field.y,
        field.width,
        field.height,
        cardWidth,
        cardHeight,
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Image(
              pw.MemoryImage(person.photo!),
              fit: pw.BoxFit.cover,
            ),
          ),
        ),
      );
    }

    final label = CardFieldKeys.arabicLabel(field.fieldKey);
    final value = CardFieldKeys.valueFor(person, field.fieldKey);
    final text = field.shouldShowLabel(template.showLabels)
        ? '$label: $value'
        : value;
    return _positioned(
      field.x,
      field.y,
      field.width,
      field.height,
      cardWidth,
      cardHeight,
      pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: _pdfTextAlign(field.textAlign),
        maxLines: 2,
        style: pw.TextStyle(
          font: field.fieldKey == CardFieldKeys.name ? boldFont : regularFont,
          fontSize: _scaledTemplateFontSize(field.fontSize, cardWidth),
          color: PdfColor.fromInt(field.color),
          fontWeight: field.fieldKey == CardFieldKeys.name
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildTemplateBarcode(
    PersonListDTO person,
    CardBarcodeElement barcode,
    double cardWidth,
    double cardHeight,
  ) {
    final codeWidget = pw.BarcodeWidget(
      barcode: barcode.type == CardCodeType.qr
          ? Barcode.qrCode()
          : Barcode.code128(),
      data: person.id.toString(),
      width: barcode.width * cardWidth,
      height: barcode.height * cardHeight,
      drawText: false,
    );
    final content = barcode.backgroundMode == CardBarcodeBackgroundMode.white
        ? pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(2),
            child: codeWidget,
          )
        : codeWidget;
    return _positioned(
      barcode.x,
      barcode.y,
      barcode.width,
      barcode.height,
      cardWidth,
      cardHeight,
      content,
    );
  }

  static double _scaledTemplateFontSize(double fontSize, double cardWidth) {
    return fontSize * cardWidth / CardTemplate.fontReferenceWidth;
  }

  static pw.TextAlign _pdfTextAlign(CardTextAlign align) {
    return switch (align) {
      CardTextAlign.right => pw.TextAlign.right,
      CardTextAlign.center => pw.TextAlign.center,
      CardTextAlign.left => pw.TextAlign.left,
    };
  }

  static pw.Widget _positioned(
    double x,
    double y,
    double elementWidth,
    double elementHeight,
    double cardWidth,
    double cardHeight,
    pw.Widget child,
  ) {
    return pw.Positioned(
      left: x * cardWidth,
      top: y * cardHeight,
      child: pw.SizedBox(
        width: elementWidth * cardWidth,
        height: elementHeight * cardHeight,
        child: child,
      ),
    );
  }

  static pw.BoxFit _pdfFit(CardBackgroundFit fit) {
    return switch (fit) {
      CardBackgroundFit.shrinkToFit => pw.BoxFit.contain,
      CardBackgroundFit.zoomToFit => pw.BoxFit.cover,
      CardBackgroundFit.actualSize => pw.BoxFit.none,
    };
  }

  static pw.Widget _buildBackCard({
    required double width,
    required double height,
    Uint8List? logoBytes,
    required String topText,
    required String bottomText,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor accentGold,
    required PdfColor accentNavy,
    required PdfColor lightBg,
    Uint8List? backgroundBytes,
    required double backgroundOpacity,
  }) {
    pw.Widget? logoWidget;
    if (logoBytes != null) {
      final image = pw.MemoryImage(logoBytes);
      logoWidget = pw.Container(
        width: 80,
        height: 80,
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: accentGold, width: 2),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      );
    }

    final cardContent = pw.Column(
      children: [
        pw.Container(
          width: width,
          height: 6,
          decoration: pw.BoxDecoration(
            color: accentNavy,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(9),
              topRight: pw.Radius.circular(9),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (topText.isNotEmpty)
                  pw.Text(
                    topText,
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      color: accentNavy,
                    ),
                  ),
                if (logoWidget != null) logoWidget,
                if (bottomText.isNotEmpty)
                  pw.Text(
                    bottomText,
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
                  ),
              ],
            ),
          ),
        ),
        pw.Container(
          width: width,
          height: 4,
          decoration: pw.BoxDecoration(
            color: accentGold,
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(9),
              bottomRight: pw.Radius.circular(9),
            ),
          ),
        ),
      ],
    );

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: accentNavy, width: 1.5),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 9,
        verticalRadius: 9,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            if (backgroundBytes != null)
              pw.Opacity(
                opacity: backgroundOpacity.clamp(0, 1).toDouble(),
                child: pw.Image(
                  pw.MemoryImage(backgroundBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            cardContent,
          ],
        ),
      ),
    );
  }

  // Title name line
  static pw.Widget _buildInfoLine(
    String text,
    PdfColor color,
    pw.Font font,
    double size, {
    bool isTitle = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: size,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Label: Value row
  static pw.Widget _buildLabelValue(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
    PdfColor valueColor,
    PdfColor labelColor, {
    bool showLabel = true,
    double valueFontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (showLabel)
            pw.Text(
              '$label: ',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8,
                color: labelColor,
              ),
            ),
          pw.Text(
            value,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: valueFontSize,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
