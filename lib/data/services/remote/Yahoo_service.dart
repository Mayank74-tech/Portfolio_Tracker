import 'dart:convert';
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
    if (result is! List || result.isEmpty) {
      return const {};
    }

    final data = result[0] as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>? ?? {};

    final current = _toDouble(meta['regularMarketPrice']);
    final prev = _toDouble(meta['chartPreviousClose'] ?? meta['previousClose']);
    final change = current - prev;
    final changePct = prev == 0 ? 0.0 : (change / prev) * 100;

    return {
      'c': current,
      'pc': prev,
      'd': change,
      'dp': changePct,
      'o': _toDouble(meta['regularMarketOpen']),
      'h': _toDouble(meta['regularMarketDayHigh']),
      'l': _toDouble(meta['regularMarketDayLow']),
      'v': meta['regularMarketVolume'] ?? 0,
    };
  }

  // ── Company Profile ────────────────────────────────────────────────────────

  /// Returns a profile map compatible with Finnhub profile keys:
  /// name, exchange, country, finnhubIndustry, weburl, ipo, marketCapitalization
  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    final ticker = _toYahooTicker(symbol);
    final url = Uri.https(
      'query1.finance.yahoo.com',
      '/v10/finance/quoteSummary/$ticker',
      {'modules': 'assetProfile,summaryDetail,price'},
    );

    final response = await _client.get(url, headers: _headers);
    _checkStatus(response, 'Yahoo Finance profile');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['quoteSummary']?['result'];
    if (result is! List || result.isEmpty) return const {};

    final data = result[0] as Map<String, dynamic>;
    final asset = data['assetProfile'] as Map<String, dynamic>? ?? {};
    final price = data['price'] as Map<String, dynamic>? ?? {};
    final summary = data['summaryDetail'] as Map<String, dynamic>? ?? {};

    final marketCap = _toDouble(
      price['marketCap']?['raw'] ?? summary['marketCap']?['raw'],
    );

    return {
      'name': price['longName'] ?? price['shortName'] ?? symbol,
      'exchange': price['exchangeName'] ?? 'NSE',
      'country': asset['country'] ?? 'India',
      'finnhubIndustry': asset['industry'] ?? asset['sector'] ?? 'Unknown',
      'weburl': asset['website'] ?? '',
      'ipo': asset['foundedYear']?.toString() ?? '',
      // Yahoo gives full market cap in INR; Finnhub stores in millions USD
      // We store raw INR value and format it ourselves
      'marketCapitalization': marketCap,
      'currency': price['currency'] ?? 'INR',
      'sector': asset['sector'] ?? '',
    };
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