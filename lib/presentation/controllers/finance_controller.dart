// lib/presentation/controllers/finance_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/finance_repository.dart';

class FinanceController extends GetxController {
  FinanceController({FinanceRepository? repository})
      : _repo = repository ?? FinanceRepository();

  final FinanceRepository _repo;

  final RxBool isLoading       = false.obs;
  final RxBool isConnecting    = false.obs;
  final RxString errorMessage  = ''.obs;
  final RxString selectedPeriod = '1M'.obs;

  final RxList<Map<String, dynamic>> accounts =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> analysis =
  Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    _initializeFinance();
  }

  Future<void> _initializeFinance() async {
    try {
      await _repo.ensureBoxesOpen();
      loadAccounts();
    } catch (e) {
      errorMessage.value = 'Failed to initialize finance storage: $e';
      debugPrint('Finance init error: $e');
    }
  }

  // ── Load accounts ──────────────────────────────────────────────────────────

  void loadAccounts() {
    accounts.assignAll(_repo.getAccounts());
    if (accounts.isNotEmpty) {
      loadAnalysis();
      loadTransactions();
    }
  }

  // ── Connect bank ───────────────────────────────────────────────────────────

  Future<bool> connectBank({
    required String bankId,
    required String accountType,
  }) async {
    isConnecting.value = true;
    errorMessage.value = '';
    try {
      await _repo.connectAccount(
        bankId: bankId,
        accountType: accountType,
      );
      loadAccounts();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('Connect error: $e');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  // ── Load transactions ──────────────────────────────────────────────────────

  void loadTransactions({String? category}) {
    final range = _dateRange();
    transactions.assignAll(
      _repo.getTransactions(
        from: range.$1,
        to: range.$2,
        category: category,
      ),
    );
  }

  // ── Load analysis ──────────────────────────────────────────────────────────

  void loadAnalysis() {
    final range = _dateRange();
    analysis.value = _repo.getSpendingAnalysis(
      from: range.$1,
      to: range.$2,
    );
  }

  // ── Sync account ───────────────────────────────────────────────────────────

  Future<void> syncAccount(String accountId) async {
    isLoading.value = true;
    try {
      await _repo.syncAccount(accountId);
      loadAccounts();
      loadAnalysis();
      loadTransactions();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  Future<void> disconnectAccount(
      String accountId) async {
    await _repo.disconnectAccount(accountId);
    loadAccounts();
    if (accounts.isEmpty) {
      transactions.clear();
      analysis.value = {};
    } else {
      loadAnalysis();
      loadTransactions();
    }
  }

  // ── Period selector ────────────────────────────────────────────────────────

  void setPeriod(String period) {
    selectedPeriod.value = period;
    loadAnalysis();
    loadTransactions();
  }

  // ── Spending vs investing comparison ───────────────────────────────────────

  Map<String, dynamic> getSpendVsInvestComparison(
      double totalInvested) {
    final spent =
    _toDouble(analysis.value['total_spent']);
    final cats = (analysis.value['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final investCat = cats.firstWhere(
      (c) => c['name']?.toString() == 'investment',
      orElse: () => <String, dynamic>{'amount': 0.0},
    );

    final investedThisPeriod =
        _toDouble(investCat['amount']);

    final ratio = spent == 0
        ? 0.0
        : (investedThisPeriod / spent) * 100;

    return {
      'total_spent':          spent,
      'invested_this_period': investedThisPeriod,
      'invest_ratio':         ratio,
      'insight': ratio < 10
          ? 'You\'re spending ₹${_fmtNum(spent)} '
          'but only investing ₹${_fmtNum(investedThisPeriod)}. '
          'Consider increasing your SIP.'
          : ratio < 20
          ? 'Good balance — investing '
          '${ratio.toStringAsFixed(1)}% of '
          'what you spend.'
          : 'Excellent — your investment ratio '
          'is ${ratio.toStringAsFixed(1)}% '
          'of spending.',
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case '1W':
        return (
        now.subtract(const Duration(days: 7)),
        now,
        );
      case '3M':
        return (
        DateTime(now.year, now.month - 2, 1),
        now,
        );
      case '6M':
        return (
        DateTime(now.year, now.month - 5, 1),
        now,
        );
      default: // 1M
        return (DateTime(now.year, now.month, 1), now);
    }
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _fmtNum(double v) {
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(0);
  }
}
