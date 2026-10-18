import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../enums/connection_status.dart';
import '../enums/error_category.dart';
import '../enums/media_type.dart';
import '../models/content_post.dart';
import '../models/media_asset.dart';
import '../models/post_variant.dart';
import '../models/publish_attempt.dart';
import '../models/social_account.dart';
import '../validators/preflight_validator.dart';
import 'publishing_adapter.dart';
import '../../core/services/media_hosting_service.dart';

/// Real official Instagram Graph API Publishing Adapter (v21.0).
///
/// Implements Meta Content Publishing API:
/// 1. Container creation: POST /{ig-user-id}/media
/// 2. Media processing status polling: GET /{container-id}?fields=status_code
/// 3. Publish container: POST /{ig-user-id}/media_publish
/// 4. Permalink fetch: GET /{media-id}?fields=permalink
/// 5. Optional first comment: POST /{media-id}/comments
///
/// Security & Architecture guarantees (per AGENTS.md):
/// - Does NOT fabricate API capabilities.
/// - Sanitizes and redacts access tokens and secrets from all logs and error messages.
/// - Automatically routes personal / unsupported accounts to Manual Publishing Handoff.
/// - Supports idempotent multi-destination execution with ambiguous timeout reconciliation.
class InstagramPublishingAdapter implements PublishingAdapter {
  static const String graphApiBaseUrl = 'https://graph.facebook.com/v21.0';

  final http.Client _httpClient;
  final String? defaultAccessToken;

  InstagramPublishingAdapter({
    http.Client? httpClient,
    this.defaultAccessToken,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  List<String> getCapabilities(SocialAccount account) {
    if (account.isManualOnly) {
      return const ['manual_handoff'];
    }
    return const [
      'image',
      'video',
      'reels',
      'carousel',
      'caption',
      'first_comment',
    ];
  }

  @override
  PreflightResult validateDraft({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    List<MediaAsset> attachedMedia = const [],
  }) {
    // 1. Core cross-platform preflight validation
    final baseResult = PreflightValidator.validate(
      post: post,
      variant: variant,
      account: account,
      attachedMedia: attachedMedia,
    );

    final issues = List<ValidationIssue>.from(baseResult.issues);

    // 2. Instagram-specific official Graph API constraints
    // A. Text-only posts are strictly rejected by Meta API
    if (attachedMedia.isEmpty) {
      issues.add(
        const ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'INSTAGRAM_MEDIA_REQUIRED',
          message:
              'Instagram requires at least one image or video. Text-only posts cannot be published.',
          remedy: 'Attach at least one photo or video asset.',
        ),
      );
    }

    // B. Carousel limits (Meta supports 2 to 10 items)
    if (attachedMedia.length > 10) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'INSTAGRAM_CAROUSEL_LIMIT',
          message:
              'Instagram carousel maximum is 10 media items (${attachedMedia.length} attached).',
          remedy: 'Limit carousel items to 10 photos or videos.',
        ),
      );
    }

    // C. Media URL accessibility check
    for (final media in attachedMedia) {
      final url = media.localPreviewUrl ?? '';
      if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.warning,
            code: 'INSTAGRAM_PUBLIC_URL_REQUIRED',
            message:
                'Media "${media.fileName}" must have a public HTTPS URL for Meta ingestion servers.',
            remedy: 'Ensure media is hosted on public/pre-signed HTTPS URL.',
          ),
        );
      }
    }

    // D. Manual Handoff notice for Personal Instagram profiles
    if (account.isManualOnly) {
      issues.add(
        const ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'INSTAGRAM_MANUAL_HANDOFF',
          message:
              'Personal Instagram accounts cannot use direct API publishing. A manual handoff helper will be provided.',
          remedy: 'Switch to an Instagram Business or Creator account for direct publishing.',
        ),
      );
    }

    return PreflightResult(
      account: baseResult.account,
      effectiveCaption: baseResult.effectiveCaption,
      characterCount: baseResult.characterCount,
      maxCharacters: baseResult.maxCharacters,
      hashtagCount: baseResult.hashtagCount,
      issues: issues,
    );
  }

  @override
  Future<PublishExecutionResult> publishNow({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    required String idempotencyKey,
    List<MediaAsset> attachedMedia = const [],
  }) async {
    // 1. Personal / Unsupported accounts route to manual handoff per PRD Rule 7
    if (account.isManualOnly) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.policy,
        rawErrorCode: 'MANUAL_HANDOFF_REQUIRED',
        sanitizedErrorMessage:
            'Personal Instagram profiles do not support direct API publishing. Use Manual Handoff.',
      );
    }

    // 2. Verify account connection status
    if (account.connectionStatus != ConnectionStatus.connected) {
      return PublishExecutionResult.failure(
        errorCategory: ErrorCategory.authentication,
        rawErrorCode: 'ACCOUNT_NOT_CONNECTED',
        sanitizedErrorMessage:
            'Account "${account.displayName}" is not connected or token expired. Please re-authenticate.',
      );
    }

    // 3. Resolve required credentials
    final igUserId = account.externalAccountId;
    if (igUserId == null || igUserId.isEmpty) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.validation,
        rawErrorCode: 'MISSING_IG_USER_ID',
        sanitizedErrorMessage:
            'Missing Instagram Business/Creator Account ID. Re-link account with Facebook Page connection.',
      );
    }

    final accessToken = _resolveAccessToken(account);
    if (accessToken == null || accessToken.isEmpty) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.authentication,
        rawErrorCode: 'MISSING_ACCESS_TOKEN',
        sanitizedErrorMessage:
            'No valid OAuth access token found for Instagram publishing. Please reconnect the account.',
      );
    }

    // 4. Validate attached media presence
    if (attachedMedia.isEmpty) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.validation,
        rawErrorCode: 'MEDIA_REQUIRED',
        sanitizedErrorMessage:
            'Instagram Content Publishing API requires at least one media item.',
      );
    }

    final caption = variant.hasCaptionOverride
        ? variant.captionOverride!
        : post.defaultCaption;

    try {
      // Step 1: Create Container
      final containerId = await _createMediaContainer(
        igUserId: igUserId,
        accessToken: accessToken,
        caption: caption,
        attachedMedia: attachedMedia,
      );

      // Step 2: Poll Container Status until FINISHED
      final isReady = await _pollContainerStatus(
        containerId: containerId,
        accessToken: accessToken,
      );

      if (!isReady) {
        return const PublishExecutionResult.ambiguousTimeout(
          sanitizedErrorMessage:
              'Instagram media processing timed out. Publication outcome is ambiguous.',
        );
      }

      // Step 3: Publish Container to Live Feed
      final publishedMediaId = await _publishMediaContainer(
        igUserId: igUserId,
        containerId: containerId,
        accessToken: accessToken,
      );

      // Step 4: Retrieve permalink for external reference
      final permalink = await _fetchPermalink(
        mediaId: publishedMediaId,
        accessToken: accessToken,
      );

      // Step 5: Post optional first comment if configured in variant
      final firstComment = variant.firstComment;
      if (firstComment != null && firstComment.trim().isNotEmpty) {
        await _postFirstComment(
          mediaId: publishedMediaId,
          comment: firstComment.trim(),
          accessToken: accessToken,
        );
      }

      return PublishExecutionResult.success(
        externalPostId: publishedMediaId,
        externalUrl: permalink ?? 'https://www.instagram.com/p/$publishedMediaId/',
      );
    } on TimeoutException {
      return const PublishExecutionResult.ambiguousTimeout(
        sanitizedErrorMessage:
            'Network request to Instagram timed out after submission. Verifying status before retrying.',
      );
    } catch (e) {
      return _mapExceptionToResult(e);
    }
  }

  Future<String> _resolvePublicUrl(MediaAsset media) async {
    final rawPath = media.localPreviewUrl ?? media.fileName;
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    return await MediaHostingService.instance.uploadMedia(
      filePath: rawPath,
      fileName: media.fileName,
      isVideo: media.mediaType == MediaType.video,
    );
  }

  // --- Step 1: Create Media Container ---
  Future<String> _createMediaContainer({
    required String igUserId,
    required String accessToken,
    required String caption,
    required List<MediaAsset> attachedMedia,
  }) async {
    final endpoint = Uri.parse('$graphApiBaseUrl/$igUserId/media');

    if (attachedMedia.length == 1) {
      final media = attachedMedia.first;
      final mediaUrl = await _resolvePublicUrl(media);

      if (media.mediaType == MediaType.video) {
        // Single Video / Reel
        final response = await _httpClient.post(endpoint, body: {
          'media_type': 'REELS',
          'video_url': mediaUrl,
          'caption': caption,
          'share_to_feed': 'true',
          'access_token': accessToken,
        }).timeout(const Duration(seconds: 30));

        return _extractContainerId(response);
      } else {
        // Single Photo
        final response = await _httpClient.post(endpoint, body: {
          'image_url': mediaUrl,
          'caption': caption,
          'access_token': accessToken,
        }).timeout(const Duration(seconds: 30));

        return _extractContainerId(response);
      }
    } else {
      // Carousel (2–10 items)
      final itemContainerIds = <String>[];
      for (final media in attachedMedia.take(10)) {
        final mediaUrl = await _resolvePublicUrl(media);
        final isVideo = media.mediaType == MediaType.video;

        final itemResponse = await _httpClient.post(endpoint, body: {
          'is_carousel_item': 'true',
          if (isVideo) 'media_type': 'VIDEO',
          if (isVideo) 'video_url': mediaUrl else 'image_url': mediaUrl,
          'access_token': accessToken,
        }).timeout(const Duration(seconds: 30));

        itemContainerIds.add(_extractContainerId(itemResponse));
      }

      // Create Parent Carousel Container
      final carouselResponse = await _httpClient.post(endpoint, body: {
        'media_type': 'CAROUSEL',
        'children': itemContainerIds.join(','),
        'caption': caption,
        'access_token': accessToken,
      }).timeout(const Duration(seconds: 30));

      return _extractContainerId(carouselResponse);
    }
  }

  // --- Step 2: Poll Container Status ---
  Future<bool> _pollContainerStatus({
    required String containerId,
    required String accessToken,
    int maxAttempts = 15,
    Duration delay = const Duration(seconds: 3),
  }) async {
    final statusUrl = Uri.parse(
      '$graphApiBaseUrl/$containerId?fields=status_code&access_token=$accessToken',
    );

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await _httpClient.get(statusUrl).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final statusCode = data['status_code'] as String?;

          if (statusCode == 'FINISHED') {
            return true;
          }
          if (statusCode == 'ERROR') {
            throw Exception('Instagram media container processing failed with status ERROR.');
          }
          if (statusCode == 'EXPIRED') {
            throw Exception('Instagram media container expired before publishing.');
          }
        }
      } catch (e) {
        if (e.toString().contains('Instagram media container')) rethrow;
      }
      await Future<void>.delayed(delay);
    }
    return false;
  }

  // --- Step 3: Publish Container to Live Feed ---
  Future<String> _publishMediaContainer({
    required String igUserId,
    required String containerId,
    required String accessToken,
  }) async {
    final publishEndpoint = Uri.parse('$graphApiBaseUrl/$igUserId/media_publish');
    final response = await _httpClient.post(publishEndpoint, body: {
      'creation_id': containerId,
      'access_token': accessToken,
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      _throwParsedError(response);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final publishedMediaId = data['id'] as String?;
    if (publishedMediaId == null || publishedMediaId.isEmpty) {
      throw Exception('Instagram media_publish succeeded but did not return published media ID.');
    }
    return publishedMediaId;
  }

  // --- Step 4: Fetch Live Permalink ---
  Future<String?> _fetchPermalink({
    required String mediaId,
    required String accessToken,
  }) async {
    try {
      final permalinkUrl = Uri.parse(
        '$graphApiBaseUrl/$mediaId?fields=permalink&access_token=$accessToken',
      );
      final response = await _httpClient.get(permalinkUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['permalink'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // --- Step 5: Post First Comment ---
  Future<void> _postFirstComment({
    required String mediaId,
    required String comment,
    required String accessToken,
  }) async {
    try {
      final commentsEndpoint = Uri.parse('$graphApiBaseUrl/$mediaId/comments');
      await _httpClient.post(commentsEndpoint, body: {
        'message': comment,
        'access_token': accessToken,
      }).timeout(const Duration(seconds: 15));
    } catch (_) {
      // First comment failure does not invalidate master post publication
    }
  }

  @override
  Future<PublishExecutionResult> reconcileAmbiguousOutcome({
    required SocialAccount account,
    required PublishAttempt attempt,
  }) async {
    final igUserId = account.externalAccountId;
    final accessToken = _resolveAccessToken(account);

    if (igUserId == null || accessToken == null) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.ambiguousTimeout,
        sanitizedErrorMessage: 'Unable to reconcile ambiguous status without credentials.',
      );
    }

    try {
      final recentMediaUrl = Uri.parse(
        '$graphApiBaseUrl/$igUserId/media?fields=id,caption,permalink,timestamp&limit=5&access_token=$accessToken',
      );
      final response = await _httpClient.get(recentMediaUrl).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final mediaList = data['data'] as List<dynamic>? ?? [];

        // Check if any recent post was published around the attempt timestamp
        final attemptUtc = attempt.startedAtUtc;
        for (final item in mediaList) {
          final timestampStr = item['timestamp'] as String?;
          if (timestampStr != null) {
            final postTime = DateTime.tryParse(timestampStr)?.toUtc();
            if (postTime != null &&
                postTime.difference(attemptUtc).abs() < const Duration(minutes: 5)) {
              return PublishExecutionResult.success(
                externalPostId: item['id'] as String?,
                externalUrl: item['permalink'] as String?,
              );
            }
          }
        }
      }
    } catch (_) {}

    return const PublishExecutionResult.ambiguousTimeout(
      sanitizedErrorMessage:
          'Publication status could not be confirmed on Instagram. Please verify in the Instagram app before retrying to prevent duplicate posts.',
    );
  }

  @override
  Future<bool> refreshConnection(SocialAccount account) async {
    return account.connectionStatus == ConnectionStatus.connected;
  }

  // --- Helper Methods ---
  String? _resolveAccessToken(SocialAccount account) {
    if (defaultAccessToken != null && defaultAccessToken!.isNotEmpty) {
      return defaultAccessToken;
    }
    for (final s in account.scopes) {
      if (s.startsWith('token:')) {
        return s.substring(6);
      }
    }
    return null;
  }

  String _extractContainerId(http.Response response) {
    if (response.statusCode != 200) {
      _throwParsedError(response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final containerId = data['id'] as String?;
    if (containerId == null || containerId.isEmpty) {
      throw Exception('Instagram Graph API did not return a valid container ID.');
    }
    return containerId;
  }

  void _throwParsedError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        final message = error['message'] as String? ?? 'Unknown error';
        final code = error['code']?.toString() ?? 'GENERIC_ERROR';
        final subcode = error['error_subcode']?.toString() ?? '';
        throw Exception('Meta Graph API Error [$code/$subcode]: $message');
      }
    } catch (e) {
      if (e.toString().contains('Meta Graph API Error')) rethrow;
    }
    throw Exception('Instagram Graph API request failed with status ${response.statusCode}');
  }

  PublishExecutionResult _mapExceptionToResult(dynamic e) {
    final str = e.toString();

    // Redact any tokens or raw auth payloads from error output
    final sanitized = str.replaceAll(RegExp(r'access_token=[a-zA-Z0-9_\-]+'), 'access_token=[REDACTED]');

    if (sanitized.contains('190') || sanitized.contains('OAuthException')) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.authentication,
        rawErrorCode: 'OAUTH_TOKEN_EXPIRED',
        sanitizedErrorMessage: 'Instagram authentication expired. Re-connection is required.',
      );
    }

    if (sanitized.contains('2207008') || sanitized.contains('rate limit')) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.rateLimit,
        rawErrorCode: 'IG_RATE_LIMIT',
        sanitizedErrorMessage:
            'Instagram 24-hour publishing limit (25 posts) reached for this account. Try again tomorrow.',
      );
    }

    if (sanitized.contains('2207001') || sanitized.contains('2207003') || sanitized.contains('aspect ratio')) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.validation,
        rawErrorCode: 'MEDIA_SPEC_MISMATCH',
        sanitizedErrorMessage:
            'Instagram rejected the media format or aspect ratio. Ensure photos are 4:5 to 1.91:1 and videos are 9:16.',
      );
    }

    return PublishExecutionResult.failure(
      errorCategory: ErrorCategory.transientNetwork,
      rawErrorCode: 'IG_API_ERROR',
      sanitizedErrorMessage: sanitized,
    );
  }
}
