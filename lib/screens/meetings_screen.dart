import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../repositories/settings_repository.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingRecord {
  const _MeetingRecord({
    required this.sector,
    required this.date,
    required this.lessons,
  });

  final String sector;
  final DateTime date;
  final List<String> lessons;

  Map<String, dynamic> toJson() => {
    'sector': sector,
    'date': DateFormat('yyyy-MM-dd').format(date),
    'lessons': lessons,
  };

  factory _MeetingRecord.fromJson(Map<String, dynamic> json) {
    return _MeetingRecord(
      sector: json['sector'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      lessons:
          (json['lessons'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  static const _storageKey = 'meetings_records_json';

  final _sectorController = TextEditingController();
  final List<TextEditingController> _lessonControllers = [
    TextEditingController(),
  ];
  final _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime _selectedDate = DateTime.now();
  List<_MeetingRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sectorController.dispose();
    for (final controller in _lessonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await ref
        .read(settingsRepositoryProvider)
        .getSetting(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      _records = decoded
          .whereType<Map>()
          .map(
            (item) => _MeetingRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(
          _storageKey,
          jsonEncode(_records.map((record) => record.toJson()).toList()),
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _addRecord() async {
    final sector = _sectorController.text.trim();
    final lessons = _lessonControllers
        .map((controller) => controller.text.trim())
        .where((lesson) => lesson.isNotEmpty)
        .toList();
    if (sector.isEmpty || lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب القطاع ودرس واحد على الأقل')),
      );
      return;
    }

    setState(() {
      _records.insert(
        0,
        _MeetingRecord(sector: sector, date: _selectedDate, lessons: lessons),
      );
      _sectorController.clear();
      for (final controller in _lessonControllers) {
        controller.dispose();
      }
      _lessonControllers
        ..clear()
        ..add(TextEditingController());
    });
    await _persist();
  }

  void _addLessonField() {
    setState(() => _lessonControllers.add(TextEditingController()));
  }

  Future<void> _deleteRecord(int index) async {
    setState(() => _records.removeAt(index));
    await _persist();
  }

  Future<void> _exportPdf() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد اجتماعات للتصدير')));
      return;
    }
    final bytes = await _buildPdf(_records);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'meetings_lessons.pdf',
    );
  }

  Future<Uint8List> _buildPdf(List<_MeetingRecord> records) async {
    final regular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(regular);
    final boldFont = pw.Font.ttf(bold);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final widgets = <pw.Widget>[];
    widgets.add(
      pw.Text(
        'تقرير الاجتماعات والدروس المشروحة',
        style: pw.TextStyle(font: boldFont, fontSize: 22),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // Chunk the records to avoid TooManyPagesException with large tables
    const int chunkSize = 30;
    for (int i = 0; i < records.length; i += chunkSize) {
      final end = (i + chunkSize < records.length) ? i + chunkSize : records.length;
      final chunk = records.sublist(i, end);

      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: const ['القطاع', 'التاريخ', 'الدروس'],
          data: chunk
              .map(
                (record) => [
                  record.sector,
                  _dateFormat.format(record.date),
                  record.lessons
                      .asMap()
                      .entries
                      .map((entry) {
                        return 'درس ${entry.key + 1}: ${entry.value}';
                      })
                      .join('\n'),
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(font: boldFont),
          cellStyle: pw.TextStyle(font: regularFont, fontSize: 11),
          cellAlignment: pw.Alignment.centerRight,
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE8EAF6),
          ),
        ),
      );
      if (end < records.length) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => widgets,
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildFormCard(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRecordsCard()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الاجتماعات',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              'تسجيل القطاعات وتاريخ الاجتماع والدروس المشروحة',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        );

        final exportBtn = FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('تصدير PDF'),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget,
              const SizedBox(height: 12),
              exportBtn,
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: titleWidget),
              exportBtn,
            ],
          );
        }
      },
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final sectorField = TextField(
                  controller: _sectorController,
                  decoration: const InputDecoration(
                    labelText: 'القطاع',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                );
                final datePickerField = InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'التاريخ',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_dateFormat.format(_selectedDate)),
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      sectorField,
                      const SizedBox(height: 12),
                      datePickerField,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: sectorField),
                      const SizedBox(width: 12),
                      Expanded(child: datePickerField),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _lessonControllers.length; i++) ...[
              TextField(
                controller: _lessonControllers[i],
                decoration: InputDecoration(
                  labelText: 'درس ${i + 1}',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _addLessonField,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة درس'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addRecord,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ الاجتماع'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsCard() {
    return Card(
      child: _records.isEmpty
          ? const Center(child: Text('لا توجد اجتماعات محفوظة'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final record = _records[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${record.lessons.length}'),
                  ),
                  title: Text(record.sector),
                  subtitle: Text(
                    '${_dateFormat.format(record.date)} - ${record.lessons.join('، ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'حذف',
                    onPressed: () => _deleteRecord(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
}
