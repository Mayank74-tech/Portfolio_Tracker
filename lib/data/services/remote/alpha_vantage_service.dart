import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_keys.dart';

/// Alpha Vantage free tier limits:
/// - 25 requests per day
/// - 1 request per second (burst)
///
/// This service enforces both limits to prevent burning the daily quota.
class AlphaVantageService {
  AlphaVantageService({http.Client? client})
      : _client = client ?? http.Client();

  static final Uri _baseUri = Uri.https('www.alphavantage.co', '/query');
  final http.Client _client;

  // ✅ Rate limiter: enforces 1 req/sec gap between calls
  static DateTime _lastCallTime = DateTime(2000);
  static const _minGap = Duration(milliseconds: 1100); // 1.1s to be safe

  // ✅ Daily request counter: tracks usage against 25 req/day limit
  static int _dailyRequestCount = 0;
  static DateTime _dailyResetDate = DateTime.now();
  static const _dailyLimit = 22; // leave 3 buffer

  Future<Map<String, dynamic>> getDailyTimeSeries(
      String symbol, {
        String outputSize = 'compact',
      }) {
    return _query({
      'function': 'TIME_SERIES_DAILY',
      'symbol': symbol.toUpperCase(),
      'outputsize': outputSize,
    });
  }

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) {
    return _query({
      'function': 'TIME_SERIES_WEEKLY',
      'symbol': symbol.toUpperCase(),
    });
  }

  Future<Map<String, dynamic>> getRsi({
    required String symbol,
    String interval = 'daily',
    int timePeriod = 14,
    String seriesType = 'close',
  }) {
    return _query({
      'function': 'RSI',
      'symbol': symbol.toUpperCase(),
      'interval': interval,
      'time_period': timePeriod,
      'series_type': seriesType,
    });
  }

  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final data = await _query({
      'function': 'SYMBOL_SEARCH',
      'keywords': query.trim(),
    });

    final matches = data['bestMatches'];
    if (matches is List) {
      return matches.whereType<Map>().map(_stringKeyedMap).toList();
    }
    return const [];
  }

  // ── Core query with rate limiting ─────────────────────────────────────────

  Future<Map<String, dynamic>> _query(
      Map<String, dynamic> parameters,
      ) async {
    final key = ApiKeys.alphaVantage;
    if (key.isEmpty) {
      throw StateError('Missing ALPHA_VANTAGE_API_KEY in .env');
    }

    // ✅ Check daily limit BEFORE making request
    _resetDailyCounterIfNewDay();
    if (_dailyRequestCount >= _dailyLimit) {
      throw Exception(
        'Alpha Vantage daily limit reached ($_dailyLimit/day). '
            'Will reset tomorrow. Using cached data only.',
      );
    }

    // ✅ Enforce 1 request/second rate limit
    await _throttle();

    final uri = _baseUri.replace(
      queryParameters: {
        ...parameters.map(
              (k, v) => MapEntry(k, v.toString()),
        ),
        'apikey': key,
      },
    );

    final response = await _client.get(uri);

    // ✅ Increment counter only on actual network call
    _dailyRequestCount++;
    _lastCallTime = DateTime.now();

    final decoded = _decodeResponse(response);
    if (decoded is! Map) {
      throw const FormatException(
        'Alpha Vantage returned an unexpected response.',
      );
    }

    final data = _stringKeyedMap(decoded);

    // ✅ Detect rate limit message and throw cleanly
    final error =
        data['Error Message'] ?? data['Note'] ?? data['Information'];
    if (error != null) {
      final msg = error.toString();
      // If it's a rate limit message, mark as limit reached
      if (msg.contains('premium') ||
          msg.contains('rate limit') ||
          msg.contains('25 requests')) {
        _dailyRequestCount = _dailyLimit; // block further calls today
        throw Exception('Alpha Vantage rate limit hit. Fallback to Yahoo.');
      }
      throw Exception('Alpha Vantage error: $msg');
    }

    return data;
  }

  // ✅ Wait until 1.1s has passed since last call
  Future<void> _throttle() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastCallTime);
    if (elapsed < _minGap) {
      await Future.delayed(_minGap - elapsed);
    }
  }

  // ✅ Reset daily counter if it's a new calendar day
  static void _resetDailyCounterIfNewDay() {
    final now = DateTime.now();
    if (now.day != _dailyResetDate.day ||
        now.month != _dailyResetDate.month ||
        now.year != _dailyResetDate.year) {
      _dailyRequestCount = 0;
      _dailyResetDate = now;
    }
  }

  // ✅ Expose remaining calls for debugging
  static int get remainingDailyCalls =>
      (_dailyLimit - _dailyRequestCount).clamp(0, _dailyLimit);

  static bool get isDailyLimitReached =>
      _dailyRequestCount >= _dailyLimit;

  // ── Utils ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));

  static dynamic _decodeResponse(http.Response response) {
    final decoded =
    response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? decoded['Error Message'] ??
        decoded['message'] ??
        response.reasonPhrase
        : response.reasonPhrase;
    throw Exception('Alpha Vantage request failed: $message');
  }
}