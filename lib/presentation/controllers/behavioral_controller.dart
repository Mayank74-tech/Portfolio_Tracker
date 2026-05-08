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

  final memoryReality = <String, dynamic>{}.obs;
  final attentionData = <String, dynamic>{}.obs;
  final uncertaintyBands = <String, dynamic>{}.obs;
  final halfLives = <Map<String, dynamic>>[].obs;
  final silentWinners = <Map<String, dynamic>>[].obs;
  final cascadeRisk = <String, dynamic>{}.obs;
  final identityDrift = <String, dynamic>{}.obs;
  final confidenceIllusion = <String, dynamic>{}.obs;
  final frictionScore = <String, dynamic>{}.obs;
  final inactionData = <String, dynamic>{}.obs;
  final delayedTruths = <Map<String, dynamic>>[].obs;
  final conflictData = <String, dynamic>{}.obs;

  final allBeliefs = <BeliefLogModel>[].obs;
  final beliefAccuracy = 0.0.obs;

  late final BehavioralTrackerService _tracker;
  late final PortfolioController _portfolio;

  Worker? _portfolioDebounce;

  @override
  void onInit() {
    super.onInit();

    _tracker = BehavioralTrackerService();
    _portfolio = Get.find<PortfolioController>();

    // ✅ Auto refresh when holdings change (debounced)
    _portfolioDebounce = debounce(
      _portfolio.holdings,
          (_) => loadAllInsights(),
      time: const Duration(milliseconds: 400),
    );

    loadAllInsights();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ✅ HEAVY COMPUTATION MOVED TO ISOLATE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> loadAllInsights() async {
    if (isLoading.value) return; // ✅ Prevent duplicate loads

    isLoading.value = true;

    try {
      final holdingsCopy = _portfolio.holdings.toList();
      final beliefs = _tracker.getAllBeliefs();
      final accuracy = _tracker.beliefAccuracyRate();

      // ✅ Run repository analysis in background isolate
      final results = await compute(
        _analyzeBehavioralData,
        _BehavioralInput(
          holdings: holdingsCopy,
          repo: _repo,
        ),
      );

      // ✅ Batch update (less rebuild thrashing)
      beliefAccuracy.value = accuracy;
      allBeliefs.assignAll(beliefs);

      attentionData.value = results.attention;
      uncertaintyBands.value = results.uncertainty;
      halfLives.assignAll(results.halfLives);
      silentWinners.assignAll(results.silentWinners);
      cascadeRisk.value = results.cascade;
      identityDrift.value = results.identityDrift;
      confidenceIllusion.value = results.confidenceIllusion;
      frictionScore.value = results.friction;
      inactionData.value = results.inaction;
      delayedTruths.assignAll(results.delayedTruths);
      conflictData.value = results.conflict;
    } catch (e) {
      debugPrint('BehavioralController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Static isolate entry point
  static _BehavioralOutput _analyzeBehavioralData(
      _BehavioralInput input) {
    final repo = input.repo;
    final holdings = input.holdings;

    return _BehavioralOutput(
      attention: repo.getAttentionAnalysis(holdings),
      uncertainty: repo.getUncertaintyBands(holdings),
      halfLives: repo.getDecisionHalfLives(holdings),
      silentWinners: repo.getSilentWinners(holdings),
      cascade: repo.getCascadingRisk(holdings),
      identityDrift: repo.getIdentityDrift(holdings),
      confidenceIllusion: repo.getConfidenceIllusion(),
      friction: repo.getDecisionFriction(),
      inaction: repo.getInactionAnalysis(),
      delayedTruths: repo.getDelayedTruths(holdings),
      conflict: repo.getInternalConflict(holdings),
    );
  }

  // ── Feature 1 ─────────────────────────────────────────────────────────────

  Future<void> submitMemoryBelief(String userBelief) async {
    final result = _repo.analyzeMemoryVsReality(
      userBelief: userBelief,
      holdings: _portfolio.holdings,
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

  Future<void> logStockView({
    required String symbol,
    required int durationSeconds,
  }) async {
    await _tracker.logAttention(
      symbol: symbol,
      durationSeconds: durationSeconds,
      screenName: 'stock_detail',
    );
    attentionData.value =
        _repo.getAttentionAnalysis(_portfolio.holdings);
  }

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

  Future<void> logRebalanceConsidered() async {
    await _tracker.recordRebalanceConsidered();
    inactionData.value = _repo.getInactionAnalysis();
  }

  Future<void> logRebalanceActed() async {
    await _tracker.recordRebalanceActed();
    inactionData.value = _repo.getInactionAnalysis();
  }

  Future<void> setInvestingStyle(String style) async {
    await _tracker.updateInvestingStyle(style);
    identityDrift.value =
        _repo.getIdentityDrift(_portfolio.holdings);
  }

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

  Future<void> setRiskTolerance(String risk) async {
    await _tracker.setRiskTolerance(risk);
    conflictData.value =
        _repo.getInternalConflict(_portfolio.holdings);
  }

  @override
  void onClose() {
    _portfolioDebounce?.dispose();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Data classes for isolate transfer
// ─────────────────────────────────────────────────────────────────────────────

class _BehavioralInput {
  final List<Map<String, dynamic>> holdings;
  final BehavioralRepository repo;

  _BehavioralInput({
    required this.holdings,
    required this.repo,
  });
}

class _BehavioralOutput {
  final Map<String, dynamic> attention;
  final Map<String, dynamic> uncertainty;
  final List<Map<String, dynamic>> halfLives;
  final List<Map<String, dynamic>> silentWinners;
  final Map<String, dynamic> cascade;
  final Map<String, dynamic> identityDrift;
  final Map<String, dynamic> confidenceIllusion;
  final Map<String, dynamic> friction;
  final Map<String, dynamic> inaction;
  final List<Map<String, dynamic>> delayedTruths;
  final Map<String, dynamic> conflict;

  _BehavioralOutput({
    required this.attention,
    required this.uncertainty,
    required this.halfLives,
    required this.silentWinners,
    required this.cascade,
    required this.identityDrift,
    required this.confidenceIllusion,
    required this.friction,
    required this.inaction,
    required this.delayedTruths,
    required this.conflict,
  });
}