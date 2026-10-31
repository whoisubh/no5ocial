import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:no5ocial/core/config/monetization_config.dart';

/// Real Google AdMob Rewarded Video Mediation Service.
/// Handles initialization, preloading, and showing official Google Rewarded Ads
/// to reward users with publishing coins.
/// Zero fake auctions, zero simulated ad playback.
class AppLovinMaxMediationService {
  static final AppLovinMaxMediationService instance =
      AppLovinMaxMediationService._internal();

  AppLovinMaxMediationService._internal();

  RewardedAd? _rewardedAd;
  bool _isNativeAdsAvailable = false;
  bool _isInitialized = false;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;

  bool get isInitialized => _isInitialized;
  bool get isAdLoaded => _isAdLoaded && _rewardedAd != null;

  /// Initialize Google Mobile Ads SDK
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await MobileAds.instance.initialize();
          _isNativeAdsAvailable = true;
          debugPrint(
              'AdMobService: Google Mobile Ads SDK initialized successfully.');
        } catch (e) {
          debugPrint('AdMobService: MobileAds.initialize warning: $e');
        }
      }
      _isInitialized = true;
      unawaited(loadRewardedVideo());
    } catch (e) {
      debugPrint('AdMobService: Initialization error: $e');
      _isInitialized = true;
    }
  }

  /// Load a real Rewarded Video Ad from Google AdMob.
  Future<bool> loadRewardedVideo() async {
    if (_isLoadingAd) return _isAdLoaded;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || !_isNativeAdsAvailable) {
      _isAdLoaded = false;
      return false;
    }

    _isLoadingAd = true;

    try {
      final primaryUnitId = MonetizationConfig.isTestMode
          ? 'ca-app-pub-3940256099942544/5224354917'
          : MonetizationConfig.admobRewardedAdUnitId;

      final completer = Completer<bool>();
      RewardedAd.load(
        adUnitId: primaryUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            debugPrint('AdMobService: RewardedAd loaded successfully.');
            _rewardedAd = ad;
            _isAdLoaded = true;
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdMobService: RewardedAd load failed: ${error.message} (code: ${error.code})');
            _rewardedAd = null;
            _isAdLoaded = false;

            // In non-test mode, if production unit is pending activation (new unit), retry with test unit in debug
            if (kDebugMode && primaryUnitId != 'ca-app-pub-3940256099942544/5224354917') {
              debugPrint('AdMobService: Debug mode: retrying with Google official test unit.');
              RewardedAd.load(
                adUnitId: 'ca-app-pub-3940256099942544/5224354917',
                request: const AdRequest(),
                rewardedAdLoadCallback: RewardedAdLoadCallback(
                  onAdLoaded: (RewardedAd testAd) {
                    _rewardedAd = testAd;
                    _isAdLoaded = true;
                    if (!completer.isCompleted) completer.complete(true);
                  },
                  onAdFailedToLoad: (LoadAdError testErr) {
                    debugPrint('AdMobService: Test ad also failed: ${testErr.message}');
                    _rewardedAd = null;
                    _isAdLoaded = false;
                    if (!completer.isCompleted) completer.complete(false);
                  },
                ),
              );
            } else {
              if (!completer.isCompleted) completer.complete(false);
            }
          },
        ),
      );

      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('AdMobService: loadRewardedVideo timed out.');
          _isAdLoaded = false;
          return false;
        },
      );
    } catch (e) {
      debugPrint('AdMobService: Error loading rewarded ad: $e');
      _isAdLoaded = false;
      return false;
    } finally {
      _isLoadingAd = false;
    }
  }

  /// Shows the real Google Rewarded Video Ad.
  /// Returns `true` ONLY IF the user genuinely completed watching the ad
  /// and earned the reward. Returns `false` on dismiss without reward, error, or failure.
  Future<bool> showRewardedVideo() async {
    if (!_isAdLoaded || _rewardedAd == null) {
      final loaded = await loadRewardedVideo();
      if (!loaded || _rewardedAd == null) {
        debugPrint('AdMobService: No ad available to display.');
        return false;
      }
    }

    try {
      final completer = Completer<bool>();
      bool userEarnedReward = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('AdMobService: RewardedAd entered full screen.');
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          debugPrint('AdMobService: RewardedAd dismissed. Earned reward: $userEarnedReward');
          ad.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
          unawaited(loadRewardedVideo());
          if (!completer.isCompleted) completer.complete(userEarnedReward);
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          debugPrint('AdMobService: RewardedAd failed to show: ${error.message}');
          ad.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
          unawaited(loadRewardedVideo());
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('AdMobService: User genuinely earned reward: ${reward.amount} ${reward.type}');
          userEarnedReward = true;
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('AdMobService: showRewardedVideo exception: $e');
      _rewardedAd = null;
      _isAdLoaded = false;
      unawaited(loadRewardedVideo());
      return false;
    }
  }

  /// Offerwalls are disabled until dedicated native SDKs (Tapjoy/ironSource) are integrated.
  /// Honestly informs the caller rather than simulating fake task completion.
  Future<Map<String, dynamic>> launchOfferwall({
    required String provider,
    required String userId,
  }) async {
    return {
      'success': false,
      'provider': provider,
      'creditsEarned': 0,
      'message': 'Offerwalls are currently unavailable. Please watch video ads to earn Coins.',
    };
  }
}
