import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/areas_repository.dart';

class AreasScreen extends ConsumerStatefulWidget {
  const AreasScreen({super.key});

  @override
  ConsumerState<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends ConsumerState<AreasScreen> {
  final TextEditingController _nameController = TextEditingController();
  Area? _selectedArea;
  int? _selectedParentId;

  // Build a flattened tree where children follow parents
  List<Area> _buildFlattenedTree(List<Area> areas) {
    if (areas.isEmpty) return [];
    final rootAreas = areas.where((a) => a.parentId == null).toList();
    final flattened = <Area>[];

    void traverse(Area parent) {
      flattened.add(parent);
      final children = areas.where((a) => a.parentId == parent.id).toList();
      for (final child in children) {
        traverse(child);
      }
    }

    // Process nodes that have no parent but might be orphaned? Normal cases first:
    for (final root in rootAreas) traverse(root);

    // If there are missed nodes (due to bad data or disconnected components), just append them
    final missed = areas.where((a) => !flattened.any((f) => f.id == a.id)).toList();
    for (final m in missed) flattened.add(m);

    return flattened;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() { 
      _selectedArea = null; 
      _nameController.clear(); 
      _selectedParentId = null;
    });
  }

  void _saveArea() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم المنطقة')));
      return;
    }
    final repo = ref.read(areasRepositoryProvider.notifier);
    bool ok;
    if (_selectedArea == null) {
      ok = await repo.addArea(name, parentId: _selectedParentId);
      if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة بنجاح'))); _clearForm(); }
      if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المنطقة موجودة بالفعل')));
    } else {
      ok = await repo.updateArea(_selectedArea!.id, name);
      if (ok && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث بنجاح (لا يمكن تعديل الوالد حالياً)'))); _clearForm(); }
      if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التحديث')));
    }
  }

  void _deleteArea(Area area) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${area.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      )),
    );
    if (confirm == true) {
      final ok = await ref.read(areasRepositoryProvider.notifier).deleteArea(area.id);
      if (mounted) {
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن الحذف. قد تحتوي المنطقة على أشخاص أو فروع.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
          if (_selectedArea?.id == area.id) _clearForm();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasRepositoryProvider);
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
                          Expanded(child: _buildListCard(areasAsync)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 16),
                            _buildMobileList(areasAsync),
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

  Widget _buildMobileList(AsyncValue<List<Area>> areasAsync) {
    return areasAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا يوجد مناطق مسجلة حالياً'))));
        }
        final flattened = _buildFlattenedTree(list);
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flattened.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = flattened[index];
              final isSelected = _selectedArea?.id == a.id;
              return Padding(
                padding: EdgeInsets.only(right: a.level * 20.0),
                child: ListTile(
                  selected: isSelected,
                  title: Row(
                    children: [
                      if (a.level > 0) const Icon(Icons.subdirectory_arrow_left, size: 16, color: Colors.grey),
                      if (a.level > 0) const SizedBox(width: 4),
                      Text(a.name),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
                        setState(() {
                           _selectedArea = a;
                           _nameController.text = a.name;
                           _selectedParentId = a.parentId;
                        });
                      }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteArea(a)),
                    ],
                  ),
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
          'إدارة المناطق السكنية (شجري)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        Text('تحديد المناطق الجغرافية المتدرجة لتوزيع المخدومين', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                Icon(Icons.account_tree_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  _selectedArea == null ? 'إضافة منطقة جديدة' : 'تعديل بيانات المنطقة',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنطقة / الفرع',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final areasAsync = ref.watch(areasRepositoryProvider);
                return areasAsync.when(
                  data: (areas) {
                    final flattened = _buildFlattenedTree(areas);
                    // Filter out the currently selected area and its descendants if we are editing
                    List<Area> validParents = flattened;
                    if (_selectedArea != null) {
                       validParents = validParents.where((a) => a.id != _selectedArea!.id && !(a.areaPath?.startsWith(_selectedArea!.areaPath ?? '') ?? false)).toList();
                    }

                    return DropdownButtonFormField<int?>(
                      value: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'يتبع لمنطقة (اتركه فارغاً للرئيسي)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('--- منطقة رئيسية (جذر) ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        ...validParents.map((a) {
                          // Visual indent with unicode chars
                          final prefix = String.fromCharCodes(Iterable.generate(a.level * 4, (_) => 0x00A0)); // non-breaking spaces
                          final indent = a.level > 0 ? '└─ ' : '';
                          return DropdownMenuItem<int?>(
                            value: a.id,
                            child: Text('$prefix$indent${a.name}'),
                          );
                        }),
                      ],
                      onChanged: _selectedArea == null ? (val) {
                        setState(() { _selectedParentId = val; });
                      } : null, // Disable changing parent during edit for now
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const Text('خطأ في تحميل المناطق'),
                );
              }
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveArea,
              icon: Icon(_selectedArea == null ? Icons.add_location_alt_outlined : Icons.check),
              label: Text(_selectedArea == null ? 'إضافة' : 'حفظ التغييرات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_selectedArea != null) ...[
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

  Widget _buildListCard(AsyncValue<List<Area>> areasAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text('قائمة المناطق المسجلة (شجري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: areasAsync.when(
                data: (areas) {
                  if (areas.isEmpty) {
                    return const Center(child: Text('لا يوجد مناطق مسجلة حالياً'));
                  }
                  final flattened = _buildFlattenedTree(areas);
                  return ListView.separated(
                    itemCount: flattened.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = flattened[index];
                      final isSelected = _selectedArea?.id == a.id;
                      
                      return Padding(
                        padding: EdgeInsets.only(right: a.level * 24.0),
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: (a.level == 0 ? Colors.blue : Colors.orange).withOpacity(0.1),
                            child: Icon(
                              a.level == 0 ? Icons.map : Icons.location_on, 
                              color: a.level == 0 ? Colors.blue : Colors.orange, 
                              size: 18
                            ),
                          ),
                          title: Row(
                            children: [
                              if (a.level > 0) const Icon(Icons.subdirectory_arrow_left, size: 16, color: Colors.grey),
                              if (a.level > 0) const SizedBox(width: 4),
                              Text(a.name, style: TextStyle(fontWeight: a.level == 0 ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                          subtitle: Text('كود: ${a.id} ${a.areaPath != null ? ' | المسار: ${a.areaPath}' : ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedArea = a;
                                    _nameController.text = a.name;
                                    _selectedParentId = a.parentId;
                                  });
                                },
                                tooltip: 'تعديل',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteArea(a),
                                tooltip: 'حذف',
                              ),
                            ],
                          ),
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
