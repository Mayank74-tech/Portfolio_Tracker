import 'package:flutter/material.dart';

class ChartPeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const periods = ['1D', '1W', '1M', '3M', '6M', '1Y'];

  const ChartPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: periods.map((p) {
        final isActive = p == selected;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF6366F1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF6366F1)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              p,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
