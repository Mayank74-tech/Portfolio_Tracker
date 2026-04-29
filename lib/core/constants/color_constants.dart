import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Re-exports AppColors for convenience. Use AppColors directly from app_theme.dart.
export '../theme/app_theme.dart' show AppColors;

/// Additional semantic color helpers.
class ColorConstants {
  ColorConstants._();

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF6366F1);

  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkCard = Color(0xFF111827);
  static const Color darkBorder = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  static Color gainColor(bool isGain) =>
      isGain ? success : error;

  static Color gainBg(bool isGain) =>
      isGain
          ? success.withValues(alpha: 0.12)
          : error.withValues(alpha: 0.12);

  static ThemeData get darkTheme => AppTheme.darkTheme;
  static ThemeData get lightTheme => AppTheme.lightTheme;
}
