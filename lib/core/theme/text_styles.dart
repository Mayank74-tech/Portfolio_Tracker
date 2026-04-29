import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide text style presets using Google Fonts Inter.
class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle display({Color color = const Color(0xFFF1F5F9)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 32, fontWeight: FontWeight.w800);

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle h1({Color color = const Color(0xFFF1F5F9)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 24, fontWeight: FontWeight.w700);

  static TextStyle h2({Color color = const Color(0xFFF1F5F9)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle h3({Color color = const Color(0xFFF1F5F9)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 15, fontWeight: FontWeight.w600);

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle body({Color color = const Color(0xFF94A3B8)}) =>
      GoogleFonts.inter(color: color, fontSize: 14, height: 1.5);

  static TextStyle bodySmall({Color color = const Color(0xFF94A3B8)}) =>
      GoogleFonts.inter(color: color, fontSize: 12, height: 1.5);

  // ── Label / Caption ───────────────────────────────────────────────────────
  static TextStyle label({Color color = const Color(0xFF64748B)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle caption({Color color = const Color(0xFF64748B)}) =>
      GoogleFonts.inter(color: color, fontSize: 11);

  // ── Button ────────────────────────────────────────────────────────────────
  static TextStyle button({Color color = Colors.white}) =>
      GoogleFonts.inter(
          color: color, fontSize: 14, fontWeight: FontWeight.w700);

  // ── Financial ─────────────────────────────────────────────────────────────
  static TextStyle price({Color color = const Color(0xFFF1F5F9)}) =>
      GoogleFonts.inter(
          color: color, fontSize: 26, fontWeight: FontWeight.w700);

  static TextStyle gain() => GoogleFonts.inter(
      color: const Color(0xFF10B981),
      fontSize: 13,
      fontWeight: FontWeight.w600);

  static TextStyle loss() => GoogleFonts.inter(
      color: const Color(0xFFEF4444),
      fontSize: 13,
      fontWeight: FontWeight.w600);
}
