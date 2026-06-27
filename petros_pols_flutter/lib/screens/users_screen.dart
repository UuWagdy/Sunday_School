import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/users_repository.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserModel? _selectedUser;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selectedUser = null;
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  void _saveUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both username and password')));
      return;
    }

    final repo = ref.read(usersRepositoryProvider.notifier);
    bool success = false;

    if (_selectedUser == null) {
      success = await repo.addUser(username, password);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User already exists')));
      }
    } else {
      success = await repo.updateUser(_selectedUser!.id, username, password);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
        _clearForm();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update user or username already exists')));
      }
    }
  }

  void _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete user "${user.username}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(usersRepositoryProvider.notifier).deleteUser(user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully')));
          if (_selectedUser?.id == user.id) _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete user.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersRepositoryProvider);

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
                      _selectedUser == null ? 'Add New User' : 'Edit User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveUser,
                          icon: const Icon(Icons.save),
                          label: Text(_selectedUser == null ? 'Add User' : 'Update User'),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedUser != null)
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
              child: usersAsync.when(
                data: (users) {
                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Existing Users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Password')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: users.map((user) {
                          return DataRow(
                            onSelectChanged: (_) {
                              setState(() {
                                _selectedUser = user;
                                _usernameController.text = user.username;
                                _passwordController.text = user.password;
                              });
                            },
                            cells: [
                              DataCell(Text(user.id.toString())),
                              DataCell(Text(user.username)),
                              DataCell(const Text('********')), // Mask the password in the table view
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _selectedUser = user;
                                        _usernameController.text = user.username;
                                        _passwordController.text = user.password;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteUser(user),
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
