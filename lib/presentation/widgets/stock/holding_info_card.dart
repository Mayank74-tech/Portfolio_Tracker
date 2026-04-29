import 'package:flutter/material.dart';
import '../common/glass_container.dart';

/// Shows the user's holding details for a specific stock on the detail screen.
class HoldingInfoCard extends StatelessWidget {
  final Map<String, dynamic> holding;

  const HoldingInfoCard({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    final qty = _toDouble(holding['quantity']);
    final buyPrice = _toDouble(holding['buy_price']);
    final currentPrice = _toDouble(holding['current_price'] ?? buyPrice);
    final invested = qty * buyPrice;
    final current = qty * currentPrice;
    final pl = current - invested;
    final plPct = invested == 0 ? 0.0 : (pl / invested) * 100;
    final isGain = pl >= 0;
    final buyDate = holding['buy_date']?.toString() ?? '';

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your Holding',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isGain
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isGain ? "+" : ""}${plPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isGain
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('Quantity', qty.toStringAsFixed(
                  qty.truncateToDouble() == qty ? 0 : 2)),
              _stat('Buy Price', '₹${_fmt(buyPrice)}'),
              _stat('Invested', '₹${_fmt(invested)}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('Current', '₹${_fmt(current)}'),
              _stat(
                'P&L',
                '${isGain ? "+" : ""}₹${_fmt(pl.abs())}',
                color: isGain
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              if (buyDate.isNotEmpty)
                _stat('Bought', _fmtDate(buyDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? const Color(0xFFF1F5F9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }

  static String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
