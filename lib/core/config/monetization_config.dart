import 'package:flutter/foundation.dart';
import 'package:no5ocial/core/config/env_config.dart';

/// Configuration for Google Mobile Ads & Monetization.
/// Uses official Google AdMob IDs and environment configurations.
/// Zero fake placeholders, zero dummy credentials.
class MonetizationConfig {
  /// Google AdMob Application ID
  static String get admobAppId =>
      EnvConfig.get('ADMOB_APP_ID', fallback: 'ca-app-pub-7142385384774533~1890140979');

  /// Google AdMob Rewarded Video Unit ID
  static String get admobRewardedAdUnitId =>
      EnvConfig.get('ADMOB_REWARDED_AD_UNIT_ID', fallback: 'ca-app-pub-7142385384774533/7860652956');

  /// Whether ads test mode is active (defaults to true in debug mode to protect publisher accounts from invalid traffic)
  static bool get isTestMode =>
      EnvConfig.get('ADS_TEST_MODE', fallback: kDebugMode ? 'true' : 'false').toLowerCase() == 'true';
}
