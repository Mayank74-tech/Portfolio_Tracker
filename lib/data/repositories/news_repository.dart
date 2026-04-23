import '../services/local/cache_manager.dart';
import '../services/remote/marketaux_service.dart';

class NewsRepository {
  NewsRepository({MarketauxService? marketauxService})
      : _marketaux = marketauxService ?? MarketauxService();

  final MarketauxService _marketaux;

  static const Duration _newsTtl = Duration(minutes: 30);

  Future<List<Map<String, dynamic>>> getLatestNews({
    List<String> symbols = const [],
    String countries = 'in,us',
    String language = 'en',
    int limit = 10,
  }) {
    final symbolKey = symbols.map((symbol) => symbol.toUpperCase()).join(',');
    return _cachedNews(
      key: 'news:latest:$symbolKey:$countries:$language:$limit',
      loader: () => _marketaux.getLatestNews(
        symbols: symbols,
        countries: countries,
        language: language,
        limit: limit,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getNewsForSymbol(
    String symbol, {
    int limit = 10,
    String language = 'en',
  }) {
    return _cachedNews(
      key: 'news:symbol:${symbol.toUpperCase()}:$language:$limit',
      loader: () => _marketaux.getNewsForSymbol(
        symbol,
        limit: limit,
        language: language,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getNewsForHoldings(
    List<Map<String, dynamic>> holdings, {
    int limit = 10,
  }) {
    final symbols = holdings
        .map(_symbolFromHolding)
        .where((symbol) => symbol.isNotEmpty)
        .toSet()
        .toList();

    return getLatestNews(symbols: symbols, limit: limit);
  }

  Future<List<Map<String, dynamic>>> searchNews({
    required String query,
    int limit = 10,
    String language = 'en',
  }) {
    return _cachedNews(
      key: 'news:search:${query.trim().toLowerCase()}:$language:$limit',
      loader: () => _marketaux.searchNews(
        query: query,
        limit: limit,
        language: language,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _cachedNews({
    required String key,
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) async {
    final cached = await CacheManager.get<Object>(key);
    if (cached is List) {
      return cached.whereType<Map>().map(_stringKeyedMap).toList();
    }

    final data = await loader();
    await CacheManager.put(key, data, ttl: _newsTtl);
    return data;
  }

  static String _symbolFromHolding(Map<String, dynamic> holding) {
    final value = holding['stock_symbol'] ?? holding['symbol'];
    return value?.toString().trim().toUpperCase() ?? '';
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}
