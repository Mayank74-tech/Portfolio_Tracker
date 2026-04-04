import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';

// ─────────────────────────────────────────────
//  Mock data (replace with real controller data)
// ─────────────────────────────────────────────
class _MockHolding {
  final String symbol;
  final String name;
  final String sector;
  final String platform;
  final double buyPrice;
  final double currentPrice;
  final double change;
  final int qty;

  const _MockHolding({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.platform,
    required this.buyPrice,
    required this.currentPrice,
    required this.change,
    required this.qty,
  });
}

const _mockHoldings = [
  _MockHolding(
    symbol: 'RELIANCE',
    name: 'Reliance Industries Ltd',
    sector: 'Energy',
    platform: 'Zerodha',
    buyPrice: 2400,
    currentPrice: 2842.5,
    change: 1.84,
    qty: 10,
  ),
  _MockHolding(
    symbol: 'INFY',
    name: 'Infosys Ltd',
    sector: 'IT',
    platform: 'Groww',
    buyPrice: 1500,
    currentPrice: 1380,
    change: -0.62,
    qty: 15,
  ),
  _MockHolding(
    symbol: 'HDFCBANK',
    name: 'HDFC Bank Ltd',
    sector: 'Banking',
    platform: 'Angel One',
    buyPrice: 1600,
    currentPrice: 1724,
    change: 0.94,
    qty: 8,
  ),
  _MockHolding(
    symbol: 'TCS',
    name: 'Tata Consultancy Services',
    sector: 'IT',
    platform: 'Zerodha',
    buyPrice: 3500,
    currentPrice: 3842.5,
    change: 2.10,
    qty: 5,
  ),
];

// Chart data points (7-day)
class _ChartPoint {
  final String date;
  final double value;
  const _ChartPoint(this.date, this.value);
}

const _chartData = [
  _ChartPoint('Mon', 318000),
  _ChartPoint('Tue', 322000),
  _ChartPoint('Wed', 315000),
  _ChartPoint('Thu', 330000),
  _ChartPoint('Fri', 326000),
  _ChartPoint('Sat', 334000),
  _ChartPoint('Sun', 341800),
];

// ─────────────────────────────────────────────
//  Dashboard Screen
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final AnimationController _listController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // Computed totals
  final double _totalValue = _mockHoldings.fold(
      0, (s, h) => s + h.currentPrice * h.qty);
  final double _totalInvested = _mockHoldings.fold(
      0, (s, h) => s + h.buyPrice * h.qty);
  final double _todayChange = 2300;
  final double _todayChangePct = 1.84;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _cardFade = CurvedAnimation(
        parent: _cardController, curve: Curves.easeIn);
    _cardSlide = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _cardController, curve: Curves.easeOutCubic));

    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 200),
            () => _listController.forward());
  }

  @override
  void dispose() {
    _cardController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPL = _totalValue - _totalInvested;
    final totalPLPct = (totalPL / _totalInvested * 100);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Greeting header ──
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Portfolio summary card ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: _buildSummaryCard(
                              totalPL, totalPLPct),
                        ),
                      ),
                    ),
                  ),

                  // ── Mini chart ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _buildChartCard(),
                    ),
                  ),

                  // ── Quick actions ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _buildQuickActions(),
                    ),
                  ),

                  // ── Holdings header ──
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
                            onTap: () {},
                            child: Row(
                              children: const [
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

                  // ── Holdings list ──
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildHoldingTile(
                          _mockHoldings[i], i),
                      childCount: _mockHoldings.length,
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Good morning 👋',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hi, Arjun!',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Notification bell
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF131D2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
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
    );
  }

  // ─────────────────────────────────────────────
  //  SUMMARY CARD
  // ─────────────────────────────────────────────
  Widget _buildSummaryCard(double totalPL, double totalPLPct) {
    final isGain = totalPL >= 0;
    final plColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1A4F), Color(0xFF1A1235), Color(0xFF0F0D2E)],
        ),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Glow
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
                    const Color(0xFF6366F1).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              const Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              // Value
              Text(
                '₹${_formatInr(_totalValue, 0)}',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Today badges
              Row(
                children: [
                  _badge(
                    icon: Icons.trending_up_rounded,
                    label: '+₹${_formatInr(_todayChange, 0)} Today',
                    color: const Color(0xFF10B981),
                    bg: const Color(0xFF10B981).withOpacity(0.15),
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    label: '+${_todayChangePct.toStringAsFixed(2)}%',
                    color: const Color(0xFF10B981),
                    bg: const Color(0xFF10B981).withOpacity(0.10),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.07),
              ),
              const SizedBox(height: 14),
              // Bottom stats row
              Row(
                children: [
                  _statItem('Invested',
                      '₹${_formatInr(_totalInvested, 0)}'),
                  _vertDivider(),
                  _statItem(
                    'Total P&L',
                    '${isGain ? "+" : ""}₹${_formatInr(totalPL.abs(), 0)} (${totalPLPct.toStringAsFixed(1)}%)',
                    valueColor: plColor,
                  ),
                  _vertDivider(),
                  _statItem(
                      'Holdings', '${_mockHoldings.length} Stocks'),
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
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
          Text(value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _vertDivider() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withOpacity(0.07),
  );

  // ─────────────────────────────────────────────
  //  CHART CARD
  // ─────────────────────────────────────────────
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Portfolio Performance',
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('7D',
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: _MiniLineChart(data: _chartData),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK ACTIONS
  // ─────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      (Icons.add_rounded, 'Add Stock', const Color(0xFF6366F1),
      const Color(0xFF6366F1), AppRoutes.ADD_STOCK),
      (Icons.upload_file_rounded, 'Import CSV', const Color(0xFF10B981),
      const Color(0xFF10B981), AppRoutes.IMPORT_CSV),
      (Icons.smart_toy_outlined, 'Ask AI', const Color(0xFFF59E0B),
      const Color(0xFFF59E0B), AppRoutes.AI_CHAT),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(a.$5),
                child: Container(
                  margin: EdgeInsets.only(
                    right: actions.indexOf(a) < actions.length - 1 ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: a.$3.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                        Icon(a.$1, color: a.$4, size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(a.$2,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          )),
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

  // ─────────────────────────────────────────────
  //  HOLDING TILE
  // ─────────────────────────────────────────────
  Widget _buildHoldingTile(_MockHolding h, int index) {
    final isGain = h.currentPrice >= h.buyPrice;
    final plPct =
    ((h.currentPrice - h.buyPrice) / h.buyPrice * 100);
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
          arguments: {'symbol': h.symbol},
        ),
        child: Container(
          margin:
          const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border:
            Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gainColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    h.symbol.substring(0, 3),
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          h.symbol,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.06),
                            borderRadius:
                            BorderRadius.circular(6),
                          ),
                          child: Text(
                            h.platform,
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
                      '${h.qty} shares · ${h.sector}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatInr(h.currentPrice, 1)}',
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

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  String _formatInr(double v, int decimals) {
    // Simple Indian number formatting
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intStr = parts[0];
    String result = '';
    int count = 0;
    for (int i = intStr.length - 1; i >= 0; i--) {
      if (count == 3 ||
          (count > 3 && (count - 3) % 2 == 0)) {
        result = ',$result';
      }
      result = intStr[i] + result;
      count++;
    }
    return decimals > 0 ? '$result.${parts[1]}' : result;
  }
}

// ─────────────────────────────────────────────
//  Mini line chart (CustomPaint – no package)
// ─────────────────────────────────────────────
class _MiniLineChart extends StatelessWidget {
  final List<_ChartPoint> data;
  const _MiniLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniLineChartPainter(data: data),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<_ChartPoint> data;
  _MiniLineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minV = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxV = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    final padV = range * 0.15;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height -
          ((data[i].value - minV + padV) / (range + padV * 2)) * size.height;
      points.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6366F1).withOpacity(0.3),
        const Color(0xFF6366F1).withOpacity(0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // X-axis labels
    final textStyle = TextStyle(
      color: const Color(0xFF475569),
      fontSize: 9,
    );
    for (int i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].date, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(points[i].dx - tp.width / 2,
              size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter old) =>
      old.data != data;
}