import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/services_repository.dart';
import '../ui/widgets/multi_select_filter.dart';

class KhorosScreen extends ConsumerStatefulWidget {
  const KhorosScreen({super.key});

  @override
  ConsumerState<KhorosScreen> createState() => _KhorosScreenState();
}

class _KhorosScreenState extends ConsumerState<KhorosScreen> {
  final TextEditingController _nameController = TextEditingController();
  KhorosModel? _selected;
  Uint8List? _currentLogo;
  List<int> _selectedServiceIds = [];
  int? get _selectedServiceId =>
      _selectedServiceIds.isEmpty ? null : _selectedServiceIds.first;
  set _selectedServiceId(int? value) {
    _selectedServiceIds = value == null ? [] : [value];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selected = null;
      _nameController.clear();
      _currentLogo = null;
      _selectedServiceIds = [];
    });
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(khorosRepositoryProvider.notifier);
    bool ok;
    if (_selected == null) {
      ok = await repo.addKhoros(
        name,
        logo: _currentLogo,
        serviceIds: _selectedServiceIds,
      );
    } else {
      ok = await repo.updateKhoros(
        _selected!.id,
        name,
        logo: _currentLogo,
        serviceIds: _selectedServiceIds,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'تم الحفظ بنجاح' : 'هذا الخورس موجود مسبقاً'),
        ),
      );
      if (ok) _clearForm();
    }
  }

  void _delete(KhorosModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('حذف خورس "${item.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final success = await ref
          .read(khorosRepositoryProvider.notifier)
          .deleteKhoros(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم الحذف' : 'فشل الحذف، الخورس مرتبط بأشخاص.',
            ),
          ),
        );
        if (_selected?.id == item.id) _clearForm();
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      setState(() => _currentLogo = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(khorosRepositoryProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isWide ? 16 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة الخوارس',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'إضافة، تعديل وحذف خوارس الكنيسة',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 350, child: _buildForm()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildList(dataAsync)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildForm(),
                            const SizedBox(height: 16),
                            _buildList(dataAsync, mobile: true),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final servicesAsync = ref.watch(servicesRepositoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_music,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _selected == null ? 'إضافة خورس' : 'تعديل خورس',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الخورس',
                prefixIcon: Icon(Icons.library_music_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            servicesAsync.when(
              data: (servicesList) {
                return MultiSelectFilter(
                  label: 'الخدمات المرتبطة تلقائيا',
                  hintText: 'بدون خدمات',
                  selectedIds: _selectedServiceIds,
                  allItems: servicesList
                      .map((s) => SelectableItem(id: s.id, name: s.name))
                      .toList(),
                  onChanged: (ids) {
                    setState(() {
                      _selectedServiceIds = ids.cast<int>();
                    });
                  },
                );
                // ignore: dead_code
                return DropdownButtonFormField<int?>(
                  value: _selectedServiceId,
                  decoration: const InputDecoration(
                    labelText: 'الخدمة المرتبطة تلقائياً',
                    prefixIcon: Icon(Icons.group_work_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('بدون خدمة'),
                    ),
                    ...servicesList.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedServiceId = val;
                    });
                  },
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (e, _) => Text('خطأ في تحميل الخدمات: $e'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickLogo,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: _currentLogo != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Image.memory(
                              _currentLogo!,
                              fit: BoxFit.contain,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _currentLogo = null),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 28,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لوجو الخورس',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_selected == null ? Icons.add : Icons.check),
              label: Text(_selected == null ? 'إضافة' : 'حفظ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<KhorosModel>> async, {
    bool mobile = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'قائمة الخوارس',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            mobile
                ? async.when(
                    data: (list) => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _buildTile(list[i]),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('خطأ: $e')),
                  )
                : Expanded(
                    child: async.when(
                      data: (list) => ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _buildTile(list[i]),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('خطأ: $e')),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(KhorosModel t) {
    final servicesList = ref.watch(servicesRepositoryProvider).value ?? [];
    final service = servicesList
        .where((ser) => ser.id == t.serviceId)
        .firstOrNull;

    return ListTile(
      selected: _selected?.id == t.id,
      selectedTileColor: Theme.of(context).primaryColor.withAlpha(12),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
        backgroundImage: t.logo != null ? MemoryImage(t.logo!) : null,
        child: t.logo == null
            ? Icon(
                Icons.library_music,
                color: Theme.of(context).primaryColor,
                size: 18,
              )
            : null,
      ),
      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: service != null
          ? Text(
              'الخدمة: ${service.name}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
            onPressed: () => setState(() {
              _selected = t;
              _nameController.text = t.name;
              _currentLogo = t.logo;
              _selectedServiceIds = List<int>.from(t.serviceIds);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _delete(t),
          ),
        ],
      ),
    );
  }
}
