import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'glass_container.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.actions,
    this.onBack,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 68 : 56);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              GestureDetector(
                onTap: onBack ?? Get.back,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            if (showBack) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
