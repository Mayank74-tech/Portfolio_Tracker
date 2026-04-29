import 'package:get/get.dart';

import '../../data/repositories/portfolio_repository.dart';

class PortfolioController extends GetxController {
  PortfolioController({PortfolioRepository? portfolioRepository})
      : _repository = portfolioRepository ?? PortfolioRepository();

  final PortfolioRepository _repository;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> holdings = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;

  Future<void> loadPortfolio() async {
    await _runLoading(() async {
      final data = await _repository.getPortfolioSummary();
      summary.assignAll(data);
      final summaryHoldings = data['holdings'];
      if (summaryHoldings is List) {
        holdings.assignAll(
          summaryHoldings.whereType<Map>().map(_stringKeyedMap).toList(),
        );
      }
    });
  }

  Future<void> loadHoldings() async {
    await _runLoading(() async {
      final data = await _repository.getHoldingsWithPrices();
      holdings.assignAll(data);
    });
  }

  Future<void> addHolding(Map<String, dynamic> holding) async {
    await _runSaving(() async {
      await _repository.addHolding(holding);
      await loadPortfolio();
    });
  }

  Future<void> updateHolding({
    required String holdingId,
    required Map<String, dynamic> holding,
  }) async {
    await _runSaving(() async {
      await _repository.updateHolding(
        holdingId: holdingId,
        holding: holding,
      );
      await loadPortfolio();
    });
  }

  Future<void> deleteHolding(String holdingId) async {
    await _runSaving(() async {
      await _repository.deleteHolding(holdingId: holdingId);
      await loadPortfolio();
    });
  }

  Future<void> importHoldings(List<Map<String, dynamic>> imported) async {
    await _runSaving(() async {
      await _repository.importHoldings(imported);
      await loadPortfolio();
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
      rethrow; // ✅ let callers catch it too
    } finally {
      isSaving.value = false;
    }
  }

  static Map<String, dynamic> _stringKeyedMap(Map value) =>
      value.map((key, data) => MapEntry(key.toString(), data));
}
