import 'package:flutter/material.dart';
import '../common/glass_container.dart';

/// Displays an AI-generated insight text in a styled card.
class AiInsightCard extends StatelessWidget {
  final String insight;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AiInsightCard({
    super.key,
    required this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'AI Insight',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const _PulsingLoader()
          else
            Text(
              insight.isNotEmpty ? insight : 'No AI insight available yet.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingLoader extends StatefulWidget {
  const _PulsingLoader();

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF1E293B),
                const Color(0xFF334155),
                _anim.value,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 240,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF1E293B),
                const Color(0xFF334155),
                _anim.value,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 180,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF1E293B),
                const Color(0xFF334155),
                _anim.value,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
