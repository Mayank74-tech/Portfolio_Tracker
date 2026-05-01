import 'dart:ui';
import 'package:flutter/material.dart';

/// A sleek Glassmorphism container with blur, semi-transparent background, and a subtle border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.08,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? Colors.white : Colors.black);

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: opacity),
              borderRadius: radius,
              border: Border.all(
                color: borderColor ?? baseColor.withValues(alpha: isDark ? 0.15 : 0.08),
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: opacity + 0.05),
                  baseColor.withValues(alpha: opacity),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
