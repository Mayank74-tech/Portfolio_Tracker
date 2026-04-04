import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

// ─────────────────────────────────────────────
//  Mock CSV preview data
// ─────────────────────────────────────────────
class _CsvRow {
  final String symbol;
  final int qty;
  final double buyPrice;
  final String platform;
  const _CsvRow(
      {required this.symbol,
        required this.qty,
        required this.buyPrice,
        required this.platform});
}

const _csvPreview = [
  _CsvRow(symbol: 'RELIANCE', qty: 10, buyPrice: 2400, platform: 'Zerodha'),
  _CsvRow(symbol: 'TCS', qty: 5, buyPrice: 3500, platform: 'Zerodha'),
  _CsvRow(symbol: 'INFY', qty: 15, buyPrice: 1500, platform: 'Groww'),
  _CsvRow(symbol: 'HDFCBANK', qty: 8, buyPrice: 1600, platform: 'Angel One'),
  _CsvRow(symbol: 'WIPRO', qty: 20, buyPrice: 420, platform: 'Groww'),
];

const _brokers = [
  ('Zerodha', Color(0xFF6366F1)),
  ('Groww', Color(0xFF10B981)),
  ('Angel One', Color(0xFFF59E0B)),
  ('Upstox', Color(0xFFEF4444)),
  ('IIFL', Color(0xFF8B5CF6)),
  ('Other', Color(0xFF64748B)),
];

// ─────────────────────────────────────────────
//  Import CSV Screen
// ─────────────────────────────────────────────
enum _Stage { upload, preview, done }

class ImportCsvScreen extends StatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  State<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends State<ImportCsvScreen>
    with TickerProviderStateMixin {
  _Stage _stage = _Stage.upload;
  bool _hovering = false;

  // Animation controllers
  late final AnimationController _uploadCtrl;
  late final AnimationController _previewCtrl;
  late final AnimationController _doneCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _checkCtrl;

  late final Animation<double> _uploadFade;
  late final Animation<Offset> _uploadSlide;
  late final Animation<double> _previewFade;
  late final Animation<Offset> _previewSlide;
  late final Animation<double> _doneScale;
  late final Animation<double> _doneFade;
  late final Animation<double> _pulse;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _uploadCtrl.forward();
  }

  void _initAnimations() {
    _uploadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _previewCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _doneCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _uploadFade =
        CurvedAnimation(parent: _uploadCtrl, curve: Curves.easeIn);
    _uploadSlide = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _uploadCtrl, curve: Curves.easeOutCubic));

    _previewFade =
        CurvedAnimation(parent: _previewCtrl, curve: Curves.easeIn);
    _previewSlide = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _previewCtrl, curve: Curves.easeOutCubic));

    _doneScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _doneCtrl, curve: Curves.elasticOut));
    _doneFade =
        CurvedAnimation(parent: _doneCtrl, curve: Curves.easeIn);

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
  }

  Future<void> _handleFilePick() async {
    // Simulate file parsing delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _uploadCtrl.reverse();
    setState(() => _stage = _Stage.preview);
    _previewCtrl.forward();
  }

  Future<void> _handleConfirm() async {
    await _previewCtrl.reverse();
    setState(() => _stage = _Stage.done);
    _doneCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) Get.offNamed(AppRoutes.DASHBOARD);
  }

  void _resetToUpload() async {
    await _previewCtrl.reverse();
    setState(() => _stage = _Stage.upload);
    _uploadCtrl.forward(from: 0);
  }

  double get _totalInvested =>
      _csvPreview.fold(0, (s, r) => s + r.qty * r.buyPrice);

  int get _platformCount =>
      _csvPreview.map((r) => r.platform).toSet().length;

  @override
  void dispose() {
    _uploadCtrl.dispose();
    _previewCtrl.dispose();
    _doneCtrl.dispose();
    _pulseCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_stage) {
      case _Stage.upload:
        return FadeTransition(
            key: const ValueKey('upload'),
            opacity: _uploadFade,
            child: SlideTransition(
                position: _uploadSlide, child: _buildUploadStage()));
      case _Stage.preview:
        return FadeTransition(
            key: const ValueKey('preview'),
            opacity: _previewFade,
            child: SlideTransition(
                position: _previewSlide, child: _buildPreviewStage()));
      case _Stage.done:
        return _buildDoneStage();
    }
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  size: 18, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Import CSV',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              Text('Bulk import from your broker',
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

  // ─────────────────────────────────────────────
  //  UPLOAD STAGE
  // ─────────────────────────────────────────────
  Widget _buildUploadStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF818CF8)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Supported CSV Format',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                  SizedBox(height: 2),
                  Text(
                    'Symbol, Quantity, Buy Price, Buy Date, Platform',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Broker grid
        const Text('Supported Brokers',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: _brokers.map((b) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: b.$2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: b.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(b.$1,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      )),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Drop zone
        GestureDetector(
          onTap: _handleFilePick,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: _hovering
                    ? const Color(0xFF6366F1).withOpacity(0.12)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hovering
                      ? const Color(0xFF6366F1)
                      : Colors.white.withOpacity(0.12),
                  width: 2,
                  // dashed via custom painter below
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.table_chart_outlined,
                        size: 30,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to Upload File',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'or drag & drop your CSV here',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.upload_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Choose File',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Sample download
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.table_chart_outlined,
                  size: 14, color: Color(0xFF818CF8)),
              SizedBox(width: 8),
              Text(
                'Download Sample CSV Template',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  PREVIEW STAGE
  // ─────────────────────────────────────────────
  Widget _buildPreviewStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // File info row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_chart_outlined,
                  size: 20, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('portfolio_export.csv',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      '${_csvPreview.length} records found · 2.4 KB',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _resetToUpload,
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('Preview (${_csvPreview.length} stocks)',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            )),
        const SizedBox(height: 10),

        // Table
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: const Color(0xFF1A2640),
                child: Row(
                  children: ['Symbol', 'Qty', 'Buy ₹', 'Platform']
                      .map((h) => Expanded(
                    child: Text(h,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                  ))
                      .toList(),
                ),
              ),
              // Rows
              ..._csvPreview.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  color: i.isEven
                      ? const Color(0xFF111827)
                      : Colors.white.withOpacity(0.02),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(row.symbol,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      Expanded(
                        child: Text('${row.qty}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            )),
                      ),
                      Expanded(
                        child: Text(
                          '₹${row.buyPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(row.platform,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                  )),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined,
                                size: 10,
                                color: Color(0xFF6366F1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Summary row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Total Stocks',
                  '${_csvPreview.length}'),
              _summaryItem('Total Invested',
                  '₹${_totalInvested.toStringAsFixed(0)}'),
              _summaryItem('Platforms',
                  '$_platformCount'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Confirm button
        GestureDetector(
          onTap: _handleConfirm,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Confirm Import',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value) => Column(
    children: [
      Text(label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
          )),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
    ],
  );

  // ─────────────────────────────────────────────
  //  DONE STAGE
  // ─────────────────────────────────────────────
  Widget _buildDoneStage() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _doneScale,
              child: FadeTransition(
                opacity: _doneFade,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    const Color(0xFF10B981).withOpacity(0.15),
                    border: Border.all(
                        color: const Color(0xFF10B981), width: 2),
                  ),
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _doneFade,
              child: Column(
                children: [
                  const Text('Import Successful!',
                      style: TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    '${_csvPreview.length} stocks added to your portfolio',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}