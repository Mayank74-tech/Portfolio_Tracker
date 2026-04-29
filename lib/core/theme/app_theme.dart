import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color surfaceLight = Color(0xFF232329);
  static const Color cardBg = Color(0xFF1E1E26);
  static const Color primary = Color(0xFF4D8EFF);
  static const Color primaryLight = Color(0xFF6BA3FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFF2A2A35);
  static const Color portfolioCard = Color(0xFF2563EB);
  static const Color aiGreen = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF0D1117),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0D1117)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF9CA3AF),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Color(0x1A000000),
      ),
    );
  }
}
