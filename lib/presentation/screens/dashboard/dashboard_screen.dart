import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/app_background.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class _ChartPoint {
  final String date;
  final double value;
  const _ChartPoint(this.date, this.value);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final PortfolioController _portfolioController;
  late final AnimationController _cardController;
  late final AnimationController _listController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _portfolioController = Get.find<PortfolioController>();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _cardFade =
        CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );

    _cardController.forward();
    Future.delayed(
      const Duration(milliseconds: 200),
          () => _listController.forward(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portfolioController.loadPortfolio();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<_ChartPoint> _buildChartPoints(List<Map<String, dynamic>> holdings) {
    if (holdings.isEmpty) return [];

    final sorted = [...holdings];
    sorted.sort((a, b) {
      final aDate = a['buy_date']?.toString() ?? '';
      final bDate = b['buy_date']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });

    final points = <_ChartPoint>[const _ChartPoint('Start', 0)];

    double cumulative = 0;
    for (final h in sorted) {
      final rawDate = h['buy_date']?.toString() ?? '';
      final date =
      rawDate.length >= 10 ? rawDate.substring(5, 10) : '?';
      final value = _asDouble(h['current_price'] ?? h['buy_price']) *
          _asDouble(h['quantity']);
      cumulative += value;
      points.add(_ChartPoint(date, cumulative));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = _portfolioController.summary;
      final holdings = _portfolioController.holdings;
      final totalValue = _asDouble(summary['total_value']);
      final totalInvested = _asDouble(summary['total_investment']);
      final totalPL = _asDouble(summary['profit_loss']);
      final totalPLPct = _asDouble(summary['profit_loss_percent']);
      final todayChange = _asDouble(summary['today_change']);

      final displayChange = todayChange != 0 ? todayChange : totalPL;
      final displayChangePct = todayChange != 0
          ? (totalValue == 0 ? 0.0 : (todayChange / totalValue) * 100)
          : totalPLPct;
      final isDisplayGain = displayChange >= 0;

      final chartPoints = _buildChartPoints(holdings);

      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _buildSummaryCard(
                        totalValue: totalValue,
                        totalInvested: totalInvested,
                        totalPL: totalPL,
                        totalPLPct: totalPLPct,
                        displayChange: displayChange,
                        displayChangePct: displayChangePct,
                        isDisplayGain: isDisplayGain,
                        isTodayChange: todayChange != 0,
                        holdingCount: holdings.length,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildChartCard(chartPoints),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildInsightsBanner(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildQuickActions(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildFinanceBanner(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Holdings',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.HOLDINGS),
                        child: const Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF6366F1),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_portfolioController.isLoading.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6366F1)),
                    ),
                  ),
                )
              else if (holdings.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No holdings yet. Add your first stock.',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildHoldingTile(holdings[i], i),
                    childCount: holdings.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ));
    });
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF130B2E), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning 👋',
                style: TextStyle(
                    color: Color(0xFF64748B), fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'Hi, Investor!',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // ── Insights button ──────────────────────
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.INSIGHTS),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🧠',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              // ── Notifications ────────────────────────
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0B1120),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ── Summary Card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard({
    required double totalValue,
    required double totalInvested,
    required double totalPL,
    required double totalPLPct,
    required double displayChange,
    required double displayChangePct,
    required bool isDisplayGain,
    required bool isTodayChange,
    required int holdingCount,
  }) {
    final isGain = totalPL >= 0;
    final plColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final changeColor =
    isDisplayGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1A4F),
            Color(0xFF1A1235),
            Color(0xFF0F0D2E),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${_formatInr(totalValue, 0)}',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _badge(
                    icon: isDisplayGain
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    label:
                    '${displayChange >= 0 ? "+" : "-"}₹${_formatInr(displayChange.abs(), 0)} '
                        '${isTodayChange ? "Today" : "P&L"}',
                    color: changeColor,
                    bg: changeColor.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    label:
                    '${displayChangePct >= 0 ? "+" : ""}${displayChangePct.toStringAsFixed(2)}%',
                    color: changeColor,
                    bg: changeColor.withValues(alpha: 0.10),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.07)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statItem(
                      'Invested', '₹${_formatInr(totalInvested, 0)}'),
                  _vertDivider(),
                  _statItem(
                    'Total P&L',
                    '${isGain ? "+" : ""}₹${_formatInr(totalPL.abs(), 0)}'
                        ' (${totalPLPct.toStringAsFixed(1)}%)',
                    valueColor: plColor,
                  ),
                  _vertDivider(),
                  _statItem('Holdings', '$holdingCount Stocks'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge({
    IconData? icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vertDivider() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: 0.07),
  );

  // ── Chart Card ─────────────────────────────────────────────────────────────

  Widget _buildChartCard(List<_ChartPoint> chartPoints) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Performance',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ALL TIME',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart area — fixed height, full width
          SizedBox(
            width: double.infinity,
            height: 120,
            child: chartPoints.length < 2
                ? const Center(
              child: Text(
                'Add a stock to see chart',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            )
                : _MiniLineChart(data: chartPoints),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.INSIGHTS),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA855F7)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  '🧠',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Behavioral Insights',
                    style: TextStyle(
                      color: Color(0xFFE9D5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Memory gaps · Attention bias · '
                        'Decision patterns · Identity drift',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFA855F7)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Explore',
                style: TextStyle(
                  color: Color(0xFFD8B4FE),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      (
      Icons.add_rounded,
      'Add Stock',
      const Color(0xFF6366F1),
      const Color(0xFF6366F1),
      AppRoutes.ADD_STOCK,
      ),
      (
      Icons.upload_file_rounded,
      'Import CSV',
      const Color(0xFF10B981),
      const Color(0xFF10B981),
      AppRoutes.IMPORT_CSV,
      ),
      (
      Icons.smart_toy_outlined,
      'Ask AI',
      const Color(0xFFF59E0B),
      const Color(0xFFF59E0B),
      AppRoutes.AI_CHAT,
      ),
      (
      Icons.psychology_outlined,
      'Insights',
      const Color(0xFFA855F7),
      const Color(0xFFA855F7),
      AppRoutes.INSIGHTS,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
              color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 10),
        // ── Row 1: Add Stock + Import CSV ──────────────
        Row(
          children: actions.sublist(0, 2).asMap().entries.map((entry) {
            final a = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(a.$5),
                child: GlassContainer(
                  margin: EdgeInsets.only(
                    right: entry.key == 0 ? 10 : 0,
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: a.$3.withValues(alpha: 0.12),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child:
                        Icon(a.$1, color: a.$4, size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.$2,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // ── Row 2: Ask AI + Insights ───────────────────
        Row(
          children: actions.sublist(2, 4).asMap().entries.map((entry) {
            final a = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(a.$5),
                child: GlassContainer(
                  margin: EdgeInsets.only(
                    right: entry.key == 0 ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: a.$3.withValues(alpha: 0.12),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Icon(a.$1,
                            color: a.$4, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        a.$2,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFinanceBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.FINANCE_DASHBOARD),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF38BDF8),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finance Dashboard',
                    style: TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Track bank balances, spending and spend-vs-invest trends.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Open',
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── Holding Tile ───────────────────────────────────────────────────────────

  Widget _buildHoldingTile(Map<String, dynamic> h, int index) {
    final symbol = _asString(h['stock_symbol'] ?? h['symbol'], 'STK');
    final name = _asString(h['stock_name'] ?? h['name'], symbol);
    final platform = _asString(h['platform'], 'Manual');
    final buyPrice = _asDouble(h['buy_price']);
    final currentPrice =
    _asDouble(h['current_price'] ?? h['buy_price']);
    final qty = _asDouble(h['quantity']);
    final isGain = currentPrice >= buyPrice;
    final plPct = buyPrice == 0
        ? 0.0
        : ((currentPrice - buyPrice) / buyPrice * 100);
    final currentValue = currentPrice * qty;
    final gainColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: _listController,
      builder: (_, child) {
        final delay = index * 0.12;
        final t = (_listController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * -20, 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Get.toNamed(
          AppRoutes.STOCK_DETAIL,
          arguments: {'symbol': symbol},
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    symbol.length >= 3
                        ? symbol.substring(0, 3)
                        : symbol,
                    style: TextStyle(
                      color: gainColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            symbol,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            platform,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)}'
                          ' shares · $name',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price & P&L
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatInr(currentValue, 0)}',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isGain
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 11,
                        color: gainColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isGain ? "+" : ""}${plPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: gainColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatInr(double v, int decimals) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intStr = parts[0];
    String result = '';
    int count = 0;
    for (int i = intStr.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
        result = ',$result';
      }
      result = intStr[i] + result;
      count++;
    }
    return decimals > 0 ? '$result.${parts[1]}' : result;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(Object? value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}

// ── Mini Line Chart ────────────────────────────────────────────────────────────
// ── Mini Line Chart ────────────────────────────────────────────────────────────

class _MiniLineChart extends StatefulWidget {
  final List<_ChartPoint> data;
  const _MiniLineChart({required this.data});

  @override
  State<_MiniLineChart> createState() => _MiniLineChartState();
}

class _MiniLineChartState extends State<_MiniLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _MiniLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height =
        constraints.maxHeight.isFinite ? constraints.maxHeight : 110.0;

        return AnimatedBuilder(
          animation: _progress,
          builder: (_, __) {
            return CustomPaint(
              size: Size(width, height),
              painter: _MiniLineChartPainter(
                data: widget.data,
                progress: _progress.value,
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<_ChartPoint> data;
  final double progress;

  const _MiniLineChartPainter({
    required this.data,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: never paint on zero-size canvas or fewer than 2 points
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;

    const labelHeight = 16.0;
    final chartHeight = size.height - labelHeight;
    if (chartHeight <= 0) return;

    final minV =
    data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxV =
    data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final rawRange = maxV - minV;
    final range = rawRange < 1.0 ? 1.0 : rawRange;
    final padV = range * 0.15;
    final totalRange = range + padV * 2;

    // Build all pixel points
    final allPoints = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i / (data.length - 1) * size.width;
      final y = chartHeight -
          ((data[i].value - minV + padV) / totalRange) * chartHeight;
      allPoints.add(Offset(x, y));
    }

    // Slice visible points according to animation progress
    final stopIndex = progress * (allPoints.length - 1);
    final fullIndex = stopIndex.floor().clamp(0, allPoints.length - 1);
    final visible = List<Offset>.from(allPoints.sublist(0, fullIndex + 1));

    if (fullIndex < allPoints.length - 1) {
      final fraction = stopIndex - fullIndex;
      final s = allPoints[fullIndex];
      final e = allPoints[fullIndex + 1];
      visible.add(Offset(
        s.dx + (e.dx - s.dx) * fraction,
        s.dy + (e.dy - s.dy) * fraction,
      ));
    }

    if (visible.length < 2) return;

    // Gradient fill under the line
    final fillPath = Path()..moveTo(visible.first.dx, chartHeight);
    for (final p in visible) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(visible.last.dx, chartHeight)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.30),
            const Color(0xFF6366F1).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );

    // Line
    final linePath = Path()
      ..moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      linePath.lineTo(visible[i].dx, visible[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Animated end dot
    final last = visible.last;
    canvas.drawCircle(last, 5, Paint()..color = const Color(0xFF6366F1));
    canvas.drawCircle(last, 3, Paint()..color = Colors.white);

    // X-axis labels — skip index 0 ('Start')
    const textStyle = TextStyle(color: Color(0xFF475569), fontSize: 9);
    final step = data.length > 6 ? 2 : 1;

    for (int i = 1; i < data.length; i += step) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].date, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final rawX = data.length == 1
          ? size.width / 2
          : i / (data.length - 1) * size.width - tp.width / 2;

      final labelX = rawX.clamp(
          0.0, (size.width - tp.width).clamp(0.0, size.width));

      tp.paint(canvas, Offset(labelX, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter old) =>
      old.data != data || old.progress != progress;
}