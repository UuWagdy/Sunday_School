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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final containerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final containerBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final accentAction = isDark ? const Color(0xFF38BDF8) : primaryColor;
    final redAction = isDark ? const Color(0xFFF87171) : Colors.red.shade700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print_rounded, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'إعدادات فترة الطباعة والخدمات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تحديد فترة التقرير:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: Text(
                    'اليوم الحالي (${DateFormat('yyyy-MM-dd').format(widget.anchorDate)})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedPeriod == 'day' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedPeriod == 'day' ? textPrimary : textSecondary,
                    ),
                  ),
                  value: 'day',
                  activeColor: primaryColor,
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'هذا الأسبوع (${_getWeekRangeString(startOfWeek, endOfWeek)})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedPeriod == 'week' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedPeriod == 'week' ? textPrimary : textSecondary,
                    ),
                  ),
                  value: 'week',
                  activeColor: primaryColor,
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'هذا الشهر (${_getMonthRangeString(startOfMonth, endOfMonth)})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedPeriod == 'month' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedPeriod == 'month' ? textPrimary : textSecondary,
                    ),
                  ),
                  value: 'month',
                  activeColor: primaryColor,
                  groupValue: _selectedPeriod,
                  onChanged: (v) => setState(() => _selectedPeriod = v!),
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'تاريخ مخصص (البداية والنهاية)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedPeriod == 'custom' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedPeriod == 'custom' ? textPrimary : textSecondary,
                    ),
                  ),
                  value: 'custom',
                  activeColor: primaryColor,
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
                            decoration: InputDecoration(
                              labelText: 'من تاريخ',
                              labelStyle: TextStyle(color: textMuted, fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: containerBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: containerBorder, width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: containerBorder, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: primaryColor, width: 1.8),
                              ),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_customDateFrom),
                              style: TextStyle(color: textPrimary, fontSize: 13),
                            ),
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
                            decoration: InputDecoration(
                              labelText: 'إلى تاريخ',
                              labelStyle: TextStyle(color: textMuted, fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: containerBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: containerBorder, width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: containerBorder, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: primaryColor, width: 1.8),
                              ),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_customDateTo),
                              style: TextStyle(color: textPrimary, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: dividerColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تحديد الخدمات:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedServiceIds = widget.services.map((s) => s.id).toSet();
                            });
                          },
                          child: Text(
                            'تحديد الكل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentAction,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedServiceIds.clear();
                            });
                          },
                          child: Text(
                            'إلغاء الكل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: redAction,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: containerBorder, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                    color: containerBg,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.services.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد خدمات متاحة',
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.services.length,
                          separatorBuilder: (context, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: dividerColor.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, idx) {
                            final svc = widget.services[idx];
                            final isChecked = _selectedServiceIds.contains(svc.id);
                            return CheckboxListTile(
                              title: Text(
                                '${svc.name} (${svc.dayName})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                svc.formattedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                              value: isChecked,
                              activeColor: primaryColor,
                              checkColor: Colors.white,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
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
            child: Text(
              'إلغاء',
              style: TextStyle(color: textMuted),
            ),
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
