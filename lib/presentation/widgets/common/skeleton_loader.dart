import 'package:flutter/material.dart';

/// Animated shimmer skeleton loader for list/card placeholders.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Color.lerp(
            const Color(0xFF1E293B),
            const Color(0xFF334155),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton that mimics a holding tile.
class HoldingSkeletonCard extends StatelessWidget {
  const HoldingSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SkeletonLoader(width: 42, height: 42, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 100, height: 14),
                SizedBox(height: 6),
                SkeletonLoader(width: 60, height: 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLoader(width: 70, height: 14),
              SizedBox(height: 6),
              SkeletonLoader(width: 50, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}
