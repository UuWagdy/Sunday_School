import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../repositories/dashboard_repository.dart';
import '../../utils/storyteller.dart';

class StatCardsGrid extends StatelessWidget {
  const StatCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCardWidget(title: 'المناطق', provider: demographicAreasProvider, icon: Icons.map, isMobile: isMobile),
        _StatCardWidget(title: 'المراحل', provider: demographicStagesProvider, icon: Icons.school, isMobile: isMobile),
        _StatCardWidget(title: 'آباء الاعتراف', provider: demographicFathersProvider, icon: Icons.accessibility_new, isMobile: isMobile),
        _StatCardWidget(title: 'النوع', provider: demographicGenderProvider, icon: Icons.people, isMobile: isMobile, isPie: true),
        _StatCardWidget(title: 'أشهر الأسماء الأولى', provider: demographicFirstNamesProvider, icon: Icons.sort_by_alpha, isMobile: isMobile),
      ],
    );
  }
}

class _StatCardWidget extends ConsumerStatefulWidget {
  final String title;
  final dynamic provider;
  final IconData icon;
  final bool isMobile;
  final bool isPie;

  const _StatCardWidget({
    required this.title,
    required this.provider,
    required this.icon,
    required this.isMobile,
    this.isPie = false,
  });

  @override
  ConsumerState<_StatCardWidget> createState() => _StatCardWidgetState();
}

class _StatCardWidgetState extends ConsumerState<_StatCardWidget> {
  int _displayLimit = 10;
  String _sortCriteria = 'desc'; // 'desc', 'asc', 'alpha'

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(widget.provider) as AsyncValue<List<DemographicStatData>>;
    final width = widget.isMobile ? double.infinity : (MediaQuery.of(context).size.width / 2.5).clamp(350.0, 500.0);

    return SizedBox(
      width: width,
      child: Card(
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: Theme.of(context).primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: Colors.grey, size: 20),
                    onSelected: (value) => setState(() => _sortCriteria = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'desc', child: Row(children: [Icon(Icons.trending_down, size: 18), SizedBox(width: 8), Text('الأكثر عدداً (تنازلي)')])),
                      const PopupMenuItem(value: 'asc', child: Row(children: [Icon(Icons.trending_up, size: 18), SizedBox(width: 8), Text('الأقل عدداً (تصاعدي)')])),
                      const PopupMenuItem(value: 'alpha', child: Row(children: [Icon(Icons.sort_by_alpha, size: 18), SizedBox(width: 8), Text('ترتيب أبجدي')])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              asyncData.when(
                data: (rawData) {
                  if (rawData.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('لا توجد بيانات')));
                  
                  // Apply sorting
                  final data = List<DemographicStatData>.from(rawData);
                  if (_sortCriteria == 'desc') {
                    data.sort((a, b) => b.count.compareTo(a.count));
                  } else if (_sortCriteria == 'asc') {
                    data.sort((a, b) => a.count.compareTo(b.count));
                  } else if (_sortCriteria == 'alpha') {
                    data.sort((a, b) => a.label.compareTo(b.label));
                  }

                  final displayedData = widget.isPie ? data : data.take(_displayLimit).toList();
                  final hasMore = !widget.isPie && data.length > _displayLimit;

                  return Column(
                    children: [
                      if (widget.isPie) 
                        SizedBox(height: 220, child: _buildPieChart(displayedData))
                      else 
                        _buildBarChart(context, displayedData, data),
                      
                      if (hasMore) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _displayLimit += 10),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                            label: const Text('عرض المزيد', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                Storyteller.analyzeDemographics(data, widget.title),
                                style: const TextStyle(
                                  fontSize: 14, 
                                  height: 1.6, 
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (e, st) => SizedBox(height: 200, child: Center(child: Text('خطأ: $e'))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<DemographicStatData> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final colorPalettes = [
      [Colors.blue.shade400, Colors.blue.shade700],
      [Colors.pink.shade300, Colors.pink.shade600],
      [Colors.orange.shade300, Colors.orange.shade600],
      [Colors.teal.shade300, Colors.teal.shade600],
      [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
    ];
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 45,
        sections: List.generate(data.length, (i) {
          final palette = colorPalettes[i % colorPalettes.length];
          return PieChartSectionData(
            gradient: LinearGradient(colors: palette, begin: Alignment.topLeft, end: Alignment.bottomRight),
            value: data[i].count.toDouble(),
            title: data[i].count > 0 ? '${data[i].label}\n${data[i].count}' : '',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black26)]),
          );
        }),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<DemographicStatData> displayedData, List<DemographicStatData> fullData) {
    int maxCount = 0;
    for (var d in fullData) if (d.count > maxCount) maxCount = d.count;
    if (maxCount == 0) maxCount = 1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedData.length,
      itemBuilder: (context, index) {
        final item = displayedData[index];
        final double percentage = item.count / maxCount;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.6), Theme.of(context).primaryColor]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.count}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 13)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
