import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stages_repository.dart';
import '../repositories/services_repository.dart';
import '../ui/widgets/multi_select_filter.dart';

class StagesScreen extends ConsumerStatefulWidget {
  const StagesScreen({super.key});

  @override
  ConsumerState<StagesScreen> createState() => _StagesScreenState();
}

class _ServiceName {
  const _ServiceName(this.name);
  final String name;
}

class _StagesScreenState extends ConsumerState<StagesScreen> {
  final TextEditingController _nameController = TextEditingController();
  StageModel? _selectedStage;
  List<int> _selectedServiceIds = [];
  final Set<int> _selectedBulkStageIds = {};
  List<int> _bulkStageServiceIds = [];
  bool _isBulkSaving = false;
  int? get _selectedServiceId =>
      _selectedServiceIds.isEmpty ? null : _selectedServiceIds.first;
  set _selectedServiceId(int? value) {
    _selectedServiceIds = value == null ? [] : [value];
  }

  int? _selectedNextStageId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selectedStage = null;
      _nameController.clear();
      _selectedServiceIds = [];
      _selectedNextStageId = null;
    });
  }

  void _clearBulkSelection() {
    setState(() {
      _selectedBulkStageIds.clear();
      _bulkStageServiceIds = [];
    });
  }

  void _toggleSelectAll(List<StageModel> list) {
    final ids = list.map((item) => item.id).toSet();
    final allSelected =
        ids.isNotEmpty && ids.every((id) => _selectedBulkStageIds.contains(id));
    setState(() {
      if (allSelected) {
        _selectedBulkStageIds.removeAll(ids);
      } else {
        _selectedBulkStageIds.addAll(ids);
      }
    });
  }

  Future<void> _applyBulkServices() async {
    if (_selectedBulkStageIds.isEmpty || _isBulkSaving) return;
    setState(() => _isBulkSaving = true);
    try {
      final count = await ref
          .read(stagesRepositoryProvider.notifier)
          .updateStageServicesForIds(
            _selectedBulkStageIds,
            _bulkStageServiceIds,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم ربط الخدمات بـ $count مرحلة')));
      _clearBulkSelection();
    } finally {
      if (mounted) setState(() => _isBulkSaving = false);
    }
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الإسم')));
      return;
    }
    final repo = ref.read(stagesRepositoryProvider.notifier);
    bool ok;
    if (_selectedStage == null) {
      ok = await repo.addStage(
        name,
        serviceIds: _selectedServiceIds,
        nextStageId: _selectedNextStageId,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
        _clearForm();
      }
      if (!ok && mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('موجود بالفعل')));
    } else {
      ok = await repo.updateStage(
        _selectedStage!.id,
        name,
        serviceIds: _selectedServiceIds,
        nextStageId: _selectedNextStageId,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم التحديث')));
        _clearForm();
      }
      if (!ok && mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل التحديث')));
    }
  }

  void _delete(StageModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('حذف "${s.name}"؟'),
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
          .read(stagesRepositoryProvider.notifier)
          .deleteStage(s.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? 'تم الحذف' : 'فشل')));
        if (_selectedStage?.id == s.id) _clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stagesRepositoryProvider);
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
                          Expanded(child: _buildListCard(async)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 16),
                            _buildMobileList(async),
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

  Widget _buildMobileList(AsyncValue<List<StageModel>> async) {
    final servicesList = ref.watch(servicesRepositoryProvider).value ?? [];
    final stagesList = async.value ?? [];

    return async.when(
      data: (list) {
        if (list.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('لا يوجد مراحل مسجلة حالياً')),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildBulkServicesBar(list, servicesList),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = list[index];
                    final isSelected = _selectedStage?.id == s.id;
                    final linkedServices = servicesList
                        .where((ser) => s.serviceIds.contains(ser.id))
                        .map((ser) => ser.name)
                        .toList();
                    final service = linkedServices.isEmpty
                        ? null
                        : _ServiceName(linkedServices.join('، '));
                    final nextStage = stagesList
                        .where((st) => st.id == s.nextStageId)
                        .firstOrNull;

                    return ListTile(
                      selected: isSelected,
                      leading: Checkbox(
                        value: _selectedBulkStageIds.contains(s.id),
                        visualDensity: VisualDensity.compact,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedBulkStageIds.add(s.id);
                            } else {
                              _selectedBulkStageIds.remove(s.id);
                            }
                          });
                        },
                      ),
                      title: Text(s.name),
                      subtitle: (service != null || nextStage != null)
                          ? Text(
                              '${service != null ? "الخدمة: ${service.name}" : ""}${service != null && nextStage != null ? " • " : ""}${nextStage != null ? "التالية: ${nextStage.name}" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _selectedStage = s;
                                _nameController.text = s.name;
                                _selectedServiceIds = List<int>.from(
                                  s.serviceIds,
                                );
                                _selectedNextStageId = s.nextStageId;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
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
          'إدارة المراحل الدراسية',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          'إدارة قائمة المراحل التعليمية والمدارس التابعة للخدمة',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBulkServicesBar(
    List<StageModel> list,
    List<ServiceDTO> servicesList,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();
    final allSelected = list.every(
      (item) => _selectedBulkStageIds.contains(item.id),
    );
    final selectedCount = list
        .where((item) => _selectedBulkStageIds.contains(item.id))
        .length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selectedCount == 0 ? Colors.grey.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedCount == 0
              ? Colors.grey.shade200
              : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _toggleSelectAll(list),
                icon: Icon(
                  allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                ),
                label: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
              ),
              if (selectedCount > 0)
                Chip(
                  label: Text('$selectedCount مرحلة محددة'),
                  visualDensity: VisualDensity.compact,
                ),
              if (selectedCount > 0)
                IconButton(
                  onPressed: _clearBulkSelection,
                  icon: const Icon(Icons.close),
                  tooltip: 'مسح التحديد',
                ),
            ],
          ),
          if (selectedCount > 0) ...[
            const SizedBox(height: 8),
            MultiSelectFilter(
              label: 'الخدمات التي سيتم ربطها بالمحدد',
              hintText: 'بدون خدمات',
              selectedIds: _bulkStageServiceIds,
              allItems: servicesList
                  .map((s) => SelectableItem(id: s.id, name: s.name))
                  .toList(),
              onChanged: (ids) {
                setState(() => _bulkStageServiceIds = ids.cast<int>());
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isBulkSaving ? null : _applyBulkServices,
              icon: _isBulkSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: const Text('ربط الخدمات بالمحدد'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final stagesAsync = ref.watch(stagesRepositoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedStage == null
                        ? 'إضافة مرحلة جديدة'
                        : 'تعديل بيانات المرحلة',
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
                  labelText: 'اسم المرحلة أو المدرسة',
                  prefixIcon: Icon(Icons.edit_note_outlined),
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
              stagesAsync.when(
                data: (stagesList) {
                  final filteredStages = stagesList
                      .where(
                        (s) =>
                            _selectedStage == null ||
                            s.id != _selectedStage!.id,
                      )
                      .toList();
                  return DropdownButtonFormField<int?>(
                    value: _selectedNextStageId,
                    decoration: const InputDecoration(
                      labelText: 'المرحلة التالية (للترقية)',
                      prefixIcon: Icon(Icons.arrow_forward_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('تخرج / نهاية المراحل'),
                      ),
                      ...filteredStages.map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedNextStageId = val;
                      });
                    },
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('خطأ في تحميل المراحل: $e'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_selectedStage == null ? Icons.add : Icons.check),
                label: Text(
                  _selectedStage == null ? 'إضافة للخدمة' : 'حفظ التعديلات',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_selectedStage != null) ...[
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
      ),
    );
  }

  Widget _buildListCard(AsyncValue<List<StageModel>> async) {
    final servicesList = ref.watch(servicesRepositoryProvider).value ?? [];
    final stagesList = async.value ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_list_bulleted, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'قائمة المراحل المسجلة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            async.maybeWhen(
              data: (list) => _buildBulkServicesBar(list, servicesList),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('لا يوجد مراحل دراسية مسجلة حالياً'),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = list[index];
                      final isSelected = _selectedStage?.id == s.id;
                      final linkedServices = servicesList
                          .where((ser) => s.serviceIds.contains(ser.id))
                          .map((ser) => ser.name)
                          .toList();
                      final service = linkedServices.isEmpty
                          ? null
                          : _ServiceName(linkedServices.join('، '));
                      final nextStage = stagesList
                          .where((st) => st.id == s.nextStageId)
                          .firstOrNull;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.05),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedBulkStageIds.contains(s.id),
                              visualDensity: VisualDensity.compact,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedBulkStageIds.add(s.id);
                                  } else {
                                    _selectedBulkStageIds.remove(s.id);
                                  }
                                });
                              },
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${s.id}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (service != null || nextStage != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (service != null) ...[
                                    Icon(
                                      Icons.group_work_outlined,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      service.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (nextStage != null)
                                      const Text(
                                        ' • ',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                  ],
                                  if (nextStage != null) ...[
                                    Icon(
                                      Icons.arrow_forward_outlined,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      nextStage.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedStage = s;
                                  _nameController.text = s.name;
                                  _selectedServiceIds = List<int>.from(
                                    s.serviceIds,
                                  );
                                  _selectedNextStageId = s.nextStageId;
                                });
                              },
                              tooltip: 'تعديل',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _delete(s),
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
