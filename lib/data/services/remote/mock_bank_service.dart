import 'dart:convert';
import 'package:http/http.dart' as http;

/// Mock bank service that talks to local mock_bank_api server.
///
/// Run server with:
///   cd mock_bank_api
///   dart run bin/server.dart
class MockBankService {
  MockBankService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ✅ Use 10.0.2.2 for Android emulator → localhost
  // For real device, replace with your computer's IP (e.g. 192.168.1.5)
  static const String _baseUrl = 'http://172.20.10.2:8080';

  static List<Map<String, String>> get availableBanks => const [
    {
      'id': 'hdfc',
      'name': 'HDFC Bank',
      'logo': '🏦',
      'ifscPrefix': 'HDFC',
    },
    {
      'id': 'sbi',
      'name': 'State Bank of India',
      'logo': '🏛',
      'ifscPrefix': 'SBIN',
    },
    {
      'id': 'icici',
      'name': 'ICICI Bank',
      'logo': '💳',
      'ifscPrefix': 'ICIC',
    },
    {
      'id': 'axis',
      'name': 'Axis Bank',
      'logo': '💰',
      'ifscPrefix': 'UTIB',
    },
    {
      'id': 'kotak',
      'name': 'Kotak Mahindra',
      'logo': '🏪',
      'ifscPrefix': 'KKBK',
    },
    {
      'id': 'pnb',
      'name': 'Punjab National Bank',
      'logo': '🏤',
      'ifscPrefix': 'PUNB',
    },
  ];

  // ── Health check ────────────────────────────────────────────────────────

  Future<bool> isServerRunning() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Get all banks from server ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/banks'));
      _checkStatus(response);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final banks = body['banks'] as List? ?? [];
      return banks.whereType<Map>().map(_stringKeyedMap).toList();
    } catch (_) {
      // Fallback to local list if server is down
      return availableBanks
          .map((b) => Map<String, dynamic>.from(b))
          .toList();
    }
  }

  // ── STEP 1: Initiate Connection ─────────────────────────────────────────
  /// Validates bank, account number, and IFSC code.
  /// Returns sessionId and OTP (demo only).
  Future<Map<String, dynamic>> initiateConnection({
    required String bankId,
    required String accountNumber,
    required String ifsc,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/connect/initiate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bankId': bankId,
        'accountNumber': accountNumber,
        'ifsc': ifsc.toUpperCase(),
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to initiate connection');
    }

    return _stringKeyedMap(body);
  }

  // ── STEP 2: Verify OTP ──────────────────────────────────────────────────
  /// Verifies the OTP and creates the bank account.
  Future<Map<String, dynamic>> verifyOtp({
    required String sessionId,
    required String otp,
    required String accountType,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/connect/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
        'otp': otp,
        'accountType': accountType,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'OTP verification failed');
    }

    return _stringKeyedMap(body['account'] as Map);
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────

  Future<String> resendOtp(String sessionId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/connect/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to resend OTP');
    }

    return body['otp']?.toString() ?? '';
  }

  // ── DEPRECATED: Old single-step connect (kept for backward compat) ──────
  /// @deprecated Use [initiateConnection] + [verifyOtp] instead.
  Future<Map<String, dynamic>> connectBank({
    required String bankId,
    required String accountType,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/connect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bankId': bankId,
        'accountType': accountType,
      }),
    );

    _checkStatus(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _stringKeyedMap(body['account'] as Map);
  }

  // ── Get transactions ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions(String accountId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/accounts/$accountId/transactions'),
    );

    _checkStatus(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final txs = body['transactions'] as List? ?? [];
    return txs.whereType<Map>().map(_stringKeyedMap).toList();
  }

  // ── Get balance (refresh) ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getBalance(String accountId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/accounts/$accountId/balance'),
    );

    _checkStatus(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _stringKeyedMap(body);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Bank API request failed: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          message = body['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  // ── Utility: Validate IFSC code format ──────────────────────────────────
  /// Returns true if [ifsc] matches Indian IFSC format: 4 letters + 0 + 6 alphanumeric
  static bool isValidIfsc(String ifsc) {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.toUpperCase());
  }

  // ── Utility: Validate account number ────────────────────────────────────
  /// Returns true if [accountNumber] is 9-18 digits.
  static bool isValidAccountNumber(String accountNumber) {
    return RegExp(r'^\d{9,18}$').hasMatch(accountNumber);
  }

  // ── Utility: Get bank by IFSC ───────────────────────────────────────────
  /// Auto-detect bank from IFSC code prefix.
  static Map<String, String>? getBankByIfsc(String ifsc) {
    if (ifsc.length < 4) return null;
    final prefix = ifsc.substring(0, 4).toUpperCase();
    try {
      return availableBanks.firstWhere(
            (b) => b['ifscPrefix'] == prefix,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    _client.close();
  }
}