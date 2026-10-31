import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show Platform, File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/fathers_repository.dart';
import '../ui/widgets/multi_select_filter.dart';
import '../utils/arabic_helper.dart';
import '../widgets/print_progress_dialog.dart';
import '../services/pdf_generation_task.dart';
import '../ui/dialogs/attendance_notes_dialog.dart';
import '../repositories/bus_repository.dart';
import '../ui/ribbon/ribbon_bus.dart';
import 'qr_scanner_screen.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';
import '../utils/silent_refresh_controller.dart';
import '../sync/person_change_source.dart';
import '../utils/delta_page_cache.dart';
import '../theme/app_theme.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  static const int _defaultAttendancePoints = 2;
  String? _changeCursor;
  Future<void>? _refreshFlight;
  bool _refreshAgain = false;

  // --- Person Data Filters ---
  String _searchQuery = '';
  Timer? _searchDebounce;
  bool _isResolvingCode = false;
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
  List<int> _selectedServiceIds = [];
  String _filterStatus = 'present';
  String _sortBy = 'code';
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

  late final SilentRefreshController _refreshController;

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

  bool _isSaving = false;
  bool _isCheckingOutAll = false;
  bool _isBulkActionRunning = false;
  bool _isCheckoutMode = false;
  String _selectedQuickCheckoutType =
      'alone'; // 'alone', 'bus', 'parent', 'other'
  final TextEditingController _quickOtherReasonController =
      TextEditingController();
  int _attendanceSavedPoints = 2;
  int _checkoutSavedPoints = 2;

  @override
  void initState() {
    super.initState();
    _refreshController = SilentRefreshController();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _refreshController.dispose();
    _scrollController.dispose();
    _codeFocusNode.dispose();
    _pointsController.dispose();
    _quickOtherReasonController.dispose();
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
  bool _isLoadingMore = false;
  Completer<void>? _pageLoad;

  Future<void> _loadInitialData() async {
    final callId = DateTime.now().millisecondsSinceEpoch;
    _lastCallId = callId;
    final pageLoad = Completer<void>();
    _pageLoad = pageLoad;
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;

    setState(() {
      _isLoading = _records.isEmpty;
    });

    final repo = ref.read(attendanceRepositoryProvider.notifier);
    DateTime? dFrom = _filterDateFrom;
    DateTime? dTo = _filterDateTo;
    if (_filterSpecificDateOnly) {
      dFrom = _selectedDate;
      dTo = _selectedDate;
    }

    try {
      if (!mounted ||
          generation != _refreshController.currentGeneration ||
          _lastCallId != callId)
        return;

      final checkpoint = await ref
          .read(personChangeSourceProvider)
          .read(cursor: null, knownIds: const [], domain: 'attendance');
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
          serviceIds: _selectedServiceIds,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          sortBy: _sortBy,
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
          serviceIds: _selectedServiceIds,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          callId: '$callId-SUM',
        ),
      ]);

      if (!mounted ||
          generation != _refreshController.currentGeneration ||
          _lastCallId != callId)
        return;

      final data = await _completeBoundary(
        results[0] as List<AttendanceDTO>,
        rawHasMore,
      );
      if (!mounted ||
          generation != _refreshController.currentGeneration ||
          _lastCallId != callId)
        return;
      final summary = results[1] as Map<String, int>;

      setState(() {
        _totalCount = summary['total'] ?? 0;
        _presentCount = summary['present'] ?? 0;
        _absentCount = summary['absent'] ?? 0;
        _records.clear();
        _records.addAll(data);
        _changeCursor = checkpoint.cursor;
        final visiblePersonIds = data.map((r) => r.personId).toSet();
        _selectedPersonIds.removeWhere((id) => !visiblePersonIds.contains(id));
        _hasMore = rawHasMore;
        _isLoading = false;
        _offset = _rawCount(data);
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
    } finally {
      if (!pageLoad.isCompleted) pageLoad.complete();
      if (identical(_pageLoad, pageLoad)) _pageLoad = null;
    }
  }

  Future<List<AttendanceDTO>> _fetchPage({
    int? limit,
    int offset = 0,
    List<int>? changedPersonIds,
    String? callId,
    void Function(bool)? onHasMore,
  }) {
    final dFrom = _filterSpecificDateOnly ? _selectedDate : _filterDateFrom;
    final dTo = _filterSpecificDateOnly ? _selectedDate : _filterDateTo;
    return ref
        .read(attendanceRepositoryProvider.notifier)
        .fetchAttendance(
          month: _filterMonth,
          year: _filterYear,
          search: _searchQuery,
          limit: limit,
          offset: offset,
          changedPersonIds: changedPersonIds,
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
          serviceIds: _selectedServiceIds,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          sortBy: _sortBy,
          callId: callId,
          onHasMore: onHasMore,
        );
  }

  int _rawCount(Iterable<AttendanceDTO> rows) => rows.fold(
    0,
    (count, row) =>
        count + (row.serviceRecords.isEmpty ? 1 : row.serviceRecords.length),
  );

  Future<List<AttendanceDTO>> _completeBoundary(
    List<AttendanceDTO> rows,
    bool hasMore,
  ) async {
    if (!hasMore || rows.isEmpty) return rows;
    final last = await _fetchPage(changedPersonIds: [rows.last.personId]);
    return [...rows.take(rows.length - 1), ...last];
  }

  Future<void> _silentRefresh() {
    if (_refreshFlight != null) {
      _refreshAgain = true;
      return _refreshFlight!;
    }
    return _refreshFlight = (() async {
      do {
        _refreshAgain = false;
        await _refreshCachedPage();
      } while (_refreshAgain && mounted);
    })().whenComplete(() => _refreshFlight = null);
  }

  Future<void> _refreshCachedPage() async {
    if (!mounted) return;
    while (_pageLoad != null) {
      await _pageLoad!.future;
    }
    if (!mounted) return;
    final generation = _refreshController.currentGeneration;

    final targetLimit = _offset > _limit ? _offset : _limit;
    final repo = ref.read(attendanceRepositoryProvider.notifier);
    DateTime? dFrom = _filterDateFrom;
    DateTime? dTo = _filterDateTo;
    if (_filterSpecificDateOnly) {
      dFrom = _selectedDate;
      dTo = _selectedDate;
    }

    try {
      final checkpoint = await ref
          .read(personChangeSourceProvider)
          .read(
            cursor: _changeCursor,
            knownIds: _records.map((p) => p.personId),
            domain: 'attendance',
          );
      final changedIds = checkpoint.personIds;
      if (!mounted || generation != _refreshController.currentGeneration)
        return;
      if (changedIds != null && changedIds.isEmpty) {
        _changeCursor = checkpoint.cursor;
        return;
      }
      bool rawHasMore = false;
      final results = await Future.wait([
        _fetchPage(
          limit: changedIds == null ? targetLimit : null,
          changedPersonIds: changedIds?.toList(),
          callId: 'SILENT-DATA',
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
          serviceIds: _selectedServiceIds,
          visitedStatus: _filterVisitedStatus,
          notesFilter: _filterNotesStatus,
          lateAfterTime: _lateAfterTimeString(),
          status: _filterStatus,
          customFilters: _customFilters,
          callId: 'SILENT-SUM',
        ),
      ]);

      if (!mounted || generation != _refreshController.currentGeneration)
        return;

      var data = results[0] as List<AttendanceDTO>;
      if (changedIds == null) {
        data = await _completeBoundary(data, rawHasMore);
      } else {
        int compare(AttendanceDTO a, AttendanceDTO b) {
          final name = _sortBy == 'name'
              ? a.personName.compareTo(b.personName)
              : 0;
          return name != 0 ? name : a.personId.compareTo(b.personId);
        }

        data = mergeChangedPrefix<AttendanceDTO>(
          cached: _records,
          changed: data,
          changedIds: changedIds,
          idOf: (p) => p.personId,
          compare: compare,
          hasMore: _hasMore,
        );
        rawHasMore = _hasMore;
        final rawCount = _rawCount(data);
        if (rawHasMore && rawCount < targetLimit) {
          var tail = await _fetchPage(
            limit: targetLimit - rawCount,
            offset: rawCount,
            onHasMore: (val) => rawHasMore = val,
          );
          tail = await _completeBoundary(tail, rawHasMore);
          final ids = data.map((p) => p.personId).toSet();
          data.addAll(tail.where((p) => ids.add(p.personId)));
        }
      }
      if (!mounted || generation != _refreshController.currentGeneration)
        return;
      final summary = results[1] as Map<String, int>;

      setState(() {
        _isLoading = false;
        _totalCount = summary['total'] ?? 0;
        _presentCount = summary['present'] ?? 0;
        _absentCount = summary['absent'] ?? 0;
        _records.clear();
        _records.addAll(data);
        _changeCursor = checkpoint.cursor;
        final visiblePersonIds = data.map((r) => r.personId).toSet();
        _selectedPersonIds.retainWhere((id) => visiblePersonIds.contains(id));
        _hasMore = rawHasMore;
        _offset = _rawCount(data);
      });
    } catch (e, st) {
      debugPrint('[AttendanceScreen] Silent refresh error: $e\n$st');
      rethrow;
    }
  }

  Future<void> _loadMore() async {
    if (_pageLoad != null || _isLoading || _isLoadingMore || !_hasMore) return;
    final pageLoad = Completer<void>();
    _pageLoad = pageLoad;
    _isLoadingMore = true;
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;
    try {
      final repo = ref.read(attendanceRepositoryProvider.notifier);
      DateTime? dFrom = _filterDateFrom;
      DateTime? dTo = _filterDateTo;
      if (_filterSpecificDateOnly) {
        dFrom = _selectedDate;
        dTo = _selectedDate;
      }
      bool rawHasMore = false;
      var data = await repo.fetchAttendance(
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
        serviceIds: _selectedServiceIds,
        visitedStatus: _filterVisitedStatus,
        notesFilter: _filterNotesStatus,
        lateAfterTime: _lateAfterTimeString(),
        customFilters: _customFilters,
        sortBy: _sortBy,
        onHasMore: (val) => rawHasMore = val,
      );
      data = await _completeBoundary(data, rawHasMore);
      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() {
          final ids = _records.map((r) => r.personId).toSet();
          _records.addAll(data.where((r) => ids.add(r.personId)));
          _offset = _rawCount(_records);
          _hasMore = rawHasMore;
        });
      }
    } catch (e) {
      if (mounted && generation == _refreshController.currentGeneration) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء تحميل المزيد: $e')));
      }
    } finally {
      _isLoadingMore = false;
      if (!pageLoad.isCompleted) pageLoad.complete();
      if (identical(_pageLoad, pageLoad)) _pageLoad = null;
      if (mounted &&
          generation == _refreshController.currentGeneration &&
          _refreshController.isStale) {
        _refreshController.requestRefresh(onRefresh: _silentRefresh);
      }
    }
  }

  Future<void> _reloadPreservingScroll() => _silentRefresh();

  List<AttendanceDTO> get _selectedRecords =>
      _records.where((r) => _selectedPersonIds.contains(r.personId)).toList();

  List<AttendanceServiceRecord> _serviceRecordsFor(AttendanceDTO record) {
    if (record.serviceRecords.isNotEmpty) return record.serviceRecords;
    final id = record.id;
    if (id == null) return const [];
    return [
      AttendanceServiceRecord(
        id: id,
        serviceId: record.serviceId,
        serviceName: record.serviceName,
        dateWeek: record.dateWeek,
        attendTime: record.attendTime,
        checkoutTime: record.checkoutTime,
        point: record.point ?? 0,
        attendancePoint: null,
        checkoutPoint: null,
      ),
    ];
  }

  List<int> get _selectedAttendanceIds => _selectedRecords
      .expand(_serviceRecordsFor)
      .where(
        (record) =>
            _selectedServiceIds.isEmpty ||
            _selectedServiceIds.contains(record.serviceId),
      )
      .map((record) => record.id)
      .toSet()
      .toList();

  int get _currentPoints =>
      int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;

  Future<void> _toggleSelectAllVisible() async {
    final visibleIds = _records.map((r) => r.personId).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedPersonIds.contains);
    if (allSelected) {
      setState(() {
        _selectedPersonIds.removeAll(visibleIds);
      });
      return;
    }

    if (_hasMore) {
      setState(() => _isBulkActionRunning = true);
      DateTime? dateFrom = _filterDateFrom;
      DateTime? dateTo = _filterDateTo;
      if (_filterSpecificDateOnly) {
        dateFrom = _selectedDate;
        dateTo = _selectedDate;
      }
      final allRecords = await ref
          .read(attendanceRepositoryProvider.notifier)
          .fetchAttendance(
            month: _filterMonth,
            year: _filterYear,
            search: _searchQuery,
            dateFrom: dateFrom,
            dateTo: dateTo,
            stageIds: _filterStageIds,
            khorosIds: _filterKhorosIds,
            areaIds: _filterAreaIds,
            fatherIds: _filterFatherIds,
            genders: _filterGenders,
            birthdayDay: _filterBirthdayDay,
            birthdayMonth: _filterBirthdayMonth,
            birthdayYear: _filterBirthdayYear,
            serviceIds: _selectedServiceIds,
            visitedStatus: _filterVisitedStatus,
            notesFilter: _filterNotesStatus,
            lateAfterTime: _lateAfterTimeString(),
            status: _filterStatus,
            customFilters: _customFilters,
            sortBy: _sortBy,
          );
      if (!mounted) return;
      setState(() {
        _records
          ..clear()
          ..addAll(allRecords);
        _selectedPersonIds.addAll(allRecords.map((r) => r.personId));
        _hasMore = false;
        _offset = allRecords.length;
        _isBulkActionRunning = false;
      });
      return;
    }

    setState(() => _selectedPersonIds.addAll(visibleIds));
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
      final services = ref.read(servicesRepositoryProvider).value ?? [];
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
              serviceId: r.serviceId ?? _selectedServiceIds.firstOrNull,
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
    _refreshController.bumpGeneration();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      _loadInitialData,
    );
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
    final services = ref.read(servicesRepositoryProvider).value ?? [];
    if (services.isNotEmpty && _selectedServiceIds.isEmpty) {
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

    // Validate weekday and eligibility for all selected services
    for (final sId in _selectedServiceIds) {
      final svc = services.where((s) => s.id == sId).firstOrNull;
      if (svc != null) {
        if (_selectedDate.weekday != svc.dayOfWeek) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خدمة "${svc.name}" ليست اليوم (${svc.dayName})'),
              backgroundColor: Colors.red,
            ),
          );
          _autocompleteController?.clear();
          _selectedPersonId = null;
          _selectedPersonName = null;
          _internalFocusNode?.requestFocus();
          _codeFocusNode.requestFocus();
          return;
        }

        // addAttendance validates eligibility inside its error handling. Doing
        // the same network reads here delayed saving and let HTTP errors escape.
      }
    }

    String? otherReason;
    if (_isCheckoutMode && _selectedQuickCheckoutType == 'other') {
      otherReason = _quickOtherReasonController.text.trim();
      if (otherReason.isEmpty) {
        otherReason = await _promptForOtherReason(
          context,
          _selectedPersonName ?? '',
        );
        if (otherReason == null || otherReason.trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ يجب كتابة سبب الانصراف عند اختيار "آخر"!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          _refocusCodeField();
          return;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final pId = _selectedPersonId!;
      final pName = _selectedPersonName ?? '';
      _autocompleteController?.clear();
      _selectedPersonId = null;
      _selectedPersonName = null;
      _internalFocusNode?.requestFocus();
      _codeFocusNode.requestFocus();

      final points =
          int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = _currentTime12h();

      String? lastError;
      final attendanceServices = _selectedServiceIds.isEmpty
          ? <int?>[null]
          : _selectedServiceIds.cast<int?>();
      for (final sId in attendanceServices) {
        final serviceName = _serviceNameById(services, sId);
        final errorMsg = await ref
            .read(attendanceRepositoryProvider.notifier)
            .addAttendance(
              personId: pId,
              dateWeek: dateStr,
              point: points,
              month: _selectedDate.month,
              year: _selectedDate.year,
              serviceId: sId,
              attendTime: timeStr,
              isCheckout: _isCheckoutMode,
              checkoutType: _isCheckoutMode ? _selectedQuickCheckoutType : null,
              checkoutNotes:
                  _isCheckoutMode && _selectedQuickCheckoutType == 'other'
                  ? otherReason
                  : null,
              personName: pName,
              serviceName: serviceName,
            );
        if (errorMsg != null) {
          lastError = errorMsg;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (lastError == null) {
          await _reloadPreservingScroll();
          ref.read(busRefreshTriggerProvider.notifier).trigger();
          final noteSuffix =
              (_isCheckoutMode &&
                  _selectedQuickCheckoutType == 'other' &&
                  otherReason != null &&
                  otherReason.isNotEmpty)
              ? ' (السبب: $otherReason)'
              : '';
          final label = _isCheckoutMode
              ? (_selectedQuickCheckoutType == 'alone'
                    ? 'انصراف بمفرده'
                    : (_selectedQuickCheckoutType == 'parent'
                          ? 'انصراف لولي الأمر (مستبعد من الأتوبيس)'
                          : _selectedQuickCheckoutType == 'other'
                          ? 'انصراف لسبب آخر (مستبعد من الأتوبيس)$noteSuffix'
                          : 'انصراف بالأتوبيس'))
              : 'حضور';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تسجيل $label $pName بنجاح'),
              backgroundColor: _isCheckoutMode
                  ? (_selectedQuickCheckoutType == 'alone'
                        ? Colors.teal.shade700
                        : (_selectedQuickCheckoutType == 'parent'
                              ? Colors.orange.shade800
                              : _selectedQuickCheckoutType == 'other'
                              ? Colors.purple.shade700
                              : Colors.indigo.shade700))
                  : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          _refocusCodeField();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $lastError'),
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

  Future<void> _openAttendanceNotesDialog(AttendanceDTO r) async {
    final res = await AttendanceNotesDialog.show(
      context,
      personName: r.personName,
      personId: r.personId,
      initialAttendanceNotes: r.attendanceNotes,
      initialCheckoutNotes: r.checkoutNotes,
      initialCheckoutType: r.checkoutType,
      isPresent: r.id != null,
      isCheckoutDone: r.checkoutTime != null && r.checkoutTime!.isNotEmpty,
    );

    if (res == null) return;

    if (r.id != null) {
      await ref
          .read(attendanceRepositoryProvider.notifier)
          .updateAttendanceNotes(
            id: r.id!,
            attendanceNotes: res.attendanceNotes,
            checkoutNotes: res.checkoutNotes,
            checkoutType: res.checkoutType,
          );
      await _reloadPreservingScroll();
      ref.read(busRefreshTriggerProvider.notifier).trigger();
      if (mounted) {
        final isExcluded =
            res.checkoutType == 'parent' || res.checkoutType == 'other';
        final parentMsg = isExcluded ? ' (تم استبعاده من الأتوبيس اليوم)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حفظ ملاحظات ${r.personName}$parentMsg بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Record attendance with notes directly
      final points =
          int.tryParse(_pointsController.text) ?? _defaultAttendancePoints;
      final services = ref.read(servicesRepositoryProvider).value ?? [];
      final sId = _selectedServiceIds.firstOrNull;
      final serviceName = _serviceNameById(services, sId);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = _currentTime12h();

      await ref
          .read(attendanceRepositoryProvider.notifier)
          .addAttendance(
            personId: r.personId,
            dateWeek: dateStr,
            point: points,
            month: _selectedDate.month,
            year: _selectedDate.year,
            serviceId: sId,
            attendTime: timeStr,
            personName: r.personName,
            serviceName: serviceName,
            attendanceNotes: res.attendanceNotes,
            checkoutNotes: res.checkoutNotes,
            checkoutType: res.checkoutType,
          );
      await _reloadPreservingScroll();
      ref.read(busRefreshTriggerProvider.notifier).trigger();
    }
  }

  Future<String?> _promptForOtherReason(
    BuildContext context,
    String studentName, {
    String? initialReason,
  }) async {
    final controller = TextEditingController(text: initialReason ?? '');
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.alt_route_rounded,
                        color: Colors.purple.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سبب الانصراف (آخر)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            studentName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'يرجى كتابة سبب الانصراف (مطلوب):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'مثال: تعب مفاجئ، ظروف أسرية، مشوار خاص...',
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.purple.shade50.withOpacity(0.3),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isEmpty) {
                          setDialogState(
                            () => errorText = 'يجب كتابة سبب الانصراف',
                          );
                        } else {
                          Navigator.of(dialogCtx).pop(val.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 سيتم استبعاد الطالب تلقائياً من كشف وجدول الأتوبيس لهذا اليوم',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(null),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final val = controller.text.trim();
                      if (val.isEmpty) {
                        setDialogState(
                          () => errorText = 'يجب كتابة سبب الانصراف',
                        );
                      } else {
                        Navigator.of(dialogCtx).pop(val);
                      }
                    },
                    child: const Text('تأكيد الانصراف'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _checkoutPerson(
    AttendanceDTO r, {
    String? checkoutType,
    String? checkoutNotes,
  }) async {
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
      final services = ref.read(servicesRepositoryProvider).value ?? [];
      final serviceId = r.serviceId ?? _selectedServiceIds.firstOrNull;
      final serviceName =
          r.serviceName ?? _serviceNameById(services, serviceId);
      final effectiveType = checkoutType ?? r.checkoutType ?? 'alone';
      final effectiveNotes = checkoutNotes ?? r.checkoutNotes;

      String? errorMsg;
      final bool alreadyCheckedOut =
          r.checkoutTime != null && r.checkoutTime!.isNotEmpty;

      if (alreadyCheckedOut) {
        final ids = _serviceRecordsFor(
          r,
        ).map((rec) => rec.id).whereType<int>().toList();
        if (ids.isEmpty && r.id != null) ids.add(r.id!);
        for (final id in ids) {
          await ref
              .read(attendanceRepositoryProvider.notifier)
              .updateAttendanceNotes(
                id: id,
                checkoutType: effectiveType,
                checkoutNotes: effectiveNotes,
              );
        }
      } else {
        errorMsg = await ref
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
              checkoutType: effectiveType,
              checkoutNotes: effectiveNotes,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (errorMsg == null) {
          await _reloadPreservingScroll();
          ref.read(busRefreshTriggerProvider.notifier).trigger();
          final isAlone = effectiveType == 'alone';
          final isParent = effectiveType == 'parent';
          final isOther = effectiveType == 'other';
          final noteSuffix =
              (effectiveNotes != null && effectiveNotes.trim().isNotEmpty)
              ? ' (السبب: ${effectiveNotes.trim()})'
              : '';
          final label = isAlone
              ? '✅ تم تسجيل انصراف ${r.personName} بمفرده (مستبعد من الأتوبيس)'
              : (isParent
                    ? '✅ تم تسجيل انصراف ${r.personName} لولي الأمر (مستبعد من الأتوبيس)$noteSuffix'
                    : isOther
                    ? '✅ تم تسجيل انصراف ${r.personName} لسبب آخر (مستبعد من الأتوبيس)$noteSuffix'
                    : '✅ تم تسجيل انصراف ${r.personName} بنجاح');
          final snackColor = isAlone
              ? Colors.teal.shade700
              : (isParent
                    ? Colors.orange.shade800
                    : isOther
                    ? Colors.purple.shade700
                    : Colors.indigo.shade700);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(label),
              backgroundColor: snackColor,
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

  Future<void> _cancelCheckoutForPerson(AttendanceDTO r) async {
    if (_periodModeEnabled) {
      _showPeriodModeBlockedMessage();
      return;
    }
    final ids = _serviceRecordsFor(
      r,
    ).map((rec) => rec.id).whereType<int>().toList();
    if (ids.isEmpty && r.id != null) ids.add(r.id!);
    if (ids.isEmpty) return;

    await ref
        .read(attendanceRepositoryProvider.notifier)
        .clearCheckoutForIds(ids);
    await _reloadPreservingScroll();
    ref.read(busRefreshTriggerProvider.notifier).trigger();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء انصراف ${r.personName} بنجاح'),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveManualAttendance() async {
    if (_periodModeEnabled) {
      _showPeriodModeBlockedMessage();
      return;
    }
    if (_isCheckingOutAll) return;

    final services = ref.read(servicesRepositoryProvider).value ?? [];
    if (services.isNotEmpty && _selectedServiceIds.isEmpty) {
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
    final serviceNames = _selectedServiceIds.isEmpty
        ? 'بدون خدمة'
        : services
              .where((service) => _selectedServiceIds.contains(service.id))
              .map((service) => service.name)
              .join('، ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد انصراف الكل'),
          content: Text(
            'سيتم تسجيل الانصراف الآن لكل من حضر ولم ينصرف في '
            '$serviceNames بتاريخ $date، '
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
      int totalCount = 0;
      final checkoutServices = _selectedServiceIds.isEmpty
          ? <int?>[null]
          : _selectedServiceIds.cast<int?>();
      for (final sId in checkoutServices) {
        final count = await ref
            .read(attendanceRepositoryProvider.notifier)
            .checkoutAll(
              dateWeek: date,
              checkoutTime: _currentTime12h(),
              points: points,
              serviceId: sId,
            );
        totalCount += count;
      }
      if (!mounted) return;
      await _loadInitialData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            totalCount == 0
                ? 'لا يوجد أشخاص منتظر تسجيل انصرافهم'
                : 'تم تسجيل انصراف $totalCount شخص بنجاح 🎉',
          ),
          backgroundColor: totalCount == 0 ? Colors.orange : Colors.green,
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
        ref.read(busRefreshTriggerProvider.notifier).trigger();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'تم الحذف بنجاح' : 'فشل الحذف')),
        );
        _refocusCodeField();
      }
    }
  }

  void _showEditDialog(AttendanceDTO r) {
    final records = _serviceRecordsFor(r);
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد سجلات حضور للتعديل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set initial values from the first record
    AttendanceServiceRecord selectedRecord = records.first;
    final pointAttendanceCtrl = TextEditingController(
      text: '${selectedRecord.attendancePoint ?? selectedRecord.point}',
    );
    final pointCheckoutCtrl = TextEditingController(
      text: '${selectedRecord.checkoutPoint ?? 0}',
    );
    DateTime editDate = selectedRecord.dateWeek != null
        ? (DateTime.tryParse(selectedRecord.dateWeek!) ?? DateTime.now())
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
                  if (records.length > 1) ...[
                    DropdownButtonFormField<AttendanceServiceRecord>(
                      value: selectedRecord,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الخدمة المراد تعديلها',
                      ),
                      items: records
                          .map(
                            (rec) => DropdownMenuItem(
                              value: rec,
                              child: Text(rec.serviceName ?? 'خدمة غير معروفة'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() {
                            selectedRecord = val;
                            pointAttendanceCtrl.text =
                                '${val.attendancePoint ?? val.point}';
                            pointCheckoutCtrl.text =
                                '${val.checkoutPoint ?? 0}';
                            editDate = val.dateWeek != null
                                ? (DateTime.tryParse(val.dateWeek!) ??
                                      DateTime.now())
                                : DateTime.now();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: pointAttendanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نقاط الحضور'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointCheckoutCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نقاط الانصراف',
                    ),
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
                    final attPoints =
                        int.tryParse(pointAttendanceCtrl.text) ?? 0;
                    final chkPoints = int.tryParse(pointCheckoutCtrl.text) ?? 0;
                    final totalPoints = attPoints + chkPoints;
                    final success = await ref
                        .read(attendanceRepositoryProvider.notifier)
                        .updateAttendance(
                          id: selectedRecord.id,
                          point: totalPoints,
                          attendancePoint: attPoints,
                          checkoutPoint: chkPoints,
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
    ref.listen<int>(sourceEpochProvider, (previous, next) {
      _refreshController.updateEpoch(next);
      if (mounted) {
        setState(() {
          _changeCursor = null;
          _selectedPersonIds.clear();
        });
        _refreshController.requestRefresh(
          onRefresh: _silentRefresh,
          immediate: true,
        );
      }
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.attendance), (
      prev,
      next,
    ) {
      if (next > 1) {
        _refreshController.markStale(next, onRefresh: _silentRefresh);
      }
    });

    ref.listen<RibbonCommandEvent?>(ribbonCommandBusProvider, (previous, next) {
      if (next == null) return;
      switch (next.command) {
        case RibbonCommand.focusQuickAttendance:
          setState(() {
            _isCheckoutMode = false;
          });
          if (next.payload != null && next.payload is PersonListDTO) {
            final p = next.payload as PersonListDTO;
            _selectedPersonId = p.id;
            _selectedPersonName = p.name;
            _autocompleteController?.text = p.name;
          }
          _refocusCodeField();
          break;
        case RibbonCommand.setCheckoutAlone:
          setState(() {
            _isCheckoutMode = true;
            _selectedQuickCheckoutType = 'alone';
          });
          _refocusCodeField();
          break;
        case RibbonCommand.setCheckoutBus:
          setState(() {
            _isCheckoutMode = true;
            _selectedQuickCheckoutType = 'bus';
          });
          _refocusCodeField();
          break;
        case RibbonCommand.setCheckoutParent:
          setState(() {
            _isCheckoutMode = true;
            _selectedQuickCheckoutType = 'parent';
          });
          _refocusCodeField();
          break;
        case RibbonCommand.checkoutAll:
          _saveManualAttendance();
          break;
        case RibbonCommand.filterAbsent2Weeks:
        case RibbonCommand.filterAbsentMonth:
          setState(() {
            _filterStatus = 'absent';
          });
          _loadInitialData();
          break;
        case RibbonCommand.filterReset:
          setState(() {
            _filterStatus = 'all';
          });
          _loadInitialData();
          break;
        case RibbonCommand.reloadAttendance:
          _loadInitialData();
          break;
        default:
          break;
      }
    });

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
                    _buildDesktopHeaderRow(),
                    const SizedBox(height: 8),
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

  Widget _buildDesktopHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.how_to_reg_rounded,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'سجل الحضور',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'متابعة حضور الأشخاص وتوزيع النقاط والافتقاد',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildSummaryCards(),
      ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF151E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final dividerColor = isDark
        ? const Color(0xFF334155)
        : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSingleCard('الإجمالي', _totalCount, Colors.blue),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 16,
            color: dividerColor,
          ),
          _buildSingleCard('الحضور', _presentCount, Colors.green),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 16,
            color: dividerColor,
          ),
          _buildSingleCard('الغياب', _absentCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSingleCard(String title, int count, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700;
    final adaptiveColor = AppTheme.getAdaptiveAccent(color, isDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : adaptiveColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineForm(bool isMobile) {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final services = servicesAsync.value ?? [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF151E2E) : const Color(0xFFF5F7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF334155)
              : theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: isDark ? const Color(0xFF93C5FD) : theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'تسجيل حضور سريع',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : theme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (!isMobile && _isCheckoutMode) ...[
                  _buildTopCheckoutCards(),
                  const SizedBox(width: 8),
                ],
                // Check-in / Check-out Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isCheckoutMode
                        ? (isDark
                              ? Colors.red.withValues(alpha: 0.22)
                              : Colors.red.shade50)
                        : (isDark
                              ? Colors.green.withValues(alpha: 0.22)
                              : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCheckoutMode
                          ? (isDark
                                ? Colors.red.withValues(alpha: 0.5)
                                : Colors.red.shade200)
                          : (isDark
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.green.shade200),
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
            const SizedBox(height: 8),
            if (isMobile) ...[
              if (_isCheckoutMode) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildTopCheckoutCards(),
                ),
                const SizedBox(height: 8),
              ],
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
                      : _saveManualAttendance,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _periodModeEnabled
            ? (isDark
                  ? Colors.orange.shade900.withValues(alpha: 0.3)
                  : Colors.orange.shade50)
            : (isDark ? const Color(0xFF151E2E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _periodModeEnabled
              ? (isDark ? Colors.orange.shade700 : Colors.orange.shade200)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
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
    if (services.isEmpty) return const SizedBox.shrink();
    return MultiSelectFilter(
      label: 'الخدمات للتحضير والفلترة',
      selectedIds: _selectedServiceIds,
      allItems: services
          .map(
            (s) => SelectableItem(id: s.id, name: '${s.name} - ${s.dayName}'),
          )
          .toList(),
      onChanged: (ids) async {
        setState(() {
          _selectedServiceIds = List<int>.from(ids);
          _selectedPersonIds.clear();
        });
        await _loadInitialData();
      },
    );
  }

  Widget _buildPersonAutocomplete() {
    final personsAsync = ref.watch(personsRepositoryProvider);
    return personsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (persons) {
        Future<void> submitCode(String value) async {
          if (_isSaving || _isResolvingCode) return;
          _isResolvingCode = true;
          try {
            final query = value.trim();
            if (query.isNotEmpty) {
              final normalizedQ = normalizeArabic(query.toLowerCase());
              final intQ = int.tryParse(query);

              if (intQ != null && !persons.any((p) => p.id == intQ)) {
                try {
                  final matches = await ref
                      .read(personsRepositoryProvider.notifier)
                      .fetchPersonOptions(personId: intQ, limit: 1);
                  if (!mounted) return;
                  if (matches.isNotEmpty) {
                    setState(() {
                      _selectedPersonId = matches.first.id;
                      _selectedPersonName = matches.first.name;
                    });
                    await _saveAttendance();
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم العثور على شخص بهذا الكود'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                } catch (error) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر البحث عن الكود: $error')),
                    );
                  return;
                }
              }

              final exactMatch = persons
                  .where(
                    (p) =>
                        p.id.toString() == query ||
                        normalizeArabic(p.name.toLowerCase()) == normalizedQ ||
                        (intQ != null && p.id == intQ),
                  )
                  .toList();

              final partialMatch = persons
                  .where(
                    (p) =>
                        normalizeArabic(
                          p.name.toLowerCase(),
                        ).contains(normalizedQ) ||
                        p.id.toString().contains(query),
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
          } finally {
            _isResolvingCode = false;
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

            final normalizedQ = normalizeArabic(query.toLowerCase());
            final intQ = int.tryParse(query);

            return persons
                .where((p) {
                  final idMatch =
                      p.id.toString() == query ||
                      (intQ != null && p.id == intQ);
                  return normalizeArabic(
                        p.name.toLowerCase(),
                      ).contains(normalizedQ) ||
                      idMatch;
                })
                .map((p) => PersonOption(id: p.id, name: p.name));
          },
          displayStringForOption: (option) => '${option.id} - ${option.name}',
          onSelected: (option) async {
            if (_isSaving || _isResolvingCode) return;
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
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
              ),
              onSubmitted: submitCode,
            );
          },
        );
      },
      error: (err, stack) => TextButton.icon(
        onPressed: () => ref.invalidate(personsRepositoryProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('تعذر تحميل الأسماء — إعادة المحاولة'),
      ),
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
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
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
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
      ),
    );
  }

  Widget _buildSaveButton() {
    final String labelText;
    final Color? btnColor;
    if (_isCheckoutMode) {
      if (_selectedQuickCheckoutType == 'alone') {
        labelText = 'انصراف (بمفرده)';
        btnColor = Colors.teal.shade700;
      } else if (_selectedQuickCheckoutType == 'parent') {
        labelText = 'انصراف (ولي أمر)';
        btnColor = Colors.orange.shade800;
      } else if (_selectedQuickCheckoutType == 'other') {
        labelText = 'انصراف (آخر)';
        btnColor = Colors.purple.shade700;
      } else {
        labelText = 'انصراف (أتوبيس)';
        btnColor = Colors.indigo.shade700;
      }
    } else {
      labelText = 'سجل حضور';
      btnColor = null;
    }

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
          labelText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: btnColor,
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
    final hasPendingCheckout = _selectedRecords
        .expand(_serviceRecordsFor)
        .where(
          (record) =>
              _selectedServiceIds.isEmpty ||
              _selectedServiceIds.contains(record.serviceId),
        )
        .any(
          (record) =>
              record.attendTime != null &&
              (record.checkoutTime == null || record.checkoutTime!.isEmpty),
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bulkBg = selectedCount == 0
        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
        : (isDark
              ? Theme.of(context).primaryColor.withValues(alpha: 0.25)
              : Colors.blue.shade50);
    final bulkBorder = selectedCount == 0
        ? (isDark ? const Color(0xFF334155) : Colors.grey.shade200)
        : (isDark
              ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
              : Colors.blue.shade100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bulkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bulkBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _isBulkActionRunning ? null : _toggleSelectAllVisible,
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
          : () {
              if (_isCheckoutMode == val) return;
              setState(() {
                final currentVal =
                    int.tryParse(_pointsController.text) ??
                    _defaultAttendancePoints;
                if (_isCheckoutMode) {
                  _checkoutSavedPoints = currentVal;
                } else {
                  _attendanceSavedPoints = currentVal;
                }

                _isCheckoutMode = val;

                if (val) {
                  _pointsController.text = '$_checkoutSavedPoints';
                } else {
                  _pointsController.text = '$_attendanceSavedPoints';
                }
              });
            },
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

  Widget _buildTopCheckoutCards() {
    final options = [
      {
        'type': 'alone',
        'label': 'بمفرده',
        'icon': Icons.directions_walk_rounded,
        'color': Colors.teal.shade700,
        'bg': Colors.teal.shade50,
        'activeBg': Colors.teal.shade700,
      },
      {
        'type': 'bus',
        'label': 'أتوبيس',
        'icon': Icons.directions_bus_rounded,
        'color': Colors.indigo,
        'bg': Colors.indigo.shade50,
        'activeBg': Colors.indigo,
      },
      {
        'type': 'parent',
        'label': 'ولي أمر',
        'icon': Icons.family_restroom_rounded,
        'color': Colors.orange.shade800,
        'bg': Colors.orange.shade50,
        'activeBg': Colors.orange.shade800,
      },
      {
        'type': 'other',
        'label': 'آخر',
        'icon': Icons.alt_route_rounded,
        'color': Colors.purple.shade700,
        'bg': Colors.purple.shade50,
        'activeBg': Colors.purple.shade700,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...options.map((opt) {
            final isSelected = _selectedQuickCheckoutType == opt['type'];
            final color = opt['color'] as Color;
            final activeBg = opt['activeBg'] as Color;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedQuickCheckoutType = opt['type'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeBg
                      : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? activeBg : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.black87),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check, size: 13, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (_selectedQuickCheckoutType == 'other') ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 160,
              height: 32,
              child: TextField(
                controller: _quickOtherReasonController,
                decoration: InputDecoration(
                  hintText: 'اكتب السبب... *',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.purple.shade400,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  filled: true,
                  fillColor: Colors.purple.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.purple.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.purple.shade700,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildCardCheckoutButtons(AttendanceDTO r) {
    final bool isCheckedOut =
        r.checkoutTime != null && r.checkoutTime!.isNotEmpty;
    final String currentType = r.checkoutType ?? 'alone';

    final options = [
      {
        'type': 'alone',
        'label': 'بمفرده',
        'icon': Icons.directions_walk_rounded,
        'color': Colors.teal.shade700,
        'bg': Colors.teal.shade50,
        'activeBg': Colors.teal.shade700,
      },
      {
        'type': 'bus',
        'label': 'أتوبيس',
        'icon': Icons.directions_bus_rounded,
        'color': Colors.indigo,
        'bg': Colors.indigo.shade50,
        'activeBg': Colors.indigo,
      },
      {
        'type': 'parent',
        'label': 'ولي أمر',
        'icon': Icons.family_restroom_rounded,
        'color': Colors.orange.shade800,
        'bg': Colors.orange.shade50,
        'activeBg': Colors.orange.shade800,
      },
      {
        'type': 'other',
        'label': 'آخر',
        'icon': Icons.alt_route_rounded,
        'color': Colors.purple.shade700,
        'bg': Colors.purple.shade50,
        'activeBg': Colors.purple.shade700,
      },
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...options.map((opt) {
          final type = opt['type'] as String;
          final isThisSelected = isCheckedOut && currentType == type;
          final color = opt['color'] as Color;
          final activeBg = opt['activeBg'] as Color;
          final bg = opt['bg'] as Color;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                if (type == 'other') {
                  final reason = await _promptForOtherReason(
                    context,
                    r.personName,
                    initialReason: r.checkoutNotes,
                  );
                  if (reason == null || reason.trim().isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚠️ يجب كتابة سبب الانصراف عند اختيار "آخر"!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  _checkoutPerson(
                    r,
                    checkoutType: 'other',
                    checkoutNotes: reason.trim(),
                  );
                } else {
                  _checkoutPerson(r, checkoutType: type);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isThisSelected ? activeBg : bg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isThisSelected ? activeBg : color.withOpacity(0.4),
                    width: isThisSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isThisSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      size: 13,
                      color: isThisSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isThisSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isThisSelected ? Colors.white : color,
                      ),
                    ),
                    if (isThisSelected) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.check, size: 12, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (isCheckedOut) ...[
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 16),
            tooltip: 'إلغاء الانصراف',
            color: Colors.red.shade400,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: () => _cancelCheckoutForPerson(r),
          ),
        ],
      ],
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
    final fields = ref.watch(fieldsRepositoryProvider).value ?? [];
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
            final fields = ref.watch(fieldsRepositoryProvider).value ?? [];
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
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFFF8FAFC)
                                              : Colors.black87),
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
        // Sort Order
        DropdownButtonFormField<String>(
          value: _sortBy,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'ترتيب الأسماء',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
              value: 'code',
              child: Text('كود الطالب (رقم الكارنيه)'),
            ),
            DropdownMenuItem(value: 'name', child: Text('أبجدي (حسب الإسم)')),
          ],
          onChanged: (v) {
            setState(() => _sortBy = v ?? 'code');
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
            const Expanded(
              child: Text(
                'تاريخ اليوم فقط',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
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
              final services = servicesAsync.value ?? [];

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
                    sortBy: _sortBy,
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
                      ref.read(servicesRepositoryProvider).value ?? [];
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
              final services = servicesAsync.value ?? [];

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
                final fields = ref.read(fieldsRepositoryProvider).value ?? [];
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
                    sortBy: _sortBy,
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
                  final svcsData =
                      ref.read(servicesRepositoryProvider).value ?? [];
                  final Map<String, int> serviceNameToMins = {
                    for (var s in svcsData)
                      s.name.trim(): s.hour * 60 + s.minute,
                  };
                  final Map<int, int> serviceMinsMap = {
                    for (var s in svcsData) s.id: s.hour * 60 + s.minute,
                  };

                  final List<String> sortedDates = uniqueDatesSet.toList()
                    ..sort((a, b) {
                      final dateA = a.split('|')[0];
                      final dateB = b.split('|')[0];
                      final dateCompare = dateA.compareTo(dateB);
                      if (dateCompare != 0) return dateCompare;

                      final serviceA = a.split('|')[1];
                      final serviceB = b.split('|')[1];
                      final minsA = serviceNameToMins[serviceA] ?? 0;
                      final minsB = serviceNameToMins[serviceB] ?? 0;
                      final timeCompare = minsA.compareTo(minsB);
                      if (timeCompare != 0) return timeCompare;

                      return serviceA.compareTo(serviceB);
                    });

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
              final services = servicesAsync.value ?? [];

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
                    sortBy: _sortBy,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }
                  final svcsData =
                      ref.read(servicesRepositoryProvider).value ?? [];
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
                    final df = periodServiceResult.dateFrom;
                    final dt = periodServiceResult.dateTo;
                    final String dateSuffix;
                    if (df.year == dt.year &&
                        df.month == dt.month &&
                        df.day == dt.day) {
                      dateSuffix = DateFormat('yyyy-MM-dd').format(df);
                    } else {
                      dateSuffix =
                          '${DateFormat('yyyy-MM-dd').format(df)} - ${DateFormat('yyyy-MM-dd').format(dt)}';
                    }
                    final exportResult =
                        await GroupedPdfExportService.writeGroups<
                          AttendanceDTO
                        >(
                          groups: groupedData,
                          directoryPath: directory,
                          baseName: 'Attendance_Report',
                          dateSuffix: dateSuffix,
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
                                sortBy: _sortBy,
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
                    sortBy: _sortBy,
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
                  if (Platform.isWindows) {
                    final tempDir = await getTemporaryDirectory();
                    final file = File('${tempDir.path}/Attendance_Report.pdf');
                    await file.writeAsBytes(pdfBytes);
                    await launchUrl(Uri.file(file.path));
                  } else {
                    await Printing.layoutPdf(
                      onLayout: (_) async => pdfBytes,
                      name: 'Attendance_Report.pdf',
                    );
                  }
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
              final services = servicesAsync.value ?? [];

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
                final fields = ref.read(fieldsRepositoryProvider).value ?? [];
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
                    sortBy: _sortBy,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }

                  final svcsData =
                      ref.read(servicesRepositoryProvider).value ?? [];
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
                    final df = periodServiceResult.dateFrom;
                    final dt = periodServiceResult.dateTo;
                    final String dateSuffix;
                    if (df.year == dt.year &&
                        df.month == dt.month &&
                        df.day == dt.day) {
                      dateSuffix = DateFormat('yyyy-MM-dd').format(df);
                    } else {
                      dateSuffix =
                          '${DateFormat('yyyy-MM-dd').format(df)} - ${DateFormat('yyyy-MM-dd').format(dt)}';
                    }
                    final exportResult =
                        await GroupedPdfExportService.writeGroups<
                          AttendanceDTO
                        >(
                          groups: groupedData,
                          directoryPath: directory,
                          baseName: 'Attendance_Grid',
                          dateSuffix: dateSuffix,
                          buildPdf: (groupName, rows) =>
                              AttendanceGridPdfGenerator.generateGridPDF(
                                data: rows,
                                title: 'سجل الحضور والغياب - $groupName',
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
                                sortBy: _sortBy,
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
                        title: 'سجل الحضور والغياب',
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
                        sortBy: _sortBy,
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
                  if (Platform.isWindows) {
                    final tempDir = await getTemporaryDirectory();
                    final file = File('${tempDir.path}/Attendance_Grid.pdf');
                    await file.writeAsBytes(pdfBytes);
                    await launchUrl(Uri.file(file.path));
                  } else {
                    await Printing.layoutPdf(
                      onLayout: (_) async => pdfBytes,
                      name: 'Attendance_Grid.pdf',
                    );
                  }
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
      findChildIndexCallback: (key) {
        if (key is! ValueKey<int>) return null;
        final index = _records.indexWhere((p) => p.personId == key.value);
        return index < 0 ? null : index;
      },
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

  Widget _buildServiceAttendanceLine(AttendanceServiceRecord record) {
    final serviceName = (record.serviceName?.trim().isNotEmpty ?? false)
        ? record.serviceName!
        : 'خدمة غير محددة';
    final checkout = (record.checkoutTime?.trim().isNotEmpty ?? false)
        ? ' • انصراف: ${record.checkoutTime}'
        : '';
    final hasCheckout = record.checkoutTime?.trim().isNotEmpty ?? false;
    final fallbackAttendancePoints = hasCheckout
        ? (record.point < 0
              ? 0
              : (record.point > _defaultAttendancePoints
                    ? _defaultAttendancePoints
                    : record.point))
        : record.point;
    final attendancePoints = record.attendancePoint ?? fallbackAttendancePoints;
    final checkoutPoints =
        record.checkoutPoint ??
        (hasCheckout && record.point > attendancePoints
            ? record.point - attendancePoints
            : 0);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.12)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            serviceName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          Text(
            '${record.dateWeek ?? ''} • حضور: ${record.attendTime ?? '-'}$checkout',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Chip(
            avatar: const Icon(Icons.login, size: 14, color: Colors.green),
            label: Text('نقاط الحضور: $attendancePoints'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelStyle: TextStyle(
              color: Colors.green.shade800,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (hasCheckout)
            Chip(
              avatar: const Icon(Icons.logout, size: 14, color: Colors.red),
              label: Text('نقاط الانصراف: $checkoutPoints'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelStyle: TextStyle(
                color: Colors.red.shade800,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (hasCheckout)
            Chip(
              label: Text('الإجمالي: ${record.point}'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTag(IconData icon, String? label, Color color) {
    if (label == null || label.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adaptiveColor = AppTheme.getAdaptiveAccent(color, isDark);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 1.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.45)
              : color.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 12, color: adaptiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : color,
              fontSize: isMobile ? 10.5 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    AttendanceDTO r, {
    bool canEdit = true,
    bool canDelete = true,
    bool canAdd = true,
  }) {
    final fields = ref.watch(fieldsRepositoryProvider).value ?? [];
    String getLabel(String key, String fallback) {
      final f = fields.where((f) => f.fieldKey == key).firstOrNull;
      return f?.name ?? fallback;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final bool isPresent = r.id != null && r.attendTime != null;
    final bool isSelected = _selectedPersonIds.contains(r.personId);
    final visitIcon = r.visited == 2
        ? Icons.check_box
        : (r.visited == 1
              ? Icons.indeterminate_check_box
              : Icons.check_box_outline_blank);
    final visitColor = r.visited == 2
        ? Colors.green
        : (r.visited == 1
              ? Colors.orange
              : (isDark ? const Color(0xFF94A3B8) : Colors.grey));

    final cardSurface = isPresent
        ? (isDark ? const Color(0xFF151E2E) : Colors.white)
        : (isDark ? const Color(0xFF0F1623) : const Color(0xFFF8FAFC));

    final cardBorder = isSelected
        ? theme.primaryColor
        : (isPresent
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)));

    Widget buildTimingBadge() {
      if (!isPresent || r.attendTime == null || r.serviceId == null) {
        return const SizedBox.shrink();
      }
      final svcs = ref.read(servicesRepositoryProvider).value ?? [];
      final svc = svcs.where((s) => s.id == r.serviceId).firstOrNull;
      if (svc != null && r.attendTime!.isNotEmpty) {
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
            final serviceMins = svc.hour * 60 + svc.minute;
            final diff = attendMins - serviceMins;
            if (diff != 0) {
              final isLate = diff > 0;
              final absDiff = diff.abs();
              final badgeColor = isLate ? Colors.orange : Colors.blue;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? badgeColor.withValues(alpha: 0.22)
                      : badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? badgeColor.withValues(alpha: 0.45)
                        : badgeColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isLate ? 'تأخير: $absDiff د' : 'تبكير: $absDiff د',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFF8FAFC)
                        : (isLate
                              ? Colors.orange.shade900
                              : Colors.blue.shade900),
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
    }

    if (isMobile) {
      // Compact, responsive mobile attendance card
      return Card(
        key: ValueKey(r.personId),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        elevation: isPresent ? (isDark ? 2.5 : 1.5) : (isDark ? 0.8 : 0.5),
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cardBorder, width: isSelected ? 1.5 : 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Checkbox + Status Indicator + Name & Code + Timing + Actions
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
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: (isPresent ? Colors.green : Colors.red).withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPresent
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isPresent
                          ? (isDark ? const Color(0xFF4ADE80) : Colors.green)
                          : Colors.red,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.personName ?? 'مجهول',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPresent
                                      ? textPrimary
                                      : textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '#${r.personId}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isPresent) buildTimingBadge(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Trailing compact action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Badge(
                          isLabelVisible:
                              (r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                              (r.checkoutNotes?.trim().isNotEmpty ?? false),
                          smallSize: 6,
                          backgroundColor: Colors.amber.shade800,
                          child: Icon(
                            ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                                    (r.checkoutNotes?.trim().isNotEmpty ??
                                        false))
                                ? Icons.note_alt_rounded
                                : Icons.note_alt_outlined,
                            size: 18,
                            color:
                                ((r.attendanceNotes?.trim().isNotEmpty ??
                                        false) ||
                                    (r.checkoutNotes?.trim().isNotEmpty ??
                                        false))
                                ? Colors.amber.shade800
                                : textMuted,
                          ),
                        ),
                        onPressed: () => _openAttendanceNotesDialog(r),
                        tooltip: 'الملاحظات',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      if (isPresent && canEdit) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showEditDialog(r),
                          tooltip: 'تعديل',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                      if (isPresent && canDelete) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.redAccent,
                            size: 19,
                          ),
                          onPressed: () => _deleteAttendance(r),
                          tooltip: 'حذف',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Row 2: Compact Tags Wrap (Stage, Khoros, Area, Phone)
              Wrap(
                spacing: 4,
                runSpacing: 3,
                children: [
                  if (r.stageName != null && r.stageName!.isNotEmpty)
                    _buildAttendanceTag(
                      Icons.school,
                      '${getLabel('stage', 'المرحلة')}: ${r.stageName}',
                      Colors.blue,
                    ),
                  if (r.khorosName != null && r.khorosName!.isNotEmpty)
                    _buildAttendanceTag(
                      Icons.library_music,
                      '${getLabel('khoros', 'الخورس')}: ${r.khorosName}',
                      Colors.purple,
                    ),
                  if (r.areaName != null && r.areaName!.isNotEmpty)
                    _buildAttendanceTag(
                      Icons.map,
                      '${getLabel('area', 'المنطقة')}: ${r.areaName}',
                      Colors.teal,
                    ),
                  if (r.mobile != null && r.mobile!.isNotEmpty)
                    InkWell(
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: r.mobile);
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(
                            alpha: isDark ? 0.22 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withValues(
                              alpha: isDark ? 0.45 : 0.25,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 10.5,
                              color: isDark
                                  ? const Color(0xFF4ADE80)
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              r.mobile!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              // Row 3: Status / Attend Lines or Absent Quick-Action
              if (isPresent) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _serviceRecordsFor(
                    r,
                  ).map(_buildServiceAttendanceLine).toList(),
                ),
                if (canAdd && _serviceRecordsFor(r).length == 1) ...[
                  const SizedBox(height: 4),
                  _buildChildCardCheckoutButtons(r),
                ],
                if (r.checkoutType == 'other' &&
                    (r.checkoutNotes?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(
                        alpha: isDark ? 0.22 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.purple.withValues(
                          alpha: isDark ? 0.45 : 0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 14,
                          color: isDark
                              ? Colors.purple.shade200
                              : Colors.purple.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'سبب الانصراف (آخر): ${r.checkoutNotes!.trim()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.purple.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: isDark ? 0.22 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withValues(
                            alpha: isDark ? 0.45 : 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        'غائب',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF87171)
                              : Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canAdd)
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPersonId = r.personId;
                            _selectedPersonName = r.personName;
                            _autocompleteController?.text = r.personName ?? "";
                          });
                          _saveAttendance();
                        },
                        icon: const Icon(Icons.add_task_rounded, size: 14),
                        label: const Text(
                          'تسجيل حضور',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              // Row 4: Visitation Section
              if (r.id != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: !canEdit
                            ? null
                            : () async {
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
                            Icon(visitIcon, color: visitColor, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              r.visited == 2 ? 'تم الافتقاد' : 'لم يتم',
                              style: TextStyle(
                                fontSize: 11,
                                color: visitColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Desktop/Tablet spacious layout
    return Card(
      key: ValueKey(r.personId),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPresent ? 4 : 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.primaryColor
              : (isPresent
                    ? theme.primaryColor.withOpacity(0.2)
                    : (isDark ? const Color(0xFF334155) : Colors.transparent)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      color: cardSurface,
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
                              fontSize: 16,
                              color: isPresent ? textPrimary : textSecondary,
                            ),
                          ),
                          buildTimingBadge(),
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
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              'كود: ${r.personId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (r.stageName != null && r.stageName!.isNotEmpty)
                            _buildAttendanceTag(
                              Icons.school,
                              '${getLabel('stage', 'المرحلة')}: ${r.stageName}',
                              Colors.blue,
                            ),
                          if (r.khorosName != null && r.khorosName!.isNotEmpty)
                            _buildAttendanceTag(
                              Icons.library_music,
                              '${getLabel('khoros', 'الخورس')}: ${r.khorosName}',
                              Colors.purple,
                            ),
                          if (r.areaName != null && r.areaName!.isNotEmpty)
                            _buildAttendanceTag(
                              Icons.map,
                              '${getLabel('area', 'المنطقة')}: ${r.areaName}',
                              Colors.teal,
                            ),
                          if (r.mobile != null && r.mobile!.isNotEmpty)
                            _buildAttendanceTag(
                              Icons.phone,
                              '${getLabel('mobile', 'تليفون')}: ${r.mobile}',
                              Colors.orange,
                            ),
                          if (r.phone != null && r.phone!.isNotEmpty)
                            _buildAttendanceTag(
                              Icons.phone_in_talk,
                              '${getLabel('phone', 'أرضي')}: ${r.phone}',
                              Colors.brown,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isPresent)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _serviceRecordsFor(
                            r,
                          ).map(_buildServiceAttendanceLine).toList(),
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
              if (r.checkoutType == 'other' &&
                  (r.checkoutNotes?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(
                      alpha: isDark ? 0.22 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withValues(
                        alpha: isDark ? 0.45 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alt_route_rounded,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سبب الانصراف (آخر): ${r.checkoutNotes!.trim()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : Colors.purple.shade900,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          final reason = await _promptForOtherReason(
                            context,
                            r.personName,
                            initialReason: r.checkoutNotes,
                          );
                          if (reason != null && reason.trim().isNotEmpty) {
                            _checkoutPerson(
                              r,
                              checkoutType: 'other',
                              checkoutNotes: reason.trim(),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'تعديل السبب',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (r.checkoutType == 'parent' &&
                  (r.checkoutNotes?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: isDark ? 0.22 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(
                        alpha: isDark ? 0.45 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        size: 15,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ملاحظة ولي الأمر: ${r.checkoutNotes!.trim()}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (r.attendanceNotes?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: isDark ? 0.22 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(
                        alpha: isDark ? 0.45 : 0.25,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ملاحظات الحضور: ${r.attendanceNotes!.trim()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isPresent &&
                      canAdd &&
                      _serviceRecordsFor(r).length == 1) ...[
                    _buildChildCardCheckoutButtons(r),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Badge(
                      isLabelVisible:
                          (r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                          (r.checkoutNotes?.trim().isNotEmpty ?? false),
                      smallSize: 8,
                      backgroundColor: Colors.amber.shade800,
                      child: Icon(
                        ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                                (r.checkoutNotes?.trim().isNotEmpty ?? false))
                            ? Icons.note_alt_rounded
                            : Icons.note_alt_outlined,
                        size: 22,
                        color:
                            ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                                (r.checkoutNotes?.trim().isNotEmpty ?? false))
                            ? Colors.amber.shade800
                            : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : Colors.indigo.shade600),
                      ),
                    ),
                    onPressed: () => _openAttendanceNotesDialog(r),
                    tooltip: 'الملاحظات (حضور وانصراف)',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
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
              Row(
                children: [
                  Expanded(
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Badge(
                      isLabelVisible:
                          (r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                          (r.checkoutNotes?.trim().isNotEmpty ?? false),
                      smallSize: 8,
                      backgroundColor: Colors.amber.shade800,
                      child: Icon(
                        ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                                (r.checkoutNotes?.trim().isNotEmpty ?? false))
                            ? Icons.note_alt_rounded
                            : Icons.note_alt_outlined,
                        size: 22,
                        color:
                            ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                                (r.checkoutNotes?.trim().isNotEmpty ?? false))
                            ? Colors.amber.shade800
                            : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : Colors.grey.shade600),
                      ),
                    ),
                    onPressed: () => _openAttendanceNotesDialog(r),
                    tooltip: 'الملاحظات (حضور وانصراف)',
                  ),
                ],
              ),
            ],
            if ((r.attendanceNotes?.trim().isNotEmpty ?? false) ||
                (r.checkoutNotes?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.22 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: isDark ? 0.45 : 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.attendanceNotes?.trim().isNotEmpty ?? false)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.login_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ملاحظة حضور: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF4ADE80)
                                  : Colors.green.shade900,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.attendanceNotes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if ((r.attendanceNotes?.trim().isNotEmpty ?? false) &&
                        (r.checkoutNotes?.trim().isNotEmpty ?? false))
                      const SizedBox(height: 4),
                    if (r.checkoutNotes?.trim().isNotEmpty ?? false)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ملاحظة انصراف: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF87171)
                                  : Colors.red.shade900,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.checkoutNotes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
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
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.grey[50],
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
