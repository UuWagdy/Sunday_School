import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/bus_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/bus_pdf_service.dart';
import '../sync/data_change_coordinator.dart';
import '../utils/silent_refresh_controller.dart';
import '../sync/data_change_domains.dart';

class BusesScreen extends ConsumerStatefulWidget {
  const BusesScreen({super.key});

  @override
  ConsumerState<BusesScreen> createState() => _BusesScreenState();
}

class _BusesScreenState extends ConsumerState<BusesScreen> {
  int? _selectedDriverId;
  int _studentsGeneration = 0;
  late final SilentRefreshController _studentsRefreshController;
  DateTime _selectedDate = DateTime.now();
  bool _showExcludedWithParent = false;
  bool _isLoadingStudents = false;
  List<BusStudentDTO> _currentStudents = [];

  // Search/Add student
  StudentSearchResult? _selectedStudentToLink;
  TextEditingController? _searchStudentController;
  FocusNode? _searchStudentFocusNode;

  // Columns configuration
  List<BusColumnItem> _columns = List.from(BusPdfService.defaultColumns);
  static const String _columnsPrefsKey = 'bus_columns_config';

  @override
  void initState() {
    super.initState();
    _studentsRefreshController = SilentRefreshController(
      onRefresh: () async {
        final id = _selectedDriverId;
        if (id != null) await _loadStudentsForDriver(id, silent: true);
      },
    );
    _loadColumns();
  }

  Future<void> _loadColumns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_columnsPrefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        final loaded = decoded
            .map((e) => BusColumnItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final existingKeys = loaded.map((c) => c.key).toSet();
        for (final def in BusPdfService.defaultColumns) {
          if (!existingKeys.contains(def.key)) {
            loaded.add(def);
          }
        }
        if (mounted) {
          setState(() {
            _columns = loaded;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading bus columns: $e');
    }
  }

  Future<void> _saveColumns(List<BusColumnItem> cols) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(cols.map((c) => c.toJson()).toList());
      await prefs.setString(_columnsPrefsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving bus columns: $e');
    }
  }

  Future<void> _showCustomizeColumnsDialog() async {
    List<BusColumnItem> tempCols = _columns
        .map(
          (c) =>
              BusColumnItem(key: c.key, label: c.label, isVisible: c.isVisible),
        )
        .toList();

    final result = await showDialog<List<BusColumnItem>>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.view_column_rounded, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('تخصيص وترتيب أعمدة الكشف'),
                ],
              ),
              content: SizedBox(
                width: 420,
                height: 460,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'اسحب من المقبض لإعادة الترتيب، وفعل/عطل ظهور العمود في الجدول وملف الـ PDF.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: tempCols.length,
                        onReorder: (oldIndex, newIndex) {
                          setDlgState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = tempCols.removeAt(oldIndex);
                            tempCols.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final col = tempCols[index];
                          return Card(
                            key: ValueKey(col.key),
                            elevation: 0,
                            color: col.isVisible
                                ? Colors.grey.shade50
                                : Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: col.isVisible
                                    ? Colors.indigo.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              leading: Checkbox(
                                value: col.isVisible,
                                onChanged: (val) {
                                  setDlgState(() {
                                    tempCols[index] = col.copyWith(
                                      isVisible: val ?? true,
                                    );
                                  });
                                },
                              ),
                              title: Text(
                                col.label,
                                style: TextStyle(
                                  fontWeight: col.isVisible
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: col.isVisible
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              trailing: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(
                                  Icons.drag_handle_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setDlgState(() {
                      tempCols = BusPdfService.defaultColumns
                          .map(
                            (c) => BusColumnItem(
                              key: c.key,
                              label: c.label,
                              isVisible: c.isVisible,
                            ),
                          )
                          .toList();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('استعادة الافتراضي'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (!tempCols.any((c) => c.isVisible)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('يجب إبقاء عمود واحد على الأقل ظاهراً'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, tempCols);
                  },
                  child: const Text('حفظ الترتيب'),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _columns = result;
      });
      await _saveColumns(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ تخصيص الأعمدة بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _studentsRefreshController.dispose();
    _studentsGeneration++;
    super.dispose();
  }

  Future<void> _loadStudentsForDriver(
    int driverId, {
    bool silent = false,
  }) async {
    final generation = ++_studentsGeneration;
    final date = _selectedDate;
    if (!silent) setState(() => _isLoadingStudents = true);
    try {
      final students = await ref
          .read(busRepositoryProvider.notifier)
          .fetchStudentsForDriver(driverId, date: _selectedDate);
      if (mounted &&
          generation == _studentsGeneration &&
          driverId == _selectedDriverId &&
          date == _selectedDate) {
        setState(() {
          _currentStudents = students;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (silent) rethrow;
      if (mounted &&
          generation == _studentsGeneration &&
          driverId == _selectedDriverId &&
          date == _selectedDate) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  void _onDriverSelected(int driverId) {
    setState(() {
      _selectedDriverId = driverId;
      _selectedStudentToLink = null;
    });
    _loadStudentsForDriver(driverId);
  }

  Future<bool> _linkStudentDirectly(int personId, String personName) async {
    if (_selectedDriverId == null) return false;

    final success = await ref
        .read(busRepositoryProvider.notifier)
        .assignStudentToDriver(
          driverId: _selectedDriverId!,
          personId: personId,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم ربط الطالب $personName بالسائق بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _selectedStudentToLink = null;
        });
        _loadStudentsForDriver(_selectedDriverId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ حدث خطأ أثناء ربط الطالب بالسائق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return success;
  }

  Future<void> _linkStudentToCurrentDriver() async {
    if (_selectedDriverId == null || _selectedStudentToLink == null) return;
    await _linkStudentDirectly(
      _selectedStudentToLink!.personId,
      _selectedStudentToLink!.personName,
    );
  }

  Future<void> _unlinkStudent(BusStudentDTO student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تأكيد إلغاء الربط'),
          content: Text(
            'هل تريد إلغاء ربط الطالب "${student.personName}" بهذا السائق؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(busRepositoryProvider.notifier)
        .removeStudentFromDriver(student.personId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم إلغاء ربط الطالب ${student.personName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        if (_selectedDriverId != null) {
          _loadStudentsForDriver(_selectedDriverId!);
        }
      }
    }
  }

  Future<void> _showAddEditDriverDialog([BusDriverDTO? driver]) async {
    final isEdit = driver != null;
    final nameController = TextEditingController(text: driver?.name ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final busNumController = TextEditingController(
      text: driver?.busNumber ?? '',
    );
    final notesController = TextEditingController(text: driver?.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                color: Theme.of(ctx).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'تعديل بيانات السائق' : 'إضافة سائق جديد'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم السائق *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: busNumController,
                    decoration: InputDecoration(
                      labelText: 'رقم الأتوبيس / خط السير (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.directions_bus_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات إضافية (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال اسم السائق')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة السائق'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final repo = ref.read(busRepositoryProvider.notifier);
    bool ok;
    if (isEdit) {
      ok = await repo.updateDriver(
        id: driver.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        busNumber: busNumController.text.trim(),
        notes: notesController.text.trim(),
      );
    } else {
      ok = await repo.addDriver(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        busNumber: busNumController.text.trim(),
        notes: notesController.text.trim(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? '✅ تم حفظ بيانات السائق' : '⚠️ حدث خطأ أثناء الحفظ',
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDriver(BusDriverDTO driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('حذف السائق'),
          content: Text(
            'هل أنت متأكد من حذف السائق "${driver.name}"؟ سيتم فك ربط الطلاب التابعين له.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف السائق'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final ok = await ref
        .read(busRepositoryProvider.notifier)
        .deleteDriver(driver.id);
    if (mounted && ok) {
      if (_selectedDriverId == driver.id) {
        setState(() {
          _selectedDriverId = null;
          _currentStudents = [];
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حذف السائق بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- Printing & Export ---

  Future<DateTime?> _promptDateForPrint(String title) async {
    DateTime chosenDate = _selectedDate;
    final confirmed = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Text(title),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر تاريخ الكشف المراد طباعته (سيتم التحقق من استبعاد الطلاب المنصرفين في هذا التاريخ تحديداً):',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDlgState(() => chosenDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.indigo,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat(
                                  'yyyy-MM-dd (EEEE)',
                                  'ar',
                                ).format(chosenDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, chosenDate),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('تأكيد ومتابعة الطباعة'),
                ),
              ],
            );
          },
        ),
      ),
    );
    return confirmed;
  }

  Future<void> _printCurrentDriver(BusDriverDTO driver) async {
    final printDate = await _promptDateForPrint('طباعة كشف: ${driver.name}');
    if (printDate == null) return;

    final programName =
        ref.read(programNameProvider).asData?.value ?? 'مدارس الأحد';
    final churchName = await ref
        .read(settingsRepositoryProvider)
        .getSetting('church_name');
    final churchLogo = await ref
        .read(settingsRepositoryProvider)
        .getChurchLogo();

    // Fetch fresh students for this driver on the exact specified printDate
    final studentsForDate = await ref
        .read(busRepositoryProvider.notifier)
        .fetchStudentsForDriver(driver.id, date: printDate);

    final pdfDriver = BusDriverPdfData(
      id: driver.id,
      name: driver.name,
      phone: driver.phone,
      busNumber: driver.busNumber,
      notes: driver.notes,
    );

    final pdfStudents = studentsForDate.map((s) {
      return BusStudentPdfData(
        personId: s.personId,
        personName: s.personName,
        stageName: s.stageName,
        khorosName: s.khorosName,
        areaName: s.areaName,
        street: s.street,
        phone: s.phone,
        mobile: s.mobile,
        notes: s.notes,
        hasLeftWithParentToday: s.hasLeftWithParentToday,
        isExcludedFromBusToday: s.isExcludedFromBusToday,
        exclusionReason: s.checkoutTypeToday == 'alone'
            ? 'بمفرده'
            : (s.checkoutTypeToday == 'other'
                  ? (s.checkoutNotesToday != null &&
                            s.checkoutNotesToday!.trim().isNotEmpty
                        ? 'آخر: ${s.checkoutNotesToday!.trim()}'
                        : 'آخر')
                  : (s.checkoutTypeToday == 'parent'
                        ? (s.checkoutNotesToday != null &&
                                  s.checkoutNotesToday!.trim().isNotEmpty
                              ? 'ولي أمر: ${s.checkoutNotesToday!.trim()}'
                              : 'ولي أمر')
                        : null)),
      );
    }).toList();

    await BusPdfService.printDriverPdf(
      driver: pdfDriver,
      students: pdfStudents,
      programName: programName,
      churchName: churchName,
      churchLogo: churchLogo,
      date: printDate,
      customColumns: _columns,
    );
  }

  Future<void> _exportAllDriversToSeparateFiles() async {
    final exportDate = await _promptDateForPrint('تصدير كشوفات كل السائقين');
    if (exportDate == null) return;

    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر المجلد لحفظ ملفات PDF لكل سائق',
    );

    if (selectedDirectory == null || selectedDirectory.isEmpty) return;

    final programName =
        ref.read(programNameProvider).asData?.value ?? 'مدارس الأحد';
    final churchName = await ref
        .read(settingsRepositoryProvider)
        .getSetting('church_name');
    final churchLogo = await ref
        .read(settingsRepositoryProvider)
        .getChurchLogo();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ جاري تصدير ملفات PDF لكل السائقين...'),
        duration: Duration(seconds: 2),
      ),
    );

    final repo = ref.read(busRepositoryProvider.notifier);
    final allDriversMap = await repo.fetchAllDriversWithStudents(
      date: exportDate,
    );

    final pdfMap = <BusDriverPdfData, List<BusStudentPdfData>>{};
    for (final entry in allDriversMap.entries) {
      final d = entry.key;
      final stList = entry.value;

      final pdfDriver = BusDriverPdfData(
        id: d.id,
        name: d.name,
        phone: d.phone,
        busNumber: d.busNumber,
        notes: d.notes,
      );

      final pdfStudents = stList.map((s) {
        return BusStudentPdfData(
          personId: s.personId,
          personName: s.personName,
          stageName: s.stageName,
          khorosName: s.khorosName,
          areaName: s.areaName,
          street: s.street,
          phone: s.phone,
          mobile: s.mobile,
          notes: s.notes,
          hasLeftWithParentToday: s.hasLeftWithParentToday,
          isExcludedFromBusToday: s.isExcludedFromBusToday,
          exclusionReason: s.checkoutTypeToday == 'alone'
              ? 'بمفرده'
              : (s.checkoutTypeToday == 'other'
                    ? (s.checkoutNotesToday != null &&
                              s.checkoutNotesToday!.trim().isNotEmpty
                          ? 'آخر: ${s.checkoutNotesToday!.trim()}'
                          : 'آخر')
                    : (s.checkoutTypeToday == 'parent'
                          ? (s.checkoutNotesToday != null &&
                                    s.checkoutNotesToday!.trim().isNotEmpty
                                ? 'ولي أمر: ${s.checkoutNotesToday!.trim()}'
                                : 'ولي أمر')
                          : null)),
        );
      }).toList();

      pdfMap[pdfDriver] = pdfStudents;
    }

    final targetDir = Directory(selectedDirectory);
    final files = await BusPdfService.exportAllDriversToSeparateFiles(
      targetDir: targetDir,
      driverStudentsMap: pdfMap,
      programName: programName,
      churchName: churchName,
      churchLogo: churchLogo,
      date: exportDate,
      customColumns: _columns,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('تم التصدير بنجاح'),
              ],
            ),
            content: Text(
              'تم تصدير ${files.length} ملف PDF بنجاح بتاريخ ${DateFormat('yyyy-MM-dd').format(exportDate)} في المجلد:\n$selectedDirectory\n\nكل ملف باسم السائق متضمناً الأعمدة المخصصة واستبعاد المنصرفين في هذا التاريخ.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(busRefreshTriggerProvider, (prev, next) {
      _studentsRefreshController.requestRefresh();
      ref.read(busRepositoryProvider.notifier).refreshDrivers();
    });
    ref.listen<int>(domainRevisionProvider(DataDomain.buses), (prev, next) {
      _studentsRefreshController.requestRefresh();
    });
    ref.listen<int>(sourceEpochProvider, (prev, next) {
      _studentsGeneration++;
      _studentsRefreshController.updateEpoch(next);
      setState(() => _currentStudents = []);
      _studentsRefreshController.requestRefresh(immediate: true);
    });

    final driversAsync = ref.watch(busRepositoryProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(driversAsync),
        body: driversAsync.when(
          skipLoadingOnReload: true,
          skipError: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              Center(child: Text('خطأ في تحميل البيانات: $err')),
          data: (drivers) {
            if (_selectedDriverId == null && drivers.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedDriverId == null) {
                  _onDriverSelected(drivers.first.id);
                }
              });
            }

            if (isDesktop) {
              return Row(
                children: [
                  // Drivers List (Right Panel)
                  SizedBox(width: 320, child: _buildDriversListPanel(drivers)),
                  const VerticalDivider(width: 1),
                  // Students & Details (Left Panel)
                  Expanded(child: _buildStudentsPanel(drivers)),
                ],
              );
            } else {
              // Mobile layout
              return Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: _buildDriversListPanel(drivers, isHorizontal: true),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildStudentsPanel(drivers)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<List<BusDriverDTO>> driversAsync,
  ) {
    final drivers = driversAsync.value ?? [];
    final currentDriver = drivers
        .where((d) => d.id == _selectedDriverId)
        .firstOrNull;

    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.directions_bus_filled_rounded, size: 26),
          SizedBox(width: 10),
          Text(
            'الاتوبيسات وتوصيل الطلاب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث الكشف وبيانات الطلاب',
          onPressed: () {
            if (_selectedDriverId != null) {
              _loadStudentsForDriver(_selectedDriverId!);
            }
            ref.invalidate(busRepositoryProvider);
          },
        ),
        // Print / Export Menu Button
        PopupMenuButton<String>(
          tooltip: 'خيارات الطباعة والتصدير',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (action) {
            if (action == 'print_current') {
              if (currentDriver != null) {
                _printCurrentDriver(currentDriver);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار سائق أولاً')),
                );
              }
            } else if (action == 'export_all') {
              _exportAllDriversToSeparateFiles();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'print_current',
              enabled: currentDriver != null,
              child: Row(
                children: [
                  const Icon(
                    Icons.print_rounded,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentDriver != null
                        ? 'طباعة كشف السائق: ${currentDriver.name}'
                        : 'طباعة كشف السائق الحالي',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_all',
              child: Row(
                children: [
                  Icon(Icons.folder_zip_rounded, color: Colors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'تصدير كل السائقين في ملفات PDF منفصلة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'طباعة الكشوفات',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),

        // Customize Columns Button
        OutlinedButton.icon(
          onPressed: _showCustomizeColumnsDialog,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text(
            'تخصيص الأعمدة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            side: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),

        // Add Driver Button
        FilledButton.tonalIcon(
          onPressed: () => _showAddEditDriverDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'إضافة سائق',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDriversListPanel(
    List<BusDriverDTO> drivers, {
    bool isHorizontal = false,
  }) {
    if (drivers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              const Text('لا يوجد سائقين مضافين حتى الآن'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDriverDialog(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة أول سائق'),
              ),
            ],
          ),
        ),
      );
    }

    if (isHorizontal) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: drivers.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final d = drivers[index];
          final isSelected = d.id == _selectedDriverId;
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _onDriverSelected(d.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.08)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.phone ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${d.assignedCount} طالب',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة السائقين',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${drivers.length} سائق',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final d = drivers[index];
                final isSelected = d.id == _selectedDriverId;
                return Card(
                  elevation: isSelected ? 2 : 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  color: isSelected
                      ? Colors.indigo.shade50.withOpacity(0.6)
                      : Colors.white,
                  child: ListTile(
                    onTap: () => _onDriverSelected(d.id),
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade200,
                      foregroundColor: isSelected
                          ? Colors.white
                          : Colors.black87,
                      child: const Icon(Icons.person, size: 20),
                    ),
                    title: Text(
                      d.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (d.phone != null && d.phone!.isNotEmpty)
                          Text(
                            d.phone!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (d.busNumber != null && d.busNumber!.isNotEmpty)
                          Text(
                            'أتوبيس: ${d.busNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${d.assignedCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.indigo.shade900,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showAddEditDriverDialog(d);
                            } else if (val == 'delete') {
                              _deleteDriver(d);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('تعديل', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'حذف',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsPanel(List<BusDriverDTO> drivers) {
    if (_selectedDriverId == null) {
      return const Center(
        child: Text('يرجى اختيار سائق لعرض الطلاب المرتبطين به'),
      );
    }

    final driver = drivers.where((d) => d.id == _selectedDriverId).firstOrNull;
    if (driver == null) {
      return const Center(child: Text('السائق غير موجود'));
    }

    final excludedCount = _currentStudents
        .where((s) => s.isExcludedFromBusToday)
        .length;
    final displayStudents = _showExcludedWithParent
        ? _currentStudents
        : _currentStudents.where((s) => !s.isExcludedFromBusToday).toList();

    return Column(
      children: [
        // Driver Detail Bar & Search / Link Student
        _buildDriverHeaderAndSearch(driver),
        const Divider(height: 1),

        // Excluded notification banner
        if (excludedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade900,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ تم استبعاد $excludedCount طالب تلقائياً من كشف وجدول الأتوبيس اليوم (انصراف لولي الأمر أو لسبب آخر).',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(
                      () => _showExcludedWithParent = !_showExcludedWithParent,
                    );
                  },
                  icon: Icon(
                    _showExcludedWithParent
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                    color: Colors.orange.shade900,
                  ),
                  label: Text(
                    _showExcludedWithParent
                        ? 'إخفاء المستبعدين'
                        : 'عرض المستبعدين',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Students Table
        Expanded(
          child: _isLoadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _buildStudentsTable(displayStudents),
        ),
      ],
    );
  }

  Widget _buildDriverHeaderAndSearch(BusDriverDTO driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'طلاب السائق: ${driver.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (driver.phone != null &&
                            driver.phone!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driver.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (driver.busNumber != null &&
                            driver.busNumber!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.directions_bus,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'أتوبيس: ${driver.busNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    if (_selectedDriverId != null) {
                      _loadStudentsForDriver(_selectedDriverId!);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search & Link Student Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<StudentSearchResult>(
                        displayStringForOption: (option) =>
                            '${option.personName} (كود: ${option.personId})${option.stageName != null ? ' - ${option.stageName}' : ''}',
                        optionsBuilder: (textEditingValue) async {
                          final text = textEditingValue.text.trim();
                          if (text.isEmpty) return const [];
                          return await ref
                              .read(busRepositoryProvider.notifier)
                              .searchAvailableStudents(text);
                        },
                        onSelected: (option) async {
                          await _linkStudentDirectly(
                            option.personId,
                            option.personName,
                          );
                          _searchStudentController?.clear();
                          _searchStudentFocusNode?.requestFocus();
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              _searchStudentController = textEditingController;
                              _searchStudentFocusNode = focusNode;

                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText:
                                      'اكتب اسم الطالب أو الكود واضغط Enter للربط التلقائي...',
                                  hintStyle: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade500,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  suffixIcon:
                                      textEditingController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            textEditingController.clear();
                                            setState(
                                              () =>
                                                  _selectedStudentToLink = null,
                                            );
                                            focusNode.requestFocus();
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (value) async {
                                  final query = value.trim();
                                  if (query.isEmpty) return;
                                  if (_selectedDriverId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى اختيار سائق أولاً'),
                                      ),
                                    );
                                    return;
                                  }

                                  final results = await ref
                                      .read(busRepositoryProvider.notifier)
                                      .searchAvailableStudents(query);

                                  StudentSearchResult? target;
                                  final asId = int.tryParse(query);
                                  if (asId != null) {
                                    target = results
                                        .where((s) => s.personId == asId)
                                        .firstOrNull;
                                  }
                                  target ??= results
                                      .where(
                                        (s) => s.personName.trim() == query,
                                      )
                                      .firstOrNull;
                                  if (target == null && results.length == 1) {
                                    target = results.first;
                                  }

                                  if (target != null) {
                                    await _linkStudentDirectly(
                                      target.personId,
                                      target.personName,
                                    );
                                    textEditingController.clear();
                                    focusNode.requestFocus();
                                  } else if (results.isNotEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'يوجد ${results.length} نتائج، يرجى اختيار الطالب المطلوب من القائمة',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'لم يتم العثور على طالب يطابق "$query"',
                                          ),
                                          backgroundColor:
                                              Colors.orange.shade800,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    focusNode.requestFocus();
                                  }
                                },
                              );
                            },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedStudentToLink != null
                          ? _linkStudentToCurrentDriver
                          : null,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text(
                        'ربط بالسائق',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedStudentToLink != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'طالب محدد: ${_selectedStudentToLink!.personName} (كود: ${_selectedStudentToLink!.personId})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedStudentToLink!.currentDriverName !=
                            null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(مرتبط حالياً بالسائق: ${_selectedStudentToLink!.currentDriverName})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(List<BusStudentDTO> students) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'لا يوجد طلاب مرتبطين بهذا السائق حالياً',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'اكتب اسم الطالب أو كوده في الحقل أعلاه واضغط Enter لربطه مباشرة بالأوتوبيس',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final visibleColumns = _columns.where((c) => c.isVisible).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 12.5,
              ),
              dataRowMaxHeight: 52,
              columns: [
                ...visibleColumns.map(
                  (col) => DataColumn(label: Text(col.label)),
                ),
                const DataColumn(label: Text('حالة الانصراف')),
                const DataColumn(label: Text('إجراء')),
              ],
              rows: students.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final location = [
                  s.areaName,
                  s.street,
                ].where((x) => x != null && x.isNotEmpty).join(' - ');
                final contact = (s.mobile != null && s.mobile!.isNotEmpty)
                    ? s.mobile!
                    : (s.phone ?? '-');

                final cells = <DataCell>[];

                for (final col in visibleColumns) {
                  switch (col.key) {
                    case 'index':
                      cells.add(
                        DataCell(
                          Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 'code':
                      cells.add(
                        DataCell(
                          Text(
                            '${s.personId}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                      break;
                    case 'name':
                      cells.add(
                        DataCell(
                          Text(
                            s.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                      break;
                    case 'stage':
                      cells.add(
                        DataCell(
                          Text(
                            s.stageName ?? '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                      break;
                    case 'khoros':
                      cells.add(
                        DataCell(
                          Text(
                            s.khorosName ?? '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                      break;
                    case 'address':
                      cells.add(
                        DataCell(
                          Text(
                            location.isEmpty ? '-' : location,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                      break;
                    case 'phone':
                      cells.add(
                        DataCell(
                          Text(contact, style: const TextStyle(fontSize: 11)),
                        ),
                      );
                      break;
                    case 'notes':
                      cells.add(
                        DataCell(
                          Text(
                            s.notes ?? '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                      break;
                    case 'delivered':
                      cells.add(
                        DataCell(
                          Checkbox(
                            value: s.isDelivered,
                            activeColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: s.isExcludedFromBusToday
                                ? null
                                : (val) {
                                    setState(
                                      () => s.isDelivered = val ?? false,
                                    );
                                  },
                          ),
                        ),
                      );
                      break;
                    default:
                      cells.add(const DataCell(Text('-')));
                      break;
                  }
                }

                // Dismissal status
                cells.add(
                  DataCell(
                    s.isExcludedFromBusToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: s.hasLeftWithParentToday
                                  ? Colors.orange.shade100
                                  : Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: s.hasLeftWithParentToday
                                    ? Colors.orange.shade300
                                    : Colors.purple.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.hasLeftWithParentToday
                                      ? Icons.family_restroom
                                      : Icons.alt_route_rounded,
                                  size: 12,
                                  color: s.hasLeftWithParentToday
                                      ? Colors.orange.shade900
                                      : Colors.purple.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.hasLeftWithParentToday
                                      ? (s.checkoutNotesToday != null &&
                                                s.checkoutNotesToday!
                                                    .trim()
                                                    .isNotEmpty
                                            ? 'ولي أمر: ${s.checkoutNotesToday!.trim()}'
                                            : 'انصرف لولي الأمر')
                                      : (s.checkoutNotesToday != null &&
                                                s.checkoutNotesToday!
                                                    .trim()
                                                    .isNotEmpty
                                            ? 'آخر: ${s.checkoutNotesToday!.trim()}'
                                            : 'انصرف لسبب آخر'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: s.hasLeftWithParentToday
                                        ? Colors.orange.shade900
                                        : Colors.purple.shade900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            'بالأتوبيس',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                  ),
                );

                // Unlink action
                cells.add(
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.link_off_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      tooltip: 'إلغاء الربط بالسائق',
                      onPressed: () => _unlinkStudent(s),
                    ),
                  ),
                );

                return DataRow(
                  key: ValueKey(s.personId),
                  color: WidgetStateProperty.resolveWith((states) {
                    if (s.isExcludedFromBusToday) {
                      return s.hasLeftWithParentToday
                          ? Colors.orange.shade50
                          : Colors.purple.shade50;
                    }
                    return idx % 2 == 0 ? Colors.white : Colors.grey.shade50;
                  }),
                  cells: cells,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
