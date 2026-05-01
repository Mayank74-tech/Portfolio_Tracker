import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/app_background.dart';
import 'package:smart_portfolio_tracker/presentation/widgets/common/glass_container.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen>
    with SingleTickerProviderStateMixin {
  late final PortfolioController _portfolioController;
  late final AnimationController _listController;

  String _searchQuery = '';
  String _sortBy = 'name'; // name | value | pl
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _portfolioController = Get.find<PortfolioController>();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portfolioController.loadHoldings();
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> holdings) {
    var list = holdings.where((h) {
      final symbol =
      (h['stock_symbol'] ?? h['symbol'] ?? '').toString().toUpperCase();
      final name =
      (h['stock_name'] ?? h['name'] ?? '').toString().toUpperCase();
      final q = _searchQuery.toUpperCase();
      return q.isEmpty || symbol.contains(q) || name.contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'value':
          final aVal = _asDouble(a['current_price'] ?? a['buy_price']) *
              _asDouble(a['quantity']);
          final bVal = _asDouble(b['current_price'] ?? b['buy_price']) *
              _asDouble(b['quantity']);
          cmp = aVal.compareTo(bVal);
          break;
        case 'pl':
          final aPL = _plPercent(a);
          final bPL = _plPercent(b);
          cmp = aPL.compareTo(bPL);
          break;
        default: // name
          final aName =
          (a['stock_symbol'] ?? a['symbol'] ?? '').toString();
          final bName =
          (b['stock_symbol'] ?? b['symbol'] ?? '').toString();
          cmp = aName.compareTo(bName);
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  double _plPercent(Map<String, dynamic> h) {
    final buy = _asDouble(h['buy_price']);
    final cur = _asDouble(h['current_price'] ?? h['buy_price']);
    return buy == 0 ? 0 : ((cur - buy) / buy) * 100;
  }

  // ── Confirm delete dialog ──────────────────────────────────────────────────

  Future<void> _confirmDelete(Map<String, dynamic> holding) async {
    final symbol =
    (holding['stock_symbol'] ?? holding['symbol'] ?? '').toString();
    final id = holding['id']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF131D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Remove Holding',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remove $symbol from your portfolio?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

    if (confirmed == true && id.isNotEmpty) {
      await _portfolioController.deleteHolding(id);
      // Re-animate list after deletion
      _listController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildSortBar(),
            Expanded(
              child: Obx(() {
                if (_portfolioController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  );
                }

                final filtered =
                _filtered(_portfolioController.holdings);

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF131D2E),
                  onRefresh: () => _portfolioController.loadHoldings(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildHoldingCard(filtered[i], i),
                  ),
                );
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
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'All Holdings',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Obx(() {
            final count = _portfolioController.holdings.length;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count stocks',
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GlassContainer(
        height: 44,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search stocks…',
            hintStyle: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF475569),
              size: 18,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF475569),
                size: 16,
              ),
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Sort bar ───────────────────────────────────────────────────────────────

  Widget _buildSortBar() {
    final options = [
      ('name', 'Name'),
      ('value', 'Value'),
      ('pl', 'P&L %'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          const Text(
            'Sort:',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          ...options.map((opt) {
            final isActive = _sortBy == opt.$1;
            return GestureDetector(
              onTap: () => setState(() {
                if (_sortBy == opt.$1) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = opt.$1;
                  _sortAsc = true;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                      : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt.$2,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _sortAsc
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: const Color(0xFF818CF8),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Holding card ───────────────────────────────────────────────────────────

  Widget _buildHoldingCard(Map<String, dynamic> h, int index) {
    final symbol =
    (h['stock_symbol'] ?? h['symbol'] ?? 'STK').toString();
    final name =
    (h['stock_name'] ?? h['name'] ?? symbol).toString();
    final platform = (h['platform'] ?? 'Manual').toString();
    final buyPrice = _asDouble(h['buy_price']);
    final currentPrice =
    _asDouble(h['current_price'] ?? h['buy_price']);
    final qty = _asDouble(h['quantity']);
    final invested = buyPrice * qty;
    final currentValue = currentPrice * qty;
    final pl = currentValue - invested;
    final plPct = buyPrice == 0
        ? 0.0
        : ((currentPrice - buyPrice) / buyPrice) * 100;
    final isGain = pl >= 0;
    final gainColor =
    isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final buyDate = _formatDate(h['buy_date']);

    return AnimatedBuilder(
      animation: _listController,
      builder: (_, child) {
        final delay = (index * 0.08).clamp(0.0, 0.6);
        final t = (_listController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 20),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(h['id'] ?? symbol + index.toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          await _confirmDelete(h);
          return false; // always return false — we handle deletion ourselves
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              SizedBox(height: 4),
              Text(
                'Remove',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => Get.toNamed(
            AppRoutes.STOCK_DETAIL,
            arguments: {'symbol': symbol},
          ),
          child: GlassContainer(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // ── Row 1: Avatar + Name + Delete btn ──
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: gainColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                  BorderRadius.circular(6),
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
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: () => _confirmDelete(h),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Divider ──
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 14),
                // ── Row 2: Stats grid ──
                Row(
                  children: [
                    _statCol('Qty',
                        qty.toStringAsFixed(
                            qty.truncateToDouble() == qty ? 0 : 2)),
                    _statCol('Buy Price',
                        '₹${_formatNum(buyPrice)}'),
                    _statCol('Cur. Price',
                        '₹${_formatNum(currentPrice)}'),
                    _statCol('Value',
                        '₹${_formatNum(currentValue)}'),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Row 3: P&L bar ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: gainColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gainColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGain
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: gainColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'P&L',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${isGain ? "+" : "-"}₹${_formatNum(pl.abs())}',
                        style: TextStyle(
                          color: gainColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: gainColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${isGain ? "+" : ""}${plPct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: gainColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ── Row 4: Buy date ──
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bought on $buyDate',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Expanded(
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
          const SizedBox(height: 3),
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

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: Color(0xFF6366F1),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No holdings yet',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different symbol or name.'
                  : 'Add your first stock to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.ADD_STOCK),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1)
                            .withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Add Stock',
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
            ],
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.ADD_STOCK),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Stock',
              style: TextStyle(
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatNum(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  static String _formatDate(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return 'Unknown';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}