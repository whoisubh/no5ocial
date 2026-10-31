import 'package:no5ocial/domain/adapters/publishing_adapter.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_attempt.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';

/// Production fallback adapter for platforms that have no official API adapter.
/// Returns honest error results — never fakes success.
class UnsupportedPlatformAdapter implements PublishingAdapter {
  const UnsupportedPlatformAdapter();

  @override
  List<String> getCapabilities(SocialAccount account) {
    return const ['manual_handoff'];
  }

  @override
  PreflightResult validateDraft({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    List<MediaAsset> attachedMedia = const [],
  }) {
    final baseResult = PreflightValidator.validate(
      post: post,
      variant: variant,
      account: account,
      attachedMedia: attachedMedia,
    );

    final issues = List<ValidationIssue>.from(baseResult.issues);
    issues.add(
      ValidationIssue(
        severity: ValidationSeverity.blocker,
        code: 'UNSUPPORTED_PLATFORM',
        message:
            'Automated publishing is not available for ${account.platform.displayName}. Use manual handoff instead.',
        remedy:
            'Mark this channel as manual-only, or remove it from the publish destinations.',
      ),
    );

    return PreflightResult(issues: issues);
  }

  @override
  Future<PublishExecutionResult> publishNow({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    required String idempotencyKey,
    List<MediaAsset> attachedMedia = const [],
  }) async {
    return PublishExecutionResult.failure(
      errorCategory: ErrorCategory.validation,
      rawErrorCode: 'UNSUPPORTED_PLATFORM',
      sanitizedErrorMessage:
          '${account.platform.displayName} does not have an official API adapter. '
          'Use manual handoff to publish to this platform.',
    );
  }

  @override
  Future<PublishExecutionResult> reconcileAmbiguousOutcome({
    required SocialAccount account,
    required PublishAttempt attempt,
  }) async {
    return const PublishExecutionResult.failure(
      errorCategory: ErrorCategory.validation,
      rawErrorCode: 'UNSUPPORTED_PLATFORM_RECONCILE',
      sanitizedErrorMessage:
          'Cannot reconcile outcomes for unsupported platforms.',
    );
  }

  @override
  Future<bool> refreshConnection(SocialAccount account) async {
    return false;
  }
}

