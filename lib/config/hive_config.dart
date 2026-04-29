
// lib/config/hive_config.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/behavioral/attention_log_model.dart';
import '../data/models/behavioral/belief_log_model.dart';
import '../data/models/behavioral/decision_event_model.dart';
import '../data/models/behavioral/behavior_profile_model.dart';

class HiveConfig {
  HiveConfig._();

  // ── Box names ──────────────────────────────────────────────────────────────
  static const String holdingsBox        = 'holdings';
  static const String portfolioBox       = 'portfolio';
  static const String stockCacheBox      = 'stock_cache';
  static const String newsCacheBox       = 'news_cache';
  static const String chatHistoryBox     = 'chat_history';
  static const String userPrefsBox       = 'user_prefs';
  static const String apiCacheBox        = 'api_cache';
  static const String apiCacheMetaBox    = 'api_cache_meta';
  static const String bankAccountsBox    = 'bank_accounts';
  static const String transactionsBox    = 'transactions';

  // ── Behavioral boxes ───────────────────────────────────────────────────────
  static const String attentionLogsBox   = 'attention_logs';
  static const String beliefLogsBox      = 'belief_logs';
  static const String decisionEventsBox  = 'decision_events';
  static const String behaviorProfileBox = 'behavior_profile';

  // ── Initialize everything ──────────────────────────────────────────────────

  static Future<void> init() async {
    // 1. Initialize Hive with Flutter path
    await Hive.initFlutter();

    // 2. Register all adapters
    _registerAdapters();

    // 3. Open all boxes
    await _openBoxes();
  }

  // ── Register adapters ──────────────────────────────────────────────────────

  static void _registerAdapters() {
    // Behavioral adapters — typeIds 20–23
    // Guard with isAdapterRegistered to survive hot restart
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(AttentionLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(BeliefLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(DecisionEventModelAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(BehaviorProfileModelAdapter());
    }
  }

  // ── Open boxes ─────────────────────────────────────────────────────────────

  static Future<void> _openBoxes() async {
    // Core app boxes
    await _safeOpen(holdingsBox);
    await _safeOpen(portfolioBox);
    await _safeOpen(stockCacheBox);
    await _safeOpen(newsCacheBox);
    await _safeOpen(chatHistoryBox);
    await _safeOpen(userPrefsBox);
    await _safeOpen(apiCacheBox);
    await _safeOpen(apiCacheMetaBox);
    await _safeOpen(bankAccountsBox);
    await _safeOpen(transactionsBox);

    // Behavioral boxes — typed
    await _safeOpenTyped<AttentionLogModel>(attentionLogsBox);
    await _safeOpenTyped<BeliefLogModel>(beliefLogsBox);
    await _safeOpenTyped<DecisionEventModel>(decisionEventsBox);
    await _safeOpenTyped<BehaviorProfileModel>(behaviorProfileBox);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Opens a dynamic box safely — skips if already open
  static Future<void> _safeOpen(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox(name);
    }
  }

  /// Opens a typed box safely — skips if already open
  static Future<void> _safeOpenTyped<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
  }

  // ── Box accessors ──────────────────────────────────────────────────────────
  // Use these everywhere instead of Hive.box() directly

  static Box get holdings        => Hive.box(holdingsBox);
  static Box get portfolio       => Hive.box(portfolioBox);
  static Box get stockCache      => Hive.box(stockCacheBox);
  static Box get newsCache       => Hive.box(newsCacheBox);
  static Box get chatHistory     => Hive.box(chatHistoryBox);
  static Box get userPrefs       => Hive.box(userPrefsBox);
  static Box get apiCache        => Hive.box(apiCacheBox);
  static Box get apiCacheMeta    => Hive.box(apiCacheMetaBox);

  static Box<AttentionLogModel>  get attentionLogs   =>
      Hive.box<AttentionLogModel>(attentionLogsBox);
  static Box<BeliefLogModel>     get beliefLogs      =>
      Hive.box<BeliefLogModel>(beliefLogsBox);
  static Box<DecisionEventModel> get decisionEvents  =>
      Hive.box<DecisionEventModel>(decisionEventsBox);
  static Box<BehaviorProfileModel> get behaviorProfile =>
      Hive.box<BehaviorProfileModel>(behaviorProfileBox);

  // ── User preferences helpers ───────────────────────────────────────────────

  static T? getPref<T>(String key) =>
      Hive.box(userPrefsBox).get(key) as T?;

  static Future<void> setPref<T>(String key, T value) =>
      Hive.box(userPrefsBox).put(key, value);

  // Common prefs
  static bool get isDarkMode =>
      getPref<bool>('dark_mode') ?? true;

  static Future<void> setDarkMode(bool value) =>
      setPref('dark_mode', value);

  static bool get isFirstTime =>
      getPref<bool>('is_first_time') ?? true;

  static Future<void> setFirstTime(bool value) =>
      setPref('is_first_time', value);

  static String get currency =>
      getPref<String>('currency') ?? 'INR';

  static Future<void> setCurrency(String value) =>
      setPref('currency', value);

  static String get statedRiskTolerance =>
      getPref<String>('risk_tolerance') ?? 'medium';

  static Future<void> setRiskTolerance(String value) =>
      setPref('risk_tolerance', value);

  static String get investingStyle =>
      getPref<String>('investing_style') ?? 'unknown';

  static Future<void> setInvestingStyle(String value) =>
      setPref('investing_style', value);

  // ── Clear all data (logout / reset) ───────────────────────────────────────

  static Future<void> clearAll() async {
    await Hive.box(holdingsBox).clear();
    await Hive.box(portfolioBox).clear();
    await Hive.box(stockCacheBox).clear();
    await Hive.box(newsCacheBox).clear();
    await Hive.box(chatHistoryBox).clear();
    await Hive.box(userPrefsBox).clear();
    await Hive.box(apiCacheBox).clear();
    await Hive.box(apiCacheMetaBox).clear();
    await Hive.box<AttentionLogModel>(attentionLogsBox).clear();
    await Hive.box<BeliefLogModel>(beliefLogsBox).clear();
    await Hive.box<DecisionEventModel>(decisionEventsBox).clear();
    await Hive.box<BehaviorProfileModel>(behaviorProfileBox).clear();
  }

  /// Clear only cache boxes — keeps holdings and behavioral data
  static Future<void> clearCache() async {
    await Hive.box(stockCacheBox).clear();
    await Hive.box(newsCacheBox).clear();
    await Hive.box(apiCacheBox).clear();
    await Hive.box(apiCacheMetaBox).clear();
  }
}