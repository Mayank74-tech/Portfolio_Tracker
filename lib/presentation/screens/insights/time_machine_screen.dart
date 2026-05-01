// lib/presentation/screens/insights/time_machine_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';
import '../../controllers/portfolio_controller.dart';

class TimeMachineScreen extends StatefulWidget {
  const TimeMachineScreen({super.key});

  @override
  State<TimeMachineScreen> createState() =>
      _TimeMachineScreenState();
}

class _TimeMachineScreenState
    extends State<TimeMachineScreen>
    with SingleTickerProviderStateMixin {
  late final BehavioralController _bc;
  late final PortfolioController _pc;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _bc = Get.find<BehavioralController>();
    _pc = Get.find<PortfolioController>();
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
                  final truths = _bc.delayedTruths;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 40),
                    child: Column(
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        if (truths.isEmpty)
                          _emptyState()
                        else ...[
                          _decisionSelector(truths),
                          const SizedBox(height: 16),
                          if (_selectedIndex <
                              truths.length)
                            _decisionReplay(
                                truths[_selectedIndex]),
                        ],
                        const SizedBox(height: 16),
                        _reflectionCard(),
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
                  'Financial Time Machine',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Replay your past decisions with fresh eyes',
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
          colors: [
            Color(0xFF0D2137),
            Color(0xFF0B1120),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF0EA5E9)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏱',
              style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          const Text(
            'Bad decision or bad outcome?',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Elite investors separate these. A decision can be '
                'correct even if the outcome was bad — and vice versa. '
                'This replays what you knew at the time.',
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

  Widget _decisionSelector(
      List<Map<String, dynamic>> truths) {
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
            'Select a Past Decision',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...truths.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            final isSelected = _selectedIndex == i;
            final change =
            _toDouble(t['change_pct']);
            final isGain = change >= 0;

            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                margin:
                const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      .withValues(alpha: 0.12)
                      : Colors.white
                      .withValues(alpha: 0.03),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        .withValues(alpha: 0.4)
                        : Colors.white
                        .withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      t['symbol'].toString(),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t['days_ago']} days ago',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${isGain ? "+" : ""}${change.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isGain
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _decisionReplay(Map<String, dynamic> t) {
    final symbol = t['symbol'].toString();
    final daysAgo = t['days_ago'] as int;
    final priceThen = _toDouble(t['price_then']);
    final priceNow = _toDouble(t['price_now']);
    final change = _toDouble(t['change_pct']);
    final isGain = change >= 0;

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
          Row(
            children: [
              const Text('📅',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$daysAgo days ago you bought $symbol',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price comparison
          Row(
            children: [
              Expanded(
                child: _priceBox(
                  'Price Then',
                  '₹${_fmtNum(priceThen)}',
                  const Color(0xFF64748B),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                child: Icon(
                  isGain
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isGain
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              Expanded(
                child: _priceBox(
                  'Price Now',
                  '₹${_fmtNum(priceNow)}',
                  isGain
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Outcome
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGain
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444))
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isGain
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444))
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGain
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  color: isGain
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Outcome: ${isGain ? "+" : ""}${change.toStringAsFixed(2)}% '
                      'since your decision',
                  style: TextStyle(
                    color: isGain
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reflection question
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reflection Question',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '"Knowing only what you knew at the time of purchase — '
                      'would you make this decision again?"',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _answerBtn(
                  'Yes, I would',
                  const Color(0xFF10B981),
                  Icons.thumb_up_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _answerBtn(
                  'No, I wouldn\'t',
                  const Color(0xFFEF4444),
                  Icons.thumb_down_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reflectionCard() {
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
            '💡 How to Think About Past Decisions',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            (
            'Good decision, bad outcome',
            'You followed a sound process but got unlucky. '
                'Don\'t change your process.',
            ),
            (
            'Bad decision, good outcome',
            'You got lucky. Don\'t mistake luck for skill '
                'or repeat the same reasoning.',
            ),
            (
            'Good decision, good outcome',
            'Ideal. Understand exactly what you did right '
                'and repeat it.',
            ),
            (
            'Bad decision, bad outcome',
            'The clearest feedback. Identify the flaw '
                'in your reasoning.',
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
          Text('⏳',
              style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          Text(
            'No decisions to replay yet',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Decisions appear here after 7 days. '
                'Keep investing to build your time machine.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBox(
      String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerBtn(
      String label, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _showReflectionSaved(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReflectionSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Reflection saved. This builds self-awareness over time.',
        ),
        backgroundColor: const Color(0xFF131D2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(2);
  }
}