// lib/presentation/screens/finance/finance_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/portfolio_controller.dart';
import '../../../data/services/remote/mock_bank_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/glass_container.dart';
import 'bank_connect_flow.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen>
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
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ✅ Open new multi-step bank connect flow
  void _openBankConnect() {
    Get.to(
          () => const BankConnectFlow(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  // ✅ Confirm before disconnecting
  Future<void> _confirmDisconnect(Map<String, dynamic> account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.link_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Disconnect Account?',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will remove ${account['bankName']} and all its transactions from this app.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Disconnect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
    );

    if (result == true) {
      await _fc.disconnectAccount(account['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account['bankName']} disconnected'),
            backgroundColor: const Color(0xFF131D2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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
                  return _fc.accounts.isNotEmpty
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

  // ════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _iconBox(
            Icons.chevron_left_rounded,
            onTap: () => Get.back(),
          ),
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
                    letterSpacing: -0.3,
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
            onTap: _openBankConnect,
            highlight: true,
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CONNECT STATE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildConnectState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeroConnect(),
          const SizedBox(height: 20),
          _buildSupportedBanks(),
          const SizedBox(height: 16),
          _buildBenefitsList(),
        ],
      ),
    );
  }

  Widget _buildHeroConnect() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF081220),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connect Your Bank',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'See where your money goes. Link a bank account\n'
                'to visualize spending alongside your investments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Connect button
          GestureDetector(
            onTap: _openBankConnect,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Connect Bank Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: const Color(0xFF64748B),
                size: 12,
              ),
              const SizedBox(width: 5),
              const Text(
                'Bank-level encryption · Mock data only',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF0EA5E9),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Supported Banks',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockBankService.availableBanks
                .map((bank) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(bank['logo']!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    bank['name']!,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildBenefitsList() {
    final benefits = [
      ('💰', 'Auto-categorize spending', 'Food, transport, shopping & more'),
      ('📊', 'Visual analytics', 'Charts, trends & breakdowns'),
      ('🎯', 'Spend vs Invest insights', 'Balance saving with investing'),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you\'ll get',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...benefits.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        b.$1,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          b.$3,
                          style: const TextStyle(
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
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MAIN DASHBOARD
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: const Color(0xFF0EA5E9),
      backgroundColor: const Color(0xFF131D2E),
      onRefresh: () => _fc.syncAllAccounts(),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

  // ════════════════════════════════════════════════════════════════════════
  // PERIOD SELECTOR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPeriodSelector() {
    const periods = ['1W', '1M', '3M', '6M'];
    return Obx(() => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: periods.map((p) {
          final isActive = _fc.selectedPeriod.value == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => _fc.setPeriod(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF0EA5E9),
                      Color(0xFF0284C7),
                    ],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(8),
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
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNT CARDS (with swipe-to-disconnect)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAccountCards() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Connected Accounts',
              style: TextStyle(
                color: const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_fc.accounts.length}',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._fc.accounts.map((acc) => _buildAccountCard(acc)),
      ],
    ));
  }

  Widget _buildAccountCard(Map<String, dynamic> acc) {
    final balance = _toDouble(acc['balance']);
    final lastSynced = acc['lastSynced']?.toString() ?? '';
    final syncDate = DateTime.tryParse(lastSynced);
    final bankLogo = _bankLogo(acc['bankName']?.toString() ?? '');

    return Dismissible(
      key: ValueKey(acc['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDisconnect(acc);
        return false; // we handle deletion ourselves
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Disconnect',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  bankLogo,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc['bankName'].toString(),
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_capitalize(acc['accountType']?.toString() ?? '')} · '
                        '${acc['maskedNumber']}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  if (syncDate != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Synced ${_timeAgo(syncDate)}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_fmtNum(balance)}',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _fc.syncAccount(acc['id'].toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: const Color(0xFF0EA5E9),
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'Sync',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SPENDING OVERVIEW
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSpendingOverview() {
    return Obx(() {
      final data = _fc.analysis.value;
      if (data.isEmpty) return const SizedBox.shrink();

      final spent = _toDouble(data['total_spent']);
      final earned = _toDouble(data['total_earned']);
      final savings = _toDouble(data['savings_rate']);
      final isPositive = savings >= 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF081220),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Overview',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${_fmtNum(spent)}',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.8,
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
                _statDivider(),
                Expanded(
                  child: _overviewStat(
                    'Savings',
                    '${savings.toStringAsFixed(1)}%',
                    isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                  ),
                ),
                _statDivider(),
                Expanded(
                  child: _overviewStat(
                    'Txns',
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

  Widget _statDivider() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: Colors.white.withValues(alpha: 0.07),
  );

  Widget _overviewStat(
      String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CATEGORY BREAKDOWN
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryBreakdown() {
    return Obx(() {
      final data = _fc.analysis.value;
      final categories = (data['categories'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      if (categories.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending by Category',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (categories.length > 6)
                  GestureDetector(
                    onTap: () =>
                        Get.toNamed(AppRoutes.SPENDING_ANALYSIS),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.take(6).map((cat) {
              final pct = _toDouble(cat['percentage']);
              final amount = _toDouble(cat['amount']);
              final name = cat['name'].toString();
              final color = _categoryColor(name);
              final emoji = cat['emoji'].toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _capitalize(name),
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '₹${_fmtNum(amount)}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: (pct / 100).clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) =>
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 5,
                              backgroundColor:
                              Colors.white.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
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

  // ════════════════════════════════════════════════════════════════════════
  // SPEND vs INVEST
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSpendVsInvest() {
    return Obx(() {
      final summary = _pc.summary;
      final totalInvested = _toDouble(summary['total_investment']);
      final comparison = _fc.getSpendVsInvestComparison(totalInvested);

      final spent = _toDouble(comparison['total_spent']);
      final invested = _toDouble(comparison['invested_this_period']);
      final ratio = _toDouble(comparison['invest_ratio']);

      if (spent == 0) return const SizedBox.shrink();

      final total = spent + invested;
      final spendPct = total == 0 ? 0.5 : spent / total;
      final investPct = total == 0 ? 0.5 : invested / total;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('💸', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  'Spend vs Invest',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Text('📈', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // Animated split bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => Row(
                  children: [
                    Expanded(
                      flex: ((spendPct * 100) * value).round().clamp(1, 99),
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEF4444).withValues(alpha: 0.8),
                              const Color(0xFFDC2626).withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(spendPct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex:
                      ((investPct * 100) * value).round().clamp(1, 99),
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.8),
                              const Color(0xFF059669).withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(investPct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legendDot(const Color(0xFFEF4444)),
                const SizedBox(width: 5),
                Text(
                  'Spent ₹${_fmtNum(spent)}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                _legendDot(const Color(0xFF10B981)),
                const SizedBox(width: 5),
                Text(
                  'Invested ₹${_fmtNum(invested)}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF38BDF8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
            ),
          ],
        ),
      );
    });
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════
  // DAILY TREND
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDailyTrend() {
    return Obx(() {
      final data = _fc.analysis.value;
      final daily =
      (data['daily_spend'] as Map<String, dynamic>? ?? {});
      if (daily.isEmpty) return const SizedBox.shrink();

      final entries = daily.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final maxVal = entries.fold(
        0.0,
            (m, e) => _toDouble(e.value) > m ? _toDouble(e.value) : m,
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.take(30).map((entry) {
                  final val = _toDouble(entry.value);
                  final h = maxVal == 0 ? 4.0 : (val / maxVal) * 70;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: h.clamp(4.0, 70.0)),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, height, __) => Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.8),
                                const Color(0xFF0284C7)
                                    .withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // RECENT TRANSACTIONS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildRecentTransactions() {
    return Obx(() {
      final txs = _fc.transactions.take(10).toList();
      if (txs.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  onTap: () => Get.toNamed(AppRoutes.TRANSACTIONS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF0EA5E9),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...txs.map((tx) {
              final isCredit = tx['type'] == 'credit';
              final amount = _toDouble(tx['amount']);
              final cat = tx['category'].toString();
              final date =
              DateTime.tryParse(tx['date']?.toString() ?? '');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _categoryColor(cat).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          _categoryEmoji(cat),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['description'].toString(),
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (date != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(date),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? "+" : "-"}₹${_fmtNum(amount)}',
                      style: TextStyle(
                        color: isCredit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE2E8F0),
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
      );
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════

  Widget _iconBox(
      IconData icon, {
        VoidCallback? onTap,
        bool highlight = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
              : const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: highlight
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: highlight
              ? const Color(0xFF0EA5E9)
              : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  static String _bankLogo(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('hdfc')) return '🏦';
    if (lower.contains('sbi') || lower.contains('state bank')) return '🏛';
    if (lower.contains('icici')) return '💳';
    if (lower.contains('axis')) return '💰';
    if (lower.contains('kotak')) return '🏪';
    if (lower.contains('punjab') || lower.contains('pnb')) return '🏤';
    return '🏦';
  }

  static Color _categoryColor(String cat) {
    const map = {
      'food': Color(0xFFEF4444),
      'transport': Color(0xFFF59E0B),
      'shopping': Color(0xFF8B5CF6),
      'investment': Color(0xFF10B981),
      'utilities': Color(0xFF0EA5E9),
      'entertainment': Color(0xFFF97316),
      'health': Color(0xFFEC4899),
      'other': Color(0xFF64748B),
    };
    return map[cat] ?? const Color(0xFF64748B);
  }

  static String _categoryEmoji(String cat) {
    const map = {
      'food': '🍔',
      'transport': '🚗',
      'shopping': '🛍',
      'investment': '📈',
      'utilities': '💡',
      'entertainment': '🎬',
      'health': '🏥',
      'other': '💰',
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
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