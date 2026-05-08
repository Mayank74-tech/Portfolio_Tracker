// lib/data/repositories/finance_repository.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/finance/bank_account_model.dart';
import '../services/remote/mock_bank_service.dart';

class FinanceRepository {
  FinanceRepository({MockBankService? service})
      : _service = service ?? MockBankService();

  final MockBankService _service;

  static const String _accountsBox = 'bank_accounts';
  static const String _transactionsBox = 'transactions';
  static const String _sessionsBox = 'connection_sessions';

  Box get _accounts => Hive.box(_accountsBox);
  Box get _transactions => Hive.box(_transactionsBox);
  Box get _sessions => Hive.box(_sessionsBox);

  Future<void> ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_accountsBox)) {
      await Hive.openBox(_accountsBox);
    }
    if (!Hive.isBoxOpen(_transactionsBox)) {
      await Hive.openBox(_transactionsBox);
    }
    if (!Hive.isBoxOpen(_sessionsBox)) {
      await Hive.openBox(_sessionsBox);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // NEW 2-STEP BANK CONNECTION FLOW
  // ════════════════════════════════════════════════════════════════════════

  /// STEP 1: Validate account + IFSC, get OTP
  /// Returns: { sessionId, otp (demo), message, expiresIn }
  Future<Map<String, dynamic>> initiateBankConnection({
    required String bankId,
    required String accountNumber,
    required String ifsc,
  }) async {
    // ✅ Client-side validation first (fast fail)
    if (!MockBankService.isValidAccountNumber(accountNumber)) {
      throw Exception('Account number must be 9-18 digits');
    }
    if (!MockBankService.isValidIfsc(ifsc)) {
      throw Exception('Invalid IFSC code format');
    }

    final result = await _service.initiateConnection(
      bankId: bankId,
      accountNumber: accountNumber,
      ifsc: ifsc,
    );

    // ✅ Store session locally for retry/resend support
    final sessionId = result['sessionId']?.toString();
    if (sessionId != null) {
      await _sessions.put(sessionId, {
        'sessionId': sessionId,
        'bankId': bankId,
        'accountNumber': accountNumber,
        'ifsc': ifsc.toUpperCase(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return result;
  }

  /// STEP 2: Verify OTP and complete connection
  Future<BankAccountModel> verifyAndConnect({
    required String sessionId,
    required String otp,
    required String accountType,
  }) async {
    if (otp.length != 6) {
      throw Exception('OTP must be 6 digits');
    }

    final accountData = await _service.verifyOtp(
      sessionId: sessionId,
      otp: otp,
      accountType: accountType,
    );

    // ✅ Convert to model
    final account = BankAccountModel(
      id: accountData['id']?.toString() ?? '',
      bankName: accountData['bankName']?.toString() ?? '',
      accountType: accountData['accountType']?.toString() ?? 'savings',
      maskedNumber: accountData['maskedNumber']?.toString() ?? '',
      balance: _toDouble(accountData['balance']),
      connectedAt: DateTime.tryParse(
        accountData['connectedAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      lastSynced: DateTime.tryParse(
        accountData['lastSynced']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );

    // ✅ Persist to Hive with extra fields
    await _accounts.put(account.id, {
      'id': account.id,
      'bankName': account.bankName,
      'bankId': accountData['bankId']?.toString() ?? '',
      'accountType': account.accountType,
      'accountNumber': accountData['accountNumber']?.toString() ?? '',
      'ifsc': accountData['ifsc']?.toString() ?? '',
      'maskedNumber': account.maskedNumber,
      'balance': account.balance,
      'connectedAt': account.connectedAt.toIso8601String(),
      'lastSynced': account.lastSynced.toIso8601String(),
    });

    // ✅ Cleanup session after successful connection
    await _sessions.delete(sessionId);

    // ✅ Auto-fetch initial transactions
    await _syncTransactions(account.id);

    return account;
  }

  /// Resend OTP for an existing session
  Future<String> resendOtp(String sessionId) async {
    final session = _sessions.get(sessionId);
    if (session == null) {
      throw Exception('Session expired. Please start over.');
    }
    return await _service.resendOtp(sessionId);
  }

  // ════════════════════════════════════════════════════════════════════════
  // DEPRECATED: Old single-step connection (kept for backward compatibility)
  // ════════════════════════════════════════════════════════════════════════

  @Deprecated('Use initiateBankConnection() + verifyAndConnect() instead')
  Future<BankAccountModel> connectAccount({
    required String bankId,
    required String accountType,
  }) async {
    final accountData = await _service.connectBank(
      bankId: bankId,
      accountType: accountType,
    );

    final account = BankAccountModel(
      id: accountData['id']?.toString() ?? '',
      bankName: accountData['bankName']?.toString() ?? '',
      accountType: accountData['accountType']?.toString() ?? 'savings',
      maskedNumber: accountData['maskedNumber']?.toString() ?? '',
      balance: _toDouble(accountData['balance']),
      connectedAt: DateTime.tryParse(
        accountData['connectedAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      lastSynced: DateTime.tryParse(
        accountData['lastSynced']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );

    await _accounts.put(account.id, {
      'id': account.id,
      'bankName': account.bankName,
      'accountType': account.accountType,
      'maskedNumber': account.maskedNumber,
      'balance': account.balance,
      'connectedAt': account.connectedAt.toIso8601String(),
      'lastSynced': account.lastSynced.toIso8601String(),
    });

    await _syncTransactions(account.id);
    return account;
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNTS
  // ════════════════════════════════════════════════════════════════════════

  /// Get all connected accounts
  List<Map<String, dynamic>> getAccounts() {
    return _accounts.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  /// Get single account by ID
  Map<String, dynamic>? getAccount(String accountId) {
    final raw = _accounts.get(accountId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Disconnect a bank account (deletes account + its transactions)
  Future<void> disconnectAccount(String accountId) async {
    await _accounts.delete(accountId);

    // ✅ Batch delete transactions for this account
    final toDelete = _transactions.keys.where((k) {
      final tx = _transactions.get(k);
      if (tx is Map) {
        return tx['accountId'] == accountId;
      }
      return false;
    }).toList();

    for (final key in toDelete) {
      await _transactions.delete(key);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Get filtered transactions
  List<Map<String, dynamic>> getTransactions({
    String? accountId,
    String? category,
    DateTime? from,
    DateTime? to,
    String? type, // 'debit' or 'credit'
  }) {
    var all = _transactions.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();

    if (accountId != null) {
      all = all.where((t) => t['accountId'] == accountId).toList();
    }
    if (category != null) {
      all = all.where((t) => t['category'] == category).toList();
    }
    if (type != null) {
      all = all.where((t) => t['type'] == type).toList();
    }
    if (from != null) {
      all = all.where((t) {
        final date = DateTime.tryParse(t['date']?.toString() ?? '');
        return date != null && !date.isBefore(from);
      }).toList();
    }
    if (to != null) {
      all = all.where((t) {
        final date = DateTime.tryParse(t['date']?.toString() ?? '');
        return date != null && !date.isAfter(to);
      }).toList();
    }

    // ✅ Sort by date descending (newest first)
    all.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
      final bDate =
          DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return all;
  }

  // ════════════════════════════════════════════════════════════════════════
  // SPENDING ANALYSIS
  // ════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> getSpendingAnalysis({
    DateTime? from,
    DateTime? to,
  }) {
    final now = DateTime.now();
    final start = from ?? DateTime(now.year, now.month, 1);
    final end = to ?? now;

    final debits = getTransactions(
      from: start,
      to: end,
      type: 'debit',
    );
    final credits = getTransactions(
      from: start,
      to: end,
      type: 'credit',
    );

    final totalSpent = debits.fold(
      0.0,
          (sum, t) => sum + _toDouble(t['amount']),
    );
    final totalEarned = credits.fold(
      0.0,
          (sum, t) => sum + _toDouble(t['amount']),
    );

    // ✅ Category aggregation in single pass
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final t in debits) {
      final cat = t['category']?.toString() ?? 'other';
      categoryTotals[cat] =
          (categoryTotals[cat] ?? 0.0) + _toDouble(t['amount']);
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final categories = categoryTotals.entries.map((e) {
      return {
        'name': e.key,
        'amount': e.value,
        'percentage':
        totalSpent == 0 ? 0.0 : (e.value / totalSpent) * 100,
        'count': categoryCounts[e.key] ?? 0,
        'emoji': _categoryEmoji(e.key),
      };
    }).toList()
      ..sort((a, b) =>
          _toDouble(b['amount']).compareTo(_toDouble(a['amount'])));

    // ✅ Daily spending trend
    final dailySpend = <String, double>{};
    for (final t in debits) {
      final date = DateTime.tryParse(t['date']?.toString() ?? '');
      if (date == null) continue;
      final key = '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      dailySpend[key] = (dailySpend[key] ?? 0) + _toDouble(t['amount']);
    }

    // ✅ Biggest single transaction
    Map<String, dynamic>? biggest;
    for (final t in debits) {
      if (biggest == null ||
          _toDouble(t['amount']) > _toDouble(biggest['amount'])) {
        biggest = t;
      }
    }

    // ✅ Savings rate
    final savingsRate = totalEarned == 0
        ? 0.0
        : ((totalEarned - totalSpent) / totalEarned) * 100;

    // ✅ Average daily spend
    final daysDiff = end.difference(start).inDays + 1;
    final avgDaily = daysDiff > 0 ? totalSpent / daysDiff : 0.0;

    return {
      'total_spent': totalSpent,
      'total_earned': totalEarned,
      'savings_rate': savingsRate,
      'avg_daily_spend': avgDaily,
      'categories': categories,
      'daily_spend': dailySpend,
      'biggest_expense': biggest,
      'transaction_count': debits.length,
      'period_start': start.toIso8601String(),
      'period_end': end.toIso8601String(),
      'period_days': daysDiff,
    };
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYNC
  // ════════════════════════════════════════════════════════════════════════

  /// Fetch latest transactions for an account
  Future<void> _syncTransactions(String accountId) async {
    try {
      final transactions = await _service.getTransactions(accountId);

      for (final tx in transactions) {
        final id = tx['id']?.toString();
        if (id == null) continue;

        await _transactions.put(id, {
          'id': id,
          'accountId': tx['accountId']?.toString() ?? accountId,
          'amount': _toDouble(tx['amount']),
          'type': tx['type']?.toString() ?? 'debit',
          'category': tx['category']?.toString() ?? 'other',
          'description': tx['description']?.toString() ?? '',
          'merchantName': tx['merchantName']?.toString() ?? '',
          'date': tx['date']?.toString() ??
              DateTime.now().toIso8601String(),
          'balanceAfter': _toDouble(tx['balanceAfter']),
        });
      }
    } catch (e) {
      debugPrint('Sync transactions error: $e');
    }
  }

  /// Refresh balance + transactions for an account
  Future<void> syncAccount(String accountId) async {
    try {
      // Refresh transactions
      await _syncTransactions(accountId);

      // Refresh balance
      final balanceData = await _service.getBalance(accountId);
      final newBalance = _toDouble(balanceData['balance']);

      final existing = _accounts.get(accountId);
      if (existing != null) {
        final map = Map<String, dynamic>.from(existing as Map);
        map['balance'] = newBalance;
        map['lastSynced'] = DateTime.now().toIso8601String();
        await _accounts.put(accountId, map);
      }
    } catch (e) {
      debugPrint('Sync account error: $e');
    }
  }

  /// Sync all connected accounts at once (parallel)
  Future<void> syncAllAccounts() async {
    final accounts = getAccounts();
    if (accounts.isEmpty) return;

    // ✅ Run all syncs in parallel
    await Future.wait(
      accounts.map((a) => syncAccount(a['id'].toString())),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SESSIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Clear expired connection sessions (older than 10 minutes)
  Future<void> clearExpiredSessions() async {
    final now = DateTime.now();
    final toDelete = <dynamic>[];

    for (final key in _sessions.keys) {
      final session = _sessions.get(key);
      if (session is Map) {
        final createdAt = DateTime.tryParse(
          session['createdAt']?.toString() ?? '',
        );
        if (createdAt != null &&
            now.difference(createdAt).inMinutes > 10) {
          toDelete.add(key);
        }
      }
    }

    for (final key in toDelete) {
      await _sessions.delete(key);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ════════════════════════════════════════════════════════════════════════

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _categoryEmoji(String cat) {
    const map = {
      'food': '🍔',
      'transport': '🚗',
      'shopping': '🛍',
      'investment': '📈',
      'utilities': '💡',
      'entertainment': '🎬',
      'health': '🏥',
      'other': '💰',
    };
    return map[cat] ?? '💰';
  }
}