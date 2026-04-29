import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/app_background.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final Map<String, dynamic> _article;
  WebViewController? _webViewController;
  bool _isLoadingPage = true;
  bool _showWebView = false;

  @override
  void initState() {
    super.initState();
    _article = _normalizeArticle(Get.arguments);
    final url = _url;

    if (url.isNotEmpty) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoadingPage = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoadingPage = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _isLoadingPage = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    } else {
      _isLoadingPage = false;
    }
  }

  String get _title => _article['title']?.toString() ?? 'Market update';
  String get _source => _article['source']?.toString() ?? 'Unknown source';
  String get _summary {
    final description = _article['description']?.toString().trim();
    if (description != null && description.isNotEmpty) return description;
    final snippet = _article['snippet']?.toString().trim();
    if (snippet != null && snippet.isNotEmpty) return snippet;
    return 'Open the original article for the full report and source details.';
  }

  String get _url => _article['url']?.toString().trim() ?? '';
  String get _publishedAt => _formatPublished(_article['published_at']);
  String get _tag => _primaryTag(_article);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showWebView ? _buildWebView() : _buildSummaryView(),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _iconButton(Icons.chevron_left_rounded, onTap: () => Get.back()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'News Detail',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _source,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_url.isNotEmpty)
            _iconButton(
              Icons.open_in_browser_rounded,
              onTap: _openExternal,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1A4F), Color(0xFF0F0D2E)],
              ),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _tag,
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _publishedAt,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _summary,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMetaCard(),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    final entities = (_article['entities'] is List)
        ? (_article['entities'] as List)
            .whereType<Map>()
            .map((entity) => entity.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList()
        : <Map<String, dynamic>>[];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Article Context',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _metaRow('Source', _source),
          _metaRow('Published', _publishedAt),
          _metaRow(
              'Linked article', _url.isEmpty ? 'Unavailable' : 'Available'),
          if (entities.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Mentioned Symbols',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entities.take(8).map((entity) {
                final symbol = entity['symbol']?.toString().toUpperCase() ??
                    entity['name']?.toString() ??
                    'MARKET';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_url.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                setState(() => _showWebView = true);
              },
              icon: const Icon(Icons.language_rounded),
              label: const Text('Read Inside App'),
            ),
          ),
        if (_url.isNotEmpty) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCBD5E1),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _url.isEmpty ? null : _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Original Source'),
          ),
        ),
      ],
    );
  }

  Widget _buildWebView() {
    if (_webViewController == null) {
      return _buildUnavailableState();
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showWebView = false),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'In-app article view',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isLoadingPage)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: WebViewWidget(controller: _webViewController!),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableState() {
    return const Center(
      child: Text(
        'This article does not include a readable link.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
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
        child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
      ),
    );
  }

  Future<void> _openExternal() async {
    if (_url.isEmpty) return;
    final uri = Uri.tryParse(_url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Map<String, dynamic> _normalizeArticle(Object? arguments) {
    if (arguments is Map) {
      return arguments.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String _formatPublished(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Unknown';
    final local = date.toLocal();
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year} · $hour:$minute $period';
  }

  static String _primaryTag(Map<String, dynamic> article) {
    final entities = article['entities'];
    if (entities is List && entities.isNotEmpty && entities.first is Map) {
      final entity = (entities.first as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      final symbol = entity['symbol']?.toString().trim();
      if (symbol != null && symbol.isNotEmpty) return symbol.toUpperCase();
      final name = entity['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name.toUpperCase();
    }
    return 'MARKET';
  }
}
