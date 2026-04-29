class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Portfolio Tracker';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Cache durations
  static const Duration quoteCacheDuration = Duration(minutes: 5);
  static const Duration profileCacheDuration = Duration(hours: 24);
  static const Duration newsCacheDuration = Duration(minutes: 30);
  static const Duration timeSeriesCacheDuration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int newsPageSize = 10;

  // Behavioral thresholds
  static const int attentionBiasThresholdDays = 7;
  static const double silentWinnerThresholdPct = 5.0;
  static const int decisionReviewThresholdDays = 90;
  static const int impulsiveBuyThresholdSeconds = 120;

  // Portfolio
  static const double maxSectorConcentrationPct = 40.0;
  static const int maxHoldingsDisplay = 50;

  // Animation durations
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration longAnim = Duration(milliseconds: 700);

  // Hive box names
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String apiCacheBox = 'api_cache';
  static const String apiCacheMetaBox = 'api_cache_meta';
  static const String attentionLogsBox = 'attention_logs';
  static const String beliefLogsBox = 'belief_logs';
  static const String decisionEventsBox = 'decision_events';
  static const String behaviorProfileBox = 'behavior_profile';
}
