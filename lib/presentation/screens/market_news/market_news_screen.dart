import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/news_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/app_background.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class _NewsItem {
  final int id;
  final String title;
  final String source;
  final String time;
  final String tag;
  final String summary;
  final String url;
  final String imageUrl;
  final String category;
  final Color accent;
  final Color imageColor;
  final Map<String, dynamic> raw;

  const _NewsItem({
    required this.id,
    required this.title,
    required this.source,
    required this.time,
    required this.tag,
    required this.summary,
    required this.url,
    required this.imageUrl,
    required this.category,
    required this.accent,
    required this.imageColor,
    required this.raw,
  });
}

Color _tagAccent(String tag) {
  switch (tag) {
    case 'TCS':
      return const Color(0xFF6366F1);
    case 'RELIANCE':
      return const Color(0xFFEF4444);
    case 'HDFC':
    case 'HDFCBANK':
      return const Color(0xFFF59E0B);
    case 'INFY':
      return const Color(0xFF10B981);
    case 'WIPRO':
      return const Color(0xFF06B6D4);
    default:
      return const Color(0xFF8B5CF6);
  }
}

class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({super.key});

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen>
    with TickerProviderStateMixin {
  late final NewsController _newsController;
  late final PortfolioController _portfolioController;
  late final AnimationController _listController;
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  String _activeTab = 'All';

  static const _tabs = ['All', 'My Stocks', 'Trending'];

  List<_NewsItem> get _items =>
      _newsController.news.map(_newsItemFromMap).toList();

  List<String> get _headlineTags {
    final tags = <String>{};
    for (final item in _items) {
      if (item.tag != 'MARKET') tags.add(item.tag);
      if (tags.length == 8) break;
    }
    return tags.isEmpty ? const ['MARKET', 'NIFTY', 'SENSEX'] : tags.toList();
  }

  @override
  void initState() {
    super.initState();
    _newsController = Get.find<NewsController>();
    _portfolioController = Get.find<PortfolioController>();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeIn,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 150), _listController.forward);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newsController.loadLatestNews();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _switchTab(String tab) async {
    setState(() => _activeTab = tab);

    if (tab == 'My Stocks') {
      await _loadMyStockNews();
    } else if (tab == 'Trending') {
      await _newsController.searchNews('market');
    } else {
      await _newsController.loadLatestNews();
    }

    _listController.forward(from: 0);
  }

  Future<void> _loadMyStockNews() async {
    if (_portfolioController.holdings.isEmpty) {
      await _portfolioController.loadHoldings();
    }
    await _newsController.loadNewsForHoldings(_portfolioController.holdings);
  }

  Future<void> _showSearchDialog() async {
    final controller = TextEditingController();

    await Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Search News',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search by company, stock symbol, or topic.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Try RELIANCE, AI, banking...',
                    hintStyle: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onSubmitted: (value) async {
                    Get.back<void>();
                    setState(() => _activeTab = 'All');
                    await _newsController.searchNews(value);
                    _listController.forward(from: 0);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    Get.back<void>();
                    setState(() => _activeTab = 'All');
                    await _newsController.searchNews(controller.text);
                    _listController.forward(from: 0);
                  },
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  _NewsItem _newsItemFromMap(Map<String, dynamic> data) {
    final entities = data['entities'];
    final tag = entities is List && entities.isNotEmpty && entities.first is Map
        ? ((entities.first as Map)['symbol'] ?? (entities.first as Map)['name'])
                ?.toString()
                .toUpperCase() ??
            'MARKET'
        : 'MARKET';

    final accent = _tagAccent(tag);
    return _NewsItem(
      id: (data['uuid'] ?? data['url'] ?? data['title'] ?? data.hashCode)
          .toString()
          .hashCode,
      title: data['title']?.toString().trim().isNotEmpty == true
          ? data['title'].toString().trim()
          : 'Market update',
      source: data['source']?.toString().trim().isNotEmpty == true
          ? data['source'].toString().trim()
          : 'Marketaux',
      time: _relativeTime(data['published_at']),
      tag: tag,
      summary: _summaryFrom(data),
      url: data['url']?.toString() ?? '',
      imageUrl: data['image_url']?.toString() ?? '',
      category: _activeTab == 'Trending' ? 'trending' : 'general',
      accent: accent,
      imageColor: accent.withValues(alpha: 0.16),
      raw: data,
    );
  }

  String _summaryFrom(Map<String, dynamic> data) {
    final summary = data['description']?.toString().trim();
    if (summary != null && summary.isNotEmpty) return summary;
    final snippet = data['snippet']?.toString().trim();
    if (snippet != null && snippet.isNotEmpty) return snippet;
    return 'Open the article to read the full market update and source context.';
  }

  String _relativeTime(Object? value) {
    final published = DateTime.tryParse(value?.toString() ?? '');
    if (published == null) return 'Just now';
    final diff = DateTime.now().difference(published);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildHeader(),
                ),
              ),
              _buildHeadlineTags(),
              const SizedBox(height: 6),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF131D2E),
                  onRefresh: () => _switchTab(_activeTab),
                  child: _buildNewsList(),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    'Live headlines for your portfolio and the market',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showSearchDialog,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D2E),
                    borderRadius: BorderRadius.circular(11),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
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
                                      .withValues(alpha: 0.35),
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
                          color:
                              isActive ? Colors.white : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildHeadlineTags() {
    final tags = _headlineTags;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, index) {
          final tag = tags[index];
          final accent = _tagAccent(tag);
          return GestureDetector(
            onTap: () async {
              setState(() => _activeTab = 'All');
              await _newsController.searchNews(tag);
              _listController.forward(from: 0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    tag,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tags.length,
      ),
    );
  }

  Widget _buildNewsList() {
    final items = _items;

    if (_newsController.isLoading.value && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No news for this filter',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _AnimatedNewsCard(
          news: items[index],
          index: index,
          listController: _listController,
          onTap: () => Get.toNamed(
            AppRoutes.NEWS_DETAIL,
            arguments: items[index].raw,
          ),
        );
      },
    );
  }
}

class _AnimatedNewsCard extends StatelessWidget {
  final _NewsItem news;
  final int index;
  final AnimationController listController;
  final VoidCallback onTap;

  const _AnimatedNewsCard({
    required this.news,
    required this.index,
    required this.listController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.08;

    return AnimatedBuilder(
      animation: listController,
      builder: (_, child) {
        final t =
            ((listController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [news.accent, Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: news.imageColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: news.accent.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: news.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  news.tag,
                                  style: TextStyle(
                                    color: news.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
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
                                news.time,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news.title,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news.summary,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${news.source} · ${news.category == 'trending' ? 'Trending' : 'Latest'}',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: news.accent,
                              ),
                            ],
                          ),
                        ],
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
