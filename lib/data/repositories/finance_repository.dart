// lib/data/repositories/finance_repository.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/finance/bank_account_model.dart';
import '../services/remote/mock_bank_service.dart';

class FinanceRepository {
  FinanceRepository({MockBankService? service})
      : _service = service ?? MockBankService();

  final MockBankService _service;

  static const String _accountsBox     = 'bank_accounts';
  static const String _transactionsBox = 'transactions';

  Box get _accounts     => Hive.box(_accountsBox);
  Box get _transactions => Hive.box(_transactionsBox);

  Future<void> ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_accountsBox)) {
      await Hive.openBox(_accountsBox);
    }
    if (!Hive.isBoxOpen(_transactionsBox)) {
      await Hive.openBox(_transactionsBox);
    }
  }

  // ── Connect bank account ───────────────────────────────────────────────────

  Future<BankAccountModel> connectAccount({
    required String bankId,
    required String accountType,
  }) async {
    final account = await _service.connectAccount(
      bankId: bankId,
      accountType: accountType,
    );

    await _accounts.put(account.id, {
      'id':           account.id,
      'bankName':     account.bankName,
      'accountType':  account.accountType,
      'maskedNumber': account.maskedNumber,
      'balance':      account.balance,
      'connectedAt':  account.connectedAt.toIso8601String(),
      'lastSynced':   account.lastSynced.toIso8601String(),
    });

    // Fetch last 30 days of transactions
    await _syncTransactions(account.id);

    return account;
  }

  // ── Get all connected accounts ─────────────────────────────────────────────

  List<Map<String, dynamic>> getAccounts() {
    return _accounts.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  // ── Get transactions ───────────────────────────────────────────────────────

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
      all = all
          .where((t) => t['accountId'] == accountId)
          .toList();
    }
    if (category != null) {
      all = all
          .where((t) => t['category'] == category)
          .toList();
    }
    if (type != null) {
      all = all
          .where((t) => t['type'] == type)
          .toList();
    }
    if (from != null) {
      all = all.where((t) {
        final date = DateTime.tryParse(
            t['date']?.toString() ?? '');
        return date != null && !date.isBefore(from);
      }).toList();
    }
    if (to != null) {
      all = all.where((t) {
        final date = DateTime.tryParse(
            t['date']?.toString() ?? '');
        return date != null && !date.isAfter(to);
      }).toList();
    }

    all.sort((a, b) {
      final aDate = DateTime.tryParse(
          a['date']?.toString() ?? '') ??
          DateTime.now();
      final bDate = DateTime.tryParse(
          b['date']?.toString() ?? '') ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });

    return all;
  }

  // ── Spending analysis ──────────────────────────────────────────────────────

  Map<String, dynamic> getSpendingAnalysis({
    DateTime? from,
    DateTime? to,
  }) {
    final now = DateTime.now();
    final start = from ??
        DateTime(now.year, now.month, 1);
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

    // Total spent this period
    final totalSpent = debits.fold(
        0.0, (sum, t) => sum + _toDouble(t['amount']));
    final totalEarned = credits.fold(
        0.0, (sum, t) => sum + _toDouble(t['amount']));

    // Category breakdown
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final t in debits) {
      final cat = t['category']?.toString() ?? 'other';
      final existing = categoryTotals[cat] ?? 0.0;
      categoryTotals[cat] = existing + _toDouble(t['amount']);
      final existingCount = categoryCounts[cat] ?? 0;
      categoryCounts[cat] = existingCount + 1;
    }

    final categories = categoryTotals.entries.map((e) {
      return {
        'name':              e.key,
        'amount':            e.value,
        'percentage':        totalSpent == 0
            ? 0.0
            : (e.value / totalSpent) * 100,
        'count':             categoryCounts[e.key] ?? 0,
        'emoji':             _categoryEmoji(e.key),
      };
    }).toList()
      ..sort((a, b) => _toDouble(b['amount'])
          .compareTo(_toDouble(a['amount'])));

    // Daily spending trend
    final dailySpend = <String, double>{};
    for (final t in debits) {
      final date = DateTime.tryParse(
          t['date']?.toString() ?? '');
      if (date == null) continue;
      final key =
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      dailySpend[key] =
          (dailySpend[key] ?? 0) + _toDouble(t['amount']);
    }

    // Biggest single transaction
    Map<String, dynamic>? biggest;
    for (final t in debits) {
      if (biggest == null ||
          _toDouble(t['amount']) >
              _toDouble(biggest['amount'])) {
        biggest = t;
      }
    }

    // Savings rate
    final savingsRate = totalEarned == 0
        ? 0.0
        : ((totalEarned - totalSpent) / totalEarned) *
        100;

    return {
      'total_spent':       totalSpent,
      'total_earned':      totalEarned,
      'savings_rate':      savingsRate,
      'categories':        categories,
      'daily_spend':       dailySpend,
      'biggest_expense':   biggest,
      'transaction_count': debits.length,
      'period_start':      start.toIso8601String(),
      'period_end':        end.toIso8601String(),
    };
  }

  // ── Sync transactions ──────────────────────────────────────────────────────

  Future<void> _syncTransactions(String accountId) async {
    try {
      final transactions = await _service.fetchTransactions(
        accountId: accountId,
        fromDate: DateTime.now()
            .subtract(const Duration(days: 30)),
        toDate: DateTime.now(),
      );

      for (final tx in transactions) {
        await _transactions.put(tx.id, {
          'id':           tx.id,
          'accountId':    tx.accountId,
          'amount':       tx.amount,
          'type':         tx.type,
          'category':     tx.category,
          'description':  tx.description,
          'merchantName': tx.merchantName,
          'date':         tx.date.toIso8601String(),
          'balanceAfter': tx.balanceAfter,
        });
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> syncAccount(String accountId) async {
    await _syncTransactions(accountId);
    final newBalance =
    await _service.syncBalance(accountId);
    final existing = _accounts.get(accountId);
    if (existing != null) {
      final map =
      Map<String, dynamic>.from(existing as Map);
      map['balance'] = newBalance;
      map['lastSynced'] =
          DateTime.now().toIso8601String();
      await _accounts.put(accountId, map);
    }
  }

  Future<void> disconnectAccount(
      String accountId) async {
    await _accounts.delete(accountId);
    final toDelete = _transactions.keys
        .where((k) =>
    _transactions.get(k)?['accountId'] ==
        accountId)
        .toList();
    for (final key in toDelete) {
      await _transactions.delete(key);
    }
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
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
}
