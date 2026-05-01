// lib/presentation/screens/insights/uncertainty_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';

class UncertaintyScreen extends StatefulWidget {
  const UncertaintyScreen({super.key});

  @override
  State<UncertaintyScreen> createState() =>
      _UncertaintyScreenState();
}

class _UncertaintyScreenState
    extends State<UncertaintyScreen>
    with SingleTickerProviderStateMixin {
  late final BehavioralController _bc;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _bc = Get.find<BehavioralController>();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade =
        CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Obx(() {
                  final data =
                      _bc.uncertaintyBands.value;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 40),
                    child: Column(
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        if (data.isEmpty ||
                            data['error'] != null)
                          _emptyState()
                        else ...[
                          _bandsCard(data),
                          const SizedBox(height: 16),
                          _visualizerCard(data),
                        ],
                        const SizedBox(height: 16),
                        _educationCard(),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _iconBox(Icons.chevron_left_rounded,
              onTap: () => Get.back()),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uncertainty Visualizer',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your portfolio is a range, not a number',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1F2D), Color(0xFF0B1120)],
        ),
        border: Border.all(
          color: const Color(0xFF0EA5E9)
              .withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            'Stop thinking in single numbers.',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Professional traders never say "my portfolio is ₹1,00,000." '
                'They say "my portfolio is between ₹92K and ₹1.08L with '
                '68% confidence." This is how they think about risk.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandsCard(Map<String, dynamic> data) {
    final current = _toDouble(data['current']);
    final optimistic = _toDouble(data['optimistic']);
    final likelyHigh = _toDouble(data['likely_high']);
    final likelyLow = _toDouble(data['likely_low']);
    final pessimistic = _toDouble(data['pessimistic']);
    final vol = _toDouble(data['volatility_pct']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Current value center display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Portfolio Value',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_fmtNum(current)}',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Volatility: ${vol.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bands
          _bandItem(
            emoji: '🟢',
            label: 'Optimistic Scenario',
            sublabel: 'If things go well',
            value: optimistic,
            current: current,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _bandItem(
            emoji: '🔵',
            label: 'Likely High',
            sublabel: '68% confidence upper',
            value: likelyHigh,
            current: current,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Text(
                  'Most likely range: ',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                Text(
                  data['confidence_interval']
                      .toString(),
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _bandItem(
            emoji: '🔵',
            label: 'Likely Low',
            sublabel: '68% confidence lower',
            value: likelyLow,
            current: current,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),
          _bandItem(
            emoji: '🔴',
            label: 'Pessimistic Scenario',
            sublabel: 'If things go badly',
            value: pessimistic,
            current: current,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _bandItem({
    required String emoji,
    required String label,
    required String sublabel,
    required double value,
    required double current,
    required Color color,
  }) {
    final diff = value - current;
    final isUp = diff >= 0;

    return Row(
      children: [
        Text(emoji,
            style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${_fmtNum(value)}',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${isUp ? "+" : ""}${diff >= 0 ? "+" : ""}₹${_fmtNum(diff.abs())}',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _visualizerCard(Map<String, dynamic> data) {
    final current = _toDouble(data['current']);
    final optimistic = _toDouble(data['optimistic']);
    final pessimistic = _toDouble(data['pessimistic']);
    final likelyHigh = _toDouble(data['likely_high']);
    final likelyLow = _toDouble(data['likely_low']);

    final range = optimistic - pessimistic;
    if (range <= 0) return const SizedBox.shrink();

    double norm(double v) =>
        ((v - pessimistic) / range).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visual Range',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // Background track
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.05),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Likely range band
                    Positioned(
                      top: 20,
                      left: norm(likelyLow) * width,
                      width: (norm(likelyHigh) -
                          norm(likelyLow)) *
                          width,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.4),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // Current value marker
                    Positioned(
                      top: 14,
                      left: (norm(current) * width - 12)
                          .clamp(0.0, width - 24),
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF0EA5E9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Labels
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Text(
                        '₹${_fmtNum(pessimistic)}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(
                        '₹${_fmtNum(optimistic)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Current value',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1)
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '68% confidence band',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _educationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 What These Bands Mean',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            (
            '68% Confidence Band',
            'Your portfolio will most likely stay within '
                'this range over the next month. Based on '
                'historical volatility of your holdings.',
            ),
            (
            'Optimistic Scenario',
            'If all your stocks perform in the upper range '
                'of their historical moves. Not guaranteed.',
            ),
            (
            'Pessimistic Scenario',
            'If all your stocks face headwinds simultaneously. '
                'Rare but possible — this is your worst-case '
                'planning number.',
            ),
          ].map((item) => Padding(
            padding:
            const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(
                      top: 5, right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        children: [
          Text('📊',
              style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          Text(
            'No portfolio data',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add holdings to see your uncertainty bands.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon,
            size: 18, color: const Color(0xFF94A3B8)),
      ),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmtNum(double v) {
    if (v >= 10000000) {
      return '${(v / 10000000).toStringAsFixed(2)}Cr';
    }
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(2)}L';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }
}