import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../repositories/tayo_repository.dart';

class TayoReportPdfGenerator {
  static Future<Uint8List> generateReport({
    required List<PersonPointsDTO> data,
    required String title,
    String? dateRange,
    required List<String> columns,
  }) async {
    final pdf = pw.Document();

    final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);

    const accentNavy = PdfColor.fromInt(0xFF1A237E);
    const accentGold = PdfColor.fromInt(0xFFB8860B);
    const headerBg = PdfColor.fromInt(0xFF1A237E);

    pdf.addPage(
      pw.MultiPage(
        maxPages: 2000,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                    color: accentNavy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (dateRange != null)
                  pw.Text(
                    dateRange,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(height: 2, color: accentGold),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey500),
          ),
        ),
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDirection: pw.TextDirection.rtl,
              tableDirection: pw.TextDirection.rtl,
              cellAlignment: pw.Alignment.center,
              headerDecoration: pw.BoxDecoration(color: headerBg),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
              cellAlignments: {
                for (var i = 0; i < columns.length; i++)
                  i: columns[i] == 'الاسم' ? pw.Alignment.centerRight : pw.Alignment.center,
              },
              columnWidths: {
                for (var i = 0; i < columns.length; i++)
                  if (columns[i] == '#')
                    i: const pw.FixedColumnWidth(40)
                  else if (columns[i] == 'الاسم')
                    i: const pw.FlexColumnWidth(3)
                  else
                    i: const pw.FlexColumnWidth(2),
              },
              headers: columns.reversed.toList(),
              data: List.generate(data.length, (i) {
                final d = data[i];
                final row = columns.map((col) {
                  switch (col) {
                    case '#': return '${i + 1}';
                    case 'الاسم': return d.personName;
                    case 'المرحلة': return d.stageName ?? '-';
                    case 'المنطقة': return d.areaName ?? '-';
                    case 'إجمالي النقاط': return d.totalPoints.toString();
                    case 'نقاط الطايو': return d.tayoPoints.toString();
                    case 'نقاط الحضور': return d.attendancePoints.toString();
                    default: return (d.cardPoints[col] ?? 0).toString();
                  }
                }).toList();
                return row.reversed.toList();
              }),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
