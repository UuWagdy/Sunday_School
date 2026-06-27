import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../database/database.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? selectedUser;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (selectedUser != null && _passwordController.text.isNotEmpty) {
      final success = await ref.read(authServiceProvider.notifier).login(selectedUser!, _passwordController.text);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid password or user.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final usersAsync = ref.watch(allUsersProvider);
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Card(
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(32.0),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.church, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Petros Pols',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                usersAsync.when(
                  data: (users) {
                    // Update selected user if current selection is invalid
                    if (selectedUser != null && !users.any((u) => u.username == selectedUser)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => selectedUser = null);
                      });
                    }
                    
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedUser,
                      items: users.map((user) {
                        return DropdownMenuItem(
                          value: user.username,
                          child: Text(user.username),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUser = value;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error loading users: $e'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _login,
                    child: authState.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
