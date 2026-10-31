import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';
import '../services/auth_service.dart';
import '../ui/dialogs/server_connection_dialog.dart';
import '../widgets/theme_toggle_button.dart';

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
      final success = await ref
          .read(authServiceProvider.notifier)
          .login(selectedUser!, _passwordController.text);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الدخول بنجاح!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('كلمة مرور أو مستخدم غير صحيح.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final programName =
        ref.watch(programNameProvider).value ??
        SettingsRepository.defaultProgramName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF090D16),
                      Color.alphaBlend(
                        primary.withValues(alpha: 0.22),
                        const Color(0xFF111827),
                      ),
                    ]
                  : [
                      primary,
                      Color.alphaBlend(
                        Colors.indigo.withValues(alpha: 0.35),
                        primary,
                      ),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Top Action Bar: Server Connection on Left, Theme Toggle on Right (never overlap)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ServerConnectionStatusButton(
                          compact: isMobile,
                          darkBackground: true,
                        ),
                        const ThemeToggleButton(
                          compact: true,
                          darkBackground: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildLogo(programName),
                        const SizedBox(height: 28),
                        _buildLoginCard(usersAsync, authState),
                        const SizedBox(height: 20),
                        Text(
                          programName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(String programName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          programName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    AsyncValue<List<User>> usersAsync,
    AsyncValue<User?> authState,
  ) {
    return Card(
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        width: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'إعدادات الاتصال بالسيرفر والمزامنة',
                  onPressed: () => ServerConnectionDialog.show(context),
                  icon: Icon(
                    Icons.settings_ethernet_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى اختيار المستخدم وإدخال كلمة المرور',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            usersAsync.when(
              skipLoadingOnReload: true,
              skipError: true,
              data: (users) {
                final validSelection =
                    users.any((u) => u.username == selectedUser)
                    ? selectedUser
                    : null;
                if (selectedUser != validSelection) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => selectedUser = null);
                  });
                }

                return DropdownButtonFormField<String>(
                  key: ValueKey(validSelection),
                  initialValue: validSelection,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: users.map((user) {
                    return DropdownMenuItem(
                      value: user.username,
                      child: Text(user.username),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedUser = value),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) {
                print('LoginScreen Users Error: $e');
                print(st);
                return Column(
                  children: [
                    Text(
                      'خطأ في تحميل البيانات: $e',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(allUsersProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'دخول للنظام',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
