import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/persons_repository.dart';

class PersonsScreen extends ConsumerStatefulWidget {
  const PersonsScreen({super.key});

  @override
  ConsumerState<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends ConsumerState<PersonsScreen> {
  // We will add tracking features and form fields here later
  // For now, focusing on the Data Table viewing aspect

  void _deletePerson(PersonListDTO person) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete person "${person.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(personsRepositoryProvider.notifier).deletePerson(person.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Person deleted successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete person.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(personsRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: personsAsync.when(
          data: (persons) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Persons & Tracking',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open Add Person dialog
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Person dialog not implemented yet')));
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Person'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Father Details')),
                          DataColumn(label: Text('Stage')),
                          DataColumn(label: Text('Area')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Street')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: persons.map((person) {
                          return DataRow(
                            cells: [
                              DataCell(Text(person.id.toString())),
                              DataCell(Text(person.name)),
                              DataCell(Text(person.fatherName)),
                              DataCell(Text(person.stageName)),
                              DataCell(Text(person.areaName)),
                              DataCell(Text(person.mobile)),
                              DataCell(Text(person.streetName)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      // TODO: Open Edit Person dialog
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Person dialog not implemented yet')));
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deletePerson(person),
                                    tooltip: 'Delete',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.calendar_month, color: Colors.green),
                                    onPressed: () {
                                      // TODO: Open Attendance tracking logic
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance tracking not implemented yet')));
                                    },
                                    tooltip: 'Tracking',
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
