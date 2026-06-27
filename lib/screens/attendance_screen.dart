import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';
import '../database/database_provider.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/fields_repository.dart';
import '../ui/dialogs/sorting_dialog.dart';
import '../ui/dialogs/print_period_services_dialog.dart';
import '../services/attendance_report_service.dart';
import '../services/attendance_grid_pdf_generator.dart';
import '../services/excel_export_service.dart';
import '../services/grouped_pdf_export_service.dart';
import '../models/pdf_export_options.dart';
import '../models/person_option.dart';
import '../services/auth_service.dart';
import '../repositories/persons_repository.dart';
import '../repositories/service_eligibility_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/fathers_repository.dart';
import '../ui/widgets/multi_select_filter.dart';
import '../widgets/print_progress_dialog.dart';
import '../services/pdf_generation_task.dart';
import 'qr_scanner_screen.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  static const int _defaultAttendancePoints = 2;

  // --- Person Data Filters ---
  String _searchQuery = '';
  List<String> _filterGenders = [];
  List<int> _filterStageIds = [];
  List<int> _filterKhorosIds = [];
  List<int> _filterAreaIds = [];
  List<int> _filterFatherIds = [];
  List<int> _filterBirthdayDay = [];
  List<int> _filterBirthdayMonth = [];
  List<int> _filterBirthdayYear = [];
  Map<int, dynamic> _customFilters = {};

  // --- Attendance Filters ---
  List<int> _filterMonth = [];
  List<int> _filterYear = [];
  int? _filterServiceId;
  String _filterStatus = 'present';
  bool _filterSpecificDateOnly = true;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  TimeOfDay? _filterLateAfter;
  bool _periodModeEnabled = false;
  DateTime? _periodStartDate;
  DateTime? _periodEndDate;

  // --- Visitation Filters ---
  int? _filterVisitedStatus; // null=all, 0=not done, 1=in progress, 2=done
  String _filterNotesStatus = 'all'; // 'all', 'with', 'without'

  // --- Filter section visibility ---
  bool _showPersonFilters = false;
  bool _showAttendanceFilters = true;
  bool _showVisitationFilters = false;
  bool _mobileFiltersExpanded = false;

  // --- Data / Pagination ---
  final ScrollController _scrollController = ScrollController();
  final List<AttendanceDTO> _records = [];
  final Set<int> _selectedPersonIds = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 50;

  // --- Summary Counts ---
  int _totalCount = 0;
  int _presentCount = 0;
  int _absentCount = 0;

  // --- Inline form ---
  final FocusNode _codeFocusNode = FocusNode();
  FocusNode? _internalFocusNode;
  TextEditingController? _autocompleteController;
  bool _isCodeFocusBridgeAttached = false;
  final TextEditingController _pointsController = TextEditingController(
    text: '$_defaultAttendancePoints',
  );
  DateTime _selectedDate = DateTime.now();
  int? _selectedPersonId;
  String? _selectedPersonName;
  int? _selectedServiceId;
  bool _isSaving = false;
  bool _isCheckingOutAll = false;
  bool _isBulkActionRunning = false;
  bool _isCheckoutMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _codeFocusNode.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _refocusCodeField() {
    _autocompleteController?.clear();
    _selectedPersonId = null;
    _selectedPersonName = null;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_internalFocusNode != null && _internalFocusNode!.canRequestFocus) {
        _internalFocusNode!.requestFocus();
      } else {
        _codeFocusNode.requestFocus();
      }
      // Trigger autocomplete dropdown to reappear
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted || _autocompleteController == null) return;
        _autocompleteController!.text = ' ';
        _autocompleteController!.clear();
      });
    });
  }

  void _showPeriodModeBlockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'وضع الفترة مفعل، لا يمكن تسجيل حضور أو انصراف. استخدم الفلاتر والتقارير فقط.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _pickPeriodDate({required bool start}) async {
    final initial = start
        ? (_periodStartDate ?? _filterDateFrom ?? _selectedDate)
        : (_periodEndDate ?? _filterDateTo ?? _selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _periodStartDate = picked;
        if (_periodEndDate != null && _periodEndDate!.isBefore(picked)) {
          _periodEndDate = picked;
        }
      } else {
        _periodEndDate = picked;
        if (_periodStartDate != null && _periodStartDate!.isAfter(picked)) {
          _periodStartDate = picked;
        }
      }
      _applyPeriodToFilters();
    });
    _loadInitialData();
  }

  void _togglePeriodMode(bool value) {
    setState(() {
      _periodModeEnabled = value;
      if (value) {
        _periodStartDate ??= _filterDateFrom ?? _selectedDate;
        _periodEndDate ??= _filterDateTo ?? _selectedDate;
        _applyPeriodToFilters();
      }
    });
    _loadInitialData();
  }

  void _applyPeriodToFilters() {
    if (!_periodModeEnabled) return;
    _filterSpecificDateOnly = false;
    _filterDateFrom = _periodStartDate;
    _filterDateTo = _periodEndDate;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) _loadMore();
    }
  }

  String? _lateAfterTimeString() {
    if (_filterLateAfter == null) return null;
    // Convert to comparable 24h string for DB query
    return '${_filterLateAfter!.hour.toString().padLeft(2, '0')}:${_filterLateAfter!.minute.toString().padLeft(2, '0')}';
  }

  String _attendanceGroupValue(AttendanceDTO record, String criterion) {
    switch (criterion) {
      case 'area':
        return record.areaName?.trim().isNotEmpty == true
            ? record.areaName!.trim()
            : 'غير محدد';
      case 'stage':
        return record.stageName?.trim().isNotEmpty == true
            ? record.stageName!.trim()
            : 'غير محدد';
      case 'father':
        return record.fatherName?.trim().isNotEmpty == true
            ? record.fatherName!.trim()
            : 'غير محدد';
      case 'khoros':
        return record.khorosName?.trim().isNotEmpty == true
            ? record.khorosName!.trim()
            : 'غير محدد';
      case 'name':
        return record.personName?.trim().isNotEmpty == true
            ? record.personName!.trim()
            : 'غير محدد';
      default:
        return 'كل البيانات';
    }
  }

  Map<String, List<AttendanceDTO>> _groupAttendanceForPdf(
    List<AttendanceDTO> data,
    List<String> sorting,
  ) {
    final criterion = sorting.where((item) => item != 'name').firstOrNull;
    if (criterion == null) return {'كل البيانات': data};
    final groups = <String, List<AttendanceDTO>>{};
    for (final record in data) {
      final key = _attendanceGroupValue(record, criterion);
      groups.putIfAbsent(key, () => <AttendanceDTO>[]).add(record);
    }
    return groups;
  }

  int _lastCallId = 0;

  Future<void> _loadInitialData() async {
    final callId = DateTime.now().millisecondsSinceEpoch;
    _lastCallId = callId;

    setState(() {
      _isLoading = true;
      _records.clear();
      _offset = 0;
      _hasMore = true;
      _totalCount = 0;
      _presentCount = 0;
      _absentCount = 0;
    });

    final repo = ref.read(attendanceRepositoryProvider.notifier);
    DateTime? dFrom = _filterDateFrom;
    DateTime? dTo = _filterDateTo;
    if (_filterSpecificDateOnly) {
      dFrom = _selectedDate;
      dTo = _selectedDate;
    }

    try {
      if (!mounted || _lastCallId != callId) return;

      bool rawHasMore = false;
      final results = await Future.wait([
        repo.fetchAttendance(
          month: _filterMonth,
          year: _filterYear,
          search: _searchQuery,
          limit: _limit,
          offset: 0,
          dateFrom: dFrom,
          dateTo: dTo,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          serviceId: _filterServiceId,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          callId: '$callId-DATA',
          onHasMore: (val) => rawHasMore = val,
        ),
        repo.fetchAttendanceSummary(
          month: _filterMonth,
          year: _filterYear,
          search: _searchQuery,
          dateFrom: dFrom,
          dateTo: dTo,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          serviceId: _filterServiceId,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          callId: '$callId-SUM',
        ),
      ]);

      if (!mounted || _lastCallId != callId) return;

      final data = results[0] as List<AttendanceDTO>;
      final summary = results[1] as Map<String, int>;

      setState(() {
        _totalCount = summary['total'] ?? 0;
        _presentCount = summary['present'] ?? 0;
        _absentCount = summary['absent'] ?? 0;
        _records.clear();
        _records.addAll(data);
        final visiblePersonIds = data.map((r) => r.personId).toSet();
        _selectedPersonIds.removeWhere((id) => !visiblePersonIds.contains(id));
        _hasMore = rawHasMore;
        _isLoading = false;
        _offset = _limit;
      });
    } catch (e, st) {
      debugPrint('UI Debug Error [$callId] in _loadInitialData: $e\n$st');
      if (mounted && _lastCallId == callId) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoading = true);
    final repo = ref.read(attendanceRepositoryProvider.notifier);
    DateTime? dFrom = _filterDateFrom;
    DateTime? dTo = _filterDateTo;
    if (_filterSpecificDateOnly) {
      dFrom = _selectedDate;
      dTo = _selectedDate;
    }
    bool rawHasMore = false;
    final data = await repo.fetchAttendance(
      month: _filterMonth,
      year: _filterYear,
      search: _searchQuery,
      limit: _limit,
      offset: _offset,
      dateFrom: dFrom,
      dateTo: dTo,
      stageIds: _filterStageIds,
      khorosIds: _filterKhorosIds,
      areaIds: _filterAreaIds,
      fatherIds: _filterFatherIds,
      status: _filterStatus,
      genders: _filterGenders,
      birthdayDay: _filterBirthdayDay,
      birthdayMonth: _filterBirthdayMonth,
      birthdayYear: _filterBirthdayYear,
      serviceId: _filterServiceId,
      visitedStatus: _filterVisitedStatus,
      notesFilter: _filterNotesStatus,
      lateAfterTime: _lateAfterTimeString(),
      customFilters: _customFilters,
      onHasMore: (val) => rawHasMore = val,
    );
    if (mounted) {
      setState(() {
        _records.addAll(data);
        _isLoading = false;
        _offset = _offset + _limit;
        _hasMore = rawHasMore;
      });
    }
  }

  Future<void> _reloadPreservingScroll() async {
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    await _loadInitialData();
    if (!mounted || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0.0, max));
    });
  }

  List<AttendanceDTO> get _selectedRecords =>
      _records.where((r) => _selectedPersonIds.contains(r.personId)).toList();

  List<int> get _selectedAttendanceIds =>
      _selectedRecords.map((r) => r.id).whereType<int>().toSet().toList();

  int get _currentPoints =>
      int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;

  void _toggleSelectAllVisible() {
    final visibleIds = _records.map((r) => r.personId).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedPersonIds.contains);
    setState(() {
      if (allSelected) {
        _selectedPersonIds.removeAll(visibleIds);
      } else {
        _selectedPersonIds.addAll(visibleIds);
      }
    });
  }

  void _clearSelection() {
    if (_selectedPersonIds.isEmpty) return;
    setState(_selectedPersonIds.clear);
  }

  Future<void> _applyPointsToSelected() async {
    if (_selectedAttendanceIds.isEmpty || _isBulkActionRunning) return;
    setState(() => _isBulkActionRunning = true);
    try {
      final count = await ref
          .read(attendanceRepositoryProvider.notifier)
          .updateAttendancePointsForIds(
            ids: _selectedAttendanceIds,
            points: _currentPoints,
            isCheckoutMode: _isCheckoutMode,
            defaultAttendancePoints: _defaultAttendancePoints,
          );
      await _reloadPreservingScroll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعديل النقاط لـ $count سجل'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _cancelSelectedAttendance() async {
    if (_selectedAttendanceIds.isEmpty || _isBulkActionRunning) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الحضور'),
          content: Text(
            'سيتم حذف سجلات الحضور المحددة (${_selectedAttendanceIds.length} سجل).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isBulkActionRunning = true);
    try {
      final count = await ref
          .read(attendanceRepositoryProvider.notifier)
          .deleteAttendanceForIds(_selectedAttendanceIds);
      _clearSelection();
      await _reloadPreservingScroll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء الحضور لـ $count سجل'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _cancelSelectedCheckout() async {
    if (_selectedAttendanceIds.isEmpty || _isBulkActionRunning) return;
    setState(() => _isBulkActionRunning = true);
    try {
      final count = await ref
          .read(attendanceRepositoryProvider.notifier)
          .clearCheckoutForIds(_selectedAttendanceIds);
      await _reloadPreservingScroll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء الانصراف لـ $count سجل'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _checkoutSelected() async {
    final targets = _selectedRecords
        .where(
          (r) =>
              r.id != null &&
              r.attendTime != null &&
              (r.checkoutTime == null || r.checkoutTime!.isEmpty),
        )
        .toList();
    if (targets.isEmpty || _isBulkActionRunning || _periodModeEnabled) return;

    setState(() => _isBulkActionRunning = true);
    try {
      final services = ref.read(servicesRepositoryProvider).asData?.value ?? [];
      var count = 0;
      for (final r in targets) {
        final errorMsg = await ref
            .read(attendanceRepositoryProvider.notifier)
            .addAttendance(
              personId: r.personId,
              dateWeek:
                  r.dateWeek ?? DateFormat('yyyy-MM-dd').format(_selectedDate),
              point: _currentPoints,
              month: _selectedDate.month,
              year: _selectedDate.year,
              serviceId: r.serviceId ?? _selectedServiceId,
              attendTime: _currentTime12h(),
              isCheckout: true,
              personName: r.personName,
              serviceName:
                  r.serviceName ?? _serviceNameById(services, r.serviceId),
            );
        if (errorMsg == null) count++;
      }
      await _reloadPreservingScroll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل انصراف $count شخص'),
          backgroundColor: count == 0 ? Colors.orange : Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  void _onSearch(String val) {
    setState(() => _searchQuery = val);
    _loadInitialData();
  }

  String _currentTime12h() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;
    final s = now.second;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} $period';
  }

  String _extractAttendanceCodeFromScan(String rawValue) {
    final trimmed = rawValue.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      for (final key in const ['code', 'personId', 'person_id', 'id']) {
        final value = uri.queryParameters[key]?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }

    final namedCodeMatch = RegExp(
      r'(?:code|personId|person_id|id)\s*[:=]\s*([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    final namedCode = namedCodeMatch?.group(1)?.trim();
    if (namedCode != null && namedCode.isNotEmpty) return namedCode;

    return trimmed;
  }

  String? _serviceNameById(List<ServiceDTO> services, int? serviceId) {
    if (serviceId == null) return null;
    for (final service in services) {
      if (service.id == serviceId) return service.name;
    }
    return null;
  }

  Future<void> _saveAttendance() async {
    if (_periodModeEnabled) {
      _showPeriodModeBlockedMessage();
      return;
    }
    if (_isSaving) return;
    if (_selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار شخص أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      _autocompleteController?.clear();
      _selectedPersonId = null;
      _selectedPersonName = null;
      _internalFocusNode?.requestFocus();
      _codeFocusNode.requestFocus();
      return;
    }

    // Validate service day
    final services = ref.read(servicesRepositoryProvider).asData?.value ?? [];
    if (services.isNotEmpty && _selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الخدمة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      _autocompleteController?.clear();
      _selectedPersonId = null;
      _selectedPersonName = null;
      _internalFocusNode?.requestFocus();
      _codeFocusNode.requestFocus();
      return;
    }

    if (_selectedServiceId != null) {
      final svc = services.firstWhere(
        (s) => s.id == _selectedServiceId,
        orElse: () => services.first,
      );
      // DateTime weekday: 1=Mon .. 7=Sun (matches our convention)
      if (_selectedDate.weekday != svc.dayOfWeek) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خدمة "${svc.name}" ليست اليوم (${svc.dayName})'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear the person name and refocus the input
        _autocompleteController?.clear();
        _selectedPersonId = null;
        _selectedPersonName = null;
        _internalFocusNode?.requestFocus();
        _codeFocusNode.requestFocus();
        return;
      }
    }

    if (_selectedServiceId != null) {
      final selectedServiceName = _serviceNameById(
        services,
        _selectedServiceId,
      );
      final eligible = await ref
          .read(serviceEligibilityRepositoryProvider)
          .isPersonEligibleForService(
            personId: _selectedPersonId!,
            serviceId: _selectedServiceId,
          );
      if (!eligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serviceEligibilityErrorMessageFor(
                personName: _selectedPersonName,
                serviceName: selectedServiceName,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        _refocusCodeField();
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final pId = _selectedPersonId!;
      final pName = _selectedPersonName ?? '';
      final serviceName = _serviceNameById(services, _selectedServiceId);
      _autocompleteController?.clear();
      _selectedPersonId = null;
      _selectedPersonName = null;
      _internalFocusNode?.requestFocus();
      _codeFocusNode.requestFocus();

      final points =
          int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = _currentTime12h();

      final errorMsg = await ref
          .read(attendanceRepositoryProvider.notifier)
          .addAttendance(
            personId: pId,
            dateWeek: dateStr,
            point: points,
            month: _selectedDate.month,
            year: _selectedDate.year,
            serviceId: _selectedServiceId,
            attendTime: timeStr,
            isCheckout: _isCheckoutMode,
            personName: pName,
            serviceName: serviceName,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (errorMsg == null) {
          await _reloadPreservingScroll();
          final label = _isCheckoutMode ? 'انصراف' : 'حضور';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تسجيل $label $pName بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          _refocusCodeField();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $errorMsg'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
          _refocusCodeField();
        }
      }
    } catch (e, st) {
      debugPrint('Error in _saveAttendance: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _checkoutPerson(AttendanceDTO r) async {
    if (_periodModeEnabled) {
      _showPeriodModeBlockedMessage();
      return;
    }
    if (_isSaving || r.id == null) return;
    setState(() => _isSaving = true);
    try {
      final points =
          int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;
      final dateStr =
          r.dateWeek ?? DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = _currentTime12h();
      final services = ref.read(servicesRepositoryProvider).asData?.value ?? [];
      final serviceId = r.serviceId ?? _selectedServiceId;
      final serviceName =
          r.serviceName ?? _serviceNameById(services, serviceId);

      final errorMsg = await ref
          .read(attendanceRepositoryProvider.notifier)
          .addAttendance(
            personId: r.personId,
            dateWeek: dateStr,
            point: points,
            month: _selectedDate.month,
            year: _selectedDate.year,
            serviceId: serviceId,
            attendTime: timeStr,
            isCheckout: true,
            personName: r.personName,
            serviceName: serviceName,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (errorMsg == null) {
          await _reloadPreservingScroll();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تسجيل انصراف ${r.personName} بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $errorMsg'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Error in _checkoutPerson: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _checkoutAll() async {
    if (_periodModeEnabled) {
      _showPeriodModeBlockedMessage();
      return;
    }
    if (_isCheckingOutAll) return;

    final services = ref.read(servicesRepositoryProvider).asData?.value ?? [];
    if (services.isNotEmpty && _selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الخدمة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final points =
        int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final serviceName = _selectedServiceId == null
        ? 'بدون خدمة'
        : services
              .where((service) => service.id == _selectedServiceId)
              .map((service) => service.name)
              .firstOrNull;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد انصراف الكل'),
          content: Text(
            'سيتم تسجيل الانصراف الآن لكل من حضر ولم ينصرف في '
            '$serviceName بتاريخ $date، '
            'مع إضافة $points نقطة لكل شخص.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout),
              label: const Text('انصراف الكل'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCheckingOutAll = true);
    try {
      final count = await ref
          .read(attendanceRepositoryProvider.notifier)
          .checkoutAll(
            dateWeek: date,
            checkoutTime: _currentTime12h(),
            points: points,
            serviceId: _selectedServiceId,
          );
      if (!mounted) return;
      await _loadInitialData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'لا يوجد أشخاص منتظر تسجيل انصرافهم'
                : 'تم تسجيل انصراف $count شخص بنجاح',
          ),
          backgroundColor: count == 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تسجيل انصراف الكل: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOutAll = false);
    }
  }

  void _deleteAttendance(AttendanceDTO r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف سجل حضور "${r.personName ?? ''}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (ok == true && r.id != null) {
      final success = await ref
          .read(attendanceRepositoryProvider.notifier)
          .deleteAttendance(r.id!);
      if (mounted) {
        await _reloadPreservingScroll();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'تم الحذف بنجاح' : 'فشل الحذف')),
        );
        _refocusCodeField();
      }
    }
  }

  void _showEditDialog(AttendanceDTO r) {
    final pointCtrl = TextEditingController(text: '${r.point ?? 0}');
    DateTime editDate = r.dateWeek != null
        ? (DateTime.tryParse(r.dateWeek!) ?? DateTime.now())
        : DateTime.now();
    showDialog(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('تعديل سجل الحضور'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pointCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'النقاط'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: editDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDlgState(() => editDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'التاريخ'),
                      child: Text(DateFormat('yyyy-MM-dd').format(editDate)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(c);
                    final success = await ref
                        .read(attendanceRepositoryProvider.notifier)
                        .updateAttendance(
                          id: r.id!,
                          point: int.tryParse(pointCtrl.text),
                          dateWeek: DateFormat('yyyy-MM-dd').format(editDate),
                        );
                    if (mounted && success) {
                      await _reloadPreservingScroll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم التعديل بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).value;
    final attendancePermissions =
        user?.granularPermissions['attendance'] ??
        user?.granularPermissions['absence'];
    final canAdd =
        user == null ||
        !user.isAdvanced ||
        (attendancePermissions?['add'] ?? false);
    final canEdit =
        user == null ||
        !user.isAdvanced ||
        (attendancePermissions?['edit'] ?? false);
    final canDelete =
        user == null ||
        !user.isAdvanced ||
        (attendancePermissions?['delete'] ?? false);

    final viewport = MediaQuery.sizeOf(context);
    final isMobile = viewport.width < 700 || viewport.height < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      _buildSummaryCards(),
                      const SizedBox(height: 12),
                      if (canAdd) _buildInlineForm(isMobile),
                      const SizedBox(height: 8),
                      // Collapsible filter toggle
                      InkWell(
                        onTap: () => setState(
                          () =>
                              _mobileFiltersExpanded = !_mobileFiltersExpanded,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _mobileFiltersExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _mobileFiltersExpanded
                                    ? 'إخفاء التصفية'
                                    : 'إظهار التصفية',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_mobileFiltersExpanded) ...[
                        const SizedBox(height: 8),
                        _buildFilterPanel(scrollable: false),
                      ],
                      const SizedBox(height: 8),
                      _buildSearchField(),
                      const SizedBox(height: 8),
                      _buildBulkSelectionBar(
                        canEdit: canEdit,
                        canDelete: canDelete,
                        canAdd: canAdd,
                      ),
                      if (_records.isNotEmpty) const SizedBox(height: 8),
                      if (_records.isEmpty && !_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text('لا توجد سجلات حضور مطابقة للتصفية'),
                          ),
                        )
                      else
                        _buildAttendanceList(
                          shrinkWrap: true,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          canAdd: canAdd,
                        ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    if (canAdd) _buildInlineForm(isMobile),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 300,
                            child: SingleChildScrollView(
                              child: _buildFilterPanel(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildSearchField(),
                                const SizedBox(height: 8),
                                _buildBulkSelectionBar(
                                  canEdit: canEdit,
                                  canDelete: canDelete,
                                  canAdd: canAdd,
                                ),
                                if (_records.isNotEmpty)
                                  const SizedBox(height: 8),
                                Expanded(
                                  child: _records.isEmpty && !_isLoading
                                      ? const Center(
                                          child: Text(
                                            'لا توجد سجلات حضور مطابقة للتصفية',
                                          ),
                                        )
                                      : _buildAttendanceList(
                                          canEdit: canEdit,
                                          canDelete: canDelete,
                                          canAdd: canAdd,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل الحضور',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'متابعة حضور الأشخاص وتوزيع النقاط والافتقاد',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSingleCard('الإجمالي', _totalCount, Colors.blue),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          _buildSingleCard('الحضور', _presentCount, Colors.green),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          _buildSingleCard('الغياب', _absentCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSingleCard(String title, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineForm(bool isMobile) {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final services = servicesAsync.asData?.value ?? [];
    return Card(
      elevation: 3,
      color: const Color(0xFFF5F7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'تسجيل حضور سريع',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                // Check-in / Check-out Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isCheckoutMode
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCheckoutMode
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleButton(false, 'حضور', Colors.green),
                      _toggleButton(true, 'انصراف', Colors.red),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPeriodModeControls(isMobile),
            const SizedBox(height: 12),
            if (isMobile) ...[
              _buildPersonAutocomplete(),
              const SizedBox(height: 10),
              if (services.isNotEmpty) ...[
                _buildServiceDropdownInline(services),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(child: _buildDateField()),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: _buildPointsField()),
                  const SizedBox(width: 10),
                  _buildSaveButton(),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(flex: 3, child: _buildPersonAutocomplete()),
                  if (services.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: _buildServiceDropdownInline(services),
                    ),
                  ],
                  const SizedBox(width: 12),
                  SizedBox(width: 160, child: _buildDateField()),
                  const SizedBox(width: 12),
                  SizedBox(width: 80, child: _buildPointsField()),
                  const SizedBox(width: 12),
                  _buildSaveButton(),
                ],
              ),
            if (_isCheckoutMode) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSaving || _isCheckingOutAll || _periodModeEnabled)
                      ? null
                      : _checkoutAll,
                  icon: _isCheckingOutAll
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Icon(Icons.groups_rounded, size: 16),
                  label: const Text(
                    'انصراف الكل',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodModeControls(bool isMobile) {
    final startText = _periodStartDate == null
        ? 'بداية الفترة'
        : DateFormat('yyyy-MM-dd').format(_periodStartDate!);
    final endText = _periodEndDate == null
        ? 'نهاية الفترة'
        : DateFormat('yyyy-MM-dd').format(_periodEndDate!);
    final controls = [
      FilterChip(
        selected: _periodModeEnabled,
        avatar: Icon(
          _periodModeEnabled ? Icons.event_busy : Icons.date_range,
          size: 18,
        ),
        label: const Text('فترة'),
        onSelected: _togglePeriodMode,
      ),
      OutlinedButton.icon(
        onPressed: _periodModeEnabled
            ? () => _pickPeriodDate(start: true)
            : null,
        icon: const Icon(Icons.today_outlined, size: 16),
        label: Text(startText),
      ),
      OutlinedButton.icon(
        onPressed: _periodModeEnabled
            ? () => _pickPeriodDate(start: false)
            : null,
        icon: const Icon(Icons.event_outlined, size: 16),
        label: Text(endText),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _periodModeEnabled ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _periodModeEnabled
              ? Colors.orange.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Wrap(spacing: 8, runSpacing: 8, children: controls)
                : Row(
                    children: [
                      controls[0],
                      const SizedBox(width: 8),
                      controls[1],
                      const SizedBox(width: 8),
                      controls[2],
                    ],
                  ),
            if (_periodModeEnabled) ...[
              const SizedBox(height: 6),
              Text(
                'التسجيل متوقف في وضع الفترة. التقارير والفلاتر تستخدم تاريخ البداية والنهاية لمعرفة الحاضرين أو الغائبين.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDropdownInline(List<ServiceDTO> services) {
    return DropdownButtonFormField<int?>(
      value: _selectedServiceId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'الخدمة',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('اختر الخدمة')),
        ...services.map(
          (s) => DropdownMenuItem(
            value: s.id,
            child: Text(
              '${s.name} - ${s.dayName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() {
          _selectedServiceId = v;
        });
      },
    );
  }

  Widget _buildPersonAutocomplete() {
    final personsAsync = ref.watch(personsRepositoryProvider);
    return personsAsync.when(
      data: (persons) {
        Future<void> submitCode(String value) async {
          if (_isSaving) return;
          final query = value.trim();
          if (query.isNotEmpty) {
            final lowerQ = query.toLowerCase();
            final intQ = int.tryParse(lowerQ);

            final exactMatch = persons
                .where(
                  (p) =>
                      p.id.toString() == lowerQ ||
                      p.name.toLowerCase() == lowerQ ||
                      (intQ != null && p.id == intQ),
                )
                .toList();

            final partialMatch = persons
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(lowerQ) ||
                      p.id.toString().contains(lowerQ),
                )
                .toList();

            final matchToUse = exactMatch.isNotEmpty
                ? exactMatch
                : partialMatch;
            if (matchToUse.length == 1) {
              setState(() {
                _selectedPersonId = matchToUse.first.id;
                _selectedPersonName = matchToUse.first.name;
              });
              await _saveAttendance();
            } else if (matchToUse.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لم يتم العثور على شخص'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أكثر من شخص بنفس الاسم. حدد بدقة.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else if (_selectedPersonId != null) {
            await _saveAttendance();
          }
        }

        Future<void> openContinuousQrScanner(
          TextEditingController controller,
        ) async {
          if (_isSaving) return;
          try {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => QrScannerScreen(
                  onCodeScanned: (rawValue) async {
                    if (!mounted) return;
                    final scannedCode = _extractAttendanceCodeFromScan(
                      rawValue,
                    );
                    if (scannedCode.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لم يتم قراءة كود صالح'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    controller.text = scannedCode;
                    controller.selection = TextSelection.collapsed(
                      offset: scannedCode.length,
                    );
                    await submitCode(scannedCode);
                  },
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تعذر فتح الكاميرا: $e'),
                backgroundColor: Colors.red,
              ),
            );
          } finally {
            if (mounted) _refocusCodeField();
          }
        }

        return Autocomplete<PersonOption>(
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim();
            if (query.isEmpty)
              return persons.map((p) => PersonOption(id: p.id, name: p.name));

            final lowerQ = query.toLowerCase();
            final intQ = int.tryParse(lowerQ);

            return persons
                .where((p) {
                  final idMatch =
                      p.id.toString() == lowerQ ||
                      (intQ != null && p.id == intQ);
                  return p.name.toLowerCase().contains(lowerQ) || idMatch;
                })
                .map((p) => PersonOption(id: p.id, name: p.name));
          },
          displayStringForOption: (option) => '${option.id} - ${option.name}',
          onSelected: (option) async {
            setState(() {
              _selectedPersonId = option.id;
              _selectedPersonName = option.name;
            });
            await _saveAttendance();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            _autocompleteController = controller;
            _internalFocusNode = focusNode;
            if (!_isCodeFocusBridgeAttached) {
              _isCodeFocusBridgeAttached = true;
              _codeFocusNode.addListener(() {
                if (_codeFocusNode.hasFocus && !focusNode.hasFocus)
                  focusNode.requestFocus();
              });
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'اكتب الكود أو الاسم...',
                prefixIcon: const Icon(Icons.person_search, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedPersonId != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    IconButton(
                      tooltip: 'فحص QR الكارنيه',
                      onPressed: _isSaving
                          ? null
                          : () => openContinuousQrScanner(controller),
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                    ),
                  ],
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) async {
                if (_isSaving) return;
                final query = value.trim();
                if (query.isNotEmpty) {
                  final lowerQ = query.toLowerCase();
                  final intQ = int.tryParse(lowerQ);

                  final exactMatch = persons
                      .where(
                        (p) =>
                            p.id.toString() == lowerQ ||
                            p.name.toLowerCase() == lowerQ ||
                            (intQ != null && p.id == intQ),
                      )
                      .toList();

                  final partialMatch = persons
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(lowerQ) ||
                            p.id.toString().contains(lowerQ),
                      )
                      .toList();

                  final matchToUse = exactMatch.isNotEmpty
                      ? exactMatch
                      : partialMatch;
                  if (matchToUse.length == 1) {
                    setState(() {
                      _selectedPersonId = matchToUse.first.id;
                      _selectedPersonName = matchToUse.first.name;
                    });
                    await _saveAttendance();
                  } else if (matchToUse.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لم يتم العثور على شخص'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('أكثر من شخص بنفس الاسم. حدد بدقة.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else if (_selectedPersonId != null) {
                  await _saveAttendance();
                }
              },
            );
          },
        );
      },
      error: (err, stack) => const Center(child: Text('خطأ في تحميل البيانات')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _filterSpecificDateOnly = true;
          });
          _loadInitialData();
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'التاريخ',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsField() {
    return TextField(
      controller: _pointsController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: 'النقاط',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: (_isSaving || _periodModeEnabled) ? null : _saveAttendance,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(
          _isCheckoutMode ? 'سجل انصراف' : 'سجل حضور',
          style: const TextStyle(fontSize: 13),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _isCheckoutMode ? Colors.red : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBulkSelectionBar({
    required bool canEdit,
    required bool canDelete,
    required bool canAdd,
  }) {
    if (_records.isEmpty) return const SizedBox.shrink();

    final visibleIds = _records.map((r) => r.personId).toSet();
    final selectedCount = visibleIds.where(_selectedPersonIds.contains).length;
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedPersonIds.contains);
    final hasSelectedRecords = _selectedAttendanceIds.isNotEmpty;
    final hasPendingCheckout = _selectedRecords.any(
      (r) =>
          r.id != null &&
          r.attendTime != null &&
          (r.checkoutTime == null || r.checkoutTime!.isEmpty),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selectedCount == 0 ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedCount == 0
              ? Colors.grey.shade200
              : Colors.blue.shade100,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _toggleSelectAllVisible,
            icon: Icon(
              allSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
            ),
            label: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
          ),
          if (selectedCount > 0)
            Chip(
              avatar: const Icon(Icons.people_alt_outlined, size: 16),
              label: Text('$selectedCount محدد'),
              visualDensity: VisualDensity.compact,
            ),
          if (selectedCount > 0 && canEdit && hasSelectedRecords)
            FilledButton.icon(
              onPressed: _isBulkActionRunning ? null : _applyPointsToSelected,
              icon: const Icon(Icons.exposure_outlined, size: 18),
              label: const Text('تطبيق النقاط'),
            ),
          if (selectedCount > 0 &&
              _isCheckoutMode &&
              canAdd &&
              hasPendingCheckout)
            FilledButton.icon(
              onPressed: _isBulkActionRunning ? null : _checkoutSelected,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('انصراف المحددين'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
          if (selectedCount > 0 && !_isCheckoutMode && canDelete)
            OutlinedButton.icon(
              onPressed: _isBulkActionRunning
                  ? null
                  : _cancelSelectedAttendance,
              icon: const Icon(Icons.event_busy_rounded, size: 18),
              label: const Text('إلغاء الحضور'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          if (selectedCount > 0 && _isCheckoutMode && canEdit)
            OutlinedButton.icon(
              onPressed: _isBulkActionRunning ? null : _cancelSelectedCheckout,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('إلغاء الانصراف'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          if (selectedCount > 0)
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.close),
              tooltip: 'مسح التحديد',
            ),
        ],
      ),
    );
  }

  Widget _toggleButton(bool val, String label, Color color) {
    final active = _isCheckoutMode == val;
    return GestureDetector(
      onTap: _periodModeEnabled
          ? null
          : () => setState(() {
              _isCheckoutMode = val;
              if (val) {
                _pointsController.text = '$_defaultAttendancePoints';
              }
            }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : color.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // =================== FILTER PANEL ===================
  Widget _buildFilterPanel({bool scrollable = true}) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilterGroup(
            '👤 بيانات المخدوم',
            _showPersonFilters,
            (v) => setState(() => _showPersonFilters = v),
            _buildPersonFilters(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildFilterGroup(
            '📅 الحضور والغياب',
            _showAttendanceFilters,
            (v) => setState(() => _showAttendanceFilters = v),
            _buildAttendanceFilters(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildFilterGroup(
            '🏠 الافتقاد والمتابعة',
            _showVisitationFilters,
            (v) => setState(() => _showVisitationFilters = v),
            _buildVisitationFilters(),
          ),
        ],
      ),
    );

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }

  Widget _buildFilterGroup(
    String title,
    bool expanded,
    ValueChanged<bool> onToggle,
    Widget content,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () => onToggle(!expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[const SizedBox(height: 12), content],
      ],
    );
  }

  Widget _buildPersonFilters() {
    final fields = ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
    String getLabel(String key, String fallback) {
      final f = fields.where((f) => f.fieldKey == key).firstOrNull;
      return f?.name ?? fallback;
    }

    return Column(
      children: [
        // Gender
        MultiSelectFilter(
          label: getLabel('gender', 'النوع'),
          selectedIds: _filterGenders,
          allItems: [
            SelectableItem(id: 'ذكر', name: 'ذكر'),
            SelectableItem(id: 'أنثى', name: 'أنثى'),
          ],
          onChanged: (ids) {
            setState(() => _filterGenders = List<String>.from(ids));
            _loadInitialData();
          },
        ),
        const SizedBox(height: 12),
        // Stage
        ref
            .watch(stagesRepositoryProvider)
            .when(
              data: (stages) => MultiSelectFilter(
                label: getLabel('stage', 'المرحلة'),
                selectedIds: _filterStageIds,
                allItems: stages
                    .map((s) => SelectableItem(id: s.id, name: s.name))
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterStageIds = List<int>.from(ids));
                  _loadInitialData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Err: $e'),
            ),
        const SizedBox(height: 12),
        // Khoros
        ref
            .watch(khorosRepositoryProvider)
            .when(
              data: (khoroses) => MultiSelectFilter(
                label: getLabel('khoros', 'الخورس'),
                selectedIds: _filterKhorosIds,
                allItems: khoroses
                    .map((k) => SelectableItem(id: k.id, name: k.name))
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterKhorosIds = List<int>.from(ids));
                  _loadInitialData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Err: $e'),
            ),
        const SizedBox(height: 12),
        // Area
        ref
            .watch(areasRepositoryProvider)
            .when(
              data: (areas) => MultiSelectFilter(
                label: getLabel('area', 'المنطقة'),
                selectedIds: _filterAreaIds,
                allItems: areas
                    .map((a) => SelectableItem(id: a.id, name: a.name))
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterAreaIds = List<int>.from(ids));
                  _loadInitialData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Err: $e'),
            ),
        const SizedBox(height: 12),
        // Father
        ref
            .watch(fathersRepositoryProvider)
            .when(
              data: (fathers) => MultiSelectFilter(
                label: getLabel('father', 'الأب'),
                selectedIds: _filterFatherIds,
                allItems: fathers
                    .map((f) => SelectableItem(id: f.id, name: f.name))
                    .toList(),
                onChanged: (ids) {
                  setState(() => _filterFatherIds = List<int>.from(ids));
                  _loadInitialData();
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Err: $e'),
            ),
        const SizedBox(height: 12),
        // Birthday filters
        MultiSelectFilter(
          label: 'يوم (${getLabel('birthday', 'الميلاد')})',
          selectedIds: _filterBirthdayDay,
          allItems: List.generate(
            31,
            (i) => SelectableItem(id: i + 1, name: '${i + 1}'),
          ),
          onChanged: (ids) {
            setState(() => _filterBirthdayDay = List<int>.from(ids));
            _loadInitialData();
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
            _loadInitialData();
          },
        ),
        const SizedBox(height: 12),
        MultiSelectFilter(
          label: 'سنة (${getLabel('birthday', 'الميلاد')})',
          selectedIds: _filterBirthdayYear,
          allItems: List.generate(80, (i) {
            final y = DateTime.now().year - i;
            return SelectableItem(id: y, name: '$y');
          }),
          onChanged: (ids) {
            setState(() => _filterBirthdayYear = List<int>.from(ids));
            _loadInitialData();
          },
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        // Dynamic Custom Filters
        Consumer(
          builder: (context, ref, child) {
            final fields =
                ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
            final filterableFields = fields
                .where((f) => f.isFilter && f.type != 'native')
                .toList();

            if (filterableFields.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فلاتر إضافية:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...filterableFields.map((f) {
                  if (f.type == 'text') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: f.name,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: _customFilters[f.id]?.isNotEmpty == true
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() => _customFilters.remove(f.id));
                                    _loadInitialData();
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (v) {
                          setState(() => _customFilters[f.id] = v);
                          _loadInitialData();
                        },
                      ),
                    );
                  } else if (f.type == 'dropdown') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String?>(
                        value: _customFilters[f.id] as String?,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: f.name,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('كل ${f.name}'),
                          ),
                          ...f.options.map(
                            (opt) =>
                                DropdownMenuItem(value: opt, child: Text(opt)),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == null)
                              _customFilters.remove(f.id);
                            else
                              _customFilters[f.id] = v;
                          });
                          _loadInitialData();
                        },
                      ),
                    );
                  } else if (f.type == 'multi_select') {
                    final selected =
                        (_customFilters[f.id] as List<String>?) ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
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
                            children: f.options.map((opt) {
                              final isSelected = selected.contains(opt);
                              return FilterChip(
                                label: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: Theme.of(context).primaryColor,
                                checkmarkColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
                                  _loadInitialData();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  } else if (f.type == 'checkbox') {
                    final checkedLabel = f.options.isNotEmpty
                        ? f.options[0]
                        : 'نعم';
                    final uncheckedLabel = f.options.length > 1
                        ? f.options[1]
                        : 'لا';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String?>(
                        value: _customFilters[f.id] as String?,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: f.name,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('كل ${f.name}'),
                          ),
                          DropdownMenuItem(
                            value: checkedLabel,
                            child: Text(checkedLabel),
                          ),
                          DropdownMenuItem(
                            value: uncheckedLabel,
                            child: Text(uncheckedLabel),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == null)
                              _customFilters.remove(f.id);
                            else
                              _customFilters[f.id] = v;
                          });
                          _loadInitialData();
                        },
                      ),
                    );
                  } else if (f.type == 'document') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String?>(
                        value: _customFilters[f.id] as String?,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: f.name,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('كل ${f.name}'),
                          ),
                          const DropdownMenuItem(
                            value: 'has_files',
                            child: Text('لديه مرفقات'),
                          ),
                          const DropdownMenuItem(
                            value: 'no_files',
                            child: Text('ليس لديه مرفقات'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == null)
                              _customFilters.remove(f.id);
                            else
                              _customFilters[f.id] = v;
                          });
                          _loadInitialData();
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceFilters() {
    return Column(
      children: [
        // Month & Year
        MultiSelectFilter(
          label: 'الشهر',
          selectedIds: _filterMonth,
          allItems: List.generate(
            12,
            (i) => SelectableItem(id: i + 1, name: 'شهر ${i + 1}'),
          ),
          onChanged: (ids) {
            setState(() => _filterMonth = List<int>.from(ids));
            _loadInitialData();
          },
        ),
        const SizedBox(height: 12),
        MultiSelectFilter(
          label: 'السنة',
          selectedIds: _filterYear,
          allItems: List.generate(15, (i) {
            final y = DateTime.now().year - i;
            return SelectableItem(id: y, name: '$y');
          }),
          onChanged: (ids) {
            setState(() => _filterYear = List<int>.from(ids));
            _loadInitialData();
          },
        ),
        const SizedBox(height: 8),
        // Status
        DropdownButtonFormField<String>(
          value: _filterStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'قائمة الحضور',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('الكل')),
            DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
            DropdownMenuItem(value: 'absent', child: Text('الغائبين')),
            DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
            DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
          ],
          onChanged: (v) {
            setState(() => _filterStatus = v ?? 'all');
            _loadInitialData();
          },
        ),
        const SizedBox(height: 8),
        // Today only toggle
        Row(
          children: [
            Switch(
              value: _filterSpecificDateOnly,
              onChanged: (v) {
                setState(() => _filterSpecificDateOnly = v);
                _loadInitialData();
              },
            ),
            const Text(
              'تاريخ اليوم فقط',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Date range
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _filterDateFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (p != null) {
                    setState(() {
                      _filterDateFrom = p;
                      _filterSpecificDateOnly = false;
                    });
                    _loadInitialData();
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'من',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _filterDateFrom == null
                        ? '-'
                        : DateFormat('MM-dd').format(_filterDateFrom!),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _filterDateTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (p != null) {
                    setState(() {
                      _filterDateTo = p;
                      _filterSpecificDateOnly = false;
                    });
                    _loadInitialData();
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'إلى',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _filterDateTo == null
                        ? '-'
                        : DateFormat('MM-dd').format(_filterDateTo!),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            if (_filterDateFrom != null || _filterDateTo != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _filterDateFrom = null;
                    _filterDateTo = null;
                  });
                  _loadInitialData();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Late after time
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime:
                  _filterLateAfter ?? const TimeOfDay(hour: 17, minute: 0),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(alwaysUse24HourFormat: false),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() => _filterLateAfter = picked);
              _loadInitialData();
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'التأخير عن',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _filterLateAfter != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() => _filterLateAfter = null);
                        _loadInitialData();
                      },
                    )
                  : null,
            ),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: Builder(
                builder: (ctx) => Text(
                  _filterLateAfter == null
                      ? 'اختر وقت'
                      : _filterLateAfter!.format(ctx),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitationFilters() {
    return Column(
      children: [
        DropdownButtonFormField<int?>(
          value: _filterVisitedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'حالة الافتقاد',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('الكل')),
            DropdownMenuItem(value: 0, child: Text('لم يتم')),
            DropdownMenuItem(value: 2, child: Text('تم')),
          ],
          onChanged: (v) {
            setState(() => _filterVisitedStatus = v);
            _loadInitialData();
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _filterNotesStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'ملاحظات',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('الكل')),
            DropdownMenuItem(value: 'with', child: Text('به ملاحظات')),
            DropdownMenuItem(value: 'without', child: Text('بدون')),
          ],
          onChanged: (v) {
            setState(() => _filterNotesStatus = v ?? 'all');
            _loadInitialData();
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'بحث بالإسم أو الكود...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGridPrintButton(),
                const SizedBox(width: 8),
                _buildGridExcelButton(),
                const SizedBox(width: 8),
                _buildPrintButton(),
                const SizedBox(width: 8),
                _buildListExcelButton(),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'بحث بالإسم أو الكود...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildGridPrintButton(),
        const SizedBox(width: 8),
        _buildGridExcelButton(),
        const SizedBox(width: 8),
        _buildPrintButton(),
        const SizedBox(width: 8),
        _buildListExcelButton(),
      ],
    );
  }

  Widget _buildListExcelButton() {
    return ElevatedButton.icon(
      onPressed: _records.isEmpty
          ? null
          : () async {
              final servicesAsync = ref.read(servicesRepositoryProvider);
              final services = servicesAsync.asData?.value ?? [];

              final periodServiceResult =
                  await showDialog<PrintPeriodServicesResult>(
                    context: context,
                    builder: (c) => PrintPeriodServicesDialog(
                      anchorDate: _selectedDate,
                      services: services,
                    ),
                  );
              if (periodServiceResult == null) return;

              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(),
              );
              if (result != null) {
                final List<String> sorting =
                    (result['sorting'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<String> headerIds =
                    (result['header'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<Map<String, String>> cols =
                    (result['columns'] as List)
                        .map(
                          (c) => {
                            'id': c.id.toString(),
                            'title': c.title.toString(),
                            'isPhone': c.isPhone.toString(),
                          },
                        )
                        .toList();

                final db = ref.read(appDatabaseProvider);
                final Map<String, String> headerData = {};

                if (headerIds.contains('church_name')) {
                  final cn = await ref
                      .read(settingsRepositoryProvider)
                      .getSetting('church_name');
                  if (cn != null && cn.isNotEmpty)
                    headerData['اسم الكنيسة'] = cn;
                }
                if (headerIds.contains('service_name')) {
                  headerData['الخدمة'] = periodServiceResult.serviceLabel;
                }
                headerData['الفترة'] = periodServiceResult.periodLabel;

                if (headerIds.contains('khoros')) {
                  if (_filterKhorosIds.isNotEmpty) {
                    final items = await (db.select(
                      db.khoroses,
                    )..where((t) => t.khorosId.isIn(_filterKhorosIds))).get();
                    headerData['الخورس'] = items
                        .map((e) => e.khorosName)
                        .join('، ');
                  } else {
                    headerData['الخورس'] = 'كل الخوارس';
                  }
                }
                if (headerIds.contains('stage')) {
                  if (_filterStageIds.isNotEmpty) {
                    final items = await (db.select(
                      db.stages,
                    )..where((t) => t.stageId.isIn(_filterStageIds))).get();
                    headerData['المرحلة'] = items
                        .map((e) => e.stageName)
                        .join('، ');
                  } else {
                    headerData['المرحلة'] = 'كل المراحل';
                  }
                }
                if (headerIds.contains('area')) {
                  if (_filterAreaIds.isNotEmpty) {
                    final items = await (db.select(
                      db.areas,
                    )..where((t) => t.areaId.isIn(_filterAreaIds))).get();
                    headerData['المنطقة'] = items
                        .map((e) => e.areaName)
                        .join('، ');
                  } else {
                    headerData['المنطقة'] = 'كل المناطق';
                  }
                }
                if (headerIds.contains('father')) {
                  if (_filterFatherIds.isNotEmpty) {
                    final items = await (db.select(
                      db.fathers,
                    )..where((t) => t.fatherId.isIn(_filterFatherIds))).get();
                    headerData['أب الاعتراف'] = items
                        .map((e) => e.fatherName)
                        .join('، ');
                  } else {
                    headerData['أب الاعتراف'] = 'كل الآباء';
                  }
                }

                final repo = ref.read(attendanceRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات الحضور للإكسل...',
                );

                try {
                  progress.update('جاري تحميل كل سجلات الحضور المطابقة...');
                  final allData = await repo.fetchAttendance(
                    month: _filterMonth,
                    year: _filterYear,
                    search: _searchQuery,
                    dateFrom: periodServiceResult.dateFrom,
                    dateTo: periodServiceResult.dateTo,
                    stageIds: _filterStageIds,
                    khorosIds: _filterKhorosIds,
                    areaIds: _filterAreaIds,
                    fatherIds: _filterFatherIds,
                    genders: _filterGenders,
                    birthdayDay: _filterBirthdayDay,
                    birthdayMonth: _filterBirthdayMonth,
                    birthdayYear: _filterBirthdayYear,
                    status: _filterStatus,
                    serviceIds: periodServiceResult.selectedServiceIds,
                    visitedStatus: _filterVisitedStatus,
                    notesFilter: _filterNotesStatus,
                    lateAfterTime: _lateAfterTimeString(),
                    customFilters: _customFilters,
                    deduplicatePeople: false,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }

                  // Sort the data based on user criteria
                  allData.sort((a, b) {
                    for (var criterion in sorting) {
                      int cmp = 0;
                      if (criterion == 'area') {
                        cmp = (a.areaName ?? '').compareTo(b.areaName ?? '');
                      } else if (criterion == 'stage') {
                        cmp = (a.stageName ?? '').compareTo(b.stageName ?? '');
                      } else if (criterion == 'father') {
                        cmp = (a.fatherName ?? '').compareTo(
                          b.fatherName ?? '',
                        );
                      } else if (criterion == 'name') {
                        cmp = (a.personName ?? '').compareTo(
                          b.personName ?? '',
                        );
                      }
                      if (cmp != 0) return cmp;
                    }
                    return 0;
                  });

                  final svcsData =
                      ref.read(servicesRepositoryProvider).asData?.value ?? [];
                  final Map<int, int> serviceMinsMap = {
                    for (var s in svcsData) s.id: s.hour * 60 + s.minute,
                  };

                  progress.update('جاري إنشاء ملف إكسل...');
                  final path = await ExcelExportService.exportAttendanceList(
                    data: allData,
                    columns: cols,
                    headerData: headerData,
                    serviceMinsMap: serviceMinsMap,
                  );
                  progress.close();

                  if (mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم حفظ ملف الإكسل بنجاح في: $path'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء التصدير للإكسل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
      icon: const Icon(Icons.table_view, size: 18),
      label: const Text('إكسل قائمة', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildGridExcelButton() {
    return ElevatedButton.icon(
      onPressed: _records.isEmpty
          ? null
          : () async {
              final servicesAsync = ref.read(servicesRepositoryProvider);
              final services = servicesAsync.asData?.value ?? [];

              final periodServiceResult =
                  await showDialog<PrintPeriodServicesResult>(
                    context: context,
                    builder: (c) => PrintPeriodServicesDialog(
                      anchorDate: _selectedDate,
                      services: services,
                    ),
                  );
              if (periodServiceResult == null) return;

              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(isAttendance: true),
              );
              if (result != null) {
                final List<String> sorting =
                    (result['sorting'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<String> headerIds =
                    (result['header'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<Map<String, String>> cols =
                    (result['columns'] as List)
                        .map(
                          (c) => {
                            'id': c.id.toString(),
                            'title': c.title.toString(),
                            'isPhone': c.isPhone.toString(),
                          },
                        )
                        .toList();

                final db = ref.read(appDatabaseProvider);
                final settingsRepo = ref.read(settingsRepositoryProvider);
                final churchNameReal = await settingsRepo.getSetting(
                  'church_name',
                );

                final Map<String, String> headerData = {};
                final fields =
                    ref.read(fieldsRepositoryProvider).asData?.value ?? [];
                final labels = {
                  for (var f in fields)
                    if (f.fieldKey != null) f.fieldKey!: f.name,
                };
                String getL(String key, String fallback) =>
                    labels[key] ?? fallback;

                if (headerIds.contains('church_name')) {
                  headerData['الكنيسة'] = churchNameReal ?? '';
                }
                if (headerIds.contains('service_name')) {
                  headerData['الخدمة'] = periodServiceResult.serviceLabel;
                }
                headerData['الفترة'] = periodServiceResult.periodLabel;

                if (headerIds.contains('khoros')) {
                  if (_filterKhorosIds.isNotEmpty) {
                    final items = await (db.select(
                      db.khoroses,
                    )..where((t) => t.khorosId.isIn(_filterKhorosIds))).get();
                    headerData[getL('khoros', 'الخورس')] = items
                        .map((e) => e.khorosName)
                        .join('، ');
                  } else {
                    headerData[getL('khoros', 'الخورس')] = 'كل الخوارس';
                  }
                }
                if (headerIds.contains('stage')) {
                  if (_filterStageIds.isNotEmpty) {
                    final items = await (db.select(
                      db.stages,
                    )..where((t) => t.stageId.isIn(_filterStageIds))).get();
                    headerData[getL('stage', 'المرحلة')] = items
                        .map((e) => e.stageName)
                        .join('، ');
                  } else {
                    headerData[getL('stage', 'المرحلة')] = 'كل المراحل';
                  }
                }
                if (headerIds.contains('area')) {
                  if (_filterAreaIds.isNotEmpty) {
                    final items = await (db.select(
                      db.areas,
                    )..where((t) => t.areaId.isIn(_filterAreaIds))).get();
                    headerData[getL('area', 'المنطقة')] = items
                        .map((e) => e.areaName)
                        .join('، ');
                  } else {
                    headerData[getL('area', 'المنطقة')] = 'كل المناطق';
                  }
                }
                if (headerIds.contains('father')) {
                  if (_filterFatherIds.isNotEmpty) {
                    final items = await (db.select(
                      db.fathers,
                    )..where((t) => t.fatherId.isIn(_filterFatherIds))).get();
                    headerData[getL('father', 'أب الاعتراف')] = items
                        .map((e) => e.fatherName)
                        .join('، ');
                  } else {
                    headerData[getL('father', 'أب الاعتراف')] = 'كل الآباء';
                  }
                }

                final repo = ref.read(attendanceRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات شبكة الحضور للإكسل...',
                );

                try {
                  progress.update('جاري تحميل كل سجلات الحضور المطابقة...');
                  final allData = await repo.fetchAttendance(
                    month: _filterMonth,
                    year: _filterYear,
                    search: _searchQuery,
                    dateFrom: periodServiceResult.dateFrom,
                    dateTo: periodServiceResult.dateTo,
                    stageIds: _filterStageIds,
                    khorosIds: _filterKhorosIds,
                    areaIds: _filterAreaIds,
                    fatherIds: _filterFatherIds,
                    genders: _filterGenders,
                    birthdayDay: _filterBirthdayDay,
                    birthdayMonth: _filterBirthdayMonth,
                    birthdayYear: _filterBirthdayYear,
                    status: _filterStatus,
                    serviceIds: periodServiceResult.selectedServiceIds,
                    visitedStatus: _filterVisitedStatus,
                    notesFilter: _filterNotesStatus,
                    lateAfterTime: _lateAfterTimeString(),
                    customFilters: _customFilters,
                    deduplicatePeople: false,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }

                  // Sort the data based on user criteria
                  allData.sort((a, b) {
                    for (var criterion in sorting) {
                      int cmp = 0;
                      if (criterion == 'area') {
                        cmp = (a.areaName ?? '').compareTo(b.areaName ?? '');
                      } else if (criterion == 'stage') {
                        cmp = (a.stageName ?? '').compareTo(b.stageName ?? '');
                      } else if (criterion == 'father') {
                        cmp = (a.fatherName ?? '').compareTo(
                          b.fatherName ?? '',
                        );
                      } else if (criterion == 'name') {
                        cmp = (a.personName ?? '').compareTo(
                          b.personName ?? '',
                        );
                      } else if (criterion == 'khoros') {
                        cmp = (a.khorosName ?? '').compareTo(
                          b.khorosName ?? '',
                        );
                      }
                      if (cmp != 0) return cmp;
                    }
                    return 0;
                  });

                  // Extract unique Date+Service combinations
                  final Set<String> uniqueDatesSet = {};
                  for (var r in allData) {
                    if (r.dateWeek != null && r.dateWeek!.isNotEmpty) {
                      final d = r.dateWeek!;
                      final s = r.serviceName?.trim() ?? '';
                      uniqueDatesSet.add('$d|$s');
                    }
                  }
                  final List<String> sortedDates = uniqueDatesSet.toList()
                    ..sort(
                      (a, b) => a.split('|')[0].compareTo(b.split('|')[0]),
                    );

                  final svcsData =
                      ref.read(servicesRepositoryProvider).asData?.value ?? [];
                  final Map<int, int> serviceMinsMap = {
                    for (var s in svcsData) s.id: s.hour * 60 + s.minute,
                  };

                  progress.update('جاري إنشاء ملف إكسل...');
                  final path = await ExcelExportService.exportAttendanceGrid(
                    data: allData,
                    columns: cols,
                    dates: sortedDates,
                    headerData: headerData,
                    serviceMinsMap: serviceMinsMap,
                  );
                  progress.close();

                  if (mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم حفظ ملف الإكسل بنجاح في: $path'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء التصدير للإكسل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
      icon: const Icon(Icons.grid_on, size: 18),
      label: const Text('إكسل شبكة', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildPrintButton() {
    return ElevatedButton.icon(
      onPressed: _records.isEmpty
          ? null
          : () async {
              final servicesAsync = ref.read(servicesRepositoryProvider);
              final services = servicesAsync.asData?.value ?? [];

              final periodServiceResult =
                  await showDialog<PrintPeriodServicesResult>(
                    context: context,
                    builder: (c) => PrintPeriodServicesDialog(
                      anchorDate: _selectedDate,
                      services: services,
                    ),
                  );
              if (periodServiceResult == null) return;

              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(),
              );
              if (result != null) {
                final List<String> sorting =
                    (result['sorting'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<String> headerIds =
                    (result['header'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<Map<String, String>> cols =
                    (result['columns'] as List)
                        .map(
                          (c) => {
                            'id': c.id.toString(),
                            'title': c.title.toString(),
                            'isPhone': c.isPhone.toString(),
                          },
                        )
                        .toList();
                final bool separatePages =
                    result['separatePages'] as bool? ?? false;
                final exportOptions =
                    result['exportOptions'] as PdfExportOptions? ??
                    const PdfExportOptions();

                final db = ref.read(appDatabaseProvider);
                final Map<String, String> headerData = {};

                if (headerIds.contains('church_name')) {
                  final cn = await ref
                      .read(settingsRepositoryProvider)
                      .getSetting('church_name');
                  if (cn != null && cn.isNotEmpty)
                    headerData['اسم الكنيسة'] = cn;
                }
                if (headerIds.contains('service_name')) {
                  headerData['الخدمة'] = periodServiceResult.serviceLabel;
                }
                headerData['الفترة'] = periodServiceResult.periodLabel;

                if (headerIds.contains('khoros')) {
                  if (_filterKhorosIds.isNotEmpty) {
                    final items = await (db.select(
                      db.khoroses,
                    )..where((t) => t.khorosId.isIn(_filterKhorosIds))).get();
                    headerData['الخورس'] = items
                        .map((e) => e.khorosName)
                        .join('، ');
                  } else {
                    headerData['الخورس'] = 'كل الخوارس';
                  }
                }
                if (headerIds.contains('stage')) {
                  if (_filterStageIds.isNotEmpty) {
                    final items = await (db.select(
                      db.stages,
                    )..where((t) => t.stageId.isIn(_filterStageIds))).get();
                    headerData['المرحلة'] = items
                        .map((e) => e.stageName)
                        .join('، ');
                  } else {
                    headerData['المرحلة'] = 'كل المراحل';
                  }
                }
                if (headerIds.contains('area')) {
                  if (_filterAreaIds.isNotEmpty) {
                    final items = await (db.select(
                      db.areas,
                    )..where((t) => t.areaId.isIn(_filterAreaIds))).get();
                    headerData['المنطقة'] = items
                        .map((e) => e.areaName)
                        .join('، ');
                  } else {
                    headerData['المنطقة'] = 'كل المناطق';
                  }
                }
                if (headerIds.contains('father')) {
                  if (_filterFatherIds.isNotEmpty) {
                    final items = await (db.select(
                      db.fathers,
                    )..where((t) => t.fatherId.isIn(_filterFatherIds))).get();
                    headerData['أب الاعتراف'] = items
                        .map((e) => e.fatherName)
                        .join('، ');
                  } else {
                    headerData['أب الاعتراف'] = 'كل الآباء';
                  }
                }

                // Fetch logos
                final settingsRepo = ref.read(settingsRepositoryProvider);
                final churchLogo = await settingsRepo.getChurchLogo();
                final churchName = await settingsRepo.getSetting('church_name');

                // Get all selected services' logos
                final List<Uint8List> serviceLogos = [];
                for (var id in periodServiceResult.selectedServiceIds) {
                  final svc = services.where((s) => s.id == id).firstOrNull;
                  if (svc?.logo != null && svc!.logo!.isNotEmpty) {
                    serviceLogos.add(svc.logo!);
                  }
                }

                // Get khoros logo from the filtered khoros (if only one selected)
                Uint8List? khorosLogo;
                if (_filterKhorosIds.length == 1) {
                  final khorosRow =
                      await (db.select(db.khoroses)..where(
                            (t) => t.khorosId.equals(_filterKhorosIds.first),
                          ))
                          .getSingleOrNull();
                  khorosLogo = khorosRow?.logo;
                }

                final repo = ref.read(attendanceRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات الحضور...',
                );

                try {
                  progress.update('جاري تحميل كل سجلات الحضور المطابقة...');
                  final allData = await repo.fetchAttendance(
                    month: _filterMonth,
                    year: _filterYear,
                    search: _searchQuery,
                    dateFrom: periodServiceResult.dateFrom,
                    dateTo: periodServiceResult.dateTo,
                    stageIds: _filterStageIds,
                    khorosIds: _filterKhorosIds,
                    areaIds: _filterAreaIds,
                    fatherIds: _filterFatherIds,
                    genders: _filterGenders,
                    birthdayDay: _filterBirthdayDay,
                    birthdayMonth: _filterBirthdayMonth,
                    birthdayYear: _filterBirthdayYear,
                    status: _filterStatus,
                    serviceIds: periodServiceResult.selectedServiceIds,
                    visitedStatus: _filterVisitedStatus,
                    notesFilter: _filterNotesStatus,
                    lateAfterTime: _lateAfterTimeString(),
                    customFilters: _customFilters,
                    deduplicatePeople: false,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }
                  final svcsData =
                      ref.read(servicesRepositoryProvider).asData?.value ?? [];
                  final Map<int, int> serviceMinsMap = {
                    for (var s in svcsData) s.id: s.hour * 60 + s.minute,
                  };

                  if (exportOptions.groupMode ==
                      PdfGroupExportMode.separatePdfPerGroup) {
                    final directory = await FilePicker.platform
                        .getDirectoryPath();
                    if (directory == null) {
                      progress.close();
                      return;
                    }
                    final groupedData = _groupAttendanceForPdf(
                      allData,
                      sorting,
                    );
                    final exportResult =
                        await GroupedPdfExportService.writeGroups<
                          AttendanceDTO
                        >(
                          groups: groupedData,
                          directoryPath: directory,
                          baseName: 'Attendance_Report',
                          buildPdf: (groupName, rows) =>
                              AttendanceReportService.generatePDF(
                                data: rows,
                                sortingCriteria: sorting,
                                columns: cols,
                                title: 'سجل حضور الأشخاص - $groupName',
                                headerData: headerData,
                                serviceLogos: serviceLogos,
                                churchLogo: churchLogo,
                                khorosLogo: khorosLogo,
                                churchName: churchName,
                                hasServiceSelected: periodServiceResult
                                    .selectedServiceIds
                                    .isNotEmpty,
                                serviceMinsMap: serviceMinsMap,
                                separatePages: false,
                                exportOptions: exportOptions.copyWith(
                                  groupMode:
                                      PdfGroupExportMode.singlePdfNewPages,
                                ),
                              ),
                        );
                    if (!mounted) return;
                    await progress.complete(
                      'تم إنشاء ${exportResult.writtenFiles.length} ملف PDF',
                      total: allData.length,
                    );
                    progress.close();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حفظ ${exportResult.writtenFiles.length} ملف PDF',
                        ),
                      ),
                    );
                    return;
                  }

                  final task = await AttendanceReportService.startPDFGeneration(
                    data: allData,
                    sortingCriteria: sorting,
                    columns: cols,
                    title: 'سجل حضور الأشخاص',
                    headerData: headerData,
                    serviceLogos: serviceLogos,
                    churchLogo: churchLogo,
                    khorosLogo: khorosLogo,
                    churchName: churchName,
                    hasServiceSelected:
                        periodServiceResult.selectedServiceIds.isNotEmpty,
                    serviceMinsMap: serviceMinsMap,
                    separatePages: separatePages,
                    exportOptions: exportOptions,
                  );
                  progress.setCancelAction(task.cancel);
                  final subscription = task.progress.listen(
                    (value) => progress.update(
                      value.message,
                      current: value.current,
                      total: value.total,
                    ),
                  );
                  final pdfBytes = await task.result.whenComplete(
                    subscription.cancel,
                  );

                  if (!mounted) return;
                  await progress.complete(
                    'تم إنشاء التقرير، جاري فتح نافذة الطباعة...',
                    total: allData.length,
                  );
                  progress.close();
                  await Printing.layoutPdf(
                    onLayout: (_) async => pdfBytes,
                    name: 'Attendance_Report.pdf',
                  );
                } on PdfGenerationCancelledException {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إلغاء الطباعة')),
                    );
                  }
                } catch (e) {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء تحضير الطباعة: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
      icon: const Icon(Icons.picture_as_pdf, size: 18),
      label: const Text('قائمة', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildGridPrintButton() {
    return ElevatedButton.icon(
      onPressed: _records.isEmpty
          ? null
          : () async {
              final servicesAsync = ref.read(servicesRepositoryProvider);
              final services = servicesAsync.asData?.value ?? [];

              final periodServiceResult =
                  await showDialog<PrintPeriodServicesResult>(
                    context: context,
                    builder: (c) => PrintPeriodServicesDialog(
                      anchorDate: _selectedDate,
                      services: services,
                    ),
                  );
              if (periodServiceResult == null) return;

              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(isAttendance: true),
              );
              if (result != null) {
                final List<String> sorting =
                    (result['sorting'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<String> headerIds =
                    (result['header'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final List<Map<String, String>> cols =
                    (result['columns'] as List)
                        .map(
                          (c) => {
                            'id': c.id.toString(),
                            'title': c.title.toString(),
                            'isPhone': c.isPhone.toString(),
                          },
                        )
                        .toList();
                final bool separatePages =
                    result['separatePages'] as bool? ?? false;
                final exportOptions =
                    result['exportOptions'] as PdfExportOptions? ??
                    const PdfExportOptions();

                final db = ref.read(appDatabaseProvider);
                final settingsRepo = ref.read(settingsRepositoryProvider);
                final churchNameReal = await settingsRepo.getSetting(
                  'church_name',
                );
                final churchLogo = await settingsRepo.getChurchLogo();

                final Map<String, String> headerData = {};
                final fields =
                    ref.read(fieldsRepositoryProvider).asData?.value ?? [];
                final labels = {
                  for (var f in fields)
                    if (f.fieldKey != null) f.fieldKey!: f.name,
                };
                String getL(String key, String fallback) =>
                    labels[key] ?? fallback;

                if (headerIds.contains('church_name')) {
                  headerData['الكنيسة'] = churchNameReal ?? '';
                }
                if (headerIds.contains('service_name')) {
                  headerData['الخدمة'] = periodServiceResult.serviceLabel;
                }
                headerData['الفترة'] = periodServiceResult.periodLabel;

                if (headerIds.contains('khoros')) {
                  if (_filterKhorosIds.isNotEmpty) {
                    final items = await (db.select(
                      db.khoroses,
                    )..where((t) => t.khorosId.isIn(_filterKhorosIds))).get();
                    headerData[getL('khoros', 'الخورس')] = items
                        .map((e) => e.khorosName)
                        .join('، ');
                  } else {
                    headerData[getL('khoros', 'الخورس')] = 'كل الخوارس';
                  }
                }
                if (headerIds.contains('stage')) {
                  if (_filterStageIds.isNotEmpty) {
                    final items = await (db.select(
                      db.stages,
                    )..where((t) => t.stageId.isIn(_filterStageIds))).get();
                    headerData[getL('stage', 'المرحلة')] = items
                        .map((e) => e.stageName)
                        .join('، ');
                  } else {
                    headerData[getL('stage', 'المرحلة')] = 'كل المراحل';
                  }
                }
                if (headerIds.contains('area')) {
                  if (_filterAreaIds.isNotEmpty) {
                    final items = await (db.select(
                      db.areas,
                    )..where((t) => t.areaId.isIn(_filterAreaIds))).get();
                    headerData[getL('area', 'المنطقة')] = items
                        .map((e) => e.areaName)
                        .join('، ');
                  } else {
                    headerData[getL('area', 'المنطقة')] = 'كل المناطق';
                  }
                }
                if (headerIds.contains('father')) {
                  if (_filterFatherIds.isNotEmpty) {
                    final items = await (db.select(
                      db.fathers,
                    )..where((t) => t.fatherId.isIn(_filterFatherIds))).get();
                    headerData[getL('father', 'أب الاعتراف')] = items
                        .map((e) => e.fatherName)
                        .join('، ');
                  } else {
                    headerData[getL('father', 'أب الاعتراف')] = 'كل الآباء';
                  }
                }

                // Get all selected services' logos
                final List<Uint8List> serviceLogos = [];
                for (var id in periodServiceResult.selectedServiceIds) {
                  final svc = services.where((s) => s.id == id).firstOrNull;
                  if (svc?.logo != null && svc!.logo!.isNotEmpty) {
                    serviceLogos.add(svc.logo!);
                  }
                }

                Uint8List? khorosLogo;
                if (_filterKhorosIds.length == 1) {
                  final khorosRow =
                      await (db.select(db.khoroses)..where(
                            (t) => t.khorosId.equals(_filterKhorosIds.first),
                          ))
                          .getSingleOrNull();
                  khorosLogo = khorosRow?.logo;
                }

                final repo = ref.read(attendanceRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات شبكة الحضور...',
                );

                try {
                  progress.update('جاري تحميل كل سجلات الحضور المطابقة...');
                  final allData = await repo.fetchAttendance(
                    month: _filterMonth,
                    year: _filterYear,
                    search: _searchQuery,
                    dateFrom: periodServiceResult.dateFrom,
                    dateTo: periodServiceResult.dateTo,
                    stageIds: _filterStageIds,
                    khorosIds: _filterKhorosIds,
                    areaIds: _filterAreaIds,
                    fatherIds: _filterFatherIds,
                    genders: _filterGenders,
                    birthdayDay: _filterBirthdayDay,
                    birthdayMonth: _filterBirthdayMonth,
                    birthdayYear: _filterBirthdayYear,
                    status: _filterStatus,
                    serviceIds: periodServiceResult.selectedServiceIds,
                    visitedStatus: _filterVisitedStatus,
                    notesFilter: _filterNotesStatus,
                    lateAfterTime: _lateAfterTimeString(),
                    customFilters: _customFilters,
                    deduplicatePeople: false,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }

                  final svcsData =
                      ref.read(servicesRepositoryProvider).asData?.value ?? [];
                  final Map<int, int> serviceMinsMap = {
                    for (var s in svcsData) s.id: s.hour * 60 + s.minute,
                  };

                  if (exportOptions.groupMode ==
                      PdfGroupExportMode.separatePdfPerGroup) {
                    final directory = await FilePicker.platform
                        .getDirectoryPath();
                    if (directory == null) {
                      progress.close();
                      return;
                    }
                    final groupedData = _groupAttendanceForPdf(
                      allData,
                      sorting,
                    );
                    final exportResult =
                        await GroupedPdfExportService.writeGroups<
                          AttendanceDTO
                        >(
                          groups: groupedData,
                          directoryPath: directory,
                          baseName: 'Attendance_Grid',
                          buildPdf: (groupName, rows) =>
                              AttendanceGridPdfGenerator.generateGridPDF(
                                data: rows,
                                title: 'سجل الغياب والحضور - $groupName',
                                headerData: headerData,
                                sortingCriteria: sorting,
                                columns: cols,
                                serviceLogos: serviceLogos,
                                churchLogo: churchLogo,
                                khorosLogo: khorosLogo,
                                churchName: churchNameReal,
                                hasServiceSelected: periodServiceResult
                                    .selectedServiceIds
                                    .isNotEmpty,
                                serviceMinsMap: serviceMinsMap,
                                dynamicLabels: labels,
                                separatePages: false,
                                exportOptions: exportOptions.copyWith(
                                  groupMode:
                                      PdfGroupExportMode.singlePdfNewPages,
                                ),
                              ),
                        );
                    if (!mounted) return;
                    await progress.complete(
                      'تم إنشاء ${exportResult.writtenFiles.length} ملف PDF',
                      total: allData.length,
                    );
                    progress.close();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حفظ ${exportResult.writtenFiles.length} ملف PDF',
                        ),
                      ),
                    );
                    return;
                  }

                  final task =
                      await AttendanceGridPdfGenerator.startGridPDFGeneration(
                        data: allData,
                        title: 'سجل الغياب والحضور',
                        headerData: headerData,
                        sortingCriteria: sorting,
                        columns: cols,
                        serviceLogos: serviceLogos,
                        churchLogo: churchLogo,
                        khorosLogo: khorosLogo,
                        churchName: churchNameReal,
                        hasServiceSelected:
                            periodServiceResult.selectedServiceIds.isNotEmpty,
                        serviceMinsMap: serviceMinsMap,
                        dynamicLabels: labels,
                        separatePages: separatePages,
                        exportOptions: exportOptions,
                      );
                  progress.setCancelAction(task.cancel);
                  final subscription = task.progress.listen(
                    (value) => progress.update(
                      value.message,
                      current: value.current,
                      total: value.total,
                    ),
                  );
                  final pdfBytes = await task.result.whenComplete(
                    subscription.cancel,
                  );

                  if (!mounted) return;
                  await progress.complete(
                    'تم إنشاء الشبكة، جاري فتح نافذة الطباعة...',
                    total: allData.length,
                  );
                  progress.close();
                  await Printing.layoutPdf(
                    onLayout: (_) async => pdfBytes,
                    name: 'Attendance_Grid.pdf',
                  );
                } on PdfGenerationCancelledException {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إلغاء الطباعة')),
                    );
                  }
                } catch (e) {
                  progress.close();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء تحضير الطباعة: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
      icon: const Icon(Icons.grid_on, size: 18),
      label: const Text('شبكة', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildAttendanceList({
    bool shrinkWrap = false,
    bool canEdit = false,
    bool canDelete = false,
    bool canAdd = false,
  }) {
    return ListView.builder(
      controller: shrinkWrap ? null : _scrollController,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: _records.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _records.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      label: const Text('عرض المزيد'),
                    ),
            ),
          );
        }
        return _buildAttendanceCard(
          _records[index],
          canEdit: canEdit,
          canDelete: canDelete,
          canAdd: canAdd,
        );
      },
    );
  }

  Widget _buildAttendanceCard(
    AttendanceDTO r, {
    bool canEdit = true,
    bool canDelete = true,
    bool canAdd = true,
  }) {
    final fields = ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
    String getLabel(String key, String fallback) {
      final f = fields.where((f) => f.fieldKey == key).firstOrNull;
      return f?.name ?? fallback;
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    final bool isPresent = r.id != null && r.attendTime != null;
    final bool isSelected = _selectedPersonIds.contains(r.personId);
    final visitIcon = r.visited == 2
        ? Icons.check_box
        : (r.visited == 1
              ? Icons.indeterminate_check_box
              : Icons.check_box_outline_blank);
    final visitColor = r.visited == 2
        ? Colors.green
        : (r.visited == 1 ? Colors.orange : Colors.grey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPresent ? 4 : 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPresent
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
      ),
      color: isPresent ? Colors.white : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  visualDensity: VisualDensity.compact,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedPersonIds.add(r.personId);
                      } else {
                        _selectedPersonIds.remove(r.personId);
                      }
                    });
                  },
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isPresent ? Colors.green : Colors.red).withOpacity(
                      0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            r.personName ?? 'مجهول',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 14 : 16,
                              color: isPresent
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          if (isPresent &&
                              r.attendTime != null &&
                              r.serviceId != null)
                            Builder(
                              builder: (context) {
                                final svcs =
                                    ref
                                        .read(servicesRepositoryProvider)
                                        .asData
                                        ?.value ??
                                    [];
                                final svc = svcs
                                    .where((s) => s.id == r.serviceId)
                                    .firstOrNull;
                                if (svc != null &&
                                    r.attendTime != null &&
                                    r.attendTime!.isNotEmpty) {
                                  try {
                                    // parse attend time (e.g. 05:30 م)
                                    final parts = r.attendTime!.split(' ');
                                    if (parts.length >= 2) {
                                      final timeParts = parts[0].split(':');
                                      int h = int.parse(timeParts[0]);
                                      final int m = int.parse(timeParts[1]);
                                      final isPm = parts[1] == 'م';
                                      if (isPm && h < 12) h += 12;
                                      if (!isPm && h == 12) h = 0;

                                      final attendMins = h * 60 + m;
                                      final serviceMins =
                                          svc.hour * 60 + svc.minute;

                                      final diff = attendMins - serviceMins;
                                      if (diff != 0) {
                                        final isLate = diff > 0;
                                        final absDiff = diff.abs();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isLate
                                                        ? Colors.orange
                                                        : Colors.blue)
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            isLate
                                                ? 'تأخير: $absDiff د'
                                                : 'تبكير: $absDiff د',
                                            style: TextStyle(
                                              color: isLate
                                                  ? Colors.orange.shade800
                                                  : Colors.blue.shade800,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (_) {}
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'كود: ${r.personId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (r.stageName != null && r.stageName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                '${getLabel('stage', 'المرحلة')}: ${r.stageName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (r.khorosName != null && r.khorosName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Text(
                                '${getLabel('khoros', 'الخورس')}: ${r.khorosName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (r.areaName != null && r.areaName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Text(
                                '${getLabel('area', 'المنطقة')}: ${r.areaName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (r.mobile != null && r.mobile!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                '${getLabel('mobile', 'تليفون')}: ${r.mobile}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (r.phone != null && r.phone!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.brown.shade200,
                                ),
                              ),
                              child: Text(
                                '${getLabel('phone', 'أرضي')}: ${r.phone}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.brown.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isPresent)
                        Text(
                          '${r.dateWeek ?? ""} ${r.attendTime != null ? "• حضور: ${r.attendTime}" : ""} ${r.checkoutTime != null ? " • انصراف: ${r.checkoutTime}" : ""} ${r.serviceName != null ? " • ${r.serviceName}" : ""}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'غائب',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPresent) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${r.point ?? 0} نقطة',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isPresent && canAdd) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _checkoutPerson(r),
                      icon: Icon(
                        (r.checkoutTime == null || r.checkoutTime!.isEmpty)
                            ? Icons.logout_rounded
                            : Icons.refresh_rounded,
                        size: 14,
                      ),
                      label: Text(
                        (r.checkoutTime == null || r.checkoutTime!.isEmpty)
                            ? 'تسجيل انصراف'
                            : 'تحديث انصراف',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            (r.checkoutTime == null || r.checkoutTime!.isEmpty)
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        foregroundColor:
                            (r.checkoutTime == null || r.checkoutTime!.isEmpty)
                            ? Colors.red.shade700
                            : Colors.orange.shade800,
                        side: BorderSide(
                          color:
                              (r.checkoutTime == null ||
                                  r.checkoutTime!.isEmpty)
                              ? Colors.red.shade200
                              : Colors.orange.shade300,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 22,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showEditDialog(r),
                      tooltip: 'تعديل',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                      onPressed: () => _deleteAttendance(r),
                      tooltip: 'حذف',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                ],
              ),
            ] else if (canAdd) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedPersonId = r.personId;
                      _selectedPersonName = r.personName;
                      _autocompleteController?.text = r.personName ?? "";
                    });
                    _saveAttendance();
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text(
                    'تسجيل حضور',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            // Visitation row
            if (r.id != null) ...[
              const Divider(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: !canEdit
                        ? null
                        : () async {
                            // Binary toggle between 0 (not visited) and 2 (visited)
                            final newVal = (r.visited == 2) ? 0 : 2;
                            await ref
                                .read(attendanceRepositoryProvider.notifier)
                                .updateVisitation(
                                  id: r.id!,
                                  visited: newVal,
                                  visitNotes: r.visitNotes,
                                );
                            await _reloadPreservingScroll();
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(visitIcon, color: visitColor, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          r.visited == 2 ? 'تم الافتقاد' : 'لم يتم',
                          style: TextStyle(
                            fontSize: 13,
                            color: visitColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VisitationNotesTextField(
                      attendanceId: r.id!,
                      visited: r.visited,
                      initialNotes: r.visitNotes ?? '',
                      canEdit: canEdit,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VisitationNotesTextField extends ConsumerStatefulWidget {
  final int attendanceId;
  final int? visited;
  final String initialNotes;
  final bool canEdit;

  const VisitationNotesTextField({
    super.key,
    required this.attendanceId,
    required this.visited,
    required this.initialNotes,
    required this.canEdit,
  });

  @override
  ConsumerState<VisitationNotesTextField> createState() =>
      _VisitationNotesTextFieldState();
}

class _VisitationNotesTextFieldState
    extends ConsumerState<VisitationNotesTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _lastSavedNotes = '';

  @override
  void initState() {
    super.initState();
    _lastSavedNotes = widget.initialNotes;
    _controller = TextEditingController(text: widget.initialNotes);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant VisitationNotesTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attendanceId != oldWidget.attendanceId) {
      _lastSavedNotes = widget.initialNotes;
      _controller.text = widget.initialNotes;
    } else if (widget.initialNotes != oldWidget.initialNotes &&
        !_focusNode.hasFocus) {
      _lastSavedNotes = widget.initialNotes;
      _controller.text = widget.initialNotes;
    }
  }

  @override
  void dispose() {
    _saveIfNeeded();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _saveIfNeeded();
    }
  }

  Future<void> _saveIfNeeded() async {
    final currentText = _controller.text;
    if (currentText == _lastSavedNotes) return;

    _lastSavedNotes = currentText;

    try {
      await ref
          .read(attendanceRepositoryProvider.notifier)
          .updateVisitation(
            id: widget.attendanceId,
            visited: widget.visited,
            visitNotes: currentText,
          );
    } catch (e) {
      debugPrint('Error saving visitation notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: 2,
      minLines: 1,
      enabled: widget.canEdit,
      decoration: InputDecoration(
        hintText: 'ملاحظات الافتقاد...',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: Colors.grey[50],
        filled: true,
      ),
      style: const TextStyle(fontSize: 12),
      onSubmitted: (val) {
        _saveIfNeeded();
      },
      onTapOutside: (event) {
        _focusNode.unfocus();
      },
    );
  }
}
