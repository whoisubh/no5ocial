import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/platform_type.dart';
import '../../domain/models/channel_growth_metric.dart';
import '../../domain/models/social_account.dart';

/// Service that queries official platform analytics endpoints and computes growth metrics.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  http.Client _httpClient = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _httpClient = client;

  static const String _metricsStoragePrefix = 'growth_metrics_account_';

  /// Fetches and computes growth metrics for all given connected accounts.
  Future<List<ChannelGrowthMetric>> getMetricsForAccounts(List<SocialAccount> accounts) async {
    final results = <ChannelGrowthMetric>[];

    for (final account in accounts) {
      try {
        final metric = await fetchMetricForAccount(account);
        results.add(metric);
      } catch (e) {
        debugPrint('[AnalyticsService] Error fetching metrics for ${account.displayName}: $e');
        // Fallback to cached or baseline metric
        final cached = await getCachedMetric(account.id);
        if (cached != null) {
          results.add(cached);
        } else {
          results.add(_createBaselineMetric(account));
        }
      }
    }

    return results;
  }

  /// Fetches real statistics from the official platform API for a single account.
  Future<ChannelGrowthMetric> fetchMetricForAccount(SocialAccount account) async {
    final token = _resolveAccessToken(account);

    int followers = 0;
    int totalPosts = 0;
    int totalViews = 0;
    int engagements = 0;
    String? avatarUrl;

    if (token != null && token.isNotEmpty) {
      switch (account.platform) {
        case PlatformType.youtube:
          final ytStats = await _fetchYouTubeStats(token);
          followers = ytStats['subscribers'] ?? 0;
          totalPosts = ytStats['videos'] ?? 0;
          totalViews = ytStats['views'] ?? 0;
          avatarUrl = ytStats['avatarUrl'];
          break;

        case PlatformType.x:
          final xStats = await _fetchXStats(token);
          followers = xStats['followers'] ?? 0;
          totalPosts = xStats['tweets'] ?? 0;
          engagements = xStats['following'] ?? 0;
          avatarUrl = xStats['avatarUrl'];
          break;

        case PlatformType.instagram:
          final igStats = await _fetchInstagramStats(account.externalAccountId ?? 'me', token);
          followers = igStats['followers'] ?? 0;
          totalPosts = igStats['mediaCount'] ?? 0;
          break;

        case PlatformType.threads:
          final threadsStats = await _fetchThreadsStats(token);
          followers = threadsStats['followers'] ?? 0;
          totalPosts = threadsStats['threadsCount'] ?? 0;
          avatarUrl = threadsStats['avatarUrl'];
          break;

        case PlatformType.linkedin:
          final liStats = await _fetchLinkedInStats(account.externalAccountId ?? '', token);
          followers = liStats['followers'] ?? 0;
          totalPosts = liStats['posts'] ?? 0;
          break;

        case PlatformType.facebook:
          break;
      }
    }

    // Retrieve previous snapshot to compute delta and trend line
    final previous = await getCachedMetric(account.id);
    final previousFollowers = previous?.followersCount ?? (followers > 0 ? (followers * 0.95).round() : 0);

    // Build history points
    final history = <MetricHistoryPoint>[];
    if (previous != null && previous.history.isNotEmpty) {
      history.addAll(previous.history);
    } else {
      // Seed 7-day initial historical curve
      final now = DateTime.now();
      for (int i = 6; i >= 1; i--) {
        final d = now.subtract(Duration(days: i));
        final factor = 1.0 - (i * 0.015);
        history.add(MetricHistoryPoint(
          date: d,
          followers: (followers * factor).round(),
          views: (totalViews * factor).round(),
        ));
      }
    }

    history.add(MetricHistoryPoint(
      date: DateTime.now(),
      followers: followers,
      views: totalViews,
    ));

    // Keep history capped at 30 days
    if (history.length > 30) {
      history.removeRange(0, history.length - 30);
    }

    final metric = ChannelGrowthMetric(
      accountId: account.id,
      platform: account.platform,
      accountName: account.displayName,
      handle: account.handle,
      avatarUrl: avatarUrl,
      followersCount: followers,
      previousFollowersCount: previousFollowers,
      totalPostsCount: totalPosts,
      totalViewsCount: totalViews,
      engagementCount: engagements,
      lastUpdated: DateTime.now(),
      history: history,
    );

    await _cacheMetric(metric);
    return metric;
  }

  // --- Platform API Handlers ---

  Future<Map<String, dynamic>> _fetchYouTubeStats(String token) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&mine=true',
    );
    final res = await _httpClient.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final item = items.first as Map<String, dynamic>;
        final stats = item['statistics'] as Map<String, dynamic>? ?? {};
        final snippet = item['snippet'] as Map<String, dynamic>? ?? {};
        return {
          'subscribers': int.tryParse(stats['subscriberCount']?.toString() ?? '0') ?? 0,
          'videos': int.tryParse(stats['videoCount']?.toString() ?? '0') ?? 0,
          'views': int.tryParse(stats['viewCount']?.toString() ?? '0') ?? 0,
          'avatarUrl': snippet['thumbnails']?['medium']?['url'],
        };
      }
    }
    return {'subscribers': 0, 'videos': 0, 'views': 0};
  }

  Future<Map<String, dynamic>> _fetchXStats(String token) async {
    final uri = Uri.parse('https://api.twitter.com/2/users/me?user.fields=public_metrics,profile_image_url');
    final res = await _httpClient.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final metrics = data['data']?['public_metrics'] as Map<String, dynamic>? ?? {};
      return {
        'followers': metrics['followers_count'] as int? ?? 0,
        'following': metrics['following_count'] as int? ?? 0,
        'tweets': metrics['tweet_count'] as int? ?? 0,
        'avatarUrl': data['data']?['profile_image_url'],
      };
    }
    return {'followers': 0, 'tweets': 0, 'following': 0};
  }

  Future<Map<String, dynamic>> _fetchInstagramStats(String igUserId, String token) async {
    final uri = Uri.parse('https://graph.facebook.com/v21.0/$igUserId?fields=followers_count,media_count&access_token=$token');
    final res = await _httpClient.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'followers': data['followers_count'] as int? ?? 0,
        'mediaCount': data['media_count'] as int? ?? 0,
      };
    }
    return {'followers': 0, 'mediaCount': 0};
  }

  Future<Map<String, dynamic>> _fetchThreadsStats(String token) async {
    final uri = Uri.parse('https://graph.threads.net/v1.0/me?fields=id,username,threads_profile_picture_url&access_token=$token');
    final res = await _httpClient.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'followers': 0, // Threads API limits follower count retrieval to specific insights scopes
        'threadsCount': 0,
        'avatarUrl': data['threads_profile_picture_url'],
      };
    }
    return {'followers': 0, 'threadsCount': 0};
  }

  Future<Map<String, dynamic>> _fetchLinkedInStats(String authorUrn, String token) async {
    // For organization page: query network sizes
    if (authorUrn.startsWith('urn:li:organization:')) {
      final orgId = authorUrn.replaceFirst('urn:li:organization:', '');
      final uri = Uri.parse('https://api.linkedin.com/rest/networkSizes/urn:li:organization:$orgId?edgeType=CompanyFollowedByMember');
      final res = await _httpClient.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'LinkedIn-Version': '202401',
        'X-Restli-Protocol-Version': '2.0.0',
      }).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'followers': data['firstDegreeSize'] as int? ?? 0,
          'posts': 0,
        };
      }
    }
    return {'followers': 0, 'posts': 0};
  }

  // --- Persistence & Cache ---

  Future<ChannelGrowthMetric?> getCachedMetric(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_metricsStoragePrefix$accountId');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ChannelGrowthMetric.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheMetric(ChannelGrowthMetric metric) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_metricsStoragePrefix${metric.accountId}',
      jsonEncode(metric.toJson()),
    );
  }

  ChannelGrowthMetric _createBaselineMetric(SocialAccount account) {
    return ChannelGrowthMetric(
      accountId: account.id,
      platform: account.platform,
      accountName: account.displayName,
      handle: account.handle,
      avatarUrl: null,
      followersCount: 0,
      previousFollowersCount: 0,
      totalPostsCount: 0,
      totalViewsCount: 0,
      lastUpdated: DateTime.now(),
      history: [
        MetricHistoryPoint(
          date: DateTime.now(),
          followers: 0,
          views: 0,
        ),
      ],
    );
  }

  String? _resolveAccessToken(SocialAccount account) {
    for (final scope in account.scopes) {
      if (scope.startsWith('token:')) {
        return scope.substring(6);
      }
    }
    return null;
  }
}
