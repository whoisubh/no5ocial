import 'package:flutter/foundation.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';

/// Available account plan tiers in no5ocial.
enum AccountPlanTier {
  soloFree,
  soloPro,
  b2bTeam,
  b2bEnterprise;

  String get displayName {
    switch (this) {
      case AccountPlanTier.soloFree:
        return 'Solo Free';
      case AccountPlanTier.soloPro:
        return 'Solo Pro';
      case AccountPlanTier.b2bTeam:
        return 'B2B Team';
      case AccountPlanTier.b2bEnterprise:
        return 'Enterprise';
    }
  }

  bool get isPaid => this != AccountPlanTier.soloFree;

  bool get isB2B => this == AccountPlanTier.b2bTeam || this == AccountPlanTier.b2bEnterprise;

  static AccountPlanTier fromString(String? value) {
    if (value == null) return AccountPlanTier.soloFree;
    return AccountPlanTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AccountPlanTier.soloFree,
    );
  }
}

/// Strict Audience Segmentation Logic
/// Completely hides all ad placements from multi-person companies to preserve corporate credibility
/// and enforces a pure premium subscription model for them.
class AudienceSegmentation {
  /// Determines if a workspace is a multi-person company / corporate team.
  static bool isMultiPersonCompany({
    required WorkspaceMode workspaceMode,
    required int memberCount,
    required AccountPlanTier planTier,
  }) {
    // 1. Explicit team workspace mode
    if (workspaceMode.isTeam) return true;

    // 2. Multi-member organization (more than 1 person)
    if (memberCount > 1) return true;

    // 3. Registered under a B2B corporate tier
    if (planTier.isB2B) return true;

    return false;
  }

  /// Determines whether any ad placements, banners, or rewarded video flows
  /// should be rendered in the application UI.
  ///
  /// CRITICAL RULE:
  /// Completely hides ALL ads from multi-person companies (corporate credibility)
  /// and from any paid subscribers (Solo Pro, B2B Team, Enterprise).
  static bool shouldDisplayAds({
    required WorkspaceMode workspaceMode,
    required int memberCount,
    required AccountPlanTier planTier,
  }) {
    // Hide from multi-person companies
    if (isMultiPersonCompany(
      workspaceMode: workspaceMode,
      memberCount: memberCount,
      planTier: planTier,
    )) {
      return false;
    }

    // Hide from paid individual subscribers
    if (planTier.isPaid) {
      return false;
    }

    // Only solo creators on the free tier see ad/reward opportunities
    return true;
  }
}

/// Day Pass Status for Solo Creators / D2C Users.
/// Watching a capped sequence of videos unlocks a full 24 hours of standard scheduling
/// without interrupting the creator's publishing workflows.
@immutable
class DayPassStatus {
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final int videosWatchedInSequence;

  /// Capped sequence threshold to unlock a Day Pass (e.g. 3 videos)
  static const int requiredVideosInSequence = 3;

  /// Duration of a granted Day Pass
  static const Duration passDuration = Duration(hours: 24);

  const DayPassStatus({
    this.activatedAt,
    this.expiresAt,
    this.videosWatchedInSequence = 0,
  });

  /// Check if the 24-hour pass is currently active.
  bool get isActive {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isBefore(expiresAt!);
  }

  /// Remaining duration of the active day pass.
  Duration get remainingTime {
    if (!isActive || expiresAt == null) return Duration.zero;
    return expiresAt!.difference(DateTime.now().toUtc());
  }

  /// Formatted string for UI display (e.g. "18h 42m remaining")
  String get remainingTimeString {
    final rem = remainingTime;
    if (rem.inMinutes <= 0) return 'Expired';
    final hours = rem.inHours;
    final mins = rem.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${mins}m remaining';
    }
    return '${mins}m remaining';
  }

  /// Whether the user has watched the required videos to unlock the next pass.
  bool get isSequenceComplete => videosWatchedInSequence >= requiredVideosInSequence;

  /// Progress ratio towards next unlock (0.0 to 1.0)
  double get sequenceProgress => (videosWatchedInSequence / requiredVideosInSequence).clamp(0.0, 1.0);

  DayPassStatus copyWith({
    DateTime? activatedAt,
    DateTime? expiresAt,
    int? videosWatchedInSequence,
  }) {
    return DayPassStatus(
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      videosWatchedInSequence: videosWatchedInSequence ?? this.videosWatchedInSequence,
    );
  }

  Map<String, dynamic> toJson() => {
        'activatedAt': activatedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'videosWatchedInSequence': videosWatchedInSequence,
      };

  factory DayPassStatus.fromJson(Map<String, dynamic> json) {
    return DayPassStatus(
      activatedAt: json['activatedAt'] != null ? DateTime.tryParse(json['activatedAt'])?.toUtc() : null,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'])?.toUtc() : null,
      videosWatchedInSequence: json['videosWatchedInSequence'] as int? ?? 0,
    );
  }
}

/// Hardcoded Daily Reward Ceiling for free-tier accounts.
/// Protects backend server infrastructure and API resources from automated
/// or high-volume usage, preventing abuse of free scheduling and third-party platform quotas.
@immutable
class DailyRewardCeiling {
  final String dateKeyUtc; // YYYY-MM-DD
  final int dayPassesUnlockedToday;
  final int offerwallCreditsEarnedToday;
  final int scheduledPostsToday;

  /// Hardcoded Ceilings for Free-Tier Safeguards
  static const int maxDayPassesPerDay = 1; // Exactly 1 24h pass per calendar day
  static const int maxOfferwallCreditsPerDay = 50; // Max 50 micro-task credits per day
  static const int maxFreeScheduledPostsPerDay = 10; // Anti-bot rate limiter for free tier

  const DailyRewardCeiling({
    required this.dateKeyUtc,
    this.dayPassesUnlockedToday = 0,
    this.offerwallCreditsEarnedToday = 0,
    this.scheduledPostsToday = 0,
  });

  /// Factory for today's date key in UTC
  factory DailyRewardCeiling.today() {
    final now = DateTime.now().toUtc();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return DailyRewardCeiling(dateKeyUtc: key);
  }

  bool get hasReachedDayPassLimit => dayPassesUnlockedToday >= maxDayPassesPerDay;

  bool get hasReachedOfferwallLimit => offerwallCreditsEarnedToday >= maxOfferwallCreditsPerDay;

  bool get hasReachedScheduledPostCeiling => scheduledPostsToday >= maxFreeScheduledPostsPerDay;

  DailyRewardCeiling copyWith({
    String? dateKeyUtc,
    int? dayPassesUnlockedToday,
    int? offerwallCreditsEarnedToday,
    int? scheduledPostsToday,
  }) {
    return DailyRewardCeiling(
      dateKeyUtc: dateKeyUtc ?? this.dateKeyUtc,
      dayPassesUnlockedToday: dayPassesUnlockedToday ?? this.dayPassesUnlockedToday,
      offerwallCreditsEarnedToday: offerwallCreditsEarnedToday ?? this.offerwallCreditsEarnedToday,
      scheduledPostsToday: scheduledPostsToday ?? this.scheduledPostsToday,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKeyUtc': dateKeyUtc,
        'dayPassesUnlockedToday': dayPassesUnlockedToday,
        'offerwallCreditsEarnedToday': offerwallCreditsEarnedToday,
        'scheduledPostsToday': scheduledPostsToday,
      };

  factory DailyRewardCeiling.fromJson(Map<String, dynamic> json) {
    return DailyRewardCeiling(
      dateKeyUtc: json['dateKeyUtc'] as String? ?? DailyRewardCeiling.today().dateKeyUtc,
      dayPassesUnlockedToday: json['dayPassesUnlockedToday'] as int? ?? 0,
      offerwallCreditsEarnedToday: json['offerwallCreditsEarnedToday'] as int? ?? 0,
      scheduledPostsToday: json['scheduledPostsToday'] as int? ?? 0,
    );
  }
}

/// Identifies the system bottleneck prompting an upgrade modal.
enum SystemBottleneckType {
  dayPassExpired,
  dailyPostCeilingReached,
  dailyRewardCeilingReached,
  teamSeatExpansion,
  bulkPlatformPublishing;

  String get title {
    switch (this) {
      case SystemBottleneckType.dayPassExpired:
        return 'Day Pass Expired';
      case SystemBottleneckType.dailyPostCeilingReached:
        return 'Daily Free Scheduling Ceiling Reached';
      case SystemBottleneckType.dailyRewardCeilingReached:
        return 'Daily Reward Limit Reached';
      case SystemBottleneckType.teamSeatExpansion:
        return 'Multi-Person Company Detected';
      case SystemBottleneckType.bulkPlatformPublishing:
        return 'High Volume Multi-Platform Queue';
    }
  }

  String get description {
    switch (this) {
      case SystemBottleneckType.dayPassExpired:
        return 'Your 24-hour Day Pass has concluded. Watch a quick 3-video sequence to re-activate, complete a micro-task, or upgrade to Solo Pro for uninterrupted lifetime scheduling.';
      case SystemBottleneckType.dailyPostCeilingReached:
        return 'To protect infrastructure resources and API quotas against automated abuse, free accounts are limited to 10 scheduled posts/day. Upgrade to Solo Pro for unlimited queue capacity.';
      case SystemBottleneckType.dailyRewardCeilingReached:
        return 'You have reached today\'s reward ceiling for free accounts. Reset occurs at 00:00 UTC, or upgrade to bypass all reward loops.';
      case SystemBottleneckType.teamSeatExpansion:
        return 'Collaborating with team members requires a B2B Team subscription to preserve corporate credibility and unlock approval workflows without advertising.';
      case SystemBottleneckType.bulkPlatformPublishing:
        return 'Publishing across multiple simultaneous channels requires higher concurrency limits available on paid tiers.';
    }
  }
}
