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

  // ✅ Longer TTLs = fewer API calls burned per day
  static const Duration _quoteTtl     = Duration(minutes: 10);
  static const Duration _profileTtl   = Duration(days: 30);
  static const Duration _historyTtl   = Duration(hours: 48);
  static const Duration _avFallbackTtl = Duration(days: 7);

  Future<void> clearProfileCache(String symbol) async {
    final s = symbol.toUpperCase();
    await CacheManager.remove('company-profile:$s');
    await CacheManager.remove('quote:$s');
    await CacheManager.remove('daily-history:$s:full');
    await CacheManager.remove('daily-history:$s:compact');
    await CacheManager.remove('weekly-history:$s');
  }

  // ── Quote ─────────────────────────────────────────────────────────────────
  // Yahoo = primary (unlimited, free, accurate for India)
  // Finnhub = fallback (US/global)

  Future<Map<String, dynamic>> getQuote(String symbol) {
    return _cachedMap(
      key: 'quote:${symbol.toUpperCase()}',
      ttl: _quoteTtl,
      loader: () async {
        try {
          final data = await _yahoo.getQuote(symbol);
          if (data.isNotEmpty && _toDouble(data['c']) > 0) return data;
        } catch (_) {}
        return _finnhub.getQuote(symbol);
      },
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    if (query.trim().isEmpty) return const [];
    final results = await _finnhub.searchSymbols(query);
    if (results.isNotEmpty) return results;
    return _fmp.searchCompanies(query);
  }

  // ── Company Profile ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCompanyProfile(String symbol) {
    return _cachedMap(
      key: 'company-profile:${symbol.toUpperCase()}',
      ttl: _profileTtl,
      loader: () async {
        try {
          final data = await _yahoo.getCompanyProfile(symbol);
          if (data.isNotEmpty) return data;
        } catch (_) {}
        try {
          final data = await _finnhub.getCompanyProfile(symbol);
          if (data.isNotEmpty) return data;
        } catch (_) {}
        return _fmp.getCompanyProfile(symbol);
      },
    );
  }

  // ── Financials ────────────────────────────────────────────────────────────

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

  // ── Daily Time Series ─────────────────────────────────────────────────────
  // Strategy:
  // 1. Try Yahoo (unlimited, primary)
  // 2. Only call Alpha Vantage if Yahoo fails AND daily limit not reached
  // 3. Cache AV results for 7 days to preserve quota

  Future<Map<String, dynamic>> getDailyTimeSeries(
      String symbol, {
        String outputSize = 'compact',
      }) {
    return _cachedMap(
      key: 'daily-history:${symbol.toUpperCase()}:$outputSize',
      ttl: _historyTtl,
      loader: () async {
        // ✅ Yahoo first - no rate limits
        try {
          final data = await _yahoo.getDailyTimeSeries(
            symbol,
            outputSize: outputSize,
          );
          if (_hasSeriesData(data, 'Time Series (Daily)')) return data;
        } catch (_) {}

        // ✅ Alpha Vantage fallback ONLY if limit not reached
        if (AlphaVantageService.isDailyLimitReached) {
          return const {}; // return empty - caller handles gracefully
        }

        try {
          final data = await _alphaVantage.getDailyTimeSeries(
            symbol,
            outputSize: outputSize,
          );
          // ✅ Cache AV results longer to preserve quota
          if (data.isNotEmpty) {
            await CacheManager.put(
              'daily-history:${symbol.toUpperCase()}:$outputSize',
              data,
              ttl: _avFallbackTtl,
            );
          }
          return data;
        } catch (_) {
          return const {};
        }
      },
    );
  }

  // ── Weekly Time Series ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) {
    return _cachedMap(
      key: 'weekly-history:${symbol.toUpperCase()}',
      ttl: _historyTtl,
      loader: () async {
        // ✅ Yahoo first
        try {
          final data = await _yahoo.getWeeklyTimeSeries(symbol);
          if (_hasSeriesData(data, 'Weekly Time Series')) return data;
        } catch (_) {}

        // ✅ Alpha Vantage fallback ONLY if limit not reached
        if (AlphaVantageService.isDailyLimitReached) {
          return const {};
        }

        try {
          final data = await _alphaVantage.getWeeklyTimeSeries(symbol);
          if (data.isNotEmpty) {
            await CacheManager.put(
              'weekly-history:${symbol.toUpperCase()}',
              data,
              ttl: _avFallbackTtl,
            );
          }
          return data;
        } catch (_) {
          return const {};
        }
      },
    );
  }

  // ── RSI ───────────────────────────────────────────────────────────────────
  // RSI only comes from Alpha Vantage - cache for 48h to save quota

  Future<Map<String, dynamic>> getRsi({
    required String symbol,
    String interval = 'daily',
    int timePeriod = 14,
    String seriesType = 'close',
  }) {
    // ✅ Skip entirely if daily limit reached
    if (AlphaVantageService.isDailyLimitReached) {
      return Future.value(const {});
    }

    return _cachedMap(
      key: 'rsi:${symbol.toUpperCase()}:$interval:$timePeriod:$seriesType',
      ttl: _avFallbackTtl, // ✅ 7 days to preserve quota
      loader: () async {
        try {
          return await _alphaVantage.getRsi(
            symbol: symbol,
            interval: interval,
            timePeriod: timePeriod,
            seriesType: seriesType,
          );
        } catch (_) {
          return const {};
        }
      },
    );
  }

  // ── Stock Detail (combined) ───────────────────────────────────────────────

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

  // ── Cache helpers ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _cachedMap({
    required String key,
    required Duration ttl,
    required Future<Map<String, dynamic>> Function() loader,
  }) async {
    // ✅ Check cache first
    final cached = await CacheManager.get<Object>(key);
    if (cached is Map) {
      final map = _stringKeyedMap(cached);
      if (map.isNotEmpty) return map;
    }

    final data = await loader();

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
    if (data.isNotEmpty) {
      await CacheManager.put(key, data, ttl: ttl);
    }
    return data;
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

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