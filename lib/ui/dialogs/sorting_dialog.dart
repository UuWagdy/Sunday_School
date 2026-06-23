import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pdf_export_options.dart';
import '../../repositories/fields_repository.dart';

class ReportColumn {
  final String id;
  final String title;
  bool isSelected;

  ReportColumn({required this.id, required this.title, this.isSelected = true});
}

class SortingCriterion {
  final String id;
  final String title;
  bool isSelected;

  SortingCriterion({
    required this.id,
    required this.title,
    this.isSelected = true,
  });
}

class SortingDialog extends ConsumerStatefulWidget {
  final bool isAttendance;
  const SortingDialog({super.key, this.isAttendance = true});

  @override
  ConsumerState<SortingDialog> createState() => _SortingDialogState();
}

class _SortingDialogState extends ConsumerState<SortingDialog> {
  // Sorting grouping criteria
  late List<SortingCriterion> _sortingCriteria = [];
  late List<SortingCriterion> _headerFields = [];
  late List<ReportColumn> _columns = [];
  bool _separatePages = false;
  bool _isInit = false;
  String? _shortcutType = 'name_code';
  PdfPageOrientationOption _orientation = PdfPageOrientationOption.auto;
  bool _stretchToFit = true;
  PdfGroupExportMode _groupExportMode = PdfGroupExportMode.singlePdfNewPages;

  void _applyShortcut(String type) {
    if (type == 'name_code') {
      for (var col in _columns) {
        if (col.id == 'name' || col.id == 'id') {
          col.isSelected = true;
        } else {
          col.isSelected = false;
        }
      }
    } else if (type == 'visitation') {
      final visitationIds = {
        'name',
        'id',
        'area',
        'stage',
        'father',
        'mobile',
        'phone',
        'street',
      };
      for (var col in _columns) {
        if (visitationIds.contains(col.id)) {
          col.isSelected = true;
        } else {
          col.isSelected = false;
        }
      }
    }
  }

  void _updateShortcutTypeFromColumns() {
    final selectedIds = _columns
        .where((c) => c.isSelected)
        .map((c) => c.id)
        .toSet();
    final visitationIds = {
      'name',
      'id',
      'area',
      'stage',
      'father',
      'mobile',
      'phone',
      'street',
    };

    if (selectedIds.length == 2 &&
        selectedIds.contains('name') &&
        selectedIds.contains('id')) {
      _shortcutType = 'name_code';
    } else if (selectedIds.length == 8 &&
        selectedIds.every((id) => visitationIds.contains(id))) {
      _shortcutType = 'visitation';
    } else {
      _shortcutType = null;
    }
  }

  void _init(List<FieldConfigDTO> fields) {
    if (_isInit) return;

    String getLabel(String key, String fallback) {
      final f = fields.where((f) => f.fieldKey == key).firstOrNull;
      return f?.name ?? fallback;
    }

    _sortingCriteria = [
      SortingCriterion(
        id: 'area',
        title: getLabel('area', 'المنطقة'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'stage',
        title: getLabel('stage', 'المرحلة'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'father',
        title: getLabel('father', 'أب الاعتراف'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'khoros',
        title: getLabel('khoros', 'الخورس'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'rohot',
        title: getLabel('rohot', 'الرهط'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'leader',
        title: getLabel('leader', 'القائد'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'services',
        title: getLabel('services', 'الخدمات'),
        isSelected: false,
      ),
      ...fields
          .where((f) => f.type == 'dropdown' || f.type == 'multi_select')
          .map((f) => SortingCriterion(
                id: 'custom_${f.id}_${f.name}',
                title: f.name,
                isSelected: false,
              )),
      SortingCriterion(id: 'name', title: 'الاسم', isSelected: false),
    ];

    _headerFields = [
      SortingCriterion(
        id: 'church_name',
        title: 'اسم الكنيسة',
        isSelected: true,
      ),
      SortingCriterion(
        id: 'khoros',
        title: getLabel('khoros', 'الخورس'),
        isSelected: true,
      ),
      if (widget.isAttendance)
        SortingCriterion(
          id: 'service_name',
          title: 'اسم الخدمة',
          isSelected: true,
        ),
      SortingCriterion(
        id: 'stage',
        title: getLabel('stage', 'المرحلة'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'area',
        title: getLabel('area', 'المنطقة'),
        isSelected: false,
      ),
      SortingCriterion(
        id: 'father',
        title: getLabel('father', 'أب الاعتراف'),
        isSelected: false,
      ),
    ];

    _columns = [
      ReportColumn(id: 'name', title: 'الاسم', isSelected: true),
      ReportColumn(id: 'id', title: 'الكود', isSelected: true),
      ReportColumn(
        id: 'area',
        title: getLabel('area', 'المنطقة'),
        isSelected: false,
      ),
      ReportColumn(
        id: 'stage',
        title: getLabel('stage', 'المرحلة'),
        isSelected: false,
      ),
      ReportColumn(
        id: 'father',
        title: getLabel('father', 'أب الاعتراف'),
        isSelected: false,
      ),
      ReportColumn(
        id: 'mobile',
        title: getLabel('mobile', 'موبايل'),
        isSelected: false,
      ),
      ReportColumn(
        id: 'phone',
        title: getLabel('phone', 'تليفون أرضي'),
        isSelected: false,
      ),
      ReportColumn(
        id: 'street',
        title: getLabel('street', 'العنوان بالتفصيل'),
        isSelected: false,
      ),
      if (!widget.isAttendance) ...[
        ReportColumn(
          id: 'gender',
          title: getLabel('gender', 'النوع'),
          isSelected: false,
        ),
        ReportColumn(
          id: 'birthday',
          title: getLabel('birthday', 'تاريخ الميلاد'),
          isSelected: false,
        ),
        ReportColumn(
          id: 'relationship',
          title: 'صلة القرابة',
          isSelected: false,
        ),
      ],
      if (widget.isAttendance) ...[
        ReportColumn(id: 'date', title: 'التاريخ', isSelected: false),
        ReportColumn(id: 'points', title: 'النقاط', isSelected: false),
        ReportColumn(id: 'time', title: 'وقت الحضور', isSelected: false),
        ReportColumn(id: 'checkout', title: 'وقت الانصراف', isSelected: false),
        ReportColumn(
          id: 'earlyLate',
          title: 'التبكير/التأخير',
          isSelected: false,
        ),
        ReportColumn(id: 'service', title: 'الخدمة', isSelected: false),
        ReportColumn(
          id: 'visitNotes',
          title: 'ملاحظات الافتقاد',
          isSelected: false,
        ),
      ],
    ];
    _isInit = true;
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsRepositoryProvider);
    return fieldsAsync.maybeWhen(
      data: (fields) {
        _init(fields);
        return DefaultTabController(
          length: 4,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                widget.isAttendance
                    ? 'إعدادات تقرير الحضور'
                    : 'إعدادات التقرير',
              ),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 500,
                height: 450,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'ترتيب المجموعات'),
                        Tab(text: 'اختيار الأعمدة'),
                        Tab(text: 'بيانات رأس التقرير'),
                        Tab(text: 'الطباعة'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSortingTab(),
                          _buildColumnsTab(),
                          _buildHeaderTab(),
                          _buildPrintOptionsTabClean(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final result = {
                      'sorting': _sortingCriteria
                          .where((c) => c.isSelected)
                          .map((c) => c.id)
                          .toList(),
                      'columns': _columns.where((c) => c.isSelected).toList(),
                      'header': _headerFields
                          .where((c) => c.isSelected)
                          .map((c) => c.id)
                          .toList(),
                      'separatePages': _separatePages,
                      'exportOptions': PdfExportOptions(
                        orientation: _orientation,
                        stretchToFit: _stretchToFit,
                        groupMode: _groupExportMode,
                      ),
                    };
                    Navigator.pop(context, result);
                  },
                  child: const Text('بدء الطباعة'),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSortingTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'اختر مستويات المجموعة واسحبها لتحديد الأولوية (مثلاً المنطقة أولاً):',
          ),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _sortingCriteria.removeAt(oldIndex);
                _sortingCriteria.insert(newIndex, item);
              });
            },
            children: [
              for (final criterion in _sortingCriteria)
                CheckboxListTile(
                  key: ValueKey('sort_${criterion.id}'),
                  secondary: const Icon(Icons.drag_handle),
                  title: Text(criterion.title),
                  value: criterion.isSelected,
                  onChanged: (val) {
                    setState(() => criterion.isSelected = val ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        CheckboxListTile(
          title: const Text('فصل كل تجميع جديد في صفحة خاصة به جديدة'),
          value: _separatePages || _groupExportMode == PdfGroupExportMode.separatePdfPerGroup,
          onChanged: (val) {
            setState(() {
              final isChecked = val ?? false;
              if (isChecked) {
                _separatePages = true;
                _groupExportMode = PdfGroupExportMode.singlePdfNewPages;
              } else {
                _separatePages = false;
                _groupExportMode = PdfGroupExportMode.singlePdfNewPages;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        if (_separatePages || _groupExportMode == PdfGroupExportMode.separatePdfPerGroup)
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: CheckboxListTile(
              title: const Text('كل تجميع في ملف لوحده (ملف PDF منفصل لكل تجميع)'),
              value: _groupExportMode == PdfGroupExportMode.separatePdfPerGroup,
              onChanged: (val) {
                setState(() {
                  final isChecked = val ?? false;
                  if (isChecked) {
                    _groupExportMode = PdfGroupExportMode.separatePdfPerGroup;
                    _separatePages = false;
                  } else {
                    _groupExportMode = PdfGroupExportMode.singlePdfNewPages;
                    _separatePages = true;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ),
      ],
    );
  }

  Widget _buildColumnsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('الاسم والكود فقط'),
                selected: _shortcutType == 'name_code',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _shortcutType = 'name_code';
                      _applyShortcut('name_code');
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('الافتقاد'),
                selected: _shortcutType == 'visitation',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _shortcutType = 'visitation';
                      _applyShortcut('visitation');
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('اختر الأعمدة واسحبها لترتيبها من اليمين لليسار:'),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _columns.removeAt(oldIndex);
                _columns.insert(newIndex, item);
              });
            },
            children: [
              for (final col in _columns)
                CheckboxListTile(
                  key: ValueKey('col_${col.id}'),
                  secondary: const Icon(Icons.drag_handle),
                  title: Text(col.title),
                  value: col.isSelected,
                  onChanged: (val) {
                    setState(() {
                      col.isSelected = val ?? false;
                      _updateShortcutTypeFromColumns();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('حدد البيانات المراد إظهارها في رأس التقرير الشبكي:'),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final criterion in _headerFields)
                CheckboxListTile(
                  key: ValueKey('hdr_${criterion.id}'),
                  title: Text(criterion.title),
                  value: criterion.isSelected,
                  onChanged: (val) {
                    setState(() => criterion.isSelected = val ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrintOptionsTabClean() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'اتجاه الصفحة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        RadioListTile<PdfPageOrientationOption>(
          title: const Text('تلقائي'),
          value: PdfPageOrientationOption.auto,
          groupValue: _orientation,
          onChanged: (value) {
            if (value != null) setState(() => _orientation = value);
          },
          dense: true,
        ),
        RadioListTile<PdfPageOrientationOption>(
          title: const Text('طولي'),
          value: PdfPageOrientationOption.portrait,
          groupValue: _orientation,
          onChanged: (value) {
            if (value != null) setState(() => _orientation = value);
          },
          dense: true,
        ),
        RadioListTile<PdfPageOrientationOption>(
          title: const Text('عرضي'),
          value: PdfPageOrientationOption.landscape,
          groupValue: _orientation,
          onChanged: (value) {
            if (value != null) setState(() => _orientation = value);
          },
          dense: true,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('تصغير الجدول ليناسب عرض الصفحة'),
          value: _stretchToFit,
          onChanged: (value) => setState(() => _stretchToFit = value),
          dense: true,
        ),
      ],
    );
  }
}
