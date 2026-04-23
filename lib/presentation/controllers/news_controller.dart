import 'package:get/get.dart';

import '../../data/repositories/news_repository.dart';

class NewsController extends GetxController {
  NewsController({NewsRepository? newsRepository})
      : _repository = newsRepository ?? NewsRepository();

  final NewsRepository _repository;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString activeFilter = 'all'.obs;
  final RxList<Map<String, dynamic>> news = <Map<String, dynamic>>[].obs;

  Future<void> loadLatestNews({
    List<String> symbols = const [],
    String countries = 'in,us',
    String language = 'en',
    int limit = 10,
  }) async {
    await _runLoading(() async {
      activeFilter.value = symbols.isEmpty ? 'all' : 'symbols';
      final data = await _repository.getLatestNews(
        symbols: symbols,
        countries: countries,
        language: language,
        limit: limit,
      );
      news.assignAll(data);
    });
  }

  Future<void> loadNewsForSymbol(String symbol, {int limit = 10}) async {
    await _runLoading(() async {
      activeFilter.value = symbol.toUpperCase();
      final data = await _repository.getNewsForSymbol(symbol, limit: limit);
      news.assignAll(data);
    });
  }

  Future<void> loadNewsForHoldings(
    List<Map<String, dynamic>> holdings, {
    int limit = 10,
  }) async {
    await _runLoading(() async {
      activeFilter.value = 'my_stocks';
      final data = await _repository.getNewsForHoldings(
        holdings,
        limit: limit,
      );
      news.assignAll(data);
    });
  }

  Future<void> searchNews(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) {
      await loadLatestNews(limit: limit);
      return;
    }

    await _runLoading(() async {
      activeFilter.value = 'search';
      final data = await _repository.searchNews(query: query, limit: limit);
      news.assignAll(data);
    });
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
