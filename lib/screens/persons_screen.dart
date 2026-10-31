import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../services/auth_service.dart';
import '../database/database_provider.dart';
import '../repositories/persons_repository.dart';
import '../repositories/fields_repository.dart';
import '../repositories/documents_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/fathers_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/services_repository.dart';
import '../ui/dialogs/sorting_dialog.dart';
import '../services/person_report_service.dart';
import '../services/excel_export_service.dart';
import 'person_dialog.dart';
import '../ui/dialogs/bulk_edit_dialog.dart';
import 'person_fields_settings_screen.dart';
import 'family_relationships_view.dart';
import '../models/person_option.dart';
import '../models/bulk_person_edit.dart';
import '../ui/widgets/multi_select_filter.dart';
import '../widgets/print_progress_dialog.dart';
import '../services/pdf_generation_task.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';
import '../utils/silent_refresh_controller.dart';
import '../sync/person_change_source.dart';
import '../utils/delta_page_cache.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class _PersonPrintServiceChoice {
  const _PersonPrintServiceChoice({this.service});

  final ServiceDTO? service;
}

class PersonsScreen extends ConsumerStatefulWidget {
  const PersonsScreen({super.key});

  @override
  ConsumerState<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends ConsumerState<PersonsScreen> {
  final Set<int> _selectedIds = {};
  String _searchQuery = '';
  List<int> _filterStageIds = [];
  List<int> _filterKhorosIds = [];
  List<int> _filterAreaIds = [];
  List<int> _filterFatherIds = [];
  List<String> _filterGenders = [];
  List<int> _filterBirthdayDay = [];
  List<int> _filterBirthdayMonth = [];
  List<int> _filterBirthdayYear = [];
  List<String> _filterRohots = [];
  bool _showFilters = false;
  bool _mobileFiltersExpanded = false;

  final ScrollController _scrollController = ScrollController();
  final List<PersonListDTO> _allPersons = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Completer<void>? _pageLoad;
  bool _hasMore = true;
  int _offset = 0;
  int _totalCount = 0;
  int _limit = 50;

  String? _changeCursor;
  Future<void>? _refreshFlight;
  bool _refreshAgain = false;
  late final SilentRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = SilentRefreshController();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openFieldsSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PersonFieldsSettingsScreen()),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _searchQuery.isEmpty) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final pageLoad = Completer<void>();
    _pageLoad = pageLoad;
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;
    setState(() {
      _isLoading = _allPersons.isEmpty;
      _isLoadingMore = false;
      _selectedIds.clear();
    });

    try {
      final repo = ref.read(personsRepositoryProvider.notifier);
      final checkpoint = await ref
          .read(personChangeSourceProvider)
          .read(cursor: null, knownIds: const [], domain: 'people');

      final results = await Future.wait([
        repo.fetchTotalCount(
          search: _searchQuery,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          rohots: _filterRohots,
        ),
        repo.fetchPersons(
          search: _searchQuery,
          limit: _limit,
          offset: 0,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          rohots: _filterRohots,
          includeServices: false,
        ),
      ]);

      final count = results[0] as int;
      final data = results[1] as List<PersonListDTO>;

      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() {
          _allPersons.clear();
          _allPersons.addAll(data);
          _changeCursor = checkpoint.cursor;
          _totalCount = count;
          _isLoading = false;
          _offset = data.length;
          _hasMore = data.length < _totalCount;
        });
      }
    } catch (e) {
      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التحميل: $e')));
      }
    } finally {
      if (!pageLoad.isCompleted) pageLoad.complete();
      if (identical(_pageLoad, pageLoad)) _pageLoad = null;
    }
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

    final targetLimit = _allPersons.isNotEmpty ? _allPersons.length : _limit;
    final repo = ref.read(personsRepositoryProvider.notifier);

    try {
      final checkpoint = await ref
          .read(personChangeSourceProvider)
          .read(
            cursor: _changeCursor,
            knownIds: _allPersons.map((p) => p.id),
            domain: 'people',
          );
      final changedIds = checkpoint.personIds;
      if (!mounted || generation != _refreshController.currentGeneration)
        return;
      if (changedIds != null && changedIds.isEmpty) {
        _changeCursor = checkpoint.cursor;
        return;
      }
      final results = await Future.wait([
        repo.fetchTotalCount(
          search: _searchQuery,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          rohots: _filterRohots,
        ),
        repo.fetchPersons(
          search: _searchQuery,
          personIds: changedIds?.toList(),
          limit: changedIds == null ? targetLimit : null,
          offset: 0,
          stageIds: _filterStageIds,
          khorosIds: _filterKhorosIds,
          areaIds: _filterAreaIds,
          fatherIds: _filterFatherIds,
          genders: _filterGenders,
          birthdayDay: _filterBirthdayDay,
          birthdayMonth: _filterBirthdayMonth,
          birthdayYear: _filterBirthdayYear,
          rohots: _filterRohots,
          includeServices: false,
        ),
      ]);

      final count = results[0] as int;
      var data = results[1] as List<PersonListDTO>;
      if (changedIds != null) {
        data = mergeChangedPrefix<PersonListDTO>(
          cached: _allPersons,
          changed: data,
          changedIds: changedIds,
          idOf: (p) => p.id,
          compare: (a, b) => b.id.compareTo(a.id),
          hasMore: _hasMore,
        );
        if (data.length > targetLimit) data = data.take(targetLimit).toList();
        if (data.length < targetLimit && data.length < count) {
          final tail = await repo.fetchPersons(
            search: _searchQuery,
            limit: targetLimit - data.length,
            offset: data.length,
            stageIds: _filterStageIds,
            khorosIds: _filterKhorosIds,
            areaIds: _filterAreaIds,
            fatherIds: _filterFatherIds,
            genders: _filterGenders,
            birthdayDay: _filterBirthdayDay,
            birthdayMonth: _filterBirthdayMonth,
            birthdayYear: _filterBirthdayYear,
            rohots: _filterRohots,
            includeServices: false,
          );
          final ids = data.map((p) => p.id).toSet();
          data.addAll(tail.where((p) => ids.add(p.id)));
        }
      }

      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() {
          _allPersons.clear();
          _allPersons.addAll(data);
          _changeCursor = checkpoint.cursor;
          _isLoading = false;
          _isLoadingMore = false;
          _totalCount = count;
          _offset = data.length;
          _hasMore = data.length < _totalCount;
          // Retain valid selections that still exist in data
          final existingIds = data.map((p) => p.id).toSet();
          _selectedIds.retainWhere((id) => existingIds.contains(id));
        });
      }
    } catch (e) {
      debugPrint('[PersonsScreen] Silent refresh error: $e');
      rethrow;
    }
  }

  Future<void> _loadMore() async {
    if (_pageLoad != null || _isLoadingMore || _isLoading || !_hasMore) return;
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;
    final pageLoad = Completer<void>();
    _pageLoad = pageLoad;

    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(personsRepositoryProvider.notifier);
      final data = await repo.fetchPersons(
        search: _searchQuery,
        limit: _limit,
        offset: _offset,
        stageIds: _filterStageIds,
        khorosIds: _filterKhorosIds,
        areaIds: _filterAreaIds,
        fatherIds: _filterFatherIds,
        genders: _filterGenders,
        birthdayDay: _filterBirthdayDay,
        birthdayMonth: _filterBirthdayMonth,
        birthdayYear: _filterBirthdayYear,
        rohots: _filterRohots,
        includeServices: false,
      );

      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() {
          final ids = _allPersons.map((p) => p.id).toSet();
          _allPersons.addAll(data.where((p) => ids.add(p.id)));
          _offset += data.length;
          _isLoadingMore = false;
          if (data.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء تحميل المزيد: $e')));
      }
    } finally {
      if (!pageLoad.isCompleted) pageLoad.complete();
      if (identical(_pageLoad, pageLoad)) _pageLoad = null;
      if (mounted &&
          generation == _refreshController.currentGeneration &&
          _refreshController.isStale) {
        _refreshController.requestRefresh(onRefresh: _silentRefresh);
      }
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadInitialData();
  }

  void _openAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PersonDialog(),
    );
    if (result == true && mounted) {
      await _silentRefresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة الشخص بنجاح')));
    }
  }

  void _openEditDialog(PersonListDTO person) async {
    final fullPerson = await ref
        .read(personsRepositoryProvider.notifier)
        .fetchPersonById(person.id);
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PersonDialog(person: fullPerson ?? person),
    );
    if (result == true && mounted) {
      await _silentRefresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح')));
    }
  }

  void _deletePerson(PersonListDTO person) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${person.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(personsRepositoryProvider.notifier)
          .deletePerson(person.id);
      if (mounted) {
        if (success) {
          await _silentRefresh();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('فشل الحذف')));
        }
      }
    }
  }

  Future<void> _printSinglePerson(PersonListDTO person) async {
    try {
      final personsRepo = ref.read(personsRepositoryProvider.notifier);
      final fullPerson = await personsRepo.fetchPersonById(person.id) ?? person;
      final fields = await ref
          .read(fieldsRepositoryProvider.notifier)
          .fetchAll();
      final customValues = await personsRepo.fetchCustomFieldValues(person.id);
      final services = await ref.read(servicesRepositoryProvider.future);
      if (!mounted) return;

      final serviceChoice = await _pickPersonPrintService(services);
      if (serviceChoice == null) return;

      final reportFields = <SinglePersonReportField>[];
      final documents = <SinglePersonReportDocument>[];
      final documentsRepo = ref.read(documentsRepositoryProvider.notifier);

      for (final field in fields) {
        if (field.type == 'native') {
          reportFields.add(
            SinglePersonReportField(
              label: field.name,
              value: _nativePersonFieldValue(fullPerson, field.fieldKey),
            ),
          );
        } else if (field.type == 'document') {
          final fieldDocuments = await documentsRepo.fetchDocuments(
            fullPerson.id,
            field.id,
          );
          documents.addAll(
            fieldDocuments.map(
              (document) => SinglePersonReportDocument(
                fieldName: field.name,
                fileName: document.fileName,
                fileContent: document.fileContent,
                createdAt: document.createdAt,
              ),
            ),
          );
          reportFields.add(
            SinglePersonReportField(
              label: field.name,
              value: fieldDocuments.isEmpty
                  ? '-'
                  : fieldDocuments
                        .map((document) => document.fileName)
                        .join('، '),
            ),
          );
        } else {
          reportFields.add(
            SinglePersonReportField(
              label: field.name,
              value: customValues[field.id] ?? '',
            ),
          );
        }
      }

      final bytes = await PersonReportService.generateSinglePersonPDF(
        person: fullPerson,
        fields: reportFields,
        documents: documents,
        serviceName: serviceChoice.service?.name,
        serviceLogo: serviceChoice.service?.logo,
      );
      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'person_${fullPerson.id}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر طباعة بيانات الشخص: $error')),
      );
    }
  }

  Future<void> _bulkEditSelected() async {
    if (_selectedIds.isEmpty) return;
    final personIds = _selectedIds.toList(growable: false);
    final result = await showDialog<BulkPersonEdit>(
      context: context,
      builder: (context) => BulkEditDialog(personIds: personIds),
    );
    if (result != null && mounted) {
      final success = await ref
          .read(personsRepositoryProvider.notifier)
          .bulkUpdatePersons(
            ids: personIds,
            stageId: result.stageId,
            khorosId: result.khorosId,
            areaId: result.areaId,
            fatherId: result.fatherId,
            streetName: result.streetName,
            phone: result.phone,
            mobile: result.mobile,
            day: result.day,
            month: result.month,
            year: result.year,
            jenderName: result.jenderName,
            rohot: result.rohot,
            leader: result.leader,
            serviceIds: result.serviceIds,
            customValues: result.customValues,
          );
      if (mounted) {
        if (success) {
          setState(() {
            _selectedIds.clear();
          });
          await _loadInitialData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل البيانات بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('فشل تعديل البيانات')));
        }
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف الجماعي'),
          content: Text(
            'هل أنت متأكد من حذف ${_selectedIds.length} من الأشخاص المحددين؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف الكل',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(personsRepositoryProvider.notifier)
          .bulkDeletePersons(_selectedIds.toList());
      if (mounted) {
        if (success) {
          setState(() {
            _selectedIds.clear();
          });
          await _loadInitialData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الأشخاص المحددين بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف بعض أو كل الأشخاص')),
          );
        }
      }
    }
  }

  Future<void> _printSelectedForms() async {
    if (_selectedIds.isEmpty) return;
    try {
      final repo = ref.read(personsRepositoryProvider.notifier);
      final fields = await ref
          .read(fieldsRepositoryProvider.notifier)
          .fetchAll();
      final services = await ref.read(servicesRepositoryProvider.future);

      if (!mounted) return;

      final serviceChoice = await _pickPersonPrintService(services);
      if (serviceChoice == null) return;

      final progress = await showPrintProgressDialog(
        context,
        initialMessage: 'جاري جلب استمارات المحددين...',
      );

      final selectedPersonsList = <PersonListDTO>[];
      final fieldsList = <List<SinglePersonReportField>>[];
      final documentsList = <List<SinglePersonReportDocument>>[];

      final documentsRepo = ref.read(documentsRepositoryProvider.notifier);

      int count = 0;
      for (final id in _selectedIds) {
        count++;
        progress.update(
          'جاري جلب بيانات الشخص $count من ${_selectedIds.length}...',
          current: count,
          total: _selectedIds.length,
        );

        final fullPerson = await repo.fetchPersonById(id);
        if (fullPerson == null) continue;

        final customValues = await repo.fetchCustomFieldValues(id);

        final reportFields = <SinglePersonReportField>[];
        final documents = <SinglePersonReportDocument>[];

        for (final field in fields) {
          if (field.type == 'native') {
            reportFields.add(
              SinglePersonReportField(
                label: field.name,
                value: _nativePersonFieldValue(fullPerson, field.fieldKey),
              ),
            );
          } else if (field.type == 'document') {
            final fieldDocuments = await documentsRepo.fetchDocuments(
              fullPerson.id,
              field.id,
            );
            documents.addAll(
              fieldDocuments.map(
                (document) => SinglePersonReportDocument(
                  fieldName: field.name,
                  fileName: document.fileName,
                  fileContent: document.fileContent,
                  createdAt: document.createdAt,
                ),
              ),
            );
            reportFields.add(
              SinglePersonReportField(
                label: field.name,
                value: fieldDocuments.isEmpty
                    ? '-'
                    : fieldDocuments
                          .map((document) => document.fileName)
                          .join('، '),
              ),
            );
          } else {
            reportFields.add(
              SinglePersonReportField(
                label: field.name,
                value: customValues[field.id] ?? '',
              ),
            );
          }
        }

        selectedPersonsList.add(fullPerson);
        fieldsList.add(reportFields);
        documentsList.add(documents);
      }

      progress.update(
        'جاري إنشاء ملف استمارات PDF...',
        current: count,
        total: _selectedIds.length,
      );

      final bytes = await PersonReportService.generateMultiplePeopleFormsPDF(
        persons: selectedPersonsList,
        fieldsList: fieldsList,
        documentsList: documentsList,
        serviceName: serviceChoice.service?.name,
        serviceLogo: serviceChoice.service?.logo,
      );

      progress.close();
      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'selected_persons_forms.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء طباعة الاستمارات: $e')),
        );
      }
    }
  }

  Future<_PersonPrintServiceChoice?> _pickPersonPrintService(
    List<ServiceDTO> services,
  ) {
    return showDialog<_PersonPrintServiceChoice>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('بيانات الخدمة في الاستمارة'),
          children: [
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(context, const _PersonPrintServiceChoice()),
              child: const ListTile(
                leading: Icon(Icons.not_interested_outlined),
                title: Text('بدون خدمة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            for (final service in services)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(
                  context,
                  _PersonPrintServiceChoice(service: service),
                ),
                child: ListTile(
                  leading: service.logo == null || service.logo!.isEmpty
                      ? const CircleAvatar(child: Icon(Icons.church, size: 18))
                      : CircleAvatar(
                          backgroundImage: MemoryImage(service.logo!),
                        ),
                  title: Text(service.name),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _nativePersonFieldValue(PersonListDTO person, String? fieldKey) {
    switch (fieldKey) {
      case 'name':
        return person.name;
      case 'code':
        return person.id.toString();
      case 'stage':
        return person.stageName;
      case 'khoros':
        return person.khorosName;
      case 'area':
        return person.areaName;
      case 'father':
        return person.fatherName;
      case 'phone':
        return person.phone;
      case 'mobile':
        return person.mobile;
      case 'street':
        return person.streetName;
      case 'rohot':
        return person.rohot ?? '';
      case 'gender':
      case 'jender':
        return person.jenderName ?? '';
      case 'birthday':
        final parts = [person.day, person.month, person.year]
            .whereType<int>()
            .map((part) => part.toString().padLeft(2, '0'))
            .toList();
        return parts.join('/');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(sourceEpochProvider, (previous, next) {
      _refreshController.updateEpoch(next);
      if (mounted) {
        setState(() {
          _changeCursor = null;
          _selectedIds.clear();
        });
        _refreshController.requestRefresh(
          onRefresh: _silentRefresh,
          immediate: true,
        );
      }
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.people), (prev, next) {
      if (next > 1) {
        _refreshController.markStale(next, onRefresh: _silentRefresh);
      }
    });

    final user = ref.watch(authServiceProvider).value;
    final canAdd =
        user == null ||
        !user.isAdvanced ||
        (user.granularPermissions['persons']?['add'] ?? false);

    final viewport = MediaQuery.sizeOf(context);
    final isMobile = viewport.width < 700 || viewport.height < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: isMobile ? 8 : 16),
              Expanded(
                child: isMobile
                    ? Column(
                        children: [
                          _buildMobileFilterToggle(),
                          if (_mobileFiltersExpanded)
                            Expanded(child: _buildFilterPanel()),
                          const SizedBox(height: 8),
                          if (!_mobileFiltersExpanded)
                            Expanded(
                              child: _isLoading && _allPersons.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _buildPersonsList(user),
                            ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showFilters)
                            SizedBox(width: 280, child: _buildFilterPanel())
                          else
                            const SizedBox.shrink(),
                          if (_showFilters) const SizedBox(width: 16),
                          Expanded(
                            child: _isLoading && _allPersons.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _buildPersonsList(user),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: canAdd
            ? (isMobile
                  ? FloatingActionButton(
                      onPressed: _openAddDialog,
                      child: const Icon(Icons.add),
                    )
                  : FloatingActionButton.extended(
                      onPressed: _openAddDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة شخص جديد'),
                    ))
            : null,
      ),
    );
  }

  Widget _buildPageSizeSelector() {
    final sizes = [50, 100, 200, 500, 999999];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151E2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'تحميل:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94A3B8) : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          ...sizes.map((s) {
            final isSelected =
                (_limit >= 999999 && s == 999999) || (_limit == s);
            final label = s == 999999 ? 'الكل' : s.toString();

            return InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                if (_limit == s) return;
                setState(() {
                  _limit = s;
                });
                _loadInitialData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : (isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : Colors.black87),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectAllBar() {
    if (_allPersons.isEmpty) return const SizedBox.shrink();
    final bool isAllSelected =
        _selectedIds.length == _allPersons.length && _selectedIds.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isAllSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedIds.addAll(_allPersons.map((p) => p.id));
                } else {
                  _selectedIds.clear();
                }
              });
            },
          ),
          const Text(
            'تحديد الكل في الصفحة الحالية',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          _buildPageSizeSelector(),
          const Spacer(),
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selectedIds.clear()),
              child: const Text(
                'إلغاء التحديد',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildTitleAndCount()),
                      if (_selectedIds.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: _bulkEditSelected,
                          tooltip: 'تعديل جماعي',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: _deleteSelected,
                          tooltip: 'مسح لهم',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.print_outlined,
                            color: Colors.deepPurple,
                          ),
                          onPressed: _printSelectedForms,
                          tooltip: 'طباعة استمارات المحددين',
                        ),
                        const SizedBox(width: 4),
                      ],
                      _buildPrintButton(isMobile: true),
                      const SizedBox(width: 8),
                      _buildExcelButton(isMobile: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSelectAllBar(),
                  _buildSearchBox(),
                ],
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTitleAndCount(),
                    const SizedBox(width: 12),
                    _buildPageSizeSelector(),
                    if (_allPersons.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value:
                                _selectedIds.length == _allPersons.length &&
                                _selectedIds.isNotEmpty,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.addAll(
                                    _allPersons.map((p) => p.id),
                                  );
                                } else {
                                  _selectedIds.clear();
                                }
                              });
                            },
                          ),
                          const Text(
                            'تحديد الكل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_selectedIds.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _bulkEditSelected,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'تعديل جماعي',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(
                          'مسح لهم',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _printSelectedForms,
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text(
                          'طباعة الاستمارات',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedIds.clear()),
                        child: const Text(
                          'إلغاء التحديد',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                        color: _showFilters
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                      onPressed: () =>
                          setState(() => _showFilters = !_showFilters),
                      tooltip: 'تصفية النتائج',
                    ),
                    const SizedBox(width: 8),
                    _buildPrintButton(),
                    const SizedBox(width: 8),
                    _buildExcelButton(),
                    const SizedBox(width: 8),
                    SizedBox(width: 250, child: _buildSearchBox()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildExcelButton({bool isMobile = false}) {
    return ElevatedButton.icon(
      onPressed: _allPersons.isEmpty && !_isLoading
          ? null
          : () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(isAttendance: false),
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

                final repo = ref.read(personsRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات الأشخاص للإكسل...',
                );

                try {
                  progress.update('جاري تحميل كل النتائج المطابقة...');
                  final allData = await repo.fetchPersons(
                    search: _selectedIds.isNotEmpty ? null : _searchQuery,
                    limit: 5000,
                    offset: 0,
                    stageIds: _selectedIds.isNotEmpty ? null : _filterStageIds,
                    khorosIds: _selectedIds.isNotEmpty
                        ? null
                        : _filterKhorosIds,
                    areaIds: _selectedIds.isNotEmpty ? null : _filterAreaIds,
                    fatherIds: _selectedIds.isNotEmpty
                        ? null
                        : _filterFatherIds,
                    genders: _selectedIds.isNotEmpty ? null : _filterGenders,
                    birthdayDay: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayDay,
                    birthdayMonth: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayMonth,
                    birthdayYear: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayYear,
                    rohots: _selectedIds.isNotEmpty ? null : _filterRohots,
                    personIds: _selectedIds.isNotEmpty
                        ? _selectedIds.toList()
                        : null,
                    includeServices: false,
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
                        cmp = (a.areaName).compareTo(b.areaName);
                      } else if (criterion == 'stage') {
                        cmp = (a.stageName).compareTo(b.stageName);
                      } else if (criterion == 'father') {
                        cmp = (a.fatherName).compareTo(b.fatherName);
                      } else if (criterion == 'khoros') {
                        cmp = (a.khorosName).compareTo(b.khorosName);
                      } else if (criterion == 'name') {
                        cmp = (a.name).compareTo(b.name);
                      }
                      if (cmp != 0) return cmp;
                    }
                    return 0;
                  });

                  progress.update('جاري إنشاء ملف إكسل...');
                  final path = await ExcelExportService.exportPersonsList(
                    data: allData,
                    columns: cols,
                    headerData: headerData,
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
      icon: Icon(Icons.table_view_outlined, size: isMobile ? 16 : 18),
      label: Text(
        _selectedIds.isNotEmpty
            ? (isMobile ? 'تصدير المحددين' : 'تصدير المحددين للإكسل')
            : (isMobile ? 'تصدير' : 'تصدير إكسل'),
        style: TextStyle(fontSize: isMobile ? 11 : 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildPrintButton({bool isMobile = false}) {
    return ElevatedButton.icon(
      onPressed: _allPersons.isEmpty && !_isLoading
          ? null
          : () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (c) => const SortingDialog(isAttendance: false),
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

                final settingsRepo = ref.read(settingsRepositoryProvider);
                final churchLogo = await settingsRepo.getChurchLogo();
                final churchName = await settingsRepo.getSetting('church_name');

                Uint8List? khorosLogo;
                if (_filterKhorosIds.length == 1) {
                  final khorosRow =
                      await (db.select(db.khoroses)..where(
                            (t) => t.khorosId.equals(_filterKhorosIds.first),
                          ))
                          .getSingleOrNull();
                  khorosLogo = khorosRow?.logo;
                }

                final repo = ref.read(personsRepositoryProvider.notifier);
                if (!mounted) return;
                final progress = await showPrintProgressDialog(
                  context,
                  initialMessage: 'جاري تحميل بيانات الأشخاص...',
                );

                try {
                  progress.update('جاري تحميل كل النتائج المطابقة...');
                  final allData = await repo.fetchPersons(
                    search: _selectedIds.isNotEmpty ? null : _searchQuery,
                    limit: 5000,
                    offset: 0,
                    stageIds: _selectedIds.isNotEmpty ? null : _filterStageIds,
                    khorosIds: _selectedIds.isNotEmpty
                        ? null
                        : _filterKhorosIds,
                    areaIds: _selectedIds.isNotEmpty ? null : _filterAreaIds,
                    fatherIds: _selectedIds.isNotEmpty
                        ? null
                        : _filterFatherIds,
                    genders: _selectedIds.isNotEmpty ? null : _filterGenders,
                    birthdayDay: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayDay,
                    birthdayMonth: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayMonth,
                    birthdayYear: _selectedIds.isNotEmpty
                        ? null
                        : _filterBirthdayYear,
                    rohots: _selectedIds.isNotEmpty ? null : _filterRohots,
                    personIds: _selectedIds.isNotEmpty
                        ? _selectedIds.toList()
                        : null,
                    includeServices: false,
                  );
                  if (progress.isCancelled) {
                    progress.close();
                    return;
                  }

                  final task = await PersonReportService.startPDFGeneration(
                    data: allData,
                    sortingCriteria: sorting,
                    columns: cols,
                    title: 'قائمة الأشخاص والبيانات',
                    headerData: headerData,
                    churchLogo: churchLogo,
                    khorosLogo: khorosLogo,
                    churchName: churchName,
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
                    name: 'Persons_List.pdf',
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
      icon: Icon(Icons.picture_as_pdf_outlined, size: isMobile ? 16 : 18),
      label: Text(
        _selectedIds.isNotEmpty
            ? (isMobile ? 'تقرير المحددين' : 'تقرير المحددين PDF')
            : (isMobile ? 'تقرير' : 'تقرير الأشخاص'),
        style: TextStyle(fontSize: isMobile ? 11 : 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildTitleAndCount() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'قائمة الأشخاص',
          style: TextStyle(
            fontSize: isMobile ? 16 : 17,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$_totalCount',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FamilyRelationshipsView()),
          ),
          icon: Icon(
            Icons.family_restroom,
            color: Colors.green,
            size: isMobile ? 18 : 20,
          ),
          tooltip: 'صلات القرابة',
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _openFieldsSettings,
          icon: Icon(
            Icons.settings,
            color: Colors.blue,
            size: isMobile ? 18 : 20,
          ),
          tooltip: 'إعدادات الخانات',
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    final personsAsync = ref.watch(personsRepositoryProvider);
    return personsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (allData) {
        return Autocomplete<PersonOption>(
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim();
            if (query.isEmpty) return const Iterable<PersonOption>.empty();

            final lowerQ = query.toLowerCase();
            final intQ = int.tryParse(lowerQ);

            // Search in the full list for suggestions
            return allData
                .where((p) {
                  final idMatch =
                      p.id.toString() == lowerQ ||
                      (intQ != null && p.id == intQ);
                  return p.name.toLowerCase().contains(lowerQ) || idMatch;
                })
                .take(15)
                .map((p) => PersonOption(id: p.id, name: p.name));
          },
          displayStringForOption: (option) => option.name,
          onSelected: (option) {
            _searchQuery = option.id.toString();
            _loadInitialData();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            // No need to manually sync _searchQuery to controller here,
            // the Autocomplete widget handles the connection.

            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'بحث بالإسم أو الكود أو الموبايل...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) => _onSearch(val),
            );
          },
        );
      },
      loading: () => const TextField(
        decoration: InputDecoration(hintText: 'جاري التحميل...'),
      ),
      error: (e, _) => TextField(
        onSubmitted: _onSearch,
        decoration: const InputDecoration(hintText: 'بحث...'),
      ),
    );
  }

  Widget _buildMobileFilterToggle() {
    return InkWell(
      onTap: () =>
          setState(() => _mobileFiltersExpanded = !_mobileFiltersExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
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
              _mobileFiltersExpanded ? 'إخفاء التصفية' : 'إظهار التصفية',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'تصفية النتائج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterStageIds = [];
                        _filterKhorosIds = [];
                        _filterAreaIds = [];
                        _filterFatherIds = [];
                        _filterGenders = [];
                        _filterBirthdayDay = [];
                        _filterBirthdayMonth = [];
                        _filterBirthdayYear = [];
                      });
                      _loadInitialData();
                    },
                    child: const Text(
                      'تصفير',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildStageFilter(),
              const SizedBox(height: 12),
              _buildKhorosFilter(),
              const SizedBox(height: 12),
              _buildAreaFilter(),
              const SizedBox(height: 12),
              _buildFatherFilter(),
              const SizedBox(height: 12),
              _buildGenderFilter(),
              const SizedBox(height: 12),
              _buildRohotFilter(),
              const SizedBox(height: 12),
              _buildBirthdayDayFilter(),
              const SizedBox(height: 12),
              _buildBirthdayMonthFilter(),
              const SizedBox(height: 12),
              _buildBirthdayYearFilter(),
            ],
          ),
        ),
      ),
    );
  }

  String _getLabel(String key, String fallback) {
    final fields = ref.read(fieldsRepositoryProvider).value ?? [];
    final f = fields.where((f) => f.fieldKey == key).firstOrNull;
    return f?.name ?? fallback;
  }

  Widget _buildStageFilter() {
    final stages = ref.watch(stagesRepositoryProvider).value ?? [];
    return MultiSelectFilter(
      label: _getLabel('stage', 'المرحلة'),
      selectedIds: _filterStageIds,
      allItems: stages
          .map((s) => SelectableItem(id: s.id, name: s.name))
          .toList(),
      onChanged: (ids) {
        setState(() => _filterStageIds = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildKhorosFilter() {
    final khoroses = ref.watch(khorosRepositoryProvider).value ?? [];
    return MultiSelectFilter(
      label: _getLabel('khoros', 'الخورس'),
      selectedIds: _filterKhorosIds,
      allItems: khoroses
          .map((k) => SelectableItem(id: k.id, name: k.name))
          .toList(),
      onChanged: (ids) {
        setState(() => _filterKhorosIds = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildAreaFilter() {
    final areas = ref.watch(areasRepositoryProvider).value ?? [];
    return MultiSelectFilter(
      label: _getLabel('area', 'المنطقة'),
      selectedIds: _filterAreaIds,
      allItems: areas
          .map((a) => SelectableItem(id: a.id, name: a.name))
          .toList(),
      onChanged: (ids) {
        setState(() => _filterAreaIds = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildFatherFilter() {
    final fathers = ref.watch(fathersRepositoryProvider).value ?? [];
    return MultiSelectFilter(
      label: _getLabel('father', 'أب الاعتراف'),
      selectedIds: _filterFatherIds,
      allItems: fathers
          .map((f) => SelectableItem(id: f.id, name: f.name))
          .toList(),
      onChanged: (ids) {
        setState(() => _filterFatherIds = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildGenderFilter() {
    return MultiSelectFilter(
      label: _getLabel('gender', 'النوع'),
      selectedIds: _filterGenders,
      allItems: [
        SelectableItem(id: 'ذكر', name: 'ذكر'),
        SelectableItem(id: 'أنثى', name: 'أنثى'),
      ],
      onChanged: (ids) {
        setState(() => _filterGenders = List<String>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildBirthdayDayFilter() {
    return MultiSelectFilter(
      label: 'يوم (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayDay,
      allItems: List.generate(
        31,
        (i) => SelectableItem(id: i + 1, name: '${i + 1}'),
      ),
      onChanged: (ids) {
        setState(() => _filterBirthdayDay = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildBirthdayMonthFilter() {
    return MultiSelectFilter(
      label: 'شهر (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayMonth,
      allItems: List.generate(
        12,
        (i) => SelectableItem(id: i + 1, name: '${i + 1}'),
      ),
      onChanged: (ids) {
        setState(() => _filterBirthdayMonth = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildBirthdayYearFilter() {
    return MultiSelectFilter(
      label: 'سنة (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayYear,
      allItems: List.generate(80, (i) {
        final y = DateTime.now().year - i;
        return SelectableItem(id: y, name: '$y');
      }),
      onChanged: (ids) {
        setState(() => _filterBirthdayYear = List<int>.from(ids));
        _loadInitialData();
      },
    );
  }

  Widget _buildPersonsList(User? user) {
    if (_allPersons.isEmpty && !_isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أشخاص مطابقين للبحث',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final fields = ref.watch(fieldsRepositoryProvider).value ?? [];

    return ListView.builder(
      controller: _scrollController,
      itemCount: _allPersons.length + (_hasMore ? 1 : 0),
      findChildIndexCallback: (key) {
        if (key is! ValueKey<int>) return null;
        final index = _allPersons.indexWhere((p) => p.id == key.value);
        return index < 0 ? null : index;
      },
      itemBuilder: (context, index) {
        if (index == _allPersons.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      label: const Text('عرض المزيد'),
                    ),
            ),
          );
        }

        final person = _allPersons[index];
        return _buildPersonCard(person, index, user, fields);
      },
    );
  }

  Widget _buildPersonCard(
    PersonListDTO person,
    int index,
    User? user,
    List<FieldConfigDTO> fields,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);
    final cardSurface = isDark ? const Color(0xFF151E2E) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final canEdit =
        user == null ||
        !user.isAdvanced ||
        (user.granularPermissions['persons']?['edit'] ?? false);
    final canDelete =
        user == null ||
        !user.isAdvanced ||
        (user.granularPermissions['persons']?['delete'] ?? false);

    final visibleTags = fields
        .where(
          (f) =>
              f.isVisible &&
              f.type == 'native' &&
              f.fieldKey != 'name' &&
              f.fieldKey != 'street' &&
              f.fieldKey != 'mobile',
        )
        .toList();

    final isSelected = _selectedIds.contains(person.id);

    final avatarWidget = person.photo != null && person.photo!.isNotEmpty
        ? CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundImage: MemoryImage(person.photo!),
          )
        : CircleAvatar(
            backgroundColor: isDark
                ? theme.primaryColor.withValues(alpha: 0.25)
                : theme.primaryColor.withValues(alpha: 0.12),
            radius: isMobile ? 20 : 24,
            child: Icon(
              Icons.person_rounded,
              color: isDark ? const Color(0xFF93C5FD) : theme.primaryColor,
              size: isMobile ? 22 : 26,
            ),
          );

    final checkboxWidget = Checkbox(
      value: isSelected,
      visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedIds.add(person.id);
          } else {
            _selectedIds.remove(person.id);
          }
        });
      },
    );

    if (isMobile) {
      // Sleek, clean mobile card layout giving full visibility to the person's name
      return Card(
        key: ValueKey(person.id),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        elevation: isDark ? 2 : 1,
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? theme.primaryColor : cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Checkbox + Avatar + Expanded Name & ID + Clean Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  checkboxWidget,
                  const SizedBox(width: 4),
                  avatarWidget,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF93C5FD)
                                      : theme.primaryColor,
                                ),
                              ),
                            ),
                            if (person.stageName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  person.stageName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 22),
                      color: Colors.blueAccent,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'تعديل',
                      onPressed: () => _openEditDialog(person),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'خيارات إضافية',
                    onSelected: (val) {
                      if (val == 'print') {
                        _printSinglePerson(person);
                      } else if (val == 'delete' && canDelete) {
                        _deletePerson(person);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(
                              Icons.print_outlined,
                              size: 18,
                              color: Colors.deepPurpleAccent,
                            ),
                            SizedBox(width: 8),
                            Text('طباعة البيانات'),
                          ],
                        ),
                      ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'حذف المخدوم',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Compact Chips Row
              Wrap(
                spacing: 5,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (person.khorosName.isNotEmpty)
                    _buildInfoTag(
                      Icons.library_music,
                      person.khorosName,
                      Colors.orange,
                    ),
                  if (person.areaName.isNotEmpty)
                    _buildInfoTag(
                      Icons.map_outlined,
                      person.areaName,
                      Colors.teal,
                    ),
                  if (person.services != null && person.services!.isNotEmpty)
                    _buildInfoTag(
                      Icons.miscellaneous_services_rounded,
                      person.services!,
                      Colors.indigo,
                    ),
                ],
              ),
              // Mobile phone & street
              if (fields.any(
                (f) =>
                    f.isVisible &&
                    (f.fieldKey == 'mobile' || f.fieldKey == 'street'),
              )) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (fields.any(
                          (f) => f.isVisible && f.fieldKey == 'mobile',
                        ) &&
                        person.mobile.isNotEmpty) ...[
                      InkWell(
                        onTap: () async {
                          final uri = Uri(scheme: 'tel', path: person.mobile);
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
                            horizontal: 7,
                            vertical: 2.5,
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
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 11,
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : Colors.green.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                person.mobile,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.green.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (fields.any(
                          (f) => f.isVisible && f.fieldKey == 'street',
                        ) &&
                        person.streetName.isNotEmpty) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                person.streetName,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Desktop/Tablet layout
    return Card(
      key: ValueKey(person.id),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isDark ? 3 : 2,
      color: cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : cardBorder,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checkboxWidget,
            const SizedBox(width: 8),
            avatarWidget,
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildInfoTag(
                        Icons.tag,
                        '${person.id}',
                        theme.primaryColor,
                      ),
                      ...visibleTags.map((f) {
                        switch (f.fieldKey) {
                          case 'father':
                            return _buildInfoTag(
                              Icons.church,
                              person.fatherName,
                              Colors.brown,
                            );
                          case 'stage':
                            return _buildInfoTag(
                              Icons.school,
                              person.stageName,
                              Colors.blue,
                            );
                          case 'area':
                            return _buildInfoTag(
                              Icons.map,
                              person.areaName,
                              Colors.teal,
                            );
                          case 'khoros':
                            return _buildInfoTag(
                              Icons.library_music,
                              person.khorosName,
                              Colors.orange,
                            );
                          case 'rohot':
                            return _buildInfoTag(
                              Icons.groups,
                              person.rohot ?? '',
                              Colors.purple,
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      }),
                      if (person.services != null &&
                          person.services!.isNotEmpty)
                        _buildInfoTag(
                          Icons.miscellaneous_services_rounded,
                          person.services!,
                          Colors.indigo,
                        ),
                    ],
                  ),
                  if (fields.any(
                    (f) =>
                        f.isVisible &&
                        (f.fieldKey == 'mobile' || f.fieldKey == 'street'),
                  )) ...[
                    const SizedBox(height: 4),
                    if (fields.any(
                          (f) => f.isVisible && f.fieldKey == 'mobile',
                        ) &&
                        person.mobile.isNotEmpty)
                      Text(
                        '${fields.firstWhere((f) => f.fieldKey == 'mobile').name}: ${person.mobile}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    if (fields.any(
                          (f) => f.isVisible && f.fieldKey == 'street',
                        ) &&
                        person.streetName.isNotEmpty)
                      Text(
                        '${fields.firstWhere((f) => f.fieldKey == 'street').name}: ${person.streetName}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                  ],
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.print_outlined,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () => _printSinglePerson(person),
                  tooltip: 'طباعة بيانات الشخص',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (canEdit || canDelete) const SizedBox(height: 8),
                if (canEdit)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.blue,
                    ),
                    onPressed: () => _openEditDialog(person),
                    tooltip: 'تعديل',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (canEdit && canDelete) const SizedBox(height: 8),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePerson(person),
                    tooltip: 'حذف',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRohotFilter() {
    return FutureBuilder<String?>(
      future: ref
          .read(settingsRepositoryProvider)
          .getSetting('rohot_groups_json'),
      builder: (context, snap) {
        final raw = snap.data;
        List<String> rohotNames = [];
        if (raw != null && raw.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              rohotNames = decoded
                  .whereType<Map>()
                  .map((item) => (item['name'] as String? ?? '').trim())
                  .where((name) => name.isNotEmpty)
                  .toList();
            }
          } catch (_) {}
        }

        return MultiSelectFilter(
          label: _getLabel('rohot', 'الرهط'),
          selectedIds: _filterRohots,
          allItems: rohotNames
              .map((name) => SelectableItem(id: name, name: name))
              .toList(),
          onChanged: (ids) {
            setState(() => _filterRohots = List<String>.from(ids));
            _loadInitialData();
          },
        );
      },
    );
  }

  Widget _buildInfoTag(IconData icon, String label, Color color) {
    if (label.isEmpty) return const SizedBox.shrink();
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
}
