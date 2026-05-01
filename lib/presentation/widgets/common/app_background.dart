import 'dart:ui';
import 'package:flutter/material.dart';

/// A dynamic animated mesh gradient background to make the Glassmorphism pop.
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B14) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background mesh animated blobs
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              return Stack(
                children: [
                  // Top left blob
                  Positioned(
                    top: -100 + (t * 50),
                    left: -100 - (t * 30),
                    child: _Blob(
                      color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.15),
                      size: 400,
                    ),
                  ),
                  // Bottom right blob
                  Positioned(
                    bottom: -150 - (t * 40),
                    right: -100 + (t * 60),
                    child: _Blob(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.1),
                      size: 450,
                    ),
                  ),
                  // Center right blob
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.3 + (t * 100),
                    right: -50 - (t * 20),
                    child: _Blob(
                      color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.15 : 0.08),
                      size: 300,
                    ),
                  ),
                ],
              );
            },
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: const SizedBox(),
      ),
    );
  }
}

