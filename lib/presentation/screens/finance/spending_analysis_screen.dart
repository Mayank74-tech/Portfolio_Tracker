// lib/presentation/screens/finance/spending_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/portfolio_controller.dart';
import '../../widgets/common/glass_container.dart';

class SpendingAnalysisScreen extends StatefulWidget {
  const SpendingAnalysisScreen({super.key});

  @override
  State<SpendingAnalysisScreen> createState() =>
      _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState
    extends State<SpendingAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final FinanceController _fc;
  late final PortfolioController _pc;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fc = Get.find<FinanceController>();
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
              _buildTopBar(),
              Expanded(
                child: Obx(() {
                  final data = _fc.analysis.value;
                  if (data.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    color: const Color(0xFF0EA5E9),
                    backgroundColor:
                    const Color(0xFF131D2E),
                    onRefresh: () async =>
                        _fc.loadAnalysis(),
                    child: ListView(
                      physics:
                      const BouncingScrollPhysics(
                        parent:
                        AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 80),
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 14),
                        _buildSpendingScore(data),
                        const SizedBox(height: 14),
                        _buildDonutChart(data),
                        const SizedBox(height: 14),
                        _buildCategoryDetails(data),
                        const SizedBox(height: 14),
                        _buildBiggestExpense(data),
                        const SizedBox(height: 14),
                        _buildSpendingInsights(data),
                        const SizedBox(height: 14),
                        _buildDailyAverage(data),
                        const SizedBox(height: 14),
                        _buildFinancialHealth(data),
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

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
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
                  'Spending Analysis',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Deep dive into your spending patterns',
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

  // ── Period selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    const periods = ['1W', '1M', '3M', '6M'];
    return Obx(() => GlassContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: periods.map((p) {
          final isActive =
              _fc.selectedPeriod.value == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => _fc.setPeriod(p),
              child: AnimatedContainer(
                duration: const Duration(
                    milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0EA5E9)
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }

  // ── Spending score ─────────────────────────────────────────────────────────

  Widget _buildSpendingScore(
      Map<String, dynamic> data) {
    final savings = _toDouble(data['savings_rate']);
    final spent = _toDouble(data['total_spent']);
    final earned = _toDouble(data['total_earned']);

    // Score 0-100 based on savings rate
    final score = savings.clamp(0.0, 100.0).toInt();
    final scoreColor = score >= 30
        ? const Color(0xFF10B981)
        : score >= 15
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final scoreLabel = score >= 30
        ? 'Excellent Saver 🌟'
        : score >= 15
        ? 'Good Balance 👍'
        : 'Needs Attention ⚠️';

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      borderColor: scoreColor.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              // Score circle
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 7,
                        backgroundColor: Colors.white
                            .withValues(alpha: 0.08),
                        valueColor:
                        AlwaysStoppedAnimation(
                            scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Savings rate: '
                          '${savings.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earned ₹${_fmtNum(earned)}, '
                          'Spent ₹${_fmtNum(spent)}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Donut chart ────────────────────────────────────────────────────────────

  Widget _buildDonutChart(Map<String, dynamic> data) {
    final categories =
    (data['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .take(6)
        .toList();

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          // Custom donut chart using CustomPaint
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _DonutChartPainter(
                    categories: categories),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '₹${_fmtNum(_toDouble(data['total_spent']))}',
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categories.map((cat) {
              final color =
              _categoryColor(cat['name'].toString());
              final pct =
              _toDouble(cat['percentage']);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                      BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${cat['emoji']} '
                        '${_capitalize(cat['name'].toString())} '
                        '${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Category details ───────────────────────────────────────────────────────

  Widget _buildCategoryDetails(
      Map<String, dynamic> data) {
    final categories =
    (data['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Details',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Category',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Txns',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Share',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 8),
          ...categories.map((cat) {
            final color =
            _categoryColor(cat['name'].toString());
            final pct = _toDouble(cat['percentage']);
            final amount = _toDouble(cat['amount']);
            final count =
                (cat['count'] as int?) ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(
                              cat['emoji'].toString(),
                              style: const TextStyle(
                                  fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _capitalize(
                                    cat['name']
                                        .toString()),
                                style: const TextStyle(
                                  color:
                                  Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${_fmtNum(amount)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.white
                          .withValues(alpha: 0.06),
                      valueColor:
                      AlwaysStoppedAnimation(color),
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

  // ── Biggest expense ────────────────────────────────────────────────────────

  Widget _buildBiggestExpense(
      Map<String, dynamic> data) {
    final biggest = data['biggest_expense']
    as Map<String, dynamic>?;
    if (biggest == null) return const SizedBox.shrink();

    final amount = _toDouble(biggest['amount']);
    final desc = biggest['description'].toString();
    final cat = biggest['category'].toString();
    final date = DateTime.tryParse(
        biggest['date']?.toString() ?? '');

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💸 Biggest Single Expense',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444)
                  .withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor(cat)
                        .withValues(alpha: 0.12),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(cat),
                      style:
                      const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (date != null)
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '-₹${_fmtNum(amount)}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Spending insights ──────────────────────────────────────────────────────

  Widget _buildSpendingInsights(
      Map<String, dynamic> data) {
    final categories =
    (data['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final total = _toDouble(data['total_spent']);
    final savings = _toDouble(data['savings_rate']);

    final insights = <String>[];

    // Generate insights from data
    for (final cat in categories) {
      final pct = _toDouble(cat['percentage']);
      final name = cat['name'].toString();

      if (name == 'food' && pct > 35) {
        insights.add(
          '🍔 Food & dining is ${pct.toStringAsFixed(1)}% '
              'of spending. Consider meal prep to reduce costs.',
        );
      }
      if (name == 'entertainment' && pct > 15) {
        insights.add(
          '🎬 Entertainment is ${pct.toStringAsFixed(1)}% '
              'of spending. Check for unused subscriptions.',
        );
      }
      if (name == 'shopping' && pct > 25) {
        insights.add(
          '🛍 Shopping at ${pct.toStringAsFixed(1)}% '
              'is high. Try a 48-hour rule before purchases.',
        );
      }
      if (name == 'investment' && pct < 10) {
        insights.add(
          '📈 Only ${pct.toStringAsFixed(1)}% going to '
              'investments. Aim for at least 20%.',
        );
      }
    }

    if (savings < 10) {
      insights.add(
        '⚠️ Savings rate of ${savings.toStringAsFixed(1)}% '
            'is low. Try the 50-30-20 rule: '
            '50% needs, 30% wants, 20% savings.',
      );
    }

    if (insights.isEmpty) {
      insights.add(
        '✅ Your spending patterns look healthy. '
            'Keep maintaining this balance!',
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 AI Spending Insights',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(
                bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1)
                    .withValues(alpha: 0.07),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1)
                      .withValues(alpha: 0.15),
                ),
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
          )),
        ],
      ),
    );
  }

  // ── Daily average ──────────────────────────────────────────────────────────

  Widget _buildDailyAverage(Map<String, dynamic> data) {
    final total = _toDouble(data['total_spent']);
    final txCount =
        (data['transaction_count'] as int?) ?? 1;
    final daily = (data['daily_spend']
    as Map<String, dynamic>? ??
        {});
    // ✅ FIXED
    final days = daily.keys.length.clamp(1, 30);
    final dailyAvg = total / days;
    final avgTxPerDay = txCount / days;

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
            'Daily Averages',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _avgBox(
                  'Per Day',
                  '₹${_fmtNum(dailyAvg)}',
                  const Color(0xFF0EA5E9),
                  Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _avgBox(
                  'Per Transaction',
                  '₹${_fmtNum(txCount == 0 ? 0 : total / txCount)}',
                  const Color(0xFFF59E0B),
                  Icons.receipt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _avgBox(
                  'Txns/Day',
                  avgTxPerDay.toStringAsFixed(1),
                  const Color(0xFF8B5CF6),
                  Icons.repeat_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avgBox(String label, String value,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
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

  // ── Financial health ───────────────────────────────────────────────────────

  Widget _buildFinancialHealth(
      Map<String, dynamic> data) {
    final savings = _toDouble(data['savings_rate']);
    final categories =
    (data['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final investPct = _toDouble(
      categories
          .firstWhere(
            (c) => c['name'] == 'investment',
        orElse: () => {'percentage': 0.0},
      )['percentage'],
    );

    final needsPct = _toDouble(
      categories
          .where((c) => [
        'food',
        'utilities',
        'health',
        'transport'
      ].contains(c['name']))
          .fold<double>(0.0,
              (sum, c) => sum + _toDouble(c['percentage'])),
    );

    final wantsPct = _toDouble(
      categories
          .where((c) => [
        'shopping',
        'entertainment'
      ].contains(c['name']))
          .fold<double>(0.0,
              (sum, c) => sum + _toDouble(c['percentage'])),
    );

    final rules = [
      (
      'Savings Rate',
      '${savings.toStringAsFixed(1)}%',
      savings >= 20
          ? '✅'
          : savings >= 10
          ? '⚠️'
          : '❌',
      'Target: 20%+',
      savings / 20,
      ),
      (
      'Investment Ratio',
      '${investPct.toStringAsFixed(1)}%',
      investPct >= 15
          ? '✅'
          : investPct >= 8
          ? '⚠️'
          : '❌',
      'Target: 15%+',
      investPct / 15,
      ),
      (
      'Needs (50 Rule)',
      '${needsPct.toStringAsFixed(1)}%',
      needsPct <= 50
          ? '✅'
          : needsPct <= 60
          ? '⚠️'
          : '❌',
      'Target: ≤50%',
      1 - (needsPct - 50).clamp(0.0, 50.0) / 50,
      ),
      (
      'Wants (30 Rule)',
      '${wantsPct.toStringAsFixed(1)}%',
      wantsPct <= 30
          ? '✅'
          : wantsPct <= 40
          ? '⚠️'
          : '❌',
      'Target: ≤30%',
      1 - (wantsPct - 30).clamp(0.0, 30.0) / 30,
      ),
    ];

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
            '🏦 Financial Health Check',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on the 50-30-20 budgeting rule',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) {
            final score =
            rule.$5.clamp(0.0, 1.0);
            final color = score >= 0.8
                ? const Color(0xFF10B981)
                : score >= 0.5
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

            return Padding(
              padding:
              const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rule.$3,
                        style: const TextStyle(
                            fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rule.$1,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        rule.$2,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rule.$4,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 5,
                      backgroundColor: Colors.white
                          .withValues(alpha: 0.07),
                      valueColor:
                      AlwaysStoppedAnimation(color),
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

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '📊',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'No spending data yet',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect a bank account to see\nyour spending analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0EA5E9),
                    Color(0xFF0284C7),
                  ],
                ),
              ),
              child: const Text(
                'Connect Bank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  static Color _categoryColor(String cat) {
    const map = {
      'food':          Color(0xFFEF4444),
      'transport':     Color(0xFFF59E0B),
      'shopping':      Color(0xFF8B5CF6),
      'investment':    Color(0xFF10B981),
      'utilities':     Color(0xFF0EA5E9),
      'entertainment': Color(0xFFF97316),
      'health':        Color(0xFFEC4899),
      'other':         Color(0xFF64748B),
    };
    return map[cat] ?? const Color(0xFF64748B);
  }

  static String _categoryEmoji(String cat) {
    const map = {
      'food':          '🍔',
      'transport':     '🚗',
      'shopping':      '🛍',
      'investment':    '📈',
      'utilities':     '💡',
      'entertainment': '🎬',
      'health':        '🏥',
      'other':         '💰',
    };
    return map[cat] ?? '💰';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmtNum(double v) {
    if (v >= 10000000) {
      return '${(v / 10000000).toStringAsFixed(2)}Cr';
    }
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Donut Chart Painter ────────────────────────────────────────────────────────

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;

  const _DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.05),
    );

    double startAngle = -90 * (3.14159 / 180);

    for (final cat in categories) {
      final pct = _toDouble(cat['percentage']) / 100;
      final sweepAngle = pct * 2 * 3.14159;
      final color = _categoryColor(cat['name'].toString());

      paint.color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.02, // small gap between segments
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.categories != categories;

  static Color _categoryColor(String cat) {
    const map = {
      'food':          Color(0xFFEF4444),
      'transport':     Color(0xFFF59E0B),
      'shopping':      Color(0xFF8B5CF6),
      'investment':    Color(0xFF10B981),
      'utilities':     Color(0xFF0EA5E9),
      'entertainment': Color(0xFFF97316),
      'health':        Color(0xFFEC4899),
      'other':         Color(0xFF64748B),
    };
    return map[cat] ?? const Color(0xFF64748B);
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}
