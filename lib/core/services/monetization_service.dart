import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/applovin_max_mediation_service.dart';
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
  bool _isInitialized = false;

  AccountPlanTier get currentPlan => _currentPlan;
  DayPassStatus get dayPassStatus => _dayPassStatus;
  DailyRewardCeiling get dailyCeiling => _dailyCeiling;
  int get offerwallCredits => _offerwallCredits;
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

      _isInitialized = true;
      notifyListeners();
      debugPrint('MonetizationService: Initialized with plan ${_currentPlan.displayName}, Day Pass active: ${_dayPassStatus.isActive}');
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
    return AudienceSegmentation.shouldDisplayAds(
      workspaceMode: workspaceMode,
      memberCount: memberCount,
      planTier: _currentPlan,
    );
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

  /// Evaluates whether the user can schedule a post right now or if a system bottleneck is hit.
  ({bool canSchedule, SystemBottleneckType? bottleneck}) evaluateSchedulingAccess({
    required WorkspaceMode workspaceMode,
    required int memberCount,
  }) {
    // 1. Multi-person company check: If collaborating on a team, enforce B2B subscription
    final isTeam = isMultiPersonCompany(workspaceMode: workspaceMode, memberCount: memberCount);
    if (isTeam && !_currentPlan.isB2B) {
      return (canSchedule: false, bottleneck: SystemBottleneckType.teamSeatExpansion);
    }

    // 2. Paid individual tier (Solo Pro) or B2B: Unlimited scheduling, zero bottlenecks
    if (_currentPlan.isPaid) {
      return (canSchedule: true, bottleneck: null);
    }

    // 3. Free D2C Tier: Anti-bot daily post ceiling check
    if (_dailyCeiling.hasReachedScheduledPostCeiling) {
      return (canSchedule: false, bottleneck: SystemBottleneckType.dailyPostCeilingReached);
    }

    // 4. Free D2C Tier: Day Pass check
    if (!_dayPassStatus.isActive) {
      return (canSchedule: false, bottleneck: SystemBottleneckType.dayPassExpired);
    }

    // Day Pass is active and under daily limit
    return (canSchedule: true, bottleneck: null);
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
}
