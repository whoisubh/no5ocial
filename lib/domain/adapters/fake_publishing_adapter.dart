import 'package:no5ocial/domain/adapters/publishing_adapter.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_attempt.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';

/// Test fake adapter explicitly labeled as FAKE for unit testing and local simulation.
/// DOES NOT call external social networks.
class FakePublishingAdapter implements PublishingAdapter {
  final bool shouldSimulateTimeout;
  final bool shouldSimulateTransientError;
  final bool shouldSimulateAuthError;
  final String? simulatedPostId;
  final String? simulatedPostUrl;

  const FakePublishingAdapter({
    this.shouldSimulateTimeout = false,
    this.shouldSimulateTransientError = false,
    this.shouldSimulateAuthError = false,
    this.simulatedPostId = 'fake_post_12345',
    this.simulatedPostUrl = 'https://example.com/fake_post_12345',
  });

  @override
  List<String> getCapabilities(SocialAccount account) {
    return ['caption', 'image', 'video', 'manual_handoff'];
  }

  @override
  PreflightResult validateDraft({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    List<MediaAsset> attachedMedia = const [],
  }) {
    return PreflightValidator.validate(
      post: post,
      variant: variant,
      account: account,
      attachedMedia: attachedMedia,
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
    if (shouldSimulateAuthError) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.authentication,
        rawErrorCode: 'AUTH_EXPIRED',
        sanitizedErrorMessage: 'The OAuth connection token has expired. Re-authentication required.',
      );
    }

    if (shouldSimulateTimeout) {
      return const PublishExecutionResult.ambiguousTimeout(
        sanitizedErrorMessage:
            'Request timed out after submission. Outcome is ambiguous; check destination before retry.',
      );
    }

    if (shouldSimulateTransientError) {
      return const PublishExecutionResult.failure(
        errorCategory: ErrorCategory.rateLimit,
        rawErrorCode: 'RATE_LIMIT_429',
        sanitizedErrorMessage: 'Provider rate limit exceeded. Retryable after backoff period.',
      );
    }

    return PublishExecutionResult.success(
      externalPostId: simulatedPostId,
      externalUrl: simulatedPostUrl,
    );
  }

  @override
  Future<PublishExecutionResult> reconcileAmbiguousOutcome({
    required SocialAccount account,
    required PublishAttempt attempt,
  }) async {
    // Fakes reconciliation response
    return PublishExecutionResult.success(
      externalPostId: simulatedPostId,
      externalUrl: simulatedPostUrl,
    );
  }

  @override
  Future<bool> refreshConnection(SocialAccount account) async {
    return true;
  }
}
