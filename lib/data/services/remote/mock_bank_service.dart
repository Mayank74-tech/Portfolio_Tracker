// lib/data/services/remote/mock_bank_service.dart
// Calls local mock_bank_api server.

import 'dart:convert';
import '../../../data/models/finance/transaction_model.dart';
import '../../../data/models/finance/bank_account_model.dart';
import 'package:http/http.dart' as http;

class MockBankService {
  MockBankService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:8080';

  final String _baseUrl;

  // ── Mock banks to connect ──────────────────────────────────────────────────

  static const List<Map<String, String>> availableBanks = [
    {'id': 'sbi',    'name': 'State Bank of India',  'logo': '🏦'},
    {'id': 'hdfc',   'name': 'HDFC Bank',            'logo': '🏛'},
    {'id': 'icici',  'name': 'ICICI Bank',           'logo': '🏢'},
    {'id': 'axis',   'name': 'Axis Bank',            'logo': '🏗'},
    {'id': 'kotak',  'name': 'Kotak Mahindra Bank',  'logo': '🏠'},
    {'id': 'paytm',  'name': 'Paytm Payments Bank',  'logo': '💙'},
    {'id': 'gpay',   'name': 'Google Pay (UPI)',      'logo': '🟢'},
    {'id': 'phonepe','name': 'PhonePe',               'logo': '💜'},
  ];

  // ── Connect account (mock auth flow) ──────────────────────────────────────

  Future<BankAccountModel> connectAccount({
    required String bankId,
    required String accountType,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/connect'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'bankId': bankId,
        'accountType': accountType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Bank connect failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final account = data['account'] as Map<String, dynamic>? ?? {};

    return BankAccountModel(
      id: account['id']?.toString() ?? '',
      bankName: account['bankName']?.toString() ?? 'Unknown Bank',
      accountType: account['accountType']?.toString() ?? accountType,
      maskedNumber: account['maskedNumber']?.toString() ?? 'XXXX 0000',
      balance: _toDouble(account['balance']),
      connectedAt: DateTime.tryParse(
            account['connectedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      lastSynced: DateTime.tryParse(
            account['lastSynced']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  // ── Fetch transactions (mock data) ────────────────────────────────────────

  Future<List<TransactionModel>> fetchTransactions({
    required String accountId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/accounts/$accountId/transactions'),
      headers: const {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Fetch transactions failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = (data['transactions'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final filtered = rawList.where((item) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      if (date == null) return false;
      return !date.isBefore(fromDate) && !date.isAfter(toDate);
    });

    final transactions = filtered.map((item) {
      return TransactionModel(
        id: item['id']?.toString() ?? '',
        accountId: item['accountId']?.toString() ?? accountId,
        amount: _toDouble(item['amount']),
        type: item['type']?.toString() ?? 'debit',
        category: item['category']?.toString() ?? 'other',
        description: item['description']?.toString() ?? '',
        merchantName: item['merchantName']?.toString() ?? '',
        date: DateTime.tryParse(item['date']?.toString() ?? '') ??
            DateTime.now(),
        balanceAfter: _toDouble(item['balanceAfter']),
      );
    }).toList();

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  // ── Sync account balance ───────────────────────────────────────────────────

  Future<double> syncBalance(String accountId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/accounts/$accountId/balance'),
      headers: const {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Sync balance failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _toDouble(data['balance']);
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}
