import 'package:flutter/foundation.dart';
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

  // ✅ Debounce worker - disposed in onClose
  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();

    // ✅ Debounce rapid holdings updates
    // If holdings changes 10 times in 300ms, only runs once
    _debounceWorker = debounce(
      holdings,
          (_) => _onHoldingsChanged(),
      time: const Duration(milliseconds: 300),
    );
  }

  void _onHoldingsChanged() {
    // ✅ Heavy metric calculations run in isolate
    // Does not block main thread / UI
    if (holdings.isNotEmpty) {
      compute(_calculateSummaryMetrics, holdings.toList()).then((metrics) {
        // Update any derived reactive state here if needed
        // e.g. totalValue.value = metrics['totalValue'];
      });
    }
  }

  // ✅ Static - required for compute() to work
  // Runs in separate isolate, not on main thread
  static Map<String, double> _calculateSummaryMetrics(
      List<Map<String, dynamic>> holdings,
      ) {
    double totalInvested = 0;
    double totalCurrent = 0;

    for (final h in holdings) {
      final qty = (h['quantity'] as num?)?.toDouble() ?? 0;
      final avgPrice = (h['averagePrice'] as num?)?.toDouble() ?? 0;
      final currentPrice = (h['currentPrice'] as num?)?.toDouble() ?? 0;

      totalInvested += qty * avgPrice;
      totalCurrent += qty * currentPrice;
    }

    final gain = totalCurrent - totalInvested;
    final gainPct =
    totalInvested > 0 ? (gain / totalInvested) * 100 : 0.0;

    return {
      'totalInvested': totalInvested,
      'totalCurrent': totalCurrent,
      'totalGain': gain,
      'gainPercent': gainPct,
    };
  }

  Future<void> loadPortfolio() async {
    // ✅ Guard: don't stack duplicate loads
    if (isLoading.value) return;

    await _runLoading(() async {
      final data = await _repository.getPortfolioSummary();
      summary.assignAll(data);

      final summaryHoldings = data['holdings'];
      if (summaryHoldings is List) {
        // ✅ Parse off main thread
        final parsed = await compute(
          _parseHoldings,
          summaryHoldings,
        );
        // ✅ Single assignAll = single rebuild, not one per item
        holdings.assignAll(parsed);
      }
    });
  }

  // ✅ Static for compute()
  static List<Map<String, dynamic>> _parseHoldings(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> loadHoldings() async {
    if (isLoading.value) return; // ✅ Guard duplicate calls

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

  void clearError() => errorMessage.value = '';

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
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }
}