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
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
