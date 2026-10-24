import 'package:flutter/foundation.dart';
import 'package:no5ocial/core/config/env_config.dart';

/// Configuration for AppLovin MAX Mediation and Demand Partners.
/// Aggregates real-time bidding demand from Google AdMob, Meta Audience Network,
/// and Unity Ads for maximum eCPMs, alongside Tapjoy and ironSource Offerwalls.
class MonetizationConfig {
  /// AppLovin MAX SDK Key (retrieved securely from environment)
  static String get appLovinSdkKey =>
      EnvConfig.get('APPLOVIN_SDK_KEY', fallback: 'max_demo_sdk_key_shaadow_corp');

  /// AppLovin MAX Rewarded Ad Unit ID (Android)
  static String get rewardedAdUnitId =>
      EnvConfig.get('APPLOVIN_REWARDED_AD_UNIT_ID', fallback: 'max_rewarded_daypass_unit_01');

  // --- Real-Time Bidding Demand Partners ---

  /// Google AdMob Application ID (Configured in AndroidManifest)
  static String get admobAppId =>
      EnvConfig.get('ADMOB_APP_ID', fallback: 'ca-app-pub-7142385384774533~1890140979');

  /// Google AdMob Rewarded Bidding Unit ID
  static String get admobRewardedAdUnitId =>
      EnvConfig.get('ADMOB_REWARDED_AD_UNIT_ID', fallback: 'ca-app-pub-7142385384774533/7860652956');

  /// Meta Audience Network Placement ID
  static String get metaAudiencePlacementId =>
      EnvConfig.get('META_AUDIENCE_PLACEMENT_ID', fallback: 'VID_HD_16_9_15S_APP_INSTALL#YOUR_PLACEMENT_ID');

  /// Unity Ads Game ID (Android)
  static String get unityGameId =>
      EnvConfig.get('UNITY_ADS_GAME_ID', fallback: '1234567');

  /// Unity Ads Rewarded Placement ID
  static String get unityRewardedPlacementId =>
      EnvConfig.get('UNITY_REWARDED_PLACEMENT_ID', fallback: 'Rewarded_Android');

  // --- High-Payout Offerwall Partners (Micro-Task Completion) ---

  /// Tapjoy SDK Key
  static String get tapjoySdkKey =>
      EnvConfig.get('TAPJOY_SDK_KEY', fallback: 'tapjoy_sdk_key_production');

  /// Tapjoy Offerwall Placement Name
  static String get tapjoyPlacementName =>
      EnvConfig.get('TAPJOY_PLACEMENT_NAME', fallback: 'offerwall_no5ocial_tasks');

  /// ironSource App Key
  static String get ironSourceAppKey =>
      EnvConfig.get('IRONSOURCE_APP_KEY', fallback: 'ironsource_app_key_prod');

  /// Whether mediation test mode is active
  static bool get isTestMode =>
      EnvConfig.get('ADS_TEST_MODE', fallback: kDebugMode ? 'true' : 'false').toLowerCase() == 'true';

  /// Minimum expected eCPM threshold for RTB optimization
  static double get targetEcpmFloorUsd => 18.50; // High tier rewarded video eCPM floor
}
