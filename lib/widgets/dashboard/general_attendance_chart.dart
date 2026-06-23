import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../repositories/dashboard_repository.dart';
import '../../utils/storyteller.dart';
import '../../database/database_provider.dart';
import '../../screens/period_comparison_screen.dart';
import '../../repositories/services_repository.dart';
import 'package:drift/drift.dart' as drift;

final totalPersonsProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final countExp = db.persons.personId.count();
  final query = db.selectOnly(db.persons)..addColumns([countExp]);
  final result = await query.getSingle();
  return result.read(countExp) ?? 0;
});

class GeneralAttendanceWidget extends ConsumerStatefulWidget {
  const GeneralAttendanceWidget({super.key});

  @override
  ConsumerState<GeneralAttendanceWidget> createState() => _GeneralAttendanceWidgetState();
}

class _GeneralAttendanceWidgetState extends ConsumerState<GeneralAttendanceWidget> {
  String _groupBy = 'month'; // 'day', 'month', 'year'
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedServiceId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(generalAttendanceTrendProvider(
      groupBy: _groupBy,
      filterYear: _groupBy == 'month' || _groupBy == 'day' ? _selectedYear : null,
      filterMonth: _groupBy == 'day' ? _selectedMonth : null,
      serviceId: _selectedServiceId,
      status: _selectedStatus,
    ));
    final totalAsync = ref.watch(totalPersonsProvider);

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Builder(builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'الحضور العام',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PeriodComparisonScreen()),
                            );
                          },
                          icon: const Icon(Icons.auto_graph_outlined, size: 16),
                          label: const Text('مقارنة فترات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (_groupBy == 'month' || _groupBy == 'day')
                          _buildBetterDropdown<int?>(
                            value: _selectedYear,
                            hint: 'السنة',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل السنوات')),
                              ...List.generate(10, (i) {
                                int y = DateTime.now().year - i;
                                return DropdownMenuItem(value: y, child: Text(y.toString()));
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedYear = val),
                          ),
                        if (_groupBy == 'day')
                          _buildBetterDropdown<int?>(
                            value: _selectedMonth,
                            hint: 'الشهر',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل الشهور')),
                              ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('شهر ${i + 1}'))),
                            ],
                            onChanged: (val) => setState(() => _selectedMonth = val),
                          ),
                        _buildBetterDropdown<int?>(
                          value: _selectedServiceId,
                          hint: 'الخدمة',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل الخدمات')),
                            ...ref.watch(servicesRepositoryProvider).maybeWhen(
                              data: (services) => services.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              )).toList(),
                              orElse: () => [],
                            ),
                          ],
                          onChanged: (val) => setState(() => _selectedServiceId = val),
                        ),
                        _buildBetterDropdown<String>(
                          value: _groupBy,
                          items: const [
                            DropdownMenuItem(value: 'day', child: Text('باليوم')),
                            DropdownMenuItem(value: 'month', child: Text('بالشهر')),
                            DropdownMenuItem(value: 'year', child: Text('بالسنة')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _groupBy = val);
                          },
                        ),
                        _buildBetterDropdown<String?>(
                          value: _selectedStatus,
                          hint: 'الحالة',
                          items: const [
                            DropdownMenuItem(value: null, child: Text('الكل')),
                            DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
                            DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
                            DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'الحضور العام', 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -1,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PeriodComparisonScreen()),
                          );
                        },
                        icon: const Icon(Icons.auto_graph_outlined, size: 18),
                        label: const Text('مقارنة فترات الحضور', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_groupBy == 'month' || _groupBy == 'day')
                        _buildBetterDropdown<int?>(
                          value: _selectedYear,
                          hint: 'السنة',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل السنوات')),
                            ...List.generate(10, (i) {
                              int y = DateTime.now().year - i;
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }),
                          ],
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                      if (_groupBy == 'day')
                        _buildBetterDropdown<int?>(
                          value: _selectedMonth,
                          hint: 'الشهر',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل الشهور')),
                            ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('شهر ${i + 1}'))),
                          ],
                          onChanged: (val) => setState(() => _selectedMonth = val),
                        ),
                      _buildBetterDropdown<int?>(
                        value: _selectedServiceId,
                        hint: 'الخدمة',
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كل الخدمات')),
                          ...ref.watch(servicesRepositoryProvider).maybeWhen(
                            data: (services) => services.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            )).toList(),
                            orElse: () => [],
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedServiceId = val),
                      ),
                      _buildBetterDropdown<String>(
                        value: _groupBy,
                        items: const [
                          DropdownMenuItem(value: 'day', child: Text('باليوم')),
                          DropdownMenuItem(value: 'month', child: Text('بالشهر')),
                          DropdownMenuItem(value: 'year', child: Text('بالسنة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _groupBy = val);
                        },
                      ),
                      _buildBetterDropdown<String?>(
                        value: _selectedStatus,
                        hint: 'الحالة',
                        items: const [
                          DropdownMenuItem(value: null, child: Text('الكل')),
                          DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
                          DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
                          DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(Colors.grey.shade400, "إجمالي الأشخاص"),
                    const SizedBox(width: 24),
                    _buildLegendItem(Colors.green.shade600, "الحاضرين"),
                    const SizedBox(width: 24),
                    _buildLegendItem(Colors.red.shade400, "الغائبين"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            trendAsync.when(
              data: (data) {
                return totalAsync.when(
                  data: (total) {
                     if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('لا توجد بيانات')));
                     return Column(
                       children: [
                         SizedBox(
                           height: 320,
                           child: _buildChart(data, total),
                         ),
                         const SizedBox(height: 32),
                         Container(
                           padding: const EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             color: Theme.of(context).primaryColor.withOpacity(0.08),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.15)),
                             boxShadow: [
                               BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                             ],
                           ),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: Theme.of(context).primaryColor,
                                   shape: BoxShape.circle,
                                 ),
                                 child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Text(
                                   Storyteller.analyzeGeneralTrend(data, _groupBy),
                                   style: TextStyle(
                                     fontWeight: FontWeight.w700, 
                                     height: 1.6, 
                                     fontSize: 15,
                                     color: Colors.blueGrey.shade900,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                     );
                  },
                  loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                  error: (e, st) => Center(child: Text('خطأ: $e')),
                );
              },
              loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              error: (e, st) => Center(child: Text('خطأ: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetterDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 13)) : null,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14, 
          height: 14, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade800)),
      ],
    );
  }

  Widget _buildChart(List<AttendanceTrendData> data, int totalPersons) {
    final displayData = data.length > 20 ? data.sublist(data.length - 20) : data;
    
    double maxY = totalPersons.toDouble();
    if (maxY < 10) maxY = 10;
    for(var d in data) {
      if (d.count > maxY) maxY = d.count.toDouble();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth < 400 ? 8 : 12;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.15,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1A237E),
                tooltipPadding: const EdgeInsets.all(12),
                tooltipBorderRadius: BorderRadius.circular(12),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String label = rodIndex == 0 ? 'إجمالي الأشخاص' : (rodIndex == 1 ? 'الحضور' : 'الغياب');
                  return BarTooltipItem(
                    '$label\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${rod.toY.toInt()} فرد',
                        style: TextStyle(color: Colors.blue.shade100, fontWeight: FontWeight.normal, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < displayData.length) {
                      final date = displayData[index].date;
                      String text;
                      if (_groupBy == 'day') {
                        text = '${date.day}';
                      } else if (_groupBy == 'month') {
                        text = '${date.month}';
                      } else {
                        text = '${date.year}';
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 12,
                        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade700)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: List.generate(displayData.length, (index) {
              final item = displayData[index];
              final attendees = item.count;
              final absentees = totalPersons - attendees;
              
              return BarChartGroupData(
                x: index,
                groupVertically: false,
                barRods: [
                  BarChartRodData(
                    toY: totalPersons.toDouble(),
                    color: Colors.grey.shade200,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: attendees.toDouble(),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: absentees > 0 ? absentees.toDouble() : 0.0,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade300, Colors.red.shade600],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: barWidth,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        );
      }
    );
  }
}
