import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/pdf_export_options.dart';
import '../repositories/term_attendance_repository.dart';

class TermAttendancePdfService {
  static Uint8List? _cachedRegularFontBytes;
  static Uint8List? _cachedBoldFontBytes;

  static Future<Uint8List> _getRegularFontBytes() async {
    if (_cachedRegularFontBytes != null) return _cachedRegularFontBytes!;
    final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
    _cachedRegularFontBytes = fontData.buffer.asUint8List(
      fontData.offsetInBytes,
      fontData.lengthInBytes,
    );
    return _cachedRegularFontBytes!;
  }

  static Future<Uint8List> _getBoldFontBytes() async {
    if (_cachedBoldFontBytes != null) return _cachedBoldFontBytes!;
    final fontData = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
    _cachedBoldFontBytes = fontData.buffer.asUint8List(
      fontData.offsetInBytes,
      fontData.lengthInBytes,
    );
    return _cachedBoldFontBytes!;
  }

  static Future<void> exportReport(
    TermAttendanceReport report, {
    required bool includeKhorosName,
    required bool includeKhorosCode,
    required bool includeStageName,
    required bool includeStageCode,
    String? churchName,
    Uint8List? churchLogo,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();

    final pdf = pw.Document();
    final regular = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));

    final dateFormat = DateFormat('yyyy-MM-dd');

    // Determine orientation based on column count
    final int columnCount = 2 + // code + name
        (includeStageCode ? 1 : 0) +
        (includeStageName ? 1 : 0) +
        (includeKhorosCode ? 1 : 0) +
        (includeKhorosName ? 1 : 0) +
        report.meetings.length +
        2 + // Attendance, points
        (report.addBehavior ? 1 : 0) +
        1; // final grade

    final pageFormat = exportOptions.pageFormatForColumnCount(columnCount);
    final tableFontSize = exportOptions.fittedFontSize(
      columnCount,
      baseSize: 7,
      comfortableColumnCount: 8,
    );

    // Headers
    final headers = [
      'كود الطالب',
      'اسم الطالب',
      if (includeStageCode) 'كود المرحلة',
      if (includeStageName) 'اسم المرحلة',
      if (includeKhorosCode) 'كود الخورس',
      if (includeKhorosName) 'اسم الخورس',
      ...report.meetings.map(
        (m) => '${dateFormat.format(m.date)}\n${m.serviceName}',
      ),
      'الحضور',
      'مجموع النقاط',
      if (report.addBehavior) 'متوسط السلوك',
      'المجموع',
    ];

    // Data rows
    final data = report.students.map((student) {
      return [
        student.personId.toString(),
        student.personName,
        if (includeStageCode) student.stageId?.toString() ?? '',
        if (includeStageName) student.stageName,
        if (includeKhorosCode) student.khorosId?.toString() ?? '',
        if (includeKhorosName) student.khorosName,
        ...report.meetings.map((meeting) {
          if (!student.serviceIds.contains(meeting.serviceId)) {
            return '-';
          }
          final attended = student.attendedKeys.contains(meeting.key);
          if (attended) {
            final pt = student.dailyPoints[meeting.key] ?? 0;
            return '✓ ($pt/${_formatGrade(report.dayMaxGrade)})';
          }
          return '';
        }),
        '${_formatGrade(student.attendanceGrade)} (${_formatGrade(student.attendancePercentage)}%)',
        student.totalDailyPoints.toString(),
        if (report.addBehavior) _formatGrade(student.averageBehavior),
        _formatGrade(student.grade),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(
          regular,
          bold,
          'تقفيل حضور الترم',
          report,
          churchName,
          churchLogo,
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: pw.TextStyle(font: regular, fontSize: tableFontSize),
            headerStyle: pw.TextStyle(
              font: bold,
              fontSize: tableFontSize,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
        footer: (context) => _buildFooter(
          regular,
          bold,
          context.pageNumber,
          context.pagesCount,
        ),
      ),
    );

    final titleDate =
        '${dateFormat.format(report.startDate)}_${dateFormat.format(report.endDate)}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'term_attendance_$titleDate.pdf',
    );
  }

  static pw.Widget _buildHeader(
    pw.Font font,
    pw.Font boldFont,
    String title,
    TermAttendanceReport report,
    String? churchName,
    Uint8List? churchLogo,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final logoImage = churchLogo != null ? pw.MemoryImage(churchLogo) : null;

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Image(logoImage, width: 50, height: 50)
              else
                pw.SizedBox(width: 50),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (churchName != null && churchName.isNotEmpty)
                      pw.Text(
                        churchName,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 11,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 50),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 15,
            runSpacing: 5,
            alignment: pw.WrapAlignment.center,
            children: [
              pw.Text(
                'الخدمات: ${report.services.map((s) => s.serviceName ?? '').join('، ')}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'الفترة: من ${dateFormat.format(report.startDate)} إلى ${dateFormat.format(report.endDate)}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'درجة الحضور: ${_formatGrade(report.maxGrade)}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'درجة اليوم: ${_formatGrade(report.dayMaxGrade)}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Font font,
    pw.Font boldFont,
    int page,
    int total,
  ) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 5),
          pw.Text(
            'صفحة $page من $total',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatGrade(double grade) {
    return grade == grade.roundToDouble()
        ? grade.toInt().toString()
        : grade.toStringAsFixed(2);
  }
}
