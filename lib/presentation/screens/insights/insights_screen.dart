// lib/presentation/screens/insights/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/behavioral_controller.dart';
import '../../controllers/portfolio_controller.dart';
import '../../widgets/common/app_background.dart';
import '../../widgets/common/glass_container.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  late final BehavioralController _bc;
  late final PortfolioController _pc;
  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final TextEditingController _beliefInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bc = Get.find<BehavioralController>();
    _pc = Get.find<PortfolioController>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bc.loadAllInsights();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _beliefInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Obx(() {
                if (_bc.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  );
                }
                return FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: RefreshIndicator(
                      color: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFF131D2E),
                      onRefresh: _bc.loadAllInsights,
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 100),
                        children: [
                          _sectionLabel(
                              '🧠 Memory & Perception'),
                          _buildMemoryRealityCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '👁 Attention Analysis'),
                          _buildAttentionCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '🔇 Silent Winners'),
                          _buildSilentWinnersCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '⏳ Decision Age'),
                          _buildHalfLifeCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '📊 Uncertainty Bands'),
                          _buildUncertaintyCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '🌊 Cascade Risk'),
                          _buildCascadeCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '🪞 Identity Drift'),
                          _buildIdentityCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '⚡ Decision Friction'),
                          _buildFrictionCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '🚫 What You Didn\'t Do'),
                          _buildInactionCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '🕰 Delayed Truth'),
                          _buildDelayedTruthCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '⚔ Internal Conflict'),
                          _buildConflictCard(),
                          const SizedBox(height: 12),
                          _sectionLabel(
                              '📈 Confidence Illusion'),
                          _buildConfidenceCard(),
                        ],
                      ),
                    ),
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

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: _iconBox(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Behavioral Insights',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'How you think vs what actually happened',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _bc.loadAllInsights,
            child: _iconBox(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  // ── Feature 1: Memory vs Reality ──────────────────────────────────────────

  Widget _buildMemoryRealityCard() {
    return Obx(() {
      final data = _bc.memoryReality.value;

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🧠',
              title: 'Memory vs Reality',
              subtitle:
              'What you believe vs what data shows',
            ),
            const SizedBox(height: 14),

            // Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _beliefInput,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText:
                  'Which stock do you think performed worst?',
                  hintStyle: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      if (_beliefInput.text.trim().isNotEmpty) {
                        _bc.submitMemoryBelief(
                            _beliefInput.text.trim());
                        _beliefInput.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (data.isNotEmpty && data['explanation'] != null)
              ...[
                const SizedBox(height: 14),
                _resultBanner(
                  isCorrect: data['was_correct'] == true,
                  text: data['explanation'].toString(),
                ),
                const SizedBox(height: 10),

                // Ranked list
                if (data['ranked'] != null) ...[
                  const Text(
                    'Actual ranking (worst → best)',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(data['ranked'] as List)
                      .asMap()
                      .entries
                      .map((entry) {
                    final rank = entry.key + 1;
                    final item =
                    entry.value as Map<String, dynamic>;
                    final pl = _toDouble(item['pl_percent']);
                    final isGain = pl >= 0;
                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.06),
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '$rank',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['symbol'].toString(),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${isGain ? "+" : ""}${pl.toStringAsFixed(2)}%',
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
                    );
                  }),
                ],
              ],

            // Accuracy rate
            if (_bc.beliefAccuracy.value > 0) ...[
              const SizedBox(height: 12),
              _infoRow(
                'Your memory accuracy rate',
                '${(_bc.beliefAccuracy.value * 100).toStringAsFixed(0)}%',
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Feature 3: Attention ───────────────────────────────────────────────────

  Widget _buildAttentionCard() {
    return Obx(() {
      final data = _bc.attentionData.value;
      if (data.isEmpty || data['error'] != null) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                icon: '👁',
                title: 'Attention Map',
                subtitle: 'Where your focus really goes',
              ),
              const SizedBox(height: 12),
              _emptyHint(data['error']?.toString() ??
                  'Browse your stocks to build attention data.'),
            ],
          ),
        );
      }

      final items =
      (data['items'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '👁',
              title: 'Attention Map',
              subtitle: 'Where your focus really goes',
            ),
            const SizedBox(height: 6),
            _insightBubble(
                data['insight']?.toString() ?? ''),
            const SizedBox(height: 14),
            ...items.map((item) {
              final symbol = item['symbol'].toString();
              final realPct =
              _toDouble(item['real_allocation_pct']);
              final attPct =
              _toDouble(item['attention_pct']);
              final gap = _toDouble(item['gap']);
              final isOver = gap > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (gap.abs() > 5)
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
                                  ? 'Overattended'
                                  : 'Ignored',
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
                    const SizedBox(height: 6),
                    // Real allocation bar
                    _dualBar(
                      label1: 'Portfolio',
                      pct1: realPct,
                      color1: const Color(0xFF6366F1),
                      label2: 'Attention',
                      pct2: attPct,
                      color2: const Color(0xFFF59E0B),
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

  // ── Feature 8: Silent Winners ──────────────────────────────────────────────

  Widget _buildSilentWinnersCard() {
    return Obx(() {
      final winners = _bc.silentWinners;
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🔇',
              title: 'Silent Winners',
              subtitle:
              'Good performers you\'re ignoring',
            ),
            const SizedBox(height: 12),
            if (winners.isEmpty)
              _emptyHint(
                'No silent winners right now. '
                    'All your good performers are getting attention.',
              )
            else
              ...winners.map((w) => _insightTile(
                symbol: w['symbol'].toString(),
                text: w['insight'].toString(),
                badge:
                '+${_toDouble(w['pl_percent']).toStringAsFixed(1)}%',
                badgeColor: const Color(0xFF10B981),
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF10B981),
              )),
          ],
        ),
      );
    });
  }

  // ── Feature 5: Half-Life ───────────────────────────────────────────────────

  Widget _buildHalfLifeCard() {
    return Obx(() {
      final list = _bc.halfLives;
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '⏳',
              title: 'Decision Age',
              subtitle:
              'How fresh are your buy decisions?',
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              _emptyHint('No holdings to analyze yet.')
            else
              ...list.map((item) {
                final score =
                _toDouble(item['score']);
                final ageDays = item['age_days'] as int;
                final needsReview =
                    item['needs_review'] == true;
                final pl =
                _toDouble(item['pl_percent']);
                final isGain = pl >= 0;

                return Padding(
                  padding:
                  const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['symbol'].toString(),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$ageDays days old',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          if (needsReview)
                            _miniTag(
                              'Review',
                              const Color(0xFFF59E0B),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            '${isGain ? "+" : ""}${pl.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isGain
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Freshness bar
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white
                              .withValues(alpha: 0.08),
                          valueColor:
                          AlwaysStoppedAnimation(
                            score > 0.6
                                ? const Color(0xFF10B981)
                                : score > 0.3
                                ? const Color(
                                0xFFF59E0B)
                                : const Color(
                                0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'].toString(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
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

  // ── Feature 4: Uncertainty ─────────────────────────────────────────────────

  Widget _buildUncertaintyCard() {
    return Obx(() {
      final data = _bc.uncertaintyBands.value;
      if (data.isEmpty || data['error'] != null) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                icon: '📊',
                title: 'Uncertainty Bands',
                subtitle:
                'Your portfolio is not a single number',
              ),
              const SizedBox(height: 12),
              _emptyHint(
                  data['error']?.toString() ?? ''),
            ],
          ),
        );
      }

      final current = _toDouble(data['current']);
      final optimistic = _toDouble(data['optimistic']);
      final likelyHigh = _toDouble(data['likely_high']);
      final likelyLow = _toDouble(data['likely_low']);
      final pessimistic = _toDouble(data['pessimistic']);
      final vol = _toDouble(data['volatility_pct']);

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '📊',
              title: 'Uncertainty Bands',
              subtitle:
              'Your portfolio is not a single number',
            ),
            const SizedBox(height: 16),

            // Current value
            Center(
              child: Column(
                children: [
                  const Text(
                    'Current Value',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_fmtNum(current)}',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
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

            // Band visualization
            _bandRow('🟢 Optimistic', optimistic,
                const Color(0xFF10B981)),
            const SizedBox(height: 8),
            _bandRow('🔵 Likely High', likelyHigh,
                const Color(0xFF6366F1)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6366F1)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Text(
                    '68% chance range: ',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    data['confidence_interval']
                        .toString(),
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _bandRow('🔵 Likely Low', likelyLow,
                const Color(0xFF6366F1)),
            const SizedBox(height: 8),
            _bandRow('🔴 Pessimistic', pessimistic,
                const Color(0xFFEF4444)),
          ],
        ),
      );
    });
  }

  // ── Feature 9: Cascade Risk ────────────────────────────────────────────────

  Widget _buildCascadeCard() {
    return Obx(() {
      final data = _bc.cascadeRisk.value;
      if (data.isEmpty || data['error'] != null) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                icon: '🌊',
                title: 'Cascade Risk',
                subtitle: 'What fails if one sector crashes',
              ),
              const SizedBox(height: 12),
              _emptyHint('No sector data available yet.'),
            ],
          ),
        );
      }

      final topSector = data['top_sector'].toString();
      final topPct = _toDouble(data['top_sector_pct']);
      final isConcentrated =
          data['is_concentrated'] == true;
      final affected =
      (data['affected_symbols'] as List? ?? [])
          .cast<String>();
      final breakdown =
      (data['sector_breakdown'] as Map? ?? {})
          .cast<String, dynamic>();

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🌊',
              title: 'Cascade Risk',
              subtitle:
              'What fails if one sector crashes',
            ),
            const SizedBox(height: 12),
            _insightBubble(
                data['cascade_insight'].toString()),
            const SizedBox(height: 14),
            if (isConcentrated)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'High concentration in $topSector '
                            '(${topPct.toStringAsFixed(1)}%). '
                            'Consider diversifying.',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Sector breakdown
            ...breakdown.entries.map((e) {
              final pct = _toDouble(e.value);
              return Padding(
                padding:
                const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white
                            .withValues(alpha: 0.07),
                        valueColor: AlwaysStoppedAnimation(
                          pct > 40
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (affected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: affected
                    .map((s) => _chip(s))
                    .toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Feature 10: Identity Drift ─────────────────────────────────────────────

  Widget _buildIdentityCard() {
    return Obx(() {
      final data = _bc.identityDrift.value;
      final hasDrifted = data['has_drifted'] == true;

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🪞',
              title: 'Identity Drift',
              subtitle:
              'Who you think you are vs how you act',
            ),
            const SizedBox(height: 12),
            if (data['drift_insight'] != null)
              _insightBubble(
                  data['drift_insight'].toString()),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _identityBox(
                    label: 'Stated Style',
                    value: _styleLabel(
                        data['stated_style']?.toString() ??
                            'unknown'),
                    color: const Color(0xFF6366F1),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8),
                  decoration: BoxDecoration(
                    color: (hasDrifted
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDrifted
                        ? Icons.swap_horiz_rounded
                        : Icons.check_rounded,
                    color: hasDrifted
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    size: 16,
                  ),
                ),
                Expanded(
                  child: _identityBox(
                    label: 'Actual Style',
                    value: _styleLabel(
                        data['inferred_style']
                            ?.toString() ??
                            'unknown'),
                    color: hasDrifted
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Style selector
            const Text(
              'Update your stated style:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                'long_term',
                'short_term',
                'swing',
              ].map((style) {
                final isSelected =
                    data['stated_style'] == style;
                return GestureDetector(
                  onTap: () =>
                      _bc.setInvestingStyle(style),
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 200),
                    margin:
                    const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.white
                          .withValues(alpha: 0.05),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.white
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      _styleLabel(style),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  // ── Feature 12: Friction Score ─────────────────────────────────────────────

  Widget _buildFrictionCard() {
    return Obx(() {
      final data = _bc.frictionScore.value;
      final avgMin =
          data['avg_minutes']?.toString() ?? '0';
      final label =
          data['label']?.toString() ?? 'No data yet';
      final isImpulsive = data['is_impulsive'] == true;
      final total =
          (data['total_buy_decisions'] as int?) ?? 0;

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '⚡',
              title: 'Decision Friction',
              subtitle: 'How fast do you pull the trigger?',
            ),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  Text(
                    '$avgMin min',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'average decision time',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _insightBubble(
                data['insight']?.toString() ?? ''),
            if (isImpulsive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'High impulsivity detected. '
                            'Try waiting at least 10 minutes '
                            'before buying.',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _infoRow(
                'Total buy decisions tracked',
                '$total'),
          ],
        ),
      );
    });
  }

  // ── Feature 13: Inaction ───────────────────────────────────────────────────

  Widget _buildInactionCard() {
    return Obx(() {
      final data = _bc.inactionData.value;
      final considered =
          (data['rebalance_considered'] as int?) ?? 0;
      final acted =
          (data['rebalance_acted'] as int?) ?? 0;
      final skipped =
          (data['rebalance_skipped'] as int?) ?? 0;
      final drift =
      _toDouble(data['drift_estimate_pct']);

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🚫',
              title: 'What You Didn\'t Do',
              subtitle: 'Inaction has a cost too',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _statBox(
                        'Considered', '$considered',
                        const Color(0xFF6366F1))),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox(
                        'Acted', '$acted',
                        const Color(0xFF10B981))),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox(
                        'Skipped', '$skipped',
                        const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 14),
            _insightBubble(
                data['insight']?.toString() ?? ''),
            if (drift > 0) ...[
              const SizedBox(height: 10),
              _infoRow(
                  'Estimated portfolio drift',
                  '~${drift.toStringAsFixed(1)}%'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _outlineBtn(
                    'Log: Considered Rebalancing',
                    Icons.psychology_outlined,
                        () => _bc.logRebalanceConsidered(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _outlineBtn(
                    'Log: Did Rebalance',
                    Icons.check_circle_outline_rounded,
                        () => _bc.logRebalanceActed(),
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Feature 14: Delayed Truth ──────────────────────────────────────────────

  Widget _buildDelayedTruthCard() {
    return Obx(() {
      final truths = _bc.delayedTruths;
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '🕰',
              title: 'Delayed Truth',
              subtitle:
              'How are your past decisions doing?',
            ),
            const SizedBox(height: 12),
            if (truths.isEmpty)
              _emptyHint(
                'Decisions show up here after 7 days. '
                    'Keep investing to build your history.',
              )
            else
              ...truths.map((t) {
                final change =
                _toDouble(t['change_pct']);
                final isGain = change >= 0;
                return _insightTile(
                  symbol: t['symbol'].toString(),
                  text: t['insight'].toString(),
                  badge:
                  '${isGain ? "+" : ""}${change.toStringAsFixed(1)}%',
                  badgeColor: isGain
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  icon: isGain
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  iconColor: isGain
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  sub:
                  '${t['days_ago']} days ago · '
                      '₹${_fmtNum(_toDouble(t['price_then']))} → '
                      '₹${_fmtNum(_toDouble(t['price_now']))}',
                );
              }),
          ],
        ),
      );
    });
  }

  // ── Feature 15: Internal Conflict ─────────────────────────────────────────

  Widget _buildConflictCard() {
    return Obx(() {
      final data = _bc.conflictData.value;
      final hasConflict = data['has_conflict'] == true;
      final stated =
          data['stated_risk']?.toString() ?? 'medium';
      final inferred =
          data['inferred_risk']?.toString() ?? 'medium';
      final vol =
      _toDouble(data['avg_volatility']);

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '⚔',
              title: 'Internal Conflict',
              subtitle:
              'Your stated vs actual risk tolerance',
            ),
            const SizedBox(height: 12),
            _insightBubble(
                data['insight']?.toString() ?? ''),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _identityBox(
                    label: 'Stated Risk',
                    value: _riskLabel(stated),
                    color: const Color(0xFF6366F1),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8),
                  decoration: BoxDecoration(
                    color: (hasConflict
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasConflict
                        ? Icons.warning_rounded
                        : Icons.check_rounded,
                    color: hasConflict
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    size: 16,
                  ),
                ),
                Expanded(
                  child: _identityBox(
                    label: 'Actual Risk',
                    value: _riskLabel(inferred),
                    color: hasConflict
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
              'Portfolio avg volatility',
              '${vol.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            // Risk selector
            const Text(
              'Update your stated risk tolerance:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high']
                  .map((risk) {
                final isSelected = stated == risk;
                return GestureDetector(
                  onTap: () =>
                      _bc.setRiskTolerance(risk),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    margin:
                    const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.white
                          .withValues(alpha: 0.05),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.white
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      _riskLabel(risk),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  // ── Feature 11: Confidence Illusion ───────────────────────────────────────

  Widget _buildConfidenceCard() {
    return Obx(() {
      final data = _bc.confidenceIllusion.value;
      if (data['error'] != null) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                icon: '📈',
                title: 'Confidence Illusion',
                subtitle:
                'Does confidence predict your returns?',
              ),
              const SizedBox(height: 12),
              _emptyHint(data['error'].toString()),
              const SizedBox(height: 12),
              _outlineBtn(
                'Log a confidence rating',
                Icons.star_outline_rounded,
                    () => _showConfidenceDialog(),
              ),
            ],
          ),
        );
      }

      final correlation =
      _toDouble(data['correlation']);
      final points =
          (data['data_points'] as int?) ?? 0;
      final avgConf =
      _toDouble(data['avg_confidence']);
      final avgRet =
      _toDouble(data['avg_return']);

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
              icon: '📈',
              title: 'Confidence Illusion',
              subtitle:
              'Does confidence predict your returns?',
            ),
            const SizedBox(height: 14),
            _insightBubble(
                data['insight']?.toString() ?? ''),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _statBox(
                        'Avg Confidence',
                        '${(avgConf * 100).toStringAsFixed(0)}%',
                        const Color(0xFF6366F1))),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox(
                        'Avg Return',
                        '${avgRet >= 0 ? "+" : ""}${avgRet.toStringAsFixed(1)}%',
                        avgRet >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))),
                const SizedBox(width: 8),
                Expanded(
                    child: _statBox(
                        'Correlation',
                        correlation.toStringAsFixed(2),
                        correlation > 0.3
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
                'Data points', '$points decisions'),
            const SizedBox(height: 12),
            _outlineBtn(
              'Log a confidence rating',
              Icons.star_outline_rounded,
                  () => _showConfidenceDialog(),
            ),
          ],
        ),
      );
    });
  }

  // ── Confidence dialog ──────────────────────────────────────────────────────

  void _showConfidenceDialog() {
    double confidence = 0.7;
    double actualReturn = 0.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: const Color(0xFF131D2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Decision Confidence',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rate how confident you felt about a past decision '
                      'and what the actual return was.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: confidence,
                  onChanged: (v) =>
                      setModalState(() => confidence = v),
                  activeColor: const Color(0xFF6366F1),
                  inactiveColor: Colors.white
                      .withValues(alpha: 0.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Actual Return: ${actualReturn >= 0 ? "+" : ""}${actualReturn.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                Slider(
                  value: actualReturn,
                  min: -30,
                  max: 30,
                  onChanged: (v) => setModalState(
                          () => actualReturn = v),
                  activeColor: actualReturn >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  inactiveColor: Colors.white
                      .withValues(alpha: 0.1),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pop(ctx),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.06),
                            borderRadius:
                            BorderRadius.circular(
                                12),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color:
                                Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _bc.recordConfidence(
                            confidence: confidence,
                            actualReturn: actualReturn,
                          );
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(
                                12),
                            gradient:
                            const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF4F46E5),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable UI components ─────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _cardHeader({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _insightBubble(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _resultBanner(
      {required bool isCorrect, required String text}) {
    final color = isCorrect
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightTile({
    required String symbol,
    required String text,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    String? sub,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: iconColor, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                symbol,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                  badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: Color(0xFF475569),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _dualBar({
    required String label1,
    required double pct1,
    required Color color1,
    required String label2,
    required double pct2,
    required Color color2,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label1,
              style:
              TextStyle(color: color1, fontSize: 10),
            ),
            const SizedBox(width: 4),
            Text(
              '${pct1.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color1,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              label2,
              style:
              TextStyle(color: color2, fontSize: 10),
            ),
            const SizedBox(width: 4),
            Text(
              '${pct2.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color2,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct1 / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor:
                Colors.white.withValues(alpha: 0.07),
                valueColor:
                AlwaysStoppedAnimation(color1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct2 / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white
                      .withValues(alpha: 0.07),
                  valueColor:
                  AlwaysStoppedAnimation(color2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bandRow(
      String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ),
        Text(
          '₹${_fmtNum(value)}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statBox(
      String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _identityBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: 0.2)),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _miniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _outlineBtn(
      String label,
      IconData icon,
      VoidCallback onTap, {
        Color color = const Color(0xFF6366F1),
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
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
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  static String _styleLabel(String style) {
    switch (style) {
      case 'long_term':  return 'Long Term';
      case 'short_term': return 'Short Term';
      case 'swing':      return 'Swing';
      default:           return 'Unknown';
    }
  }

  static String _riskLabel(String risk) {
    switch (risk) {
      case 'low':    return 'Conservative';
      case 'medium': return 'Moderate';
      case 'high':   return 'Aggressive';
      default:       return risk;
    }
  }
}