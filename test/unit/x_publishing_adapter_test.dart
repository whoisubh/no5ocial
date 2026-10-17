import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:no5ocial/domain/adapters/x_publishing_adapter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';

void main() {
  group('XPublishingAdapter Tests', () {
    final standardAccount = SocialAccount(
      id: 'acc-x-std',
      brandId: 'brand-1',
      platform: PlatformType.x,
      displayName: 'Standard User',
      handle: '@std_user',
      connectionStatus: ConnectionStatus.connected,
      capabilities: ['text', 'image', 'video', 'character_limit_280', 'subtype:x_profile'],
      scopes: ['token:valid_x_token_123', 'tweet.read', 'tweet.write'],
    );

    final premiumAccount = SocialAccount(
      id: 'acc-x-prem',
      brandId: 'brand-1',
      platform: PlatformType.x,
      displayName: 'Premium Org',
      handle: '@premium_org',
      connectionStatus: ConnectionStatus.connected,
      capabilities: ['text', 'image', 'video', 'character_limit_25000', 'subtype:x_premium'],
      scopes: ['token:valid_x_token_456', 'tweet.read', 'tweet.write'],
    );

    final testPost = ContentPost(
      id: 'post-1',
      brandId: 'brand-1',
      title: 'Test Post',
      defaultCaption: 'Short update for X',
      createdAtUtc: DateTime.utc(2026, 1, 1),
      updatedAtUtc: DateTime.utc(2026, 1, 1),
    );

    final testVariant = PostVariant(
      id: 'var-1',
      contentPostId: 'post-1',
      socialAccountId: 'acc-x-std',
    );

    test('getCapabilities distinguishes between Standard and Premium accounts', () {
      final adapter = XPublishingAdapter();

      final stdCaps = adapter.getCapabilities(standardAccount);
      expect(stdCaps, contains('character_limit_280'));
      expect(stdCaps, contains('standard_publishing'));

      final premCaps = adapter.getCapabilities(premiumAccount);
      expect(premCaps, contains('long_form_25000'));
      expect(premCaps, contains('x_premium_publishing'));
    });

    test('Preflight blocker on empty content without media', () {
      final adapter = XPublishingAdapter();
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
        account: standardAccount,
      );
      expect(res.issues.any((i) => i.code == 'X_CONTENT_REQUIRED'), isTrue);
    });

    test('Preflight validates 280-character limit on Standard vs 25,000 on Premium', () {
      final adapter = XPublishingAdapter();
      final longText = 'A' * 300;
      final longPost = ContentPost(
        id: 'p-long',
        brandId: 'b-1',
        title: 'Long Post',
        defaultCaption: longText,
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      // Standard account must fail on 300 characters
      final stdRes = adapter.validateDraft(
        post: longPost,
        variant: testVariant,
        account: standardAccount,
      );
      expect(stdRes.issues.any((i) => i.code == 'X_STANDARD_LIMIT_EXCEEDED'), isTrue);

      // Premium account must pass on 300 characters
      final premRes = adapter.validateDraft(
        post: longPost,
        variant: testVariant,
        account: premiumAccount,
      );
      expect(premRes.issues.any((i) => i.code == 'X_STANDARD_LIMIT_EXCEEDED'), isFalse);
      expect(premRes.issues.any((i) => i.code == 'X_PREMIUM_LIMIT_EXCEEDED'), isFalse);
    });

    test('Preflight validates media constraints (max 4 images, max 1 video)', () {
      final adapter = XPublishingAdapter();

      final images = List.generate(
        5,
        (i) => MediaAsset(
          id: 'img-$i',
          fileName: 'img$i.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1000,
          mediaType: MediaType.image,
          createdAtUtc: DateTime.utc(2026, 1, 1),
        ),
      );

      final mediaRes = adapter.validateDraft(
        post: testPost,
        variant: testVariant,
        account: standardAccount,
        attachedMedia: images,
      );
      expect(mediaRes.issues.any((i) => i.code == 'X_MEDIA_LIMIT_EXCEEDED'), isTrue);
    });

    test('publishNow successfully returns tweet ID and URL on 201 Created', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), equals('https://api.twitter.com/2/tweets'));
        expect(request.headers['Authorization'], equals('Bearer valid_x_token_123'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], equals('Short update for X'));

        return http.Response(
          jsonEncode({
            'data': {
              'id': '1789000111222333',
              'text': 'Short update for X',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = XPublishingAdapter(httpClient: mockClient);
      final result = await adapter.publishNow(
        post: testPost,
        variant: testVariant,
        account: standardAccount,
        idempotencyKey: 'idemp-123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.externalPostId, equals('1789000111222333'));
      expect(result.externalUrl, equals('https://x.com/std_user/status/1789000111222333'));
    });

    test('publishNow redacts access tokens and handles 401 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'title': 'Unauthorized',
            'detail': 'Invalid or expired token valid_x_token_123',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = XPublishingAdapter(httpClient: mockClient);
      final result = await adapter.publishNow(
        post: testPost,
        variant: testVariant,
        account: standardAccount,
        idempotencyKey: 'idemp-123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCategory, equals(ErrorCategory.authentication));
      expect(result.sanitizedErrorMessage?.contains('valid_x_token_123'), isFalse);
    });
  });
}
