import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'areas_screen.dart';
import 'users_screen.dart';
import 'stages_screen.dart';
import 'persons_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Dashboard Placeholder')),
    const AreasScreen(),
    const UsersScreen(),
    const StagesScreen(),
    const PersonsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).value;

    if (user == null) {
      // Should ideally be handled by a router, but for simplicity here:
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petros Pols'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Welcome, ${user.username}'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map),
                label: Text('Areas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text('Schools'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_search),
                label: Text('Tracking'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
