import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/pdf_export_options.dart';
import '../repositories/persons_repository.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'pdf_generation_task.dart';

class SinglePersonReportField {
  const SinglePersonReportField({required this.label, required this.value});

  final String label;
  final String value;
}

class SinglePersonReportDocument {
  const SinglePersonReportDocument({
    required this.fieldName,
    required this.fileName,
    required this.fileContent,
    required this.createdAt,
  });

  final String fieldName;
  final String fileName;
  final Uint8List fileContent;
  final DateTime createdAt;

  bool get isImage {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}

class _PersonPdfRequest {
  const _PersonPdfRequest({
    required this.data,
    required this.sortingCriteria,
    required this.columns,
    required this.title,
    required this.headerData,
    required this.churchLogo,
    required this.khorosLogo,
    required this.churchName,
    required this.regularBytes,
    required this.boldBytes,
    required this.exportOptions,
  });

  final List<PersonListDTO> data;
  final List<String> sortingCriteria;
  final List<Map<String, String>> columns;
  final String? title;
  final Map<String, String>? headerData;
  final Uint8List? churchLogo;
  final Uint8List? khorosLogo;
  final String? churchName;
  final Uint8List regularBytes;
  final Uint8List boldBytes;
  final PdfExportOptions exportOptions;
}

Future<void> _personPdfEntryPoint(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  final request = message[1] as _PersonPdfRequest;
  try {
    final bytes = await PersonReportService._buildPDF(
      data: request.data,
      sortingCriteria: request.sortingCriteria,
      columns: request.columns,
      title: request.title,
      headerData: request.headerData,
      churchLogo: request.churchLogo,
      khorosLogo: request.khorosLogo,
      churchName: request.churchName,
      regularBytes: request.regularBytes,
      boldBytes: request.boldBytes,
      reporter: reporter,
      exportOptions: request.exportOptions,
    );
    reporter.complete(bytes);
  } catch (error, stackTrace) {
    reporter.fail(error, stackTrace);
  }
}

class PersonReportService {
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
    required List<PersonListDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final task = await startPDFGeneration(
      data: data,
      sortingCriteria: sortingCriteria,
      columns: columns,
      title: title,
      headerData: headerData,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      exportOptions: exportOptions,
    );
    return task.result;
  }

  static Future<Uint8List> generateSinglePersonPDF({
    required PersonListDTO person,
    required List<SinglePersonReportField> fields,
    List<SinglePersonReportDocument> documents = const [],
    String? serviceName,
    Uint8List? serviceLogo,
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();
    final regular = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));
    final pdf = pw.Document();

    pw.ImageProvider? personPhoto;
    if (person.photo != null && person.photo!.isNotEmpty) {
      try {
        personPhoto = pw.MemoryImage(person.photo!);
      } catch (_) {}
    }

    pw.ImageProvider? serviceLogoImage;
    if (serviceLogo != null && serviceLogo.isNotEmpty) {
      try {
        serviceLogoImage = pw.MemoryImage(serviceLogo);
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (_) => _buildSinglePersonHeader(
          regular,
          bold,
          person,
          serviceName,
          serviceLogoImage,
        ),
        footer: (context) =>
            _buildFooter(regular, bold, context.pageNumber, context.pagesCount),
        build: (_) => [
          _buildSinglePersonSummary(regular, bold, person, fields, personPhoto),
          if (documents.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _buildDocumentsList(regular, bold, documents),
          ],
        ],
      ),
    );

    final imageDocuments = documents.where((document) => document.isImage);
    for (final document in imageDocuments) {
      try {
        final image = pw.MemoryImage(document.fileContent);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            theme: pw.ThemeData.withFont(base: regular, bold: bold),
            textDirection: pw.TextDirection.rtl,
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  '${document.fieldName} - ${document.fileName}',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 16,
                    color: PdfColors.blue900,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (_) {}
    }

    return pdf.save();
  }

  static Future<Uint8List> generateMultiplePeopleFormsPDF({
    required List<PersonListDTO> persons,
    required List<List<SinglePersonReportField>> fieldsList,
    required List<List<SinglePersonReportDocument>> documentsList,
    String? serviceName,
    Uint8List? serviceLogo,
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();
    final regular = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));
    final pdf = pw.Document();

    pw.ImageProvider? serviceLogoImage;
    if (serviceLogo != null && serviceLogo.isNotEmpty) {
      try {
        serviceLogoImage = pw.MemoryImage(serviceLogo);
      } catch (_) {}
    }

    for (int i = 0; i < persons.length; i++) {
      final person = persons[i];
      final fields = fieldsList[i];
      final documents = documentsList[i];

      pw.ImageProvider? personPhoto;
      if (person.photo != null && person.photo!.isNotEmpty) {
        try {
          personPhoto = pw.MemoryImage(person.photo!);
        } catch (_) {}
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          textDirection: pw.TextDirection.rtl,
          header: (_) => _buildSinglePersonHeader(
            regular,
            bold,
            person,
            serviceName,
            serviceLogoImage,
          ),
          footer: (context) => _buildFooter(
            regular,
            bold,
            context.pageNumber,
            context.pagesCount,
          ),
          build: (_) => [
            _buildSinglePersonSummary(
              regular,
              bold,
              person,
              fields,
              personPhoto,
            ),
            if (documents.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _buildDocumentsList(regular, bold, documents),
            ],
          ],
        ),
      );

      final imageDocuments = documents.where((document) => document.isImage);
      for (final document in imageDocuments) {
        try {
          final image = pw.MemoryImage(document.fileContent);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(28),
              theme: pw.ThemeData.withFont(base: regular, bold: bold),
              textDirection: pw.TextDirection.rtl,
              build: (_) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    '${document.fieldName} - ${document.fileName}',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 16,
                      color: PdfColors.blue900,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (_) {}
      }
    }

    return pdf.save();
  }

  static Future<PdfGenerationTask> startPDFGeneration({
    required List<PersonListDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final regularBytes = await _getRegularFontBytes();
    final boldBytes = await _getBoldFontBytes();

    return PdfGenerationTask.start(
      _personPdfEntryPoint,
      _PersonPdfRequest(
        data: data,
        sortingCriteria: sortingCriteria,
        columns: columns,
        title: title,
        headerData: headerData,
        churchLogo: churchLogo,
        khorosLogo: khorosLogo,
        churchName: churchName,
        regularBytes: regularBytes,
        boldBytes: boldBytes,
        exportOptions: exportOptions,
      ),
    );
  }

  static Future<Uint8List> _buildPDF({
    required List<PersonListDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    required Uint8List regularBytes,
    required Uint8List boldBytes,
    required PdfGenerationReporter reporter,
    required PdfExportOptions exportOptions,
  }) async {
    final pdf = pw.Document();
    final regular = pw.Font.ttf(ByteData.sublistView(regularBytes));
    final bold = pw.Font.ttf(ByteData.sublistView(boldBytes));

    // Sort the data based on user criteria
    final sortedData = List<PersonListDTO>.from(data);
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
          title ?? 'قائمة الأشخاص',
          headerData,
          churchLogoImage,
          khorosLogoImage,
          churchName,
        ),
        build: (context) => _buildContent(
          regular,
          bold,
          sortedData,
          sortingCriteria,
          columns,
          reporter,
          tableFontSize,
        ),
        footer: (context) =>
            _buildFooter(regular, bold, context.pageNumber, context.pagesCount),
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrintPDF({
    required List<PersonListDTO> data,
    required List<String> sortingCriteria,
    required List<Map<String, String>> columns,
    String? title,
    Map<String, String>? headerData,
    Uint8List? churchLogo,
    Uint8List? khorosLogo,
    String? churchName,
    PdfExportOptions exportOptions = const PdfExportOptions(),
  }) async {
    final bytes = await generatePDF(
      data: data,
      sortingCriteria: sortingCriteria,
      columns: columns,
      title: title,
      headerData: headerData,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: churchName,
      exportOptions: exportOptions,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Persons_List.pdf',
    );
  }

  static pw.Widget _buildSinglePersonHeader(
    pw.Font font,
    pw.Font boldFont,
    PersonListDTO person,
    String? serviceName,
    pw.ImageProvider? serviceLogo,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (serviceLogo != null)
                pw.Image(serviceLogo, width: 56, height: 56)
              else
                pw.SizedBox(width: 56),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      person.name,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 24,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (serviceName != null && serviceName.trim().isNotEmpty)
                      pw.Text(
                        serviceName.trim(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 56),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'تاريخ الطباعة: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
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

  static pw.Widget _buildSinglePersonSummary(
    pw.Font font,
    pw.Font boldFont,
    PersonListDTO person,
    List<SinglePersonReportField> fields,
    pw.ImageProvider? personPhoto,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildSinglePersonFieldsTable(font, boldFont, fields),
            ),
            pw.SizedBox(width: 14),
            pw.Container(
              width: 112,
              height: 140,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: personPhoto == null
                  ? pw.Center(
                      child: pw.Text(
                        person.id.toString(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          color: PdfColors.blue900,
                        ),
                      ),
                    )
                  : pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(personPhoto, fit: pw.BoxFit.cover),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSinglePersonFieldsTable(
    pw.Font font,
    pw.Font boldFont,
    List<SinglePersonReportField> fields,
  ) {
    final rows = fields.isEmpty
        ? const [SinglePersonReportField(label: 'البيانات', value: '-')]
        : fields;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(5), 1: pw.FlexColumnWidth(2)},
      children: rows.map((field) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                field.value.trim().isEmpty ? '-' : field.value,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ),
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                field.label,
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildDocumentsList(
    pw.Font font,
    pw.Font boldFont,
    List<SinglePersonReportDocument> documents,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'المرفقات',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(4),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _documentCell('التاريخ', boldFont, bold: true),
                _documentCell('الحجم', boldFont, bold: true),
                _documentCell('اسم الملف', boldFont, bold: true),
                _documentCell('الحقل', boldFont, bold: true),
              ],
            ),
            for (final document in documents)
              pw.TableRow(
                children: [
                  _documentCell(
                    DateFormat('yyyy-MM-dd').format(document.createdAt),
                    font,
                  ),
                  _documentCell(
                    _formatBytes(document.fileContent.length),
                    font,
                  ),
                  _documentCell(document.fileName, font),
                  _documentCell(document.fieldName, font),
                ],
              ),
          ],
        ),
        if (documents.any((document) => document.isImage)) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'الصور المرفقة تظهر في الصفحات التالية.',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _documentCell(
    String value,
    pw.Font font, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  static pw.Widget _buildHeader(
    pw.Font font,
    pw.Font boldFont,
    String title,
    Map<String, String>? headerData,
    pw.ImageProvider? churchLogo,
    pw.ImageProvider? khorosLogo,
    String? churchName,
  ) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (khorosLogo != null)
                pw.Image(khorosLogo, width: 50, height: 50)
              else
                pw.SizedBox(width: 50),
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
              if (churchLogo != null)
                pw.Image(churchLogo, width: 50, height: 50)
              else
                pw.SizedBox(width: 50),
            ],
          ),
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
    List<PersonListDTO> data,
    List<String> criteria,
    List<Map<String, String>> columns,
    PdfGenerationReporter reporter,
    double tableFontSize,
  ) {
    if (data.isEmpty)
      return [
        pw.Center(
          child: pw.Text('لا توجد بيانات', style: pw.TextStyle(font: font)),
        ),
      ];

    final widgets = <pw.Widget>[];
    final Map<String, String?> currentValues = {};
    for (var c in criteria) currentValues[c] = null;
    var nextRowNumber = 0;
    int allocateRowNumber() => ++nextRowNumber;

    List<PersonListDTO> currentGroup = [];

    void flushGroup(PersonListDTO? nextRecord) {
      if (currentGroup.isNotEmpty) {
        widgets.add(
          _buildTable(
            font,
            boldFont,
            currentGroup,
            columns,
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

      bool levelChanged = false;
      for (var i = 0; i < criteria.length; i++) {
        final cid = criteria[i];
        if (cid == 'name') continue;

        final val = _getValue(nextRecord, cid);
        if (levelChanged || val != currentValues[cid]) {
          levelChanged = true;
          currentValues[cid] = val;

          for (var j = i + 1; j < criteria.length; j++) {
            currentValues[criteria[j]] = null;
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
      if (needsFlush) flushGroup(r);
      currentGroup.add(r);
    }

    if (currentGroup.isNotEmpty) {
      widgets.add(
        _buildTable(
          font,
          boldFont,
          currentGroup,
          columns,
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

  static String? _getValue(PersonListDTO r, String id) {
    if (id == 'area') return r.areaName;
    if (id == 'stage') return r.stageName;
    if (id == 'father') return r.fatherName;
    if (id == 'khoros') return r.khorosName;
    if (id == 'name') return r.name;
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
    List<PersonListDTO> data,
    List<Map<String, String>> columns,
    PdfGenerationReporter reporter,
    int total,
    int Function() allocateRowNumber,
    double tableFontSize,
  ) {
    final rtlColumns = columns
        .where((col) {
          final id = col['id'] ?? '';
          return !id.startsWith('call_') && !id.startsWith('whatsapp_');
        })
        .toList()
        .reversed
        .toList();

    String valueFor(PersonListDTO r, String columnId) {
      switch (columnId) {
        case 'name':
          return r.name;
        case 'id':
          return r.id.toString();
        case 'area':
          return r.areaName;
        case 'stage':
          return r.stageName;
        case 'father':
          return r.fatherName;
        case 'mobile':
          return r.mobile;
        case 'phone':
          return r.phone;
        case 'street':
        case 'address':
          return r.streetName;
        case 'gender':
          return r.jenderName ?? '';
        case 'birthday':
          return (r.day != null && r.month != null)
              ? '${r.year ?? ""}-${r.month}-${r.day}'
              : '';
        case 'relationship':
          return r.relationship ?? '';
        default:
          if (columnId.startsWith('custom_')) {
            return _getValue(r, columnId) ?? '';
          }
          return '';
      }
    }

    pw.Widget buildCell(PersonListDTO r, Map<String, String> col, int rowNumber) {
      if ((col['id'] ?? '') == 'done_checkbox') {
        return _buildDoneCheckbox('done_${r.id}_$rowNumber');
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
                'جاري رسم بيانات الأشخاص داخل ملف PDF...',
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
