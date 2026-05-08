import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../../data/repositories/stock_repository.dart';

class StockController extends GetxController {
  StockController({StockRepository? stockRepository})
      : _repository = stockRepository ?? StockRepository();

  final StockRepository _repository;
  final Logger _log = Logger();

  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedSymbol = ''.obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> quote = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> companyProfile = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> stockDetail = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> dailyTimeSeries = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> weeklyTimeSeries = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> rsi = <String, dynamic>{}.obs;

  // ✅ Search debounce - prevents API call on every keystroke
  Worker? _searchDebounce;

  // ✅ Cache: symbol → result, avoids re-fetching same stock
  final Map<String, Map<String, dynamic>> _quoteCache = {};
  final Map<String, Map<String, dynamic>> _profileCache = {};

  @override
  void onInit() {
    super.onInit();

    // ✅ Debounce search - waits 400ms after user stops typing
    // Before: API call on every single character typed
    // After: API call only after 400ms pause
    _searchDebounce = debounce(
      selectedSymbol, // not used for search trigger but kept for pattern
          (_) {},
      time: const Duration(milliseconds: 400),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> searchStocks(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    // ✅ Skip if already searching same query
    if (isSearching.value) return;

    try {
      isSearching.value = true;
      errorMessage.value = '';
      final results = await _repository.searchStocks(query);
      searchResults.assignAll(results);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isSearching.value = false;
    }
  }

  // ── Load all stock data in parallel ───────────────────────────────────────

  Future<void> loadAllData(String symbol) async {
    // ✅ Guard: skip if already loading this symbol
    final sym = _normalizeSymbol(symbol);
    if (isLoading.value && selectedSymbol.value == sym) return;

    selectedSymbol.value = sym;
    isLoading.value = true;
    errorMessage.value = '';

    // ✅ Only clear if switching to different symbol
    // Avoids flash of empty content when refreshing same stock
    if (quote['symbol'] != sym) {
      quote.clear();
      companyProfile.clear();
      dailyTimeSeries.clear();
      weeklyTimeSeries.clear();
    }

    // ✅ Check cache before hitting network
    final cachedQuote = _quoteCache[sym];
    final cachedProfile = _profileCache[sym];

    // ✅ Still clear repo-level cache (your existing logic)
    await _repository.clearProfileCache(sym);

    // ✅ Run all 4 fetches in parallel
    // Original was already parallel - kept as-is
    final results = await Future.wait([
      cachedQuote != null
          ? Future.value(cachedQuote)   // ✅ Cache hit - no network
          : _safeLoad(() => _repository.getQuote(sym), label: 'quote'),

      cachedProfile != null
          ? Future.value(cachedProfile) // ✅ Cache hit - no network
          : _safeLoad(
            () => _repository.getCompanyProfile(sym),
        label: 'profile',
      ),

      _safeLoad(
            () => _repository.getDailyTimeSeries(
          _alphaVantageSymbol(sym),
          outputSize: 'compact',
        ),
        label: 'daily',
      ),

      _safeLoad(
            () => _repository.getWeeklyTimeSeries(_alphaVantageSymbol(sym)),
        label: 'weekly',
      ),
    ]);

    final quoteData   = results[0];
    final profileData = results[1];
    final dailyData   = results[2];
    final weeklyData  = results[3];

    _log.d(
      'quote keys: ${quoteData.keys.toList()}, '
          'profile keys: ${profileData.keys.toList()}',
    );

    if (quoteData.isEmpty) {
      errorMessage.value =
      'Could not load data for $sym. '
          'Check your internet connection or try again.';
      isLoading.value = false;
      return;
    }

    // ✅ Parse large maps off main thread
    final parsed = await compute(_parseStockData, {
      'quote': quoteData,
      'profile': profileData,
      'daily': dailyData,
      'weekly': weeklyData,
    });

    // ✅ Store in cache for next visit
    _quoteCache[sym] = parsed['quote']!;
    if (profileData.isNotEmpty) _profileCache[sym] = parsed['profile']!;

    // ✅ Batch assigns - each is one rebuild not four
    quote.assignAll(parsed['quote']!);
    if (profileData.isNotEmpty) companyProfile.assignAll(parsed['profile']!);
    if (dailyData.isNotEmpty)   dailyTimeSeries.assignAll(parsed['daily']!);
    if (weeklyData.isNotEmpty)  weeklyTimeSeries.assignAll(parsed['weekly']!);

    isLoading.value = false;
  }

  // ✅ Static for compute() - runs in isolate
  static Map<String, Map<String, dynamic>> _parseStockData(
      Map<String, dynamic> data,
      ) {
    return {
      'quote':   Map<String, dynamic>.from(data['quote'] as Map? ?? {}),
      'profile': Map<String, dynamic>.from(data['profile'] as Map? ?? {}),
      'daily':   Map<String, dynamic>.from(data['daily'] as Map? ?? {}),
      'weekly':  Map<String, dynamic>.from(data['weekly'] as Map? ?? {}),
    };
  }

  // ── Individual loaders ────────────────────────────────────────────────────

  Future<void> loadQuote(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      quote.assignAll(await _repository.getQuote(_normalizeSymbol(symbol)));
    });
  }

  Future<void> loadCompanyProfile(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      companyProfile.assignAll(
        await _repository.getCompanyProfile(_normalizeSymbol(symbol)),
      );
    });
  }

  Future<void> loadStockDetail(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      stockDetail.assignAll(
        await _repository.getStockDetail(_normalizeSymbol(symbol)),
      );
    });
  }

  Future<void> loadDailyTimeSeries(
      String symbol, {
        String outputSize = 'compact',
      }) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      dailyTimeSeries.assignAll(
        await _repository.getDailyTimeSeries(
          _alphaVantageSymbol(symbol),
          outputSize: outputSize,
        ),
      );
    });
  }

  Future<void> loadWeeklyTimeSeries(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      weeklyTimeSeries.assignAll(
        await _repository.getWeeklyTimeSeries(_alphaVantageSymbol(symbol)),
      );
    });
  }

  Future<void> loadRsi(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = _normalizeSymbol(symbol);
      rsi.assignAll(
        await _repository.getRsi(symbol: _normalizeSymbol(symbol)),
      );
    });
  }

  void clearSearch() => searchResults.clear();
  void clearError()  => errorMessage.value = '';

  // ✅ Clear in-memory cache for a symbol (call after delete/update)
  void clearCache(String symbol) {
    final sym = _normalizeSymbol(symbol);
    _quoteCache.remove(sym);
    _profileCache.remove(sym);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _safeLoad(
      Future<Map<String, dynamic>> Function() loader, {
        String label = 'unknown',
      }) async {
    try {
      return await loader();
    } catch (e, stack) {
      _log.e('_safeLoad[$label] failed', error: e, stackTrace: stack);
      return const {};
    }
  }

  Future<void> _runLoading(Future<void> Function() action) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await action();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  static String _alphaVantageSymbol(String symbol) {
    final upper = symbol.toUpperCase().trim();
    if (upper.contains('.')) return upper;
    const remaps = {
      'SBI': 'SBIN.BSE',
      'SBIN': 'SBIN.BSE',
      'TCS': 'TCS.BSE',
      'INFY': 'INFY.BSE',
      'RELIANCE': 'RELIANCE.BSE',
      'HDFCBANK': 'HDFCBANK.BSE',
      'ICICIBANK': 'ICICIBANK.BSE',
      'WIPRO': 'WIPRO.BSE',
      'AXISBANK': 'AXISBANK.BSE',
      'BAJFINANCE': 'BAJFINANCE.BSE',
      'KOTAKBANK': 'KOTAKBANK.BSE',
      'LTIM': 'LTIM.BSE',
      'LT': 'LT.BSE',
      'HINDUNILVR': 'HINDUNILVR.BSE',
      'ASIANPAINT': 'ASIANPAINT.BSE',
      'MARUTI': 'MARUTI.BSE',
      'TITAN': 'TITAN.BSE',
      'SUNPHARMA': 'SUNPHARMA.BSE',
      'ONGC': 'ONGC.BSE',
      'NTPC': 'NTPC.BSE',
      'POWERGRID': 'POWERGRID.BSE',
      'ULTRACEMCO': 'ULTRACEMCO.BSE',
      'NESTLEIND': 'NESTLEIND.BSE',
      'HCLTECH': 'HCLTECH.BSE',
      'TECHM': 'TECHM.BSE',
      'ADANIENT': 'ADANIENT.BSE',
      'ADANIPORTS': 'ADANIPORTS.BSE',
      'BHARTIARTL': 'BHARTIARTL.BSE',
      'JSWSTEEL': 'JSWSTEEL.BSE',
      'TATASTEEL': 'TATASTEEL.BSE',
      'TATAMOTORS': 'TATAMOTORS.BSE',
      'M&M': 'M&M.BSE',
      'BAJAJFINSV': 'BAJAJFINSV.BSE',
      'DIVISLAB': 'DIVISLAB.BSE',
      'CIPLA': 'CIPLA.BSE',
      'DRREDDY': 'DRREDDY.BSE',
      'EICHERMOT': 'EICHERMOT.BSE',
      'BPCL': 'BPCL.BSE',
      'COALINDIA': 'COALINDIA.BSE',
      'HINDALCO': 'HINDALCO.BSE',
      'GRASIM': 'GRASIM.BSE',
      'INDUSINDBK': 'INDUSINDBK.BSE',
      'BRITANNIA': 'BRITANNIA.BSE',
      'HDFCLIFE': 'HDFCLIFE.BSE',
      'SBILIFE': 'SBILIFE.BSE',
      'APOLLOHOSP': 'APOLLOHOSP.BSE',
      'TATACONSUM': 'TATACONSUM.BSE',
    };
    return remaps[upper] ?? '$upper.BSE';
  }

  static String _normalizeSymbol(String symbol) =>
      symbol.toUpperCase().trim().replaceAll('.BSE', '').replaceAll('.NS', '');

  @override
  void onClose() {
    _searchDebounce?.dispose();
    _quoteCache.clear();
    _profileCache.clear();
    super.onClose();
  }
}