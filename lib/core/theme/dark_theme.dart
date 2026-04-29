import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Re-exports AppTheme.darkTheme for convenience.
/// This file exists as a clean alias — use AppTheme.darkTheme directly.
export 'app_theme.dart' show AppTheme, AppColors;

/// Pre-built dark ThemeData, identical to AppTheme.darkTheme.
ThemeData buildDarkTheme() => AppTheme.darkTheme;

/// Text style presets for the dark theme.
class DarkTextStyles {
  DarkTextStyles._();

  static TextStyle get heading1 => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get body => GoogleFonts.inter(
        color: const Color(0xFF94A3B8),
        fontSize: 14,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 11,
      );

  static TextStyle get label => GoogleFonts.inter(
        color: const Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
}
