import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database_provider.dart';
import '../../database/database.dart';
import '../../repositories/fields_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/hierarchical_area_picker.dart';

class BulkEditDialog extends ConsumerStatefulWidget {
  final List<int> personIds;
  const BulkEditDialog({super.key, required this.personIds});

  @override
  ConsumerState<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends ConsumerState<BulkEditDialog> {
  final _formKey = GlobalKey<FormState>();

  // Map to track which fields are checked for editing
  final Map<String, bool> _enabled = {};

  // Input state variables
  int? _stageId;
  int? _khorosId;
  int? _areaId;
  int? _fatherId;
  String? _gender;
  String? _rohot;
  String? _leader;
  
  final TextEditingController _streetC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();
  final TextEditingController _mobileC = TextEditingController();

  // Birth Date
  final TextEditingController _dayC_birth = TextEditingController();
  final TextEditingController _monthC_birth = TextEditingController();
  final TextEditingController _yearC_birth = TextEditingController();

  // Services
  List<int> _selectedServiceIds = [];

  // Custom Fields Map: fieldId -> value
  final Map<int, String> _customValues = {};

  // Rohot and Leader options
  Map<String, String> _rohotLeaderMap = {};
  List<String> _leadersList = [];

  bool _isInit = false;

  @override
  void dispose() {
    _streetC.dispose();
    _phoneC.dispose();
    _mobileC.dispose();
    _dayC_birth.dispose();
    _monthC_birth.dispose();
    _yearC_birth.dispose();
    super.dispose();
  }

  Future<void> _loadRohotGroupsMap() async {
    if (_isInit) return;
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final raw = await settingsRepo.getSetting('rohot_groups_json');
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        final Map<String, String> map = {};
        for (var item in list) {
          if (item is Map) {
            final k = item['name']?.toString() ?? '';
            final v = item['leader']?.toString() ?? '';
            if (k.isNotEmpty) map[k] = v;
          }
        }
        setState(() {
          _rohotLeaderMap = map;
        });
      } catch (_) {}
    }

    final rawLeaders = await settingsRepo.getSetting('rohot_leaders_json');
    if (rawLeaders != null && rawLeaders.isNotEmpty) {
      try {
        setState(() {
          _leadersList = List<String>.from(jsonDecode(rawLeaders));
        });
      } catch (_) {}
    }
    _isInit = true;
  }

  bool _isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    final daysInMonths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return day <= (isLeap ? 29 : 28);
    }

    return day <= daysInMonths[month];
  }

  @override
  Widget build(BuildContext context) {
    _loadRohotGroupsMap();
    final db = ref.watch(appDatabaseProvider);
    final fieldsAsync = ref.watch(fieldsRepositoryProvider);

    return fieldsAsync.maybeWhen(
      data: (customFields) {
        String getLabel(String key, String fallback) {
          final f = customFields.where((f) => f.fieldKey == key).firstOrNull;
          return f?.name ?? fallback;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل جماعي لعدد ${widget.personIds.length} شخص'),
            content: SizedBox(
              width: 600,
              height: 500,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'قم بتحديد الحقول التي ترغب في تعديلها للجميع، وأدخل القيمة الجديدة:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                      const Divider(),
                      // 1. Stage
                      _buildRow(
                        'stage',
                        getLabel('stage', 'المرحلة'),
                        _buildStageDropdown(db, getLabel('stage', 'المرحلة')),
                      ),
                      // 2. Khoros
                      _buildRow(
                        'khoros',
                        getLabel('khoros', 'الخورس'),
                        _buildKhorosDropdown(db, getLabel('khoros', 'الخورس')),
                      ),
                      // 3. Area
                      _buildRow(
                        'area',
                        getLabel('area', 'المنطقة'),
                        _buildAreaDropdown(db, getLabel('area', 'المنطقة')),
                      ),
                      // 4. Father
                      _buildRow(
                        'father',
                        getLabel('father', 'أب الاعتراف'),
                        _buildFatherDropdown(db, getLabel('father', 'أب الاعتراف')),
                      ),
                      // 5. Gender
                      _buildRow(
                        'gender',
                        getLabel('gender', 'النوع'),
                        _buildGenderDropdown(getLabel('gender', 'النوع')),
                      ),
                      // 6. Rohot
                      _buildRow(
                        'rohot',
                        getLabel('rohot', 'الرهط'),
                        _buildRohotDropdown(db, getLabel('rohot', 'الرهط')),
                      ),
                      // 7. Leader
                      _buildRow(
                        'leader',
                        getLabel('leader', 'القائد'),
                        _buildLeaderDropdown(db, getLabel('leader', 'القائد')),
                      ),
                      // 8. Services
                      _buildRow(
                        'services',
                        getLabel('services', 'الخدمات'),
                        _buildServicesMultiSelect(db, getLabel('services', 'الخدمات')),
                      ),
                      // 9. Street Address
                      _buildRow(
                        'street',
                        getLabel('street', 'العنوان بالتفصيل'),
                        TextFormField(
                          controller: _streetC,
                          decoration: InputDecoration(
                            labelText: getLabel('street', 'العنوان بالتفصيل'),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ),
                      // 10. Phone
                      _buildRow(
                        'phone',
                        getLabel('phone', 'تليفون أرضي'),
                        TextFormField(
                          controller: _phoneC,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: getLabel('phone', 'تليفون أرضي'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      // 11. Mobile
                      _buildRow(
                        'mobile',
                        getLabel('mobile', 'موبايل'),
                        TextFormField(
                          controller: _mobileC,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: getLabel('mobile', 'موبايل'),
                            prefixIcon: const Icon(Icons.phone_android_outlined),
                          ),
                        ),
                      ),
                      // 12. Birthday
                      _buildRow(
                        'birthday',
                        getLabel('birthday', 'تاريخ الميلاد'),
                        _buildBirthDatePicker(getLabel('birthday', 'تاريخ الميلاد')),
                      ),
                      const Divider(),
                      // Custom Fields
                      if (customFields.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'الحقول المخصصة:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ...customFields
                            .where((f) => f.type != 'document')
                            .map((f) => _buildRow(
                                  'custom_${f.id}',
                                  f.name,
                                  _buildCustomFieldInput(f),
                                )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: _save,
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        );
      },
      orElse: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRow(String key, String label, Widget childWidget) {
    final isEnabled = _enabled[key] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: (val) {
              setState(() {
                _enabled[key] = val ?? false;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !isEnabled,
                child: childWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Stage>>(
      future: db.select(db.stages).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        return DropdownButtonFormField<int?>(
          value: _stageId,
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.school_outlined)),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map((s) => DropdownMenuItem(value: s.stageId, child: Text(s.stageName ?? ''))),
          ],
          onChanged: (v) => setState(() => _stageId = v),
        );
      },
    );
  }

  Widget _buildKhorosDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Khorose>>(
      future: db.select(db.khoroses).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        return DropdownButtonFormField<int?>(
          value: _khorosId,
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.library_music_outlined)),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map((k) => DropdownMenuItem(value: k.khorosId, child: Text(k.khorosName ?? ''))),
          ],
          onChanged: (v) => setState(() => _khorosId = v),
        );
      },
    );
  }

  Widget _buildAreaDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Area>>(
      future: db.select(db.areas).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
        }
        return HierarchicalAreaPicker(
          allAreas: data,
          initialAreaId: _areaId,
          rootLabel: label,
          onChanged: (val) => setState(() => _areaId = val),
        );
      },
    );
  }

  Widget _buildFatherDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Father>>(
      future: db.select(db.fathers).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        return DropdownButtonFormField<int?>(
          value: _fatherId,
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.person_pin_outlined)),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map((f) => DropdownMenuItem(value: f.fatherId, child: Text(f.fatherName ?? ''))),
          ],
          onChanged: (v) => setState(() => _fatherId = v),
        );
      },
    );
  }

  Widget _buildGenderDropdown(String label) {
    const genders = ['ذكر', 'أنثى'];
    return DropdownButtonFormField<String?>(
      value: _gender,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.people_outline)),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ...genders.map((g) => DropdownMenuItem(value: g, child: Text(g))),
      ],
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _buildRohotDropdown(AppDatabase db, String label) {
    final rohotNames = _rohotLeaderMap.keys.toList();
    return DropdownButtonFormField<String?>(
      value: _rohot,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.group_outlined)),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ...rohotNames.map((name) => DropdownMenuItem(value: name, child: Text(name))),
      ],
      onChanged: (v) {
        setState(() {
          _rohot = v;
          if (v != null && _rohotLeaderMap.containsKey(v)) {
            _leader = _rohotLeaderMap[v];
            _enabled['leader'] = true; // Auto-enable leader if Rohot is edited
          }
        });
      },
    );
  }

  Widget _buildLeaderDropdown(AppDatabase db, String label) {
    return DropdownButtonFormField<String?>(
      value: _leader,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.person_outline)),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ..._leadersList.map((name) => DropdownMenuItem(value: name, child: Text(name))),
      ],
      onChanged: (v) => setState(() => _leader = v),
    );
  }

  Widget _buildServicesMultiSelect(AppDatabase db, String label) {
    return FutureBuilder<List<ServiceData>>(
      future: db.select(db.services).get(),
      builder: (_, snap) {
        final allServices = snap.data ?? [];
        if (allServices.isEmpty) return const SizedBox.shrink();

        final selectedServices = allServices.where((s) => _selectedServiceIds.contains(s.serviceId)).toList();

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$label: ${selectedServices.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () async {
                      final result = await showDialog<List<int>>(
                        context: context,
                        builder: (context) => _ServicesSelectionDialog(
                          allServices: allServices,
                          initialSelectedIds: _selectedServiceIds,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedServiceIds = result;
                        });
                      }
                    },
                    child: const Text('تعديل الخدمات', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              if (selectedServices.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: selectedServices
                      .map((s) => Chip(
                            label: Text(s.serviceName ?? '', style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBirthDatePicker(String label) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _dayC_birth,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'اليوم', hintText: 'DD'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _monthC_birth,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الشهر', hintText: 'MM'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _yearC_birth,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'السنة', hintText: 'YYYY'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFieldInput(FieldConfigDTO f) {
    switch (f.type) {
      case 'text':
        return TextFormField(
          initialValue: _customValues[f.id],
          decoration: InputDecoration(labelText: f.name, prefixIcon: const Icon(Icons.edit_note)),
          onChanged: (v) => _customValues[f.id] = v,
        );
      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: _customValues[f.id]?.isNotEmpty == true ? _customValues[f.id] : null,
          decoration: InputDecoration(labelText: f.name, prefixIcon: const Icon(Icons.list)),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر ${f.name}')),
            ...f.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
          ],
          onChanged: (v) => setState(() => _customValues[f.id] = v ?? ''),
        );
      case 'multi_select':
        final currentVals = _customValues[f.id]?.split(',').where((e) => e.isNotEmpty).toList() ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: f.options.map((opt) {
                final isSelected = currentVals.contains(opt);
                return FilterChip(
                  label: Text(opt, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        currentVals.add(opt);
                      } else {
                        currentVals.remove(opt);
                      }
                      _customValues[f.id] = currentVals.join(',');
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 'checkbox':
        final isChecked = _customValues[f.id] == 'true';
        final trueLabel = f.options.isNotEmpty ? f.options[0] : 'نعم';
        final falseLabel = f.options.length > 1 ? f.options[1] : 'لا';
        return CheckboxListTile(
          title: Text(f.name),
          subtitle: Text(isChecked ? trueLabel : falseLabel),
          value: isChecked,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _customValues[f.id] = (v ?? false).toString()),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate birth date if enabled
    int? day, month, year;
    if (_enabled['birthday'] == true) {
      final dayStr = _dayC_birth.text.trim();
      final monthStr = _monthC_birth.text.trim();
      final yearStr = _yearC_birth.text.trim();

      if (dayStr.isEmpty || monthStr.isEmpty || yearStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال تاريخ ميلاد كامل (يوم، شهر، سنة)')),
        );
        return;
      }

      day = int.tryParse(dayStr);
      month = int.tryParse(monthStr);
      year = int.tryParse(yearStr);

      if (!_isValidDate(day, month, year)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تاريخ الميلاد غير صالح!')),
        );
        return;
      }
    }

    final fields = ref.read(fieldsRepositoryProvider).asData?.value ?? [];

    // Construct custom values payload
    Map<int, String>? customValuesPayload;
    final enabledCustomFields = fields.where((f) => f.type != 'document' && _enabled['custom_${f.id}'] == true).toList();
    if (enabledCustomFields.isNotEmpty) {
      customValuesPayload = {};
      for (final f in enabledCustomFields) {
        customValuesPayload[f.id] = _customValues[f.id] ?? '';
      }
    }

    Navigator.pop(context, {
      'stageId': _enabled['stage'] == true ? drift.Value(_stageId) : const drift.Value.absent(),
      'khorosId': _enabled['khoros'] == true ? drift.Value(_khorosId) : const drift.Value.absent(),
      'areaId': _enabled['area'] == true ? drift.Value(_areaId) : const drift.Value.absent(),
      'fatherId': _enabled['father'] == true ? drift.Value(_fatherId) : const drift.Value.absent(),
      'streetName': _enabled['street'] == true ? drift.Value(_streetC.text.trim()) : const drift.Value.absent(),
      'phone': _enabled['phone'] == true ? drift.Value(_phoneC.text.trim()) : const drift.Value.absent(),
      'mobile': _enabled['mobile'] == true ? drift.Value(_mobileC.text.trim()) : const drift.Value.absent(),
      'day': _enabled['birthday'] == true ? drift.Value(day) : const drift.Value.absent(),
      'month': _enabled['birthday'] == true ? drift.Value(month) : const drift.Value.absent(),
      'year': _enabled['birthday'] == true ? drift.Value(year) : const drift.Value.absent(),
      'jenderName': _enabled['gender'] == true ? drift.Value(_gender) : const drift.Value.absent(),
      'rohot': _enabled['rohot'] == true ? drift.Value(_rohot) : const drift.Value.absent(),
      'leader': _enabled['leader'] == true ? drift.Value(_leader) : const drift.Value.absent(),
      'serviceIds': _enabled['services'] == true ? _selectedServiceIds : null,
      'customValues': customValuesPayload,
    });
  }
}

class _ServicesSelectionDialog extends StatefulWidget {
  final List<ServiceData> allServices;
  final List<int> initialSelectedIds;

  const _ServicesSelectionDialog({
    required this.allServices,
    required this.initialSelectedIds,
  });

  @override
  State<_ServicesSelectionDialog> createState() => _ServicesSelectionDialogState();
}

class _ServicesSelectionDialogState extends State<_ServicesSelectionDialog> {
  late List<int> _selectedIds;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = widget.allServices.where((s) {
      final name = s.serviceName ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.group_work_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'اختيار الخدمات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'بحث في الخدمات...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredServices.length,
                  itemBuilder: (context, idx) {
                    final service = filteredServices[idx];
                    final isChecked = _selectedIds.contains(service.serviceId);
                    return CheckboxListTile(
                      title: Text(service.serviceName ?? ''),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(service.serviceId);
                          } else {
                            _selectedIds.remove(service.serviceId);
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selectedIds),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
