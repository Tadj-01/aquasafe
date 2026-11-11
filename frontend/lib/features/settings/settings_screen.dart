import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/branding/app_branding.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/administrator.dart';
import '../home/home_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';
import 'admin_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Administrator? _currentAdmin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final admin = await AuthService.getCurrentAdmin();
    if (mounted) {
      setState(() {
        _currentAdmin = admin;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (_currentAdmin != null) {
                          final updated = await Navigator.push<Administrator>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminProfileScreen(admin: _currentAdmin!),
                            ),
                          );
                          if (updated != null) {
                            setState(() => _currentAdmin = updated);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0369A1)
                                    : AppBranding.primaryBlue.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _currentAdmin?.name.isNotEmpty == true
                                      ? _currentAdmin!.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppBranding.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _currentAdmin?.name ?? 'Administrator',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_currentAdmin?.isSupervisor == true) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_user_rounded,
                                          size: 16,
                                          color: Colors.purple,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentAdmin?.email ?? 'admin@aquasafe.dz',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppBranding.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _currentAdmin?.isSupervisor == true
                                              ? Colors.purple.withOpacity(0.12)
                                              : AppBranding.lightWaterBlue,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Role: ${_currentAdmin?.role ?? "ADMIN"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _currentAdmin?.isSupervisor == true
                                                ? Colors.purple
                                                : AppBranding.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppBranding.secondaryText),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Supervisor Console Button (Only visible for SUPERVISOR)
                  if (_currentAdmin?.isSupervisor == true) ...[
                    const Text(
                      'Supervisor Governance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: isDark
                          ? const Color(0xFF1E1B4B)
                          : const Color(0xFFF3E8FF),
                      child: ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.purple,
                          size: 30,
                        ),
                        title: const Text(
                          'Supervisor Authority Console',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.purple,
                          ),
                        ),
                        subtitle: const Text(
                          'Manage administrators, approve new applicants, and oversee permissions.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.purple),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupervisorDashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Preferences Section (Dark Theme Toggle)
                  const Text(
                    'Preferences & Appearance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppBranding.primaryBlue,
                      ),
                      title: const Text(
                        'Dark Theme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isDark
                            ? 'High contrast dark theme enabled'
                            : 'Standard light water palette enabled',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isDark,
                      activeColor: AppBranding.primaryBlue,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Application & System Information
                  const Text(
                    'Application & System Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.water_drop_outlined,
                          title: 'Application Working Name',
                          subtitle: AppBranding.appName,
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.public,
                          title: 'Geographic Provider',
                          subtitle: 'Syscli Algeria (69 Wilayas, 1541 Communes)',
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.map_outlined,
                          title: 'Mapping Engine',
                          subtitle: 'OpenStreetMap (flutter_map) + OSRM Routing',
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.dns_outlined,
                          title: 'Backend API Server',
                          subtitle: ApiConstants.baseUrl,
                        ),
                        const Divider(),
                        _buildSettingTile(
                          icon: Icons.info_outline,
                          title: 'Version',
                          subtitle: 'v1.1.0 (Supervisor Governance Architecture)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppBranding.statusUnderRepair, size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppBranding.statusUnderRepair,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppBranding.statusUnderRepair,
                          width: 1.5,
                        ),
                      ),
                      onPressed: _handleLogout,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppBranding.primaryBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppBranding.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
