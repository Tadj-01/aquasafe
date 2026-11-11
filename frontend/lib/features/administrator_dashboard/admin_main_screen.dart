import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../administrator_dashboard/admin_dashboard_screen.dart';
import '../leak_map/leak_map_screen.dart';
import '../reports/reports_list_screen.dart';
import '../repair_teams/repair_teams_screen.dart';
import '../settings/settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = [
      AdminDashboardScreen(onNavigateTab: _onTabSelected),
      const LeakMapScreen(),
      const ReportsListScreen(),
      const RepairTeamsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppBranding.pureWhite,
        indicatorColor: isDark
            ? const Color(0xFF0369A1)
            : AppBranding.lightWaterBlue,
        elevation: 2,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: isDark ? Colors.white : AppBranding.primaryBlue,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: Icon(
              Icons.map_rounded,
              color: isDark ? Colors.white : AppBranding.primaryBlue,
            ),
            label: 'Map',
          ),
          NavigationDestination(
            icon: const Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(
              Icons.format_list_bulleted_rounded,
              color: isDark ? Colors.white : AppBranding.primaryBlue,
            ),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: Icon(
              Icons.groups_rounded,
              color: isDark ? Colors.white : AppBranding.primaryBlue,
            ),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: isDark ? Colors.white : AppBranding.primaryBlue,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
