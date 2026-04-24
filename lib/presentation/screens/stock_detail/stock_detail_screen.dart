import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/stock_controller.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

class _ChartPoint {
  final DateTime date;
  final double price;
  final String label;

  const _ChartPoint({
    required this.date,
    required this.price,
    required this.label,
  });
}

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with TickerProviderStateMixin {
  late final StockController _stockController;
  late final PortfolioController _portfolioController;
  late final String _symbol;

  String _activeRange = '1M';
  bool _starred = false;
  bool _isRefreshing = false;

  late final AnimationController _headerController;
  late final AnimationController _chartController;
  late final AnimationController _cardsController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _chartFade;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _stockController = Get.find<StockController>();
    _portfolioController = Get.isRegistered<PortfolioController>()
        ? Get.find<PortfolioController>()
        : Get.put(PortfolioController());
    _symbol = _resolveSymbol(Get.arguments);

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeIn,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _chartFade = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeIn,
    );
    _cardsFade = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeIn,
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.easeOutCubic),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 150), _chartController.forward);
    Future.delayed(const Duration(milliseconds: 280), _cardsController.forward);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _chartController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_symbol.isEmpty) return;

    if (refresh && mounted) {
      setState(() => _isRefreshing = true);
    }

    _stockController.clearError();

    if (_portfolioController.holdings.isEmpty) {
      await _portfolioController.loadHoldings();
    }

    await _stockController.loadQuote(_symbol);
    await _stockController.loadCompanyProfile(_symbol);
    await _stockController.loadDailyTimeSeries(_symbol, outputSize: 'full');
    await _stockController.loadWeeklyTimeSeries(_symbol);

    if (refresh && mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_symbol.isEmpty) {
      return _buildMissingSymbolState();
    }

    return Obx(() {
      final quote = _stockController.quote;
      final profile = _stockController.companyProfile;
      final holding = _findHolding(_portfolioController.holdings, _symbol);
      final points = _historyPoints(
        dailyData: _stockController.dailyTimeSeries,
        weeklyData: _stockController.weeklyTimeSeries,
        range: _activeRange,
      );

      final currentPrice = _number(quote['c'] ?? quote['price']);
      final previousClose = _number(quote['pc'] ?? quote['previousClose']);
      final priceDelta = _number(quote['d']) != 0
          ? _number(quote['d'])
          : currentPrice - previousClose;
      final changePercent = _number(quote['dp']) != 0
          ? _number(quote['dp'])
          : previousClose == 0
              ? 0.0
              : (priceDelta / previousClose) * 100;
      final isGain = changePercent >= 0;
      final accent = isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

      final hasAnyData =
          quote.isNotEmpty || profile.isNotEmpty || points.isNotEmpty;

      if (!hasAnyData && _stockController.isLoading.value) {
        return _buildLoadingState();
      }

      if (!hasAnyData && _stockController.errorMessage.value.isNotEmpty) {
        return _buildErrorState(_stockController.errorMessage.value);
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildTopBar(profile),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF131D2E),
                  onRefresh: () => _loadData(refresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _headerFade,
                          child: _buildPriceHeader(
                            profile: profile,
                            currentPrice: currentPrice,
                            changePercent: changePercent,
                            priceDelta: priceDelta,
                            isGain: isGain,
                            accent: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildRangeSelector(),
                        ),
                        FadeTransition(
                          opacity: _chartFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildChart(points, accent),
                          ),
                        ),
                        FadeTransition(
                          opacity: _cardsFade,
                          child: SlideTransition(
                            position: _cardsSlide,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildHoldingCard(
                                holding: holding,
                                currentPrice: currentPrice,
                                accent: accent,
                              ),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _cardsFade,
                          child: SlideTransition(
                            position: _cardsSlide,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildCompanyCard(profile),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _cardsFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: _buildActions(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMissingSymbolState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF64748B),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No stock selected',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Open this page from a holding or stock search result.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _primaryButton(
                  label: 'Back',
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Get.back(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Color(0xFF0B1120),
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 46,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load stock',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _primaryButton(
                  label: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onTap: () => _loadData(refresh: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic> profile) {
    final companyName = _cleanText(profile['name'], fallback: _symbol);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left_rounded, onTap: () => Get.back()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              companyName,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _iconBtn(
            _starred ? Icons.star_rounded : Icons.star_outline_rounded,
            color: _starred ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
            onTap: () => setState(() => _starred = !_starred),
          ),
          const SizedBox(width: 8),
          _iconBtn(
            _isRefreshing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
            onTap: () => _loadData(refresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHeader({
    required Map<String, dynamic> profile,
    required double currentPrice,
    required double changePercent,
    required double priceDelta,
    required bool isGain,
    required Color accent,
  }) {
    final sector = _cleanText(profile['finnhubIndustry'], fallback: 'Stock');
    final exchange = _cleanText(profile['exchange'], fallback: 'Market');
    final companyName = _cleanText(profile['name'], fallback: _symbol);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _symbol.substring(
                              0, _symbol.length.clamp(1, 3).toInt()),
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _symbol,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$exchange · $sector',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currentPrice > 0
                      ? '₹${_formatMoney(currentPrice, decimals: 2)}'
                      : companyName,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                if (currentPrice > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Latest market price',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
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
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isGain ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isGain ? '+' : ''}₹${_formatMoney(priceDelta.abs())} today',
                style: const TextStyle(
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

  Widget _buildRangeSelector() {
    const ranges = ['7D', '1M', '1Y'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ranges.map((range) {
          final isActive = _activeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeRange = range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color:
                      isActive ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<_ChartPoint> points, Color accent) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: points.length < 2
          ? const Center(
              child: Text(
                'Not enough price history yet',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            )
          : _StockLineChart(data: points, color: accent),
    );
  }

  Widget _buildHoldingCard({
    required Map<String, dynamic>? holding,
    required double currentPrice,
    required Color accent,
  }) {
    if (holding == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Holding',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This stock is not in your portfolio yet.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            _primaryButton(
              label: 'Add To Portfolio',
              icon: Icons.add_rounded,
              onTap: () => Get.toNamed(AppRoutes.ADD_STOCK),
            ),
          ],
        ),
      );
    }

    final quantity = _number(holding['quantity']);
    final buyPrice = _number(holding['buy_price']);
    final invested = quantity * buyPrice;
    final currentValue = quantity * currentPrice;
    final profitLoss = currentValue - invested;
    final profitLossPercent = invested == 0 ? 0 : (profitLoss / invested) * 100;
    final isGain = profitLoss >= 0;
    final plColor = isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final stats = [
      ('Avg. Buy Price', '₹${_formatMoney(buyPrice)}'),
      ('Quantity', _formatQuantity(quantity)),
      ('Invested', '₹${_formatMoney(invested)}'),
      ('Current Value', '₹${_formatMoney(currentValue)}'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Holding',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: stats.map((stat) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.$1,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.$2,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: plColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: plColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isGain
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: plColor,
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
                      '${isGain ? '+' : '-'}₹${_formatMoney(profitLoss.abs())}',
                      style: TextStyle(
                        color: plColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '(${isGain ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: plColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _secondaryStat(
                  label: 'Platform',
                  value: _cleanText(holding['platform'], fallback: 'Manual'),
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryStat(
                  label: 'Buy Date',
                  value: _formatDate(holding['buy_date']),
                  accent: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> profile) {
    final companyName = _cleanText(profile['name'], fallback: _symbol);
    final website = _cleanText(profile['weburl'], fallback: 'Not available');
    final marketCapValue = _number(profile['marketCapitalization']) * 1000000;

    final items = [
      ('Sector', _cleanText(profile['finnhubIndustry'], fallback: 'Unknown')),
      ('Exchange', _cleanText(profile['exchange'], fallback: 'Unknown')),
      ('Country', _cleanText(profile['country'], fallback: 'Unknown')),
      ('IPO', _formatDate(profile['ipo'])),
      (
        'Market Cap',
        marketCapValue > 0 ? _formatCompactNumber(marketCapValue) : 'Unknown',
      ),
      ('Website', website),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companyName,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Company overview',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          item.$2,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _primaryButton(
            label: 'Ask AI',
            icon: Icons.smart_toy_outlined,
            onTap: () => Get.toNamed(AppRoutes.AI_CHAT),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TextButton.icon(
              onPressed: () => _loadData(refresh: true),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _secondaryStat({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
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
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  static String _resolveSymbol(Object? arguments) {
    if (arguments is Map) {
      final symbol = arguments['symbol']?.toString().trim().toUpperCase();
      if (symbol != null && symbol.isNotEmpty) return symbol;
    }
    if (arguments is String && arguments.trim().isNotEmpty) {
      return arguments.trim().toUpperCase();
    }
    return '';
  }

  static Map<String, dynamic>? _findHolding(
    List<Map<String, dynamic>> holdings,
    String symbol,
  ) {
    for (final holding in holdings) {
      final current =
          (holding['stock_symbol'] ?? holding['symbol'])?.toString().trim();
      if (current != null && current.toUpperCase() == symbol.toUpperCase()) {
        return holding;
      }
    }
    return null;
  }

  static List<_ChartPoint> _historyPoints({
    required Map<String, dynamic> dailyData,
    required Map<String, dynamic> weeklyData,
    required String range,
  }) {
    final rawSeries = range == '1Y'
        ? _seriesMap(weeklyData['Weekly Time Series'])
        : _seriesMap(dailyData['Time Series (Daily)']);

    final fallbackSeries = _seriesMap(dailyData['Time Series (Daily)']);
    final series = rawSeries.isNotEmpty ? rawSeries : fallbackSeries;
    final desiredCount = switch (range) {
      '7D' => 7,
      '1Y' => 52,
      _ => 30,
    };

    final points = <_ChartPoint>[];

    for (final entry in series.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;

      final value = entry.value is Map
          ? _number(
              (entry.value as Map)['4. close'] ?? (entry.value as Map)['close'],
            )
          : 0.0;

      if (value <= 0) continue;

      points.add(
        _ChartPoint(
          date: date,
          price: value,
          label: _labelForRange(date, range),
        ),
      );
    }

    points.sort((a, b) => a.date.compareTo(b.date));

    if (points.length > desiredCount) {
      return points.sublist(points.length - desiredCount);
    }

    return points;
  }

  static Map<String, dynamic> _seriesMap(Object? value) {
    if (value is Map) {
      return value.map((key, data) => MapEntry(key.toString(), data));
    }
    return const {};
  }

  static String _labelForRange(DateTime date, String range) {
    switch (range) {
      case '7D':
        return DateFormat('EEE').format(date);
      case '1Y':
        return DateFormat('MMM').format(date);
      default:
        return DateFormat('d MMM').format(date);
    }
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _cleanText(Object? value, {String fallback = 'N/A'}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return fallback;
    return text;
  }

  static String _formatMoney(double value, {int decimals = 2}) {
    final pattern = decimals == 0 ? '#,##,##0' : '#,##,##0.${'0' * decimals}';
    return NumberFormat(pattern, 'en_IN').format(value);
  }

  static String _formatCompactNumber(double value) {
    if (value <= 0) return 'Unknown';
    return NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 1,
    ).format(value);
  }

  static String _formatQuantity(double quantity) {
    final hasFraction = quantity.truncateToDouble() != quantity;
    return hasFraction
        ? '${quantity.toStringAsFixed(2)} shares'
        : '${quantity.toStringAsFixed(0)} shares';
  }

  static String _formatDate(Object? value) {
    final raw = value?.toString();
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return 'Unknown';
    return DateFormat('d MMM y').format(date);
  }
}

class _StockLineChart extends StatefulWidget {
  final List<_ChartPoint> data;
  final Color color;

  const _StockLineChart({
    required this.data,
    required this.color,
  });

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
  void didUpdateWidget(covariant _StockLineChart oldWidget) {
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
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        return CustomPaint(
          painter: _StockChartPainter(
            data: widget.data,
            color: widget.color,
            progress: _progress.value,
          ),
        );
      },
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

    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    final prices = data.map((point) => point.price).toList();
    final minValue = prices.reduce((a, b) => a < b ? a : b);
    final maxValue = prices.reduce((a, b) => a > b ? a : b);
    final range = ((maxValue - minValue)).clamp(1.0, double.maxFinite);
    final verticalPadding = range * 0.15;

    final allPoints = <Offset>[];
    for (int index = 0; index < data.length; index++) {
      final x = index / (data.length - 1) * size.width;
      final y = chartHeight -
          ((data[index].price - minValue + verticalPadding) /
                  (range + verticalPadding * 2)) *
              chartHeight;
      allPoints.add(Offset(x, y));
    }

    final stopIndex = progress * (allPoints.length - 1);
    final fullIndex = stopIndex.floor();
    final visible = allPoints.sublist(0, fullIndex + 1);
    if (fullIndex < allPoints.length - 1) {
      final fraction = stopIndex - fullIndex;
      final start = allPoints[fullIndex];
      final end = allPoints[fullIndex + 1];
      visible.add(
        Offset(
          start.dx + (end.dx - start.dx) * fraction,
          start.dy + (end.dy - start.dy) * fraction,
        ),
      );
    }

    if (visible.length < 2) return;

    final fillPath = Path()..moveTo(visible.first.dx, chartHeight);
    for (final point in visible) {
      fillPath.lineTo(point.dx, point.dy);
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
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0.0, 0.0, size.width, chartHeight)),
    );

    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (int index = 1; index < visible.length; index++) {
      linePath.lineTo(visible[index].dx, visible[index].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastPoint = visible.last;
    canvas.drawCircle(lastPoint, 5, Paint()..color = color);
    canvas.drawCircle(lastPoint, 3, Paint()..color = Colors.white);

    const textStyle = TextStyle(
      color: Color(0xFF475569),
      fontSize: 9,
    );
    final step = data.length > 6 ? (data.length / 6).ceil() : 1;

    for (int index = 0; index < data.length; index += step) {
      final textPainter = TextPainter(
        text: TextSpan(text: data[index].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (index / (data.length - 1) * size.width).toDouble();
      textPainter.paint(
        canvas,
        Offset(
          (x - textPainter.width / 2)
              .clamp(0.0, size.width - textPainter.width)
              .toDouble(),
          (chartHeight + 4.0).toDouble(),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}
