import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.add_rounded,
          label: 'Add Stock',
          color: const Color(0xFF6366F1),
          onTap: () => Get.toNamed(AppRoutes.ADD_STOCK),
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.upload_file_rounded,
          label: 'Import CSV',
          color: const Color(0xFF10B981),
          onTap: () => Get.toNamed(AppRoutes.IMPORT_CSV),
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.bar_chart_rounded,
          label: 'Insights',
          color: const Color(0xFFF59E0B),
          onTap: () => Get.toNamed(AppRoutes.INSIGHTS),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
