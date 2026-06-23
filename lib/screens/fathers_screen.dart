import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/fathers_repository.dart';

class FathersScreen extends ConsumerStatefulWidget {
  const FathersScreen({super.key});

  @override
  ConsumerState<FathersScreen> createState() => _FathersScreenState();
}

class _FathersScreenState extends ConsumerState<FathersScreen> {
  final TextEditingController _nameController = TextEditingController();
  FatherModel? _selected;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selected = null;
      _nameController.clear();
    });
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الإسم')));
      return;
    }
    final repo = ref.read(fathersRepositoryProvider.notifier);
    bool ok;
    if (_selected == null) {
      ok = await repo.addFather(name);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
        _clearForm();
      }
    } else {
      ok = await repo.updateFather(_selected!.id, name);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
        _clearForm();
      }
    }
  }

  void _delete(FatherModel f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('حذف "${f.name}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (ok == true) {
      final success = await ref.read(fathersRepositoryProvider.notifier).deleteFather(f.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'تم الحذف' : 'فشل الحذف')));
        if (_selected?.id == f.id) _clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(fathersRepositoryProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 350, child: _buildFormCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildListCard(dataAsync)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 16),
                            // On mobile, the list card needs a fixed height or we use a non-expanded version
                            _buildMobileList(dataAsync),
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

  Widget _buildMobileList(AsyncValue<List<FatherModel>> dataAsync) {
    return dataAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا يوجد آباء إعتراف مسجلين حالياً'))));
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = list[index];
              final isSelected = _selected?.id == f.id;
              return ListTile(
                selected: isSelected,
                title: Text(f.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
                      setState(() {
                         _selected = f;
                         _nameController.text = f.name;
                      });
                    }),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(f)),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'آباء الإعتراف',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        Text('إدارة قائمة آباء الإعتراف في الخدمة', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person_add_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  _selected == null ? 'إضافة أب إعتراف' : 'تعديل البيانات',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم أب الإعتراف',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_selected == null ? Icons.add : Icons.check),
              label: Text(_selected == null ? 'إضافة للخدمة' : 'حفظ التعديلات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء التعديل'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(AsyncValue<List<FatherModel>> dataAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue),
                const SizedBox(width: 8),
                Text('القائمة المسجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dataAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('لا يوجد آباء إعتراف مسجلين حالياً'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final f = list[index];
                      final isSelected = _selected?.id == f.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text('${index + 1}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('كود تعريفي: ${f.id}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selected = f;
                                  _nameController.text = f.name;
                                });
                              },
                              tooltip: 'تعديل',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _delete(f),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ في التحميل: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
