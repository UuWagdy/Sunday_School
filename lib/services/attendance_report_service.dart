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

class _AttendancePdfRequest {
  const _AttendancePdfRequest({
    required this.data,
    required this.sortingCriteria,
    required this.columns,
    required this.title,
    required this.headerData,
    required this.serviceLogos,
    required this.churchLogo,
    required this.khorosLogo,
    required this.churchName,
    required this.hasServiceSelected,
    required this.serviceMinsMap,
    required this.regularBytes,
    required this.boldBytes,
    required this.separatePages,
    required this.exportOptions,
  });

  final List<AttendanceDTO> data;
  final List<String> sortingCriteria;
  final List<Map<String, String>> columns;
  final String? title;
  final Map<String, String>? headerData;
  final List<Uint8List>? serviceLogos;
  final Uint8List? churchLogo;
  final Uint8List? khorosLogo;
  final String? churchName;
  final bool hasServiceSelected;
  final Map<int, int>? serviceMinsMap;
  final Uint8List regularBytes;
  final Uint8List boldBytes;
  final bool separatePages;
  final PdfExportOptions exportOptions;
}

Future<void> _attendancePdfEntryPoint(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  final request = message[1] as _AttendancePdfRequest;
  try {
    final bytes = await AttendanceReportService._buildPDF(
      data: request.data,
      sortingCriteria: request.sortingCriteria,
      columns: request.columns,
      title: request.title,
      headerData: request.headerData,
      serviceLogos: request.serviceLogos,
      churchLogo: request.churchLogo,
      khorosLogo: request.khorosLogo,
      churchName: request.churchName,
      hasServiceSelected: request.hasServiceSelected,
      serviceMinsMap: request.serviceMinsMap,
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

class AttendanceReportService {
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

  static Future<Uint8List> generatePDF({
    required List<AttendanceDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final task = await startPDFGeneration(
      data: data,
      sortingCriteria: sortingCriteria,
      columns: columns,
      title: title,
      headerData: headerData,
      serviceLogos: serviceLogos,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      hasServiceSelected: hasServiceSelected,
      serviceMinsMap: serviceMinsMap,
      separatePages: separatePages,
      exportOptions: exportOptions,
    );
    return task.result;
  }

  static Future<PdfGenerationTask> startPDFGeneration({
    required List<AttendanceDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();

    return PdfGenerationTask.start(
      _attendancePdfEntryPoint,
      _AttendancePdfRequest(
        data: data,
        sortingCriteria: sortingCriteria,
        columns: columns,
        title: title,
        headerData: headerData,
        serviceLogos: serviceLogos,
        churchLogo: churchLogo,
        khorosLogo: khorosLogo,
        churchName: churchName,
        hasServiceSelected: hasServiceSelected,
        serviceMinsMap: serviceMinsMap,
        regularBytes: regularBytes,
        boldBytes: boldBytes,
        separatePages: separatePages,
        exportOptions: exportOptions,
      ),
    );
  }

  static Future<Uint8List> _buildPDF({
    required List<AttendanceDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    required bool hasServiceSelected,
    Map<int, int>? serviceMinsMap,
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
        final valA = _getValue(a, criterion) ?? '';
        final valB = _getValue(b, criterion) ?? '';
        int cmp = valA.compareTo(valB);
        if (cmp != 0) return cmp;
      }
      return 0;
    });

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

    final pageFormat = exportOptions.pageFormatForColumnCount(
      columns.length,
      landscapeThreshold: 7,
    );
    final tableFontSize = exportOptions.fittedFontSize(
      columns.length,
      baseSize: 8,
      comfortableColumnCount: 7,
    );

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(
          regular,
          bold,
          title ?? 'تقرير الحضور',
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
          columns,
          serviceMinsMap,
          reporter,
          separatePages,
          tableFontSize,
        ),
        footer: (context) =>
            _buildFooter(regular, bold, context.pageNumber, context.pagesCount),
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrintPDF({
    required List<AttendanceDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    List<Uint8List>? serviceLogos,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    bool hasServiceSelected = false,
    Map<int, int>? serviceMinsMap,
    bool separatePages = false,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final bytes = await generatePDF(
      data: data,
      sortingCriteria: sortingCriteria,
      columns: columns,
      title: title,
      headerData: headerData,
      serviceLogos: serviceLogos,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      hasServiceSelected: hasServiceSelected,
      serviceMinsMap: serviceMinsMap,
      separatePages: separatePages,
      exportOptions: exportOptions,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Attendance_Report.pdf',
    );
  }

  static pw.Widget _buildHeader(
    pw.Font font,
    pw.Font boldFont,
    String title,
    Map<String, String>? headerData,
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                child: pw.Image(img, width: 45, height: 45),
              ),
            )
            .toList(),
      );
      if (khorosLogo != null) {
        showKhorosInCenter = true;
      }
    } else if (khorosLogo != null) {
      leftmostWidget = pw.Image(khorosLogo, width: 50, height: 50);
    } else {
      leftmostWidget = pw.SizedBox(width: 50);
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        children: [
          // Logo row: Church logo on the right (RTL), Service logo(s) on the left
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Right side (RTL first): Church logo
              if (rightLogo != null)
                pw.Image(rightLogo, width: 50, height: 50)
              else
                pw.SizedBox(width: 50),
              // Title in center
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
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
              // Left side (RTL last): service logos or khoros logo
              leftmostWidget,
            ],
          ),
          // If both service and khoros selected, show khoros logo centered below
          if (showKhorosInCenter && khorosLogo != null) ...[
            pw.SizedBox(height: 5),
            pw.Center(child: pw.Image(khorosLogo, width: 40, height: 40)),
          ],
          pw.SizedBox(height: 5),
          if (headerData != null && headerData.isNotEmpty)
            pw.Wrap(
              spacing: 15,
              runSpacing: 5,
              alignment: pw.WrapAlignment.center,
              children: headerData.entries
                  .map(
                    (e) => pw.Text(
                      '${e.key}: ${e.value}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 5),
          pw.Text(
            'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
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
    Map<int, int>? serviceMinsMap,
    PdfGenerationReporter reporter,
    bool separatePages,
    double tableFontSize,
  ) {
    if (data.isEmpty)
      return [
        pw.Center(
          child: pw.Text('لا توجد بيانات', style: pw.TextStyle(font: font)),
        ),
      ];

    final widgets = <pw.Widget>[];

    // Tracking current values for each grouping level
    final Map<String, String?> currentValues = {};
    for (var c in criteria) currentValues[c] = null;
    var nextRowNumber = 0;
    int allocateRowNumber() => ++nextRowNumber;

    List<AttendanceDTO> currentGroup = [];

    void flushGroup(AttendanceDTO? nextRecord) {
      // Add one spanning table so its header can repeat at page boundaries.
      if (currentGroup.isNotEmpty) {
        widgets.add(
          _buildTable(
            font,
            boldFont,
            currentGroup,
            columns,
            serviceMinsMap,
            reporter,
            data.length,
            allocateRowNumber,
            tableFontSize,
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        currentGroup = [];
      }

      if (nextRecord == null) return;

      // 2. Identify which levels changed
      bool levelChanged = false;
      for (var i = 0; i < criteria.length; i++) {
        final cid = criteria[i];
        if (cid == 'name') continue; // Don't group by name header

        final val = _getValue(nextRecord, cid);
        if (levelChanged || val != currentValues[cid]) {
          levelChanged = true;
          currentValues[cid] = val;

          // Reset deeper levels
          for (var j = i + 1; j < criteria.length; j++) {
            currentValues[criteria[j]] = null;
          }

          if (separatePages && i == 0 && widgets.isNotEmpty) {
            widgets.add(pw.NewPage());
          }

          // 3. Build Header for this level
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
          final label = _getLabel(cid);

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
      widgets.add(
        _buildTable(
          font,
          boldFont,
          currentGroup,
          columns,
          serviceMinsMap,
          reporter,
          data.length,
          allocateRowNumber,
          tableFontSize,
        ),
      );
    }

    return widgets;
  }

  static String _getLabel(String id) {
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

  static pw.Widget _buildDoneCheckbox(String name) {
    return pw.Center(
      child: pw.Checkbox(
        name: name,
        value: false,
        width: 13,
        height: 13,
        activeColor: PdfColors.green700,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700, width: 1.2),
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
    );
  }

  static pw.Widget _cellText(
    pw.Font font,
    double fontSize,
    String value, {
    PdfColor color = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
      textAlign: align,
    );
  }

  static pw.Widget _buildTable(
    pw.Font font,
    pw.Font boldFont,
    List<AttendanceDTO> data,
    List<Map<String, String>> columns,
    Map<int, int>? serviceMinsMap,
    PdfGenerationReporter reporter,
    int total,
    int Function() allocateRowNumber,
    double tableFontSize,
  ) {
    // Reverse the list because the PDF package renders Index 0 on the left,
    // but the user expects the top of the list in the dialog to be the rightmost column.
    final rtlColumns = columns
        .where((col) {
          final id = col['id'] ?? '';
          return !id.startsWith('call_') &&
              !id.startsWith('whatsapp_') &&
              id != 'visited' &&
              id != 'visitType';
        })
        .toList()
        .reversed
        .toList();
    String valueFor(AttendanceDTO r, String columnId) {
      switch (columnId) {
        case 'name':
          return r.personName;
        case 'id':
          return r.personId.toString();
        case 'area':
          return r.areaName ?? '';
        case 'stage':
          return r.stageName ?? '';
        case 'father':
          return r.fatherName ?? '';
        case 'mobile':
          return r.mobile ?? '';
        case 'phone':
          return r.phone ?? '';
        case 'street':
        case 'address':
          return r.address ?? '';
        case 'date':
          return r.dateWeek ?? '';
        case 'points':
          return r.point?.toString() ?? '';
        case 'time':
          return r.attendTime ?? '';
        case 'checkout':
          return r.checkoutTime ?? '';
        case 'earlyLate':
          if (r.serviceId != null &&
              r.attendTime != null &&
              serviceMinsMap != null &&
              serviceMinsMap.containsKey(r.serviceId)) {
            try {
              final parts = r.attendTime!.split(' ');
              if (parts.length >= 2) {
                final timeParts = parts[0].split(':');
                int h = int.parse(timeParts[0]);
                final int m = int.parse(timeParts[1]);
                final isPm = parts[1] == 'م';
                if (isPm && h < 12) h += 12;
                if (!isPm && h == 12) h = 0;

                final attendMins = h * 60 + m;
                final serviceMins = serviceMinsMap[r.serviceId]!;
                final diff = attendMins - serviceMins;

                if (diff > 0) return 'تأخير ${diff} ق';
                if (diff < 0) return 'تبكير ${diff.abs()} ق';
                return '-';
              }
            } catch (_) {}
          }
          return '';
        case 'service':
          return r.serviceName ?? '';
        case 'visitNotes':
          return r.visitNotes ?? '';
        default:
          if (columnId.startsWith('custom_')) {
            return _getValue(r, columnId) ?? '';
          }
          return '';
      }
    }

    pw.Widget buildCell(AttendanceDTO r, Map<String, String> col, int rowNumber) {
      if ((col['id'] ?? '') == 'done_checkbox') {
        return _buildDoneCheckbox('done_${r.personId}_$rowNumber');
      }
      return _cellText(font, tableFontSize, valueFor(r, col['id'] ?? ''));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: rtlColumns
              .map(
                (col) => pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    col['title'] ?? '',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: tableFontSize + 1,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        ...data.map((r) {
          final rowNumber = allocateRowNumber();
          final cells = rtlColumns
              .map((col) => buildCell(r, col, rowNumber))
              .toList();
          if (cells.isNotEmpty) {
            cells[0] = PdfProgressMarker(
              child: cells[0],
              onPaint: () => reporter.update(
                rowNumber,
                total,
                'جاري رسم سجلات الحضور داخل ملف PDF...',
              ),
            );
          }
          return pw.TableRow(
            decoration: rowNumber.isOdd
                ? const pw.BoxDecoration(color: PdfColors.grey100)
                : null,
            children: cells
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: cell,
                  ),
                )
                .toList(),
          );
        }),
      ],
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
