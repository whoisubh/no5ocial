import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:no5ocial/domain/adapters/threads_publishing_adapter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';

void main() {
  group('ThreadsPublishingAdapter Tests', () {
    final threadsAccount = SocialAccount(
      id: 'acc-threads-1',
      brandId: 'brand-1',
      platform: PlatformType.threads,
      externalAccountId: '178414000111222',
      displayName: 'Threads User',
      handle: '@threads_user',
      connectionStatus: ConnectionStatus.connected,
      capabilities: ['text', 'image', 'video', 'carousel', 'character_limit_500', 'subtype:threads_profile'],
      scopes: ['token:valid_threads_token_abc', 'threads_basic', 'threads_content_publish'],
    );

    final testPost = ContentPost(
      id: 'post-1',
      brandId: 'brand-1',
      title: 'Test Thread',
      defaultCaption: 'Exciting update on Threads! #no5ocial',
      createdAtUtc: DateTime.utc(2026, 1, 1),
      updatedAtUtc: DateTime.utc(2026, 1, 1),
    );

    final testVariant = PostVariant(
      id: 'var-1',
      contentPostId: 'post-1',
      socialAccountId: 'acc-threads-1',
    );

    test('getCapabilities returns text, image, video, carousel, 500 char limit', () {
      final adapter = ThreadsPublishingAdapter();
      final caps = adapter.getCapabilities(threadsAccount);

      expect(caps, contains('text'));
      expect(caps, contains('image'));
      expect(caps, contains('video'));
      expect(caps, contains('carousel'));
      expect(caps, contains('character_limit_500'));
      expect(caps, contains('threads_publishing'));
    });

    test('Preflight blocker on empty post without media', () {
      final adapter = ThreadsPublishingAdapter();
      final emptyPost = ContentPost(
        id: 'p-empty',
        brandId: 'b-1',
        title: 'Empty Post',
        defaultCaption: '',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final res = adapter.validateDraft(
        post: emptyPost,
        variant: testVariant,
        account: threadsAccount,
      );

      expect(res.issues.any((i) => i.code == 'THREADS_CONTENT_REQUIRED'), isTrue);
    });

    test('Preflight validates 500-character limit on Threads', () {
      final adapter = ThreadsPublishingAdapter();
      final longPost = ContentPost(
        id: 'p-long',
        brandId: 'b-1',
        title: 'Long Post',
        defaultCaption: 'T' * 501,
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final res = adapter.validateDraft(
        post: longPost,
        variant: testVariant,
        account: threadsAccount,
      );

      expect(res.issues.any((i) => i.code == 'THREADS_CAPTION_TOO_LONG'), isTrue);
    });

    test('Preflight validates media limit (max 10 items)', () {
      final adapter = ThreadsPublishingAdapter();
      final elevenImages = List.generate(
        11,
        (i) => MediaAsset(
          id: 'img-$i',
          fileName: 'img$i.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1000,
          mediaType: MediaType.image,
          createdAtUtc: DateTime.utc(2026, 1, 1),
        ),
      );

      final res = adapter.validateDraft(
        post: testPost,
        variant: testVariant,
        account: threadsAccount,
        attachedMedia: elevenImages,
      );

      expect(res.issues.any((i) => i.code == 'THREADS_TOO_MANY_MEDIA'), isTrue);
    });

    test('publishNow successfully creates container and publishes to Threads', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // Step 1: Create media container
          expect(request.url.toString(), equals('https://graph.threads.net/v1.0/178414000111222/threads'));
          expect(request.bodyFields['media_type'], equals('TEXT'));
          expect(request.bodyFields['text'], equals('Exciting update on Threads! #no5ocial'));
          expect(request.bodyFields['access_token'], equals('valid_threads_token_abc'));

          return http.Response(
            jsonEncode({'id': 'container_999888'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          // Step 2: Publish container
          expect(request.url.toString(), equals('https://graph.threads.net/v1.0/178414000111222/threads_publish'));
          expect(request.bodyFields['creation_id'], equals('container_999888'));
          expect(request.bodyFields['access_token'], equals('valid_threads_token_abc'));

          return http.Response(
            jsonEncode({'id': 'thread_post_123456789'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final adapter = ThreadsPublishingAdapter(httpClient: mockClient);
      final result = await adapter.publishNow(
        post: testPost,
        variant: testVariant,
        account: threadsAccount,
        idempotencyKey: 'idemp-threads-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.externalPostId, equals('thread_post_123456789'));
      expect(result.externalUrl, equals('https://www.threads.net/@threads_user/post/thread_post_123456789'));
    });

    test('publishNow redacts access tokens and maps 401 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'Error validating access token: Session has expired.',
              'type': 'OAuthException',
              'code': 190,
            }
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = ThreadsPublishingAdapter(httpClient: mockClient);
      final result = await adapter.publishNow(
        post: testPost,
        variant: testVariant,
        account: threadsAccount,
        idempotencyKey: 'idemp-threads-2',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCategory, equals(ErrorCategory.authentication));
      expect(result.sanitizedErrorMessage?.contains('valid_threads_token_abc'), isFalse);
    });
  });
}
