// lib/presentation/screens/insights/attention_map_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/glass_container.dart';

class AttentionMapScreen extends StatefulWidget {
  const AttentionMapScreen({super.key});

  @override
  State<AttentionMapScreen> createState() =>
      _AttentionMapScreenState();
}

class _AttentionMapScreenState
    extends State<AttentionMapScreen>
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
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Obx(() {
                  final data = _bc.attentionData.value;
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
                          _summaryCard(data),
                          const SizedBox(height: 16),
                          _attentionBubbles(data),
                          const SizedBox(height: 16),
                          _detailList(data),
                        ],
                        const SizedBox(height: 16),
                        _insightCard(),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
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
                  'Attention Map',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Mental allocation vs real allocation',
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
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('👁', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            'Not all money feels equal.',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You may have ₹50,000 in a stock but spend '
                '80% of your mental energy on a ₹5,000 position. '
                'This map shows where your attention really goes.',
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

  Widget _summaryCard(Map<String, dynamic> data) {
    final overAttended =
        data['most_overattended']?.toString() ?? '';
    final ignored =
        data['most_ignored']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _insightBubble(
              data['insight']?.toString() ?? ''),
          if (overAttended.isNotEmpty ||
              ignored.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (overAttended.isNotEmpty)
                  Expanded(
                    child: _summaryBox(
                      '🔴 Most Watched',
                      overAttended,
                      const Color(0xFFEF4444),
                    ),
                  ),
                if (overAttended.isNotEmpty &&
                    ignored.isNotEmpty)
                  const SizedBox(width: 10),
                if (ignored.isNotEmpty)
                  Expanded(
                    child: _summaryBox(
                      '🔵 Most Ignored',
                      ignored,
                      const Color(0xFF6366F1),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _attentionBubbles(Map<String, dynamic> data) {
    final items =
    (data['items'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (items.isEmpty) return const SizedBox.shrink();

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
            'Attention vs Portfolio Weight',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final symbol = item['symbol'].toString();
            final realPct =
            _toDouble(item['real_allocation_pct']);
            final attPct =
            _toDouble(item['attention_pct']);
            final gap = _toDouble(item['gap']);
            final isOver = gap > 0;
            final daysSince =
                (item['days_since_viewed'] as int?) ??
                    999;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (daysSince < 999)
                        Text(
                          daysSince == 0
                              ? 'viewed today'
                              : 'viewed $daysSince days ago',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                      const Spacer(),
                      if (gap.abs() > 3)
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isOver
                                ? const Color(
                                0xFFF59E0B)
                                : const Color(
                                0xFF6366F1))
                                .withValues(alpha: 0.15),
                            borderRadius:
                            BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOver
                                ? '+${gap.toStringAsFixed(1)}% over'
                                : '${gap.toStringAsFixed(1)}% under',
                            style: TextStyle(
                              color: isOver
                                  ? const Color(
                                  0xFFF59E0B)
                                  : const Color(
                                  0xFF6366F1),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Portfolio bar
                  _labeledBar(
                    '💼 Portfolio',
                    realPct,
                    const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 4),
                  // Attention bar
                  _labeledBar(
                    '👁 Attention',
                    attPct,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _detailList(Map<String, dynamic> data) {
    final items =
    (data['items'] as List? ?? [])
        .cast<Map<String, dynamic>>();

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
            'Detailed Breakdown',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                  flex: 2,
                  child: Text('Stock',
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10))),
              Expanded(
                  child: Text('Portfolio',
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10),
                      textAlign: TextAlign.center)),
              Expanded(
                  child: Text('Attention',
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10),
                      textAlign: TextAlign.center)),
              Expanded(
                  child: Text('Gap',
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10),
                      textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),
          ...items.map((item) {
            final gap = _toDouble(item['gap']);
            final isOver = gap > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['symbol'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_toDouble(item['real_allocation_pct']).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_toDouble(item['attention_pct']).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${isOver ? "+" : ""}${gap.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isOver
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _insightCard() {
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
            '💡 Why Attention Matters',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Overattended stocks get sold too early during dips '
                'because you\'re emotionally invested.',
            'Ignored winners get held past their peak '
                'because you\'re not watching them.',
            'Attention allocation reveals emotional bias '
                'more clearly than any other metric.',
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
                    color: Color(0xFFF59E0B),
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
          Text('👁',
              style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          Text(
            'No attention data yet',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Browse your stock detail pages to '
                'start building your attention map.',
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

  Widget _labeledBar(
      String label, double pct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
              Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _summaryBox(
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightBubble(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 12,
          height: 1.5,
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
}