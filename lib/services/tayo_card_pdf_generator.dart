import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import '../repositories/tayo_repository.dart';

class TayoCardPdfGenerator {
  static Future<Uint8List> generateCards({
    required List<TayoCardDTO> cards,
    required String codeType, // 'qr' or 'barcode'
    required int cardsPerRow,
    required int cardsPerCol,
    bool printBackSide = false,
    Uint8List? backLogoBytes,
    String backTopText = '',
    String backBottomText = '',
  }) async {
    final pdf = pw.Document();

    final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);

    const accentGold = PdfColor.fromInt(0xFFB8860B);
    const accentNavy = PdfColor.fromInt(0xFF1A237E);
    const lightBg = PdfColor.fromInt(0xFFFAFAFA);
    const accentTeal = PdfColor.fromInt(0xFF00695C);

    const double pageMargin = 10 * PdfPageFormat.mm;
    const double cardGapH = 4 * PdfPageFormat.mm;
    const double cardGapV = 4 * PdfPageFormat.mm;

    final double usableWidth = PdfPageFormat.a4.width - (pageMargin * 2);
    final double usableHeight = PdfPageFormat.a4.height - (pageMargin * 2);

    final double totalHGaps = cardGapH * (cardsPerRow - 1);
    final double totalVGaps = cardGapV * (cardsPerCol - 1);

    final double cardWidth = (usableWidth - totalHGaps) / cardsPerRow;
    final double cardHeight = (usableHeight - totalVGaps) / cardsPerCol;

    final maxCardsPerPage = cardsPerRow * cardsPerCol;

    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    for (int i = 0; i < cards.length; i += maxCardsPerPage) {
      final pageCards = cards.skip(i).take(maxCardsPerPage).toList();

      // --- Front Page ---
      final List<pw.Widget> frontRows = [];
      for (int row = 0; row < cardsPerCol; row++) {
        final List<pw.Widget> rowCards = [];
        for (int col = 0; col < cardsPerRow; col++) {
          final idx = row * cardsPerRow + col;
          if (idx < pageCards.length) {
            rowCards.add(
              pw.SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildCard(
                  card: pageCards[idx],
                  codeType: codeType,
                  width: cardWidth,
                  height: cardHeight,
                  regularFont: regularFont,
                  boldFont: boldFont,
                  accentGold: accentGold,
                  accentNavy: accentNavy,
                  accentTeal: accentTeal,
                  lightBg: lightBg,
                ),
              ),
            );
          } else {
            rowCards.add(pw.SizedBox(width: cardWidth, height: cardHeight));
          }
          if (col < cardsPerRow - 1) rowCards.add(pw.SizedBox(width: cardGapH));
        }
        frontRows.add(
          pw.Row(
            children: rowCards,
            mainAxisAlignment: pw.MainAxisAlignment.start,
          ),
        );
        if (row < cardsPerCol - 1) frontRows.add(pw.SizedBox(height: cardGapV));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(pageMargin),
          textDirection: pw.TextDirection.rtl,
          theme: theme,
          build: (context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: frontRows,
            );
          },
        ),
      );

      // --- Back Page (if enabled) ---
      if (printBackSide) {
        final List<pw.Widget> backRows = [];
        for (int row = 0; row < cardsPerCol; row++) {
          final List<pw.Widget> rowCards = [];
          for (int col = 0; col < cardsPerRow; col++) {
            // For correct duplex alignment, we mirror ONLY the list index Access,
            // but keep the physical layout (row/col) consistent with the front.
            // Alignment fix: reverse col index for index calculation
            final mirroredCol = (cardsPerRow - 1) - col;
            final idx = row * cardsPerRow + mirroredCol;

            if (idx < pageCards.length) {
              rowCards.add(
                pw.SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildBackCard(
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
                  ),
                ),
              );
            } else {
              rowCards.add(pw.SizedBox(width: cardWidth, height: cardHeight));
            }
            if (col < cardsPerRow - 1)
              rowCards.add(pw.SizedBox(width: cardGapH));
          }
          backRows.add(
            pw.Row(
              children: rowCards,
              mainAxisAlignment: pw.MainAxisAlignment.start,
            ),
          );
          if (row < cardsPerCol - 1)
            backRows.add(pw.SizedBox(height: cardGapV));
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(pageMargin),
            textDirection: pw.TextDirection.rtl,
            theme: theme,
            build: (context) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: backRows,
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  static pw.Widget _buildCard({
    required TayoCardDTO card,
    required String codeType,
    required double width,
    required double height,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor accentGold,
    required PdfColor accentNavy,
    required PdfColor accentTeal,
    required PdfColor lightBg,
  }) {
    // Image widget
    pw.Widget? imageWidget;
    if (card.cardImage != null && card.cardImage!.isNotEmpty) {
      final img = pw.MemoryImage(Uint8List.fromList(card.cardImage!));
      imageWidget = pw.Container(
        width: 55,
        height: 55,
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: accentGold, width: 1.5),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(img, fit: pw.BoxFit.cover),
        ),
      );
    }

    // Code widget
    pw.Widget codeWidget;
    final codeData = card.cardId.toString();
    if (codeType == 'qr') {
      codeWidget = pw.BarcodeWidget(
        barcode: Barcode.qrCode(),
        data: codeData,
        width: 45,
        height: 45,
        drawText: false,
      );
    } else {
      codeWidget = pw.BarcodeWidget(
        barcode: Barcode.code128(),
        data: codeData,
        width: width * 0.75,
        height: 35,
        drawText: false,
      );
    }

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: accentNavy, width: 1.5),
      ),
      child: pw.Column(
        children: [
          // Top accent bar
          pw.Container(
            width: width,
            height: 6,
            decoration: pw.BoxDecoration(
              color: accentTeal,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(9),
                topRight: pw.Radius.circular(9),
              ),
            ),
          ),
          // Card Name (top)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text(
              card.cardName,
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
              maxLines: 2,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                color: accentNavy,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          // Image
          pw.Expanded(
            child: imageWidget == null
                ? pw.SizedBox.shrink()
                : pw.Center(child: imageWidget),
          ),
          // Points
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: pw.BoxDecoration(
              color: accentGold,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              '${card.cardPoints} نقطة',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          // Barcode/QR Section
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6, left: 8, right: 8),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Center(child: codeWidget),
                pw.SizedBox(height: 2),
                pw.Text(
                  'كود: ${card.cardId}',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: accentNavy,
                  ),
                ),
              ],
            ),
          ),
          // Bottom accent bar
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
      ),
    );
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
  }) {
    // Logo Widget
    pw.Widget? logoWidget;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final image = pw.MemoryImage(logoBytes);
      logoWidget = pw.Container(
        width: 60,
        height: 60,
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

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: accentNavy, width: 1.5),
      ),
      child: pw.Column(
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
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (topText.isNotEmpty)
                    pw.Text(
                      topText,
                      maxLines: 2,
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
                      maxLines: 2,
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
      ),
    );
  }
}
