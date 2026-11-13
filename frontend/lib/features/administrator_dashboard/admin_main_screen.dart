import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supervisor_service.dart';
import '../administrator_dashboard/admin_dashboard_screen.dart';
import '../leak_map/leak_map_screen.dart';
import '../reports/reports_list_screen.dart';
import '../repair_teams/repair_teams_screen.dart';
import '../settings/settings_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  bool _isSupervisor = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkSupervisorStatus();
  }

  Future<void> _checkSupervisorStatus() async {
    final admin = await AuthService.getCurrentAdmin();
    if (admin != null && admin.isSupervisor) {
      int count = 0;
      try {
        count = await SupervisorService.getPendingCount();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSupervisor = true;
          _pendingCount = count;
        });
      }
    }
  }

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
      if (_isSupervisor) const SupervisorDashboardScreen(),
      const SettingsScreen(),
    ];

    // Ensure _currentIndex is within bounds
    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : AppBranding.pureWhite,
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
          if (_isSupervisor)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _pendingCount > 0,
                label: Text('$_pendingCount'),
                backgroundColor: Colors.red,
                child: const Icon(Icons.admin_panel_settings_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: _pendingCount > 0,
                label: Text('$_pendingCount'),
                backgroundColor: Colors.red,
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.purple,
                ),
              ),
              label: 'Supervisor',
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
