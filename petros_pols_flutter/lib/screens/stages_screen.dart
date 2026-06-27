import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stages_repository.dart';

class StagesScreen extends ConsumerStatefulWidget {
  const StagesScreen({super.key});

  @override
  ConsumerState<StagesScreen> createState() => _StagesScreenState();
}

class _StagesScreenState extends ConsumerState<StagesScreen> {
  final TextEditingController _nameController = TextEditingController();
  StageModel? _selectedStage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selectedStage = null;
      _nameController.clear();
    });
  }

  void _saveStage() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a stage/school name')));
      return;
    }

    final repo = ref.read(stagesRepositoryProvider.notifier);
    bool success = false;

    if (_selectedStage == null) {
      success = await repo.addStage(name);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage added successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage already exists')));
      }
    } else {
      success = await repo.updateStage(_selectedStage!.id, name);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage updated successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update stage or name already exists')));
      }
    }
  }

  void _deleteStage(StageModel stage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${stage.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(stagesRepositoryProvider.notifier).deleteStage(stage.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stage deleted successfully')));
          if (_selectedStage?.id == stage.id) _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete stage.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesRepositoryProvider);

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
                      _selectedStage == null ? 'Add New Stage / School' : 'Edit Stage / School',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Stage/School Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveStage,
                          icon: const Icon(Icons.save),
                          label: Text(_selectedStage == null ? 'Add' : 'Update'),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedStage != null)
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
              child: stagesAsync.when(
                data: (stages) {
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Existing Stages / Schools',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Stage Name')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: stages.map((stage) {
                          return DataRow(
                            onSelectChanged: (_) {
                              setState(() {
                                _selectedStage = stage;
                                _nameController.text = stage.name;
                              });
                            },
                            cells: [
                              DataCell(Text(stage.id.toString())),
                              DataCell(Text(stage.name)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _selectedStage = stage;
                                        _nameController.text = stage.name;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteStage(stage),
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
