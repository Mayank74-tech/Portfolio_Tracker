import '../services/local/cache_manager.dart';
import '../services/remote/Yahoo_service.dart';
import '../services/remote/alpha_vantage_service.dart';
import '../services/remote/finnhub_service.dart';
import '../services/remote/fmp_service.dart';

class StockRepository {
  StockRepository({
    FinnhubService? finnhubService,
    AlphaVantageService? alphaVantageService,
    FmpService? fmpService,
    YahooFinanceService? yahooFinanceService,
  })  : _finnhub = finnhubService ?? FinnhubService(),
        _alphaVantage = alphaVantageService ?? AlphaVantageService(),
        _fmp = fmpService ?? FmpService(),
        _yahoo = yahooFinanceService ?? YahooFinanceService();

  final FinnhubService _finnhub;
  final AlphaVantageService _alphaVantage;
  final FmpService _fmp;
  final YahooFinanceService _yahoo;

  static const Duration _quoteTtl = Duration(minutes: 5);
  static const Duration _profileTtl = Duration(days: 7);
  static const Duration _historyTtl = Duration(hours: 24);

  // In StockRepository — add this method
  Future<void> clearProfileCache(String symbol) async {
    await CacheManager.remove('company-profile:${symbol.toUpperCase()}');
    await CacheManager.remove('quote:${symbol.toUpperCase()}');
    await CacheManager.remove('daily-history:${symbol.toUpperCase()}:full');
    await CacheManager.remove('weekly-history:${symbol.toUpperCase()}');
  }

  // ── Quote ──────────────────────────────────────────────────────────────────
  // Yahoo Finance is primary for Indian stocks (free, no key, accurate).
  // Finnhub is used as fallback for US/global symbols.


  Future<Map<String, dynamic>> getQuote(String symbol) {
    return _cachedMap(
      key: 'quote:${symbol.toUpperCase()}',
      ttl: _quoteTtl,
      loader: () async {
        // Try Yahoo first — works for all NSE/BSE stocks
        try {
          final data = await _yahoo.getQuote(symbol);
          if (data.isNotEmpty && _toDouble(data['c']) > 0) return data;
        } catch (_) {}

        // Fallback to Finnhub for US/global symbols
        return _finnhub.getQuote(symbol);
      },
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    if (query.trim().isEmpty) return const [];

    final finnhubResults = await _finnhub.searchSymbols(query);
    if (finnhubResults.isNotEmpty) return finnhubResults;

    return _fmp.searchCompanies(query);
  }

  // ── Company Profile ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCompanyProfile(String symbol) {
    return _cachedMap(
      key: 'company-profile:${symbol.toUpperCase()}',
      ttl: _profileTtl,
      loader: () async {
        // Try Yahoo first
        try {
          final data = await _yahoo.getCompanyProfile(symbol);
          if (data.isNotEmpty) return data;
        } catch (_) {}

        // Try Finnhub
        try {
          final data = await _finnhub.getCompanyProfile(symbol);
          if (data.isNotEmpty) return data;
        } catch (_) {}

        // Fallback to FMP
        return _fmp.getCompanyProfile(symbol);
      },
    );
  }

  // ── Financials ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBasicFinancials(String symbol) {
    return _cachedMap(
      key: 'basic-financials:${symbol.toUpperCase()}',
      ttl: _profileTtl,
      loader: () => _finnhub.getBasicFinancials(symbol),
    );
  }

  Future<List<Map<String, dynamic>>> getRatios(
      String symbol, {
        int limit = 1,
      }) {
    return _cachedList(
      key: 'ratios:${symbol.toUpperCase()}:$limit',
      ttl: _profileTtl,
      loader: () => _fmp.getRatios(symbol, limit: limit),
    );
  }

  Future<List<Map<String, dynamic>>> getIncomeStatement(
      String symbol, {
        int limit = 4,
      }) {
    return _cachedList(
      key: 'income-statement:${symbol.toUpperCase()}:$limit',
      ttl: _profileTtl,
      loader: () => _fmp.getIncomeStatement(symbol, limit: limit),
    );
  }

  // ── Time Series ────────────────────────────────────────────────────────────
  // Yahoo Finance is primary — no rate limits, works for Indian stocks.
  // Alpha Vantage is fallback (25 req/day free limit).

  Future<Map<String, dynamic>> getDailyTimeSeries(
      String symbol, {
        String outputSize = 'compact',
      }) {
    return _cachedMap(
      key: 'daily-history:${symbol.toUpperCase()}:$outputSize',
      ttl: _historyTtl,
      loader: () async {
        // Yahoo Finance — primary
        try {
          final data = await _yahoo.getDailyTimeSeries(
            symbol,
            outputSize: outputSize,
          );
          if (_hasSeriesData(data, 'Time Series (Daily)')) return data;
        } catch (_) {}

        // Alpha Vantage — fallback
        return _alphaVantage.getDailyTimeSeries(
          symbol,
          outputSize: outputSize,
        );
      },
    );
  }

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) {
    return _cachedMap(
      key: 'weekly-history:${symbol.toUpperCase()}',
      ttl: _historyTtl,
      loader: () async {
        // Yahoo Finance — primary
        try {
          final data = await _yahoo.getWeeklyTimeSeries(symbol);
          if (_hasSeriesData(data, 'Weekly Time Series')) return data;
        } catch (_) {}

        // Alpha Vantage — fallback
        return _alphaVantage.getWeeklyTimeSeries(symbol);
      },
    );
  }

  Future<Map<String, dynamic>> getRsi({
    required String symbol,
    String interval = 'daily',
    int timePeriod = 14,
    String seriesType = 'close',
  }) {
    return _cachedMap(
      key: 'rsi:${symbol.toUpperCase()}:$interval:$timePeriod:$seriesType',
      ttl: _historyTtl,
      loader: () => _alphaVantage.getRsi(
        symbol: symbol,
        interval: interval,
        timePeriod: timePeriod,
        seriesType: seriesType,
      ),
    );
  }

  // ── Stock Detail (combined) ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStockDetail(String symbol) async {
    final results = await Future.wait([
      getQuote(symbol),
      getCompanyProfile(symbol),
      getRatios(symbol),
      getDailyTimeSeries(symbol),
    ]);

    return {
      'symbol': symbol.toUpperCase(),
      'quote': results[0],
      'profile': results[1],
      'ratios': results[2],
      'daily_time_series': results[3],
    };
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _cachedMap({
    required String key,
    required Duration ttl,
    required Future<Map<String, dynamic>> Function() loader,
  }) async {
    final cached = await CacheManager.get<Object>(key);
    if (cached is Map) {
      final map = _stringKeyedMap(cached);
      // ── Only return cache if it actually has data ──────────────────────
      if (map.isNotEmpty) return map;
    }

    final data = await loader();

    // ── Only cache successful (non-empty) responses ──────────────────────
    if (data.isNotEmpty) {
      await CacheManager.put(key, data, ttl: ttl);
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> _cachedList({
    required String key,
    required Duration ttl,
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) async {
    final cached = await CacheManager.get<Object>(key);
    if (cached is List) {
      return cached.whereType<Map>().map(_stringKeyedMap).toList();
    }

    final data = await loader();
    await CacheManager.put(key, data, ttl: ttl);
    return data;
  }

  // ── Utils ──────────────────────────────────────────────────────────────────

  static bool _hasSeriesData(Map<String, dynamic> data, String key) {
    final series = data[key];
    return series is Map && series.isNotEmpty;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}