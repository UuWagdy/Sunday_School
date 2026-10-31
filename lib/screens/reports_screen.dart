import 'dart:typed_data';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../repositories/reports_repository.dart';
import '../repositories/fields_repository.dart';
import '../services/report_generator.dart';
import '../utils/silent_refresh_controller.dart';
import '../sync/data_change_domains.dart';
import '../sync/data_change_coordinator.dart';

class _ReportExecutedQuery {
  final String reportType;
  final int? stageId;
  final int? areaId;
  final int? month;
  final int? year;
  final String? status;
  final Map<int, dynamic> customFilters;

  const _ReportExecutedQuery({
    required this.reportType,
    this.stageId,
    this.areaId,
    this.month,
    this.year,
    this.status,
    required this.customFilters,
  });
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReport = 'persons';
  int? _selectedStageId;
  int? _selectedAreaId;
  int? _selectedMonth;
  int? _selectedYear;
  String? _selectedStatus;
  Map<int, dynamic> _customFilters = {};

  List<dynamic> _reportResults = [];
  bool _isLoading = false;
  bool _showPdfInsteadOfCards = false;

  _ReportExecutedQuery? _lastExecutedQuery;
  Future<Uint8List>? _pdfFuture;
  Uint8List? _previousPdf;
  int _pdfEpoch = 0;
  int _pdfVersion = 0;
  late final SilentRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = SilentRefreshController(
      debounceDuration: const Duration(milliseconds: 300),
      onRefresh: () async {
        final q = _lastExecutedQuery;
        final generation = _refreshController.currentGeneration;
        if (q == null || !mounted) return;
        final db = ref.read(appDatabaseProvider);
        try {
          List<dynamic> results = [];
          if (q.reportType == 'persons') {
            results = await _fetchPersonsData(db, q);
          } else if (q.reportType == 'attendance') {
            results = await _fetchAttendanceData(db, q);
          } else {
            results = await _fetchStatisticsData(db);
          }
          if (mounted &&
              generation == _refreshController.currentGeneration &&
              identical(q, _lastExecutedQuery)) {
            setState(() {
              _pdfFuture = null;
              _reportResults = results;
              _pdfVersion++;
            });
          }
        } catch (error) {
          debugPrint('تعذر تحديث التقرير في الخلفية: $error');
          rethrow;
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(sourceEpochProvider, (previous, next) {
      _refreshController.updateEpoch(next);
      setState(() {
        _reportResults = [];
        _pdfFuture = null;
        _previousPdf = null;
        _pdfEpoch++;
      });

      _refreshController.requestRefresh(immediate: true);
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.reports), (prev, next) {
      if (prev != null && prev != next) _refreshController.requestRefresh();
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.people), (prev, next) {
      if (prev != null && prev != next) _refreshController.requestRefresh();
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.attendance), (
      prev,
      next,
    ) {
      if (prev != null && prev != next) _refreshController.requestRefresh();
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.fields), (prev, next) {
      if (prev != null && prev != next) _refreshController.requestRefresh();
    });

    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isMobile
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildReportTypeSelector(),
                            const SizedBox(height: 16),
                            _buildFiltersArea(),
                            const SizedBox(height: 16),
                            Container(
                              height: 400, // Give results some space
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF151E2E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _showPdfInsteadOfCards
                                  ? _buildPdfPreview()
                                  : _buildResultsView(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildReportTypeSelector(),
                    const SizedBox(height: 16),
                    _buildFiltersArea(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _showPdfInsteadOfCards
                            ? _buildPdfPreview()
                            : _buildResultsView(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset('assets/logo.png', height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'التقارير والاستخراج',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'إصدار كشوف البيانات وسجلات الحضور',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_reportResults.isNotEmpty)
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                onPressed: () => setState(
                  () => _showPdfInsteadOfCards = !_showPdfInsteadOfCards,
                ),
                icon: Icon(
                  _showPdfInsteadOfCards
                      ? Icons.grid_view
                      : Icons.picture_as_pdf,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                tooltip: _showPdfInsteadOfCards ? 'عرض كروت' : 'معاينة PDF',
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: _printReport,
                icon: const Icon(Icons.print, size: 16),
                label: const Text('طباعة', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    final types = [
      (id: 'persons', label: 'الأشخاص', icon: Icons.people_outline),
      (id: 'attendance', label: 'الحضور', icon: Icons.calendar_month_outlined),
      (id: 'statistics', label: 'الإحصائيات', icon: Icons.analytics_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
      ),
      child: Row(
        children: types
            .map((type) => Expanded(child: _buildTypeItem(type)))
            .toList(),
      ),
    );
  }

  Widget _buildTypeItem(({String id, String label, IconData icon}) type) {
    final isSelected = _selectedReport == type.id;
    return GestureDetector(
      onTap: () => setState(() {
        _refreshController.bumpGeneration();
        _lastExecutedQuery = null;
        _pdfFuture = null;
        _previousPdf = null;
        _selectedReport = type.id;
        _selectedStageId = null;
        _selectedAreaId = null;
        _selectedMonth = null;
        _selectedYear = null;
        _selectedStatus = null;
        _customFilters = {};
        _reportResults = [];
        _showPdfInsteadOfCards = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersArea() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final db = ref.watch(appDatabaseProvider);
    List<Widget> filterWidgets = [];

    if (_selectedReport == 'persons') {
      filterWidgets = [
        _buildStageFilter(db, isMobile),
        const SizedBox(width: 12, height: 12),
        _buildAreaFilter(db, isMobile),
      ];
    } else if (_selectedReport == 'attendance') {
      filterWidgets = [
        _buildMonthFilter(isMobile),
        const SizedBox(width: 12, height: 12),
        _buildYearFilter(isMobile),
        const SizedBox(width: 12, height: 12),
        _buildStatusFilter(isMobile),
      ];
    } else {
      return const SizedBox.shrink();
    }

    // Add Dynamic Custom Filters
    final fieldsAsync = ref.watch(fieldsRepositoryProvider);
    if (fieldsAsync.hasValue) {
      final fields = fieldsAsync.value!
          .where((f) => f.isFilter && f.type != 'native')
          .toList();
      for (final f in fields) {
        if (f.type == 'multi_select') {
          filterWidgets.add(const SizedBox(height: 12));
          filterWidgets.add(_buildMultiSelectFilter(f));
        } else {
          filterWidgets.add(const SizedBox(width: 12, height: 12));
          filterWidgets.add(_buildCustomFilter(f));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...filterWidgets,
                  const SizedBox(height: 16),
                  _buildSearchButton(),
                ],
              )
            : Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  ...filterWidgets.map(
                    (w) => w is Expanded
                        ? w
                        : (w is SizedBox ? w : Expanded(child: w)),
                  ),
                  const SizedBox(width: 16),
                  _buildSearchButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildStageFilter(AppDatabase db, bool isMobile) {
    return FutureBuilder(
      future: db.select(db.stages).get(),
      builder: (context, snapshot) {
        final stages = snapshot.data ?? [];
        final hasSelected =
            _selectedStageId == null ||
            stages.any((s) => s.stageId == _selectedStageId);
        return DropdownButtonFormField<int?>(
          value: hasSelected ? _selectedStageId : null,
          decoration: const InputDecoration(
            labelText: 'تصفية بالمرحلة',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('كل المراحل'),
            ),
            ...stages.map(
              (s) => DropdownMenuItem<int?>(
                value: s.stageId,
                child: Text(s.stageName ?? ''),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedStageId = val),
        );
      },
    );
  }

  Widget _buildAreaFilter(AppDatabase db, bool isMobile) {
    return FutureBuilder(
      future: db.select(db.areas).get(),
      builder: (context, snapshot) {
        final areas = snapshot.data ?? [];
        final hasSelected =
            _selectedAreaId == null ||
            areas.any((a) => a.areaId == _selectedAreaId);
        return DropdownButtonFormField<int?>(
          value: hasSelected ? _selectedAreaId : null,
          decoration: const InputDecoration(
            labelText: 'تصفية بالمنطقة',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('كل المناطق'),
            ),
            ...areas.map(
              (a) => DropdownMenuItem<int?>(
                value: a.areaId,
                child: Text(a.areaName ?? ''),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedAreaId = val),
        );
      },
    );
  }

  Widget _buildMonthFilter(bool isMobile) {
    return DropdownButtonFormField<int?>(
      value: _selectedMonth,
      decoration: const InputDecoration(
        labelText: 'تصفية بالشهر',
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('كل الشهور')),
        ...List.generate(
          12,
          (i) =>
              DropdownMenuItem<int?>(value: i + 1, child: Text('شهر ${i + 1}')),
        ),
      ],
      onChanged: (val) => setState(() => _selectedMonth = val),
    );
  }

  Widget _buildYearFilter(bool isMobile) {
    return DropdownButtonFormField<int?>(
      value: _selectedYear,
      decoration: const InputDecoration(
        labelText: 'تصفية بالسنة',
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('كل السنوات')),
        ...List.generate(10, (i) {
          final year = DateTime.now().year - i;
          return DropdownMenuItem<int?>(value: year, child: Text('$year'));
        }),
      ],
      onChanged: (val) => setState(() => _selectedYear = val),
    );
  }

  Widget _buildCustomFilter(FieldConfigDTO f) {
    if (f.type == 'text') {
      return TextField(
        decoration: InputDecoration(
          labelText: f.name,
          isDense: true,
          suffixIcon: _customFilters[f.id]?.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _customFilters.remove(f.id)),
                )
              : null,
        ),
        onSubmitted: (v) => setState(() => _customFilters[f.id] = v),
      );
    } else if (f.type == 'dropdown') {
      return DropdownButtonFormField<String?>(
        value: _customFilters[f.id] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: f.name, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text('كل ${f.name}')),
          ...(((f.options as List<dynamic>?) ?? []).map(
            (opt) => DropdownMenuItem(
              value: opt.toString(),
              child: Text(opt.toString()),
            ),
          )),
        ],
        onChanged: (v) => setState(() {
          if (v == null)
            _customFilters.remove(f.id);
          else
            _customFilters[f.id] = v;
        }),
      );
    } else if (f.type == 'checkbox') {
      final optionsList = (f.options as List<dynamic>?) ?? [];
      final trueLabel = optionsList.isNotEmpty
          ? optionsList[0].toString()
          : 'نعم';
      final falseLabel = optionsList.length > 1
          ? optionsList[1].toString()
          : 'لا';
      return DropdownButtonFormField<String?>(
        value: _customFilters[f.id] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: f.name, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text('كل ${f.name}')),
          DropdownMenuItem(value: 'true', child: Text(trueLabel)),
          DropdownMenuItem(value: 'false', child: Text(falseLabel)),
        ],
        onChanged: (v) => setState(() {
          if (v == null)
            _customFilters.remove(f.id);
          else
            _customFilters[f.id] = v;
        }),
      );
    } else if (f.type == 'document') {
      return DropdownButtonFormField<String?>(
        value: _customFilters[f.id] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: f.name, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text('كل ${f.name}')),
          const DropdownMenuItem(value: 'has_files', child: Text('يوجد ملفات')),
          const DropdownMenuItem(
            value: 'no_files',
            child: Text('لا يوجد ملفات'),
          ),
        ],
        onChanged: (v) => setState(() {
          if (v == null)
            _customFilters.remove(f.id);
          else
            _customFilters[f.id] = v;
        }),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMultiSelectFilter(FieldConfigDTO f) {
    final selected = (_customFilters[f.id] as List<String>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: ((f.options as List<dynamic>?) ?? []).map((optDyn) {
            final opt = optDyn.toString();
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(
                opt,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (val) {
                setState(() {
                  final newList = List<String>.from(selected);
                  if (val)
                    newList.add(opt);
                  else
                    newList.remove(opt);
                  if (newList.isEmpty)
                    _customFilters.remove(f.id);
                  else
                    _customFilters[f.id] = newList;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'تصفية بالحالة',
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('الكل')),
        DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
        DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
        DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
        DropdownMenuItem(value: 'absent', child: Text('الغائبين')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedStatus = val);
      },
    );
  }

  Widget _buildSearchButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _onSearch,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.search),
      label: const Text('بحث'),
    );
  }

  Future<void> _onSearch() async {
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;
    final q = _ReportExecutedQuery(
      reportType: _selectedReport,
      stageId: _selectedStageId,
      areaId: _selectedAreaId,
      month: _selectedMonth,
      year: _selectedYear,
      status: _selectedStatus,
      customFilters: Map.from(_customFilters),
    );
    _lastExecutedQuery = q;
    _previousPdf = null;
    _pdfEpoch++;
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final List<dynamic> results = q.reportType == 'persons'
          ? await _fetchPersonsData(db, q)
          : q.reportType == 'attendance'
          ? await _fetchAttendanceData(db, q)
          : await _fetchStatisticsData(db);
      if (!mounted || generation != _refreshController.currentGeneration)
        return;
      setState(() {
        _reportResults = results;
        _pdfVersion++;
        _isLoading = false;
        _showPdfInsteadOfCards = false;
        _pdfFuture = null;
      });
    } catch (e) {
      if (!mounted || generation != _refreshController.currentGeneration)
        return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ أثناء البحث: $e')));
    }
  }

  Future<void> _printReport() async {
    if (_lastExecutedQuery == null || _reportResults.isEmpty) return;
    final snapshot = _pdfFuture ??= _renderPdfSnapshot(
      _lastExecutedQuery!.reportType,
      List.from(_reportResults),
    );
    final bytes = await snapshot;
    if (mounted) await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List> _renderPdfSnapshot(String type, List<dynamic> rows) async {
    final generation = _refreshController.currentGeneration;
    final version = _pdfVersion;
    final fields = ref.read(fieldsRepositoryProvider).value ?? [];
    final labels = {
      for (final f in fields)
        if (f.fieldKey != null) f.fieldKey!: f.name,
    };
    await ReportGenerator.loadFonts();
    final doc = type == 'persons'
        ? ReportGenerator.generatePersonsReport(
            rows.cast<PersonReportDTO>(),
            dynamicLabels: labels,
          )
        : type == 'attendance'
        ? ReportGenerator.generateAttendanceReport(
            rows.cast<AttendanceReportDTO>(),
          )
        : ReportGenerator.generateStatisticsReport(rows.cast<StageStatDTO>());
    final bytes = await doc.save();
    if (mounted &&
        generation == _refreshController.currentGeneration &&
        version == _pdfVersion)
      _previousPdf = bytes;
    return bytes;
  }

  Widget _buildResultsView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reportResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'لا توجد نتائج. اضغط بحث لعرض البيانات.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportResults.length,
      itemBuilder: (context, index) {
        final item = _reportResults[index];
        if (item is PersonReportDTO) {
          return _buildPersonCard(item);
        } else if (item is AttendanceReportDTO) {
          return _buildAttendanceCard(item);
        } else if (item is StageStatDTO) {
          return _buildStatCard(item);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPersonCard(PersonReportDTO p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          p.personName ?? 'بدون اسم',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  p.stageName ?? 'غير محدد',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.map_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  p.areaName ?? 'غير محدد',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (p.mobile != null && p.mobile!.isNotEmpty)
              Text(
                'موبايل: ${p.mobile}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceReportDTO a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withOpacity(0.1),
          child: Icon(
            Icons.event_available,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(
          a.personName ?? 'بدون اسم',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'التاريخ: ${a.dateWeek} | النقاط: ${a.point} | السلوك: ${a.behavior ?? 5}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${a.month}/${a.year}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(StageStatDTO s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
        title: Text(
          s.stageName ?? 'غير محدد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${s.count} شخص',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    final q = _lastExecutedQuery;
    if (q == null) return const Center(child: Text('نفّذ البحث أولًا'));
    _pdfFuture ??= _renderPdfSnapshot(q.reportType, List.from(_reportResults));
    return FutureBuilder<Uint8List>(
      key: ValueKey(_pdfEpoch),
      future: _pdfFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data ?? _previousPdf;
        if (bytes == null) {
          if (snapshot.hasError)
            return const Center(child: Text('تعذر تجهيز المعاينة'));
          return const Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: (_) async => bytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          maxPageWidth: 700,
          pdfFileName: '${q.reportType}_report.pdf',
        );
      },
    );
  }

  Future<List<PersonReportDTO>> _fetchPersonsData(
    AppDatabase db, [
    _ReportExecutedQuery? q,
  ]) async {
    final query = db.select(db.persons).join([
      leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
      leftOuterJoin(db.areas, db.areas.areaId.equalsExp(db.persons.areaId)),
    ]);

    final stageId = q != null ? q.stageId : _selectedStageId;
    final areaId = q != null ? q.areaId : _selectedAreaId;
    final filters = q != null ? q.customFilters : _customFilters;

    if (stageId != null) {
      query.where(db.persons.stageId.equals(stageId));
    }
    if (areaId != null) {
      query.where(db.persons.areaId.equals(areaId));
    }

    // Custom Filters
    for (final entry in filters.entries) {
      final val = entry.value;
      if (val == null) continue;

      if (val is String && (val == 'has_files' || val == 'no_files')) {
        final sub = db.selectOnly(db.personDocuments)
          ..addColumns([db.personDocuments.personId])
          ..where(db.personDocuments.fieldId.equals(entry.key));
        if (val == 'has_files') {
          query.where(
            existsQuery(
              sub..where(
                db.personDocuments.personId.equalsExp(db.persons.personId),
              ),
            ),
          );
        } else {
          query.where(
            notExistsQuery(
              sub..where(
                db.personDocuments.personId.equalsExp(db.persons.personId),
              ),
            ),
          );
        }
      } else if (val is String && val.isNotEmpty) {
        final sub = db.selectOnly(db.personCustomFieldValues)
          ..addColumns([db.personCustomFieldValues.personId])
          ..where(
            db.personCustomFieldValues.fieldId.equals(entry.key) &
                db.personCustomFieldValues.value.equals(val),
          );
        query.where(
          existsQuery(
            sub..where(
              db.personCustomFieldValues.personId.equalsExp(
                db.persons.personId,
              ),
            ),
          ),
        );
      } else if (val is List<String> && val.isNotEmpty) {
        final sub = db.selectOnly(db.personCustomFieldValues)
          ..addColumns([db.personCustomFieldValues.personId]);
        Expression<bool> orExpr = const Constant(false);
        for (final opt in val) {
          orExpr = orExpr | db.personCustomFieldValues.value.like('%$opt%');
        }
        sub.where(
          db.personCustomFieldValues.fieldId.equals(entry.key) & orExpr,
        );
        query.where(
          existsQuery(
            sub..where(
              db.personCustomFieldValues.personId.equalsExp(
                db.persons.personId,
              ),
            ),
          ),
        );
      }
    }

    final rows = await query.get();
    return rows.map((row) {
      final person = row.readTable(db.persons);
      final stage = row.readTableOrNull(db.stages);
      final area = row.readTableOrNull(db.areas);
      return PersonReportDTO(
        personId: person.personId,
        personName: person.personName,
        stageName: stage?.stageName,
        areaName: area?.areaName,
        streetName: person.streetName,
        phone: person.phone,
        mobile: person.mobile,
        jenderName: person.jenderName,
      );
    }).toList();
  }

  Future<List<AttendanceReportDTO>> _fetchAttendanceData(
    AppDatabase db, [
    _ReportExecutedQuery? q,
  ]) async {
    final query = db.select(db.coming).join([
      leftOuterJoin(
        db.persons,
        db.persons.personId.equalsExp(db.coming.personId),
      ),
    ]);

    final month = q != null ? q.month : _selectedMonth;
    final year = q != null ? q.year : _selectedYear;
    final status = q != null ? q.status : _selectedStatus;
    final filters = q != null ? q.customFilters : _customFilters;

    if (month != null) {
      query.where(db.coming.mont1.equals(month));
    }
    if (year != null) {
      query.where(db.coming.year1.equals(year));
    }

    if (status != null && status != 'all' && status != 'present') {
      if (status == 'checked_out') {
        query.where(db.coming.checkoutTime.isNotNull());
      } else if (status == 'complete') {
        query.where(
          db.coming.checkoutTime.isNotNull() & db.coming.attendTime.isNotNull(),
        );
      }
    }

    // Custom Filters (Join with persons already done implicity in attendance query logic if needed)
    // Here we need to join with persons to apply demographic custom filters if we are in attendance report too?
    // Usually attendance report filters by person demographics too.
    for (final entry in filters.entries) {
      final val = entry.value;
      if (val == null) continue;

      if (val is String && (val == 'has_files' || val == 'no_files')) {
        final sub = db.selectOnly(db.personDocuments)
          ..addColumns([db.personDocuments.personId])
          ..where(db.personDocuments.fieldId.equals(entry.key));
        if (val == 'has_files') {
          query.where(
            existsQuery(
              sub..where(
                db.personDocuments.personId.equalsExp(db.persons.personId),
              ),
            ),
          );
        } else {
          query.where(
            notExistsQuery(
              sub..where(
                db.personDocuments.personId.equalsExp(db.persons.personId),
              ),
            ),
          );
        }
      } else if (val is String && val.isNotEmpty) {
        final sub = db.selectOnly(db.personCustomFieldValues)
          ..addColumns([db.personCustomFieldValues.personId])
          ..where(
            db.personCustomFieldValues.fieldId.equals(entry.key) &
                db.personCustomFieldValues.value.equals(val),
          );
        query.where(
          existsQuery(
            sub..where(
              db.personCustomFieldValues.personId.equalsExp(
                db.persons.personId,
              ),
            ),
          ),
        );
      } else if (val is List<String> && val.isNotEmpty) {
        final sub = db.selectOnly(db.personCustomFieldValues)
          ..addColumns([db.personCustomFieldValues.personId]);
        Expression<bool> orExpr = const Constant(false);
        for (final opt in val) {
          orExpr = orExpr | db.personCustomFieldValues.value.like('%$opt%');
        }
        sub.where(
          db.personCustomFieldValues.fieldId.equals(entry.key) & orExpr,
        );
        query.where(
          existsQuery(
            sub..where(
              db.personCustomFieldValues.personId.equalsExp(
                db.persons.personId,
              ),
            ),
          ),
        );
      }
    }

    final rows = await query.get();
    return rows.map((row) {
      final coming = row.readTable(db.coming);
      final person = row.readTableOrNull(db.persons);
      return AttendanceReportDTO(
        personId: coming.personId,
        personName: person?.personName,
        dateWeek: coming.dateWeek,
        point: coming.point,
        month: coming.mont1,
        year: coming.year1,
        behavior: coming.behavior,
      );
    }).toList();
  }

  Future<List<StageStatDTO>> _fetchStatisticsData(AppDatabase db) async {
    final query = db.selectOnly(db.persons).join([
      leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
    ]);
    query.addColumns([db.stages.stageName, db.persons.personId.count()]);
    query.groupBy([db.stages.stageName]);

    final rows = await query.get();
    return rows.map((row) {
      return StageStatDTO(
        stageName: row.read(db.stages.stageName),
        count: row.read(db.persons.personId.count()) ?? 0,
      );
    }).toList();
  }
}
