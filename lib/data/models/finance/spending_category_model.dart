// lib/data/models/finance/spending_category_model.dart

import 'dart:ui';

class SpendingCategory {
  final String name;
  final double amount;
  final double percentage;
  final int transactionCount;
  final String emoji;
  final Color color;

  const SpendingCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.emoji,
    required this.color,
  });

  static const categoryEmojis = {
    'food':          '🍔',
    'transport':     '🚗',
    'shopping':      '🛍',
    'investment':    '📈',
    'utilities':     '💡',
    'entertainment': '🎬',
    'health':        '🏥',
    'other':         '💰',
  };

  static const categoryColors = {
    'food':          Color(0xFFEF4444),
    'transport':     Color(0xFFF59E0B),
    'shopping':      Color(0xFF8B5CF6),
    'investment':    Color(0xFF10B981),
    'utilities':     Color(0xFF0EA5E9),
    'entertainment': Color(0xFFF97316),
    'health':        Color(0xFFEC4899),
    'other':         Color(0xFF64748B),
  };
}
