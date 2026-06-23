import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../repositories/persons_repository.dart';
import '../repositories/settings_repository.dart';

class MonthlyFundScreen extends ConsumerStatefulWidget {
  const MonthlyFundScreen({super.key});

  @override
  ConsumerState<MonthlyFundScreen> createState() => _MonthlyFundScreenState();
}

class _MonthlyFundScreenState extends ConsumerState<MonthlyFundScreen> {
  static const _amountKey = 'monthly_fund_annual_amount';
  static const _paymentsKey = 'monthly_fund_payments_json';

  final _amountController = TextEditingController(text: '70');
  final _searchController = TextEditingController();
  final Map<int, TextEditingController> _paymentControllers = {};
  List<PersonListDTO> _persons = [];
  Map<int, double> _payments = {};
  String _search = '';
  bool _loading = true;

  double get _annualAmount => double.tryParse(_amountController.text) ?? 0;
  double get _totalPaid =>
      _payments.values.fold(0, (sum, value) => sum + value);
  double get _expectedTotal => _persons.length * _annualAmount;

  List<PersonListDTO> get _filteredPersons {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _persons;
    return _persons.where((person) {
      return person.name.toLowerCase().contains(query) ||
          person.id.toString().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final savedAmount = await settings.getSetting(_amountKey);
    if (savedAmount != null && savedAmount.trim().isNotEmpty) {
      _amountController.text = savedAmount;
    }

    final rawPayments = await settings.getSetting(_paymentsKey);
    if (rawPayments != null && rawPayments.trim().isNotEmpty) {
      final decoded = jsonDecode(rawPayments);
      if (decoded is Map) {
        _payments = decoded.map(
          (key, value) => MapEntry(
            int.tryParse(key.toString()) ?? 0,
            (value as num?)?.toDouble() ?? 0,
          ),
        )..removeWhere((key, value) => key == 0);
      }
    }

    _persons = await ref
        .read(personsRepositoryProvider.notifier)
        .fetchPersons(limit: null, offset: 0, includeServices: false);
    _syncControllers();
    if (mounted) setState(() => _loading = false);
  }

  void _syncControllers() {
    for (final person in _persons) {
      _paymentControllers.putIfAbsent(
        person.id,
        () => TextEditingController(
          text: (_payments[person.id] ?? 0).toStringAsFixed(0),
        ),
      );
    }
  }

  Future<void> _persistPayments() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(
          _paymentsKey,
          jsonEncode(
            _payments.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
  }

  Future<void> _saveAnnualAmount() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(_amountKey, _amountController.text.trim());
    setState(() {});
  }

  Future<void> _setPayment(int personId, String value) async {
    final parsed = double.tryParse(value.trim()) ?? 0;
    setState(() => _payments[personId] = parsed);
    await _persistPayments();
  }

  Future<void> _exportPdf() async {
    if (_persons.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد بيانات مخدومين لتصديرها في ملف PDF'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'monthly_fund.pdf',
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في تصدير PDF'),
            content: Text('حدث خطأ أثناء إنشاء أو طباعة الملف: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<Uint8List> _buildPdf() async {
    final regular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(regular);
    final boldFont = pw.Font.ttf(bold);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    final annual = _annualAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'تقرير الصندوق الشهري',
            style: pw.TextStyle(font: boldFont, fontSize: 22),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'المبلغ السنوي: ${annual.toStringAsFixed(2)} - الإجمالي المحصل: ${_totalPaid.toStringAsFixed(2)}',
            style: pw.TextStyle(font: boldFont),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: const ['الكود', 'الاسم', 'المدفوع', 'النسبة', 'تم السداد'],
            data: _persons.map((person) {
              final paid = _payments[person.id] ?? 0;
              final percent = annual <= 0
                  ? 0
                  : (paid / annual * 100).clamp(0, 100);
              return [
                person.id.toString(),
                person.name,
                paid.toStringAsFixed(2),
                '${percent.toStringAsFixed(0)}%',
                paid >= annual && annual > 0 ? 'نعم' : 'لا',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont, fontSize: 11),
            cellAlignment: pw.Alignment.centerRight,
            headerDirection: pw.TextDirection.rtl,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8EAF6),
            ),
          ),
        ],
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
                    _buildSummaryCard(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTable()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الصندوق الشهري',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'متابعة مدفوعات المخدومين وحساب الإجمالي ونسبة السداد',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('تصدير PDF'),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الصندوق الشهري',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'متابعة مدفوعات المخدومين وحساب الإجمالي ونسبة السداد',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('تصدير PDF'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final annual = _annualAmount;
    final percent = _expectedTotal <= 0
        ? 0
        : (_totalPaid / _expectedTotal * 100);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ السنوي',
                        suffixText: 'جنيه',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _saveAnnualAmount(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _saveAnnualAmount,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'عدد المخدومين',
                      value: _persons.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      label: 'الإجمالي المتوقع',
                      value: _expectedTotal.toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'الإجمالي المحصل',
                      value: _totalPaid.toStringAsFixed(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      label: 'نسبة التحصيل',
                      value: '${percent.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم أو الكود',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'المكتملون: ${_persons.where((p) => (_payments[p.id] ?? 0) >= annual && annual > 0).length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ السنوي',
                  suffixText: 'جنيه',
                ),
                onSubmitted: (_) => _saveAnnualAmount(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _saveAnnualAmount,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الرقم'),
            ),
            _StatTile(
              label: 'عدد المخدومين',
              value: _persons.length.toString(),
              width: 150,
            ),
            _StatTile(
              label: 'الإجمالي المتوقع',
              value: _expectedTotal.toStringAsFixed(2),
              width: 150,
            ),
            _StatTile(
              label: 'الإجمالي المحصل',
              value: _totalPaid.toStringAsFixed(2),
              width: 150,
            ),
            _StatTile(
              label: 'نسبة التحصيل',
              value: '${percent.toStringAsFixed(0)}%',
              width: 150,
            ),
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم أو الكود',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            Text(
              'المكتملون: ${_persons.where((p) => (_payments[p.id] ?? 0) >= annual && annual > 0).length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final persons = _filteredPersons;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      child: persons.isEmpty
          ? const Center(child: Text('لا توجد نتائج'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: persons.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final person = persons[index];
                final paid = _payments[person.id] ?? 0;
                final complete = _annualAmount > 0 && paid >= _annualAmount;
                final percent = _annualAmount <= 0
                    ? 0
                    : (paid / _annualAmount * 100).clamp(0, 100);
                final controller = _paymentControllers[person.id]!;
                return ListTile(
                  leading: Icon(
                    complete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: complete ? Colors.green : Colors.grey,
                  ),
                  title: Text(person.name),
                  subtitle: Text(
                    'كود: ${person.id} - ${person.stageName} - ${percent.toStringAsFixed(0)}%',
                  ),
                  trailing: SizedBox(
                    width: isMobile ? 100 : 140,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'المدفوع',
                        suffixText: 'ج',
                        isDense: true,
                      ),
                      onSubmitted: (value) => _setPayment(person.id, value),
                      onEditingComplete: () =>
                          _setPayment(person.id, controller.text),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.width});

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
