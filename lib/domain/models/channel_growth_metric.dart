import '../enums/platform_type.dart';

/// Represents a historical or current snapshot of growth metrics for a connected social channel.
class ChannelGrowthMetric {
  final String accountId;
  final PlatformType platform;
  final String accountName;
  final String handle;
  final String? avatarUrl;
  final int followersCount;
  final int previousFollowersCount;
  final int totalPostsCount;
  final int totalViewsCount;
  final int engagementCount;
  final DateTime lastUpdated;
  final List<MetricHistoryPoint> history;

  const ChannelGrowthMetric({
    required this.accountId,
    required this.platform,
    required this.accountName,
    required this.handle,
    this.avatarUrl,
    required this.followersCount,
    this.previousFollowersCount = 0,
    required this.totalPostsCount,
    required this.totalViewsCount,
    this.engagementCount = 0,
    required this.lastUpdated,
    this.history = const [],
  });

  /// Net follower delta since previous recorded snapshot
  int get netFollowerGain => followersCount - previousFollowersCount;

  /// Percentage growth since previous recorded snapshot
  double get growthRatePercentage {
    if (previousFollowersCount <= 0) return 0.0;
    final diff = followersCount - previousFollowersCount;
    return (diff / previousFollowersCount) * 100.0;
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'platform': platform.name,
        'accountName': accountName,
        'handle': handle,
        'avatarUrl': avatarUrl,
        'followersCount': followersCount,
        'previousFollowersCount': previousFollowersCount,
        'totalPostsCount': totalPostsCount,
        'totalViewsCount': totalViewsCount,
        'engagementCount': engagementCount,
        'lastUpdated': lastUpdated.toIso8601String(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory ChannelGrowthMetric.fromJson(Map<String, dynamic> json) {
    return ChannelGrowthMetric(
      accountId: json['accountId'] as String? ?? '',
      platform: PlatformType.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => PlatformType.youtube,
      ),
      accountName: json['accountName'] as String? ?? 'Channel',
      handle: json['handle'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      previousFollowersCount: json['previousFollowersCount'] as int? ?? 0,
      totalPostsCount: json['totalPostsCount'] as int? ?? 0,
      totalViewsCount: json['totalViewsCount'] as int? ?? 0,
      engagementCount: json['engagementCount'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => MetricHistoryPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A point in time for charting follower and engagement growth curves.
class MetricHistoryPoint {
  final DateTime date;
  final int followers;
  final int views;

  const MetricHistoryPoint({
    required this.date,
    required this.followers,
    required this.views,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'followers': followers,
        'views': views,
      };

  factory MetricHistoryPoint.fromJson(Map<String, dynamic> json) {
    return MetricHistoryPoint(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      followers: json['followers'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
    );
  }
}
