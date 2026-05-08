import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

import '../../../data/services/local/hive_service.dart';
import '../../controllers/auth_controller.dart';

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
  late final PortfolioController _pc;
  late final AnimationController _cardController;
  late final AnimationController _listController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  late final String _displayName;
  late final String _greeting;

  List<_ChartPoint> _cachedChartPoints = [];
  int _lastHoldingsHash = 0;

  @override
  void initState() {
    super.initState();
    _pc = Get.find<PortfolioController>();

    final auth = Get.find<AuthController>();
    _displayName = HiveService.savedName ??
        auth.firebaseUser.value?.displayName ??
        auth.firebaseUser.value?.email?.split('@').first ??
        'Investor';

    // ✅ Dynamic greeting based on time
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _cardController.forward();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _listController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pc.loadPortfolio();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<_ChartPoint> _getChartPoints(List<Map<String, dynamic>> holdings) {
    final hash = holdings.length * 31 +
        (holdings.isNotEmpty ? holdings.first.hashCode : 0);
    if (hash == _lastHoldingsHash) return _cachedChartPoints;

    _lastHoldingsHash = hash;
    _cachedChartPoints = _buildChartPoints(holdings);
    return _cachedChartPoints;
  }

  List<_ChartPoint> _buildChartPoints(List<Map<String, dynamic>> holdings) {
    if (holdings.isEmpty) return [];

    final sorted = [...holdings]..sort((a, b) {
      final aD = a['buy_date']?.toString() ?? '';
      final bD = b['buy_date']?.toString() ?? '';
      return aD.compareTo(bD);
    });

    final points = <_ChartPoint>[const _ChartPoint('Start', 0)];
    double cum = 0;

    for (final h in sorted) {
      final raw = h['buy_date']?.toString() ?? '';
      final date = raw.length >= 10 ? raw.substring(5, 10) : '?';
      cum += _d(h['current_price'] ?? h['buy_price']) * _d(h['quantity']);
      points.add(_ChartPoint(date, cum));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF111827),
          onRefresh: () => _pc.loadPortfolio(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Summary Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Obx(() => _buildSummaryCard()),
                    ),
                  ),
                ),
              ),

              // ── Chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Obx(
                          () => _buildChartCard(_getChartPoints(_pc.holdings))),
                ),
              ),

              // ── Quick Actions ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _QuickActionsGrid(),
                ),
              ),

              // ── Banners ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _InsightsBanner(),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _FinanceBanner(),
                ),
              ),

              // ── Holdings Header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _HoldingsHeader(),
                ),
              ),

              // ── Holdings List ──
              Obx(() {
                if (_pc.isLoading.value) {
                  return const SliverToBoxAdapter(
                    child: _LoadingShimmer(),
                  );
                }

                final holdings = _pc.holdings;

                if (holdings.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _EmptyHoldings(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _HoldingTile(
                      key: ValueKey(holdings[i]['id'] ?? i),
                      holding: holdings[i],
                      index: i,
                      listController: _listController,
                    ),
                    childCount: holdings.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting 👋',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _displayName,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const _HeaderActions(),
        ],
      ),
    );
  }

  // ── Summary Card ────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final totalValue = _d(_pc.summary['total_value']);
    final totalInvested = _d(_pc.summary['total_investment']);
    final totalPL = _d(_pc.summary['profit_loss']);
    final totalPLPct = _d(_pc.summary['profit_loss_percent']);
    final todayChange = _d(_pc.summary['today_change']);
    final holdingCount = _pc.holdings.length;

    final displayChange = todayChange != 0 ? todayChange : totalPL;
    final displayChangePct = todayChange != 0
        ? (totalValue == 0 ? 0.0 : (todayChange / totalValue) * 100)
        : totalPLPct;
    final isUp = displayChange >= 0;
    final isPLUp = totalPL >= 0;

    final changeColor =
    isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final plColor =
    isPLUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1A4F),
            Color(0xFF151030),
            Color(0xFF0F0D2E),
          ],
        ),
        border: Border.all(color: const Color(0x336366F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x206366F1),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + Holding Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$holdingCount stocks',
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total Value
          Text(
            '₹${_inr(totalValue)}',
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 14),

          // Change Badges
          Row(
            children: [
              _ChangeBadge(
                icon: isUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label:
                '${displayChange >= 0 ? "+" : ""}₹${_inr(displayChange.abs())} '
                    '${todayChange != 0 ? "Today" : "P&L"}',
                color: changeColor,
              ),
              const SizedBox(width: 8),
              _ChangeBadge(
                label:
                '${displayChangePct >= 0 ? "+" : ""}${displayChangePct.toStringAsFixed(2)}%',
                color: changeColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _StatColumn(
                label: 'Invested',
                value: '₹${_inr(totalInvested)}',
              ),
              _StatDivider(),
              _StatColumn(
                label: 'Returns',
                value:
                '${isPLUp ? "+" : ""}₹${_inr(totalPL.abs())}',
                valueColor: plColor,
              ),
              _StatDivider(),
              _StatColumn(
                label: 'Return %',
                value:
                '${isPLUp ? "+" : ""}${totalPLPct.toStringAsFixed(1)}%',
                valueColor: plColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart Card ──────────────────────────────────────────────────────────

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
                'Portfolio Growth',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'ALL TIME',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 130,
            child: chartPoints.length < 2
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: const Color(0xFF334155),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add stocks to see growth chart',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
                : RepaintBoundary(
              child: _MiniLineChart(data: chartPoints),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static double _d(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _s(Object? v, String fb) {
    final t = v?.toString().trim();
    return t == null || t.isEmpty ? fb : t;
  }

  static String _inr(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c == 3 || (c > 3 && (c - 3) % 2 == 0)) buf.write(',');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXTRACTED WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ── Change Badge ──────────────────────────────────────────────────────────

class _ChangeBadge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _ChangeBadge({this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Column ───────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ── Header Actions ────────────────────────────────────────────────────────

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderButton(
          onTap: () => Get.toNamed(AppRoutes.INSIGHTS),
          child: const Text('🧠', style: TextStyle(fontSize: 17)),
          glowColor: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          onTap: () {},
          glowColor: const Color(0xFF334155),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF94A3B8),
                size: 19,
              ),
              Positioned(
                top: -2,
                right: -2,
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
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color glowColor;

  const _HeaderButton({
    required this.onTap,
    required this.child,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: glowColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: glowColor.withValues(alpha: 0.25),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Quick Actions Grid (REDESIGNED) ───────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    _QA(Icons.add_rounded, 'Add Stock', Color(0xFF6366F1),
        Color(0xFF4F46E5), AppRoutes.ADD_STOCK),
    _QA(Icons.upload_file_rounded, 'Import', Color(0xFF10B981),
        Color(0xFF059669), AppRoutes.IMPORT_CSV),
    _QA(Icons.smart_toy_rounded, 'Ask AI', Color(0xFFF59E0B),
        Color(0xFFD97706), AppRoutes.AI_CHAT),
    _QA(Icons.psychology_rounded, 'Insights', Color(0xFFA855F7),
        Color(0xFF9333EA), AppRoutes.INSIGHTS),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: List.generate(4, (i) {
            final a = _actions[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 5,
                  right: i == 3 ? 0 : 5,
                ),
                child: _QuickActionCard(action: a),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final Color darkColor;
  final String route;

  const _QA(this.icon, this.label, this.color, this.darkColor, this.route);
}

class _QuickActionCard extends StatelessWidget {
  final _QA action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(action.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.color.withValues(alpha: 0.25),
                    action.darkColor.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(action.icon, color: action.color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                color: action.color.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Insights Banner ───────────────────────────────────────────────────────

class _InsightsBanner extends StatelessWidget {
  const _InsightsBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.INSIGHTS),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0F30),
              Color(0xFF12082A),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: 0.25),
                    const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                ),
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 22)),
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
                  SizedBox(height: 4),
                  Text(
                    'Discover cognitive biases affecting your portfolio decisions',
                    style: TextStyle(
                      color: Color(0xFF8B7DAF),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFA855F7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Finance Banner ────────────────────────────────────────────────────────

class _FinanceBanner extends StatelessWidget {
  const _FinanceBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.FINANCE_DASHBOARD),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                    const Color(0xFF0284C7).withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF38BDF8),
                size: 22,
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
                  SizedBox(height: 4),
                  Text(
                    'Track spending, balances & invest trends',
                    style: TextStyle(
                      color: Color(0xFF6B94B8),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0EA5E9),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Holdings Header ───────────────────────────────────────────────────────

class _HoldingsHeader extends StatelessWidget {
  const _HoldingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Holdings',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.HOLDINGS),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF818CF8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading Shimmer ───────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Empty Holdings ────────────────────────────────────────────────────────

class _EmptyHoldings extends StatelessWidget {
  const _EmptyHoldings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.add_chart_rounded,
              color: Color(0xFF6366F1),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No holdings yet',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first stock to start tracking',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.ADD_STOCK),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Add Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Holding Tile (EXTRACTED + REDESIGNED) ──────────────────────────────────

class _HoldingTile extends StatelessWidget {
  final Map<String, dynamic> holding;
  final int index;
  final AnimationController listController;

  const _HoldingTile({
    super.key,
    required this.holding,
    required this.index,
    required this.listController,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = _s(holding['stock_symbol'] ?? holding['symbol'], 'STK');
    final name = _s(holding['stock_name'] ?? holding['name'], symbol);
    final platform = _s(holding['platform'], 'Manual');
    final buyPrice = _d(holding['buy_price']);
    final currentPrice = _d(holding['current_price'] ?? holding['buy_price']);
    final qty = _d(holding['quantity']);
    final isGain = currentPrice >= buyPrice;
    final plPct =
    buyPrice == 0 ? 0.0 : ((currentPrice - buyPrice) / buyPrice * 100);
    final currentValue = currentPrice * qty;

    final gainColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: listController,
      builder: (_, child) {
        final delay = (index * 0.08).clamp(0.0, 0.7);
        final t = (listController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gainColor.withValues(alpha: 0.18),
                      gainColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: gainColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
                    style: TextStyle(
                      color: gainColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            platform,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${qty.toStringAsFixed(qty == qty.truncateToDouble() ? 0 : 2)} shares · $name',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                      ),
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
                    '₹${_inr(currentValue)}',
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: gainColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGain
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 10,
                          color: gainColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${plPct >= 0 ? "+" : ""}${plPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: gainColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _d(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _s(Object? v, String fb) {
    final t = v?.toString().trim();
    return t == null || t.isEmpty ? fb : t;
  }

  static String _inr(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c == 3 || (c > 3 && (c - 3) % 2 == 0)) buf.write(',');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }
}

// ── Mini Line Chart ───────────────────────────────────────────────────────

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
        final w = constraints.maxWidth;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 120.0;
        return AnimatedBuilder(
          animation: _progress,
          builder: (_, __) => CustomPaint(
            size: Size(w, h),
            painter: _ChartPainter(
              data: widget.data,
              progress: _progress.value,
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<_ChartPoint> data;
  final double progress;

  static final _fill = Paint();
  static final _line = Paint()
    ..color = const Color(0xFF6366F1)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _dot = Paint()..color = const Color(0xFF6366F1);
  static final _dotInner = Paint()..color = Colors.white;

  const _ChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;

    const lh = 18.0;
    final ch = size.height - lh;
    if (ch <= 0) return;

    double minV = data[0].value, maxV = data[0].value;
    for (final p in data) {
      if (p.value < minV) minV = p.value;
      if (p.value > maxV) maxV = p.value;
    }
    final range = (maxV - minV) < 1.0 ? 1.0 : (maxV - minV);
    final pad = range * 0.15;
    final total = range + pad * 2;

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i / (data.length - 1) * size.width;
      final y = ch - ((data[i].value - minV + pad) / total) * ch;
      pts.add(Offset(x, y));
    }

    final si = progress * (pts.length - 1);
    final fi = si.floor().clamp(0, pts.length - 1);
    final vis = List<Offset>.from(pts.sublist(0, fi + 1));

    if (fi < pts.length - 1) {
      final f = si - fi;
      final s = pts[fi], e = pts[fi + 1];
      vis.add(Offset(s.dx + (e.dx - s.dx) * f, s.dy + (e.dy - s.dy) * f));
    }

    if (vis.length < 2) return;

    // Fill
    final fp = Path()..moveTo(vis.first.dx, ch);
    for (final p in vis) fp.lineTo(p.dx, p.dy);
    fp..lineTo(vis.last.dx, ch)..close();

    _fill.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x4D6366F1), Color(0x006366F1)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, ch));

    canvas.drawPath(fp, _fill);

    // Line
    final lp = Path()..moveTo(vis.first.dx, vis.first.dy);
    for (int i = 1; i < vis.length; i++) lp.lineTo(vis[i].dx, vis[i].dy);
    canvas.drawPath(lp, _line);

    // Dot
    final last = vis.last;
    canvas.drawCircle(last, 5, _dot);
    canvas.drawCircle(last, 3, _dotInner);

    // Labels
    const ts = TextStyle(color: Color(0xFF475569), fontSize: 9);
    final step = data.length > 6 ? 2 : 1;
    for (int i = 1; i < data.length; i += step) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].date, style: ts),
        textDirection: TextDirection.ltr,
      )..layout();
      final rx = data.length == 1
          ? size.width / 2
          : i / (data.length - 1) * size.width - tp.width / 2;
      tp.paint(
        canvas,
        Offset(
          rx.clamp(0.0, (size.width - tp.width).clamp(0.0, size.width)),
          ch + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.data != data || old.progress != progress;
}