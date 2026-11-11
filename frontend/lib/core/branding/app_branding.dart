import 'package:flutter/material.dart';

/// Centralized branding configuration for the application.
/// Allows the client to change the application name, logo, colors,
/// and tagline globally from this single source without refactoring screens.
class AppBranding {
  // Working application name
  static const String appName = 'AquaSafe';

  // Tagline / subtitle
  static const String appTagline =
      'Mobile Water Leak Reporting & Network Management';

  // Short welcome message for citizens
  static const String citizenWelcome =
      'Help preserve Algeria\'s drinking water by reporting leaks directly to the water distribution authority.';

  // Logo Configurations
  static const String? assetLogoPath = 'assets/images/logo.jpg';
  static const String assetSplashLogoPath = 'assets/images/logo_outside.jpg';

  // Primary color palette
  static const Color primaryBlue = Color(0xFF1677C8);
  static const Color deepNavy = Color(0xFF123B5D);
  static const Color lightWaterBlue = Color(0xFFEAF6FC);
  static const Color softBlue = Color(0xFFD5ECF7);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color mainText = Color(0xFF243746);
  static const Color secondaryText = Color(0xFF718096);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Status colors
  static const Color statusNew = Color(0xFF1677C8); // Blue
  static const Color statusVerified = Color(0xFFED8936); // Orange
  static const Color statusAssigned = Color(0xFF805AD5); // Purple
  static const Color statusUnderRepair = Color(0xFFE53E3E); // Red
  static const Color statusResolved = Color(0xFF38A169); // Green

  // Priority colors
  static const Color priorityNormal = Color(0xFF319795); // Teal
  static const Color priorityHigh = Color(0xFFDD6B20); // Deep Orange
  static const Color priorityCritical = Color(0xFFE53E3E); // Red

  // Placeholder Icon
  static const IconData logoIcon = Icons.water_drop_rounded;
}
