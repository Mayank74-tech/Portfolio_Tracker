// lib/presentation/controllers/finance_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/finance_repository.dart';

class FinanceController extends GetxController {
  FinanceController({FinanceRepository? repository})
      : _repo = repository ?? FinanceRepository();

  final FinanceRepository _repo;

  // ── Reactive state ───────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isVerifying = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedPeriod = '1M'.obs;

  final RxList<Map<String, dynamic>> accounts =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> analysis =
  Rx<Map<String, dynamic>>({});

  // ── Connection session state ─────────────────────────────────────────────
  final RxString currentSessionId = ''.obs;
  final RxString currentDemoOtp = ''.obs;
  final RxString pendingBankId = ''.obs;
  final RxString pendingAccountNumber = ''.obs;
  final RxString pendingIfsc = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFinance();
  }

  Future<void> _initializeFinance() async {
    try {
      await _repo.ensureBoxesOpen();
      await _repo.clearExpiredSessions();
      loadAccounts();
    } catch (e) {
      errorMessage.value =
      'Failed to initialize finance storage: $e';
      debugPrint('Finance init error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNTS
  // ════════════════════════════════════════════════════════════════════════

  void loadAccounts() {
    accounts.assignAll(_repo.getAccounts());
    if (accounts.isNotEmpty) {
      loadAnalysis();
      loadTransactions();
    } else {
      transactions.clear();
      analysis.value = {};
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // NEW 2-STEP CONNECTION FLOW
  // ════════════════════════════════════════════════════════════════════════

  /// STEP 1: Initiate connection - validates bank/account/IFSC, sends OTP.
  /// Returns true on success, false on failure.
  Future<bool> initiateConnection({
    required String bankId,
    required String accountNumber,
    required String ifsc,
  }) async {
    isConnecting.value = true;
    errorMessage.value = '';
    currentSessionId.value = '';
    currentDemoOtp.value = '';

    try {
      final result = await _repo.initiateBankConnection(
        bankId: bankId,
        accountNumber: accountNumber,
        ifsc: ifsc,
      );

      // ✅ Store session info for OTP verification step
      currentSessionId.value =
          result['sessionId']?.toString() ?? '';
      currentDemoOtp.value = result['otp']?.toString() ?? '';

      // ✅ Cache pending details for resend support
      pendingBankId.value = bankId;
      pendingAccountNumber.value = accountNumber;
      pendingIfsc.value = ifsc.toUpperCase();

      return currentSessionId.value.isNotEmpty;
    } catch (e) {
      errorMessage.value =
          e.toString().replaceAll('Exception: ', '');
      debugPrint('Initiate connection error: $e');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  /// STEP 2: Verify OTP and complete bank connection.
  /// Returns true on success, false on failure.
  Future<bool> verifyOtpAndConnect({
    required String otp,
    required String accountType,
  }) async {
    if (currentSessionId.value.isEmpty) {
      errorMessage.value = 'No active session. Please start over.';
      return false;
    }

    isVerifying.value = true;
    errorMessage.value = '';

    try {
      await _repo.verifyAndConnect(
        sessionId: currentSessionId.value,
        otp: otp,
        accountType: accountType,
      );

      // ✅ Reload accounts after successful connection
      loadAccounts();

      // ✅ Clear session state
      _clearSessionState();

      return true;
    } catch (e) {
      errorMessage.value =
          e.toString().replaceAll('Exception: ', '');
      debugPrint('Verify OTP error: $e');
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  /// Resend OTP for current pending session
  Future<bool> resendOtp() async {
    if (currentSessionId.value.isEmpty) {
      errorMessage.value = 'No active session';
      return false;
    }

    try {
      final newOtp = await _repo.resendOtp(currentSessionId.value);
      currentDemoOtp.value = newOtp;
      return true;
    } catch (e) {
      errorMessage.value =
          e.toString().replaceAll('Exception: ', '');
      debugPrint('Resend OTP error: $e');
      return false;
    }
  }

  /// Cancel current connection attempt
  void cancelConnection() {
    _clearSessionState();
    errorMessage.value = '';
  }

  void _clearSessionState() {
    currentSessionId.value = '';
    currentDemoOtp.value = '';
    pendingBankId.value = '';
    pendingAccountNumber.value = '';
    pendingIfsc.value = '';
  }

  // ════════════════════════════════════════════════════════════════════════
  // DEPRECATED: Old single-step connect (backward compatibility)
  // ════════════════════════════════════════════════════════════════════════

  @Deprecated('Use initiateConnection() + verifyOtpAndConnect() instead')
  Future<bool> connectBank({
    required String bankId,
    required String accountType,
  }) async {
    isConnecting.value = true;
    errorMessage.value = '';
    try {
      // ignore: deprecated_member_use_from_same_package
      await _repo.connectAccount(
        bankId: bankId,
        accountType: accountType,
      );
      loadAccounts();
      return true;
    } catch (e) {
      errorMessage.value =
          e.toString().replaceAll('Exception: ', '');
      debugPrint('Connect error: $e');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════
  // ANALYSIS
  // ════════════════════════════════════════════════════════════════════════

  void loadAnalysis() {
    final range = _dateRange();
    analysis.value = _repo.getSpendingAnalysis(
      from: range.$1,
      to: range.$2,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYNC
  // ════════════════════════════════════════════════════════════════════════

  Future<void> syncAccount(String accountId) async {
    isLoading.value = true;
    try {
      await _repo.syncAccount(accountId);
      loadAccounts();
    } catch (e) {
      errorMessage.value = 'Sync failed: $e';
      debugPrint('Sync error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sync all connected accounts in parallel
  Future<void> syncAllAccounts() async {
    if (accounts.isEmpty) return;

    isLoading.value = true;
    try {
      await _repo.syncAllAccounts();
      loadAccounts();
    } catch (e) {
      errorMessage.value = 'Sync failed: $e';
      debugPrint('Sync all error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // DISCONNECT
  // ════════════════════════════════════════════════════════════════════════

  Future<void> disconnectAccount(String accountId) async {
    try {
      await _repo.disconnectAccount(accountId);
      loadAccounts();
    } catch (e) {
      errorMessage.value = 'Disconnect failed: $e';
      debugPrint('Disconnect error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PERIOD SELECTOR
  // ════════════════════════════════════════════════════════════════════════

  void setPeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    loadAnalysis();
    loadTransactions();
  }

  // ════════════════════════════════════════════════════════════════════════
  // SPENDING vs INVESTING COMPARISON
  // ════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> getSpendVsInvestComparison(double totalInvested) {
    final spent = _toDouble(analysis.value['total_spent']);
    final cats = (analysis.value['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final investCat = cats.firstWhere(
          (c) => c['name']?.toString() == 'investment',
      orElse: () => <String, dynamic>{'amount': 0.0},
    );

    final investedThisPeriod = _toDouble(investCat['amount']);

    final ratio =
    spent == 0 ? 0.0 : (investedThisPeriod / spent) * 100;

    String insight;
    if (ratio < 10) {
      insight = 'You\'re spending ₹${_fmtNum(spent)} '
          'but only investing ₹${_fmtNum(investedThisPeriod)}. '
          'Consider increasing your SIP.';
    } else if (ratio < 20) {
      insight = 'Good balance — investing '
          '${ratio.toStringAsFixed(1)}% of '
          'what you spend.';
    } else {
      insight = 'Excellent — your investment ratio '
          'is ${ratio.toStringAsFixed(1)}% '
          'of spending.';
    }

    return {
      'total_spent': spent,
      'invested_this_period': investedThisPeriod,
      'invest_ratio': ratio,
      'insight': insight,
    };
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════

  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case '1W':
        return (now.subtract(const Duration(days: 7)), now);
      case '3M':
        return (DateTime(now.year, now.month - 2, 1), now);
      case '6M':
        return (DateTime(now.year, now.month - 5, 1), now);
      default: // 1M
        return (DateTime(now.year, now.month, 1), now);
    }
  }

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
}