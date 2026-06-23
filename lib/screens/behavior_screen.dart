import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../repositories/attendance_repository.dart';
import '../repositories/persons_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/stages_repository.dart';
import '../ui/widgets/multi_select_filter.dart';

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
  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchQuery = '';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearch();
    });
  }

  void _onSearch() async {
    setState(() {
      _isLoading = true;
      _personsList = [];
      _scores = {};
      _searchQuery = '';
    });

    try {
      final personsRepo = ref.read(personsRepositoryProvider.notifier);
      final persons = await personsRepo.fetchPersons(
        stageIds: _selectedStageId != null ? [_selectedStageId!] : null,
      );

      final attRepo = ref.read(attendanceRepositoryProvider.notifier);
      final existingScores = await attRepo.fetchBehaviorScores(
        dateWeek: DateFormat('yyyy-MM-dd').format(_selectedDate),
        serviceIds: _selectedServiceIds,
      );

      final Map<int, int> initialScores = {};
      for (final p in persons) {
        initialScores[p.id] = existingScores[p.id] ?? 5;
      }

      setState(() {
        _personsList = persons;
        _scores = initialScores;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
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

    setState(() => _isLoading = true);

    try {
      final attRepo = ref.read(attendanceRepositoryProvider.notifier);
      final ok = await attRepo.saveBehaviorScores(
        scores: _scores,
        dateWeek: DateFormat('yyyy-MM-dd').format(_selectedDate),
        month: _selectedDate.month,
        year: _selectedDate.year,
        serviceIds: _selectedServiceIds,
      );

      if (mounted) {
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
      setState(() => _isLoading = false);
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
        _hasSearched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final stagesAsync = ref.watch(stagesRepositoryProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilterCard(servicesAsync, stagesAsync, isWide),
              const SizedBox(height: 16),
              Expanded(child: _buildResultsSection()),
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
          'تقييم السلوك',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          'تقييم سلوك المخدومين (من 0 إلى 7) في تاريخ وخدمة أو أكثر (الافتراضي 5)',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterCard(
    AsyncValue<List<ServiceDTO>> servicesAsync,
    AsyncValue<List<StageModel>> stagesAsync,
    bool isWide,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final List<Widget> filters = [
      // Date Picker Button
      InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'التاريخ',
            prefixIcon: Icon(Icons.calendar_today_outlined),
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
            value: _selectedStageId,
            decoration: const InputDecoration(
              labelText: 'المرحلة',
              prefixIcon: Icon(Icons.school_outlined),
            ),
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
              _hasSearched = false;
            }),
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    ];

    return Card(
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

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }

    if (!_hasSearched) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thumbs_up_down_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'الرجاء اختيار الفلاتر والضغط على بحث لعرض المخدومين وتقييمهم',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_personsList.isEmpty) {
      return const Card(
        child: Center(
          child: Text(
            'لا يوجد مخدومين مسجلين حالياً',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final filtered = _filteredPersons;

    return Card(
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          }
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة الافتراضي (5) للكل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade800),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const Divider(height: 24),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final currentScore = _scores[p.id] ?? 5;
                        return _buildPersonRow(p, currentScore);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonRow(PersonListDTO p, int score) {
    Color getScoreColor(int val) {
      if (val <= 2) return Colors.red;
      if (val <= 4) return Colors.orange;
      if (val == 5) return Colors.blue;
      return Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              p.name.isNotEmpty ? p.name.substring(0, 1) : '',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كود: ${p.id}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          // Interactive score indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: getScoreColor(score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: getScoreColor(score).withOpacity(0.3)),
            ),
            child: Text(
              'السلوك: $score',
              style: TextStyle(
                color: getScoreColor(score),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Rating Selector (0 to 7) buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(8, (i) {
              final isSelected = score == i;
              final color = getScoreColor(i);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _scores[p.id] = i;
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
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
