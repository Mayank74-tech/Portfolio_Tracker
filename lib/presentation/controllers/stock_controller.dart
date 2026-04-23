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

  Future<void> loadQuote(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      quote.assignAll(await _repository.getQuote(symbol));
    });
  }

  Future<void> loadCompanyProfile(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      companyProfile.assignAll(await _repository.getCompanyProfile(symbol));
    });
  }

  Future<void> loadStockDetail(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      stockDetail.assignAll(await _repository.getStockDetail(symbol));
    });
  }

  Future<void> loadDailyTimeSeries(
    String symbol, {
    String outputSize = 'compact',
  }) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      dailyTimeSeries.assignAll(
        await _repository.getDailyTimeSeries(symbol, outputSize: outputSize),
      );
    });
  }

  Future<void> loadWeeklyTimeSeries(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      weeklyTimeSeries.assignAll(await _repository.getWeeklyTimeSeries(symbol));
    });
  }

  Future<void> loadRsi(String symbol) async {
    await _runLoading(() async {
      selectedSymbol.value = symbol.toUpperCase();
      rsi.assignAll(await _repository.getRsi(symbol: symbol));
    });
  }

  void clearSearch() {
    searchResults.clear();
  }

  void clearError() {
    errorMessage.value = '';
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
}
