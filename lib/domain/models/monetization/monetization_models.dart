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

/// Identifies the plan limit prompting an upgrade modal.
enum SystemBottleneckType {
  dayPassExpired,
  dailyPostCeilingReached,
  dailyRewardCeilingReached,
  teamSeatExpansion,
  bulkPlatformPublishing;

  String get title {
    switch (this) {
      case SystemBottleneckType.dayPassExpired:
        return 'Daily Plan Quota';
      case SystemBottleneckType.dailyPostCeilingReached:
        return 'Daily Post Limit Reached';
      case SystemBottleneckType.dailyRewardCeilingReached:
        return 'Daily Limit Reached';
      case SystemBottleneckType.teamSeatExpansion:
        return 'Team Collaboration';
      case SystemBottleneckType.bulkPlatformPublishing:
        return 'Multi-Channel Publishing';
    }
  }

  String get description {
    switch (this) {
      case SystemBottleneckType.dayPassExpired:
        return 'Upgrade to Solo Pro or Team Workspace for unlimited scheduled posts and full queue management.';
      case SystemBottleneckType.dailyPostCeilingReached:
        return 'Free accounts include up to 10 scheduled posts per day. Upgrade to Solo Pro for unlimited daily scheduling.';
      case SystemBottleneckType.dailyRewardCeilingReached:
        return 'You have reached today\'s daily post limit on the Free plan. Upgrade to Solo Pro for unlimited scheduling.';
      case SystemBottleneckType.teamSeatExpansion:
        return 'Collaborating with team members is available on our Team Workspace and Enterprise plans. Upgrade to invite colleagues and manage roles.';
      case SystemBottleneckType.bulkPlatformPublishing:
        return 'Publishing across multiple simultaneous channels is optimized on Solo Pro and Team plans.';
    }
  }
}

/// 2-Day Publishing Pass (10 Coins = 2 Posts over 2 Days)
/// Stored in local SQLite and synced to Firebase Cloud Firestore.
@immutable
class PublishingPass {
  final String id;
  final String userId;
  final int costCoins; // default 10
  final int maxPosts; // default 2
  final int postsUsed; // default 0
  final int durationDays; // default 2
  final DateTime activatedAt;
  final DateTime expiresAt;
  final bool isActive;

  const PublishingPass({
    required this.id,
    required this.userId,
    this.costCoins = 10,
    this.maxPosts = 2,
    this.postsUsed = 0,
    this.durationDays = 2,
    required this.activatedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  int get postsRemaining => (maxPosts - postsUsed).clamp(0, maxPosts);
  bool get hasPostsRemaining => postsRemaining > 0;
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired && hasPostsRemaining;

  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now().toUtc());
  }

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

  PublishingPass copyWith({
    String? id,
    String? userId,
    int? costCoins,
    int? maxPosts,
    int? postsUsed,
    int? durationDays,
    DateTime? activatedAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return PublishingPass(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      costCoins: costCoins ?? this.costCoins,
      maxPosts: maxPosts ?? this.maxPosts,
      postsUsed: postsUsed ?? this.postsUsed,
      durationDays: durationDays ?? this.durationDays,
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'cost_coins': costCoins,
        'max_posts': maxPosts,
        'posts_used': postsUsed,
        'posts_remaining': postsRemaining,
        'duration_days': durationDays,
        'activated_at_utc': activatedAt.toUtc().toIso8601String(),
        'expires_at_utc': expiresAt.toUtc().toIso8601String(),
        'is_active': isActive,
        'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
      };

  factory PublishingPass.fromJson(Map<String, dynamic> json) {
    final activated = DateTime.tryParse(json['activated_at_utc']?.toString() ?? json['activatedAt']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc();
    final duration = json['duration_days'] as int? ?? json['durationDays'] as int? ?? 2;
    final expires = DateTime.tryParse(json['expires_at_utc']?.toString() ?? json['expiresAt']?.toString() ?? '')?.toUtc() ?? activated.add(Duration(days: duration));

    return PublishingPass(
      id: json['id'] as String? ?? 'pass_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      costCoins: json['cost_coins'] as int? ?? json['costCoins'] as int? ?? 10,
      maxPosts: json['max_posts'] as int? ?? json['maxPosts'] as int? ?? 2,
      postsUsed: json['posts_used'] as int? ?? json['postsUsed'] as int? ?? 0,
      durationDays: duration,
      activatedAt: activated,
      expiresAt: expires,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['isActive'] == true,
    );
  }
}

/// Evaluation result for composer publish/schedule action
@immutable
class PublishingAccessResult {
  final bool canPublish;
  final bool canActivatePass;
  final bool requiresCoins;
  final int coinsNeeded;
  final String message;
  final PublishingPass? activePass;

  const PublishingAccessResult({
    required this.canPublish,
    this.canActivatePass = false,
    this.requiresCoins = false,
    this.coinsNeeded = 0,
    required this.message,
    this.activePass,
  });
}
