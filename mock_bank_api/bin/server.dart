import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final app = Router();
  final rng = Random();

  final banks = <Map<String, String>>[
    {'id': 'hdfc', 'name': 'HDFC Bank', 'logo': '🏦'},
    {'id': 'sbi', 'name': 'State Bank of India', 'logo': '🏛'},
    {'id': 'icici', 'name': 'ICICI Bank', 'logo': '💳'},
    {'id': 'axis', 'name': 'Axis Bank', 'logo': '💰'},
  ];

  final accounts = <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> makeTransactions(String accountId) {
    final categories = <String>[
      'food',
      'transport',
      'shopping',
      'investment',
      'utilities',
      'entertainment',
      'health',
      'other',
    ];

    final now = DateTime.now();
    final txs = <Map<String, dynamic>>[];

    for (var i = 0; i < 24; i++) {
      final isCredit = i % 6 == 0;
      final amount = isCredit
          ? (1500 + rng.nextInt(30000)).toDouble()
          : (80 + rng.nextInt(8000)).toDouble();
      txs.add({
        'id': '${accountId}_tx_$i',
        'accountId': accountId,
        'amount': amount,
        'type': isCredit ? 'credit' : 'debit',
        'category': categories[rng.nextInt(categories.length)],
        'description': isCredit ? 'Salary/Refund' : 'Card spend',
        'merchantName': isCredit ? 'Employer' : 'Merchant ${i + 1}',
        'date': now.subtract(Duration(days: i)).toIso8601String(),
        'balanceAfter': (50000 + rng.nextInt(900000)).toDouble(),
      });
    }

    return txs;
  }

  app.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'mock_bank_api'}),
      headers: {'content-type': 'application/json'},
    );
  });

  app.get('/banks', (Request req) {
    return Response.ok(
      jsonEncode({'banks': banks}),
      headers: {'content-type': 'application/json'},
    );
  });

  app.post('/connect', (Request req) async {
    final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final bankId = payload['bankId']?.toString() ?? 'hdfc';
    final accountType = payload['accountType']?.toString() ?? 'savings';

    final bank = banks.firstWhere(
      (b) => b['id'] == bankId,
      orElse: () => banks.first,
    );

    final accountId = 'acc_${DateTime.now().millisecondsSinceEpoch}';
    final account = <String, dynamic>{
      'id': accountId,
      'bankName': bank['name'],
      'accountType': accountType,
      'maskedNumber': 'XXXX ${1000 + rng.nextInt(8999)}',
      'balance': (40000 + rng.nextInt(1000000)).toDouble(),
      'connectedAt': DateTime.now().toIso8601String(),
      'lastSynced': DateTime.now().toIso8601String(),
    };

    accounts[accountId] = account;

    return Response.ok(
      jsonEncode({'account': account}),
      headers: {'content-type': 'application/json'},
    );
  });

  app.get('/accounts/<accountId>/transactions', (Request req, String accountId) {
    if (!accounts.containsKey(accountId)) {
      return Response.notFound(
        jsonEncode({'error': 'Account not found'}),
        headers: {'content-type': 'application/json'},
      );
    }
    final txs = makeTransactions(accountId);
    return Response.ok(
      jsonEncode({'transactions': txs}),
      headers: {'content-type': 'application/json'},
    );
  });

  app.get('/accounts/<accountId>/balance', (Request req, String accountId) {
    final account = accounts[accountId];
    if (account == null) {
      return Response.notFound(
        jsonEncode({'error': 'Account not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    account['balance'] = ((account['balance'] as double) + (rng.nextDouble() * 2000 - 1000))
        .clamp(0, double.infinity);
    account['lastSynced'] = DateTime.now().toIso8601String();

    return Response.ok(
      jsonEncode({
        'accountId': accountId,
        'balance': account['balance'],
        'lastSynced': account['lastSynced'],
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Mock Bank API running on http://${server.address.host}:${server.port}');
}

