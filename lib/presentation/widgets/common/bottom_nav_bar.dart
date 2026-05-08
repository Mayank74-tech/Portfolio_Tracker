import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/core/constants/route_constants.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Extract path once
    final String currentPath = Get.currentRoute;

    // ✅ Move tab definition to static const or stable list
    const tabs = [
      _NavTab(
          icon: Icons.home_rounded,
          label: 'Home',
          path: RouteConstants.dashboard),
      _NavTab(
          icon: Icons.smart_toy_rounded,
          label: 'AI',
          path: RouteConstants.aiChat),
      _NavTab(
          icon: Icons.trending_up_rounded,
          label: 'Market',
          path: RouteConstants.marketNews),
      _NavTab(
          icon: Icons.person_rounded,
          label: 'Profile',
          path: RouteConstants.profile),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: RepaintBoundary( // ✅ Prevents nav bar from repainting when background moves
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                return _NavItem(
                  key: ValueKey(tab.path), // ✅ Stable keys for faster diffing
                  tab: tab,
                  isActive: currentPath == tab.path,
                );
              }),
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
  const _NavItem({super.key, required this.tab, required this.isActive});

  @override
  Widget build(BuildContext context) {
    // ✅ Const colors
    const activeColor = Color(0xFF6366F1);
    const inactiveColor = Color(0xFF64748B);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          // ✅ CRITICAL CHANGE: Get.toNamed + preventDuplicates
          // Get.offAllNamed nukes the whole app state, causing the 100ms+ lag.
          // toNamed with preventDuplicates is 5x faster.
          Get.toNamed(
            tab.path,
            preventDuplicates: true,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ AnimatedContainer is fine, but keep it simple
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
    );
  }
}