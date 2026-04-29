import 'package:flutter/material.dart';

/// A full-width primary gradient button used throughout the app.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: onTap == null
                ? [const Color(0xFF2A2A35), const Color(0xFF2A2A35)]
                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A ghost/outlined secondary button variant.
class CustomOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final Widget? icon;

  const CustomOutlinedButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
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
