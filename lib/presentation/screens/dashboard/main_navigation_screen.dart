import 'package:flutter/material.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/bottom_nav_bar.dart';

class MainNavigationScreen extends StatelessWidget {
  final Widget child;
  const MainNavigationScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      // ✅ RepaintBoundary: bottom nav repaints independently
      // from page content - scrolling page won't repaint nav
      body: RepaintBoundary(child: child),
      bottomNavigationBar: const RepaintBoundary(
        child: BottomNavBar(),
      ),
    );
  }
}