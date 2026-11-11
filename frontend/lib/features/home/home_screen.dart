import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../shared/widgets/app_logo.dart';
import '../citizen_report/report_leak_screen.dart';
import '../administrator_auth/admin_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Centralized Branding Logo Space & Name Placeholder
                  const AppLogo(
                    size: 80,
                    showText: true,
                  ),

                  const SizedBox(height: 18),

                  // Welcome message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppBranding.citizenWelcome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppBranding.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Main Call to Action: Report a Leak
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt_rounded, size: 22),
                      label: const Text(
                        'Report a Leak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppBranding.primaryBlue,
                        foregroundColor: AppBranding.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportLeakScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secondary Action: Administrator Login
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      label: const Text(
                        'Administrator Login',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppBranding.cardBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Citizen privacy note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: AppBranding.secondaryText.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Anonymous reporting • No account required',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppBranding.secondaryText.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
