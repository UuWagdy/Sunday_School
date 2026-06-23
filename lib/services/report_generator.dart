import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pdf_export_options.dart';
import '../repositories/reports_repository.dart';

/// Generates PDF documents for various reports.
class ReportGenerator {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;

  /// Load the Arabic font from assets. Must be called before generating any report.
  static Future<void> loadFonts() async {
    if (_arabicFont != null) return;
    final fontData = await rootBundle.load('assets/fonts/arial.ttf');
    _arabicFont = pw.Font.ttf(fontData);
    _arabicBoldFont = pw.Font.ttf(fontData); // same font for bold
  }

  static pw.TextStyle _baseStyle({double fontSize = 10, pw.FontWeight? fontWeight}) {
    return pw.TextStyle(
      font: _arabicFont,
      fontBold: _arabicBoldFont,
      fontFallback: _arabicFont != null ? [_arabicFont!] : [],
      fontSize: fontSize,
      fontWeight: fontWeight ?? pw.FontWeight.normal,
    );
  }

  /// Generates a Persons List report.
  static pw.Document generatePersonsReport(
    List<PersonReportDTO> persons, {
    String? filterLabel,
    Map<String, String>? dynamicLabels,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) {
    final pdf = pw.Document();
    const columnCount = 7;
    final tableFontSize = exportOptions.fittedFontSize(
      columnCount,
      baseSize: 9,
      comfortableColumnCount: 7,
    );
    
    String getL(String key, String fallback) => dynamicLabels?[key] ?? fallback;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: exportOptions.pageFormatForColumnCount(columnCount),
        textDirection: pw.TextDirection.rtl,
        maxPages: 500,
        theme: pw.ThemeData.withFont(
          base: _arabicFont,
          bold: _arabicBoldFont,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير الأشخاص${filterLabel != null ? " - $filterLabel" : ""}',
              style: _baseStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('إجمالى عدد الأشخاص: ${persons.length}',
              style: _baseStyle(),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerDirection: pw.TextDirection.rtl,
            cellStyle: _baseStyle(fontSize: tableFontSize),
            headerStyle: _baseStyle(fontSize: tableFontSize + 1, fontWeight: pw.FontWeight.bold),
            headers: [
              'م', 
              'الإسم', 
              getL('stage', 'المرحلة'), 
              getL('area', 'المنطقة'), 
              getL('street', 'الشارع'), 
              getL('phone', 'التليفون'), 
              getL('mobile', 'الموبايل')
            ],
            data: List.generate(persons.length, (i) {
              final p = persons[i];
              return [
                '${i + 1}',
                p.personName ?? '',
                p.stageName ?? '',
                p.areaName ?? '',
                p.streetName ?? '',
                p.phone ?? '',
                p.mobile ?? '',
              ];
            }),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// Generates an Attendance report.
  static pw.Document generateAttendanceReport(
    List<AttendanceReportDTO> records, {
    String? filterLabel,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) {
    final pdf = pw.Document();
    const columnCount = 7;
    final tableFontSize = exportOptions.fittedFontSize(
      columnCount,
      baseSize: 9,
      comfortableColumnCount: 7,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: exportOptions.pageFormatForColumnCount(columnCount),
        textDirection: pw.TextDirection.rtl,
        maxPages: 500,
        theme: pw.ThemeData.withFont(
          base: _arabicFont,
          bold: _arabicBoldFont,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير الحضور${filterLabel != null ? " - $filterLabel" : ""}',
              style: _baseStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('إجمالى السجلات: ${records.length}',
              style: _baseStyle(),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerDirection: pw.TextDirection.rtl,
            cellStyle: _baseStyle(fontSize: tableFontSize),
            headerStyle: _baseStyle(fontSize: tableFontSize + 1, fontWeight: pw.FontWeight.bold),
            headers: ['م', 'الإسم', 'التاريخ', 'النقاط', 'الشهر', 'السنة', 'السلوك'],
            data: List.generate(records.length, (i) {
              final r = records[i];
              return [
                '${i + 1}',
                r.personName ?? '',
                r.dateWeek ?? '',
                '${r.point ?? 0}',
                '${r.month ?? ""}',
                '${r.year ?? ""}',
                '${r.behavior ?? 5}',
              ];
            }),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// Generates a Stage Statistics report.
  static pw.Document generateStatisticsReport(
    List<StageStatDTO> stats, {
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) {
    final pdf = pw.Document();
    final totalCount = stats.fold<int>(0, (sum, s) => sum + s.count);
    const columnCount = 3;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: exportOptions.pageFormatForColumnCount(columnCount),
        textDirection: pw.TextDirection.rtl,
        maxPages: 500,
        theme: pw.ThemeData.withFont(
          base: _arabicFont,
          bold: _arabicBoldFont,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير إحصائيات المراحل',
              style: _baseStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('إجمالى عدد الأشخاص: $totalCount',
              style: _baseStyle(),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerDirection: pw.TextDirection.rtl,
            cellStyle: _baseStyle(fontSize: 9),
            headerStyle: _baseStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            headers: ['م', 'المرحلة', 'عدد الأشخاص'],
            data: List.generate(stats.length, (i) {
              final s = stats[i];
              return [
                '${i + 1}',
                s.stageName ?? 'غير محدد',
                '${s.count}',
              ];
            }),
          ),
        ],
      ),
    );
    return pdf;
  }
}
