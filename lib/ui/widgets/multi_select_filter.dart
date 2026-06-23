import 'package:flutter/material.dart';

class SelectableItem {
  final dynamic id;
  final String name;
  SelectableItem({required this.id, required this.name});
}

class MultiSelectFilter extends StatelessWidget {
  final String label;
  final List<dynamic> selectedIds;
  final List<SelectableItem> allItems;
  final Function(List<dynamic>) onChanged;
  final String hintText;

  const MultiSelectFilter({
    super.key,
    required this.label,
    required this.selectedIds,
    required this.allItems,
    required this.onChanged,
    this.hintText = 'الكل',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            final result = await showDialog<List<dynamic>>(
              context: context,
              builder: (context) => _MultiSelectDialog(
                title: label,
                items: allItems,
                initialSelectedIds: selectedIds,
              ),
            );
            if (result != null) onChanged(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedIds.isEmpty
                      ? Text(
                          hintText,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        )
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedIds.map((id) {
                            final item = allItems.firstWhere(
                              (it) => it.id == id,
                              orElse: () => SelectableItem(id: id, name: id.toString()),
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Icon(Icons.unfold_more_rounded, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<SelectableItem> items;
  final List<dynamic> initialSelectedIds;

  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.initialSelectedIds,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<dynamic> _selectedIds;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items
        .where((item) => item.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(Icons.checklist_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'بحث سريع...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIds = widget.items.map((e) => e.id).toList()),
                    icon: const Icon(Icons.select_all_rounded, size: 18),
                    label: const Text('تحديد الكل', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIds = []),
                    icon: const Icon(Icons.deselect_rounded, size: 18),
                    label: const Text('إلغاء التحديد', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('لا يوجد نتائج', style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = _selectedIds.contains(item.id);
                          return CheckboxListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              ),
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).primaryColor,
                            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(item.id);
                                } else {
                                  _selectedIds.remove(item.id);
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
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selectedIds),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('تطبيق الفلاتر'),
          ),
        ],
      ),
    );
  }
}
