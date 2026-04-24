import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_portfolio_tracker/core/utils/csv_parser.dart';
import 'package:smart_portfolio_tracker/presentation/controllers/portfolio_controller.dart';
import 'package:smart_portfolio_tracker/presentation/routes/app_routes.dart';

const _brokers = [
  ('Zerodha', Color(0xFF6366F1)),
  ('Groww', Color(0xFF10B981)),
  ('Angel One', Color(0xFFF59E0B)),
  ('Upstox', Color(0xFFEF4444)),
  ('IIFL', Color(0xFF8B5CF6)),
  ('Other', Color(0xFF64748B)),
];

enum _Stage { upload, preview, done }

class ImportCsvScreen extends StatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  State<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends State<ImportCsvScreen>
    with TickerProviderStateMixin {
  late final PortfolioController _portfolioController;

  _Stage _stage = _Stage.upload;
  bool _isPicking = false;
  bool _isImporting = false;

  String? _fileName;
  int? _fileSizeBytes;
  String? _parseError;
  List<String> _warnings = const [];
  List<CsvImportRow> _parsedRows = const [];

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
    _portfolioController = Get.isRegistered<PortfolioController>()
        ? Get.find<PortfolioController>()
        : Get.put(PortfolioController());
    _initAnimations();
    _uploadCtrl.forward();
  }

  void _initAnimations() {
    _uploadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _previewCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _doneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _uploadFade = CurvedAnimation(parent: _uploadCtrl, curve: Curves.easeIn);
    _uploadSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _uploadCtrl, curve: Curves.easeOutCubic),
    );
    _previewFade = CurvedAnimation(parent: _previewCtrl, curve: Curves.easeIn);
    _previewSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _previewCtrl, curve: Curves.easeOutCubic),
    );
    _doneScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _doneCtrl, curve: Curves.elasticOut),
    );
    _doneFade = CurvedAnimation(parent: _doneCtrl, curve: Curves.easeIn);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _uploadCtrl.dispose();
    _previewCtrl.dispose();
    _doneCtrl.dispose();
    _pulseCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleFilePick() async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
      _parseError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException(
          'Could not read this file. Try a smaller CSV or export it again.',
        );
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = CsvParser.parse(content);

      await _uploadCtrl.reverse();
      if (!mounted) return;

      setState(() {
        _fileName = file.name;
        _fileSizeBytes = file.size;
        _parsedRows = parsed.rows;
        _warnings = parsed.warnings;
        _parseError = null;
        _stage = _Stage.preview;
      });

      _previewCtrl.forward(from: 0);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _parseError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _parseError = 'Could not import CSV: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (_parsedRows.isEmpty || _isImporting) return;

    setState(() => _isImporting = true);
    _portfolioController.clearError();

    await _portfolioController.importHoldings(
      _parsedRows.map((row) => row.toHoldingMap()).toList(),
    );

    if (!mounted) return;

    if (_portfolioController.errorMessage.value.isNotEmpty) {
      setState(() => _isImporting = false);
      Get.snackbar(
        'Import failed',
        _portfolioController.errorMessage.value,
        backgroundColor: const Color(0xFF1E293B),
        colorText: const Color(0xFFF1F5F9),
      );
      return;
    }

    await _previewCtrl.reverse();
    if (!mounted) return;

    setState(() {
      _stage = _Stage.done;
      _isImporting = false;
    });

    _doneCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    _checkCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Get.offNamed(AppRoutes.DASHBOARD);
    }
  }

  Future<void> _resetToUpload() async {
    if (_stage == _Stage.preview) {
      await _previewCtrl.reverse();
    }

    if (!mounted) return;
    setState(() {
      _stage = _Stage.upload;
      _parseError = null;
      _fileName = null;
      _fileSizeBytes = null;
      _warnings = const [];
      _parsedRows = const [];
    });
    _uploadCtrl.forward(from: 0);
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
            position: _uploadSlide,
            child: _buildUploadStage(),
          ),
        );
      case _Stage.preview:
        return FadeTransition(
          key: const ValueKey('preview'),
          opacity: _previewFade,
          child: SlideTransition(
            position: _previewSlide,
            child: _buildPreviewStage(),
          ),
        );
      case _Stage.done:
        return _buildDoneStage();
    }
  }

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
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import CSV',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Bulk import portfolio holdings',
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

  Widget _buildUploadStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF818CF8),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Columns',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Required: Symbol, Quantity, Buy Price. Optional: Buy Date, Platform, Stock Name, Exchange.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Supported Brokers',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: _brokers.map((broker) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: broker.$2.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: broker.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    broker.$1,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _handleFilePick,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isPicking
                        ? const Color(0xFF6366F1)
                        : Colors.white.withValues(alpha: 0.12),
                    width: 2,
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
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isPicking
                              ? Icons.hourglass_top_rounded
                              : Icons.table_chart_outlined,
                          size: 30,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isPicking ? 'Reading CSV...' : 'Tap to Upload CSV',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick a portfolio export and we will preview it before import',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Choose File',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_parseError != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _parseError!,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewStage() {
    final totalInvested = _parsedRows.fold<double>(
      0,
      (sum, row) => sum + (row.quantity * row.buyPrice),
    );
    final platformCount = _parsedRows
        .map((row) => row.platform.isEmpty ? 'Imported CSV' : row.platform)
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.table_chart_outlined,
                size: 20,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'portfolio.csv',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_parsedRows.length} valid rows · ${_formatFileSize(_fileSizeBytes)}',
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
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Preview (${_parsedRows.length} holdings)',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF1A2640),
                child: Row(
                  children: ['Symbol', 'Qty', 'Buy ₹', 'Platform']
                      .map(
                        (header) => Expanded(
                          child: Text(
                            header,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              ..._parsedRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  color: index.isEven
                      ? const Color(0xFF111827)
                      : Colors.white.withValues(alpha: 0.02),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.stockSymbol,
                          style: const TextStyle(
                            color: Color(0xFFF1F5F9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatQuantity(row.quantity),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '₹${_formatMoney(row.buyPrice)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.platform.isEmpty ? 'Imported CSV' : row.platform,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (_warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_warnings.length} row(s) skipped',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._warnings.take(4).map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          warning,
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                if (_warnings.length > 4)
                  Text(
                    '${_warnings.length - 4} more warning(s) not shown here.',
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Holdings', '${_parsedRows.length}'),
              _summaryItem('Invested', '₹${_formatMoney(totalInvested)}'),
              _summaryItem('Platforms', '$platformCount'),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isImporting
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isImporting ? 'Importing...' : 'Confirm Import',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
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
                  const Text(
                    'Import Successful!',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_parsedRows.length} holdings added to your portfolio',
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

  static String _formatMoney(double value) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(value);
  }

  static String _formatQuantity(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  static String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
