import '../enums/error_category.dart';
import '../models/content_post.dart';
import '../models/media_asset.dart';
import '../models/post_variant.dart';
import '../models/publish_attempt.dart';
import '../models/social_account.dart';
import '../validators/preflight_validator.dart';

/// Result from a publish execution attempt.
class PublishExecutionResult {
  final bool isSuccess;
  final String? externalPostId;
  final String? externalUrl;
  final ErrorCategory? errorCategory;
  final String? rawErrorCode;
  final String? sanitizedErrorMessage;
  final bool isAmbiguousOutcome;

  const PublishExecutionResult.success({
    required this.externalPostId,
    required this.externalUrl,
  })  : isSuccess = true,
        errorCategory = null,
        rawErrorCode = null,
        sanitizedErrorMessage = null,
        isAmbiguousOutcome = false;

  const PublishExecutionResult.failure({
    required this.errorCategory,
    this.rawErrorCode,
    required this.sanitizedErrorMessage,
    this.isAmbiguousOutcome = false,
  })  : isSuccess = false,
        externalPostId = null,
        externalUrl = null;

  const PublishExecutionResult.ambiguousTimeout({
    required this.sanitizedErrorMessage,
  })  : isSuccess = false,
        isAmbiguousOutcome = true,
        errorCategory = ErrorCategory.ambiguousTimeout,
        rawErrorCode = 'TIMEOUT_AMBIGUOUS',
        externalPostId = null,
        externalUrl = null;
}

/// Abstract contract for platform publishing adapters per ARCHITECTURE.md.
/// UI and use-case code only interact through this contract.
abstract class PublishingAdapter {
  /// Returns supported capability strings for [account].
  List<String> getCapabilities(SocialAccount account);

  /// Preflight check for [variant] against [account].
  PreflightResult validateDraft({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    List<MediaAsset> attachedMedia = const [],
  });

  /// Executes publish operation. Never blocks forever; normalizes provider responses.
  Future<PublishExecutionResult> publishNow({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    required String idempotencyKey,
    List<MediaAsset> attachedMedia = const [],
  });

  /// Reconciles an ambiguous outcome when a request timed out after submission.
  Future<PublishExecutionResult> reconcileAmbiguousOutcome({
    required SocialAccount account,
    required PublishAttempt attempt,
  });

  /// Checks and refreshes connection tokens if supported.
  Future<bool> refreshConnection(SocialAccount account);
}
