import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';

void main() {
  group('PreflightValidator Tests', () {
    final brandA = Brand(
      id: 'brand-a',
      name: 'Shaadow',
      slug: 'shaadow',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    final brandB = Brand(
      id: 'brand-b',
      name: 'Boofer',
      slug: 'boofer',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    final accountShaadowX = SocialAccount(
      id: 'acc-shaadow-x',
      brandId: brandA.id,
      platform: PlatformType.x,
      displayName: 'Shaadow',
      handle: '@shaadow',
      connectionStatus: ConnectionStatus.connected,
    );

    final accountBooferIg = SocialAccount(
      id: 'acc-boofer-ig',
      brandId: brandB.id,
      platform: PlatformType.instagram,
      displayName: 'Boofer',
      handle: '@boofer',
      connectionStatus: ConnectionStatus.connected,
    );

    final sampleImage = MediaAsset(
      id: 'img-1',
      fileName: 'photo.png',
      mimeType: 'image/png',
      sizeBytes: 2048000,
      mediaType: MediaType.image,
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    final sampleVideo = MediaAsset(
      id: 'vid-1',
      fileName: 'clip.mp4',
      mimeType: 'video/mp4',
      sizeBytes: 15000000,
      mediaType: MediaType.video,
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    test('Brand mismatch produces warning when account belongs to different brand', () {
      final post = ContentPost(
        id: 'post-1',
        brandId: brandA.id, // Brand A
        title: 'Title',
        defaultCaption: 'Caption copy',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountBooferIg.id, // Brand B
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountBooferIg,
        postBrand: brandA,
        accountBrand: brandB,
        attachedMedia: [sampleImage],
      );

      expect(result.warnings.any((w) => w.code == 'BRAND_MISMATCH'), isTrue);
    });

    test('No brand mismatch when account matches post brand', () {
      final post = ContentPost(
        id: 'post-1',
        brandId: brandA.id,
        title: 'Title',
        defaultCaption: 'Caption copy',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountShaadowX.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountShaadowX,
        postBrand: brandA,
        accountBrand: brandA,
      );

      expect(result.warnings.any((w) => w.code == 'BRAND_MISMATCH'), isFalse);
    });

    test('Caption override is used instead of shared default caption', () {
      final post = ContentPost(
        id: 'post-1',
        brandId: brandA.id,
        title: 'Title',
        defaultCaption: 'Default caption 12345',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountShaadowX.id,
        captionOverride: 'Custom override for X',
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountShaadowX,
      );

      expect(result.effectiveCaption, equals('Custom override for X'));
      expect(result.characterCount, equals('Custom override for X'.length));
    });

    test('X character limit exceeding 280 generates blocker', () {
      final longText = 'A' * 281;
      final post = ContentPost(
        id: 'post-1',
        brandId: brandA.id,
        title: 'Title',
        defaultCaption: longText,
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountShaadowX.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountShaadowX,
      );

      expect(result.isValid, isFalse);
      expect(result.blockers.any((b) => b.code == 'CAPTION_TOO_LONG'), isTrue);
    });

    test('Instagram blocks text-only posts (requires media)', () {
      final post = ContentPost(
        id: 'post-1',
        brandId: brandB.id,
        title: 'Title',
        defaultCaption: 'Instagram caption with no media attached',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountBooferIg.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountBooferIg,
        attachedMedia: [], // Empty media
      );

      expect(result.isValid, isFalse);
      expect(result.blockers.any((b) => b.code == 'MEDIA_REQUIRED_INSTAGRAM'), isTrue);
    });

    test('Instagram blocks post with more than 30 hashtags', () {
      final hashtags = List.generate(31, (i) => '#tag$i').join(' ');
      final post = ContentPost(
        id: 'post-1',
        brandId: brandB.id,
        title: 'Title',
        defaultCaption: 'Photo $hashtags',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: accountBooferIg.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: accountBooferIg,
        attachedMedia: [sampleImage],
      );

      expect(result.isValid, isFalse);
      expect(result.blockers.any((b) => b.code == 'TOO_MANY_HASHTAGS'), isTrue);
    });

    test('Expired account connection blocks publication', () {
      final expiredAccount = accountShaadowX.copyWith(
        connectionStatus: ConnectionStatus.expired,
      );

      final post = ContentPost(
        id: 'post-1',
        brandId: brandA.id,
        title: 'Title',
        defaultCaption: 'Valid short caption',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-1',
        contentPostId: post.id,
        socialAccountId: expiredAccount.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: expiredAccount,
      );

      expect(result.isValid, isFalse);
      expect(result.blockers.any((b) => b.code == 'CONNECTION_INVALID'), isTrue);
    });

    test('YouTube accepts post when valid video asset and title are provided', () {
      final ytAccount = SocialAccount(
        id: 'acc-yt-1',
        brandId: brandA.id,
        platform: PlatformType.youtube,
        displayName: 'YouTube Channel',
        handle: 'Shaadow Official',
        connectionStatus: ConnectionStatus.connected,
      );

      final post = ContentPost(
        id: 'post-yt-1',
        brandId: brandA.id,
        title: 'Launch Architecture Walkthrough',
        defaultCaption: 'Full description of the new system architecture #Tech',
        createdAtUtc: DateTime.utc(2026, 1, 1),
        updatedAtUtc: DateTime.utc(2026, 1, 1),
      );

      final variant = PostVariant(
        id: 'var-yt-1',
        contentPostId: post.id,
        socialAccountId: ytAccount.id,
      );

      final result = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: ytAccount,
        attachedMedia: [sampleVideo],
      );

      expect(result.isValid, isTrue);
      expect(result.blockers, isEmpty);
    });
  });
}
