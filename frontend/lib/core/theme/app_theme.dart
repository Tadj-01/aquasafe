import 'package:flutter/material.dart';
import '../branding/app_branding.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppBranding.primaryBlue,
      onPrimary: AppBranding.pureWhite,
      primaryContainer: AppBranding.lightWaterBlue,
      onPrimaryContainer: AppBranding.deepNavy,
      secondary: AppBranding.deepNavy,
      onSecondary: AppBranding.pureWhite,
      secondaryContainer: AppBranding.softBlue,
      onSecondaryContainer: AppBranding.deepNavy,
      surface: AppBranding.pureWhite,
      onSurface: AppBranding.mainText,
      surfaceContainerLowest: AppBranding.pureWhite,
      surfaceContainerLow: AppBranding.lightBackground,
      surfaceContainer: AppBranding.lightWaterBlue,
      error: AppBranding.statusUnderRepair,
      onError: AppBranding.pureWhite,
      outline: AppBranding.cardBorder,
      outlineVariant: AppBranding.softBlue,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppBranding.lightBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppBranding.pureWhite,
        foregroundColor: AppBranding.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppBranding.deepNavy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppBranding.pureWhite,
        indicatorColor: AppBranding.lightWaterBlue,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppBranding.primaryBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppBranding.secondaryText,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppBranding.pureWhite,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppBranding.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppBranding.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppBranding.primaryBlue,
          foregroundColor: AppBranding.pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppBranding.primaryBlue,
          side: const BorderSide(color: AppBranding.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppBranding.primaryBlue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppBranding.pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppBranding.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppBranding.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppBranding.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppBranding.statusUnderRepair),
        ),
        hintStyle: const TextStyle(
          color: AppBranding.secondaryText,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppBranding.mainText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppBranding.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF0F172A); // Slate 900
    const darkSurface = Color(0xFF1E293B);    // Slate 800
    const darkBorder = Color(0xFF334155);     // Slate 700
    const darkTextPrimary = Color(0xFFF8FAFC);
    const darkTextSecondary = Color(0xFF94A3B8);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF38BDF8), // Sky blue
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF0369A1),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF818CF8), // Indigo
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF312E81),
      onSecondaryContainer: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerLowest: darkBackground,
      surfaceContainerLow: const Color(0xFF131D33),
      surfaceContainer: darkSurface,
      error: AppBranding.statusUnderRepair,
      onError: Colors.white,
      outline: darkBorder,
      outlineVariant: const Color(0xFF475569),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF0369A1),
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38BDF8),
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF38BDF8),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppBranding.statusUnderRepair),
        ),
        hintStyle: const TextStyle(
          color: darkTextSecondary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
