// lib/presentation/screens/insights/identity_drift_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';

class IdentityDriftScreen extends StatefulWidget {
  const IdentityDriftScreen({super.key});

  @override
  State<IdentityDriftScreen> createState() =>
      _IdentityDriftScreenState();
}

class _IdentityDriftScreenState
    extends State<IdentityDriftScreen>
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
                  final data = _bc.identityDrift.value;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 40),
                    child: Column(
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        _driftStatusCard(data),
                        const SizedBox(height: 16),
                        _styleHistoryCard(data),
                        const SizedBox(height: 16),
                        _conflictCard(data),
                        const SizedBox(height: 16),
                        _styleSetterCard(data),
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
                  'Identity Drift',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Who you are vs how you actually invest',
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
          colors: [Color(0xFF1A0E2E), Color(0xFF0B1120)],
        ),
        border: Border.all(
          color: const Color(0xFFA855F7)
              .withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🪞', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            'Investors drift without realizing it.',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'A long-term investor starts making weekly trades. '
                'A conservative investor buys speculative stocks. '
                'These shifts happen gradually — this screen catches them.',
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

  Widget _driftStatusCard(Map<String, dynamic> data) {
    final hasDrifted = data['has_drifted'] == true;
    final stated =
        data['stated_style']?.toString() ?? 'unknown';
    final inferred =
        data['inferred_style']?.toString() ?? 'unknown';
    final insight =
        data['drift_insight']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (hasDrifted
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                hasDrifted ? '⚠️' : '✅',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                hasDrifted
                    ? 'Identity Drift Detected'
                    : 'Identity Consistent',
                style: TextStyle(
                  color: hasDrifted
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _styleBox(
                  'Stated Identity',
                  _styleLabel(stated),
                  const Color(0xFF6366F1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10),
                child: Icon(
                  hasDrifted
                      ? Icons.swap_horiz_rounded
                      : Icons.check_rounded,
                  color: hasDrifted
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  size: 22,
                ),
              ),
              Expanded(
                child: _styleBox(
                  'Actual Behavior',
                  _styleLabel(inferred),
                  hasDrifted
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                insight,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _styleHistoryCard(Map<String, dynamic> data) {
    final history =
    (data['style_history'] as List? ?? [])
        .cast<String>();

    if (history.isEmpty) {
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
              'Style History',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No style changes recorded yet. '
                  'Set your investing style below to start tracking.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

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
            'Style History',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...history.reversed.take(6).map((entry) {
            final parts = entry.split('_');
            final style = parts.length > 1
                ? parts.sublist(0, parts.length - 1)
                .join('_')
                : entry;
            final date = parts.isNotEmpty
                ? parts.last
                : '';

            return Padding(
              padding:
              const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _styleLabel(style),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _conflictCard(Map<String, dynamic> data) {
    final recentBuys =
        (data['recent_buy_count'] as int?) ?? 0;

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
            'Behavioral Evidence',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _evidenceRow(
            'Buy decisions last 30 days',
            '$recentBuys',
            recentBuys >= 3
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
            recentBuys >= 3
                ? 'Active trading pattern'
                : 'Measured approach',
          ),
          const SizedBox(height: 8),
          _evidenceRow(
            'Style inference method',
            recentBuys >= 3
                ? 'Frequency-based'
                : 'Hold-period based',
            const Color(0xFF6366F1),
            'Based on your last 90 days of activity',
          ),
        ],
      ),
    );
  }

  Widget _styleSetterCard(Map<String, dynamic> data) {
    final stated =
        data['stated_style']?.toString() ?? 'unknown';

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
            'Update Your Identity',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the style that best describes you:',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...[
            (
            'long_term',
            'Long-Term Investor',
            'I hold stocks for years. '
                'I don\'t react to short-term noise.',
            Icons.hourglass_full_rounded,
            ),
            (
            'short_term',
            'Short-Term Trader',
            'I capitalize on momentum and '
                'exit within weeks or months.',
            Icons.flash_on_rounded,
            ),
            (
            'swing',
            'Swing Trader',
            'I hold for days to weeks, '
                'trading on technical patterns.',
            Icons.show_chart_rounded,
            ),
          ].map((item) {
            final isSelected = stated == item.$1;
            return GestureDetector(
              onTap: () =>
                  _bc.setInvestingStyle(item.$1),
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                margin:
                const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA855F7)
                      .withValues(alpha: 0.12)
                      : Colors.white
                      .withValues(alpha: 0.03),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA855F7)
                        .withValues(alpha: 0.4)
                        : Colors.white
                        .withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isSelected
                            ? const Color(
                            0xFFA855F7)
                            : const Color(
                            0xFF64748B))
                            .withValues(alpha: 0.15),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.$4,
                        color: isSelected
                            ? const Color(0xFFA855F7)
                            : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(
                                  0xFFD8B4FE)
                                  : const Color(
                                  0xFF94A3B8),
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFA855F7),
                        size: 18,
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
            '💡 Why Identity Matters',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Style drift is often invisible — '
                'you don\'t realize you\'ve changed until '
                'you look back.',
            'Long-term strategies require different '
                'emotional tools than short-term trading. '
                'Mixing them causes confusion.',
            'The most consistent investors have a '
                'clear identity and filter every decision '
                'through it.',
          ].map((text) => Padding(
            padding:
            const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(
                      top: 4, right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA855F7),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _styleBox(
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
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _evidenceRow(
      String label, String value, Color color,
      String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12)),
                Text(sub,
                    style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 10)),
              ],
            ),
          ),
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

  static String _styleLabel(String style) {
    switch (style) {
      case 'long_term':  return 'Long-Term';
      case 'short_term': return 'Short-Term';
      case 'swing':      return 'Swing';
      default:           return 'Unknown';
    }
  }
}