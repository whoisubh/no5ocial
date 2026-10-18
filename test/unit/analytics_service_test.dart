import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:no5ocial/core/services/analytics_service.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/channel_growth_metric.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsService & ChannelGrowthMetric Tests', () {
    test('ChannelGrowthMetric calculates net gain and percentage accurately', () {
      final metric = ChannelGrowthMetric(
        accountId: 'acc_01',
        platform: PlatformType.youtube,
        accountName: 'Owl Channel',
        handle: '@owl',
        followersCount: 1200,
        previousFollowersCount: 1000,
        totalPostsCount: 45,
        totalViewsCount: 50000,
        lastUpdated: DateTime.now(),
      );

      expect(metric.netFollowerGain, 200);
      expect(metric.growthRatePercentage, 20.0);
    });

    test('AnalyticsService fetches YouTube statistics accurately', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('youtube/v3/channels')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'statistics': {
                    'subscriberCount': '14500',
                    'videoCount': '85',
                    'viewCount': '1250000',
                  },
                  'snippet': {
                    'thumbnails': {
                      'medium': {'url': 'https://yt.com/avatar.jpg'}
                    }
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      AnalyticsService.instance.httpClient = mockClient;

      const account = SocialAccount(
        id: 'acc_yt_01',
        brandId: 'brand_01',
        platform: PlatformType.youtube,
        displayName: 'Shaadow Official',
        handle: '@shaadow',
        scopes: ['token:ya29.sample_yt_token'],
      );

      final metric = await AnalyticsService.instance.fetchMetricForAccount(account);

      expect(metric.followersCount, 14500);
      expect(metric.totalPostsCount, 85);
      expect(metric.totalViewsCount, 1250000);
      expect(metric.avatarUrl, 'https://yt.com/avatar.jpg');
    });

    test('AnalyticsService fetches X (Twitter) public metrics accurately', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('api.twitter.com/2/users/me')) {
          return http.Response(
            jsonEncode({
              'data': {
                'public_metrics': {
                  'followers_count': 3200,
                  'following_count': 450,
                  'tweet_count': 610,
                },
                'profile_image_url': 'https://x.com/avatar.jpg',
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      AnalyticsService.instance.httpClient = mockClient;

      const account = SocialAccount(
        id: 'acc_x_01',
        brandId: 'brand_01',
        platform: PlatformType.x,
        displayName: 'Shaadow X',
        handle: '@shaadow_io',
        scopes: ['token:sample_x_token'],
      );

      final metric = await AnalyticsService.instance.fetchMetricForAccount(account);

      expect(metric.followersCount, 3200);
      expect(metric.totalPostsCount, 610);
      expect(metric.engagementCount, 450);
      expect(metric.avatarUrl, 'https://x.com/avatar.jpg');
    });
  });
}
