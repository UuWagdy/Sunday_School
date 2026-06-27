import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pdf_export_options.dart';
import '../repositories/attendance_repository.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'pdf_generation_task.dart';

class _AttendanceGridPdfRequest {
  const _AttendanceGridPdfRequest({
    required this.data,
    required this.title,
    required this.headerData,
    required this.sortingCriteria,
    required this.columns,
    required this.serviceLogos,
    required this.churchLogo,
    required this.khorosLogo,
    required this.churchName,
    required this.hasServiceSelected,
    required this.serviceMinsMap,
    required this.dynamicLabels,
    required this.regularBytes,
    required this.boldBytes,
    required this.separatePages,
    required this.exportOptions,
  });

  final List<AttendanceDTO> data;
  final String title;
  final Map<String, dynamic> headerData;
  final List<String> sortingCriteria;
  final List<Map<String, String>> columns;
  final List<Uint8List>? serviceLogos;
  final Uint8List? churchLogo;
  final Uint8List? khorosLogo;
  final String? churchName;
  final bool hasServiceSelected;
  final Map<int, int>? serviceMinsMap;
  final Map<String, String>? dynamicLabels;
  final Uint8List regularBytes;
  final Uint8List boldBytes;
  final bool separatePages;
  final PdfExportOptions exportOptions;
}

Future<void> _attendanceGridPdfEntryPoint(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  final request = message[1] as _AttendanceGridPdfRequest;
  try {
    final bytes = await AttendanceGridPdfGenerator._buildGridPDF(
      data: request.data,
      title: request.title,
      headerData: request.headerData,
      sortingCriteria: request.sortingCriteria,
      columns: request.columns,
      serviceLogos: request.serviceLogos,
      churchLogo: request.churchLogo,
      khorosLogo: request.khorosLogo,
      churchName: request.churchName,
      hasServiceSelected: request.hasServiceSelected,
      serviceMinsMap: request.serviceMinsMap,
      dynamicLabels: request.dynamicLabels,
      regularBytes: request.regularBytes,
      boldBytes: request.boldBytes,
      reporter: reporter,
      separatePages: request.separatePages,
      exportOptions: request.exportOptions,
    );
    reporter.complete(bytes);
  } catch (error, stackTrace) {
    reporter.fail(error, stackTrace);
  }
}

class AttendanceGridPdfGenerator {
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

  static Future<Uint8List> generateGridPDF({
    required List<AttendanceDTO> data,
    required String title,
    required Map<String, dynamic> headerData,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    Map<String, String>? dynamicLabels,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final task = await startGridPDFGeneration(
      data: data,
      title: title,
      headerData: headerData,
      sortingCriteria: sortingCriteria,
      columns: columns,
      serviceLogos: serviceLogos,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      hasServiceSelected: hasServiceSelected,
      serviceMinsMap: serviceMinsMap,
      dynamicLabels: dynamicLabels,
      separatePages: separatePages,
      exportOptions: exportOptions,
    );
    return task.result;
  }

  static Future<PdfGenerationTask> startGridPDFGeneration({
    required List<AttendanceDTO> data,
    required String title,
    required Map<String, dynamic> headerData,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    Map<String, String>? dynamicLabels,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();

    return PdfGenerationTask.start(
      _attendanceGridPdfEntryPoint,
      _AttendanceGridPdfRequest(
        data: data,
        title: title,
        headerData: headerData,
        sortingCriteria: sortingCriteria,
        columns: columns,
        serviceLogos: serviceLogos,
        churchLogo: churchLogo,
        khorosLogo: khorosLogo,
        churchName: churchName,
        hasServiceSelected: hasServiceSelected,
        serviceMinsMap: serviceMinsMap,
        dynamicLabels: dynamicLabels,
        regularBytes: regularBytes,
        boldBytes: boldBytes,
        separatePages: separatePages,
        exportOptions: exportOptions,
      ),
    );
  }

  static Future<Uint8List> _buildGridPDF({
    required List<AttendanceDTO> data,
    required String title,
    required Map<String, dynamic> headerData,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    required bool hasServiceSelected,
    Map<int, int>? serviceMinsMap,
    Map<String, String>? dynamicLabels,
    required Uint8List regularBytes,
    required Uint8List boldBytes,
    required PdfGenerationReporter reporter,
    required bool separatePages,
    required PdfExportOptions exportOptions,
  }) async {
    final pdf = pw.Document();
    final regular = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));

    // Sort the data based on user criteria
    final sortedData = List<AttendanceDTO>.from(data);
    sortedData.sort((a, b) {
      for (var criterion in sortingCriteria) {
        int cmp = 0;
        if (criterion == 'area') {
          cmp = (a.areaName ?? '').compareTo(b.areaName ?? '');
        } else if (criterion == 'stage') {
          cmp = (a.stageName ?? '').compareTo(b.stageName ?? '');
        } else if (criterion == 'father') {
          cmp = (a.fatherName ?? '').compareTo(b.fatherName ?? '');
        } else if (criterion == 'name') {
          cmp = (a.personName ?? '').compareTo(b.personName ?? '');
        } else if (criterion == 'khoros') {
          cmp = (a.khorosName ?? '').compareTo(b.khorosName ?? '');
        }
        if (cmp != 0) return cmp;
      }
      return 0;
    });

    // 1. Extract unique Date+Service combinations
    final Set<String> uniqueDatesSet = {};
    for (var r in sortedData) {
      if (r.dateWeek != null && r.dateWeek!.isNotEmpty) {
        final d = r.dateWeek!;
        final s = r.serviceName?.trim() ?? '';
        uniqueDatesSet.add('$d|$s');
      }
    }
    final List<String> sortedDates = uniqueDatesSet.toList()
      ..sort((a, b) => a.split('|')[0].compareTo(b.split('|')[0]));

    final showPointsInAttendanceCells = shouldRenderPointsInAttendanceCells(
      columns,
      sortedDates,
    );
    final List<Map<String, String>> expandedColumns = [];
    for (var col in columns) {
      final id = col['id'];
      if (id == 'points' && showPointsInAttendanceCells) {
        continue;
      }
      if (id == 'points' ||
          id == 'earlyLate' ||
          id == 'time' ||
          id == 'checkout') {
        if (sortedDates.isNotEmpty) {
          for (var d in sortedDates) {
            expandedColumns.add({
              'id': '$id|$d',
              'title': '${col['title']}\n${_formatDateService(d)}',
            });
          }
        } else {
          expandedColumns.add(col);
        }
      } else {
        expandedColumns.add(col);
      }
    }

    final totalCols = 1 + expandedColumns.length + sortedDates.length + 1;
    final pageFormat = exportOptions.pageFormatForColumnCount(totalCols);
    final tableFontSize = exportOptions.fittedFontSize(
      totalCols,
      baseSize: 7,
      comfortableColumnCount: 10,
    );

    // Prepare logo images
    final List<pw.ImageProvider> serviceLogoImages = [];
    if (serviceLogos != null) {
      for (var logo in serviceLogos) {
        try {
          serviceLogoImages.add(pw.MemoryImage(logo));
        } catch (_) {}
      }
    }
    pw.ImageProvider? churchLogoImage;
    pw.ImageProvider? khorosLogoImage;
    if (churchLogo != null) {
      try {
        churchLogoImage = pw.MemoryImage(churchLogo);
      } catch (_) {}
    }
    if (khorosLogo != null) {
      try {
        khorosLogoImage = pw.MemoryImage(khorosLogo);
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(
          regular,
          bold,
          title,
          headerData,
          serviceLogoImages,
          churchLogoImage,
          khorosLogoImage,
          churchName,
          hasServiceSelected,
        ),
        build: (context) => _buildContent(
          regular,
          bold,
          sortedData,
          sortingCriteria,
          expandedColumns,
          sortedDates,
          serviceMinsMap,
          dynamicLabels,
          reporter,
          separatePages,
          showPointsInAttendanceCells,
          tableFontSize,
        ),
        footer: (context) =>
            _buildFooter(regular, bold, context.pageNumber, context.pagesCount),
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrintGridPDF({
    required List<AttendanceDTO> data,
    required String title,
    required Map<String, dynamic> headerData,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    Map<String, String>? dynamicLabels,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final bytes = await generateGridPDF(
      data: data,
      title: title,
      headerData: headerData,
      sortingCriteria: sortingCriteria,
      columns: columns,
      serviceLogos: serviceLogos,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      hasServiceSelected: hasServiceSelected,
      serviceMinsMap: serviceMinsMap,
      dynamicLabels: dynamicLabels,
      separatePages: separatePages,
      exportOptions: exportOptions,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Attendance_Grid.pdf',
    );
  }

  static pw.Widget _buildHeader(
    pw.Font font,
    pw.Font boldFont,
    String title,
    Map<String, dynamic>? headerData,
    List<pw.ImageProvider>? serviceLogos,
    pw.ImageProvider? churchLogo,
    pw.ImageProvider? khorosLogo,
    String? churchName,
    bool hasServiceSelected,
  ) {
    // Logo positioning:
    // Right (RTL first) = Church logo
    // Left (RTL last) = Service logos (if any), else Khoros logo
    // Center = Khoros logo if service is selected and khoros is also selected
    final rightLogo = churchLogo;
    pw.Widget leftmostWidget;
    bool showKhorosInCenter = false;

    if (serviceLogos != null && serviceLogos.isNotEmpty) {
      leftmostWidget = pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: serviceLogos
            .map(
              (img) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                child: pw.Image(img, width: 32, height: 32),
              ),
            )
            .toList(),
      );
      if (khorosLogo != null) {
        showKhorosInCenter = true;
      }
    } else if (khorosLogo != null) {
      leftmostWidget = pw.Image(khorosLogo, width: 34, height: 34);
    } else {
      leftmostWidget = pw.SizedBox(width: 34);
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        children: [
          // Logo row: Church logo on the right (RTL), Service logo(s) on the left
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Right side (RTL first): Church logo
              if (rightLogo != null)
                pw.Image(rightLogo, width: 34, height: 34)
              else
                pw.SizedBox(width: 34),
              // Title in center
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
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
                          fontSize: 8,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
              // Left side (RTL last): service logos or khoros logo
              leftmostWidget,
            ],
          ),
          // If both service and khoros selected, show khoros logo centered below
          if (showKhorosInCenter && khorosLogo != null) ...[
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Image(khorosLogo, width: 24, height: 24)),
          ],
          pw.SizedBox(height: 3),
          if (headerData != null && headerData.isNotEmpty)
            pw.Wrap(
              spacing: 8,
              runSpacing: 2,
              alignment: pw.WrapAlignment.center,
              children: headerData.entries
                  .map(
                    (e) => pw.Text(
                      '${e.key}: ${e.value}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 2),
          pw.Text(
            'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildContent(
    pw.Font font,
    pw.Font boldFont,
    List<AttendanceDTO> data,
    List<String> criteria,
    List<Map<String, String>> columns,
    List<String> sortedDates,
    Map<int, int>? serviceMinsMap,
    Map<String, String>? dynamicLabels,
    PdfGenerationReporter reporter,
    bool separatePages,
    bool showPointsInAttendanceCells,
    double tableFontSize,
  ) {
    if (data.isEmpty) {
      return [
        pw.Center(
          child: pw.Text('لا توجد بيانات', style: pw.TextStyle(font: font)),
        ),
      ];
    }

    final widgets = <pw.Widget>[];

    // Tracking current values for each grouping level
    final Map<String, String?> currentValues = {};
    for (var c in criteria) currentValues[c] = null;
    var processedRecords = 0;

    void reportPaintedRecords(int count) {
      processedRecords += count;
      reporter.update(
        processedRecords.clamp(0, data.length),
        data.length,
        'جاري رسم شبكة الحضور داخل ملف PDF...',
      );
    }

    List<AttendanceDTO> currentGroup = [];

    void flushGroup(AttendanceDTO? nextRecord) {
      if (currentGroup.isNotEmpty) {
        widgets.addAll(
          _buildGroupTables(
            font,
            boldFont,
            currentGroup,
            columns,
            sortedDates,
            serviceMinsMap,
            reportPaintedRecords,
            showPointsInAttendanceCells,
            tableFontSize,
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        currentGroup = [];
      }

      if (nextRecord == null) return;

      bool levelChanged = false;
      for (var i = 0; i < criteria.length; i++) {
        final cid = criteria[i];
        if (cid == 'name') continue; // Don't group by name header

        final val = _getValue(nextRecord, cid);
        if (levelChanged || val != currentValues[cid]) {
          levelChanged = true;
          currentValues[cid] = val;

          for (var j = i + 1; j < criteria.length; j++) {
            currentValues[criteria[j]] = null;
          }

          if (separatePages && i == 0 && widgets.isNotEmpty) {
            widgets.add(pw.NewPage());
          }

          final colors = [
            PdfColors.blue100,
            PdfColors.grey200,
            PdfColors.orange50,
          ];
          final textColors = [
            PdfColors.blue800,
            PdfColors.grey800,
            PdfColors.orange900,
          ];
          final color = colors[i % colors.length];
          final textColor = textColors[i % textColors.length];
          final label = _getLabel(cid, dynamicLabels);

          widgets.add(
            pw.Container(
              padding: pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: i == 0 ? 5 : 3,
              ),
              margin: pw.EdgeInsets.only(top: i == 0 ? 10 : 0, bottom: 5),
              decoration: pw.BoxDecoration(color: color),
              width: double.infinity,
              child: pw.Text(
                '$label: ${val ?? "غير محدد"}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: i == 0 ? 16 : 13,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          );
        }
      }
    }

    for (var i = 0; i < data.length; i++) {
      final r = data[i];
      bool needsFlush = false;
      for (var cid in criteria) {
        if (cid == 'name') continue;
        if (_getValue(r, cid) != currentValues[cid]) {
          needsFlush = true;
          break;
        }
      }

      if (needsFlush) {
        flushGroup(r);
      }
      currentGroup.add(r);
    }

    if (currentGroup.isNotEmpty) {
      widgets.addAll(
        _buildGroupTables(
          font,
          boldFont,
          currentGroup,
          columns,
          sortedDates,
          serviceMinsMap,
          reportPaintedRecords,
          showPointsInAttendanceCells,
          tableFontSize,
        ),
      );
    }

    return widgets;
  }

  static String _getLabel(String id, Map<String, String>? dynamicLabels) {
    if (dynamicLabels != null && dynamicLabels.containsKey(id))
      return dynamicLabels[id]!;
    if (id == 'area') return 'المنطقة';
    if (id == 'stage') return 'المرحلة';
    if (id == 'father') return 'أب الاعتراف';
    if (id == 'khoros') return 'الخورس';
    if (id == 'name') return 'الاسم';
    if (id == 'rohot') return 'الرهط';
    if (id == 'leader') return 'القائد';
    if (id == 'services') return 'الخدمات';
    if (id.startsWith('custom_')) {
      final parts = id.split('_');
      if (parts.length > 2) {
        return parts.sublist(2).join('_');
      }
      return 'حقل مخصص';
    }
    return '';
  }

  static String? _getValue(AttendanceDTO r, String id) {
    if (id == 'area') return r.areaName;
    if (id == 'stage') return r.stageName;
    if (id == 'father') return r.fatherName;
    if (id == 'khoros') return r.khorosName;
    if (id == 'name') return r.personName;
    if (id == 'rohot') return r.rohot;
    if (id == 'leader') return r.leader;
    if (id == 'services') return r.services;
    if (id.startsWith('custom_')) {
      final parts = id.split('_');
      final fId = int.tryParse(parts[1]);
      if (fId != null) {
        return r.customValues[fId];
      }
    }
    return null;
  }

  static List<pw.Widget> _buildGroupTables(
    pw.Font font,
    pw.Font boldFont,
    List<AttendanceDTO> groupData,
    List<Map<String, String>> columns,
    List<String> dates,
    Map<int, int>? serviceMinsMap,
    void Function(int count) onPaintedRecords,
    bool showPointsInAttendanceCells,
    double tableFontSize,
  ) {
    // Extract unique persons and map their attendance for this group
    final Map<int, AttendanceDTO> personsMap = {};
    final Map<int, Set<String>> attendanceMap = {};
    final Map<int, int> recordCounts = {};
    final Map<String, AttendanceDTO> personServiceRecordMap = {};

    for (var r in groupData) {
      if (r.personId != null) {
        recordCounts[r.personId] = (recordCounts[r.personId] ?? 0) + 1;
        if (!personsMap.containsKey(r.personId!)) {
          personsMap[r.personId!] = r;
        }
        if (!attendanceMap.containsKey(r.personId!)) {
          attendanceMap[r.personId!] = {};
        }
        if (r.dateWeek != null && r.id != null) {
          final s = r.serviceName?.trim() ?? '';
          attendanceMap[r.personId!]!.add('${r.dateWeek!}|$s');
          personServiceRecordMap['${r.personId!}|${r.dateWeek!}|$s'] = r;
        }
      }
    }
    final personIds = personsMap.keys.toList();
    // Maintain overall order (they are already grouped correctly in `groupData`, we just take unique)

    final widgets = <pw.Widget>[];
    const int maxColsPerTable = 15;

    if (dates.isNotEmpty) {
      for (int i = 0; i < dates.length; i += maxColsPerTable) {
        final end = (i + maxColsPerTable < dates.length)
            ? i + maxColsPerTable
            : dates.length;
        final currentDates = dates.sublist(i, end);

        widgets.add(
          _buildTable(
            font,
            boldFont,
            currentDates,
            personIds, // All personIds in the group
            personIds, // allPersonIds
            personsMap,
            attendanceMap,
            columns,
            serviceMinsMap,
            recordCounts,
            onPaintedRecords,
            showPointsInAttendanceCells: showPointsInAttendanceCells,
            tableFontSize: tableFontSize,
            reportRows: i == 0,
            showFooter: true,
            startRowIndex: 0,
            personServiceRecordMap: personServiceRecordMap,
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
      }
    } else {
      widgets.add(
        _buildTable(
          font,
          boldFont,
          [],
          personIds, // All personIds in the group
          personIds, // allPersonIds
          personsMap,
          attendanceMap,
          columns,
          serviceMinsMap,
          recordCounts,
          onPaintedRecords,
          showPointsInAttendanceCells: showPointsInAttendanceCells,
          tableFontSize: tableFontSize,
          reportRows: true,
          showFooter: true,
          startRowIndex: 0,
          personServiceRecordMap: personServiceRecordMap,
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  // A font-independent checkmark drawn as a vector path
  static pw.Widget _checkmarkCell() {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(1),
      child: pw.CustomPaint(
        size: const PdfPoint(8, 8),
        painter: (PdfGraphics canvas, PdfPoint size) {
          canvas
            ..setColor(PdfColors.green800)
            ..setLineWidth(1.5)
            ..setLineCap(PdfLineCap.round)
            ..setLineJoin(PdfLineJoin.round)
            ..moveTo(1, 4)
            ..lineTo(3, 1.5)
            ..lineTo(7, 6.5)
            ..strokePath();
        },
      ),
    );
  }

  static bool shouldRenderPointsInAttendanceCells(
    List<Map<String, String>> columns,
    List<String> sortedDates,
  ) {
    return sortedDates.isNotEmpty &&
        columns.any((col) => col['id'] == 'points');
  }

  static String attendanceCellLabel({
    required bool attended,
    required int? points,
    required bool showPoints,
  }) {
    if (!attended) return '';
    if (!showPoints) return 'check';
    return 'check (${points ?? 0})';
  }

  static pw.Widget _attendanceCell(
    pw.Font font,
    bool attended,
    int? points,
    bool showPoints,
    double fontSize,
  ) {
    if (!attended) return pw.SizedBox();
    if (!showPoints) return _checkmarkCell();
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _checkmarkCell(),
          pw.SizedBox(width: 2),
          pw.Text(
            '(${points ?? 0})',
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(
              font: font,
              fontSize: fontSize * 0.85,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _textCellWidget(
    String text,
    pw.Font font, {
    double fontSize = 7,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTable(
    pw.Font font,
    pw.Font boldFont,
    List<String> dates,
    List<int> personIds,
    List<int> allPersonIds,
    Map<int, AttendanceDTO> personsMap,
    Map<int, Set<String>> attendanceMap,
    List<Map<String, String>> columns,
    Map<int, int>? serviceMinsMap,
    Map<int, int> recordCounts,
    void Function(int count) onPaintedRecords, {
    required bool showPointsInAttendanceCells,
    required double tableFontSize,
    required bool reportRows,
    bool showFooter = true,
    int startRowIndex = 0,
    Map<String, AttendanceDTO>? personServiceRecordMap,
  }) {
    final int dateColCount = dates.length;
    final int infoColCount = columns.length;
    // Total columns: 1 (Total) + dateColCount + infoColCount + 1 (#)
    final int totalCols = 1 + dateColCount + infoColCount + 1;

    // Column widths map
    final Map<int, pw.TableColumnWidth> colWidths = {};
    colWidths[totalCols - 1] = const pw.FixedColumnWidth(
      20,
    ); // # column (far right)
    // Name column (second from right after #)
    for (int c = 0; c < columns.reversed.length; c++) {
      if (columns.reversed.toList()[c]['id'] == 'name') {
        colWidths[1 + dateColCount + c] = const pw.FlexColumnWidth(3);
      }
    }

    // === HEADER ROW ===
    final headerCells = <pw.Widget>[];
    // Total header (far left)
    headerCells.add(
      _textCellWidget(
        'الإجمالي',
        boldFont,
        fontSize: 8,
        color: PdfColors.white,
        bold: true,
      ),
    );
    // Date headers
    for (var d in dates.reversed) {
      headerCells.add(
        _textCellWidget(
          _formatDateService(d),
          boldFont,
          fontSize: 8,
          color: PdfColors.white,
          bold: true,
        ),
      );
    }
    // Info column headers
    for (var col in columns.reversed) {
      headerCells.add(
        _textCellWidget(
          col['title']!,
          boldFont,
          fontSize: 8,
          color: PdfColors.white,
          bold: true,
        ),
      );
    }
    // # header
    headerCells.add(
      _textCellWidget(
        'م',
        boldFont,
        fontSize: 8,
        color: PdfColors.white,
        bold: true,
      ),
    );

    final tableRows = <pw.TableRow>[];
    tableRows.add(
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        children: headerCells,
      ),
    );

    // === DATA ROWS ===
    final Map<String, int> dateTotals = {};
    int grandTotal = 0;

    // Calculate totals over ALL person IDs in the group, not just the chunk
    for (final pid in allPersonIds) {
      final atts = attendanceMap[pid]!;
      grandTotal += atts.length;
      for (var d in dates) {
        if (atts.contains(d)) {
          dateTotals[d] = (dateTotals[d] ?? 0) + 1;
        }
      }
    }

    for (int i = 0; i < personIds.length; i++) {
      final pid = personIds[i];
      final personRec = personsMap[pid]!;
      final atts = attendanceMap[pid]!;

      final rowCells = <pw.Widget>[];
      // Total (far left)
      final totalCell = _textCellWidget(
        atts.length.toString(),
        font,
        fontSize: tableFontSize,
      );
      rowCells.add(
        reportRows
            ? PdfProgressMarker(
                child: totalCell,
                onPaint: () => onPaintedRecords(recordCounts[pid] ?? 1),
              )
            : totalCell,
      );

      // Date columns — checkmark or empty
      for (var d in dates.reversed) {
        final record = personServiceRecordMap?['$pid|$d'];
        rowCells.add(
          _attendanceCell(
            boldFont,
            atts.contains(d),
            record?.point,
            showPointsInAttendanceCells,
            tableFontSize,
          ),
        );
      }

      // Info columns
      for (var col in columns.reversed) {
        String txt = '';
        final colId = col['id'] ?? '';
        final parts = colId.split('|');
        final baseId = parts[0];
        final String? dateServiceKey = parts.length > 1
            ? parts.sublist(1).join('|')
            : null;

        AttendanceDTO? targetRec;
        if (dateServiceKey != null) {
          targetRec = personServiceRecordMap?['$pid|$dateServiceKey'];
        } else {
          targetRec = personRec;
        }

        if (targetRec != null) {
          switch (baseId) {
            case 'name':
              txt = targetRec.personName ?? '';
              break;
            case 'id':
              txt = targetRec.personId?.toString() ?? '';
              break;
            case 'area':
              txt = targetRec.areaName ?? '';
              break;
            case 'stage':
              txt = targetRec.stageName ?? '';
              break;
            case 'father':
              txt = targetRec.fatherName ?? '';
              break;
            case 'mobile':
              txt = targetRec.mobile ?? '';
              break;
            case 'phone':
              txt = targetRec.phone ?? '';
              break;
            case 'street':
              txt = targetRec.address ?? '';
              break;
            case 'date':
              txt = targetRec.dateWeek ?? '';
              break;
            case 'points':
              txt = targetRec.point?.toString() ?? '';
              break;
            case 'time':
              txt = targetRec.attendTime ?? '';
              break;
            case 'checkout':
              txt = targetRec.checkoutTime ?? '';
              break;
            case 'earlyLate':
              if (targetRec.serviceId != null &&
                  targetRec.attendTime != null &&
                  serviceMinsMap != null &&
                  serviceMinsMap.containsKey(targetRec.serviceId)) {
                try {
                  final partsTime = targetRec.attendTime!.split(' ');
                  if (partsTime.length >= 2) {
                    final timeParts = partsTime[0].split(':');
                    int h = int.parse(timeParts[0]);
                    final int m = int.parse(timeParts[1]);
                    final isPm = partsTime[1] == 'م';
                    if (isPm && h < 12) h += 12;
                    if (!isPm && h == 12) h = 0;

                    final attendMins = h * 60 + m;
                    final serviceMins = serviceMinsMap[targetRec.serviceId]!;
                    final diff = attendMins - serviceMins;

                    if (diff > 0)
                      txt = 'تأخير ${diff} ق';
                    else if (diff < 0)
                      txt = 'تبكير ${diff.abs()} ق';
                    else
                      txt = '-';
                  }
                } catch (_) {}
              }
              break;
            case 'service':
              txt = targetRec.serviceName ?? '';
              break;
            case 'visitNotes':
              txt = targetRec.visitNotes ?? '';
              break;
          }
        }
        rowCells.add(_textCellWidget(txt, font, fontSize: tableFontSize));
      }

      // # (far right)
      rowCells.add(
        _textCellWidget(
          (startRowIndex + i + 1).toString(),
          font,
          fontSize: tableFontSize,
        ),
      );

      final isOdd = i % 2 == 1;
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isOdd ? PdfColors.grey100 : null,
            border: const pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
            ),
          ),
          children: rowCells,
        ),
      );
    }

    // === FOOTER (TOTALS) ROW ===
    if (showFooter) {
      final footerCells = <pw.Widget>[];
      footerCells.add(
        _textCellWidget(grandTotal.toString(), boldFont, bold: true),
      );
      for (var d in dates.reversed) {
        footerCells.add(
          _textCellWidget(
            (dateTotals[d] ?? 0).toString(),
            boldFont,
            bold: true,
          ),
        );
      }
      for (var col in columns.reversed) {
        footerCells.add(
          _textCellWidget(
            col['id'] == 'name' ? 'الإجمالي' : '',
            boldFont,
            bold: true,
          ),
        );
      }
      footerCells.add(_textCellWidget('', boldFont));

      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: footerCells,
        ),
      );
    }

    return pw.Table(
      columnWidths: colWidths,
      defaultColumnWidth: const pw.IntrinsicColumnWidth(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: tableRows,
    );
  }

  static String _formatDateService(String fullDateStr) {
    // format: "2024-03-15|Service Name" -> "03-15\nService Name"
    final parts = fullDateStr.split('|');
    String d = parts.isNotEmpty ? parts[0] : '';
    String s = parts.length > 1 ? parts[1] : '';
    if (d.length >= 10) d = d.substring(5); // drop year
    if (s.isEmpty) return d;
    return '$d\n$s';
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
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: const pw.BoxDecoration(
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              color: PdfColors.grey100,
            ),
            child: pw.Text(
              '$page',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
