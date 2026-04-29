import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

/// Fetches stock data from Yahoo Finance (no API key required).
///
/// Indian stocks use the .NS suffix (NSE) e.g. RELIANCE.NS, SBIN.NS
/// BSE stocks use .BO suffix e.g. RELIANCE.BO
class YahooFinanceService {
  YahooFinanceService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
  };

  // ── Quote ──────────────────────────────────────────────────────────────────

  /// Returns a quote map compatible with Finnhub quote keys:
  /// c = current price, pc = previous close, d = change, dp = change %
  /// o = open, h = high, l = low
  Future<Map<String, dynamic>> getQuote(String symbol) async {
    final ticker = _toYahooTicker(symbol);
    final url = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      {'interval': '1d', 'range': '1d'},
    );

    final response = await _client.get(url, headers: _headers);
    _checkStatus(response, 'Yahoo Finance quote');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['chart']?['result'];
    if (result is! List || result.isEmpty) return const {};

    final data   = result[0] as Map<String, dynamic>;
    final meta   = data['meta'] as Map<String, dynamic>? ?? {};

    debugPrint('Quote meta keys: ${meta.keys.toList()}');
    debugPrint('Quote meta sample: ${meta.toString().substring(0, meta.toString().length.clamp(0, 400))}');

    final current = _toDouble(meta['regularMarketPrice']);

    // previousClose: try multiple keys Yahoo uses
    final prev = _toDouble(
      meta['chartPreviousClose'] ??
          meta['previousClose'] ??
          meta['regularMarketPreviousClose'],
    );

    final change    = current - prev;
    final changePct = prev == 0 ? 0.0 : (change / prev) * 100;

    return {
      'c':  current,
      'pc': prev,
      'd':  change,
      'dp': changePct,
      'o':  _toDouble(meta['regularMarketOpen']),
      'h':  _toDouble(meta['regularMarketDayHigh']),
      'l':  _toDouble(meta['regularMarketDayLow']),
      'v':  _toDouble(meta['regularMarketVolume']),
      't':  meta['regularMarketTime'] ?? 0,
    };
  }
  // ── Company Profile ────────────────────────────────────────────────────────
  /// Returns a profile map using the /v8/finance/chart endpoint
  /// (no crumb/cookie required — same endpoint used for quotes).
  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    final ticker = _toYahooTicker(symbol);

    // v8/chart works without crumb — extract meta for profile data
    final url = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      {
        'interval': '1d',
        'range': '1d',
        'includePrePost': 'false',
      },
    );

    debugPrint('Yahoo profile (v8) URL: $url');

    final response = await _client.get(url, headers: _headers);

    debugPrint('Yahoo profile (v8) status: ${response.statusCode}');

    _checkStatus(response, 'Yahoo Finance profile (v8)');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['chart']?['result'];

    if (result is! List || result.isEmpty) {
      debugPrint('Yahoo profile (v8): empty result');
      return const {};
    }

    final data = result[0] as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>? ?? {};

    debugPrint('Yahoo profile meta keys: ${meta.keys.toList()}');
    debugPrint('Yahoo profile meta: $meta');

    // meta contains: symbol, exchangeName, fullExchangeName, currency,
    // instrumentType, longName, shortName, regularMarketPrice,
    // marketCap (sometimes), timezone, etc.

    final longName = _nonEmpty(meta['longName']?.toString());
    final shortName = _nonEmpty(meta['shortName']?.toString());
    final exchangeName = _nonEmpty(meta['exchangeName']?.toString());
    final fullExchangeName = _nonEmpty(meta['fullExchangeName']?.toString());
    final currency = _nonEmpty(meta['currency']?.toString());
    final instrumentType = _nonEmpty(meta['instrumentType']?.toString());

    // Market cap is not always in v8 meta, but try anyway
    final marketCap = _toDouble(meta['marketCap']);

    // Derive country and exchange from known exchange codes
    final exchange = fullExchangeName ?? exchangeName ?? 'NSE';
    final country = _countryFromExchange(exchange);
    final sector = _sectorFromInstrumentType(instrumentType);

    return {
      'name': longName ?? shortName ?? symbol,
      'exchange': exchange,
      'country': country,
      'finnhubIndustry': sector,
      'weburl': '',
      'ipo': '',
      'marketCapitalization': marketCap,
      'currency': currency ?? 'INR',
      'sector': sector,
      'symbol': meta['symbol'] ?? ticker,
      'timezone': meta['exchangeTimezoneName'] ?? '',
    };
  }

  /// Maps known exchange names to countries.
  static String _countryFromExchange(String exchange) {
    const map = {
      'NSE': 'India',
      'BSE': 'India',
      'NMS': 'USA',
      'NGM': 'USA',
      'NYQ': 'USA',
      'LSE': 'UK',
      'TYO': 'Japan',
      'HKG': 'Hong Kong',
      'SHH': 'China',
      'SHZ': 'China',
    };
    for (final entry in map.entries) {
      if (exchange.toUpperCase().contains(entry.key)) return entry.value;
    }
    return 'Unknown';
  }

  /// Maps Yahoo instrument type to a readable sector string.
  static String _sectorFromInstrumentType(String? type) {
    if (type == null) return 'Equity';
    switch (type.toUpperCase()) {
      case 'EQUITY': return 'Equity';
      case 'ETF':    return 'ETF';
      case 'MUTUALFUND': return 'Mutual Fund';
      case 'FUTURE': return 'Futures';
      case 'INDEX':  return 'Index';
      default:       return type;
    }
  }

  /// Returns the string if non-null and non-empty, otherwise null.
  static String? _nonEmpty(Object? value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? null : s;
  }
  // ── Daily Time Series ──────────────────────────────────────────────────────

  /// Returns data in Alpha Vantage format so existing chart code works:
  /// { "Time Series (Daily)": { "2024-01-01": { "4. close": "100.0" } } }
  Future<Map<String, dynamic>> getDailyTimeSeries(
      String symbol, {
        String outputSize = 'compact',
      }) async {
    final ticker = _toYahooTicker(symbol);
    // compact = 1 month, full = 1 year
    final range = outputSize == 'full' ? '1y' : '1mo';

    final url = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      {'interval': '1d', 'range': range},
    );

    final response = await _client.get(url, headers: _headers);
    _checkStatus(response, 'Yahoo Finance daily series');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['chart']?['result'];
    if (result is! List || result.isEmpty) return const {};

    final data = result[0] as Map<String, dynamic>;
    final timestamps = data['timestamp'] as List? ?? [];
    final closes = (data['indicators']?['quote'] as List?)?.firstOrNull
    as Map<String, dynamic>?;
    final closePrices = closes?['close'] as List? ?? [];

    final series = <String, dynamic>{};
    for (int i = 0; i < timestamps.length; i++) {
      if (i >= closePrices.length) break;
      final price = closePrices[i];
      if (price == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(
        (timestamps[i] as int) * 1000,
      );
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      series[key] = {'4. close': price.toString()};
    }

    return {'Time Series (Daily)': series};
  }

  // ── Weekly Time Series ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) async {
    final ticker = _toYahooTicker(symbol);
    final url = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$ticker',
      {'interval': '1wk', 'range': '1y'},
    );

    final response = await _client.get(url, headers: _headers);
    _checkStatus(response, 'Yahoo Finance weekly series');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['chart']?['result'];
    if (result is! List || result.isEmpty) return const {};

    final data = result[0] as Map<String, dynamic>;
    final timestamps = data['timestamp'] as List? ?? [];
    final closes = (data['indicators']?['quote'] as List?)?.firstOrNull
    as Map<String, dynamic>?;
    final closePrices = closes?['close'] as List? ?? [];

    final series = <String, dynamic>{};
    for (int i = 0; i < timestamps.length; i++) {
      if (i >= closePrices.length) break;
      final price = closePrices[i];
      if (price == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(
        (timestamps[i] as int) * 1000,
      );
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      series[key] = {'4. close': price.toString()};
    }

    return {'Weekly Time Series': series};
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a plain NSE symbol to Yahoo Finance ticker.
  /// RELIANCE → RELIANCE.NS, SBIN → SBIN.NS
  /// Already suffixed symbols are left as-is.
  static String _toYahooTicker(String symbol) {
    final upper = symbol.toUpperCase().trim();
    if (upper.contains('.')) return upper; // already has suffix
    return '$upper.NS';
  }

  void _checkStatus(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$context failed with status ${response.statusCode}',
      );
    }
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}