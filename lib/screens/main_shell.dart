import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/settings_repository.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'areas_screen.dart';
import 'users_screen.dart';
import 'stages_screen.dart';
import 'persons_screen.dart';
import 'attendance_screen.dart';
import 'fathers_screen.dart';
import 'maintenance_screen.dart';
import 'services_management_screen.dart';
import 'id_card_screen.dart';
import 'tayo_screen.dart';
import 'transfer_screen.dart';
import 'khoros_screen.dart';
import 'behavior_screen.dart';
import 'meetings_screen.dart';
import 'monthly_fund_screen.dart';
import 'rohot_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  int? _lastUserId;

  Widget _buildDevCard(
    BuildContext context, {
    required String name,
    required String role,
    required String assetPath,
    required Color color,
    String? phone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final Uri launchUri = Uri(scheme: 'tel', path: phone);
                          try {
                            await launchUrl(
                              launchUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'نسخ الرقم',
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم نسخ الرقم بنجاح',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.content_copy_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String programName) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset('assets/logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    programName,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'إصدار 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10, right: 4),
                      child: Text(
                        'فريق العمل والتطوير:',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  _buildDevCard(
                    context,
                    name: 'م. جورج منير',
                    role: 'برمجة النسخة الأصلية (C#)',
                    assetPath: 'assets/csharp_logo.png',
                    color: const Color(0xFF512BD4),
                  ),
                  const SizedBox(height: 10),
                  _buildDevCard(
                    context,
                    name: 'د. يوساب وجدي',
                    role:
                        'تصميم وتطوير التطبيق الحالي (Flutter)\nلطلب التعديلات والتحديثات',
                    assetPath: 'assets/flutter_logo.png',
                    color: const Color(0xFF02569B),
                    phone: '01036976446',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).value;
    final programName = ref
        .watch(programNameProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => SettingsRepository.defaultProgramName,
        );

    if (user == null) {
      return const LoginScreen();
    }

    // Reset index when user changes
    if (_lastUserId != user.id) {
      _selectedIndex = 0;
      _lastUserId = user.id;
    }

    final filteredNav = _getFilteredNav(user);
    final filteredScreens = filteredNav.map((n) => n.screen).toList();

    // If no permissions at all, show a fallback screen
    if (filteredNav.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(programName)),
        body: const Center(
          child: Text(
            'لا تملك صلاحيات للوصول إلى أي جزء من التطبيق. يرجى مراجعة المسؤول.',
          ),
        ),
      );
    }

    // Clamp index
    if (_selectedIndex >= filteredNav.length) {
      _selectedIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          if (isWide) {
            return _buildDesktopLayout(
              user,
              filteredNav,
              filteredScreens,
              programName,
            );
          } else {
            return _buildMobileLayout(
              user,
              filteredNav,
              filteredScreens,
              programName,
            );
          }
        },
      ),
    );
  }

  List<_NavData> _getFilteredNav(User user) {
    bool granularFeature(String key) {
      final permissions = user.granularPermissions[key];
      return permissions != null && permissions.values.any((value) => value);
    }

    final all = [
      _NavData(
        Icons.analytics,
        'التقارير والتحليلات',
        const DashboardScreen(),
        user.canReports,
      ),
      _NavData(Icons.people, 'الأشخاص', const PersonsScreen(), user.canPersons),
      _NavData(
        Icons.badge,
        'إصدار كارنيه',
        const IdCardScreen(),
        user.canIdCard,
      ),
      _NavData(
        Icons.calendar_month,
        'الحضور',
        const AttendanceScreen(),
        user.canAbsence,
      ),
      _NavData(
        Icons.thumbs_up_down_outlined,
        'السلوك',
        const BehaviorScreen(),
        user.canBehavior,
      ),
      _NavData(
        Icons.groups_3_outlined,
        'الاجتماعات',
        const MeetingsScreen(),
        granularFeature('meetings'),
      ),
      _NavData(
        Icons.diversity_3_outlined,
        'الرهوط',
        const RohotScreen(),
        granularFeature('rohot'),
      ),
      _NavData(
        Icons.savings_outlined,
        'الصندوق الشهري',
        const MonthlyFundScreen(),
        granularFeature('monthlyFund'),
      ),
      _NavData(Icons.card_giftcard, 'الطايو', const TayoScreen(), user.canTayo),
      _NavData(Icons.school, 'المراحل', const StagesScreen(), user.canStages),
      _NavData(Icons.map, 'المناطق', const AreasScreen(), user.canAreas),
      _NavData(
        Icons.church,
        'أباء الإعتراف',
        const FathersScreen(),
        user.canFathers,
      ),
      _NavData(
        Icons.admin_panel_settings,
        'المستخدمين',
        const UsersScreen(),
        user.canUsers,
      ),
      _NavData(
        Icons.swap_horiz,
        'النقل',
        const TransferScreen(),
        user.canTransfer,
      ),
      _NavData(
        Icons.miscellaneous_services,
        'إدارة الخدمات',
        const ServicesManagementScreen(),
        user.canServices,
      ),
      _NavData(
        Icons.library_music,
        'الخوارس',
        const KhorosScreen(),
        user.canKhoros,
      ),
      _NavData(
        Icons.settings,
        'صيانة النظام',
        const MaintenanceScreen(),
        user.canMaintenance,
      ),
    ];
    return all.where((item) => item.enabled).toList();
  }

  Widget _buildDesktopLayout(
    User user,
    List<_NavData> navItems,
    List<Widget> screens,
    String programName,
  ) {
    // Already clamped in build()
    final safeIndex = _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                programName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'حول البرنامج',
            onPressed: () => _showInfoDialog(context, programName),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل خروج',
            onPressed: () => ref.read(authServiceProvider.notifier).logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: safeIndex,
                      onDestinationSelected: (int index) {
                        setState(() => _selectedIndex = index);
                      },
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Image.asset('assets/logo.png', width: 48),
                      ),
                      minWidth: 105,
                      labelType: NavigationRailLabelType.all,
                      useIndicator: true,
                      indicatorColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      selectedLabelTextStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      destinations: navItems
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(
                                item.icon,
                                color: Theme.of(context).primaryColor,
                              ),
                              label: Text(
                                item.label,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: IndexedStack(index: safeIndex, children: screens),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    User user,
    List<_NavData> navItems,
    List<Widget> screens,
    String programName,
  ) {
    final bottomBarCount = 5;
    final bottomItems = navItems.take(bottomBarCount).toList();
    final safeIndex = _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                programName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'حول البرنامج',
            onPressed: () => _showInfoDialog(context, programName),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل خروج',
            onPressed: () => ref.read(authServiceProvider.notifier).logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(child: Image.asset('assets/logo.png')),
                ),
              ),
              accountName: Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                programName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              decoration: const BoxDecoration(color: Color(0xFF1A237E)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: List.generate(navItems.length, (i) {
                  final item = navItems[i];
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: safeIndex == i
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: safeIndex == i ? FontWeight.bold : null,
                        color: safeIndex == i
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    selected: safeIndex == i,
                    selectedTileColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.05),
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('حول التطبيق'),
              onTap: () {
                Navigator.pop(context);
                _showInfoDialog(context, programName);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex < bottomItems.length ? safeIndex : 0,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: bottomItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(
                    item.icon,
                    color: Theme.of(context).primaryColor,
                  ),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  final Widget screen;
  final bool enabled;
  const _NavData(this.icon, this.label, this.screen, this.enabled);
}
