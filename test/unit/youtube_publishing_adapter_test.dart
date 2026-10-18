import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:no5ocial/domain/adapters/youtube_publishing_adapter.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';

void main() {
  group('YouTubePublishingAdapter Tests', () {
    const testAccount = SocialAccount(
      id: 'acc_yt_01',
      brandId: 'brand_01',
      platform: PlatformType.youtube,
      displayName: 'Shaadow Studios',
      handle: '@shaadow',
      externalAccountId: 'UC1234567890',
      scopes: ['token:ya29.valid_test_token'],
    );

    final validVideo = MediaAsset(
      id: 'vid_01',
      fileName: 'launch.mp4',
      mimeType: 'video/mp4',
      sizeBytes: 1048576,
      mediaType: MediaType.video,
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    test('getCapabilities returns video, shorts, title, and description', () {
      final adapter = YouTubePublishingAdapter();
      final capabilities = adapter.getCapabilities(testAccount);

      expect(capabilities, contains('video'));
      expect(capabilities, contains('shorts'));
      expect(capabilities, contains('title'));
      expect(capabilities, contains('description'));
      expect(capabilities, contains('direct_upload'));
    });

    test('Preflight blocker when no video is attached', () {
      final adapter = YouTubePublishingAdapter();
      final post = ContentPost(
        id: 'post_01',
        brandId: 'brand_01',
        title: 'Product Teaser',
        defaultCaption: 'Check this out!',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );
      const variant = PostVariant(
        id: 'var_01',
        contentPostId: 'post_01',
        socialAccountId: 'acc_yt_01',
      );

      final result = adapter.validateDraft(
        post: post,
        variant: variant,
        account: testAccount,
        attachedMedia: [],
      );

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == 'YOUTUBE_VIDEO_REQUIRED'),
        isTrue,
      );
    });

    test('Preflight blocker when video title is empty', () {
      final adapter = YouTubePublishingAdapter();
      final post = ContentPost(
        id: 'post_01',
        brandId: 'brand_01',
        title: '',
        defaultCaption: 'A description',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );
      const variant = PostVariant(
        id: 'var_01',
        contentPostId: 'post_01',
        socialAccountId: 'acc_yt_01',
      );

      final result = adapter.validateDraft(
        post: post,
        variant: variant,
        account: testAccount,
        attachedMedia: [validVideo],
      );

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.code == 'YOUTUBE_TITLE_REQUIRED'),
        isTrue,
      );
    });

    test('publishNow executes resumable upload workflow successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('upload/youtube/v3/videos')) {
          // Resumable upload init responds with 200 and Location header
          return http.Response(
            '{}',
            200,
            headers: {'location': 'https://upload.youtube.com/resumable_session_xyz'},
          );
        } else if (request.url.toString().contains('resumable_session_xyz')) {
          // File upload binary responds with 201 Created and video metadata
          return http.Response(
            jsonEncode({
              'id': 'abc123xyz',
              'snippet': {'title': 'Launch Teaser'},
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final adapter = YouTubePublishingAdapter(httpClient: mockClient);
      final post = ContentPost(
        id: 'post_01',
        brandId: 'brand_01',
        title: 'Launch Teaser',
        defaultCaption: 'Excited to announce our launch!',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );
      const variant = PostVariant(
        id: 'var_01',
        contentPostId: 'post_01',
        socialAccountId: 'acc_yt_01',
      );

      final result = await adapter.publishNow(
        post: post,
        variant: variant,
        account: testAccount,
        idempotencyKey: 'idem_yt_01',
        attachedMedia: [validVideo],
      );

      expect(result.isSuccess, isTrue);
      expect(result.externalPostId, 'abc123xyz');
      expect(result.externalUrl, 'https://youtu.be/abc123xyz');
    });
  });
}
