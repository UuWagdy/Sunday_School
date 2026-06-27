import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_provider.dart';
import '../models/pdf_export_options.dart';
import '../repositories/areas_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/fathers_repository.dart';
import '../repositories/fields_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/persons_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/visitation_repository.dart';
import '../services/attendance_report_service.dart';
import '../ui/dialogs/print_period_services_dialog.dart';
import '../ui/dialogs/sorting_dialog.dart';
import '../ui/widgets/multi_select_filter.dart';
import '../utils/contact_links.dart';
import 'person_dialog.dart';

class VisitationScreen extends ConsumerStatefulWidget {
  const VisitationScreen({super.key});

  @override
  ConsumerState<VisitationScreen> createState() => _VisitationScreenState();
}

class _VisitationScreenState extends ConsumerState<VisitationScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  bool _periodMode = false;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _selectedServiceId;

  List<String> _filterGenders = [];
  List<int> _filterStageIds = [];
  List<int> _filterKhorosIds = [];
  List<int> _filterAreaIds = [];
  List<int> _filterFatherIds = [];
  List<int> _filterBirthdayDay = [];
  List<int> _filterBirthdayMonth = [];
  List<int> _filterBirthdayYear = [];
  Map<int, dynamic> _customFilters = {};
  bool? _visitedStatus;
  String? _visitTypeFilter;

  bool _showFilters = true;
  bool _isLoading = false;
  List<VisitationPersonDTO> _records = [];

  DateTime get _effectiveDateFrom {
    if (!_periodMode) return _selectedDate;
    return _dateFrom ?? _selectedDate;
  }

  DateTime get _effectiveDateTo {
    if (!_periodMode) return _selectedDate;
    return _dateTo ?? _dateFrom ?? _selectedDate;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await ref
          .read(visitationRepositoryProvider)
          .fetchVisitations(
            dateFrom: _effectiveDateFrom,
            dateTo: _effectiveDateTo,
            serviceIds: _selectedServiceId == null
                ? null
                : [_selectedServiceId!],
            search: _searchQuery,
            stageIds: _filterStageIds,
            khorosIds: _filterKhorosIds,
            areaIds: _filterAreaIds,
            fatherIds: _filterFatherIds,
            genders: _filterGenders,
            birthdayDay: _filterBirthdayDay,
            birthdayMonth: _filterBirthdayMonth,
            birthdayYear: _filterBirthdayYear,
            visitedStatus: _visitedStatus,
            visitType: _visitTypeFilter,
            customFilters: _customFilters,
            limit: 1000,
          );
      if (!mounted) return;
      setState(() => _records = records);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل الافتقاد: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord(
    VisitationPersonDTO record, {
    required bool isVisited,
    required String visitType,
    required String notes,
  }) async {
    await ref
        .read(visitationRepositoryProvider)
        .saveVisitation(
          personId: record.personId,
          visitDate: _periodMode ? _effectiveDateFrom : _selectedDate,
          serviceId: _selectedServiceId,
          isVisited: isVisited,
          visitType: visitType,
          notes: notes,
        );
    await _loadData();
  }

  Future<void> _openEditDialog(VisitationPersonDTO record) async {
    final fullPerson = await ref
        .read(personsRepositoryProvider.notifier)
        .fetchPersonById(record.personId);
    if (!mounted || fullPerson == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PersonDialog(person: fullPerson),
    );
    if (result == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح')));
    }
  }

  Future<void> _openMessageSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final template = await settingsRepo.getVisitationMessageTemplate();
    final nameParts = await settingsRepo.getVisitationNameParts();
    if (!mounted) return;

    final result = await showDialog<_VisitationMessageSettings>(
      context: context,
      builder: (context) => _VisitationMessageSettingsDialog(
        initialTemplate: template,
        initialNameParts: nameParts,
      ),
    );
    if (result == null) return;

    await settingsRepo.saveVisitationMessageTemplate(result.template);
    await settingsRepo.saveVisitationNameParts(result.nameParts);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ رسالة الافتقاد')));
  }

  Future<void> _launchCall(String phone) async {
    final uri = ContactLinks.telUri(phone);
    if (uri == null || !await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الاتصال لهذا الرقم')),
      );
    }
  }

  Future<void> _launchWhatsApp(VisitationPersonDTO record, String phone) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final template = await settingsRepo.getVisitationMessageTemplate();
    final nameParts = await settingsRepo.getVisitationNameParts();
    final message = ContactLinks.renderVisitationMessage(
      template: template,
      personName: record.personName,
      serviceName: record.serviceName.isNotEmpty
          ? record.serviceName
          : record.services,
      date: record.visitDate ?? _dateFormat.format(_selectedDate),
      nameParts: nameParts,
      personCode: record.personId,
      phone: phone,
    );
    final uri = ContactLinks.whatsappUri(phone, message);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب لهذا الرقم')),
      );
    }
  }

  AttendanceDTO _toAttendanceDTO(VisitationPersonDTO record) {
    return AttendanceDTO(
      id: record.visitId,
      personId: record.personId,
      personName: record.personName,
      dateWeek: record.visitDate,
      stageName: record.stageName,
      khorosName: record.khorosName,
      areaName: record.areaName,
      fatherName: record.fatherName,
      phone: record.phone,
      mobile: record.mobile,
      address: record.address,
      serviceId: record.serviceId,
      serviceName: record.serviceName,
      visited: record.isVisited ? 1 : 0,
      visitType: record.visitType,
      visitNotes: record.notes,
      gender: record.gender,
      rohot: record.rohot,
      leader: record.leader,
      services: record.services,
      customValues: record.customValues,
    );
  }

  Future<void> _printList() async {
    final services = ref.read(servicesRepositoryProvider).asData?.value ?? [];
    final periodServiceResult = await showDialog<PrintPeriodServicesResult>(
      context: context,
      builder: (context) => PrintPeriodServicesDialog(
        anchorDate: _selectedDate,
        services: services,
      ),
    );
    if (periodServiceResult == null) return;
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SortingDialog(isVisitation: true),
    );
    if (result == null) return;

    final sorting =
        (result['sorting'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    final headerIds =
        (result['header'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    final columns = (result['columns'] as List)
        .map(
          (column) => {
            'id': column.id.toString(),
            'title': column.title.toString(),
            'isPhone': column.isPhone.toString(),
          },
        )
        .toList();
    final separatePages = result['separatePages'] as bool? ?? false;
    final exportOptions =
        result['exportOptions'] as PdfExportOptions? ??
        const PdfExportOptions();
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final printRecords = await ref
        .read(visitationRepositoryProvider)
        .fetchVisitations(
          dateFrom: periodServiceResult.dateFrom,
          dateTo: periodServiceResult.dateTo,
          serviceIds: periodServiceResult.selectedServiceIds.isEmpty
              ? null
              : periodServiceResult.selectedServiceIds,
          search: _searchQuery,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          visitedStatus: _visitedStatus,
          visitType: _visitTypeFilter,
          customFilters: _customFilters,
        );

    if (!mounted) return;
    if (printRecords.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للطباعة')));
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final headerData = <String, String>{};
    if (headerIds.contains('church_name')) {
      final churchName = await settingsRepo.getSetting('church_name');
      if (churchName != null && churchName.isNotEmpty) {
        headerData['الكنيسة'] = churchName;
      }
    }
    if (headerIds.contains('service_name')) {
      headerData['الخدمة'] = periodServiceResult.serviceLabel;
    }
    if (headerIds.contains('stage')) {
      headerData['المرحلة'] = _filterStageIds.isEmpty
          ? 'كل المراحل'
          : _records
                .where((r) => _filterStageIds.contains(r.stageId))
                .map((r) => r.stageName)
                .where((name) => name.isNotEmpty)
                .toSet()
                .join('، ');
    }
    if (headerIds.contains('area')) {
      headerData['المنطقة'] = _filterAreaIds.isEmpty
          ? 'كل المناطق'
          : _records
                .where((r) => _filterAreaIds.contains(r.areaId))
                .map((r) => r.areaName)
                .where((name) => name.isNotEmpty)
                .toSet()
                .join('، ');
    }
    if (headerIds.contains('father')) {
      headerData['أب الاعتراف'] = _filterFatherIds.isEmpty
          ? 'كل الآباء'
          : _records
                .where((r) => _filterFatherIds.contains(r.fatherId))
                .map((r) => r.fatherName)
                .where((name) => name.isNotEmpty)
                .toSet()
                .join('، ');
    }
    headerData['الفترة'] = periodServiceResult.periodLabel;

    final churchLogo = await settingsRepo.getChurchLogo();

    final serviceLogos = <Uint8List>[];
    for (final id in periodServiceResult.selectedServiceIds) {
      for (final service in services) {
        if (service.id == id && service.logo != null) {
          serviceLogos.add(service.logo!);
        }
      }
    }

    Uint8List? khorosLogo;
    if (_filterKhorosIds.length == 1) {
      final khorosRow =
          await (db.select(db.khoroses)
                ..where((t) => t.khorosId.equals(_filterKhorosIds.first)))
              .getSingleOrNull();
      khorosLogo = khorosRow?.logo;
    }

    final pdfBytes = await AttendanceReportService.generatePDF(
      data: printRecords.map(_toAttendanceDTO).toList(),
      sortingCriteria: sorting,
      columns: columns,
      title: 'تقرير الافتقاد',
      headerData: headerData,
      serviceLogos: serviceLogos,
      churchLogo: churchLogo,
      khorosLogo: khorosLogo,
      churchName: headerData['الكنيسة'],
      hasServiceSelected: periodServiceResult.selectedServiceIds.isNotEmpty,
      separatePages: separatePages,
      exportOptions: exportOptions,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Visitation_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (!isWide) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(child: _buildHeader(false)),
                      if (_showFilters)
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 8),
                          sliver: SliverToBoxAdapter(
                            child: _buildFiltersPanel(scrollable: false),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],
                    body: _buildList(),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(isWide),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 330, child: _buildFiltersPanel()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildList()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الافتقاد',
                    style: TextStyle(
                      fontSize: isWide ? 20 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_records.length} شخص',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isWide) ...[
                  const SizedBox(width: 8),
                  _buildHeaderActions(includeFilters: false),
                ],
              ],
            ),
            if (!isWide) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _buildHeaderActions(includeFilters: true),
              ),
            ],
            const SizedBox(height: 12),
            _buildDateServiceControls(isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions({required bool includeFilters}) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton.outlined(
          tooltip: 'رسالة الافتقاد',
          onPressed: _openMessageSettings,
          icon: const Icon(Icons.message_outlined),
        ),
        IconButton.filledTonal(
          tooltip: 'تحديث',
          onPressed: _isLoading ? null : _loadData,
          icon: const Icon(Icons.refresh),
        ),
        IconButton.filled(
          tooltip: 'طباعة القائمة',
          onPressed: _records.isEmpty ? null : _printList,
          icon: const Icon(Icons.print),
        ),
        if (includeFilters)
          IconButton.outlined(
            tooltip: 'الفلاتر',
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
          ),
      ],
    );
  }

  Widget _buildDateServiceControls(bool isWide) {
    final services = ref.watch(servicesRepositoryProvider).asData?.value ?? [];
    final controls = [
      TextField(
        decoration: const InputDecoration(
          labelText: 'بحث بالاسم أو الكود أو التليفون',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
        onSubmitted: (value) {
          setState(() => _searchQuery = value.trim());
          _loadData();
        },
      ),
      DropdownButtonFormField<int?>(
        value: _selectedServiceId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'الخدمة', isDense: true),
        items: [
          const DropdownMenuItem(value: null, child: Text('كل الخدمات')),
          ...services.map(
            (service) =>
                DropdownMenuItem(value: service.id, child: Text(service.name)),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedServiceId = value);
          _loadData();
        },
      ),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('فترة من / إلى'),
        value: _periodMode,
        onChanged: (value) {
          setState(() {
            _periodMode = value;
            _dateFrom ??= _selectedDate;
            _dateTo ??= _selectedDate;
          });
          _loadData();
        },
      ),
      if (_periodMode) ...[
        _buildDateBox('من', _effectiveDateFrom, (date) {
          setState(() => _dateFrom = date);
          _loadData();
        }),
        _buildDateBox('إلى', _effectiveDateTo, (date) {
          setState(() => _dateTo = date);
          _loadData();
        }),
      ] else
        _buildDateBox('التاريخ', _selectedDate, (date) {
          setState(() => _selectedDate = date);
          _loadData();
        }),
    ];

    if (isWide) {
      return Row(
        children: controls
            .map(
              (control) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: control,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: controls
          .map(
            (control) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: control,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDateBox(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(_dateFormat.format(value)),
      ),
    );
  }

  Widget _buildFiltersPanel({bool scrollable = true}) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الفلاتر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _buildVisitationFilters(),
          const Divider(height: 28),
          _buildPersonFilters(),
        ],
      ),
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }

  Widget _buildVisitationFilters() {
    return Column(
      children: [
        DropdownButtonFormField<bool?>(
          value: _visitedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'حالة الافتقاد',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('الكل')),
            DropdownMenuItem(value: true, child: Text('تم الافتقاد')),
            DropdownMenuItem(value: false, child: Text('لم يتم الافتقاد')),
          ],
          onChanged: (value) {
            setState(() => _visitedStatus = value);
            _loadData();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _visitTypeFilter,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'نوع الافتقاد',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الأنواع')),
            ...visitationTypes.map(
              (type) => DropdownMenuItem(value: type, child: Text(type)),
            ),
          ],
          onChanged: (value) {
            setState(() => _visitTypeFilter = value);
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildPersonFilters() {
    final fields = ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
    String getLabel(String key, String fallback) {
      for (final field in fields) {
        if (field.fieldKey == key) return field.name;
      }
      return fallback;
    }

    return Column(
      children: [
        MultiSelectFilter(
          label: getLabel('gender', 'النوع'),
          selectedIds: _filterGenders,
          allItems: [
            SelectableItem(id: 'ذكر', name: 'ذكر'),
            SelectableItem(id: 'أنثى', name: 'أنثى'),
          ],
          onChanged: (ids) {
            setState(() => _filterGenders = List<String>.from(ids));
            _loadData();
          },
        ),
        const SizedBox(height: 12),
        ref
            .watch(stagesRepositoryProvider)
            .when(
              data: (stages) => MultiSelectFilter(
                label: getLabel('stage', 'المرحلة'),
                selectedIds: _filterStageIds,
                allItems: stages
                    .map(
                      (stage) => SelectableItem(id: stage.id, name: stage.name),
                    )
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterStageIds = List<int>.from(ids));
                  _loadData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
            ),
        const SizedBox(height: 12),
        ref
            .watch(khorosRepositoryProvider)
            .when(
              data: (khoroses) => MultiSelectFilter(
                label: getLabel('khoros', 'الخورس'),
                selectedIds: _filterKhorosIds,
                allItems: khoroses
                    .map(
                      (khoros) =>
                          SelectableItem(id: khoros.id, name: khoros.name),
                    )
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterKhorosIds = List<int>.from(ids));
                  _loadData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
            ),
        const SizedBox(height: 12),
        ref
            .watch(areasRepositoryProvider)
            .when(
              data: (areas) => MultiSelectFilter(
                label: getLabel('area', 'المنطقة'),
                selectedIds: _filterAreaIds,
                allItems: areas
                    .map((area) => SelectableItem(id: area.id, name: area.name))
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterAreaIds = List<int>.from(ids));
                  _loadData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
            ),
        const SizedBox(height: 12),
        ref
            .watch(fathersRepositoryProvider)
            .when(
              data: (fathers) => MultiSelectFilter(
                label: getLabel('father', 'أب الاعتراف'),
                selectedIds: _filterFatherIds,
                allItems: fathers
                    .map(
                      (father) =>
                          SelectableItem(id: father.id, name: father.name),
                    )
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterFatherIds = List<int>.from(ids));
                  _loadData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
            ),
        const SizedBox(height: 12),
        MultiSelectFilter(
          label: 'يوم (${getLabel('birthday', 'الميلاد')})',
          selectedIds: _filterBirthdayDay,
          allItems: List.generate(
            31,
            (i) => SelectableItem(id: i + 1, name: '${i + 1}'),
          ),
          onChanged: (ids) {
            setState(() => _filterBirthdayDay = List<int>.from(ids));
            _loadData();
          },
        ),
        const SizedBox(height: 12),
        MultiSelectFilter(
          label: 'شهر (${getLabel('birthday', 'الميلاد')})',
          selectedIds: _filterBirthdayMonth,
          allItems: List.generate(
            12,
            (i) => SelectableItem(id: i + 1, name: '${i + 1}'),
          ),
          onChanged: (ids) {
            setState(() => _filterBirthdayMonth = List<int>.from(ids));
            _loadData();
          },
        ),
        const SizedBox(height: 12),
        MultiSelectFilter(
          label: 'سنة (${getLabel('birthday', 'الميلاد')})',
          selectedIds: _filterBirthdayYear,
          allItems: List.generate(80, (i) {
            final year = DateTime.now().year - i;
            return SelectableItem(id: year, name: '$year');
          }),
          onChanged: (ids) {
            setState(() => _filterBirthdayYear = List<int>.from(ids));
            _loadData();
          },
        ),
        _buildCustomFilters(
          fields.where((f) => f.isFilter && f.type != 'native').toList(),
        ),
      ],
    );
  }

  Widget _buildCustomFilters(List<FieldConfigDTO> fields) {
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 28),
        const Text(
          'فلاتر إضافية',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 8),
        ...fields.map((field) {
          if (field.type == 'dropdown' || field.type == 'checkbox') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String?>(
                value: _customFilters[field.id] as String?,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: field.name,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('كل ${field.name}'),
                  ),
                  ...field.options.map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _customFilters.remove(field.id);
                    } else {
                      _customFilters[field.id] = value;
                    }
                  });
                  _loadData();
                },
              ),
            );
          }

          if (field.type == 'multi_select') {
            final selected = (_customFilters[field.id] as List<String>?) ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MultiSelectFilter(
                label: field.name,
                selectedIds: selected,
                allItems: field.options
                    .map((option) => SelectableItem(id: option, name: option))
                    .toList(),
                onChanged: (ids) {
                  setState(() {
                    if (ids.isEmpty) {
                      _customFilters.remove(field.id);
                    } else {
                      _customFilters[field.id] = List<String>.from(ids);
                    }
                  });
                  _loadData();
                },
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              decoration: InputDecoration(
                labelText: field.name,
                isDense: true,
                suffixIcon:
                    _customFilters[field.id]?.toString().isNotEmpty == true
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _customFilters.remove(field.id));
                          _loadData();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() {
                  if (value.trim().isEmpty) {
                    _customFilters.remove(field.id);
                  } else {
                    _customFilters[field.id] = value.trim();
                  }
                });
                _loadData();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildList() {
    if (_isLoading && _records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_records.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('لا توجد بيانات مطابقة للفلاتر')),
      );
    }

    final fields = ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
    final customPhoneFields = fields
        .where(
          (field) =>
              field.type != 'native' &&
              field.type != 'document' &&
              field.isPhone,
        )
        .toList();
    String fieldLabel(String key, String fallback) {
      for (final field in fields) {
        if (field.fieldKey == key) return field.name;
      }
      return fallback;
    }

    return ListView.separated(
      itemCount: _records.length + (_isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _records.length) {
          return const Center(child: LinearProgressIndicator());
        }
        final record = _records[index];
        return _VisitationCard(
          key: ValueKey(
            '${record.personId}_${record.visitId}_${record.isVisited}_${record.visitType}',
          ),
          record: record,
          mobileLabel: fieldLabel('mobile', 'موبايل'),
          phoneLabel: fieldLabel('phone', 'تليفون'),
          customPhoneFields: customPhoneFields,
          onCall: _launchCall,
          onWhatsApp: (phone) => _launchWhatsApp(record, phone),
          onSave: (isVisited, visitType, notes) => _saveRecord(
            record,
            isVisited: isVisited,
            visitType: visitType,
            notes: notes,
          ),
          onEdit: () => _openEditDialog(record),
        );
      },
    );
  }
}

class _VisitationCard extends StatefulWidget {
  const _VisitationCard({
    super.key,
    required this.record,
    required this.mobileLabel,
    required this.phoneLabel,
    required this.customPhoneFields,
    required this.onCall,
    required this.onWhatsApp,
    required this.onSave,
    required this.onEdit,
  });

  final VisitationPersonDTO record;
  final String mobileLabel;
  final String phoneLabel;
  final List<FieldConfigDTO> customPhoneFields;
  final Future<void> Function(String phone) onCall;
  final Future<void> Function(String phone) onWhatsApp;
  final Future<void> Function(bool isVisited, String visitType, String notes)
  onSave;
  final VoidCallback onEdit;

  @override
  State<_VisitationCard> createState() => _VisitationCardState();
}

class _VisitationCardState extends State<_VisitationCard> {
  late bool _isVisited;
  late String _visitType;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isVisited = widget.record.isVisited;
    _visitType = widget.record.visitType;
    _notesController = TextEditingController(text: widget.record.notes);
  }

  @override
  void didUpdateWidget(covariant _VisitationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.visitId != widget.record.visitId ||
        oldWidget.record.notes != widget.record.notes) {
      _isVisited = widget.record.isVisited;
      _visitType = widget.record.visitType;
      _notesController.text = widget.record.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<_PhoneEntry> _phoneEntries() {
    final entries = <_PhoneEntry>[
      _PhoneEntry(widget.mobileLabel, widget.record.mobile),
      _PhoneEntry(widget.phoneLabel, widget.record.phone),
      ...widget.customPhoneFields.map(
        (field) =>
            _PhoneEntry(field.name, widget.record.customValues[field.id] ?? ''),
      ),
    ];
    return entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_isVisited, _visitType, _notesController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ افتقاد ${widget.record.personName}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _isVisited,
                  onChanged: (value) =>
                      setState(() => _isVisited = value ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.personName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (widget.record.stageName.isNotEmpty)
                            _InfoChip(Icons.school, widget.record.stageName),
                          if (widget.record.areaName.isNotEmpty)
                            _InfoChip(
                              Icons.location_on,
                              widget.record.areaName,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'تعديل البيانات',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            if (_phoneEntries().isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _phoneEntries()
                    .map(
                      (entry) => _PhoneActionsChip(
                        label: entry.label,
                        phone: entry.value,
                        onCall: () => widget.onCall(entry.value),
                        onWhatsApp: () => widget.onWhatsApp(entry.value),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final inputs = [
                  DropdownButtonFormField<String>(
                    value: _visitType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'نوع الافتقاد',
                      isDense: true,
                    ),
                    items: visitationTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _visitType = value);
                    },
                  ),
                  TextField(
                    controller: _notesController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الافتقاد',
                      isDense: true,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('حفظ'),
                  ),
                ];

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: inputs[0]),
                          const SizedBox(width: 8),
                          SizedBox(width: 88, child: inputs[2]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      inputs[1],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: inputs[0]),
                    const SizedBox(width: 10),
                    Expanded(flex: 5, child: inputs[1]),
                    const SizedBox(width: 10),
                    SizedBox(width: 96, child: inputs[2]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1A237E)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _PhoneEntry {
  const _PhoneEntry(this.label, this.value);

  final String label;
  final String value;
}

class _PhoneActionsChip extends StatelessWidget {
  const _PhoneActionsChip({
    required this.label,
    required this.phone,
    required this.onCall,
    required this.onWhatsApp,
  });

  final String label;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsetsDirectional.only(
        start: 8,
        end: 4,
        top: 3,
        bottom: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E3EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Text(
                  '$label: $phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'اتصال',
            onPressed: onCall,
            icon: const Icon(Icons.call, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: 'واتساب',
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat, size: 18),
            color: Colors.green,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _VisitationMessageSettings {
  const _VisitationMessageSettings({
    required this.template,
    required this.nameParts,
  });

  final String template;
  final int nameParts;
}

class _MessageVariable {
  const _MessageVariable(this.token, this.label);

  final String token;
  final String label;
}

class _VisitationMessageSettingsDialog extends StatefulWidget {
  const _VisitationMessageSettingsDialog({
    required this.initialTemplate,
    required this.initialNameParts,
  });

  final String initialTemplate;
  final int initialNameParts;

  @override
  State<_VisitationMessageSettingsDialog> createState() =>
      _VisitationMessageSettingsDialogState();
}

class _VisitationMessageSettingsDialogState
    extends State<_VisitationMessageSettingsDialog> {
  late final TextEditingController _controller;
  late int _nameParts;
  TextDirection _messageDirection = TextDirection.rtl;

  static const List<_MessageVariable> _variables = [
    _MessageVariable('{name}', 'الاسم حسب الاختيار'),
    _MessageVariable('{full_name}', 'الاسم بالكامل'),
    _MessageVariable('{first_name}', 'الاسم الأول'),
    _MessageVariable('{second_name}', 'الاسم الثاني'),
    _MessageVariable('{third_name}', 'الاسم الثالث'),
    _MessageVariable('{service}', 'اسم الخدمة'),
    _MessageVariable('{date}', 'تاريخ الافتقاد'),
    _MessageVariable('{code}', 'كود المخدوم'),
    _MessageVariable('{phone}', 'رقم الهاتف'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTemplate);
    _nameParts = widget.initialNameParts;
    _messageDirection = _detectDirection(_controller.text);
    _controller.addListener(_syncMessageDirection);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncMessageDirection);
    _controller.dispose();
    super.dispose();
  }

  void _syncMessageDirection() {
    final next = _detectDirection(_controller.text);
    if (next != _messageDirection) {
      setState(() => _messageDirection = next);
    }
  }

  TextDirection _detectDirection(String value) {
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(char)) {
        return TextDirection.rtl;
      }
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        return TextDirection.ltr;
      }
    }
    return TextDirection.rtl;
  }

  void _insertVariable(String token) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);
    final nextText = text.replaceRange(safeStart, safeEnd, token);
    final nextOffset = safeStart + token.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('رسالة واتساب الافتقاد'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  textDirection: _messageDirection,
                  textAlign: _messageDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  minLines: 7,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'نص الرسالة',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '{name} يتأثر باختيار شكل الاسم بالأسفل، أما {full_name} فيكتب الاسم بالكامل دائمًا.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _nameParts,
                  decoration: const InputDecoration(
                    labelText: 'شكل الاسم داخل {name}',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('اسم أحادي')),
                    DropdownMenuItem(value: 2, child: Text('اسم ثنائي')),
                    DropdownMenuItem(value: 3, child: Text('اسم ثلاثي')),
                    DropdownMenuItem(value: 0, child: Text('الاسم كامل')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _nameParts = value);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'اضغط على أي متغير لإضافته في مكان المؤشر:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _variables
                      .map(
                        (variable) => ActionChip(
                          label: Text('${variable.token}  ${variable.label}'),
                          onPressed: () => _insertVariable(variable.token),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              _controller.text = ContactLinks.defaultVisitationMessageTemplate;
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
              setState(() => _nameParts = 1);
            },
            child: const Text('استعادة الافتراضي'),
          ),
          FilledButton(
            onPressed: () {
              final template = _controller.text.trim();
              if (template.isEmpty) return;
              Navigator.pop(
                context,
                _VisitationMessageSettings(
                  template: template,
                  nameParts: _nameParts,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
