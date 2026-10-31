import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard/general_attendance_chart.dart';
import '../widgets/dashboard/individual_attendance_chart.dart';
import '../widgets/dashboard/stat_cards_grid.dart';
import '../widgets/dashboard/attendance_rankings_chart.dart';
import '../widgets/dashboard/term_attendance_closure_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              Expanded(
                child: CustomScrollView(
                  cacheExtent: 100,
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final Widget child = switch (index) {
                          0 => const GeneralAttendanceWidget(),
                          1 => const TermAttendanceClosureWidget(),
                          2 => const IndividualAttendanceWidget(),
                          3 => const AttendanceRankingsWidget(),
                          4 => Text(
                            'الإحصائيات العامة والديموغرافية',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _ => const StatCardsGrid(),
                        };
                        return _DashboardSection(
                          key: ValueKey(index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: child,
                          ),
                        );
                      }, childCount: 6),
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

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      children: [
        Image.asset('assets/logo.png', height: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تحليل البيانات واتخاذ القرارات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 18 : 24,
                ),
              ),
              Text(
                'لوحة متابعة ذكية توضح معدلات الحضور والإحصائيات الخاصة بالمخدومين',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 11 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// A section starts loading only when scrolled into view. Keep its controls and
// results when scrolling away, and isolate expensive chart repaints.
class _DashboardSection extends StatefulWidget {
  const _DashboardSection({super.key, required this.child});
  final Widget child;
  @override
  State<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<_DashboardSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}
