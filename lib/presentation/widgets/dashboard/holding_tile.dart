import 'package:flutter/material.dart';
import '../common/glass_container.dart';

class HoldingTile extends StatelessWidget {
  final Map<String, dynamic> holding;
  final VoidCallback? onTap;

  const HoldingTile({super.key, required this.holding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final symbol = holding['stock_symbol']?.toString() ?? '';
    final name = holding['stock_name']?.toString() ?? symbol;
    final qty = _toDouble(holding['quantity']);
    final buyPrice = _toDouble(holding['buy_price']);
    final currentPrice = _toDouble(holding['current_price'] ?? buyPrice);
    final invested = qty * buyPrice;
    final current = qty * currentPrice;
    final pl = current - invested;
    final plPct = invested == 0 ? 0.0 : (pl / invested) * 100;
    final isGain = pl >= 0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Symbol avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol.length >= 3 ? symbol.substring(0, 3) : symbol,
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} shares',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_fmt(current)}',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isGain ? "+" : ""}${plPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isGain
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
