import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../repositories/services_repository.dart';

class PrintPeriodServicesResult {
  final DateTime dateFrom;
  final DateTime dateTo;
  final List<int> selectedServiceIds;
  final String periodLabel;
  final String serviceLabel;

  PrintPeriodServicesResult({
    required this.dateFrom,
    required this.dateTo,
    required this.selectedServiceIds,
    required this.periodLabel,
    required this.serviceLabel,
  });
}

class PrintPeriodServicesDialog extends ConsumerStatefulWidget {
  final DateTime anchorDate;
  final List<ServiceDTO> services;

  const PrintPeriodServicesDialog({
    super.key,
    required this.anchorDate,
    required this.services,
  });

  @override
  ConsumerState<PrintPeriodServicesDialog> createState() =>
      _PrintPeriodServicesDialogState();
}

class _PrintPeriodServicesDialogState
    extends ConsumerState<PrintPeriodServicesDialog> {
  late String _selectedPeriod;
  late DateTime _customDateFrom;
  late DateTime _customDateTo;
  late Set<int> _selectedServiceIds;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = 'day';
    _customDateFrom = widget.anchorDate;
    _customDateTo = widget.anchorDate;
    _selectedServiceIds = {};
  }

  void _initDefaults() {
    if (_isInit) return;
    final weekday = widget.anchorDate.weekday;
    for (var s in widget.services) {
      if (s.dayOfWeek == weekday) {
        _selectedServiceIds.add(s.id);
      }
    }
    _isInit = true;
  }

  String _getWeekRangeString(DateTime from, DateTime to) {
    return 'من ${DateFormat('MM-dd').format(from)} إلى ${DateFormat('MM-dd').format(to)}';
  }

  String _getMonthRangeString(DateTime from, DateTime to) {
    return 'من ${DateFormat('MM-dd').format(from)} إلى ${DateFormat('MM-dd').format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    _initDefaults();

    // Calculate dates based on period
    DateTime fromDate;
    DateTime toDate;
    String periodText;

    if (_selectedPeriod == 'day') {
      fromDate = widget.anchorDate;
      toDate = widget.anchorDate;
      periodText = 'اليوم (${DateFormat('yyyy-MM-dd').format(widget.anchorDate)})';
    } else if (_selectedPeriod == 'week') {
      final int offset = widget.anchorDate.weekday - 1;
      fromDate = widget.anchorDate.subtract(Duration(days: offset));
      toDate = fromDate.add(const Duration(days: 6));
      periodText = 'هذا الأسبوع (${_getWeekRangeString(fromDate, toDate)})';
    } else if (_selectedPeriod == 'month') {
      fromDate = DateTime(widget.anchorDate.year, widget.anchorDate.month, 1);
      toDate = DateTime(widget.anchorDate.year, widget.anchorDate.month + 1, 0);
      periodText = 'هذا الشهر (${_getMonthRangeString(fromDate, toDate)})';
    } else {
      fromDate = _customDateFrom;
      toDate = _customDateTo;
      periodText = 'فترة مخصصة (من ${DateFormat('yyyy-MM-dd').format(fromDate)} إلى ${DateFormat('yyyy-MM-dd').format(toDate)})';
    }

    final int offset = widget.anchorDate.weekday - 1;
    final DateTime startOfWeek = widget.anchorDate.subtract(Duration(days: offset));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final DateTime startOfMonth = DateTime(widget.anchorDate.year, widget.anchorDate.month, 1);
    final DateTime endOfMonth = DateTime(widget.anchorDate.year, widget.anchorDate.month + 1, 0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('إعدادات فترة الطباعة والخدمات'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تحديد فترة التقرير:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: Text('اليوم الحالي (${DateFormat('yyyy-MM-dd').format(widget.anchorDate)})'),
                  value: 'day',
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text('هذا الأسبوع (${_getWeekRangeString(startOfWeek, endOfWeek)})'),
                  value: 'week',
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text('هذا الشهر (${_getMonthRangeString(startOfMonth, endOfMonth)})'),
                  value: 'month',
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('تاريخ مخصص (البداية والنهاية)'),
                  value: 'custom',
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                if (_selectedPeriod == 'custom') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customDateFrom,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _customDateFrom = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'من تاريخ',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_customDateFrom)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customDateTo,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _customDateTo = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'إلى تاريخ',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_customDateTo)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تحديد الخدمات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedServiceIds = widget.services.map((s) => s.id).toSet();
                            });
                          },
                          child: const Text('تحديد الكل', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedServiceIds.clear();
                            });
                          },
                          child: const Text('إلغاء الكل', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: widget.services.isEmpty
                      ? const Center(child: Text('لا توجد خدمات متاحة'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.services.length,
                          itemBuilder: (context, idx) {
                            final svc = widget.services[idx];
                            final isChecked = _selectedServiceIds.contains(svc.id);
                            return CheckboxListTile(
                              title: Text('${svc.name} (${svc.dayName})'),
                              subtitle: Text(svc.formattedTime),
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedServiceIds.add(svc.id);
                                  } else {
                                    _selectedServiceIds.remove(svc.id);
                                  }
                                });
                              },
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _selectedServiceIds.isEmpty
                ? null
                : () {
                    // Prepare service label
                    String serviceLabel = '';
                    if (_selectedServiceIds.length == widget.services.length) {
                      serviceLabel = 'كل الخدمات';
                    } else {
                      serviceLabel = widget.services
                          .where((s) => _selectedServiceIds.contains(s.id))
                          .map((s) => s.name)
                          .join('، ');
                    }

                    Navigator.pop(
                      context,
                      PrintPeriodServicesResult(
                        dateFrom: fromDate,
                        dateTo: toDate,
                        selectedServiceIds: _selectedServiceIds.toList(),
                        periodLabel: periodText,
                        serviceLabel: serviceLabel,
                      ),
                    );
                  },
            child: const Text('استمرار'),
          ),
        ],
      ),
    );
  }
}
