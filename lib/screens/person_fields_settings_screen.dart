import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/fields_repository.dart';

class PersonFieldsSettingsScreen extends ConsumerStatefulWidget {
  const PersonFieldsSettingsScreen({super.key});

  @override
  ConsumerState<PersonFieldsSettingsScreen> createState() =>
      _PersonFieldsSettingsScreenState();
}

class _PersonFieldsSettingsScreenState
    extends ConsumerState<PersonFieldsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsRepositoryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          elevation: 24,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 16 : 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: isMobile ? screenWidth * 0.95 : 700,
            height: isMobile ? MediaQuery.of(context).size.height * 0.9 : 850,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: fieldsAsync.when(
                    data: (fields) => _buildFieldsList(fields, isMobile),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
                _buildFooter(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withBlue(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_suggest_rounded,
              color: Colors.white,
              size: isMobile ? 22 : 28,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات خانات المخدومين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'تخصيص وترتيب البيانات الإضافية',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList(List<FieldConfigDTO> fields, bool isMobile) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        itemCount: fields.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final List<FieldConfigDTO> reordered = List.from(fields);
          final item = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);
          ref.read(fieldsRepositoryProvider.notifier).reorderFields(reordered);
        },
        itemBuilder: (context, index) {
          final f = fields[index];
          return _buildFieldItem(f, isMobile);
        },
      ),
    );
  }

  Widget _buildFieldItem(FieldConfigDTO f, bool isMobile) {
    IconData typeIcon = Icons.text_fields;
    Color typeColor = Colors.blue;
    if (f.type == 'dropdown') {
      typeIcon = Icons.arrow_drop_down_circle_outlined;
      typeColor = Colors.orange;
    } else if (f.type == 'multi_select') {
      typeIcon = Icons.checklist_rtl_outlined;
      typeColor = Colors.purple;
    } else if (f.type == 'checkbox') {
      typeIcon = Icons.check_box_outlined;
      typeColor = Colors.teal;
    } else if (f.type == 'document') {
      typeIcon = Icons.attach_file;
      typeColor = Colors.brown;
    } else if (f.type == 'native') {
      typeIcon = Icons.vpn_key_outlined;
      typeColor = Colors.grey;
    }

    final bool isNative = f.fieldKey != null;

    return Container(
      key: ValueKey(f.id),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: typeColor),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.fromLTRB(
                    isMobile ? 4 : 12,
                    isMobile ? 4 : 8,
                    isMobile ? 12 : 20,
                    isMobile ? 4 : 8,
                  ),
                  leading: Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    f.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 14 : 16,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (f.isFilter)
                          _buildChip(
                            Icons.filter_alt_rounded,
                            'فلتر',
                            Colors.green,
                            isMobile,
                          ),
                        if (f.isPhone)
                          _buildChip(
                            Icons.phone_rounded,
                            'رقم هاتف',
                            Colors.indigo,
                            isMobile,
                          ),
                        if (!f.isVisible)
                          _buildChip(
                            Icons.visibility_off_rounded,
                            'مخفي',
                            Colors.red,
                            isMobile,
                          ),
                        Text(
                          isNative ? 'نظام' : 'مخصص',
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 11,
                            color: Colors.blueGrey.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        Icons.edit_rounded,
                        Colors.indigo,
                        () => _showEditFieldDialog(f),
                        'تعديل',
                        isMobile,
                      ),
                      if (!isNative)
                        _buildActionButton(
                          Icons.delete_outline_rounded,
                          Colors.red,
                          () => _deleteField(f),
                          'حذف',
                          isMobile,
                        ),
                      if (isNative)
                        _buildActionButton(
                          f.isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          f.isVisible ? Colors.teal : Colors.blueGrey,
                          () => ref
                              .read(fieldsRepositoryProvider.notifier)
                              .updateFieldVisibility(f.id, !f.isVisible),
                          'رؤية',
                          isMobile,
                        ),
                      if (!isMobile) const SizedBox(width: 4),
                      Icon(
                        Icons.drag_indicator_rounded,
                        color: Colors.black12,
                        size: isMobile ? 20 : 24,
                      ),
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

  Widget _buildChip(
    IconData icon,
    String label,
    MaterialColor color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 10 : 12, color: color.shade700),
          SizedBox(width: isMobile ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 8 : 10,
              color: color.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
    bool isMobile,
  ) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        padding: isMobile ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
        constraints: isMobile ? const BoxConstraints() : null,
        icon: Icon(icon, size: isMobile ? 18 : 20, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        splashRadius: isMobile ? 18 : 24,
        style: IconButton.styleFrom(hoverColor: color.withOpacity(0.08)),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _showAddFieldDialog,
              icon: Icon(Icons.add, size: isMobile ? 18 : 20),
              label: Text(
                'إضافة خانة مخصصة',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 16),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 16),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'إغلاق',
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteField(FieldConfigDTO f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف خانة'),
        content: Text(
          'هل أنت متأكد من حذف الخانة "${f.name}"؟ سيتم حذف بياناتها من كل المخدومين.',
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
      await ref.read(fieldsRepositoryProvider.notifier).deleteCustomField(f.id);
    }
  }

  void _showEditFieldDialog(FieldConfigDTO f) {
    _showFieldDialog(f: f);
  }

  void _showAddFieldDialog() {
    _showFieldDialog();
  }

  void _showFieldDialog({FieldConfigDTO? f}) {
    final nameC = TextEditingController(text: f?.name);
    String type = f?.type ?? 'text';
    final List<String> options = List.from(f?.options ?? []);
    bool isFilter = f?.isFilter ?? false;
    bool isVisible = f?.isVisible ?? true;
    bool isPhone = f?.isPhone ?? false;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            title: Text(f == null ? 'إضافة خانة مخصصة' : 'تعديل خانة'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: 'اسم الخانة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'نوع الخانة',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'text',
                          child: Text('كتابة نصية'),
                        ),
                        const DropdownMenuItem(
                          value: 'dropdown',
                          child: Text('قائمة منسدلة (اختيار واحد)'),
                        ),
                        const DropdownMenuItem(
                          value: 'multi_select',
                          child: Text('قائمة منسدلة (اختيار متعدد)'),
                        ),
                        const DropdownMenuItem(
                          value: 'checkbox',
                          child: Text('مربع اختيار (نعم/لا)'),
                        ),
                        const DropdownMenuItem(
                          value: 'document',
                          child: Text('مستندات (ملفات)'),
                        ),
                        if (f?.type == 'native')
                          const DropdownMenuItem(
                            value: 'native',
                            child: Text('حقل نظام أساسي'),
                          ),
                      ],
                      onChanged: f?.fieldKey != null
                          ? null
                          : (v) => setDlgState(() {
                              type = v!;
                              if (type != 'text') isPhone = false;
                            }),
                    ),

                    if (type == 'text' && f?.fieldKey == null) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('هذا رقم هاتف'),
                        subtitle: const Text(
                          'عند تحديدها يظهر لهذه الخانة أعمدة اتصال وواتساب في تقارير الأشخاص والحضور والافتقاد.',
                        ),
                        value: isPhone,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setDlgState(() => isPhone = v ?? false),
                      ),
                    ],

                    if (type == 'dropdown' || type == 'multi_select') ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تسمية الحالات والاختيارات:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _addOption(setDlgState, options),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text('إضافة اختيار'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: options.isEmpty
                            ? const Center(
                                child: Text(
                                  'لا توجد اختيارات بعد',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: options.length,
                                itemBuilder: (ctx, i) => ListTile(
                                  dense: true,
                                  title: Text(options[i]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _editOption(
                                          setDlgState,
                                          options,
                                          i,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => setDlgState(
                                          () => options.removeAt(i),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text(
                        'هل تريد ظهور فلتر خاص بها في تبويب الحضور وتحليل البيانات؟',
                      ),
                      value: isFilter,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) =>
                          setDlgState(() => isFilter = v ?? false),
                    ),
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
                onPressed: () async {
                  if (nameC.text.trim().isEmpty) return;

                  bool ok;
                  if (f == null) {
                    ok = await ref
                        .read(fieldsRepositoryProvider.notifier)
                        .addCustomField(
                          name: nameC.text.trim(),
                          type: type,
                          options: type == 'text' ? null : options,
                          isFilter: isFilter,
                          isPhone: isPhone,
                        );
                  } else {
                    ok = await ref
                        .read(fieldsRepositoryProvider.notifier)
                        .updateCustomField(
                          id: f.id,
                          name: nameC.text.trim(),
                          type: type,
                          options: type == 'text' ? null : options,
                          isFilter: isFilter,
                          isVisible: isVisible,
                          isPhone: isPhone,
                        );
                  }
                  if (mounted && ok) Navigator.pop(context);
                },
                child: Text(f == null ? 'إضافة' : 'حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addOption(
    void Function(void Function()) setDlgState,
    List<String> options,
  ) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة اختيار جديد'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب الاختيار هنا...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                setDlgState(() => options.add(c.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editOption(
    void Function(void Function()) setDlgState,
    List<String> options,
    int index,
  ) {
    final c = TextEditingController(text: options[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاختيار'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اكتب الاختيار الجديد...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                setDlgState(() => options[index] = c.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
