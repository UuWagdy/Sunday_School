import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../repositories/attendance_repository.dart';
import '../repositories/persons_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/stages_repository.dart';
import '../ui/widgets/multi_select_filter.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';
import '../utils/silent_refresh_controller.dart';

class BehaviorScreen extends ConsumerStatefulWidget {
  const BehaviorScreen({super.key});

  @override
  ConsumerState<BehaviorScreen> createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends ConsumerState<BehaviorScreen> {
  DateTime _selectedDate = DateTime.now();
  List<int> _selectedServiceIds = [];
  int? _selectedStageId;

  List<PersonListDTO> _personsList = [];
  Map<int, int> _scores = {};
  Map<int, int> _baselineScores = {};
  bool _hasRemoteScoreConflict = false;
  final Set<int> _dirtyPersonIds = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchQuery = '';
  bool _mobileFiltersExpanded = false;
  late final SilentRefreshController _refreshController;

  List<PersonListDTO> get _filteredPersons {
    if (_searchQuery.trim().isEmpty) return _personsList;
    final query = _searchQuery.trim().toLowerCase();
    return _personsList.where((p) {
      final idMatch = p.id.toString() == query;
      final nameMatch = p.name.toLowerCase().contains(query);
      return idMatch || nameMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _refreshController = SilentRefreshController(
      onRefresh: () async {
        if (!mounted) return;
        await _silentRefresh();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearch();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!_hasSearched) return;
    final gen = _refreshController.currentGeneration;
    try {
      final date = _selectedDate;
      final services = List<int>.of(_selectedServiceIds);
      final personsRepo = ref.read(personsRepositoryProvider.notifier);
      final persons = await personsRepo.fetchPersons(
        stageIds: _selectedStageId != null ? [_selectedStageId!] : null,
      );

      final attRepo = ref.read(attendanceRepositoryProvider.notifier);
      final existingScores = await attRepo.fetchBehaviorScores(
        dateWeek: DateFormat('yyyy-MM-dd').format(date),
        serviceIds: services,
      );

      if (!mounted || _refreshController.currentGeneration != gen) return;

      final Map<int, int> updatedScores = {};
      var conflict = false;
      for (final p in persons) {
        if (!_dirtyPersonIds.contains(p.id)) {
          updatedScores[p.id] = existingScores[p.id] ?? 5;
        } else {
          updatedScores[p.id] = _scores[p.id] ?? 5;
          if ((existingScores[p.id] ?? 5) != (_baselineScores[p.id] ?? 5)) {
            conflict = true;
          }
        }
      }

      setState(() {
        _personsList = persons;
        _scores = updatedScores;
        _hasRemoteScoreConflict = conflict;
        _dirtyPersonIds.retainAll(persons.map((p) => p.id));
        for (final p in persons) {
          if (!_dirtyPersonIds.contains(p.id)) {
            _baselineScores[p.id] = existingScores[p.id] ?? 5;
          }
        }
      });
    } catch (e) {
      debugPrint('Silent refresh error in behavior: $e');
      rethrow;
    }
  }

  void _onSearch() async {
    _refreshController.bumpGeneration();
    final generation = _refreshController.currentGeneration;
    setState(() {
      _isLoading = true;
      _personsList = [];
      _scores = {};
      _dirtyPersonIds.clear();
      _searchQuery = '';
      _mobileFiltersExpanded = false;
    });

    try {
      final date = _selectedDate;
      final services = List<int>.of(_selectedServiceIds);
      final personsRepo = ref.read(personsRepositoryProvider.notifier);
      final persons = await personsRepo.fetchPersons(
        stageIds: _selectedStageId != null ? [_selectedStageId!] : null,
      );

      final attRepo = ref.read(attendanceRepositoryProvider.notifier);
      final existingScores = await attRepo.fetchBehaviorScores(
        dateWeek: DateFormat('yyyy-MM-dd').format(date),
        serviceIds: services,
      );

      if (!mounted || generation != _refreshController.currentGeneration) {
        return;
      }
      final Map<int, int> initialScores = {};
      for (final p in persons) {
        initialScores[p.id] = existingScores[p.id] ?? 5;
      }

      setState(() {
        _personsList = persons;
        _scores = initialScores;
        _baselineScores = Map.of(initialScores);
        _hasRemoteScoreConflict = false;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted || generation != _refreshController.currentGeneration) {
        return;
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    }
  }

  void _save() async {
    if (_scores.isEmpty) return;
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر خدمة واحدة على الأقل قبل حفظ السلوك'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final generation = _refreshController.currentGeneration;
    final submitted = Map<int, int>.of(_scores);
    final date = _selectedDate;
    final services = List<int>.of(_selectedServiceIds);
    setState(() => _isLoading = true);

    try {
      final attRepo = ref.read(attendanceRepositoryProvider.notifier);
      final ok = await attRepo.saveBehaviorScores(
        scores: submitted,
        dateWeek: DateFormat('yyyy-MM-dd').format(date),
        month: date.month,
        year: date.year,
        serviceIds: services,
      );

      if (mounted) {
        if (ok && generation == _refreshController.currentGeneration) {
          _dirtyPersonIds.removeWhere((id) => _scores[id] == submitted[id]);
          _baselineScores = submitted;
          _hasRemoteScoreConflict = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'تم حفظ درجات السلوك بنجاح!' : 'فشل في حفظ درجات السلوك',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e')));
      }
    } finally {
      if (mounted && generation == _refreshController.currentGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _refreshController.bumpGeneration();
        _hasSearched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(sourceEpochProvider, (previous, next) {
      _refreshController.updateEpoch(next);
      setState(() {
        _personsList = [];
        _scores = {};
        _dirtyPersonIds.clear();
      });

      _refreshController.requestRefresh(immediate: true);
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.attendance), (
      prev,
      next,
    ) {
      if (prev != null && next > prev) {
        _refreshController.requestRefresh();
      }
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.people), (prev, next) {
      if (prev != null && next > prev) {
        _refreshController.requestRefresh();
      }
    });

    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final stagesAsync = ref.watch(stagesRepositoryProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: (!isWide && _dirtyPersonIds.isNotEmpty)
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save),
                label: Text('حفظ السلوك (${_dirtyPersonIds.length})'),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              )
            : null,
        body: isWide
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFilterCard(servicesAsync, stagesAsync, true),
                    const SizedBox(height: 16),
                    if (_hasRemoteScoreConflict) ...[
                      _buildConflictBanner(),
                      const SizedBox(height: 8),
                    ],
                    Expanded(child: _buildDesktopResultsSection()),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(12.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 12),
                        _buildMobileFilterToggle(servicesAsync, stagesAsync),
                        if (_mobileFiltersExpanded) ...[
                          const SizedBox(height: 12),
                          _buildFilterCard(servicesAsync, stagesAsync, false),
                        ],
                        if (_hasRemoteScoreConflict) ...[
                          const SizedBox(height: 12),
                          _buildConflictBanner(),
                        ],
                        const SizedBox(height: 12),
                        _buildMobileActionsAndSearch(),
                        const SizedBox(height: 8),
                      ]),
                    ),
                  ),
                  _buildMobileResultsSliver(),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تقييم السلوك',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'تقييم سلوك المخدومين (من 0 إلى 7) في تاريخ وخدمة أو أكثر (الافتراضي 5)',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildConflictBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تغيرت درجات على جهاز آخر. تم الاحتفاظ بتعديلاتك؛ راجعها قبل الحفظ.',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterToggle(
    AsyncValue<List<ServiceDTO>> servicesAsync,
    AsyncValue<List<StageModel>> stagesAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('yyyy/MM/dd').format(_selectedDate);

    String stageText = 'كل المراحل';
    stagesAsync.whenData((stages) {
      if (_selectedStageId != null) {
        final match = stages.where((s) => s.id == _selectedStageId).firstOrNull;
        if (match != null) stageText = match.name;
      }
    });

    String serviceText = _selectedServiceIds.isEmpty
        ? 'كل الخدمات'
        : '${_selectedServiceIds.length} خدمة';

    return InkWell(
      onTap: () => setState(() => _mobileFiltersExpanded = !_mobileFiltersExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.tune, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$dateStr • $serviceText • $stageText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _mobileFiltersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    AsyncValue<List<ServiceDTO>> servicesAsync,
    AsyncValue<List<StageModel>> stagesAsync,
    bool isWide,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> filters = [
      // Date Picker Button
      InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'التاريخ',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : null,
          ),
          child: Text(dateStr, style: const TextStyle(fontSize: 14)),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      // Service Dropdown
      servicesAsync.when(
        data: (list) {
          return MultiSelectFilter(
            label: 'الخدمات',
            selectedIds: _selectedServiceIds,
            allItems: list
                .map(
                  (service) =>
                      SelectableItem(id: service.id, name: service.name),
                )
                .toList(),
            hintText: 'اختر خدمة أو أكثر',
            onChanged: (ids) => setState(() {
              _selectedServiceIds = ids.cast<int>();
              _refreshController.bumpGeneration();
              _hasSearched = false;
            }),
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      const SizedBox(width: 12, height: 12),
      // Stage Dropdown
      stagesAsync.when(
        data: (list) {
          return DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: _selectedStageId,
            decoration: InputDecoration(
              labelText: 'المرحلة',
              prefixIcon: const Icon(Icons.school_outlined),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : null,
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('الكل (بدون مرحلة)'),
              ),
              ...list.map(
                (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
              ),
            ],
            onChanged: (val) => setState(() {
              _selectedStageId = val;
              _refreshController.bumpGeneration();
              _hasSearched = false;
            }),
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    ];

    return Card(
      color: isDark ? const Color(0xFF151E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                children: [
                  ...filters.map((w) => w is SizedBox ? w : Expanded(child: w)),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('بحث / عرض'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...filters,
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('بحث / عرض'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileActionsAndSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredPersons;

    return Card(
      color: isDark ? const Color(0xFF151E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  _searchQuery.trim().isNotEmpty
                      ? 'عدد المخدومين: ${filtered.length} (من ${_personsList.length})'
                      : 'عدد المخدومين: ${_personsList.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? const Color(0xFFF8FAFC) : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_dirtyPersonIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${_dirtyPersonIds.length} تم تعديلهم',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _personsList.isEmpty ? null : () {
                      setState(() {
                        for (final p in _personsList) {
                          _scores[p.id] = 5;
                          _dirtyPersonIds.add(p.id);
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('الافتراضي (5)', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_personsList.isEmpty || _isLoading) ? null : _save,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('حفظ السلوك', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الكود...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileResultsSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_hasSearched) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.thumbs_up_down_outlined,
                  size: 56,
                  color: isDark ? const Color(0xFF475569) : Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'الرجاء اختيار الفلاتر والضغط على بحث لعرض المخدومين',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_personsList.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'لا يوجد مخدومين مسجلين حالياً',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    final filtered = _filteredPersons;

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'لا توجد نتائج مطابقة للبحث',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = filtered[index];
            final currentScore = _scores[p.id] ?? 5;
            return _buildPersonRow(p, currentScore, false);
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildDesktopResultsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Card(
        color: isDark ? const Color(0xFF151E2E) : Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasSearched) {
      return Card(
        color: isDark ? const Color(0xFF151E2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thumbs_up_down_outlined,
                size: 64,
                color: isDark ? const Color(0xFF475569) : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'الرجاء اختيار الفلاتر والضغط على بحث لعرض المخدومين وتقييمهم',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_personsList.isEmpty) {
      return Card(
        color: isDark ? const Color(0xFF151E2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            'لا يوجد مخدومين مسجلين حالياً',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
            ),
          ),
        ),
      );
    }

    final filtered = _filteredPersons;

    return Card(
      color: isDark ? const Color(0xFF151E2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  _searchQuery.trim().isNotEmpty
                      ? 'عدد المخدومين: ${filtered.length} (من ${_personsList.length})'
                      : 'عدد المخدومين: ${_personsList.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : Colors.black87,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          for (final p in _personsList) {
                            _scores[p.id] = 5;
                            _dirtyPersonIds.add(p.id);
                          }
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة الافتراضي (5) للكل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade700),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ السلوك للجميع'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الكود في القائمة الحالية...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const Divider(height: 24),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final currentScore = _scores[p.id] ?? 5;
                        return _buildPersonRow(p, currentScore, true);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonRow(PersonListDTO p, int score, bool isWide) {
    Color getScoreColor(int val) {
      if (val <= 2) return Colors.red;
      if (val <= 4) return Colors.orange;
      if (val == 5) return Colors.blue;
      return Colors.green;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = getScoreColor(score);

    if (!isWide) {
      // Mobile-optimized card layout
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    p.name.isNotEmpty ? p.name.substring(0, 1) : '',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF93C5FD) : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? const Color(0xFFF8FAFC) : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'كود: ${p.id}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: isDark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: isDark ? 0.5 : 0.3),
                    ),
                  ),
                  child: Text(
                    'السلوك: $score',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (i) {
                final isSelected = score == i;
                final color = getScoreColor(i);
                return InkWell(
                  onTap: () {
                    setState(() {
                      _scores[p.id] = i;
                      _dirtyPersonIds.add(p.id);
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                        width: isSelected ? 2 : 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    // Desktop row layout
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              p.name.isNotEmpty ? p.name.substring(0, 1) : '',
              style: TextStyle(
                color: isDark ? const Color(0xFF93C5FD) : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? const Color(0xFFF8FAFC) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كود: ${p.id}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: isDark ? 0.22 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scoreColor.withValues(alpha: isDark ? 0.5 : 0.3),
              ),
            ),
            child: Text(
              'السلوك: $score',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(8, (i) {
              final isSelected = score == i;
              final color = getScoreColor(i);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _scores[p.id] = i;
                      _dirtyPersonIds.add(p.id);
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
