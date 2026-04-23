import 'package:get/get.dart';

import '../../data/repositories/watchlist_repository.dart';

class WatchlistController extends GetxController {
  WatchlistController({WatchlistRepository? watchlistRepository})
      : _repository = watchlistRepository ?? WatchlistRepository();

  final WatchlistRepository _repository;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  Future<void> loadWatchlist({bool withPrices = true}) async {
    await _runLoading(() async {
      final data = withPrices
          ? await _repository.getWatchlistWithPrices()
          : await _repository.getWatchlist();
      items.assignAll(data);
    });
  }

  Future<void> addToWatchlist({
    required String symbol,
    String? name,
  }) async {
    await _runSaving(() async {
      await _repository.addToWatchlist(symbol: symbol, name: name);
      await loadWatchlist();
    });
  }

  Future<void> removeFromWatchlist(String symbol) async {
    await _runSaving(() async {
      await _repository.removeFromWatchlist(symbol: symbol);
      await loadWatchlist();
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

  Future<void> _runSaving(Future<void> Function() action) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';
      await action();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isSaving.value = false;
    }
  }
}
