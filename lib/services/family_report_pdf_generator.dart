import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' hide TextDirection;

class FamilyReportPdfGenerator {
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Font> _getRegularFont() async {
    if (_cachedRegularFont != null) return _cachedRegularFont!;
    final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
    _cachedRegularFont = pw.Font.ttf(fontData);
    return _cachedRegularFont!;
  }

  static Future<pw.Font> _getBoldFont() async {
    if (_cachedBoldFont != null) return _cachedBoldFont!;
    final fontData = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
    _cachedBoldFont = pw.Font.ttf(fontData);
    return _cachedBoldFont!;
  }

  static Future<void> generateAndPrint({
    required List<Map<String, dynamic>> groups,
    required String title,
    String? churchName,
    Uint8List? churchLogo,
    Map<String, String>? headerData,
    List<String>? selectedColumns,
    List<String>? sortingCriteria,
  }) async {
    final pdf = pw.Document();
    final regular = await _getRegularFont();
    final bold = await _getBoldFont();

    pw.ImageProvider? churchLogoImage;
    if (churchLogo != null) {
      try { churchLogoImage = pw.MemoryImage(churchLogo); } catch (_) {}
    }

    final sortedGroups = List<Map<String, dynamic>>.from(groups);
    if (sortingCriteria != null && sortingCriteria.isNotEmpty) {
      sortedGroups.sort((a, b) {
        for (var criterion in sortingCriteria) {
          int cmp = 0;
          if (criterion == 'name') {
            cmp = (a['headName'] as String).compareTo(b['headName'] as String);
          } else {
            // Check personData if available
            final childrenA = a['children'] as List?;
            final childrenB = b['children'] as List?;
            final pA = a['personData'] ?? ((childrenA != null && childrenA.isNotEmpty) ? childrenA[0]['personData'] : null);
            final pB = b['personData'] ?? ((childrenB != null && childrenB.isNotEmpty) ? childrenB[0]['personData'] : null);
            
            if (pA != null && pB != null) {
               try {
                 if (criterion == 'area') cmp = (pA.areaName ?? '').compareTo(pB.areaName ?? '');
                 else if (criterion == 'stage') cmp = (pA.stageName ?? '').compareTo(pB.stageName ?? '');
                 else if (criterion == 'father') cmp = (pA.fatherName ?? '').compareTo(pB.fatherName ?? '');
               } catch (_) {}
            }
          }
          if (cmp != 0) return cmp;
        }
        return 0;
      });
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: (selectedColumns?.length ?? 0) > 6 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(regular, bold, title, churchName, churchLogoImage, headerData),
        footer: (context) => _buildFooter(regular, bold, context.pageNumber, context.pagesCount),
        build: (context) => [
          ...sortedGroups.expand((group) => _buildFamilyGroup(regular, bold, group, selectedColumns)),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Family_Relationships_Report.pdf',
    );
  }

  static pw.Widget _buildHeader(pw.Font font, pw.Font boldFont, String title, String? churchName, pw.ImageProvider? logo, Map<String, String>? headerData) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null) pw.Image(logo, width: 45, height: 45) else pw.SizedBox(width: 45),
              pw.Column(
                children: [
                  pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
                  if (churchName != null) pw.Text(churchName, style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
              pw.SizedBox(width: 45),
            ],
          ),
          if (headerData != null && headerData.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 15,
              runSpacing: 5,
              alignment: pw.WrapAlignment.center,
              children: headerData.entries.map((e) => pw.Text(
                '${e.key}: ${e.value}', 
                style: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)
              )).toList(),
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('تاريخ الاستخراج: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
              pw.Text('نظام إدارة صلات القرابة والترابط العائلي', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        ],
      ),
    );
  }

  static Iterable<pw.Widget> _buildFamilyGroup(pw.Font font, pw.Font boldFont, Map<String, dynamic> group, List<String>? selectedColumns) sync* {
    final children = group['children'] as List<dynamic>;
    final p = group['personData']; // The head's person data
    
    // Head of Family Row (Now its own top-level widget in MultiPage)
    yield pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border(right: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8, height: 8,
                decoration: const pw.BoxDecoration(color: PdfColors.blue700, shape: pw.BoxShape.circle),
              ),
              pw.SizedBox(width: 10),
              pw.Text(group['headName'], style: pw.TextStyle(font: boldFont, fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Spacer(),
              pw.Text('كود: ${group['headId']}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
          if (selectedColumns != null && selectedColumns.isNotEmpty && p != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6, right: 18),
              child: _buildDetailsGrid(font, boldFont, p, selectedColumns),
            ),
        ],
      ),
    );

    // Recursive Tree Nodes (Flattened into the top-level list)
    for (var child in children) {
      yield* _buildNode(font, boldFont, child, 0, selectedColumns);
    }
    
    // Bottom separator
    yield pw.SizedBox(height: 5);
    yield pw.Divider(color: PdfColors.grey200, thickness: 0.5, indent: 20);
  }

  static Iterable<pw.Widget> _buildNode(pw.Font font, pw.Font boldFont, Map<String, dynamic> node, int level, List<String>? selectedColumns) sync* {
    final children = node['children'] as List<dynamic>;
    final p = node['personData']; // PersonListDTO
    
    yield pw.Padding(
      padding: pw.EdgeInsets.only(right: 20.0 * level, top: 2, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildTreeLine(level == 0),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(node['name'], style: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Spacer(),
                      pw.Text('كود: ${node['id']}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Text(
                    node['parentName'].isEmpty ? node['code'] : "${node['code']} (${node['parentName']})",
                    style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.blue800),
                  ),
                  if (selectedColumns != null && selectedColumns.isNotEmpty && p != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: _buildDetailsGrid(font, boldFont, p, selectedColumns),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Flatten children
    for (var child in children) {
      yield* _buildNode(font, boldFont, child, level + 1, selectedColumns);
    }
  }

  static pw.Widget _buildDetailsGrid(pw.Font font, pw.Font boldFont, dynamic p, List<String> columns) {
    // Filter columns to only show specific person details (not name/id which are already in head)
    final filteredCols = columns.where((c) => !['name', 'id', 'relationship'].contains(c)).toList();
    if (filteredCols.isEmpty) return pw.SizedBox();

    return pw.Wrap(
      spacing: 15,
      runSpacing: 6,
      children: filteredCols.map((colId) {
        String label = _getColLabel(colId);
        String value = _getColValue(p, colId);
        if (value.isEmpty) return pw.SizedBox();
        
        return pw.Text(
          '$label: $value',
          style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.black),
        );
      }).toList(),
    );
  }

  static String _getColLabel(String id) {
    switch (id) {
      case 'area': return 'المنطقة';
      case 'stage': return 'المرحلة';
      case 'father': return 'أب الاعتراف';
      case 'mobile': return 'موبايل';
      case 'phone': return 'تليفون';
      case 'address': return 'العنوان';
      case 'gender': return 'النوع';
      case 'birthday': return 'الميلاد';
      default: return id;
    }
  }

  static String _getColValue(dynamic p, String id) {
    switch (id) {
      case 'area': return p.areaName ?? '';
      case 'stage': return p.stageName ?? '';
      case 'father': return p.fatherName ?? '';
      case 'mobile': return p.mobile ?? '';
      case 'phone': return p.phone ?? '';
      case 'address': return p.streetName ?? '';
      case 'gender': return p.jenderName ?? '';
      case 'birthday': return (p.day != null) ? '${p.year ?? ""}-${p.month}-${p.day}' : '';
      default: return '';
    }
  }

  static pw.Widget _buildTreeLine(bool isMain) {
    return pw.Container(
      width: 12,
      height: 20,
      child: pw.CustomPaint(
        size: const PdfPoint(12, 20),
        painter: (PdfGraphics canvas, PdfPoint size) {
          canvas
            ..setColor(PdfColors.grey400)
            ..setLineWidth(0.8)
            // Vertical line
            ..moveTo(size.x, size.y)
            ..lineTo(size.x, isMain ? size.y / 2 : 0)
            // Horizontal line
            ..moveTo(size.x, size.y / 2)
            ..lineTo(0, size.y / 2)
            ..strokePath();
        },
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font, pw.Font boldFont, int page, int total) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 5),
          pw.Text('صفحة $page من $total', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
