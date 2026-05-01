// lib/presentation/screens/finance/finance_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/portfolio_controller.dart';
import '../../../data/services/remote/mock_bank_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/glass_container.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends State<FinanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final FinanceController _fc;
  late final PortfolioController _pc;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fc = Get.isRegistered<FinanceController>()
        ? Get.find<FinanceController>()
        : Get.put(FinanceController());
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
                  final hasAccounts =
                      _fc.accounts.isNotEmpty;
                  return hasAccounts
                      ? _buildDashboard()
                      : _buildConnectState();
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
                  'Personal Finance',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Spending patterns & bank overview',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => _fc.accounts.isNotEmpty
              ? _iconBox(
            Icons.add_rounded,
            onTap: () => _showBankPicker(),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // ── Connect state (no accounts yet) ───────────────────────────────────────

  Widget _buildConnectState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                const Text(
                  '🏦',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connect Your Bank',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'See where your money goes. Connect a mock '
                      'bank account to visualize spending patterns '
                      'alongside your investments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _showBankPicker(),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0EA5E9),
                          Color(0xFF0284C7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9)
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Connect Bank Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mock data only — no real bank access',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSupportedBanks(),
        ],
      ),
    );
  }

  Widget _buildSupportedBanks() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supported Banks',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockBankService.availableBanks
                .map((bank) => Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: 0.04),
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(bank['logo']!,
                      style: const TextStyle(
                          fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    bank['name']!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Main dashboard ─────────────────────────────────────────────────────────

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: const Color(0xFF0EA5E9),
      backgroundColor: const Color(0xFF131D2E),
      onRefresh: () async {
        for (final acc in _fc.accounts) {
          await _fc
              .syncAccount(acc['id'].toString());
        }
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 14),
          _buildAccountCards(),
          const SizedBox(height: 14),
          _buildSpendingOverview(),
          const SizedBox(height: 14),
          _buildCategoryBreakdown(),
          const SizedBox(height: 14),
          _buildSpendVsInvest(),
          const SizedBox(height: 14),
          _buildDailyTrend(),
          const SizedBox(height: 14),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    const periods = ['1W', '1M', '3M', '6M'];
    return Obx(() => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
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

  // ── Account cards ──────────────────────────────────────────────────────────

  Widget _buildAccountCards() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connected Accounts',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._fc.accounts.map((acc) {
          final balance =
          _toDouble(acc['balance']);
          final lastSynced =
              acc['lastSynced']?.toString() ?? '';
          final syncDate =
          DateTime.tryParse(lastSynced);

          return GlassContainer(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9)
                        .withValues(alpha: 0.12),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc['bankName'].toString(),
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${acc['accountType']} · '
                            '${acc['maskedNumber']}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                      if (syncDate != null)
                        Text(
                          'Synced ${_timeAgo(syncDate)}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmtNum(balance)}',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _fc.syncAccount(
                        acc['id'].toString(),
                      ),
                      child: const Text(
                        'Sync',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    ));
  }

  // ── Spending overview ──────────────────────────────────────────────────────

  Widget _buildSpendingOverview() {
    return Obx(() {
      final data = _fc.analysis.value;
      if (data.isEmpty) {
        return const SizedBox.shrink();
      }

      final spent = _toDouble(data['total_spent']);
      final earned = _toDouble(data['total_earned']);
      final savings = _toDouble(data['savings_rate']);
      final isPositive = savings >= 0;

      return GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        borderColor: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Overview',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${_fmtNum(spent)}',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'total spent this period',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _overviewStat(
                    'Earned',
                    '₹${_fmtNum(earned)}',
                    const Color(0xFF10B981),
                    Icons.arrow_downward_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12),
                  color: Colors.white
                      .withValues(alpha: 0.07),
                ),
                Expanded(
                  child: _overviewStat(
                    'Savings Rate',
                    '${savings.toStringAsFixed(1)}%',
                    isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12),
                  color: Colors.white
                      .withValues(alpha: 0.07),
                ),
                Expanded(
                  child: _overviewStat(
                    'Transactions',
                    '${data['transaction_count'] ?? 0}',
                    const Color(0xFF0EA5E9),
                    Icons.receipt_long_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _overviewStat(
      String label, String value, Color color,
      IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            )),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Category breakdown ─────────────────────────────────────────────────────

  Widget _buildCategoryBreakdown() {
    return Obx(() {
      final data = _fc.analysis.value;
      final categories =
      (data['categories'] as List? ?? [])
          .cast<Map<String, dynamic>>();

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
              'Spending by Category',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.take(6).map((cat) {
              final pct = _toDouble(cat['percentage']);
              final amount = _toDouble(cat['amount']);
              final name = cat['name'].toString();
              final color = _categoryColor(name);
              final emoji = cat['emoji'].toString();

              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(emoji,
                            style: const TextStyle(
                                fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _capitalize(name),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₹${_fmtNum(amount)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${pct.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100)
                            .clamp(0.0, 1.0),
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
    });
  }

  // ── Spend vs Invest ────────────────────────────────────────────────────────

  Widget _buildSpendVsInvest() {
    return Obx(() {
      final summary = _pc.summary;
      final totalInvested =
      _toDouble(summary['total_investment']);
      final comparison = _fc
          .getSpendVsInvestComparison(totalInvested);

      final spent =
      _toDouble(comparison['total_spent']);
      final invested = _toDouble(
          comparison['invested_this_period']);
      final ratio =
      _toDouble(comparison['invest_ratio']);

      if (spent == 0) return const SizedBox.shrink();

      final total = spent + invested;
      final spendPct =
      total == 0 ? 0.5 : spent / total;
      final investPct =
      total == 0 ? 0.5 : invested / total;

      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💸 Spend vs 📈 Invest',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Visual split bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    flex: (spendPct * 100).round(),
                    child: Container(
                      height: 24,
                      color: const Color(0xFFEF4444)
                          .withValues(alpha: 0.7),
                      child: Center(
                        child: Text(
                          '${(spendPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (investPct * 100).round()
                        .clamp(1, 99),
                    child: Container(
                      height: 24,
                      color: const Color(0xFF10B981)
                          .withValues(alpha: 0.7),
                      child: Center(
                        child: Text(
                          '${(investPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444)
                          .withValues(alpha: 0.7),
                      borderRadius:
                      BorderRadius.circular(3),
                    )),
                const SizedBox(width: 5),
                Text('Spent ₹${_fmtNum(spent)}',
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11)),
                const Spacer(),
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981)
                          .withValues(alpha: 0.7),
                      borderRadius:
                      BorderRadius.circular(3),
                    )),
                const SizedBox(width: 5),
                Text(
                    'Invested ₹${_fmtNum(invested)}',
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                comparison['insight'].toString(),
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Daily trend ────────────────────────────────────────────────────────────

  Widget _buildDailyTrend() {
    return Obx(() {
      final data = _fc.analysis.value;
      final daily = (data['daily_spend']
      as Map<String, dynamic>? ??
          {});
      if (daily.isEmpty) {
        return const SizedBox.shrink();
      }

      final entries = daily.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final maxVal = entries.fold(
          0.0,
              (m, e) => _toDouble(e.value) > m
              ? _toDouble(e.value)
              : m);

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
              'Daily Spending',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final barWidth = constraints.maxWidth /
                      entries.length.clamp(1, 30);
                  return Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: entries
                        .take(30)
                        .map((entry) {
                      final val =
                      _toDouble(entry.value);
                      final h = maxVal == 0
                          ? 4.0
                          : (val / maxVal) *
                          70;
                      return Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 1),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.end,
                            children: [
                              Container(
                                height: h.clamp(4.0, 70.0),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFF0EA5E9)
                                      .withValues(
                                      alpha: 0.6),
                                  borderRadius:
                                  BorderRadius.circular(
                                      3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Recent transactions ────────────────────────────────────────────────────

  Widget _buildRecentTransactions() {
    return Obx(() {
      final txs =
      _fc.transactions.take(10).toList();
      if (txs.isEmpty) {
        return const SizedBox.shrink();
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
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Get.toNamed(AppRoutes.TRANSACTIONS),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...txs.map((tx) {
              final isCredit = tx['type'] == 'credit';
              final amount =
              _toDouble(tx['amount']);
              final cat =
              tx['category'].toString();
              final date = DateTime.tryParse(
                  tx['date']?.toString() ?? '');

              return Padding(
                padding:
                const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _categoryColor(cat)
                            .withValues(alpha: 0.12),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _categoryEmoji(cat),
                          style: const TextStyle(
                              fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['description']
                                .toString(),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w500,
                            ),
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                          if (date != null)
                            Text(
                              _formatDate(date),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? "+" : "-"}₹${_fmtNum(amount)}',
                      style: TextStyle(
                        color: isCredit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF1F5F9),
                        fontSize: 13,
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
    });
  }

  // ── Bank picker bottom sheet ───────────────────────────────────────────────

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(
            16, 20, 16, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF131D2E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Bank',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...MockBankService.availableBanks
                .map((bank) => GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final success =
                await _fc.connectBank(
                  bankId: bank['id']!,
                  accountType: 'savings',
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        '${bank['name']} connected!',
                      ),
                      backgroundColor:
                      const Color(0xFF10B981),
                      behavior:
                      SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            12),
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: 0.04),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Text(bank['logo']!,
                        style: const TextStyle(
                            fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      bank['name']!,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
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

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
