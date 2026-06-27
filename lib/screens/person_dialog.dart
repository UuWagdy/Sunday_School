import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_provider.dart';
import '../database/database.dart';
import '../repositories/persons_repository.dart';
import '../repositories/service_eligibility_repository.dart';
import '../repositories/fields_repository.dart';
import '../repositories/family_repository.dart';
import '../repositories/documents_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/areas_repository.dart' hide Area;
import '../repositories/fathers_repository.dart';
import '../repositories/services_repository.dart';
import '../widgets/hierarchical_area_picker.dart';

class PersonDialog extends ConsumerStatefulWidget {
  final PersonListDTO? person;
  const PersonDialog({super.key, this.person});

  @override
  ConsumerState<PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends ConsumerState<PersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idC, _nameC, _streetC, _phoneC, _mobileC;
  late TextEditingController _dayC_birth, _monthC_birth, _yearC_birth;
  int? _stageId, _khorosId, _areaId, _fatherId, _day, _month, _year;
  String? _gender, _rohot, _leader;
  List<int> _selectedServiceIds = [];
  Map<String, String> _rohotLeaderMap = {};
  List<String> _leadersList = [];
  Map<int, String> _customValues = {};
  Uint8List? _photoBytes;
  bool _isLoading = false;
  bool _isInitDataLoaded = false;

  // Internal state to manage the person being edited/added
  PersonListDTO? _currentPerson;
  bool _hasBeenAdded = false; // Flag to indicate if a new person was just added

  bool get isEditing => _currentPerson != null;

  @override
  void initState() {
    super.initState();
    _currentPerson = widget.person; // Initialize with widget.person
    final p = _currentPerson; // Use _currentPerson for initial values
    _idC = TextEditingController(text: p?.id.toString() ?? '');
    _nameC = TextEditingController(text: p?.name ?? '');
    _streetC = TextEditingController(text: p?.streetName ?? '');
    _phoneC = TextEditingController(text: p?.phone ?? '');
    _mobileC = TextEditingController(text: p?.mobile ?? '');
    _dayC_birth = TextEditingController(
      text: p?.day != null ? p!.day.toString() : '',
    );
    _monthC_birth = TextEditingController(
      text: p?.month != null ? p!.month.toString() : '',
    );
    _yearC_birth = TextEditingController(
      text: p?.year != null ? p!.year.toString() : '',
    );
    _stageId = p?.stageId;
    _khorosId = p?.khorosId;
    _areaId = p?.areaId;
    _fatherId = p?.fatherId;
    _gender = p?.jenderName;
    _day = p?.day;
    _month = p?.month;
    _year = p?.year;
    _rohot = p?.rohot;
    _leader = p?.leader;
    _photoBytes = p?.photo;
    _selectedServiceIds = List.from(p?.serviceIds ?? []);

    if (isEditing) {
      _loadCustomValues();
    } else {
      _isInitDataLoaded = true;
      _loadNextPersonId();
    }
    _loadRohotGroupsMap();
  }

  @override
  void dispose() {
    _idC.dispose();
    _nameC.dispose();
    _streetC.dispose();
    _phoneC.dispose();
    _mobileC.dispose();
    _dayC_birth.dispose();
    _monthC_birth.dispose();
    _yearC_birth.dispose();
    super.dispose();
  }

  Future<void> _loadCustomValues() async {
    if (_currentPerson == null)
      return; // Should not happen if isEditing is true
    final values = await ref
        .read(personsRepositoryProvider.notifier)
        .fetchCustomFieldValues(_currentPerson!.id);
    if (mounted) {
      setState(() {
        _customValues = values;
        _isInitDataLoaded = true;
      });
    }
  }

  Future<void> _loadNextPersonId() async {
    final nextId = await ref
        .read(personsRepositoryProvider.notifier)
        .nextPersonId();
    if (!mounted || isEditing || _idC.text.trim().isNotEmpty) return;
    setState(() => _idC.text = nextId.toString());
  }

  bool _hasModifiedData =
      false; // Flag to return true to caller for refreshing list

  bool _isValidDate(int day, int month, int year) {
    if (month < 1 || month > 12) return false;
    if (year < 1900 || year > DateTime.now().year) return false;

    final monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      final maxDays = isLeap ? 29 : 28;
      return day >= 1 && day <= maxDays;
    }

    return day >= 1 && day <= monthLength[month - 1];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final dayStr = _dayC_birth.text.trim();
    final monthStr = _monthC_birth.text.trim();
    final yearStr = _yearC_birth.text.trim();

    if (dayStr.isNotEmpty || monthStr.isNotEmpty || yearStr.isNotEmpty) {
      if (dayStr.isEmpty || monthStr.isEmpty || yearStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إكمال تاريخ الميلاد (يوم وشهر وسنة)'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final d = int.tryParse(dayStr);
      final m = int.tryParse(monthStr);
      final y = int.tryParse(yearStr);
      if (d == null || m == null || y == null || !_isValidDate(d, m, y)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تاريخ الميلاد المدخل غير صالح (مثلاً تحقق من عدد أيام الشهر أو السنة الكبيسة)',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      _day = d;
      _month = m;
      _year = y;
    } else {
      _day = null;
      _month = null;
      _year = null;
    }

    final enteredId = int.tryParse(_idC.text.trim());
    if (enteredId == null || enteredId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم كارنيه صحيح وغير فارغ'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final idExists = await ref
        .read(personsRepositoryProvider.notifier)
        .personIdExists(enteredId);
    if (widget.person == null && !_hasBeenAdded && idExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رقم الكارنيه $enteredId مستخدم بالفعل، اختر رقمًا آخر',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final bool isBrandNew = widget.person == null && !_hasBeenAdded;

    try {
      final repo = ref.read(personsRepositoryProvider.notifier);

      if (!isBrandNew) {
        // Update Case
        final ok = await repo.updatePerson(
          id: _currentPerson!.id,
          name: _nameC.text.trim(),
          stageId: _stageId,
          khorosId: _khorosId,
          areaId: _areaId,
          fatherId: _fatherId,
          streetName: _streetC.text.trim(),
          phone: _phoneC.text.trim(),
          mobile: _mobileC.text.trim(),
          day: _day,
          month: _month,
          year: _year,
          jenderName: _gender,
          photo: _photoBytes,
          serviceIds: _selectedServiceIds,
          customValues: _customValues,
          rohot: _rohot,
          leader: _leader,
        );

        if (mounted && ok) {
          _hasModifiedData = true;
          Navigator.pop(context, true); // Complete and close
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحفظ')));
        }
      } else {
        // Initial 'Add' Case
        final newId = await repo.addPerson(
          id: enteredId,
          name: _nameC.text.trim(),
          stageId: _stageId,
          khorosId: _khorosId,
          areaId: _areaId,
          fatherId: _fatherId,
          streetName: _streetC.text.trim(),
          phone: _phoneC.text.trim(),
          mobile: _mobileC.text.trim(),
          day: _day,
          month: _month,
          year: _year,
          jenderName: _gender,
          photo: _photoBytes,
          serviceIds: _selectedServiceIds,
          customValues: _customValues,
          rohot: _rohot,
          leader: _leader,
        );

        if (mounted && newId != null) {
          _hasModifiedData = true;
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'حدث خطأ أثناء إضافة المخدوم؛ تأكد من الحقول المطلوبة',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ برمجيا: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitDataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final db = ref.watch(appDatabaseProvider);
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 700;
    final dialogWidth = isWide ? 650.0 : screenW * 0.95;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          Navigator.pop(context, _hasModifiedData);
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_outline),
                        text: 'البيانات الأساسية',
                      ),
                      Tab(
                        icon: Icon(Icons.family_restroom_outlined),
                        text: 'الأقارب',
                      ),
                    ],
                  ),
                  Flexible(
                    child: TabBarView(
                      children: [
                        // Tab 1: Basic Info
                        SingleChildScrollView(
                          padding: EdgeInsets.all(isWide ? 24 : 12),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final fieldsAsync = ref.watch(
                                fieldsRepositoryProvider,
                              );
                              return fieldsAsync.when(
                                data: (fields) => Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildPhotoPicker(),
                                      const SizedBox(height: 16),
                                      _buildStaticIdField(),
                                      const SizedBox(height: 16),
                                      ...fields
                                          .where((f) => f.isVisible)
                                          .map(
                                            (f) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: _buildDynamicField(
                                                f,
                                                db,
                                                isWide,
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, _) => Center(
                                  child: Text('Error loading fields: $e'),
                                ),
                              );
                            },
                          ),
                        ),
                        // Tab 2: Kinship
                        _buildKinshipTab(),
                      ],
                    ),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_note : Icons.person_add_outlined,
            color: Colors.white,
            size: isMobile ? 24 : 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEditing ? 'تعديل بيانات مخدوم' : 'إضافة مخدوم جديد',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context, _hasModifiedData),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Area>>(
      future: db.select(db.areas).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return HierarchicalAreaPicker(
          allAreas: data,
          initialAreaId: _areaId,
          rootLabel: label,
          onChanged: (val) {
            setState(() => _areaId = val);
          },
        );
      },
    );
  }

  Widget _buildFatherDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Father>>(
      future: db.select(db.fathers).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        final effectiveValue = data.any((f) => f.fatherId == _fatherId)
            ? _fatherId
            : null;
        return DropdownButtonFormField<int?>(
          value: effectiveValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.person_pin_outlined),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map(
              (f) => DropdownMenuItem(
                value: f.fatherId,
                child: Text(f.fatherName ?? ''),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _fatherId = v),
        );
      },
    );
  }

  Widget _buildBirthDatePicker(String label) {
    final dayField = TextFormField(
      controller: _dayC_birth,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: 'يوم',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final d = int.tryParse(val.trim());
        if (d == null || d < 1 || d > 31) return 'يوم غير صالح';
        return null;
      },
    );

    final monthField = TextFormField(
      controller: _monthC_birth,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: 'شهر',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final m = int.tryParse(val.trim());
        if (m == null || m < 1 || m > 12) return 'شهر غير صالح';
        return null;
      },
    );

    final yearField = TextFormField(
      controller: _yearC_birth,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: 'سنة',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return null;
        final y = int.tryParse(val.trim());
        final maxYear = DateTime.now().year;
        if (y == null || y < 1900 || y > maxYear) return 'سنة غير صالحة';
        return null;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(flex: 3, child: dayField),
            const SizedBox(width: 4),
            Expanded(flex: 3, child: monthField),
            const SizedBox(width: 4),
            Expanded(flex: 4, child: yearField),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pop(context, _hasModifiedData),
            child: Text(_hasModifiedData ? 'إغلاق' : 'إلغاء'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEditing ? Icons.check : Icons.add, size: 18),
            label: Text(
              _isLoading ? 'جاري...' : (isEditing ? 'حفظ' : 'إضافة'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithAddButton({
    required Widget child,
    required VoidCallback onAdd,
    String tooltip = 'إضافة جديد',
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          tooltip: tooltip,
        ),
      ],
    );
  }

  Future<String?> _showSimpleInputDialog(String title, String labelText) {
    final textC = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: TextField(
              controller: textC,
              autofocus: true,
              decoration: InputDecoration(labelText: labelText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, textC.text),
                child: const Text(
                  'موافق',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addStage(AppDatabase db) async {
    final name = await _showSimpleInputDialog(
      'إضافة مرحلة جديدة',
      'اسم المرحلة',
    );
    if (name != null && name.trim().isNotEmpty) {
      final ok = await ref
          .read(stagesRepositoryProvider.notifier)
          .addStage(name.trim());
      if (ok) {
        final list = await db.select(db.stages).get();
        final newStage = list.firstWhere(
          (s) => s.stageName == name.trim(),
          orElse: () => list.last,
        );
        setState(() {
          _stageId = newStage.stageId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المرحلة موجودة بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Future<void> _addKhoros(AppDatabase db) async {
    final name = await _showSimpleInputDialog('إضافة خورس جديد', 'اسم الخورس');
    if (name != null && name.trim().isNotEmpty) {
      final ok = await ref
          .read(khorosRepositoryProvider.notifier)
          .addKhoros(name.trim());
      if (ok) {
        final list = await db.select(db.khoroses).get();
        final newKhoros = list.firstWhere(
          (k) => k.khorosName == name.trim(),
          orElse: () => list.last,
        );
        setState(() {
          _khorosId = newKhoros.khorosId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الخورس موجود بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Future<void> _addArea(AppDatabase db) async {
    final areas = await db.select(db.areas).get();
    int? parentId = _areaId;
    final nameC = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة منطقة جديدة'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنطقة *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: parentId,
                      decoration: const InputDecoration(
                        labelText: 'المنطقة الرئيسية (اختياري)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('بدون منطقة رئيسية (منطقة مستوى أول)'),
                        ),
                        ...areas.map(
                          (a) => DropdownMenuItem(
                            value: a.areaId,
                            child: Text(a.areaName ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          parentId = val;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'إضافة',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && nameC.text.trim().isNotEmpty) {
      final ok = await ref
          .read(areasRepositoryProvider.notifier)
          .addArea(nameC.text.trim(), parentId: parentId);
      if (ok) {
        final list = await db.select(db.areas).get();
        final newArea = list.firstWhere(
          (a) => a.areaName == nameC.text.trim(),
          orElse: () => list.last,
        );
        setState(() {
          _areaId = newArea.areaId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المنطقة موجودة بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Future<void> _addFather(AppDatabase db) async {
    final name = await _showSimpleInputDialog(
      'إضافة أب اعتراف جديد',
      'اسم أب الاعتراف',
    );
    if (name != null && name.trim().isNotEmpty) {
      final ok = await ref
          .read(fathersRepositoryProvider.notifier)
          .addFather(name.trim());
      if (ok) {
        final list = await db.select(db.fathers).get();
        final newFather = list.firstWhere(
          (f) => f.fatherName == name.trim(),
          orElse: () => list.last,
        );
        setState(() {
          _fatherId = newFather.fatherId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أب الاعتراف موجود بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Future<void> _addRohotGroup() async {
    final nameC = TextEditingController();
    final leaders = List<String>.from(_leadersList);
    String? selectedLeader;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة رهط جديد'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'اسم الرهط *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedLeader,
                      decoration: const InputDecoration(
                        labelText: 'قائد الرهط (اختياري)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('بدون قائد حالياً'),
                        ),
                        ...leaders.map(
                          (l) => DropdownMenuItem(value: l, child: Text(l)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedLeader = val;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'إضافة',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && nameC.text.trim().isNotEmpty) {
      final name = nameC.text.trim();
      final settingsRepo = ref.read(settingsRepositoryProvider);

      _rohotLeaderMap[name] = selectedLeader ?? '';

      final listToSave = _rohotLeaderMap.entries
          .map((e) => {'name': e.key, 'leader': e.value})
          .toList();
      await settingsRepo.saveSetting(
        'rohot_groups_json',
        jsonEncode(listToSave),
      );

      await _loadRohotGroupsMap();
      setState(() {
        _rohot = name;
        if (selectedLeader != null) {
          _leader = selectedLeader;
        }
      });
    }
  }

  Future<void> _addLeader() async {
    final name = await _showSimpleInputDialog('إضافة قائد جديد', 'اسم القائد');
    if (name != null && name.trim().isNotEmpty) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      if (!_leadersList.contains(name.trim())) {
        _leadersList.add(name.trim());
        await settingsRepo.saveSetting(
          'rohot_leaders_json',
          jsonEncode(_leadersList),
        );
        await _loadRohotGroupsMap();
        setState(() {
          _leader = name.trim();
        });
      }
    }
  }

  Future<void> _addService(AppDatabase db) async {
    final name = await _showSimpleInputDialog('إضافة خدمة جديدة', 'اسم الخدمة');
    if (name != null && name.trim().isNotEmpty) {
      final ok = await ref
          .read(servicesRepositoryProvider.notifier)
          .addService(name: name.trim(), dayOfWeek: 5, hour: 8, minute: 0);
      if (ok) {
        final list = await db.select(db.services).get();
        final newService = list.firstWhere(
          (s) => s.serviceName == name.trim(),
          orElse: () => list.last,
        );
        setState(() {
          if (!_selectedServiceIds.contains(newService.serviceId)) {
            _selectedServiceIds.add(newService.serviceId);
          }
        });
      }
    }
  }

  Future<void> _addCustomDropdownOption(FieldConfigDTO f) async {
    final name = await _showSimpleInputDialog(
      'إضافة خيار جديد لـ ${f.name}',
      'الخيار الجديد',
    );
    if (name != null && name.trim().isNotEmpty) {
      final newOption = name.trim();
      final ok = await ref
          .read(fieldsRepositoryProvider.notifier)
          .addOptionToCustomField(f.id, newOption);
      if (ok) {
        setState(() {
          _customValues[f.id] = newOption;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الخيار موجود بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Future<void> _addCustomMultiSelectOption(FieldConfigDTO f) async {
    final name = await _showSimpleInputDialog(
      'إضافة خيار جديد لـ ${f.name}',
      'الخيار الجديد',
    );
    if (name != null && name.trim().isNotEmpty) {
      final newOption = name.trim();
      final ok = await ref
          .read(fieldsRepositoryProvider.notifier)
          .addOptionToCustomField(f.id, newOption);
      if (ok) {
        setState(() {
          final currentVals =
              _customValues[f.id]
                  ?.split(',')
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              [];
          if (!currentVals.contains(newOption)) {
            currentVals.add(newOption);
          }
          _customValues[f.id] = currentVals.join(',');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الخيار موجود بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  Widget _buildStaticIdField() {
    return TextFormField(
      controller: _idC,
      readOnly: isEditing,
      enabled: true,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isEditing ? Colors.grey.shade700 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: 'رقم الكارنيه',
        helperText: isEditing
            ? 'الرقم محفوظ لهذا الشخص'
            : 'يمكنك ترك الرقم التلقائي أو تغييره قبل الحفظ',
        prefixIcon: const Icon(Icons.qr_code),
        filled: true,
        fillColor: isEditing ? Colors.grey.shade200 : Colors.white,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final id = int.tryParse(value?.trim() ?? '');
        if (id == null || id <= 0) return 'رقم الكارنيه غير صحيح';
        return null;
      },
    );
  }

  Widget _buildDynamicField(FieldConfigDTO f, AppDatabase db, bool isWide) {
    if (f.type == 'native') {
      switch (f.fieldKey) {
        case 'name':
          return TextFormField(
            controller: _nameC,
            decoration: InputDecoration(
              labelText: '${f.name} *',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'يرجى إدخال ${f.name}' : null,
          );
        case 'gender':
          return _buildGenderDropdown(db, f.name);
        case 'stage':
          return _wrapWithAddButton(
            child: _buildStageDropdown(db, f.name),
            onAdd: () => _addStage(db),
            tooltip: 'إضافة مرحلة',
          );
        case 'mobile':
          return TextFormField(
            controller: _mobileC,
            decoration: InputDecoration(
              labelText: f.name,
              prefixIcon: const Icon(Icons.phone_android_outlined),
            ),
          );
        case 'phone':
          return TextFormField(
            controller: _phoneC,
            decoration: InputDecoration(
              labelText: f.name,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          );
        case 'area':
          return _wrapWithAddButton(
            child: _buildAreaDropdown(db, f.name),
            onAdd: () => _addArea(db),
            tooltip: 'إضافة منطقة',
          );
        case 'street':
          return TextFormField(
            controller: _streetC,
            decoration: InputDecoration(
              labelText: f.name,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          );
        case 'father':
          return _wrapWithAddButton(
            child: _buildFatherDropdown(db, f.name),
            onAdd: () => _addFather(db),
            tooltip: 'إضافة أب اعتراف',
          );
        case 'khoros':
          return _wrapWithAddButton(
            child: _buildKhorosDropdown(db, f.name),
            onAdd: () => _addKhoros(db),
            tooltip: 'إضافة خورس',
          );
        case 'rohot':
          return _wrapWithAddButton(
            child: _buildRohotDropdown(db, f.name),
            onAdd: () => _addRohotGroup(),
            tooltip: 'إضافة رهط',
          );
        case 'leader':
          return _wrapWithAddButton(
            child: _buildLeaderDropdown(db, f.name),
            onAdd: () => _addLeader(),
            tooltip: 'إضافة قائد',
          );
        case 'services':
          return _wrapWithAddButton(
            child: _buildServicesMultiSelect(db, f.name),
            onAdd: () => _addService(db),
            tooltip: 'إضافة خدمة',
          );
        case 'birthday':
          return _buildBirthDatePicker(f.name);
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Custom Fields
      switch (f.type) {
        case 'text':
          return TextFormField(
            initialValue: _customValues[f.id],
            decoration: InputDecoration(
              labelText: f.name,
              prefixIcon: const Icon(Icons.edit_note),
            ),
            onChanged: (v) => _customValues[f.id] = v,
          );
        case 'dropdown':
          return _wrapWithAddButton(
            child: DropdownButtonFormField<String>(
              value: _customValues[f.id]?.isNotEmpty == true
                  ? _customValues[f.id]
                  : null,
              decoration: InputDecoration(
                labelText: f.name,
                prefixIcon: const Icon(Icons.list),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('اختر ${f.name}')),
                ...f.options.map(
                  (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                ),
              ],
              onChanged: (v) => setState(() => _customValues[f.id] = v ?? ''),
            ),
            onAdd: () => _addCustomDropdownOption(f),
            tooltip: 'إضافة خيار جديد',
          );
        case 'multi_select':
          final currentVals =
              _customValues[f.id]
                  ?.split(',')
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    f.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: () => _addCustomMultiSelectOption(f),
                    tooltip: 'إضافة خيار جديد',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: f.options.map((opt) {
                  final isSelected = currentVals.contains(opt);
                  return FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected)
                          currentVals.add(opt);
                        else
                          currentVals.remove(opt);
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
            onChanged: (v) =>
                setState(() => _customValues[f.id] = (v ?? false).toString()),
          );
        case 'document':
          return _buildDocumentField(f);
        default:
          return const SizedBox.shrink();
      }
    }
  }

  Widget _buildDocumentField(FieldConfigDTO f) {
    if (!isEditing) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'يرجى حفظ بيانات المخدوم أولاً لإضافة ${f.name}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () => _uploadDocument(f),
              tooltip: 'إضافة ملف',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final docsAsync = ref
                .watch(documentsRepositoryProvider.notifier)
                .fetchDocuments(_currentPerson!.id, f.id);
            return FutureBuilder<List<PersonDocumentDTO>>(
              future: docsAsync,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return const LinearProgressIndicator();
                final docs = snap.data ?? [];
                if (docs.isEmpty)
                  return const Text(
                    'لا توجد ملفات',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  );
                return Column(
                  children: docs
                      .map(
                        (doc) => Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.insert_drive_file_outlined,
                            ),
                            title: Text(
                              doc.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download, size: 18),
                                  onPressed: () => _downloadDocument(doc),
                                  tooltip: 'تحميل',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => _deleteDocument(doc),
                                  tooltip: 'حذف',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _uploadDocument(FieldConfigDTO f) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.single.bytes != null) {
        final ok = await ref
            .read(documentsRepositoryProvider.notifier)
            .addDocument(
              personId: _currentPerson!.id,
              fieldId: f.id,
              fileName: result.files.single.name,
              fileContent: result.files.single.bytes!,
            );
        if (ok) setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في رفع الملف: $e')));
    }
  }

  Future<void> _downloadDocument(PersonDocumentDTO doc) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ الملف',
        fileName: doc.fileName,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(doc.fileContent);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ الملف بنجاح')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في حفظ الملف: $e')));
    }
  }

  Future<void> _deleteDocument(PersonDocumentDTO doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف ملف'),
        content: Text('هل أنت متأكد من حذف الملف "${doc.fileName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ref
          .read(documentsRepositoryProvider.notifier)
          .deleteDocument(doc.id);
      if (ok) setState(() {});
    }
  }

  Widget _buildGenderDropdown(AppDatabase db, String label) {
    const genders = ['ذكر', 'أنثى'];
    final effectiveGender = (genders.contains(_gender)) ? _gender : null;
    return DropdownButtonFormField<String?>(
      value: effectiveGender,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.wc_outlined),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ...genders.map((g) => DropdownMenuItem(value: g, child: Text(g))),
      ],
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _buildStageDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Stage>>(
      future: db.select(db.stages).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        final effectiveValue = data.any((s) => s.stageId == _stageId)
            ? _stageId
            : null;
        return DropdownButtonFormField<int?>(
          value: effectiveValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.school_outlined),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map(
              (s) => DropdownMenuItem(
                value: s.stageId,
                child: Text(s.stageName ?? ''),
              ),
            ),
          ],
          onChanged: (v) async {
            final linkedServices = await ServiceEligibilityRepository(
              db,
            ).stageServiceIds(v);
            if (!mounted) return;
            setState(() {
              _stageId = v;
              for (final serviceId in linkedServices) {
                if (!_selectedServiceIds.contains(serviceId)) {
                  _selectedServiceIds.add(serviceId);
                }
              }
            });
          },
        );
      },
    );
  }

  Widget _buildKhorosDropdown(AppDatabase db, String label) {
    return FutureBuilder<List<Khorose>>(
      future: db.select(db.khoroses).get(),
      builder: (_, snap) {
        final data = snap.data ?? [];
        final effectiveValue = data.any((k) => k.khorosId == _khorosId)
            ? _khorosId
            : null;
        return DropdownButtonFormField<int?>(
          value: effectiveValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.library_music_outlined),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('اختر $label')),
            ...data.map(
              (k) => DropdownMenuItem(
                value: k.khorosId,
                child: Text(k.khorosName ?? ''),
              ),
            ),
          ],
          onChanged: (v) async {
            final linkedServices = await ServiceEligibilityRepository(
              db,
            ).khorosServiceIds(v);
            if (!mounted) return;
            setState(() {
              _khorosId = v;
              for (final serviceId in linkedServices) {
                if (!_selectedServiceIds.contains(serviceId)) {
                  _selectedServiceIds.add(serviceId);
                }
              }
            });
          },
        );
      },
    );
  }

  Future<void> _loadRohotGroupsMap() async {
    final raw = await ref
        .read(settingsRepositoryProvider)
        .getSetting('rohot_groups_json');
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final map = <String, String>{};
          for (final item in decoded) {
            if (item is Map) {
              final name = (item['name'] as String? ?? '').trim();
              final leader = (item['leader'] as String? ?? '').trim();
              if (name.isNotEmpty && leader.isNotEmpty) {
                map[name] = leader;
              }
            }
          }
          if (mounted) {
            setState(() {
              _rohotLeaderMap = map;
            });
          }
        }
      } catch (_) {}
    }

    final rawLeaders = await ref
        .read(settingsRepositoryProvider)
        .getSetting('rohot_leaders_json');
    if (rawLeaders != null && rawLeaders.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLeaders);
        if (decoded is List) {
          if (mounted) {
            setState(() {
              _leadersList = decoded.cast<String>();
            });
          }
        }
      } catch (_) {}
    }
  }

  Widget _buildRohotDropdown(AppDatabase db, String label) {
    final rohotNames = _rohotLeaderMap.keys.toList();
    if (_rohot != null && _rohot!.isNotEmpty && !rohotNames.contains(_rohot)) {
      rohotNames.add(_rohot!);
    }
    final effectiveValue = rohotNames.contains(_rohot) ? _rohot : null;

    return DropdownButtonFormField<String?>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.groups_outlined),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ...rohotNames.map(
          (name) => DropdownMenuItem(value: name, child: Text(name)),
        ),
      ],
      onChanged: (v) {
        setState(() {
          _rohot = v;
          if (v != null && _rohotLeaderMap.containsKey(v)) {
            _leader = _rohotLeaderMap[v];
          }
        });
      },
    );
  }

  Widget _buildLeaderDropdown(AppDatabase db, String label) {
    final list = List<String>.from(_leadersList);
    if (_leader != null && _leader!.isNotEmpty && !list.contains(_leader)) {
      list.add(_leader!);
    }
    final effectiveValue = list.contains(_leader) ? _leader : null;

    return DropdownButtonFormField<String?>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_pin_outlined),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('اختر $label')),
        ...list.map((name) => DropdownMenuItem(value: name, child: Text(name))),
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

        final selectedServices = allServices
            .where((s) => _selectedServiceIds.contains(s.serviceId))
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                  Row(
                    children: [
                      Icon(
                        Icons.group_work_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$label:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
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
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text(
                      'إضافة / تعديل الخدمات',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              selectedServices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'لم يتم اختيار أي خدمات بعد.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedServices.map((s) {
                        return RawChip(
                          avatar: s.logo != null
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundImage: MemoryImage(s.logo!),
                                )
                              : CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.group_work_outlined,
                                    size: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                          label: Text(
                            s.serviceName ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedServiceIds.remove(s.serviceId);
                            });
                          },
                          deleteIcon: const Icon(
                            Icons.cancel,
                            size: 16,
                            color: Colors.red,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              image: _photoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_photoBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _photoBytes == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _photoBytes == null ? 'إضافة صورة' : 'تغيير الصورة',
                ),
              ),
              if (_photoBytes != null)
                TextButton.icon(
                  onPressed: () => setState(() => _photoBytes = null),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKinshipTab() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (!isEditing) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'يرجى حفظ بيانات المخدوم أولاً لإضافة الأقارب',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final relativesAsync = ref.watch(
      familyRepositoryProvider(_currentPerson!.id),
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showAddRelativeDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة قريب جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: relativesAsync.when(
              data: (relatives) {
                if (relatives.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد صلة قرابة مسجلة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return _buildCategorizedRelatives(relatives);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedRelatives(List<RelativeDTO> relatives) {
    final Map<String, List<RelativeDTO>> grouped = {};
    for (final r in relatives) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    const categories = [
      (id: 'marriage', label: 'الزواج', color: Colors.green),
      (id: 'first_degree', label: 'الدرجة الأولى', color: Colors.blue),
      (id: 'second_degree', label: 'الدرجة الثانية', color: Colors.orange),
      (id: 'third_degree', label: 'الدرجة الثالثة', color: Colors.purple),
      (id: 'other', label: 'أخرى', color: Colors.grey),
    ];

    return ListView(
      children: categories.where((c) => grouped.containsKey(c.id)).map((c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: c.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...grouped[c.id]!.map((r) => _buildRelativeCard(r, c.color)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRelativeCard(RelativeDTO r, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, color: color, size: 20),
        ),
        title: Text(
          r.relatedPersonName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _getRelationshipLabel(r.relationshipCode, r.customLabel),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _deleteRelationship(r),
        ),
      ),
    );
  }

  String _getRelationshipLabel(String code, String? custom) {
    if (code == 'OTHER' && custom != null) return custom;
    final Map<String, String> labels = {
      'FATHER': 'أب',
      'MOTHER': 'أم',
      'SON': 'ابن',
      'DAUGHTER': 'ابنة',
      'HUSBAND': 'زوج',
      'WIFE': 'زوجة',
      'BROTHER': 'أخ',
      'SISTER': 'أخت',
      'UNCLE_PATERNAL': 'عم',
      'AUNT_PATERNAL': 'عمة',
      'UNCLE_MATERNAL': 'خال',
      'AUNT_MATERNAL': 'خالة',
      'NEPHEW_PATERNAL': 'ابن أخ',
      'NIECE_PATERNAL': 'ابنة أخ',
      'NEPHEW_MATERNAL': 'ابن أخت',
      'NIECE_MATERNAL': 'ابنة أخت',
      'COUSIN_PATERNAL': 'ابن عم',
      'COUSIN_PATERNAL_F': 'ابنة عم',
      'COUSIN_AMMA': 'ابن عمة',
      'COUSIN_AMMA_F': 'ابنة عمة',
      'COUSIN_MATERNAL': 'ابن خال',
      'COUSIN_MATERNAL_F': 'ابنة خال',
      'COUSIN_KHALA': 'ابن خالة',
      'COUSIN_KHALA_F': 'ابنة خالة',
      'GRANDFATHER': 'جد',
      'GRANDMOTHER': 'جدة',
    };
    return labels[code] ?? code;
  }

  void _deleteRelationship(RelativeDTO r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف صلة قرابة'),
        content: Text(
          'هل أنت متأكد من حذف صلة القرابة مع "${r.relatedPersonName}"؟ سيتم حذفها من كلا الطرفين.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(familyRepositoryProvider(_currentPerson!.id).notifier)
          .deleteRelationship(r.id);
    }
  }

  void _showAddRelativeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddRelativeDialog(
        personId: _currentPerson!.id,
        personGender: _gender,
      ),
    );
    // Riverpod will auto-update since addRelationship calls invalidateSelf()
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }
}

class _AddRelativeDialog extends ConsumerStatefulWidget {
  final int personId;
  final String? personGender;
  const _AddRelativeDialog({required this.personId, this.personGender});

  @override
  ConsumerState<_AddRelativeDialog> createState() => _AddRelativeDialogState();
}

class _AddRelativeDialogState extends ConsumerState<_AddRelativeDialog> {
  String _category = 'first_degree';
  late String _relationshipCode;
  String? _targetLabel;
  String? _initiatorLabel;
  PersonListDTO? _selectedPerson;
  final TextEditingController _searchC = TextEditingController();
  List<PersonListDTO> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _relationshipCode = _getDefaultCodeForCategory('first_degree');
  }

  final Map<String, String> _categories = {
    'marriage': 'زواج',
    'first_degree': 'درجة أولى',
    'second_degree': 'درجة ثانية',
    'third_degree': 'درجة ثالثة',
    'other': 'أخرى',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة صلة قرابة'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'نوع العلاقة',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _category = v!;
                    _relationshipCode = _getDefaultCodeForCategory(v);
                  }),
                ),
                const SizedBox(height: 16),
                if (_category != 'other')
                  Builder(
                    builder: (context) {
                      final codes = _getCodesForCategory(_category);
                      final effectiveCode =
                          codes.any((c) => c.code == _relationshipCode)
                          ? _relationshipCode
                          : (codes.isNotEmpty ? codes.first.code : '');
                      return DropdownButtonFormField<String>(
                        key: ValueKey('rel_${_category}'),
                        value: effectiveCode,
                        decoration: const InputDecoration(
                          labelText: 'العلاقة',
                          border: OutlineInputBorder(),
                        ),
                        items: codes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text(c.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _relationshipCode = v!),
                      );
                    },
                  )
                else
                  Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'هو يقرب لي (مثلاً: ابن أخ)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _targetLabel = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'أنا أقرب له (مثلاً: عم)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _initiatorLabel = v),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _buildPersonSearch(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed:
                (_selectedPerson == null ||
                    (_category == 'other' &&
                        (_initiatorLabel == null || _targetLabel == null)))
                ? null
                : _save,
            child: const Text('ربط'),
          ),
        ],
      ),
    );
  }

  void _addNewPerson() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PersonDialog(),
    );
    if (result == true) {
      // Refresh or notify? The repo invalidates self on add.
      // We could try to find the last added person, but better to just let user search again.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الشخص بنجاح، يمكنك البحث عنه الآن'),
        ),
      );
    }
  }

  Widget _buildPersonSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اختيار الشخص:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _addNewPerson,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('إضافة جديد', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _searchC,
          decoration: InputDecoration(
            hintText: 'ابحث بالأسم أو الكود أو الموبايل...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onSearch,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            height: 150,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final p = _searchResults[index];
                final isSelected = _selectedPerson?.id == p.id;
                return ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text('كود: ${p.id} | ${p.stageName}'),
                  selected: isSelected,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  onTap: () => setState(() {
                    _selectedPerson = p;
                    _searchC.text = p.name;
                    _searchResults = [];
                  }),
                );
              },
            ),
          ),
        if (_selectedPerson != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'تم اختيار: ${_selectedPerson!.name}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onSearch(String v) async {
    if (v.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    final results = await ref
        .read(personsRepositoryProvider.notifier)
        .searchPersons(v);
    if (mounted) {
      setState(() {
        Iterable<PersonListDTO> filtered = results.where(
          (p) => p.id != widget.personId,
        );

        // Perspective: selection describes the Initiator (Side A).
        // Selection 'HUSBAND' -> Initiator is Husband -> Target must be female.
        // Selection 'WIFE' -> Initiator is Wife -> Target must be male.
        if (_relationshipCode == 'HUSBAND') {
          filtered = filtered.where((p) => p.jenderName == 'أنثى');
        } else if (_relationshipCode == 'WIFE') {
          filtered = filtered.where((p) => p.jenderName == 'ذكر');
        }

        _searchResults = filtered.toList();
        _isSearching = false;
      });
    }
  }

  String _getDefaultCodeForCategory(String cat) {
    bool isMale = widget.personGender == 'ذكر';
    if (cat == 'marriage') return isMale ? 'HUSBAND' : 'WIFE';
    if (cat == 'first_degree') return isMale ? 'FATHER' : 'MOTHER';
    if (cat == 'second_degree')
      return isMale ? 'UNCLE_PATERNAL' : 'AUNT_PATERNAL';
    if (cat == 'third_degree')
      return isMale ? 'COUSIN_PATERNAL' : 'COUSIN_PATERNAL_F';
    return 'OTHER';
  }

  List<({String code, String label})> _getCodesForCategory(String cat) {
    bool isMale = widget.personGender == 'ذكر';

    if (cat == 'marriage') {
      return isMale
          ? [(code: 'HUSBAND', label: 'زوج')]
          : [(code: 'WIFE', label: 'زوجة')];
    }
    if (cat == 'first_degree') {
      return [
        isMale ? (code: 'FATHER', label: 'أب') : (code: 'MOTHER', label: 'أم'),
        isMale
            ? (code: 'BROTHER', label: 'أخ')
            : (code: 'SISTER', label: 'أخت'),
        isMale
            ? (code: 'SON', label: 'ابن')
            : (code: 'DAUGHTER', label: 'ابنة'),
      ];
    }
    if (cat == 'second_degree') {
      return [
        isMale
            ? (code: 'UNCLE_PATERNAL', label: 'عم')
            : (code: 'AUNT_PATERNAL', label: 'عمة'),
        isMale
            ? (code: 'UNCLE_MATERNAL', label: 'خال')
            : (code: 'AUNT_MATERNAL', label: 'خالة'),
        isMale
            ? (code: 'NEPHEW_PATERNAL', label: 'ابن أخ')
            : (code: 'NIECE_PATERNAL', label: 'ابنة أخ'),
        isMale
            ? (code: 'NEPHEW_MATERNAL', label: 'ابن أخت')
            : (code: 'NIECE_MATERNAL', label: 'ابنة أخت'),
      ];
    }
    if (cat == 'third_degree') {
      return [
        isMale
            ? (code: 'COUSIN_PATERNAL', label: 'ابن عم')
            : (code: 'COUSIN_PATERNAL_F', label: 'ابنة عم'),
        isMale
            ? (code: 'COUSIN_AMMA', label: 'ابن عمة')
            : (code: 'COUSIN_AMMA_F', label: 'ابنة عمة'),
        isMale
            ? (code: 'COUSIN_MATERNAL', label: 'ابن خال')
            : (code: 'COUSIN_MATERNAL_F', label: 'ابنة خال'),
        isMale
            ? (code: 'COUSIN_KHALA', label: 'ابن خالة')
            : (code: 'COUSIN_KHALA_F', label: 'ابنة خالة'),
      ];
    }
    return [(code: 'OTHER', label: 'أخرى')];
  }

  void _save() async {
    if (_selectedPerson == null) return;

    final ok = await ref
        .read(familyRepositoryProvider(widget.personId).notifier)
        .addRelationship(
          personId: widget.personId,
          relatedPersonId: _selectedPerson!.id,
          category: _category,
          relationshipCode: _relationshipCode,
          customLabel: _targetLabel,
          initiatorCustomLabel: _initiatorLabel,
        );

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل الربط')));
      }
    }
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
  State<_ServicesSelectionDialog> createState() =>
      _ServicesSelectionDialogState();
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
            Icon(
              Icons.group_work_outlined,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'اختيار الخدمات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن خدمة...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Select All / Clear All buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        for (final s in filteredServices) {
                          if (!_selectedIds.contains(s.serviceId)) {
                            _selectedIds.add(s.serviceId);
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text(
                      'تحديد الكل',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        for (final s in filteredServices) {
                          _selectedIds.remove(s.serviceId);
                        }
                      });
                    },
                    icon: const Icon(Icons.deselect, size: 18),
                    label: const Text(
                      'إلغاء تحديد الكل',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(),
              // Services list
              Flexible(
                child: filteredServices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'لا توجد خدمات مطابقة للبحث',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
                            final s = filteredServices[index];
                            final isChecked = _selectedIds.contains(
                              s.serviceId,
                            );
                            return CheckboxListTile(
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(s.serviceId);
                                  } else {
                                    _selectedIds.remove(s.serviceId);
                                  }
                                });
                              },
                              title: Text(
                                s.serviceName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              secondary: s.logo != null
                                  ? CircleAvatar(
                                      backgroundImage: MemoryImage(s.logo!),
                                      radius: 16,
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                                      radius: 16,
                                      child: Icon(
                                        Icons.group_work_outlined,
                                        size: 18,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
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
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
