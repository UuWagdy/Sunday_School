import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/services_repository.dart';
import '../repositories/settings_repository.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  ConsumerState<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends ConsumerState<ServicesManagementScreen> {
  static const _days = {
    1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس',
    5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
  };

  Uint8List? _churchLogo;
  String? _churchName;
  String? _programName;
  bool _loadedChurchInfo = false;

  @override
  void initState() {
    super.initState();
    _loadChurchInfo();
  }

  Future<void> _loadChurchInfo() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final logo = await settingsRepo.getChurchLogo();
    final name = await settingsRepo.getSetting('church_name');
    final programName = await settingsRepo.getSetting(SettingsRepository.programNameKey);
    final trimmedProgramName = programName?.trim();
    if (mounted) {
      setState(() {
        _churchLogo = logo;
        _churchName = name;
        _programName = trimmedProgramName == null || trimmedProgramName.isEmpty ? null : trimmedProgramName;
        _loadedChurchInfo = true;
      });
    }
  }

  void _showAddEditDialog({ServiceDTO? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int day = existing?.dayOfWeek ?? 4;
    TimeOfDay time = TimeOfDay(hour: existing?.hour ?? 17, minute: existing?.minute ?? 0);
    TimeOfDay? endTime = (existing?.endHour != null && existing?.endMinute != null) 
        ? TimeOfDay(hour: existing!.endHour!, minute: existing!.endMinute!) 
        : null;
    Uint8List? currentLogo = existing?.logo;

    showDialog(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(builder: (ctx, setDlgState) {
          return AlertDialog(
            title: Text(existing == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الخدمة', hintText: 'مثال: مدارس الأحد')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: day, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'اليوم'),
                  items: _days.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDlgState(() => day = v ?? 4),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx, 
                      initialTime: time,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDlgState(() => time = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'ساعة البدء'),
                    child: Text(_formatTimeOfDay(time)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx, 
                      initialTime: endTime ?? const TimeOfDay(hour: 19, minute: 0),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDlgState(() => endTime = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'ساعة النهاية',
                      suffixIcon: endTime != null ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setDlgState(() => endTime = null)) : null,
                    ),
                    child: Text(endTime == null ? 'غير محدد' : _formatTimeOfDay(endTime!)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
                    if (xfile != null) {
                      final bytes = await xfile.readAsBytes();
                      setDlgState(() => currentLogo = bytes);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: currentLogo != null 
                        ? Row(children: [
                            Expanded(child: Image.memory(currentLogo!, fit: BoxFit.contain)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setDlgState(() => currentLogo = null)),
                          ])
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 28, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('لوجو الخدمة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
              FilledButton(onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(c);
                final repo = ref.read(servicesRepositoryProvider.notifier);
                bool ok;
                if (existing == null) {
                  ok = await repo.addService(
                    name: nameCtrl.text.trim(), 
                    dayOfWeek: day, 
                    hour: time.hour, 
                    minute: time.minute, 
                    endHour: endTime?.hour,
                    endMinute: endTime?.minute,
                    logo: currentLogo,
                  );
                } else {
                  ok = await repo.updateService(
                    id: existing.id, 
                    name: nameCtrl.text.trim(), 
                    dayOfWeek: day, 
                    hour: time.hour, 
                    minute: time.minute, 
                    endHour: endTime?.hour,
                    endMinute: endTime?.minute,
                    logo: currentLogo,
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم الحفظ ✅' : 'خطأ في الحفظ'), backgroundColor: ok ? Colors.green : Colors.red));
                }
              }, child: const Text('حفظ')),
            ],
          );
        }),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final period = tod.hour >= 12 ? 'م' : 'ص';
    final h12 = tod.hour % 12 == 0 ? 12 : tod.hour % 12;
    return '${h12.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')} $period';
  }

  void _deleteService(ServiceDTO svc) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حذف الخدمة'),
        content: Text('هل أنت متأكد من حذف "${svc.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ));
    if (ok == true) {
      final success = await ref.read(servicesRepositoryProvider.notifier).deleteService(svc.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'تم الحذف' : 'خطأ')));
    }
  }

  Future<void> _pickChurchLogo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      await ref.read(settingsRepositoryProvider).setChurchLogo(bytes);
      setState(() => _churchLogo = bytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث لوجو الكنيسة ⛪'), backgroundColor: Colors.green));
    }
  }

  Future<void> _deleteChurchLogo() async {
    await ref.read(settingsRepositoryProvider).deleteSetting('church_logo');
    setState(() => _churchLogo = null);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف لوجو الكنيسة'), backgroundColor: Colors.orange));
  }

  Future<void> _editChurchName() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final nameCtrl = TextEditingController(text: _churchName ?? '');
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اسم الكنيسة'),
          content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الكنيسة', hintText: 'مثال: كنيسة رئيس الملائكة ميخائيل')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, nameCtrl.text.trim()), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (result != null) {
      await settingsRepo.saveSetting('church_name', result);
      setState(() => _churchName = result.isEmpty ? null : result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.isEmpty ? 'تم حذف اسم الكنيسة' : 'تم حفظ اسم الكنيسة: $result ✅'), backgroundColor: Colors.green));
    }
  }

  Future<void> _deleteChurchName() async {
    await ref.read(settingsRepositoryProvider).deleteSetting('church_name');
    setState(() => _churchName = null);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف اسم الكنيسة'), backgroundColor: Colors.orange));
  }

  Future<void> _editProgramName() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final nameCtrl = TextEditingController(text: _programName ?? '');
    String? programNameError;
    String? validateProgramName(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return 'الرجاء إدخال اسم البرنامج';
      }
      if (trimmed.length > SettingsRepository.maxProgramNameLength) {
        return 'اسم البرنامج طويل جدًا';
      }
      return null;
    }

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('اسم البرنامج'),
              content: TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'اسم البرنامج',
                  hintText: 'مثال: مدرسة الشمامسة',
                  counterText: '',
                  errorText: programNameError,
                ),
                maxLength: SettingsRepository.maxProgramNameLength,
                onSubmitted: (_) {
                  final error = validateProgramName(nameCtrl.text);
                  if (error != null) {
                    setDlgState(() => programNameError = error);
                    return;
                  }
                  Navigator.pop(c, nameCtrl.text.trim());
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () {
                    final error = validateProgramName(nameCtrl.text);
                    if (error != null) {
                      setDlgState(() => programNameError = error);
                      return;
                    }
                    Navigator.pop(c, nameCtrl.text.trim());
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (result != null) {
      try {
        await settingsRepo.saveProgramName(result);
        ref.invalidate(programNameProvider);
        setState(() => _programName = result.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ اسم البرنامج: ${result.trim()}'), backgroundColor: Colors.green),
          );
        }
      } on ArgumentError {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء إدخال اسم برنامج صحيح'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteProgramName() async {
    await ref.read(settingsRepositoryProvider).deleteProgramName();
    ref.invalidate(programNameProvider);
    setState(() => _programName = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف اسم البرنامج'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          if (isMobile) ...[
            Text('إدارة الخدمات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('خدمة جديدة')),
            ]),
          ] else
            Row(children: [
              Text('إدارة الخدمات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('خدمة جديدة')),
            ]),
          const SizedBox(height: 16),

          // Church info card
          if (_loadedChurchInfo)
            Card(
              elevation: 3,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.account_balance, size: 20, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text('بيانات الكنيسة (تظهر في التقارير)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                  if (isMobile) ...[
                    _buildChurchLogoSection(isMobile: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Colors.transparent)),
                    _buildChurchNameSection(isMobile: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Colors.transparent)),
                    _buildProgramNameSection(isMobile: true),
                  ] else
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(child: _buildChurchLogoSection(isMobile: false)),
                        const VerticalDivider(width: 40, thickness: 1, indent: 4, endIndent: 4),
                        Expanded(child: _buildChurchNameSection(isMobile: false)),
                        const VerticalDivider(width: 40, thickness: 1, indent: 4, endIndent: 4),
                        Expanded(child: _buildProgramNameSection(isMobile: false)),
                      ]),
                    ),
                ]),
              ),
            ),
          const SizedBox(height: 12),

          // Services list
          servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ: $e'),
            data: (services) {
              if (services.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('لا توجد خدمات بعد. أضف خدمة جديدة.')));
              return Column(
                children: services.map((svc) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                      backgroundImage: svc.logo != null ? MemoryImage(svc.logo!) : null,
                      child: svc.logo == null ? Icon(Icons.church, color: Theme.of(context).primaryColor) : null,
                    ),
                    title: Text(svc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${svc.dayName} - من: ${svc.formattedTime} إلى: ${svc.formattedEndTime}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showAddEditDialog(existing: svc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteService(svc)),
                    ]),
                  ),
                )).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildChurchLogoSection({required bool isMobile}) {
    return Row(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            color: Colors.grey.shade50,
          ),
          child: _churchLogo != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_churchLogo!, fit: BoxFit.cover))
              : Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('لوجو الكنيسة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickChurchLogo,
                    icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                    label: Text(_churchLogo != null ? 'تغيير' : 'اختيار', style: const TextStyle(fontSize: 12)),
                  ),
                  if (_churchLogo != null)
                    TextButton.icon(
                      onPressed: _deleteChurchLogo,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('حذف', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChurchNameSection({required bool isMobile}) {
    return Row(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).primaryColor.withAlpha(15),
          ),
          child: Icon(Icons.drive_file_rename_outline_rounded, color: Theme.of(context).primaryColor, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اسم الكنيسة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              Text(
                _churchName ?? 'غير محدد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _churchName != null ? Colors.black87 : Colors.grey.shade400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _editChurchName,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('تعديل', style: TextStyle(fontSize: 12)),
            ),
            if (_churchName != null)
              TextButton.icon(
                onPressed: _deleteChurchName,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('حذف', style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgramNameSection({required bool isMobile}) {
    final displayName = _programName ?? SettingsRepository.defaultProgramName;
    return Row(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).primaryColor.withAlpha(15),
          ),
          child: Icon(Icons.badge_outlined, color: Theme.of(context).primaryColor, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اسم البرنامج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _programName != null ? Colors.black87 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_programName == null) ...[
                const SizedBox(height: 2),
                Text('القيمة الافتراضية', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _editProgramName,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('تعديل', style: TextStyle(fontSize: 12)),
            ),
            if (_programName != null)
              TextButton.icon(
                onPressed: _deleteProgramName,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('حذف', style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }
}
