import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../repositories/period_comparison_repository.dart';

class PeriodComparisonScreen extends ConsumerStatefulWidget {
  const PeriodComparisonScreen({super.key});

  @override
  ConsumerState<PeriodComparisonScreen> createState() =>
      _PeriodComparisonScreenState();
}

class _PeriodComparisonScreenState
    extends ConsumerState<PeriodComparisonScreen> {
  // ── Periods ──
  final List<_PeriodEntry> _periods = [
    _PeriodEntry(),
    _PeriodEntry(),
  ];

  // ── Person selection ──
  List<Person> _allPersons = [];
  List<Person> _filteredPersons = [];
  final Set<int> _selectedPersonIds = {};
  bool _selectAll = false;

  // ── Filters ──
  int? _filterStageId;
  int? _filterAreaId;
  String? _filterGender;
  String _searchQuery = '';

  // ── Results ──
  List<PersonComparisonResult> _results = [];
  bool _isComparing = false;
  bool _hasCompared = false;
  bool _isAggregate = false; // New: Toggle between Individual and Aggregate

  // Period colors - Premium Palette
  static const _periodColors = [
    Color(0xFF1A237E), // Deep Blue (Primary)
    Color(0xFFC5A059), // Gold/Brass (Secondary)
    Color(0xFF26A69A), // Teal
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF78909C), // Blue Grey
    Color(0xFF8D6E63), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final db = ref.read(appDatabaseProvider);
    final persons = await db.select(db.persons).get();
    setState(() {
      _allPersons = persons;
      _applyPersonFilter();
    });
  }

  void _applyPersonFilter() {
    _filteredPersons = _allPersons.where((p) {
      if (_filterStageId != null && p.stageId != _filterStageId) return false;
      if (_filterAreaId != null && p.areaId != _filterAreaId) return false;
      if (_filterGender != null && p.jenderName != _filterGender) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!(p.personName ?? '').contains(q) &&
            !p.personId.toString().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedPersonIds
            .addAll(_filteredPersons.map((p) => p.personId));
      } else {
        _selectedPersonIds.clear();
      }
    });
  }

  void _addPeriod() {
    setState(() => _periods.add(_PeriodEntry()));
  }

  void _removePeriod(int index) {
    if (_periods.length <= 2) return;
    setState(() => _periods.removeAt(index));
  }

  Future<void> _runComparison() async {
    // Validate
    for (int i = 0; i < _periods.length; i++) {
      if (_periods[i].from == null || _periods[i].to == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى تحديد تاريخ البداية والنهاية للفترة ${i + 1}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    if (_selectedPersonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار شخص واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isComparing = true);

    final periods = _periods.asMap().entries.map((e) {
      return ComparePeriod(
        from: e.value.from!,
        to: e.value.to!,
        label: 'فترة ${e.key + 1}',
      );
    }).toList();

    final repo = ref.read(periodComparisonRepositoryProvider.notifier);
    final results = await repo.compareAttendance(
      periods: periods,
      personIds: _selectedPersonIds.toList(),
      isAggregate: _isAggregate,
    );

    setState(() {
      _results = results;
      _isComparing = false;
      _hasCompared = true;
    });
  }

  // ════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مقارنة فترات الحضور'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              tooltip: 'فلترة الأشخاص',
              onPressed: () => _showFilterSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Top Header Card (Periods + Toggle) ──
            _buildControlHeader(isMobile, theme),

            // ── Selected persons summary + compare button ──
            _buildActionBar(theme),

            // ── Results ──
            Expanded(
              child: Container(
                color: theme.colorScheme.background.withOpacity(0.5),
                child: _buildResultsSection(isMobile, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════  PERIODS  ══════════════════════════
  Widget _buildControlHeader(bool isMobile, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPeriodsSection(isMobile, theme),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildAggregateToggle(theme),
        ],
      ),
    );
  }

  Widget _buildPeriodsSection(bool isMobile, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.date_range, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text('تحديد فترات المقارنة',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.primaryColor)),
              const Spacer(),
              _ModernTextButton(
                onPressed: _addPeriod,
                icon: Icons.add_circle,
                label: 'إضافة فترة',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _buildPeriodCard(i, isMobile, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregateToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          const Text('نظام المقارنة:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          _ToggleOption(
            label: 'فردية',
            isSelected: !_isAggregate,
            onTap: () => setState(() => _isAggregate = false),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _ToggleOption(
            label: 'مجمعة',
            isSelected: _isAggregate,
            onTap: () => setState(() => _isAggregate = true),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(int index, bool isMobile, ThemeData theme) {
    final p = _periods[index];
    final color = _periodColors[index % _periodColors.length];

    return Container(
      width: isMobile ? 280 : 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          // Period Label
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('فترة', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Date Pickers
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DateSelector(
                  label: 'من',
                  date: p.from,
                  color: color,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: p.from ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => p.from = picked);
                  },
                ),
                const SizedBox(height: 6),
                _DateSelector(
                  label: 'إلى',
                  date: p.to,
                  color: color,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: p.to ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => p.to = picked);
                  },
                ),
              ],
            ),
          ),
          if (_periods.length > 2)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
              onPressed: () => _removePeriod(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _miniDateBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }

  // ════════════════════════  ACTION BAR  ═══════════════════════════════
  Widget _buildActionBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          // Person selector summary
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedPersonIds.length} شخص مختار',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Compare button - Premium
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: _isComparing ? null : _runComparison,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                shadowColor: theme.colorScheme.secondary.withOpacity(0.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (_isComparing)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else
                    const Icon(Icons.auto_graph, size: 20),
                  const SizedBox(width: 10),
                  const Text('مقارنة الآن', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════  FILTER SHEET  ═════════════════════════════
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        allPersons: _allPersons,
        selectedIds: _selectedPersonIds,
        initialStageId: _filterStageId,
        initialAreaId: _filterAreaId,
        initialGender: _filterGender,
        initialSearch: _searchQuery,
        db: ref.read(appDatabaseProvider),
        onApply: (selectedIds, stageId, areaId, gender, search) {
          setState(() {
            _selectedPersonIds
              ..clear()
              ..addAll(selectedIds);
            _filterStageId = stageId;
            _filterAreaId = areaId;
            _filterGender = gender;
            _searchQuery = search;
            _applyPersonFilter();
            _selectAll =
                _filteredPersons.every((p) => _selectedPersonIds.contains(p.personId));
          });
        },
      ),
    );
  }

  // ════════════════════════  RESULTS  ══════════════════════════════════
  Widget _buildResultsSection(bool isMobile, ThemeData theme) {
    if (_isComparing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasCompared) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows,
                size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('اختر الفترات والأشخاص ثم اضغط "مقارنة"',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _results.length,
      itemBuilder: (context, i) =>
          _buildPersonCard(_results[i], isMobile, theme),
    );
  }

  Widget _buildPersonCard(
      PersonComparisonResult person, bool isMobile, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.primaryColor.withOpacity(0.12),
                  child: Text('${person.personId}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(person.personName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),

          // Attendance story
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: _buildAttendanceSection(
              theme: theme,
              periodResults: person.periodResults,
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection({
    required ThemeData theme,
    required List<PeriodAttendanceResult> periodResults,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('تحليل الحضور الاستراتيجي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: periodResults.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final pColor = _periodColors[i % _periodColors.length];
                final pct = r.attendancePercent;
                final change = r.attendanceChange;
                final dir = r.attendanceDirection;

                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: pColor.withOpacity(0.12), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: pColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r.periodLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Text('${r.attendedCount} من ${r.totalPossibleAttendances}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: pColor)),
                      const SizedBox(height: 8),
                      // Premium Progress Line
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [pColor, pColor.withOpacity(0.6)]),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: pColor.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (change != null && dir != null)
                        _buildChangeIndicator(change, dir, pColor)
                      else
                        const SizedBox(height: 24),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(double change, String direction, Color pColor) {
    final isUp = direction == 'increase';
    final isSame = direction == 'same';
    final color = isSame ? Colors.grey : (isUp ? Colors.green : Colors.orange);
    final icon = isSame ? Icons.horizontal_rule : (isUp ? Icons.trending_up : Icons.trending_down);
    final text = isSame ? 'ثابت' : (isUp ? 'تحسن بمقدار' : 'تراجع بمقدار');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text('${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Custom Widgets for Premium UI ──

class _ModernTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _ModernTextButton({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ToggleOption({required this.label, required this.isSelected, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color color;
  final VoidCallback onTap;

  const _DateSelector({required this.label, this.date, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                date != null ? DateFormat('yyyy-MM-dd').format(date!) : 'اختر التاريخ',
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(Icons.calendar_today, size: 14, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
//  HELPER: period entry
// ════════════════════════════════════════════════════════════════════════
class _PeriodEntry {
  DateTime? from;
  DateTime? to;
}

// ════════════════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET (Stateful!)
// ════════════════════════════════════════════════════════════════════════
class _FilterSheet extends StatefulWidget {
  final List<Person> allPersons;
  final Set<int> selectedIds;
  final int? initialStageId;
  final int? initialAreaId;
  final String? initialGender;
  final String initialSearch;
  final AppDatabase db;
  final void Function(
          Set<int> selectedIds, int? stageId, int? areaId, String? gender, String search)
      onApply;

  const _FilterSheet({
    required this.allPersons,
    required this.selectedIds,
    this.initialStageId,
    this.initialAreaId,
    this.initialGender,
    this.initialSearch = '',
    required this.db,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<int> _selected;
  int? _stageId;
  int? _areaId;
  String? _gender;
  late TextEditingController _searchCtrl;
  List<Person> _filtered = [];

  List<Area> _areas = [];
  List<Stage> _stages = [];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
    _stageId = widget.initialStageId;
    _areaId = widget.initialAreaId;
    _gender = widget.initialGender;
    _searchCtrl = TextEditingController(text: widget.initialSearch);
    _loadLookups();
    _applyFilter();
  }

  Future<void> _loadLookups() async {
    final areas = await widget.db.select(widget.db.areas).get();
    final stages = await widget.db.select(widget.db.stages).get();
    setState(() {
      _areas = areas;
      _stages = stages;
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim();
    _filtered = widget.allPersons.where((p) {
      if (_stageId != null && p.stageId != _stageId) return false;
      if (_areaId != null && p.areaId != _areaId) return false;
      if (_gender != null && p.jenderName != _gender) return false;
      if (q.isNotEmpty) {
        if (!(p.personName ?? '').contains(q) &&
            !p.personId.toString().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
    setState(() {});
  }

  bool get _allSelected =>
      _filtered.isNotEmpty &&
      _filtered.every((p) => _selected.contains(p.personId));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height * 0.85;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('اختيار الأشخاص',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.primaryColor)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onApply(
                          _selected, _stageId, _areaId, _gender, _searchCtrl.text.trim());
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filters row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Stage dropdown
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int?>(
                      value: _stageId,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'المرحلة',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('الكل')),
                        ..._stages.map((s) => DropdownMenuItem(
                            value: s.stageId,
                            child: Text(s.stageName ?? '',
                                style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (v) {
                        _stageId = v;
                        _applyFilter();
                      },
                    ),
                  ),
                  // Area dropdown
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int?>(
                      value: _areaId,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'المنطقة',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('الكل')),
                        ..._areas.map((a) => DropdownMenuItem(
                            value: a.areaId,
                            child: Text(a.areaName ?? '',
                                style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (v) {
                        _areaId = v;
                        _applyFilter();
                      },
                    ),
                  ),
                  // Gender dropdown
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String?>(
                      value: _gender,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'النوع',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('الكل')),
                        DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                        DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                      ],
                      onChanged: (v) {
                        _gender = v;
                        _applyFilter();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => _applyFilter(),
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم أو الكود...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),

            // Select all row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: _allSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected
                              .addAll(_filtered.map((p) => p.personId));
                        } else {
                          for (final p in _filtered) {
                            _selected.remove(p.personId);
                          }
                        }
                      });
                    },
                  ),
                  Text('اختيار الكل (${_filtered.length})',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('${_selected.length} محدد',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const Divider(height: 1),

            // Person list
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final p = _filtered[i];
                  final isChecked = _selected.contains(p.personId);
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(p.personId);
                          } else {
                            _selected.remove(p.personId);
                          }
                        });
                      },
                    ),
                    title: Text(p.personName ?? 'مجهول',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text('كود: ${p.personId}',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _selected.remove(p.personId);
                        } else {
                          _selected.add(p.personId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
