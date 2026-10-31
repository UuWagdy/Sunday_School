import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BusColumnItem {
  final String key;
  final String label;
  final bool isVisible;

  const BusColumnItem({
    required this.key,
    required this.label,
    this.isVisible = true,
  });

  BusColumnItem copyWith({
    String? key,
    String? label,
    bool? isVisible,
  }) {
    return BusColumnItem(
      key: key ?? this.key,
      label: label ?? this.label,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'isVisible': isVisible,
  };

  factory BusColumnItem.fromJson(Map<String, dynamic> json) => BusColumnItem(
    key: json['key'] as String,
    label: json['label'] as String,
    isVisible: (json['isVisible'] as bool?) ?? true,
  );
}

class BusDriverPdfData {
  final int id;
  final String name;
  final String? phone;
  final String? busNumber;
  final String? notes;

  const BusDriverPdfData({
    required this.id,
    required this.name,
    this.phone,
    this.busNumber,
    this.notes,
  });
}

class BusStudentPdfData {
  final int personId;
  final String personName;
  final String? stageName;
  final String? khorosName;
  final String? areaName;
  final String? street;
  final String? phone;
  final String? mobile;
  final String? notes;
  final bool hasLeftWithParentToday;
  final bool isExcludedFromBusToday;
  final String? exclusionReason;

  const BusStudentPdfData({
    required this.personId,
    required this.personName,
    this.stageName,
    this.khorosName,
    this.areaName,
    this.street,
    this.phone,
    this.mobile,
    this.notes,
    this.hasLeftWithParentToday = false,
    this.isExcludedFromBusToday = false,
    this.exclusionReason,
  });
}

class BusPdfService {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static const List<BusColumnItem> defaultColumns = [
    BusColumnItem(key: 'index', label: 'م'),
    BusColumnItem(key: 'code', label: 'الكود'),
    BusColumnItem(key: 'name', label: 'اسم الطالب'),
    BusColumnItem(key: 'stage', label: 'المرحلة'),
    BusColumnItem(key: 'khoros', label: 'الخورس'),
    BusColumnItem(key: 'address', label: 'العنوان / المنطقة'),
    BusColumnItem(key: 'phone', label: 'هاتف ولي الأمر'),
    BusColumnItem(key: 'notes', label: 'ملاحظات'),
    BusColumnItem(key: 'delivered', label: 'تم التوصيل'),
  ];

  static Future<pw.Font> _getRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    _cachedRegularFont = pw.Font.ttf(fontData);
    return _cachedRegularFont!;
  }

  static Future<pw.Font> _getBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    final fontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    _cachedBoldFont = pw.Font.ttf(fontData);
    return _cachedBoldFont!;
  }

  /// Builds a PDF Document for a single bus driver.
  /// Automatically filters out any students who have left with their parent today.
  static Future<pw.Document> buildDriverPdfDocument({
    required BusDriverPdfData driver,
    required List<BusStudentPdfData> students,
    List<BusColumnItem>? customColumns,
    String? programName,
    String? churchName,
    Uint8List? churchLogo,
    DateTime? date,
    bool includeExcludedWithParent = false,
  }) async {
    final pdf = pw.Document();
    final regular = await _getRegularFont();
    final bold = await _getBoldFont();
    final currentDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

    pw.ImageProvider? logoImage;
    if (churchLogo != null && churchLogo.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(churchLogo);
      } catch (_) {}
    }

    // Filter out students who left with parent or other reason unless explicitly requested
    final activeStudents = includeExcludedWithParent
        ? students
        : students.where((s) => !s.isExcludedFromBusToday && !s.hasLeftWithParentToday).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(
          regular: regular,
          bold: bold,
          driver: driver,
          programName: programName ?? 'مدارس الأحد',
          churchName: churchName,
          logoImage: logoImage,
          dateStr: dateStr,
          totalStudents: activeStudents.length,
        ),
        footer: (context) => _buildFooter(regular, context.pageNumber, context.pagesCount),
        build: (context) => [
          _buildStudentsTable(regular, bold, activeStudents, customColumns),
        ],
      ),
    );

    return pdf;
  }

  /// Print or show preview for a single driver's bus sheet
  static Future<void> printDriverPdf({
    required BusDriverPdfData driver,
    required List<BusStudentPdfData> students,
    List<BusColumnItem>? customColumns,
    String? programName,
    String? churchName,
    Uint8List? churchLogo,
    DateTime? date,
  }) async {
    final pdf = await buildDriverPdfDocument(
      driver: driver,
      students: students,
      customColumns: customColumns,
      programName: programName,
      churchName: churchName,
      churchLogo: churchLogo,
      date: date,
    );

    final cleanDriverName = driver.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = 'أتوبيس - $cleanDriverName.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: fileName,
    );
  }

  /// Export all drivers to separate PDF files into a target directory.
  /// Each file is named after the driver: e.g. "أتوبيس - [اسم السائق].pdf".
  static Future<List<String>> exportAllDriversToSeparateFiles({
    required Directory targetDir,
    required Map<BusDriverPdfData, List<BusStudentPdfData>> driverStudentsMap,
    List<BusColumnItem>? customColumns,
    String? programName,
    String? churchName,
    Uint8List? churchLogo,
    DateTime? date,
  }) async {
    final generatedPaths = <String>[];

    for (final entry in driverStudentsMap.entries) {
      final driver = entry.key;
      final students = entry.value;

      final pdf = await buildDriverPdfDocument(
        driver: driver,
        students: students,
        customColumns: customColumns,
        programName: programName,
        churchName: churchName,
        churchLogo: churchLogo,
        date: date,
      );

      final cleanDriverName = driver.name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = cleanDriverName.isEmpty ? 'أتوبيس_سائق_${driver.id}.pdf' : 'أتوبيس - $cleanDriverName.pdf';
      final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);
      generatedPaths.add(file.path);
    }

    return generatedPaths;
  }

  static pw.Widget _buildHeader({
    required pw.Font regular,
    required pw.Font bold,
    required BusDriverPdfData driver,
    required String programName,
    String? churchName,
    pw.ImageProvider? logoImage,
    required String dateStr,
    required int totalStudents,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo900, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.indigo50,
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 44,
                  height: 44,
                  child: pw.Image(logoImage),
                )
              else
                pw.SizedBox(width: 44),
              pw.Column(
                children: [
                  pw.Text(
                    programName,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 16,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  if (churchName != null && churchName.isNotEmpty)
                    pw.Text(
                      churchName,
                      style: pw.TextStyle(
                        font: regular,
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  pw.Text(
                    'كشف توصيل أتوبيس الطلاب',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 14,
                      color: PdfColors.indigo800,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'التاريخ: $dateStr',
                      style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.indigo900),
                    ),
                    pw.Text(
                      'العدد: $totalStudents طالب',
                      style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.green800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.indigo200, thickness: 0.8),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'السائق: ', style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.indigo900)),
                    pw.TextSpan(text: driver.name, style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.black)),
                  ],
                ),
              ),
              if (driver.phone != null && driver.phone!.isNotEmpty)
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'الهاتف: ', style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.indigo900)),
                      pw.TextSpan(text: driver.phone!, style: pw.TextStyle(font: regular, fontSize: 11)),
                    ],
                  ),
                ),
              if (driver.busNumber != null && driver.busNumber!.isNotEmpty)
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'الأتوبيس / خط السير: ', style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.indigo900)),
                      pw.TextSpan(text: driver.busNumber!, style: pw.TextStyle(font: regular, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.TableColumnWidth _getWidthForColumn(String colKey) {
    switch (colKey) {
      case 'index':
        return const pw.FixedColumnWidth(28);
      case 'code':
        return const pw.FixedColumnWidth(42);
      case 'name':
        return const pw.FlexColumnWidth(3.2);
      case 'stage':
        return const pw.FlexColumnWidth(1.8);
      case 'khoros':
        return const pw.FlexColumnWidth(1.6);
      case 'address':
        return const pw.FlexColumnWidth(2.6);
      case 'phone':
        return const pw.FlexColumnWidth(2.0);
      case 'notes':
        return const pw.FlexColumnWidth(2.0);
      case 'delivered':
        return const pw.FixedColumnWidth(65);
      default:
        return const pw.FlexColumnWidth(1.5);
    }
  }

  static pw.Widget _buildCellForColumn({
    required String colKey,
    required int index,
    required BusStudentPdfData student,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    switch (colKey) {
      case 'index':
        return pw.Text('${index + 1}', style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.center);
      case 'code':
        return pw.Text('${student.personId}', style: pw.TextStyle(font: regular, fontSize: 10), textAlign: pw.TextAlign.center);
      case 'name':
        return pw.Text(student.personName, style: pw.TextStyle(font: bold, fontSize: 10));
      case 'stage':
        return pw.Text(student.stageName ?? '-', style: pw.TextStyle(font: regular, fontSize: 9));
      case 'khoros':
        return pw.Text(student.khorosName ?? '-', style: pw.TextStyle(font: regular, fontSize: 9));
      case 'address':
        final location = [student.areaName, student.street].where((x) => x != null && x.isNotEmpty).join(' - ');
        return pw.Text(location.isEmpty ? '-' : location, style: pw.TextStyle(font: regular, fontSize: 9));
      case 'phone':
        final contact = (student.mobile != null && student.mobile!.isNotEmpty) ? student.mobile! : (student.phone ?? '-');
        return pw.Text(contact, style: pw.TextStyle(font: regular, fontSize: 9), textAlign: pw.TextAlign.center);
      case 'notes':
        return pw.Text(student.notes ?? '-', style: pw.TextStyle(font: regular, fontSize: 9));
      case 'delivered':
        return pw.Center(
          child: pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 1.2),
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
        );
      default:
        return pw.SizedBox();
    }
  }

  static pw.Widget _buildStudentsTable(
    pw.Font regular,
    pw.Font bold,
    List<BusStudentPdfData> students, [
    List<BusColumnItem>? customColumns,
  ]) {
    if (students.isEmpty) {
      return pw.Center(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Text(
            'لا يوجد طلاب مرتبطين بهذا السائق، أو تم استبعادهم لانصرافهم اليوم.',
            style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.grey600),
          ),
        ),
      );
    }

    final activeCols = (customColumns ?? defaultColumns).where((c) => c.isVisible).toList();
    if (activeCols.isEmpty) {
      return pw.Center(
        child: pw.Text('يرجى تحديد عمود واحد على الأقل للعرض', style: pw.TextStyle(font: bold, fontSize: 12)),
      );
    }

    // IMPORTANT FOR ARABIC RTL:
    // pw.Table renders column 0 on the far LEFT and the last column on the far RIGHT.
    // In Arabic RTL, reading begins from the far RIGHT margin.
    // Therefore, to make the first column (e.g. 'م') appear on the far RIGHT,
    // and the last column (e.g. 'تم التوصيل') on the far LEFT,
    // we reverse the list for pw.Table.
    final colsForPdf = activeCols.reversed.toList();

    final colWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < colsForPdf.length; i++) {
      colWidths[i] = _getWidthForColumn(colsForPdf[i].key);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: colWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo800),
          children: colsForPdf.map((c) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: pw.Text(
                c.label,
                style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        ...students.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final isEven = idx % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: colsForPdf.map((c) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: _buildCellForColumn(
                  colKey: c.key,
                  index: idx,
                  student: s,
                  regular: regular,
                  bold: bold,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font regular, int pageNumber, int totalPages) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'برنامج إدارة مدارس الأحد',
            style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'صفحة $pageNumber من $totalPages',
            style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
