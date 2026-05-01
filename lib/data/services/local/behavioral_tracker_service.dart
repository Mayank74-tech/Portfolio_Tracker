// lib/data/services/local/behavioral_tracker_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../config/hive_config.dart';
import '../../models/behavioral/attention_log_model.dart';
import '../../models/behavioral/belief_log_model.dart';
import '../../models/behavioral/decision_event_model.dart';
import '../../models/behavioral/behavior_profile_model.dart';

class BehavioralTrackerService {
  static const String _profileKey = 'profile';

  // ── Typed box accessors ────────────────────────────────────────────────────
  // Explicitly typed so Dart knows the element type at compile time

  Box<AttentionLogModel>  get _attention => HiveConfig.attentionLogs;
  Box<BeliefLogModel>     get _beliefs   => HiveConfig.beliefLogs;
  Box<DecisionEventModel> get _decisions => HiveConfig.decisionEvents;
  Box<BehaviorProfileModel> get _profile => HiveConfig.behaviorProfile;

  // ── Feature 3: Attention tracking ─────────────────────────────────────────

  Future<void> logAttention({
    required String symbol,
    required int durationSeconds,
    required String screenName,
  }) async {
    await _attention.add(AttentionLogModel(
      symbol: symbol,
      viewedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      screenName: screenName,
    ));
    debugPrint('Attention: $symbol — ${durationSeconds}s on $screenName');
  }

  /// Returns map of symbol → total seconds viewed
  Map<String, int> getAttentionMap() {
    final map = <String, int>{};
    // .values returns Iterable<AttentionLogModel> because box is typed
    for (final AttentionLogModel log in _attention.values) {
      final current = map[log.symbol] ?? 0;
      map[log.symbol] = current + log.durationSeconds;
    }
    return map;
  }

  String? getMostWatchedSymbol() {
    final map = getAttentionMap();
    if (map.isEmpty) return null;
    return map.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int daysSinceLastView(String symbol) {
    final logs = _attention.values
        .where((AttentionLogModel l) => l.symbol == symbol)
        .toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    if (logs.isEmpty) return 999;
    return DateTime.now().difference(logs.first.viewedAt).inDays;
  }

  // ── Feature 1: Belief logging ──────────────────────────────────────────────

  Future<void> logBelief({
    required String question,
    required String userBelief,
    required String actualAnswer,
    required bool wasCorrect,
    required String explanation,
  }) async {
    await _beliefs.add(BeliefLogModel(
      question: question,
      userBelief: userBelief,
      actualAnswer: actualAnswer,
      wasCorrect: wasCorrect,
      recordedAt: DateTime.now(),
      explanation: explanation,
    ));
  }

  List<BeliefLogModel> getAllBeliefs() {
    final list = _beliefs.values.toList();
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  double beliefAccuracyRate() {
    final all = _beliefs.values.toList();
    if (all.isEmpty) return 0.0;
    final correct =
        all.where((BeliefLogModel b) => b.wasCorrect).length;
    return correct / all.length;
  }

  // ── Feature 12: Decision events ────────────────────────────────────────────

  Future<void> logDecision({
    required String symbol,
    required String action,
    required double portfolioValue,
    required double stockPrice,
    required int secondsSinceLastView,
    Map<String, dynamic>? context,
  }) async {
    await _decisions.add(DecisionEventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      action: action,
      timestamp: DateTime.now(),
      portfolioValueAtTime: portfolioValue,
      stockPriceAtTime: stockPrice,
      secondsSinceLastView: secondsSinceLastView,
      context: context ?? {},
    ));
  }

  List<DecisionEventModel> getDecisionsForSymbol(String symbol) {
    final list = _decisions.values
        .where((DecisionEventModel d) => d.symbol == symbol)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<DecisionEventModel> getAllDecisions() {
    final list = _decisions.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // ── Feature 12: Decision Friction Score ───────────────────────────────────

  double averageDecisionFrictionSeconds() {
    final buys = _decisions.values
        .where((DecisionEventModel d) =>
    d.action == 'buy' && d.secondsSinceLastView > 0)
        .toList();
    if (buys.isEmpty) return 0.0;

    int total = 0;
    for (final DecisionEventModel e in buys) {
      total += e.secondsSinceLastView;
    }
    return total / buys.length;
  }

  String frictionLabel() {
    final avg = averageDecisionFrictionSeconds();
    if (avg == 0) return 'No data yet';
    if (avg < 120) return 'High impulsivity (< 2 min)';
    if (avg < 600) return 'Moderate (2–10 min)';
    if (avg < 3600) return 'Considered (10 min – 1 hr)';
    return 'Deliberate (> 1 hr)';
  }

  // ── Feature 10: Identity Drift ─────────────────────────────────────────────

  BehaviorProfileModel getOrCreateProfile() {
    final existing = _profile.get(_profileKey);
    if (existing != null) return existing;

    final p = BehaviorProfileModel(
      investingStyle: HiveConfig.investingStyle,
      statedRiskTolerance: HiveConfig.statedRiskTolerance,
      styleHistory: <String>[],
      confidenceScores: <double>[],
      actualReturns: <double>[],
      decisionTimesSeconds: <int>[],
      rebalanceConsideredCount: 0,
      rebalanceActedCount: 0,
      lastUpdated: DateTime.now(),
    );
    _profile.put(_profileKey, p);
    return p;
  }

  Future<void> updateInvestingStyle(String style) async {
    final p = getOrCreateProfile();
    final dateTag = DateTime.now().toIso8601String().substring(0, 10);
    p.styleHistory.add('${style}_$dateTag');
    p.investingStyle = style;
    p.lastUpdated = DateTime.now();
    await p.save();
    await HiveConfig.setInvestingStyle(style);
  }

  Future<void> setRiskTolerance(String risk) async {
    final p = getOrCreateProfile();
    p.statedRiskTolerance = risk;
    p.lastUpdated = DateTime.now();
    await p.save();
    await HiveConfig.setRiskTolerance(risk);
  }

  Future<void> recordConfidenceAndReturn({
    required double confidence,
    required double actualReturn,
  }) async {
    final p = getOrCreateProfile();
    p.confidenceScores.add(confidence);
    p.actualReturns.add(actualReturn);
    p.lastUpdated = DateTime.now();
    await p.save();
  }

  Future<void> recordRebalanceConsidered() async {
    final p = getOrCreateProfile();
    p.rebalanceConsideredCount++;
    p.lastUpdated = DateTime.now();
    await p.save();
  }

  Future<void> recordRebalanceActed() async {
    final p = getOrCreateProfile();
    p.rebalanceActedCount++;
    p.lastUpdated = DateTime.now();
    await p.save();
  }

  // ── Feature 5: Decision Half-Life ─────────────────────────────────────────

  int decisionAgeDays(String symbol, DateTime buyDate) =>
      DateTime.now().difference(buyDate).inDays;

  String halfLifeLabel(int ageDays) {
    if (ageDays < 30)  return 'Fresh — still relevant';
    if (ageDays < 90)  return 'Aging — worth reviewing';
    if (ageDays < 180) return 'Stale — market has changed';
    return 'Very old — re-evaluate your thesis';
  }

  double halfLifeScore(int ageDays) =>
      (0.5 * (90 / (ageDays + 1))).clamp(0.0, 1.0);

  // ── Attention summary helpers ──────────────────────────────────────────────

  /// Total seconds spent viewing a specific symbol
  int totalSecondsForSymbol(String symbol) {
    int total = 0;
    for (final AttentionLogModel log in _attention.values) {
      if (log.symbol == symbol) {
        total += log.durationSeconds;
      }
    }
    return total;
  }

  /// How many times a symbol was viewed
  int viewCountForSymbol(String symbol) =>
      _attention.values
          .where((AttentionLogModel l) => l.symbol == symbol)
          .length;

  /// All symbols viewed, deduplicated
  List<String> allViewedSymbols() =>
      _attention.values
          .map((AttentionLogModel l) => l.symbol)
          .toSet()
          .toList();
}