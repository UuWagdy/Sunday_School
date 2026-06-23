import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard_repository.dart';
import '../../database/database_provider.dart';

class AttendanceRankingsWidget extends ConsumerStatefulWidget {
  const AttendanceRankingsWidget({super.key});

  @override
  ConsumerState<AttendanceRankingsWidget> createState() => _AttendanceRankingsWidgetState();
}

class _AttendanceRankingsWidgetState extends ConsumerState<AttendanceRankingsWidget> {
  int? _selectedStageId;
  int? _selectedAreaId;
  int? _selectedFatherId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _selectedServiceId;
  String _sortCriteria = 'attendance'; // 'attendance', 'absence', 'all', 'most_late', 'most_early'
  int _limitCount = 15;

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(attendanceRankingsProvider(
      stageId: _selectedStageId,
      areaId: _selectedAreaId,
      fatherId: _selectedFatherId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      serviceId: _selectedServiceId,
      sortCriteria: _sortCriteria,
      limit: _limitCount,
    ));

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            rankingsAsync.when(
              data: (data) => _buildRankingsList(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('خطأ: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bar_chart, color: Colors.blue, size: 28),
        ),
        const SizedBox(width: 16),
        Text(
          'تصنيف الحضور',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final db = ref.watch(appDatabaseProvider);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Simplified for now, will add FutureBuilders if needed but let's try to keep it clean
        // Actually, let's use the DB directly here for filters
        _buildDbFilter<int?>(
          provider: db.select(db.stages).get(),
          value: _selectedStageId,
          label: 'المرحلة',
          onChanged: (v) => setState(() => _selectedStageId = v),
          idMapper: (s) => s.stageId,
          nameMapper: (s) => s.stageName ?? '',
        ),
        _buildDbFilter<int?>(
          provider: db.select(db.areas).get(),
          value: _selectedAreaId,
          label: 'المنطقة',
          onChanged: (v) => setState(() => _selectedAreaId = v),
          idMapper: (a) => a.areaId,
          nameMapper: (a) => a.areaName ?? '',
        ),
        _buildDbFilter<int?>(
          provider: db.select(db.fathers).get(),
          value: _selectedFatherId,
          label: 'أب الاعتراف',
          onChanged: (v) => setState(() => _selectedFatherId = v),
          idMapper: (f) => f.fatherId,
          nameMapper: (f) => f.fatherName ?? '',
        ),
        _buildDateFilter('من تاريخ', _dateFrom, (d) => setState(() => _dateFrom = d)),
        _buildDateFilter('إلى تاريخ', _dateTo, (d) => setState(() => _dateTo = d)),
        _buildDbFilter<int?>(
          provider: db.select(db.services).get(),
          value: _selectedServiceId,
          label: 'الخدمة',
          onChanged: (v) => setState(() => _selectedServiceId = v),
          idMapper: (s) => (s as dynamic).serviceId,
          nameMapper: (s) => (s as dynamic).serviceName ?? '',
        ),
        _buildDropdown<String>(
          value: _sortCriteria,
          items: const [
            DropdownMenuItem(value: 'attendance', child: Text('الأكثر حضوراً')),
            DropdownMenuItem(value: 'absence', child: Text('الأكثر غياباً')),
            DropdownMenuItem(value: 'most_late', child: Text('الأكثر تأخيراً')),
            DropdownMenuItem(value: 'most_early', child: Text('الأكثر تبكيراً')),
            DropdownMenuItem(value: 'all', child: Text('الكل')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _sortCriteria = v);
          },
          width: 150,
        ),
      ],
    );
  }

  Widget _buildDateFilter(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(value != null ? "${value.year}/${value.month}/${value.day}" : label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            if (value != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDbFilter<T>({
    required Future<List<dynamic>> provider,
    required T value,
    required String label,
    required ValueChanged<T?> onChanged,
    required int Function(dynamic) idMapper,
    required String Function(dynamic) nameMapper,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: provider,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return _buildDropdown<T>(
          value: value,
          hint: label,
          items: [
            DropdownMenuItem(value: null, child: Text('كل $label')),
            ...items.map((i) => DropdownMenuItem(value: idMapper(i) as T, child: Text(nameMapper(i)))),
          ],
          onChanged: onChanged,
          width: 140,
        );
      },
    );
  }

  Widget _buildDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, required double width, String? hint}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 12)) : null,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        ),
      ),
    );
  }

  Widget _buildRankingsList(List<DemographicStatData> data) {
    if (data.isEmpty) return const Center(child: Text('لا توجد بيانات'));
    
    int maxCount = 0;
    for (var d in data) {
      if (d.count > maxCount) maxCount = d.count;
    }
    if (maxCount == 0) maxCount = 1;

    return Column(
      children: [
        ...data.map((item) => _buildRankItem(item, maxCount)),
        if (data.length >= _limitCount) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _limitCount += 15),
              icon: const Icon(Icons.keyboard_arrow_down),
              label: const Text('عرض المزيد'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRankItem(DemographicStatData item, int maxCount) {
    final double percentage = item.count / maxCount;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _sortCriteria == 'most_late' ? [Colors.red.shade300, Colors.red.shade600] : 
                                   (_sortCriteria == 'most_early' ? [Colors.green.shade300, Colors.green.shade600] : 
                                   [Colors.blue.shade300, Colors.blue.shade600]),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                (_sortCriteria == 'most_late' || _sortCriteria == 'most_early') 
                  ? '${item.count} د' 
                  : '${item.count}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: _sortCriteria == 'most_late' ? Colors.red : 
                         (_sortCriteria == 'most_early' ? Colors.green : Colors.blue), 
                  fontSize: 13
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}
