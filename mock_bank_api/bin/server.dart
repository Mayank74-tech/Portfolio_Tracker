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
    {'id': 'hdfc', 'name': 'HDFC Bank', 'logo': '🏦', 'ifscPrefix': 'HDFC'},
    {'id': 'sbi', 'name': 'State Bank of India', 'logo': '🏛', 'ifscPrefix': 'SBIN'},
    {'id': 'icici', 'name': 'ICICI Bank', 'logo': '💳', 'ifscPrefix': 'ICIC'},
    {'id': 'axis', 'name': 'Axis Bank', 'logo': '💰', 'ifscPrefix': 'UTIB'},
    {'id': 'kotak', 'name': 'Kotak Mahindra', 'logo': '🏪', 'ifscPrefix': 'KKBK'},
    {'id': 'pnb', 'name': 'Punjab National Bank', 'logo': '🏤', 'ifscPrefix': 'PUNB'},
  ];

  // Stores: accountId -> account data
  final accounts = <String, Map<String, dynamic>>{};

  // Stores: sessionId -> { bankId, accountNumber, ifsc, otp, expiresAt }
  final pendingSessions = <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> makeTransactions(String accountId) {
    final categories = <String>[
      'food', 'transport', 'shopping', 'investment',
      'utilities', 'entertainment', 'health', 'other',
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

  Map<String, String> _json() => {'content-type': 'application/json'};

  // ── Health ────────────────────────────────────────────────────────────────
  app.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'ok', 'service': 'mock_bank_api'}),
      headers: _json(),
    );
  });

  // ── List banks ────────────────────────────────────────────────────────────
  app.get('/banks', (Request req) {
    return Response.ok(
      jsonEncode({'banks': banks}),
      headers: _json(),
    );
  });

  // ── STEP 1: Initiate connection (account + IFSC validation) ──────────────
  app.post('/connect/initiate', (Request req) async {
    try {
      final payload =
      jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final bankId = payload['bankId']?.toString() ?? '';
      final accountNumber = payload['accountNumber']?.toString() ?? '';
      final ifsc = payload['ifsc']?.toString().toUpperCase() ?? '';

      // Validate bank
      final bank = banks.firstWhere(
            (b) => b['id'] == bankId,
        orElse: () => {},
      );
      if (bank.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid bank selected'}),
            headers: _json());
      }

      // Validate account number (must be 9-18 digits)
      if (accountNumber.length < 9 || accountNumber.length > 18) {
        return Response(400,
            body: jsonEncode({
              'error': 'Account number must be between 9 and 18 digits'
            }),
            headers: _json());
      }
      if (!RegExp(r'^\d+$').hasMatch(accountNumber)) {
        return Response(400,
            body: jsonEncode({'error': 'Account number must be numeric'}),
            headers: _json());
      }

      // Validate IFSC (4 letters + 0 + 6 alphanumeric = 11 chars)
      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
        return Response(400,
            body: jsonEncode({
              'error': 'Invalid IFSC code. Format: ABCD0XXXXXX'
            }),
            headers: _json());
      }

      // Check IFSC matches selected bank
      final expectedPrefix = bank['ifscPrefix']!;
      if (!ifsc.startsWith(expectedPrefix)) {
        return Response(400,
            body: jsonEncode({
              'error': 'IFSC code does not match ${bank['name']}. '
                  'Expected prefix: $expectedPrefix'
            }),
            headers: _json());
      }

      // Generate OTP and session
      final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      final otp = (100000 + rng.nextInt(899999)).toString();

      pendingSessions[sessionId] = {
        'bankId': bankId,
        'bankName': bank['name'],
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        'otp': otp,
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      };

      // Mock: return OTP in response (in real apps it's sent via SMS)
      return Response.ok(
        jsonEncode({
          'sessionId': sessionId,
          'message':
          'OTP sent to mobile linked with account ending in ${accountNumber.substring(accountNumber.length - 4)}',
          'otp': otp, // ⚠️ Only for demo - real apps don't return this
          'expiresIn': 300,
        }),
        headers: _json(),
      );
    } catch (e) {
      return Response(500,
          body: jsonEncode({'error': 'Server error: $e'}),
          headers: _json());
    }
  });

  // ── STEP 2: Verify OTP and create account ────────────────────────────────
  app.post('/connect/verify', (Request req) async {
    try {
      final payload =
      jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final sessionId = payload['sessionId']?.toString() ?? '';
      final otp = payload['otp']?.toString() ?? '';
      final accountType =
          payload['accountType']?.toString() ?? 'savings';

      final session = pendingSessions[sessionId];
      if (session == null) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid or expired session'}),
            headers: _json());
      }

      // Check expiry
      final expiresAt = DateTime.parse(session['expiresAt'].toString());
      if (DateTime.now().isAfter(expiresAt)) {
        pendingSessions.remove(sessionId);
        return Response(400,
            body: jsonEncode({'error': 'OTP expired. Please try again.'}),
            headers: _json());
      }

      // Verify OTP
      if (session['otp'] != otp) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid OTP'}),
            headers: _json());
      }

      // Create account
      final accNum = session['accountNumber'].toString();
      final accountId = 'acc_${DateTime.now().millisecondsSinceEpoch}';

      final account = <String, dynamic>{
        'id': accountId,
        'bankName': session['bankName'],
        'bankId': session['bankId'],
        'accountType': accountType,
        'accountNumber': accNum,
        'ifsc': session['ifsc'],
        'maskedNumber':
        'XXXX XXXX ${accNum.substring(accNum.length - 4)}',
        'balance': (40000 + rng.nextInt(1000000)).toDouble(),
        'connectedAt': DateTime.now().toIso8601String(),
        'lastSynced': DateTime.now().toIso8601String(),
      };

      accounts[accountId] = account;
      pendingSessions.remove(sessionId);

      return Response.ok(
        jsonEncode({'account': account}),
        headers: _json(),
      );
    } catch (e) {
      return Response(500,
          body: jsonEncode({'error': 'Server error: $e'}),
          headers: _json());
    }
  });

  // ── Resend OTP ────────────────────────────────────────────────────────────
  app.post('/connect/resend-otp', (Request req) async {
    try {
      final payload =
      jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final sessionId = payload['sessionId']?.toString() ?? '';

      final session = pendingSessions[sessionId];
      if (session == null) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid session'}),
            headers: _json());
      }

      final newOtp = (100000 + rng.nextInt(899999)).toString();
      session['otp'] = newOtp;
      session['expiresAt'] = DateTime.now()
          .add(const Duration(minutes: 5))
          .toIso8601String();

      return Response.ok(
        jsonEncode({
          'message': 'New OTP sent',
          'otp': newOtp, // demo only
          'expiresIn': 300,
        }),
        headers: _json(),
      );
    } catch (e) {
      return Response(500,
          body: jsonEncode({'error': 'Server error: $e'}),
          headers: _json());
    }
  });

  // ── Transactions ──────────────────────────────────────────────────────────
  app.get('/accounts/<accountId>/transactions',
          (Request req, String accountId) {
        if (!accounts.containsKey(accountId)) {
          return Response.notFound(
            jsonEncode({'error': 'Account not found'}),
            headers: _json(),
          );
        }
        return Response.ok(
          jsonEncode({'transactions': makeTransactions(accountId)}),
          headers: _json(),
        );
      });

  // ── Balance ───────────────────────────────────────────────────────────────
  app.get('/accounts/<accountId>/balance', (Request req, String accountId) {
    final account = accounts[accountId];
    if (account == null) {
      return Response.notFound(
        jsonEncode({'error': 'Account not found'}),
        headers: _json(),
      );
    }

    account['balance'] = ((account['balance'] as double) +
        (rng.nextDouble() * 2000 - 1000))
        .clamp(0, double.infinity);
    account['lastSynced'] = DateTime.now().toIso8601String();

    return Response.ok(
      jsonEncode({
        'accountId': accountId,
        'balance': account['balance'],
        'lastSynced': account['lastSynced'],
      }),
      headers: _json(),
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Mock Bank API running on http://${server.address.host}:${server.port}');
}