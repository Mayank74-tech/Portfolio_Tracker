// lib/presentation/controllers/behavioral_controller.dart

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/behavioral/belief_log_model.dart';
import '../../data/repositories/behavioral_repository.dart';
import '../../data/services/local/behavioral_tracker_service.dart';
import 'portfolio_controller.dart';

class BehavioralController extends GetxController {
  BehavioralController({
    BehavioralRepository? repository,
  }) : _repo = repository ?? BehavioralRepository();

  final BehavioralRepository _repo;

  // ── Reactive state ─────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  // Feature 1
  final Rx<Map<String, dynamic>> memoryReality =
  Rx<Map<String, dynamic>>({});

  // Feature 3
  final Rx<Map<String, dynamic>> attentionData =
  Rx<Map<String, dynamic>>({});

  // Feature 4
  final Rx<Map<String, dynamic>> uncertaintyBands =
  Rx<Map<String, dynamic>>({});

  // Feature 5
  final RxList<Map<String, dynamic>> halfLives =
      <Map<String, dynamic>>[].obs;

  // Feature 8
  final RxList<Map<String, dynamic>> silentWinners =
      <Map<String, dynamic>>[].obs;

  // Feature 9
  final Rx<Map<String, dynamic>> cascadeRisk =
  Rx<Map<String, dynamic>>({});

  // Feature 10
  final Rx<Map<String, dynamic>> identityDrift =
  Rx<Map<String, dynamic>>({});

  // Feature 11
  final Rx<Map<String, dynamic>> confidenceIllusion =
  Rx<Map<String, dynamic>>({});

  // Feature 12
  final Rx<Map<String, dynamic>> frictionScore =
  Rx<Map<String, dynamic>>({});

  // Feature 13
  final Rx<Map<String, dynamic>> inactionData =
  Rx<Map<String, dynamic>>({});

  // Feature 14
  final RxList<Map<String, dynamic>> delayedTruths =
      <Map<String, dynamic>>[].obs;

  // Feature 15
  final Rx<Map<String, dynamic>> conflictData =
  Rx<Map<String, dynamic>>({});

  final RxList<BeliefLogModel> allBeliefs =
      <BeliefLogModel>[].obs;

  late final BehavioralTrackerService _tracker;
  final RxDouble beliefAccuracy = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _tracker = BehavioralTrackerService();
    loadAllInsights();
  }

  Future<void> loadAllInsights() async {
    isLoading.value = true;
    try {
      final portfolio = Get.find<PortfolioController>();
      final holdings = portfolio.holdings;

      beliefAccuracy.value = _tracker.beliefAccuracyRate();
      allBeliefs.assignAll(_tracker.getAllBeliefs());
      beliefAccuracy.value = _tracker.beliefAccuracyRate();

      attentionData.value =
          _repo.getAttentionAnalysis(holdings);
      uncertaintyBands.value =
          _repo.getUncertaintyBands(holdings);
      halfLives.assignAll(
          _repo.getDecisionHalfLives(holdings));
      silentWinners.assignAll(
          _repo.getSilentWinners(holdings));
      cascadeRisk.value =
          _repo.getCascadingRisk(holdings);
      identityDrift.value =
          _repo.getIdentityDrift(holdings);
      confidenceIllusion.value =
          _repo.getConfidenceIllusion();
      frictionScore.value =
          _repo.getDecisionFriction();
      inactionData.value =
          _repo.getInactionAnalysis();
      delayedTruths.assignAll(
          _repo.getDelayedTruths(holdings));
      conflictData.value =
          _repo.getInternalConflict(holdings);
    } catch (e) {
      debugPrint('BehavioralController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Feature 1: Memory vs Reality ──────────────────────────────────────────

  Future<void> submitMemoryBelief(String userBelief) async {
    final portfolio = Get.find<PortfolioController>();
    final result = _repo.analyzeMemoryVsReality(
      userBelief: userBelief,
      holdings: portfolio.holdings,
    );

    await _tracker.logBelief(
      question: 'Which stock has performed worst for you?',
      userBelief: userBelief,
      actualAnswer: result['actual_worst']?.toString() ?? '',
      wasCorrect: result['was_correct'] == true,
      explanation: result['explanation']?.toString() ?? '',
    );

    memoryReality.value = result;
  }

  // ── Feature 3: Log attention ───────────────────────────────────────────────

  Future<void> logStockView({
    required String symbol,
    required int durationSeconds,
  }) async {
    await _tracker.logAttention(
      symbol: symbol,
      durationSeconds: durationSeconds,
      screenName: 'stock_detail',
    );
    // Refresh attention data
    final portfolio = Get.find<PortfolioController>();
    attentionData.value =
        _repo.getAttentionAnalysis(portfolio.holdings);
  }

  // ── Feature 12: Log buy decision ──────────────────────────────────────────

  Future<void> logBuyDecision({
    required String symbol,
    required double portfolioValue,
    required double stockPrice,
    required int secondsSinceLastView,
  }) async {
    await _tracker.logDecision(
      symbol: symbol,
      action: 'buy',
      portfolioValue: portfolioValue,
      stockPrice: stockPrice,
      secondsSinceLastView: secondsSinceLastView,
    );
    frictionScore.value = _repo.getDecisionFriction();
  }

  // ── Feature 13: Log rebalance considered ──────────────────────────────────

  Future<void> logRebalanceConsidered() async {
    await _tracker.recordRebalanceConsidered();
    inactionData.value = _repo.getInactionAnalysis();
  }

  Future<void> logRebalanceActed() async {
    await _tracker.recordRebalanceActed();
    inactionData.value = _repo.getInactionAnalysis();
  }

  // ── Feature 10: Set investing style ───────────────────────────────────────

  Future<void> setInvestingStyle(String style) async {
    await _tracker.updateInvestingStyle(style);
    final portfolio = Get.find<PortfolioController>();
    identityDrift.value =
        _repo.getIdentityDrift(portfolio.holdings);
  }

  // ── Feature 11: Record confidence ─────────────────────────────────────────

  Future<void> recordConfidence({
    required double confidence,
    required double actualReturn,
  }) async {
    await _tracker.recordConfidenceAndReturn(
      confidence: confidence,
      actualReturn: actualReturn,
    );
    confidenceIllusion.value = _repo.getConfidenceIllusion();
  }

// Add setRiskTolerance method
  Future<void> setRiskTolerance(String risk) async {
    await _tracker.setRiskTolerance(risk);
    final portfolio = Get.find<PortfolioController>();
    conflictData.value =
        _repo.getInternalConflict(portfolio.holdings);
  }


}