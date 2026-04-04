import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  Mock data models
// ─────────────────────────────────────────────
class _NewsItem {
  final int id;
  final String title;
  final String source;
  final String time;
  final String tag;
  final String category; // 'trending' | 'general'
  final Color imageColor;

  const _NewsItem({
    required this.id,
    required this.title,
    required this.source,
    required this.time,
    required this.tag,
    required this.category,
    required this.imageColor,
  });
}

const _mockNews = [
  _NewsItem(
    id: 1,
    title: 'TCS Q4 Results: Net profit surges 9% YoY, beats street estimates',
    source: 'Economic Times',
    time: '2h ago',
    tag: 'TCS',
    category: 'trending',
    imageColor: Color(0xFF1E1A4F),
  ),
  _NewsItem(
    id: 2,
    title: 'Reliance Industries to invest ₹75,000 Cr in green energy over next 3 years',
    source: 'Mint',
    time: '4h ago',
    tag: 'RELIANCE',
    category: 'general',
    imageColor: Color(0xFF2D1515),
  ),
  _NewsItem(
    id: 3,
    title: 'HDFC Bank raises MCLR by 5 bps across all tenors effective April',
    source: 'Business Standard',
    time: '6h ago',
    tag: 'HDFC',
    category: 'trending',
    imageColor: Color(0xFF2D2210),
  ),
  _NewsItem(
    id: 4,
    title: "Infosys bags 2.3B deal from a leading European financial services firm",
    source: 'Moneycontrol',
    time: '8h ago',
    tag: 'INFY',
    category: 'general',
    imageColor: Color(0xFF0D2416),
  ),
  _NewsItem(
    id: 5,
    title: 'Wipro to acquire a US-based cybersecurity firm for 230 million',
    source: 'NDTV Profit',
    time: '10h ago',
    tag: 'WIPRO',
    category: 'trending',
    imageColor: Color(0xFF0D1E24),
  ),
  _NewsItem(
    id: 6,
    title: 'SEBI tightens F&O regulations: New margin rules come into effect from May',
    source: 'Financial Express',
    time: '12h ago',
    tag: 'MARKET',
    category: 'general',
    imageColor: Color(0xFF1A0D2E),
  ),
];

class _TickerItem {
  final String symbol;
  final String value;
  final String change;
  final bool up;
  const _TickerItem(
      {required this.symbol,
        required this.value,
        required this.change,
        required this.up});
}

const _tickers = [
  _TickerItem(symbol: 'SENSEX', value: '72,845', change: '+1.2%', up: true),
  _TickerItem(symbol: 'NIFTY', value: '22,530', change: '+0.9%', up: true),
  _TickerItem(symbol: 'TCS', value: '₹3,842', change: '+2.1%', up: true),
  _TickerItem(
      symbol: 'RELIANCE', value: '₹2,312', change: '-1.4%', up: false),
  _TickerItem(symbol: 'HDFC', value: '₹1,620', change: '+0.8%', up: true),
];

const _myStockTags = {'TCS', 'RELIANCE', 'HDFC', 'INFY', 'WIPRO'};

// ─────────────────────────────────────────────
//  Tag accent color helper
// ─────────────────────────────────────────────
Color _tagAccent(String tag) {
  switch (tag) {
    case 'TCS':
      return const Color(0xFF6366F1);
    case 'RELIANCE':
      return const Color(0xFFEF4444);
    case 'HDFC':
      return const Color(0xFFF59E0B);
    case 'INFY':
      return const Color(0xFF10B981);
    case 'WIPRO':
      return const Color(0xFF06B6D4);
    default:
      return const Color(0xFF8B5CF6);
  }
}

// ─────────────────────────────────────────────
//  Market News Screen
// ─────────────────────────────────────────────
class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({super.key});

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen>
    with TickerProviderStateMixin {
  String _activeTab = 'All';
  int? _expandedId;

  late final AnimationController _listController;
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  static const _tabs = ['All', 'My Stocks', 'Trending'];

  List<_NewsItem> get _filteredNews => _mockNews.where((n) {
    if (_activeTab == 'All') return true;
    if (_activeTab == 'My Stocks') return _myStockTags.contains(n.tag);
    if (_activeTab == 'Trending') return n.category == 'trending';
    return true;
  }).toList();

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic));

    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 150), _listController.forward);
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      _expandedId = null;
    });
    _listController.forward(from: 0);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + tabs ──
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildHeader(),
              ),
            ),
            // ── Ticker row ──
            _buildTickerRow(),
            const SizedBox(height: 6),
            // ── News list ──
            Expanded(child: _buildNewsList()),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF130B2E), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Market News',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Stay updated with latest market events',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF131D2E),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: const Icon(Icons.search_rounded,
                    size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tab toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: _tabs.map((tab) {
                final isActive = _activeTab == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _switchTab(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isActive
                            ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1)
                                .withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : null,
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 13,
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TICKER ROW
  // ─────────────────────────────────────────────
  Widget _buildTickerRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _tickers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _tickers[i];
          final color =
          t.up ? const Color(0xFF10B981) : const Color(0xFFEF4444);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.symbol,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.value,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  t.up
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 11,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  t.change,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  NEWS LIST
  // ─────────────────────────────────────────────
  Widget _buildNewsList() {
    final news = _filteredNews;
    if (news.isEmpty) {
      return Center(
        child: Text(
          'No news for this filter',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: news.length,
      itemBuilder: (ctx, i) => _AnimatedNewsCard(
        news: news[i],
        index: i,
        listController: _listController,
        isExpanded: _expandedId == news[i].id,
        onTap: () => setState(() {
          _expandedId = _expandedId == news[i].id ? null : news[i].id;
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Animated news card widget
// ─────────────────────────────────────────────
class _AnimatedNewsCard extends StatefulWidget {
  final _NewsItem news;
  final int index;
  final AnimationController listController;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AnimatedNewsCard({
    required this.news,
    required this.index,
    required this.listController,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_AnimatedNewsCard> createState() => _AnimatedNewsCardState();
}

class _AnimatedNewsCardState extends State<_AnimatedNewsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandHeight;
  late final Animation<double> _expandOpacity;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _expandHeight = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOut);
    _expandOpacity = CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn));
  }

  @override
  void didUpdateWidget(covariant _AnimatedNewsCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded
          ? _expandCtrl.forward()
          : _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tagAccent(widget.news.tag);
    final delay = widget.index * 0.08;

    return AnimatedBuilder(
      animation: widget.listController,
      builder: (_, child) {
        final t = ((widget.listController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border:
            Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colorful top accent bar ──
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, Colors.transparent],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Illustration square
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: widget.news.imageColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accent.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.trending_up_rounded,
                            size: 22,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              // Tag + time row
                              Row(
                                children: [
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.news.tag,
                                      style: const TextStyle(
                                        color: Color(0xFF818CF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 10,
                                    color: Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.news.time,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Title
                              Text(
                                widget.news.title,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                maxLines: widget.isExpanded ? 10 : 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Source + link icon
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.news.source,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Expanded content ──
                    AnimatedBuilder(
                      animation: _expandCtrl,
                      builder: (_, __) => ClipRect(
                        child: Align(
                          heightFactor: _expandHeight.value,
                          child: FadeTransition(
                            opacity: _expandOpacity,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 1,
                                    color: Colors.white
                                        .withOpacity(0.06),
                                    margin: const EdgeInsets.only(
                                        bottom: 12),
                                  ),
                                  Text(
                                    'This article from ${widget.news.source} covers the latest developments regarding ${widget.news.tag}. The market is closely monitoring this situation as it may impact portfolio performance. Analysts suggest keeping a close watch on the next quarterly report.',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        'Read full article',
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: 12,
                                        color: accent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}