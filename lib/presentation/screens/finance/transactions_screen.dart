// lib/presentation/screens/finance/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/finance_controller.dart';
import '../../widgets/common/glass_container.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final FinanceController _fc;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  String _selectedCategory = 'all';
  String _selectedType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController =
  TextEditingController();

  static const List<Map<String, String>> _categories = [
    {'key': 'all',           'label': 'All',           'emoji': '📋'},
    {'key': 'food',          'label': 'Food',          'emoji': '🍔'},
    {'key': 'transport',     'label': 'Transport',     'emoji': '🚗'},
    {'key': 'shopping',      'label': 'Shopping',      'emoji': '🛍'},
    {'key': 'investment',    'label': 'Investment',    'emoji': '📈'},
    {'key': 'utilities',     'label': 'Utilities',     'emoji': '💡'},
    {'key': 'entertainment', 'label': 'Entertainment', 'emoji': '🎬'},
    {'key': 'health',        'label': 'Health',        'emoji': '🏥'},
    {'key': 'other',         'label': 'Other',         'emoji': '💰'},
  ];

  @override
  void initState() {
    super.initState();
    _fc = Get.find<FinanceController>();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade =
        CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(
      List<Map<String, dynamic>> all) {
    return all.where((tx) {
      // Category filter
      if (_selectedCategory != 'all' &&
          tx['category']?.toString() !=
              _selectedCategory) {
        return false;
      }
      // Type filter
      if (_selectedType != 'all' &&
          tx['type']?.toString() != _selectedType) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final desc = tx['description']
            ?.toString()
            .toLowerCase() ??
            '';
        final merchant = tx['merchantName']
            ?.toString()
            .toLowerCase() ??
            '';
        final q = _searchQuery.toLowerCase();
        if (!desc.contains(q) && !merchant.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  double _filteredTotal(
      List<Map<String, dynamic>> filtered) {
    return filtered
        .where((tx) => tx['type'] == 'debit')
        .fold(0.0, (sum, tx) => sum + _toDouble(tx['amount']));
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
              _buildSearchBar(),
              _buildTypeFilter(),
              _buildCategoryFilter(),
              Expanded(
                child: Obx(() {
                  final filtered =
                  _filtered(_fc.transactions);
                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionList(filtered);
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
          _iconBox(Icons.chevron_left_rounded,
              onTap: () => Get.back()),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'All your bank transactions',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final count = _filtered(
                _fc.transactions)
                .length;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count txns',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
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
          controller: _searchController,
          onChanged: (v) =>
              setState(() => _searchQuery = v),
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search transactions…',
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
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
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

  // ── Type filter ────────────────────────────────────────────────────────────

  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _typeChip('all', 'All'),
          const SizedBox(width: 8),
          _typeChip('debit', '💸 Spent'),
          const SizedBox(width: 8),
          _typeChip('credit', '💚 Received'),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label) {
    final isActive = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0EA5E9)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0EA5E9)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
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
    );
  }

  // ── Category filter ────────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isActive =
              _selectedCategory == cat['key'];
          return GestureDetector(
            onTap: () => setState(
                    () => _selectedCategory = cat['key']!),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.15)
                    : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF0EA5E9)
                      .withValues(alpha: 0.4)
                      : Colors.white
                      .withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['emoji']!,
                      style: const TextStyle(
                          fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Transaction list ───────────────────────────────────────────────────────

  Widget _buildTransactionList(
      List<Map<String, dynamic>> filtered) {
    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final tx in filtered) {
      final date = DateTime.tryParse(
          tx['date']?.toString() ?? '');
      if (date == null) continue;
      final key = _dateKey(date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final total = _filteredTotal(filtered);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: keys.length + 1,
      itemBuilder: (ctx, index) {
        // Summary header
        if (index == 0) {
          return _buildSummaryHeader(
              filtered, total);
        }

        final key = keys[index - 1];
        final txs = grouped[key]!;
        final dayTotal = txs
            .where((t) => t['type'] == 'debit')
            .fold(0.0,
                (sum, t) => sum + _toDouble(t['amount']));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 10),
              child: Row(
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (dayTotal > 0)
                    Text(
                      '-₹${_fmtNum(dayTotal)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            // Transactions for this date
            GlassContainer(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: txs
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final tx = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        Container(
                          height: 1,
                          margin:
                          const EdgeInsets.only(
                              left: 60),
                          color: Colors.white
                              .withValues(alpha: 0.04),
                        ),
                      _buildTransactionTile(tx),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(
      List<Map<String, dynamic>> filtered,
      double total) {
    final creditTotal = filtered
        .where((t) => t['type'] == 'credit')
        .fold(
        0.0,
            (sum, t) =>
        sum + _toDouble(t['amount']));

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Expanded(
            child: _summaryCol(
              'Total Spent',
              '-₹${_fmtNum(total)}',
              const Color(0xFFEF4444),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          Expanded(
            child: _summaryCol(
              'Total Received',
              '+₹${_fmtNum(creditTotal)}',
              const Color(0xFF10B981),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          Expanded(
            child: _summaryCol(
              'Transactions',
              '${filtered.length}',
              const Color(0xFF0EA5E9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCol(
      String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
      Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amount = _toDouble(tx['amount']);
    final cat = tx['category'].toString();
    final desc = tx['description'].toString();
    final date = DateTime.tryParse(
        tx['date']?.toString() ?? '');
    final balance = _toDouble(tx['balanceAfter']);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor(cat)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _categoryEmoji(cat),
                style:
                const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(cat)
                            .withValues(alpha: 0.1),
                        borderRadius:
                        BorderRadius.circular(4),
                      ),
                      child: Text(
                        _capitalize(cat),
                        style: TextStyle(
                          color: _categoryColor(cat),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(date),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount + balance
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}₹${_fmtNum(amount)}',
                style: TextStyle(
                  color: isCredit
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (balance > 0)
                Text(
                  'Bal: ₹${_fmtNum(balance)}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                  ),
                ),
            ],
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9)
                    .withValues(alpha: 0.1),
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF0EA5E9),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No transactions found',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your filters or search query.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _iconBox(IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon,
            size: 18, color: const Color(0xFF94A3B8)),
      ),
    );
  }

  static Color _categoryColor(String cat) {
    const map = {
      'food':          Color(0xFFEF4444),
      'transport':     Color(0xFFF59E0B),
      'shopping':      Color(0xFF8B5CF6),
      'investment':    Color(0xFF10B981),
      'utilities':     Color(0xFF0EA5E9),
      'entertainment': Color(0xFFF97316),
      'health':        Color(0xFFEC4899),
      'other':         Color(0xFF64748B),
    };
    return map[cat] ?? const Color(0xFF64748B);
  }

  static String _categoryEmoji(String cat) {
    const map = {
      'food':          '🍔',
      'transport':     '🚗',
      'shopping':      '🛍',
      'investment':    '📈',
      'utilities':     '💡',
      'entertainment': '🎬',
      'health':        '🏥',
      'other':         '💰',
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

  static String _dateKey(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday =
    today.subtract(const Duration(days: 1));
    final dateOnly =
    DateTime(d.year, d.month, d.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
