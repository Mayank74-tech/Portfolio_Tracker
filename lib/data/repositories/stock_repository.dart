import '../services/local/cache_manager.dart';
import '../services/remote/alpha_vantage_service.dart';
import '../services/remote/finnhub_service.dart';
import '../services/remote/fmp_service.dart';

class StockRepository {
  StockRepository({
    FinnhubService? finnhubService,
    AlphaVantageService? alphaVantageService,
    FmpService? fmpService,
  })  : _finnhub = finnhubService ?? FinnhubService(),
        _alphaVantage = alphaVantageService ?? AlphaVantageService(),
        _fmp = fmpService ?? FmpService();

  final FinnhubService _finnhub;
  final AlphaVantageService _alphaVantage;
  final FmpService _fmp;

  static const Duration _quoteTtl = Duration(minutes: 5);
  static const Duration _profileTtl = Duration(days: 7);
  static const Duration _historyTtl = Duration(hours: 24);

  Future<Map<String, dynamic>> getQuote(String symbol) {
    return _cachedMap(
      key: 'quote:${symbol.toUpperCase()}',
      ttl: _quoteTtl,
      loader: () => _finnhub.getQuote(symbol),
    );
  }

  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    if (query.trim().isEmpty) return const [];

    final finnhubResults = await _finnhub.searchSymbols(query);
    if (finnhubResults.isNotEmpty) {
      return finnhubResults;
    }

    return _fmp.searchCompanies(query);
  }

  Future<Map<String, dynamic>> getCompanyProfile(String symbol) {
    return _cachedMap(
      key: 'company-profile:${symbol.toUpperCase()}',
      ttl: _profileTtl,
      loader: () async {
        final finnhubProfile = await _finnhub.getCompanyProfile(symbol);
        if (finnhubProfile.isNotEmpty) return finnhubProfile;
        return _fmp.getCompanyProfile(symbol);
      },
    );
  }

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

  Future<Map<String, dynamic>> getDailyTimeSeries(
    String symbol, {
    String outputSize = 'compact',
  }) {
    return _cachedMap(
      key: 'daily-history:${symbol.toUpperCase()}:$outputSize',
      ttl: _historyTtl,
      loader: () => _alphaVantage.getDailyTimeSeries(
        symbol,
        outputSize: outputSize,
      ),
    );
  }

  Future<Map<String, dynamic>> getWeeklyTimeSeries(String symbol) {
    return _cachedMap(
      key: 'weekly-history:${symbol.toUpperCase()}',
      ttl: _historyTtl,
      loader: () => _alphaVantage.getWeeklyTimeSeries(symbol),
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

  Future<Map<String, dynamic>> _cachedMap({
    required String key,
    required Duration ttl,
    required Future<Map<String, dynamic>> Function() loader,
  }) async {
    final cached = await CacheManager.get<Object>(key);
    if (cached is Map) return _stringKeyedMap(cached);

    final data = await loader();
    await CacheManager.put(key, data, ttl: ttl);
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

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}
