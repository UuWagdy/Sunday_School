import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../repositories/services_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/term_attendance_repository.dart';
import '../../services/term_attendance_excel_service.dart';
import '../../services/term_attendance_pdf_service.dart';

class TermAttendanceClosureWidget extends ConsumerStatefulWidget {
  const TermAttendanceClosureWidget({super.key});

  @override
  ConsumerState<TermAttendanceClosureWidget> createState() =>
      _TermAttendanceClosureWidgetState();
}

class _TermAttendanceClosureWidgetState
    extends ConsumerState<TermAttendanceClosureWidget> {
  final Set<int> _selectedServiceIds = {};
  final TextEditingController _maxGradeController = TextEditingController(
    text: '10',
  );
  final TextEditingController _dayMaxGradeController = TextEditingController(
    text: '4',
  );
  bool _addBehavior = false;
  bool _includeKhorosName = false;
  bool _includeKhorosCode = false;
  bool _includeStageName = false;
  bool _includeStageCode = false;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  TermAttendanceReport? _report;
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isPdfExporting = false;
  final ScrollController _tableHorizontalController = ScrollController();

  @override
  void dispose() {
    _maxGradeController.dispose();
    _dayMaxGradeController.dispose();
    _tableHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

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
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isMobile),
            const SizedBox(height: 20),
            servicesAsync.when(
              data: (services) => _buildControls(context, services, isMobile),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text('تعذر تحميل الخدمات: $error'),
            ),
            const SizedBox(height: 20),
            _buildReportContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تقفيل حضور الترم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'احسب درجات حضور الطلاب خلال فترة محددة للخدمة أو مجموعة خدمات.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          )
        : Row(
            children: [
              _buildIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقفيل حضور الترم',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                    Text(
                      'احسب درجات حضور الطلاب خلال فترة محددة للخدمة أو مجموعة خدمات.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.fact_check_outlined,
        color: Theme.of(context).primaryColor,
        size: 26,
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    List<ServiceDTO> services,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخدمات',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          Text(
            'لا توجد خدمات مسجلة',
            style: TextStyle(color: Colors.grey.shade600),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((service) {
              final selected = _selectedServiceIds.contains(service.id);
              return FilterChip(
                label: Text(
                  service.name.isEmpty ? 'خدمة بدون اسم' : service.name,
                ),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedServiceIds.add(service.id);
                    } else {
                      _selectedServiceIds.remove(service.id);
                    }
                    _report = null;
                  });
                },
                avatar: selected ? const Icon(Icons.check, size: 16) : null,
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DateButton(
              label: 'تاريخ البداية',
              value: _dateFormat.format(_startDate),
              icon: Icons.event_available_outlined,
              onPressed: () => _pickDate(isStart: true),
            ),
            _DateButton(
              label: 'تاريخ النهاية',
              value: _dateFormat.format(_endDate),
              icon: Icons.event_outlined,
              onPressed: () => _pickDate(isStart: false),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 160,
              child: TextField(
                controller: _maxGradeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'درجة الحضور من',
                  prefixIcon: const Icon(Icons.grade_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() => _report = null),
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 160,
              child: TextField(
                controller: _dayMaxGradeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'درجة اليوم',
                  prefixIcon: const Icon(Icons.star_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() => _report = null),
              ),
            ),
            FilterChip(
              label: const Text('إضافة السلوك'),
              selected: _addBehavior,
              onSelected: (value) {
                setState(() {
                  _addBehavior = value;
                  _report = null;
                });
              },
              avatar: _addBehavior ? const Icon(Icons.check, size: 16) : null,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _addBehavior
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            FilterChip(
              label: const Text('كود المرحلة'),
              selected: _includeStageCode,
              onSelected: (value) {
                setState(() {
                  _includeStageCode = value;
                });
              },
              avatar: _includeStageCode
                  ? const Icon(Icons.check, size: 16)
                  : null,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _includeStageCode
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            FilterChip(
              label: const Text('اسم المرحلة'),
              selected: _includeStageName,
              onSelected: (value) {
                setState(() {
                  _includeStageName = value;
                });
              },
              avatar: _includeStageName
                  ? const Icon(Icons.check, size: 16)
                  : null,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _includeStageName
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            FilterChip(
              label: const Text('كود الخورس'),
              selected: _includeKhorosCode,
              onSelected: (value) {
                setState(() {
                  _includeKhorosCode = value;
                });
              },
              avatar: _includeKhorosCode
                  ? const Icon(Icons.check, size: 16)
                  : null,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _includeKhorosCode
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            FilterChip(
              label: const Text('اسم الخورس'),
              selected: _includeKhorosName,
              onSelected: (value) {
                setState(() {
                  _includeKhorosName = value;
                });
              },
              avatar: _includeKhorosName
                  ? const Icon(Icons.check, size: 16)
                  : null,
              selectedColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _includeKhorosName
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            FilledButton.icon(
              onPressed: _isLoading ? null : _calculate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: const Text('حساب الدرجات'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: (_report == null || _isExporting) ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_view_outlined),
              label: const Text('تصدير Excel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: (_report == null || _isPdfExporting)
                  ? null
                  : _exportPdf,
              icon: _isPdfExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('تصدير PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportContent(BuildContext context) {
    final report = _report;
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (report == null) {
      return _buildEmptyState(
        context,
        'اختار الخدمات والفترة ودرجة الحضور، ثم اضغط حساب الدرجات.',
      );
    }

    if (report.meetings.isEmpty) {
      return _buildEmptyState(
        context,
        'لا توجد أيام خدمة داخل الفترة المختارة.',
      );
    }

    if (report.students.isEmpty) {
      return _buildEmptyState(
        context,
        'لا يوجد طلاب مربوطين بالخدمات المختارة.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatPill(
              label: 'عدد الطلاب',
              value: report.students.length.toString(),
              icon: Icons.groups_outlined,
            ),
            _StatPill(
              label: 'مرات الخدمة',
              value: report.totalMeetings.toString(),
              icon: Icons.calendar_month_outlined,
            ),
            _StatPill(
              label: 'متوسط الدرجة',
              value: _averageGrade(report),
              icon: Icons.trending_up_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Scrollbar(
          controller: _tableHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _tableHorizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).primaryColor.withValues(alpha: 0.08),
              ),
              columns: [
                const DataColumn(label: Text('كود')),
                const DataColumn(label: Text('الطالب')),
                if (_includeStageCode)
                  const DataColumn(label: Text('كود المرحلة')),
                if (_includeStageName)
                  const DataColumn(label: Text('اسم المرحلة')),
                if (_includeKhorosCode)
                  const DataColumn(label: Text('كود الخورس')),
                if (_includeKhorosName)
                  const DataColumn(label: Text('اسم الخورس')),
                ...report.meetings.map(
                  (meeting) => DataColumn(
                    label: SizedBox(
                      width: 92,
                      child: Text(
                        '${_dateFormat.format(meeting.date)}\n${meeting.serviceName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const DataColumn(label: Text('الحضور')),
                const DataColumn(label: Text('مجموع النقاط')),
                if (report.addBehavior)
                  const DataColumn(label: Text('متوسط السلوك')),
                const DataColumn(label: Text('المجموع')),
              ],
              rows: report.students.map((student) {
                return DataRow(
                  cells: [
                    DataCell(Text(student.personId.toString())),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          student.personName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_includeStageCode)
                      DataCell(Text(student.stageId?.toString() ?? '')),
                    if (_includeStageName) DataCell(Text(student.stageName)),
                    if (_includeKhorosCode)
                      DataCell(Text(student.khorosId?.toString() ?? '')),
                    if (_includeKhorosName) DataCell(Text(student.khorosName)),
                    ...report.meetings.map((meeting) {
                      final applies = student.serviceIds.contains(
                        meeting.serviceId,
                      );
                      final attended = student.attendedKeys.contains(
                        meeting.key,
                      );
                      final point = student.dailyPoints[meeting.key];
                      return DataCell(
                        Center(
                          child: applies
                              ? (attended
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${point ?? 0}/${_formatGrade(report.dayMaxGrade)})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked,
                                        color: Colors.grey.shade300,
                                        size: 20,
                                      ))
                              : Text(
                                  '-',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        '${_formatGrade(student.attendanceGrade)} (${_formatGrade(student.attendancePercentage)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        student.totalDailyPoints.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (report.addBehavior)
                      DataCell(
                        Text(
                          _formatGrade(student.averageBehavior),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    DataCell(
                      Text(
                        _formatGrade(student.grade),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = picked;
      }
      _report = null;
    });
  }

  Future<void> _calculate() async {
    if (_selectedServiceIds.isEmpty) {
      _showMessage('اختار خدمة واحدة على الأقل');
      return;
    }

    final maxGrade = double.tryParse(_maxGradeController.text);
    if (maxGrade == null || maxGrade <= 0) {
      _showMessage('اكتب درجة حضور صحيحة');
      return;
    }

    final dayMaxGrade = double.tryParse(_dayMaxGradeController.text);
    if (dayMaxGrade == null || dayMaxGrade <= 0) {
      _showMessage('اكتب درجة يوم صحيحة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final report = await ref
          .read(termAttendanceRepositoryProvider)
          .buildReport(
            serviceIds: _selectedServiceIds.toList(),
            startDate: _startDate,
            endDate: _endDate,
            maxGrade: maxGrade,
            dayMaxGrade: dayMaxGrade,
            addBehavior: _addBehavior,
          );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('تعذر حساب درجات الحضور: $error', isError: true);
    }
  }

  Future<void> _export() async {
    final report = _report;
    if (report == null) return;

    setState(() => _isExporting = true);
    try {
      final path = await TermAttendanceExcelService.exportReport(
        report,
        includeKhorosName: _includeKhorosName,
        includeKhorosCode: _includeKhorosCode,
        includeStageName: _includeStageName,
        includeStageCode: _includeStageCode,
      );
      if (!mounted) return;
      _showMessage(
        path == null ? 'تم إلغاء التصدير' : 'تم حفظ ملف الإكسل بنجاح',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر تصدير ملف الإكسل: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) return;

    setState(() => _isPdfExporting = true);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final churchName = await settingsRepo.getSetting('church_name');
      final churchLogo = await settingsRepo.getChurchLogo();

      await TermAttendancePdfService.exportReport(
        report,
        includeKhorosName: _includeKhorosName,
        includeKhorosCode: _includeKhorosCode,
        includeStageName: _includeStageName,
        includeStageCode: _includeStageCode,
        churchName: churchName,
        churchLogo: churchLogo,
      );
      if (!mounted) return;
      _showMessage('تم تشغيل نافذة طباعة PDF بنجاح');
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر تصدير ملف الـ PDF: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isPdfExporting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  String _averageGrade(TermAttendanceReport report) {
    if (report.students.isEmpty) return '0';
    final total = report.students.fold<double>(
      0,
      (sum, student) => sum + student.grade,
    );
    return _formatGrade(total / report.students.length);
  }

  String _formatGrade(double grade) {
    return grade == grade.roundToDouble()
        ? grade.toInt().toString()
        : grade.toStringAsFixed(2);
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
