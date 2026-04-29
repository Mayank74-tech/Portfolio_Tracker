import 'package:flutter/material.dart';

/// A single page within the onboarding flow.
/// Used by OnboardingScreen to display each step's icon, title, and body.
class OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final Color accentColor;

  const OnboardingPage({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    this.accentColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji icon in a glowing circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
