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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selectedArea = null;
      _nameController.clear();
    });
  }

  void _saveArea() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an area name')));
      return;
    }

    final repo = ref.read(areasRepositoryProvider.notifier);
    bool success = false;

    if (_selectedArea == null) {
      success = await repo.addArea(name);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area added successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area already exists')));
      }
    } else {
      success = await repo.updateArea(_selectedArea!.id, name);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area updated successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update area or name already exists')));
      }
    }
  }

  void _deleteArea(Area area) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${area.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(areasRepositoryProvider.notifier).deleteArea(area.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Area deleted successfully')));
          if (_selectedArea?.id == area.id) _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete area; it might be in use by persons.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Form
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedArea == null ? 'Add New Area' : 'Edit Area',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Area Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveArea,
                          icon: const Icon(Icons.save),
                          label: Text(_selectedArea == null ? 'Add' : 'Update'),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedArea != null)
                          TextButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Edit'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right side: Data Table
          Expanded(
            flex: 2,
            child: Card(
              child: areasAsync.when(
                data: (areas) {
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Existing Areas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Area Name')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: areas.map((area) {
                          return DataRow(
                            onSelectChanged: (_) {
                              setState(() {
                                _selectedArea = area;
                                _nameController.text = area.name;
                              });
                            },
                            cells: [
                              DataCell(Text(area.id.toString())),
                              DataCell(Text(area.name)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _selectedArea = area;
                                        _nameController.text = area.name;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteArea(area),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
