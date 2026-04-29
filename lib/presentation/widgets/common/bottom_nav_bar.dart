import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/core/constants/route_constants.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentPath = Get.currentRoute;

    final tabs = [
      const _NavTab(
          icon: Icons.home_rounded,
          label: 'Home',
          path: RouteConstants.dashboard),
      const _NavTab(
          icon: Icons.smart_toy_rounded,
          label: 'AI',
          path: RouteConstants.aiChat),
      const _NavTab(
          icon: Icons.trending_up_rounded,
          label: 'Market',
          path: RouteConstants.marketNews),
      const _NavTab(
          icon: Icons.person_rounded,
          label: 'Profile',
          path: RouteConstants.profile),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = currentPath == tab.path;
              return _NavItem(tab: tab, isActive: isActive);
            }).toList(),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String path;
  const _NavTab({required this.icon, required this.label, required this.path});
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  const _NavItem({required this.tab, required this.isActive});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6366F1);
    const inactiveColor = Color(0xFF64748B);

    return GestureDetector(
      onTap: () {
        if (!isActive) Get.offAllNamed(tab.path);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tab.icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
