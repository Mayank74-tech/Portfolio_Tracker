import 'package:get/get.dart';

import '../../data/repositories/stock_repository.dart';

class StockController extends GetxController {
  StockController({StockRepository? stockRepository})
      : _repository = stockRepository ?? StockRepository();

  final StockRepository _repository;

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


  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> searchStocks(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

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

  // ── Load all stock data in parallel (main entry point from detail screen) ─

  Future<void> loadAllData(String symbol) async {
    final sym = _normalizeSymbol(symbol);
    selectedSymbol.value = sym;

    isLoading.value = true;
    errorMessage.value = '';

    quote.clear();
    companyProfile.clear();
    dailyTimeSeries.clear();
    weeklyTimeSeries.clear();

    // ── Clear stale cache before loading ──────────────────────────────────
    await _repository.clearProfileCache(sym);

    final results = await Future.wait([
      _safeLoad(() => _repository.getQuote(sym), label: 'quote'),
      _safeLoad(() => _repository.getCompanyProfile(sym), label: 'profile'),
      _safeLoad(
            () => _repository.getDailyTimeSeries(
          _alphaVantageSymbol(sym),
          outputSize: 'compact', // ← was 'full' (premium only)
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

    print('quote:   $quoteData');
    print('profile: $profileData');

    if (quoteData.isEmpty) {
      errorMessage.value =
      'Could not load data for $sym. '
          'Check your internet connection or try again.';
      isLoading.value = false;
      return;
    }

    quote.assignAll(quoteData);
    if (profileData.isNotEmpty) companyProfile.assignAll(profileData);
    if (dailyData.isNotEmpty)   dailyTimeSeries.assignAll(dailyData);
    if (weeklyData.isNotEmpty)  weeklyTimeSeries.assignAll(weeklyData);

    isLoading.value = false;
  }


  // ── Individual loaders (kept for backward-compat with other screens) ──────

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
      rsi.assignAll(await _repository.getRsi(symbol: _normalizeSymbol(symbol)));
    });
  }

  void clearSearch() => searchResults.clear();
  void clearError()  => errorMessage.value = '';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Catches any exception and returns an empty map instead of throwing.
  /// This lets parallel calls fail silently for non-critical data.
  Future<Map<String, dynamic>> _safeLoad(
      Future<Map<String, dynamic>> Function() loader, {
        String label = 'unknown',
      }) async {
    try {
      final result = await loader();
      print('_safeLoad[$label] success — keys: ${result.keys.toList()}');
      return result;
    } catch (e, stack) {
      print('_safeLoad[$label] ERROR: $e');
      print('_safeLoad[$label] STACK: $stack');
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

  /// Alpha Vantage requires `.BSE` suffix for Indian stocks.
  /// If the symbol already has an exchange suffix, leave it as-is.
  /// Examples: SBI → SBIN.BSE, INFY → INFY.BSE, AAPL → AAPL
  static String _alphaVantageSymbol(String symbol) {
    final upper = symbol.toUpperCase().trim();
    // Already has exchange suffix
    if (upper.contains('.')) return upper;
    // Known symbol remaps (NSE ticker → BSE-listed Alpha Vantage symbol)
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

  /// Finnhub uses plain NSE symbols (no suffix needed).
  static String _normalizeSymbol(String symbol) =>
      symbol.toUpperCase().trim().replaceAll('.BSE', '').replaceAll('.NS', '');
}