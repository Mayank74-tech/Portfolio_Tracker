import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/stock_controller.dart';

// ─────────────────────────────────────────────
//  Mock data models (replace with controller)
// ─────────────────────────────────────────────
class _ChartPoint {
  final String date;
  final double price;
  const _ChartPoint(this.date, this.price);
}

class _StockDetail {
  final String symbol;
  final String name;
  final String sector;
  final String platform;
  final double buyPrice;
  final double currentPrice;
  final double change;
  final int qty;

  const _StockDetail({
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

const _demoStock = _StockDetail(
  symbol: 'RELIANCE',
  name: 'Reliance Industries Ltd',
  sector: 'Energy',
  platform: 'Zerodha',
  buyPrice: 2400,
  currentPrice: 2842.5,
  change: 1.84,
  qty: 10,
);

const _chart7D = [
  _ChartPoint('Mon', 2680),
  _ChartPoint('Tue', 2730),
  _ChartPoint('Wed', 2695),
  _ChartPoint('Thu', 2760),
  _ChartPoint('Fri', 2720),
  _ChartPoint('Sat', 2795),
  _ChartPoint('Sun', 2842),
];

const _chart1M = [
  _ChartPoint('Mar 5', 2550),
  _ChartPoint('Mar 10', 2620),
  _ChartPoint('Mar 15', 2580),
  _ChartPoint('Mar 20', 2700),
  _ChartPoint('Mar 25', 2660),
  _ChartPoint('Mar 28', 2700),
  _ChartPoint('Apr 3', 2842),
];

const _chart1Y = [
  _ChartPoint('Apr\'24', 2200),
  _ChartPoint('Jun\'24', 2350),
  _ChartPoint('Aug\'24', 2100),
  _ChartPoint('Oct\'24', 2500),
  _ChartPoint('Dec\'24', 2650),
  _ChartPoint('Feb\'25', 2750),
  _ChartPoint('Apr\'25', 2842),
];

// ─────────────────────────────────────────────
//  Stock Detail Screen
// ─────────────────────────────────────────────
class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with TickerProviderStateMixin {
  String _activeRange = '7D';
  bool _starred = false;

  // Get symbol from Get.arguments or use demo
  late final _StockDetail _stock;

  // Animation controllers
  late final AnimationController _headerController;
  late final AnimationController _chartController;
  late final AnimationController _cardsController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _chartFade;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  Map<String, List<_ChartPoint>> get _chartMap => {
    '7D': _chart7D,
    '1M': _chart1M,
    '1Y': _chart1Y,
  };

  @override
  void initState() {
    super.initState();
    _stock = _demoStock; // Replace with Get.arguments lookup

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _chartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _headerFade = CurvedAnimation(
        parent: _headerController, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic));

    _chartFade = CurvedAnimation(
        parent: _chartController, curve: Curves.easeIn);

    _cardsFade = CurvedAnimation(
        parent: _cardsController, curve: Curves.easeIn);
    _cardsSlide = Tween<Offset>(
        begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _cardsController, curve: Curves.easeOutCubic));

    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 150), _chartController.forward);
    Future.delayed(
        const Duration(milliseconds: 280), _cardsController.forward);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _chartController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGain = _stock.currentPrice >= _stock.buyPrice;
    final gainColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final pl =
        (_stock.currentPrice - _stock.buyPrice) * _stock.qty;
    final plPct =
    ((_stock.currentPrice - _stock.buyPrice) / _stock.buyPrice * 100);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildTopBar(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Price header ──
                    FadeTransition(
                      opacity: _headerFade,
                      child: _buildPriceHeader(
                          isGain, gainColor),
                    ),

                    // ── Range selector ──
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildRangeSelector(),
                    ),

                    // ── Chart ──
                    FadeTransition(
                      opacity: _chartFade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 16),
                        child: _buildChart(isGain, gainColor),
                      ),
                    ),

                    // ── Holdings info card ──
                    FadeTransition(
                      opacity: _cardsFade,
                      child: SlideTransition(
                        position: _cardsSlide,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 12),
                          child: _buildHoldingsCard(
                              isGain, gainColor, pl, plPct),
                        ),
                      ),
                    ),

                    // ── Platform badge ──
                    FadeTransition(
                      opacity: _cardsFade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 32),
                        child: _buildPlatformBadge(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Back button
          _iconBtn(Icons.chevron_left_rounded, onTap: () => Get.back()),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              _stock.name.length > 22
                  ? '${_stock.name.substring(0, 22)}…'
                  : _stock.name,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Star + More
          _iconBtn(
            _starred ? Icons.star_rounded : Icons.star_outline_rounded,
            color: _starred
                ? const Color(0xFFF59E0B)
                : const Color(0xFF64748B),
            onTap: () => setState(() => _starred = !_starred),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.more_vert_rounded),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon,
      {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PRICE HEADER
  // ─────────────────────────────────────────────
  Widget _buildPriceHeader(bool isGain, Color gainColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Symbol avatar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: gainColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _stock.symbol.substring(0, 3),
                          style: TextStyle(
                            color: gainColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stock.symbol,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'NSE · ${_stock.sector}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${_stock.currentPrice.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Right side – change badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: gainColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGain
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: gainColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isGain ? "+" : ""}${_stock.change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: gainColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Today',
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

  // ─────────────────────────────────────────────
  //  RANGE SELECTOR
  // ─────────────────────────────────────────────
  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['7D', '1M', '1Y'].map((r) {
          final isActive = _activeRange == r;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeRange = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r,
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
    );
  }

  // ─────────────────────────────────────────────
  //  CHART
  // ─────────────────────────────────────────────
  Widget _buildChart(bool isGain, Color gainColor) {
    final data = _chartMap[_activeRange]!;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _StockLineChart(
        data: data,
        color: gainColor,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HOLDINGS INFO CARD
  // ─────────────────────────────────────────────
  Widget _buildHoldingsCard(
      bool isGain, Color gainColor, double pl, double plPct) {
    final stats = [
      ('Avg. Buy Price', '₹${_stock.buyPrice.toStringAsFixed(0)}'),
      ('Quantity', '${_stock.qty} shares'),
      ('Invested',
      '₹${(_stock.buyPrice * _stock.qty).toStringAsFixed(0)}'),
      ('Current Value',
      '₹${(_stock.currentPrice * _stock.qty).toStringAsFixed(0)}'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Holdings',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          // 2x2 grid of stat tiles
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: stats.map((s) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.$1,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // P&L row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: gainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gainColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGain
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: gainColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total P&L',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isGain ? "+" : ""}₹${pl.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        color: gainColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '(${isGain ? "+" : ""}${plPct.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: gainColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PLATFORM BADGE
  // ─────────────────────────────────────────────
  Widget _buildPlatformBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _stock.platform.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                _stock.platform,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stock Line Chart (CustomPaint – no package)
// ─────────────────────────────────────────────
class _StockLineChart extends StatefulWidget {
  final List<_ChartPoint> data;
  final Color color;
  const _StockLineChart({required this.data, required this.color});

  @override
  State<_StockLineChart> createState() => _StockLineChartState();
}

class _StockLineChartState extends State<_StockLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _progress = CurvedAnimation(
        parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _StockLineChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
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
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) => CustomPaint(
        painter: _StockChartPainter(
          data: widget.data,
          color: widget.color,
          progress: _progress.value,
        ),
      ),
    );
  }
}

class _StockChartPainter extends CustomPainter {
  final List<_ChartPoint> data;
  final Color color;
  final double progress;

  _StockChartPainter({
    required this.data,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final labelHeight = 16.0;
    final chartHeight = size.height - labelHeight;

    final minV = data.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxV = data.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(1.0, double.infinity);
    final padV = range * 0.15;

    List<Offset> allPoints = [];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = chartHeight -
          ((data[i].price - minV + padV) / (range + padV * 2)) * chartHeight;
      allPoints.add(Offset(x, y));
    }

    // Clip line by progress
    final stopIdx = (progress * (allPoints.length - 1));
    final fullIdx = stopIdx.floor();
    List<Offset> points = allPoints.sublist(0, fullIdx + 1);
    if (fullIdx < allPoints.length - 1) {
      final frac = stopIdx - fullIdx;
      final p1 = allPoints[fullIdx];
      final p2 = allPoints[fullIdx + 1];
      points.add(Offset(
        p1.dx + (p2.dx - p1.dx) * frac,
        p1.dy + (p2.dy - p1.dy) * frac,
      ));
    }

    if (points.length < 2) return;

    // Fill gradient
    final fillPath = Path()
      ..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, chartHeight)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );

    // Line
    final linePath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot at current price
    final lastPt = points.last;
    canvas.drawCircle(
      lastPt,
      5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      lastPt,
      3,
      Paint()..color = Colors.white,
    );

    // X-axis labels
    final labelStyle = TextStyle(
      color: const Color(0xFF475569),
      fontSize: 9,
    );
    for (int i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].date, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = i / (data.length - 1) * size.width;
      tp.paint(
        canvas,
        Offset(
          (x - tp.width / 2).clamp(0, size.width - tp.width),
          chartHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter old) =>
      old.progress != progress || old.data != data || old.color != color;
}