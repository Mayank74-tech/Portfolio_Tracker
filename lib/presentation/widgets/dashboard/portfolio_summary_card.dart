import 'package:flutter/material.dart';
import '../common/glass_container.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const PortfolioSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalValue = _toDouble(summary['total_value']);
    final totalInvested = _toDouble(summary['total_investment']);
    final totalPl = _toDouble(summary['profit_loss']);
    final totalPlPct = _toDouble(summary['profit_loss_percent']);
    final isGain = totalPl >= 0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Portfolio',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_fmt(totalValue)}',
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox(
                'Invested',
                '₹${_fmt(totalInvested)}',
                const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              _statBox(
                'P&L',
                '${isGain ? "+" : ""}₹${_fmt(totalPl.abs())}',
                isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              _statBox(
                'Return',
                '${isGain ? "+" : ""}${totalPlPct.toStringAsFixed(2)}%',
                isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(12),
        opacity: 0.05,
        blur: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
