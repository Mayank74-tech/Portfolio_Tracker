import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/stock_controller.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

class _SearchResult {
  final String symbol;
  final String name;
  final String exchange;
  final double price;
  const _SearchResult(
      {required this.symbol,
      required this.name,
      required this.exchange,
      required this.price});
}

const _platforms = ['Zerodha', 'Groww', 'Angel One', 'Upstox', 'IIFL', 'Other'];

// ─────────────────────────────────────────────
//  Add Stock Screen
// ─────────────────────────────────────────────
class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

enum _Stage { form, success }

class _AddStockScreenState extends State<AddStockScreen>
    with TickerProviderStateMixin {
  late final StockController _stockController;
  late final PortfolioController _portfolioController;
  _Stage _stage = _Stage.form;

  // Form state
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _searchFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _priceFocus = FocusNode();

  _SearchResult? _selectedStock;
  String _platform = 'Zerodha';
  DateTime _buyDate = DateTime(2025, 4, 3);
  bool _showDropdown = false;
  List<_SearchResult> _filtered = [];

  // Animation controllers
  late final AnimationController _entranceCtrl;
  late final AnimationController _dropdownCtrl;
  late final AnimationController _previewCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _checkCtrl;

  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  late final Animation<double> _dropdownHeight;
  late final Animation<double> _previewFade;
  late final Animation<Offset> _previewSlide;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _stockController = Get.find<StockController>();
    _portfolioController = Get.isRegistered<PortfolioController>()
        ? Get.find<PortfolioController>()
        : Get.put(PortfolioController());
    _initAnimations();
    _entranceCtrl.forward();

    _searchController.addListener(_onSearchChanged);
    _qtyController.addListener(_onNumberChanged);
    _priceController.addListener(_onNumberChanged);
  }

  void _initAnimations() {
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _dropdownCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _previewCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _dropdownHeight =
        CurvedAnimation(parent: _dropdownCtrl, curve: Curves.easeOutCubic);

    _previewFade = CurvedAnimation(parent: _previewCtrl, curve: Curves.easeIn);
    _previewSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(parent: _previewCtrl, curve: Curves.easeOutCubic));

    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFade = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);

    _checkScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
  }

  Future<void> _onSearchChanged() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() => _filtered = []);
      _stockController.clearSearch();
      return;
    }

    await _stockController.searchStocks(q);
    final results = _stockController.searchResults
        .map(_searchResultFromMap)
        .where(
          (s) =>
              s.symbol.toLowerCase().contains(q.toLowerCase()) ||
              s.name.toLowerCase().contains(q.toLowerCase()),
        )
        .toList();

    setState(() => _filtered = results);
    if (results.isNotEmpty && !_showDropdown) {
      setState(() => _showDropdown = true);
      _dropdownCtrl.forward();
    } else if (results.isEmpty && _showDropdown) {
      _dropdownCtrl.reverse().then((_) {
        if (mounted) setState(() => _showDropdown = false);
      });
    }
  }

  void _onNumberChanged() {
    final hasData =
        _qtyController.text.isNotEmpty && _priceController.text.isNotEmpty;
    if (hasData) {
      _previewCtrl.forward();
    } else {
      _previewCtrl.reverse();
    }
  }

  void _selectStock(_SearchResult stock) {
    setState(() {
      _selectedStock = stock;
      _filtered = [];
      _showDropdown = false;
    });
    _dropdownCtrl.reverse();
    _searchController.text = '${stock.symbol} – ${stock.name}';
    _priceController.text = stock.price.toStringAsFixed(2);
    _searchFocus.unfocus();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _buyDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            surface: Color(0xFF1A2640),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _buyDate = picked);
  }

  Future<void> _handleAdd() async {
    final selected = _selectedStock;
    if (selected == null) return;

    await _portfolioController.addHolding({
      'stock_symbol': selected.symbol,
      'stock_name': selected.name,
      'exchange': selected.exchange,
      'quantity': double.tryParse(_qtyController.text) ?? 0,
      'buy_price': double.tryParse(_priceController.text) ?? 0,
      'buy_date': _buyDate.toIso8601String(),
      'platform': _platform,
    });

    // ✅ Check AFTER await — errorMessage is now populated if something failed
    if (_portfolioController.errorMessage.value.isNotEmpty) {
      Get.snackbar(
        'Could not add stock',
        _portfolioController.errorMessage.value,
        backgroundColor: const Color(0xFF1E293B),
        colorText: const Color(0xFFF1F5F9),
        snackPosition: SnackPosition.BOTTOM,
      );
      _portfolioController.clearError();
      return;
    }

    // ✅ No error = success
    if (!mounted) return;
    setState(() => _stage = _Stage.success);
    _successCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Get.offNamed(AppRoutes.DASHBOARD);
  }
  bool get _canAdd => _selectedStock != null && _qtyController.text.isNotEmpty;

  double get _totalInvested =>
      (double.tryParse(_qtyController.text) ?? 0) *
      (double.tryParse(_priceController.text) ?? 0);

  _SearchResult _searchResultFromMap(Map<String, dynamic> data) {
    final symbol = _firstString(data, ['symbol', 'displaySymbol', '1. symbol']);
    final name = _firstString(
      data,
      ['description', 'name', 'companyName', '2. name'],
      fallback: symbol,
    );
    final exchange = _firstString(
      data,
      ['exchange', 'type', '4. region'],
      fallback: 'NSE',
    );
    return _SearchResult(
      symbol: symbol,
      name: name,
      exchange: exchange,
      price: _number(data['price'] ?? data['c']),
    );
  }

  String _firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _searchFocus.dispose();
    _qtyFocus.dispose();
    _priceFocus.dispose();
    _entranceCtrl.dispose();
    _dropdownCtrl.dispose();
    _previewCtrl.dispose();
    _successCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.success) return _buildSuccessView();
    return _buildFormView();
  }

  // ─────────────────────────────────────────────
  //  SUCCESS VIEW
  // ─────────────────────────────────────────────
  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle with check
            ScaleTransition(
              scale: _successScale,
              child: FadeTransition(
                opacity: _successFade,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    border:
                        Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: const Icon(Icons.check_rounded,
                        size: 40, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _successFade,
              child: Column(
                children: [
                  const Text(
                    'Stock Added!',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_selectedStock?.symbol ?? "Stock"} has been added to your portfolio',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FORM VIEW
  // ─────────────────────────────────────────────
  Widget _buildFormView() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_showDropdown) {
          _dropdownCtrl.reverse().then(
              (_) => mounted ? setState(() => _showDropdown = false) : null);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(),

              // ── Scrollable form ──
              Expanded(
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 20),
                          _buildQtyPriceRow(),
                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildPlatformField(),
                          const SizedBox(height: 16),
                          _buildInvestmentPreview(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Add button ──
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left_rounded, onTap: () => Get.back()),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Add Stock',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              Text('Manually add to your portfolio',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search field + dropdown ──
  Widget _buildSearchField() {
    final isActive = _searchFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Search Stock'),
        const SizedBox(height: 8),
        // Search input
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF131D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive || _showDropdown
                  ? const Color(0xFF6366F1).withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded,
                  size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or symbol...',
                    hintStyle: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: const Color(0xFF6366F1),
                  onChanged: (_) {},
                ),
              ),
              if (_selectedStock != null)
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: Color(0xFF10B981)),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
        // Dropdown
        AnimatedBuilder(
          animation: _dropdownCtrl,
          builder: (_, __) => ClipRect(
            child: Align(
              heightFactor: _dropdownHeight.value,
              child: _buildDropdown(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2640),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        children: _filtered.map((stock) {
          return GestureDetector(
            onTap: () => _selectStock(stock),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: _filtered.indexOf(stock) > 0
                    ? Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.04)))
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                          stock.symbol.length >= 3 ? stock.symbol.substring(0, 3) : stock.symbol,
                          style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.symbol,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Text('${stock.name} · ${stock.exchange}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  Text(
                    '₹${stock.price.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Qty & Price row ──
  Widget _buildQtyPriceRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Quantity'),
              const SizedBox(height: 8),
              _inputBox(
                controller: _qtyController,
                focusNode: _qtyFocus,
                hint: '0',
                type: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Buy Price (₹)'),
              const SizedBox(height: 8),
              _inputBox(
                controller: _priceController,
                focusNode: _priceFocus,
                hint: '0.00',
                type: const TextInputType.numberWithOptions(decimal: true),
                prefix: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('₹',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Date field ──
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Buy Date'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(
                  '${_buyDate.day.toString().padLeft(2, '0')}/${_buyDate.month.toString().padLeft(2, '0')}/${_buyDate.year}',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Platform selector ──
  Widget _buildPlatformField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Platform'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _showPlatformBottomSheet();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _platform,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPlatformBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2640),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF6366F1), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Select Platform',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 16),
            ..._platforms.map((p) => GestureDetector(
                  onTap: () {
                    setState(() => _platform = p);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _platform == p
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p,
                            style: TextStyle(
                              color: _platform == p
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFFF1F5F9),
                              fontSize: 14,
                              fontWeight: _platform == p
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                        if (_platform == p)
                          const Icon(Icons.check_rounded,
                              size: 16, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Investment preview ──
  Widget _buildInvestmentPreview() {
    return AnimatedBuilder(
      animation: _previewCtrl,
      builder: (_, __) {
        if (_previewCtrl.value == 0) return const SizedBox.shrink();
        return FadeTransition(
          opacity: _previewFade,
          child: SlideTransition(
            position: _previewSlide,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Investment Preview',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Invested',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          )),
                      Text(
                        '₹${_totalInvested.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Add button ──
  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: GestureDetector(
        onTap: _canAdd ? _handleAdd : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: _canAdd
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  )
                : null,
            color: _canAdd ? null : Colors.white.withOpacity(0.06),
            boxShadow: _canAdd
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded,
                  color: _canAdd ? Colors.white : const Color(0xFF64748B),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Add to Portfolio',
                style: TextStyle(
                  color: _canAdd ? Colors.white : const Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF131D2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        ),
      );

  Widget _inputBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? type,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
  }) =>
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            if (prefix != null) prefix,
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: type,
                inputFormatters: inputFormatters,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      );
}

// ── Reusable label ──
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
}
