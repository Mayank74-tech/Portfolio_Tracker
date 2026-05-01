// lib/presentation/screens/insights/memory_reality_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';

class MemoryRealityScreen extends StatefulWidget {
  const MemoryRealityScreen({super.key});

  @override
  State<MemoryRealityScreen> createState() =>
      _MemoryRealityScreenState();
}

class _MemoryRealityScreenState
    extends State<MemoryRealityScreen>
    with SingleTickerProviderStateMixin {
  late final BehavioralController _bc;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  final TextEditingController _input =
  TextEditingController();
  bool _submitted = false;

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
    _input.dispose();
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _heroCard(),
                      const SizedBox(height: 16),
                      _inputCard(),
                      const SizedBox(height: 16),
                      Obx(() => _resultSection()),
                      const SizedBox(height: 16),
                      _historySection(),
                      const SizedBox(height: 16),
                      _scienceCard(),
                    ],
                  ),
                ),
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
                  'Memory vs Reality',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'What you believe vs what data shows',
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
            Color(0xFF1E1A4F),
            Color(0xFF0F0D2E),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6366F1)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Humans are terrible at remembering investment performance.',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We overweight recent bad news and underweight '
                'consistent good performance. This engine '
                'compares what you believe with what actually happened.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final accuracy = _bc.beliefAccuracy.value;
            if (accuracy == 0) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF818CF8),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your memory accuracy: '
                        '${(accuracy * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _inputCard() {
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
            'Test Your Memory',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Without looking at your portfolio, answer this:',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              '"Which stock do you believe has performed WORST in your portfolio?"',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              controller: _input,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Type stock symbol e.g. RELIANCE',
                hintStyle: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (_input.text.trim().isEmpty) return;
              _bc.submitMemoryBelief(
                  _input.text.trim().toUpperCase());
              setState(() => _submitted = true);
              FocusScope.of(context).unfocus();
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF4F46E5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Reveal the Truth',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultSection() {
    final data = _bc.memoryReality.value;
    if (data.isEmpty || !_submitted) {
      return const SizedBox.shrink();
    }

    final wasCorrect = data['was_correct'] == true;
    final explanation =
        data['explanation']?.toString() ?? '';
    final ranked =
    (data['ranked'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (wasCorrect
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    wasCorrect ? '✅' : '🔍',
                    style:
                    const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    wasCorrect
                        ? 'Memory Correct!'
                        : 'Memory Gap Detected',
                    style: TextStyle(
                      color: wasCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Actual Performance Ranking',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...ranked.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                final pl = _toDouble(item['pl_percent']);
                final isGain = pl >= 0;
                final isUserBelief =
                    item['symbol'].toString() ==
                        data['user_belief'].toString();

                return Container(
                  margin: const EdgeInsets.only(
                      bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUserBelief
                        ? const Color(0xFFF59E0B)
                        .withValues(alpha: 0.08)
                        : Colors.white
                        .withValues(alpha: 0.03),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: isUserBelief
                        ? Border.all(
                        color: const Color(
                            0xFFF59E0B)
                            .withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.06),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item['symbol'].toString(),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUserBelief) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'your belief',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 9,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${isGain ? "+" : ""}${pl.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isGain
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            _input.clear();
            setState(() => _submitted = false);
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: const Center(
              child: Text(
                'Test Again',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historySection() {
    return Obx(() {
      final beliefs = _bc.allBeliefs;
      if (beliefs.isEmpty) return const SizedBox.shrink();

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
              'Past Tests',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...beliefs.take(5).map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          b.wasCorrect
                              ? Icons
                              .check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          color: b.wasCorrect
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You said: ${b.userBelief}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(b.recordedAt),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.explanation,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _scienceCard() {
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
            '📚 The Science Behind This',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            (
            'Recency Bias',
            'We overweight recent events. A stock that '
                'dropped last week feels like a "bad" stock '
                'even if it\'s up 40% overall.',
            ),
            (
            'Loss Aversion',
            'Losses feel 2x more painful than equivalent '
                'gains feel good. So bad performers '
                'stick in memory longer.',
            ),
            (
            'Availability Heuristic',
            'We judge probability by how easily an example '
                'comes to mind — not by actual data.',
            ),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                    color: Color(0xFF6366F1),
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

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}