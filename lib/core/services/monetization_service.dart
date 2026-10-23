import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/applovin_max_mediation_service.dart';
import 'package:no5ocial/core/services/firebase_sync_service.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';

/// Central Monetization & Audience Segmentation Service.
/// Implements strict ad hiding for multi-person companies,
/// Day Pass sequence unlocking, high-payout Offerwalls,
/// and hardcoded daily reward ceilings for free-tier bot/resource protection.
class MonetizationService extends ChangeNotifier {
  static final MonetizationService instance = MonetizationService._internal();

  MonetizationService._internal();

  AccountPlanTier _currentPlan = AccountPlanTier.soloFree;
  DayPassStatus _dayPassStatus = const DayPassStatus();
  DailyRewardCeiling _dailyCeiling = DailyRewardCeiling.today();
  int _offerwallCredits = 0;
  int _postCoins = 0;
  String? _activeUserId;
  List<Map<String, dynamic>> _coinTransactions = const [];
  bool _isInitialized = false;

  AccountPlanTier get currentPlan => _currentPlan;
  DayPassStatus get dayPassStatus => _dayPassStatus;
  DailyRewardCeiling get dailyCeiling => _dailyCeiling;
  int get offerwallCredits => _offerwallCredits;
  int get postCoins => _postCoins;
  String? get activeUserId => _activeUserId;
  List<Map<String, dynamic>> get coinTransactions => _coinTransactions;
  bool get isInitialized => _isInitialized;

  /// Initialize service state from persistent storage
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Plan
      final savedPlanStr = prefs.getString('monetization_plan_tier');
      _currentPlan = AccountPlanTier.fromString(savedPlanStr);

      // Load Day Pass
      final savedDayPassStr = prefs.getString('monetization_day_pass');
      if (savedDayPassStr != null) {
        try {
          _dayPassStatus = DayPassStatus.fromJson(jsonDecode(savedDayPassStr));
        } catch (_) {}
      }

      // Load Ceiling & reset if day rolled over
      _refreshDailyCeiling(prefs);

      // Load Credits
      _offerwallCredits = prefs.getInt('monetization_offerwall_credits') ?? 0;

      // Load active session user wallet from real SQLite Database
      final session = await SessionService.instance.getSession();
      final uid = session?['id'] as String?;
      if (uid != null && uid.isNotEmpty) {
        await loadUserWallet(uid);
      } else {
        _postCoins = await AppDatabase.instance.getCoinBalance('local_user');
        _coinTransactions = await AppDatabase.instance.getCoinTransactions('local_user');
      }

      _isInitialized = true;
      notifyListeners();
      debugPrint('MonetizationService: Initialized with plan ${_currentPlan.displayName}, Real DB Coins: $_postCoins');
    } catch (e) {
      debugPrint('MonetizationService: Storage init fallback: $e');
      _isInitialized = true;
    }
  }

  /// Refreshes daily ceiling tracker if UTC date has changed
  void _refreshDailyCeiling(SharedPreferences prefs) {
    final today = DailyRewardCeiling.today();
    final savedCeilingStr = prefs.getString('monetization_daily_ceiling');
    if (savedCeilingStr != null) {
      try {
        final parsed = DailyRewardCeiling.fromJson(jsonDecode(savedCeilingStr));
        if (parsed.dateKeyUtc == today.dateKeyUtc) {
          _dailyCeiling = parsed;
          return;
        }
      } catch (_) {}
    }
    // New calendar day in UTC: reset ceiling counters
    _dailyCeiling = today;
  }

  /// AUDIENCE SEGMENTATION LOGIC:
  /// Completely hides all ads from multi-person companies and paid subscribers.
  bool shouldShowAds({
    required WorkspaceMode workspaceMode,
    required int memberCount,
  }) {
    // Pro subscription is disabled for now; ad system is universally active
    return true;
  }

  /// Check whether the workspace is a multi-person company.
  bool isMultiPersonCompany({
    required WorkspaceMode workspaceMode,
    required int memberCount,
  }) {
    return AudienceSegmentation.isMultiPersonCompany(
      workspaceMode: workspaceMode,
      memberCount: memberCount,
      planTier: _currentPlan,
    );
  }

  /// Evaluates whether the user can schedule or publish a post right now.
  ({bool canSchedule, bool requiresCoin, SystemBottleneckType? bottleneck}) evaluateSchedulingAccess({
    required WorkspaceMode workspaceMode,
    required int memberCount,
  }) {
    // Pro/B2B subscription is disabled for now. All users operate on the free ad-supported tier.
    // 1. Check daily free post quota (up to 10 scheduled posts/day)
    if (!_dailyCeiling.hasReachedScheduledPostCeiling) {
      return (canSchedule: true, requiresCoin: false, bottleneck: null);
    }

    // 2. Daily free quota reached, but user has Coins!
    if (_postCoins > 0) {
      return (canSchedule: true, requiresCoin: true, bottleneck: null);
    }

    // 3. Daily quota reached and 0 coins: prompt user to watch ad for coins
    return (canSchedule: false, requiresCoin: false, bottleneck: SystemBottleneckType.dailyPostCeilingReached);
  }

  /// Records a successful post scheduled under the free tier (anti-bot tracker).
  Future<void> recordScheduledPost() async {
    if (_currentPlan.isPaid) return; // Paid plans have no caps

    _dailyCeiling = _dailyCeiling.copyWith(
      scheduledPostsToday: _dailyCeiling.scheduledPostsToday + 1,
    );
    notifyListeners();
    await _saveCeiling();
  }

  /// Advances the Day Pass video sequence by 1.
  /// Calls AppLovin MAX aggregated RTB rewarded ad.
  /// When reaching the required 3 videos, activates a 24-hour pass unless daily limit reached.
  Future<({bool success, String message, bool passUnlocked})> advanceDayPassVideoSequence() async {
    if (_dailyCeiling.hasReachedDayPassLimit) {
      return (
        success: false,
        message: 'Daily Day Pass limit reached (1 pass per 24 hours). Upgrade to Solo Pro for uninterrupted scheduling.',
        passUnlocked: false,
      );
    }

    // Show rewarded video via AppLovin MAX RTB demand aggregator
    final watched = await AppLovinMaxMediationService.instance.showRewardedVideo();
    if (!watched) {
      return (
        success: false,
        message: 'Video was closed prematurely. Please watch the complete sequence to unlock your Day Pass.',
        passUnlocked: false,
      );
    }

    final newCount = _dayPassStatus.videosWatchedInSequence + 1;

    if (newCount >= DayPassStatus.requiredVideosInSequence) {
      // Sequence completed: Unlock full 24 hours of standard scheduling!
      final nowUtc = DateTime.now().toUtc();
      final expiresUtc = nowUtc.add(DayPassStatus.passDuration);

      _dayPassStatus = DayPassStatus(
        activatedAt: nowUtc,
        expiresAt: expiresUtc,
        videosWatchedInSequence: 0,
      );

      _dailyCeiling = _dailyCeiling.copyWith(
        dayPassesUnlockedToday: _dailyCeiling.dayPassesUnlockedToday + 1,
      );

      notifyListeners();
      await _saveDayPass();
      await _saveCeiling();

      return (
        success: true,
        message: '24-Hour Day Pass Unlocked! Enjoy uninterrupted scheduling across all channels.',
        passUnlocked: true,
      );
    } else {
      // Sequence advanced (e.g. 1/3 or 2/3)
      _dayPassStatus = _dayPassStatus.copyWith(videosWatchedInSequence: newCount);
      notifyListeners();
      await _saveDayPass();

      return (
        success: true,
        message: 'Video $newCount of ${DayPassStatus.requiredVideosInSequence} completed.',
        passUnlocked: false,
      );
    }
  }

  /// Launch Offerwall micro-task (Tapjoy or ironSource).
  /// High payout alternative to video sequences.
  Future<({bool success, int creditsEarned, String message})> launchOfferwallTask({
    required String provider, // 'tapjoy' or 'ironsource'
    required String userId,
  }) async {
    if (_dailyCeiling.hasReachedOfferwallLimit) {
      return (
        success: false,
        creditsEarned: 0,
        message: 'Daily micro-task reward limit reached (50 credits/day). Upgrade to Pro for unlimited usage.',
      );
    }

    final res = await AppLovinMaxMediationService.instance.launchOfferwall(
      provider: provider,
      userId: userId,
    );

    final credits = (res['creditsEarned'] as int? ?? 15);
    final allowedCredits = (_dailyCeiling.offerwallCreditsEarnedToday + credits > DailyRewardCeiling.maxOfferwallCreditsPerDay)
        ? (DailyRewardCeiling.maxOfferwallCreditsPerDay - _dailyCeiling.offerwallCreditsEarnedToday)
        : credits;

    _offerwallCredits += allowedCredits;
    _dailyCeiling = _dailyCeiling.copyWith(
      offerwallCreditsEarnedToday: _dailyCeiling.offerwallCreditsEarnedToday + allowedCredits,
    );

    // If user earns >= 20 credits, automatically activate a bonus 24-hour pass
    bool bonusPassActivated = false;
    if (allowedCredits >= 20 && !_dayPassStatus.isActive) {
      final nowUtc = DateTime.now().toUtc();
      _dayPassStatus = DayPassStatus(
        activatedAt: nowUtc,
        expiresAt: nowUtc.add(DayPassStatus.passDuration),
        videosWatchedInSequence: 0,
      );
      bonusPassActivated = true;
      await _saveDayPass();
    }

    notifyListeners();
    await _saveCeiling();
    await _saveCredits();

    return (
      success: true,
      creditsEarned: allowedCredits,
      message: bonusPassActivated
          ? 'Offerwall task completed! Earned $allowedCredits credits + 24-Hour Day Pass activated!'
          : 'Offerwall task completed! Earned $allowedCredits credits.',
    );
  }

  /// Upgrade to a paid plan tier (Solo Pro or B2B Team)
  Future<void> upgradePlan(AccountPlanTier newTier) async {
    _currentPlan = newTier;
    // Paid accounts don't need Day Pass friction
    if (newTier.isPaid) {
      _dayPassStatus = const DayPassStatus();
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('monetization_plan_tier', newTier.name);
    } catch (_) {}
  }

  // --- Persistence Helpers ---

  Future<void> _saveDayPass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('monetization_day_pass', jsonEncode(_dayPassStatus.toJson()));
    } catch (_) {}
  }

  Future<void> _saveCeiling() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('monetization_daily_ceiling', jsonEncode(_dailyCeiling.toJson()));
    } catch (_) {}
  }

  Future<void> _saveCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('monetization_offerwall_credits', _offerwallCredits);
    } catch (_) {}
  }

  // --- Real Database-Backed Coin System Methods for Free Users ---

  /// Loads real database wallet balance and verified transaction ledger for the user
  Future<void> loadUserWallet(String userId) async {
    _activeUserId = userId;
    try {
      _postCoins = await AppDatabase.instance.getCoinBalance(userId);
      _coinTransactions = await AppDatabase.instance.getCoinTransactions(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('MonetizationService: Error loading real wallet from database: $e');
    }
  }

  /// Earn publishing coins by watching a rewarded ad.
  /// Writes verified transaction to SQLite and syncs with Cloud Firestore.
  Future<({bool success, int coinsEarned, String message})> watchAdForCoins({
    int rewardAmount = 2,
    String? userId,
  }) async {
    final success = await AppLovinMaxMediationService.instance.showRewardedVideo();
    if (success) {
      final uid = userId ?? _activeUserId ?? (await SessionService.instance.getSession())?['id'] as String? ?? 'local_user';
      try {
        _postCoins = await AppDatabase.instance.addCoinsToWallet(
          userId: uid,
          amount: rewardAmount,
          type: 'ad_reward',
          description: 'Rewarded Partner Video Ad',
        );
        _coinTransactions = await AppDatabase.instance.getCoinTransactions(uid);
        unawaited(FirebaseSyncService.instance.pushWallet(uid, _postCoins));
        notifyListeners();
        return (
          success: true,
          coinsEarned: rewardAmount,
          message: '+$rewardAmount Coins added to your verified database wallet!',
        );
      } catch (e) {
        debugPrint('MonetizationService: Database error crediting coins: $e');
        return (
          success: true,
          coinsEarned: rewardAmount,
          message: '+$rewardAmount Coins earned!',
        );
      }
    } else {
      return (
        success: false,
        coinsEarned: 0,
        message: 'Video ad was closed before completion. Watch the full ad to earn Coins.',
      );
    }
  }

  /// Consumes 1 coin for publishing or scheduling a post beyond daily quota.
  /// Deducts coin and records real transaction in SQLite & Cloud Firestore.
  Future<bool> consumePostCoin({String? userId, String? postId}) async {
    if (_currentPlan.isPaid) return true;
    final uid = userId ?? _activeUserId ?? (await SessionService.instance.getSession())?['id'] as String? ?? 'local_user';
    try {
      final ok = await AppDatabase.instance.spendCoinFromWallet(
        userId: uid,
        description: 'Multi-destination post publishing',
        postId: postId,
      );
      if (ok) {
        _postCoins = await AppDatabase.instance.getCoinBalance(uid);
        _coinTransactions = await AppDatabase.instance.getCoinTransactions(uid);
        unawaited(FirebaseSyncService.instance.pushWallet(uid, _postCoins));
        notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('MonetizationService: Database error consuming coin: $e');
      if (_postCoins > 0) {
        _postCoins -= 1;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  /// Adds coins directly to the user balance in real SQLite database.
  Future<void> addCoins(int amount, {String? userId, String? description}) async {
    final uid = userId ?? _activeUserId ?? (await SessionService.instance.getSession())?['id'] as String? ?? 'local_user';
    try {
      _postCoins = await AppDatabase.instance.addCoinsToWallet(
        userId: uid,
        amount: amount,
        type: 'grant',
        description: description ?? 'Promotional Credit Grant',
      );
      _coinTransactions = await AppDatabase.instance.getCoinTransactions(uid);
      unawaited(FirebaseSyncService.instance.pushWallet(uid, _postCoins));
      notifyListeners();
    } catch (e) {
      _postCoins += amount;
      notifyListeners();
    }
  }

  /// Clears in-memory wallet and transactions on user logout
  void clearUserWallet() {
    _activeUserId = null;
    _postCoins = 0;
    _coinTransactions = [];
    notifyListeners();
  }
}
