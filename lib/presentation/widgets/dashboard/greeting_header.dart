import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/portfolio_controller.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PortfolioController>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Obx(() {
      final summary = pc.summary;
      final totalValue = _toDouble(summary['total_value']);
      final totalPl = _toDouble(summary['profit_loss']);
      final isGain = totalPl >= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting 👋',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '₹${_fmt(totalValue)}',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isGain
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isGain ? "+" : ""}${_toDouble(summary['profit_loss_percent']).toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isGain
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Total Portfolio Value',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      );
    });
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
