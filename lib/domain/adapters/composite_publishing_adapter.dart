import '../enums/platform_type.dart';
import '../models/content_post.dart';
import '../models/media_asset.dart';
import '../models/post_variant.dart';
import '../models/publish_attempt.dart';
import '../models/social_account.dart';
import '../validators/preflight_validator.dart';
import 'instagram_publishing_adapter.dart';
import 'linkedin_publishing_adapter.dart';
import 'publishing_adapter.dart';
import 'threads_publishing_adapter.dart';
import 'x_publishing_adapter.dart';
import 'youtube_publishing_adapter.dart';

/// Routes publishing, preflight validation, and reconciliation to the appropriate
/// platform-specific publishing adapter.
class CompositePublishingAdapter implements PublishingAdapter {
  final Map<PlatformType, PublishingAdapter> _platformAdapters;
  final PublishingAdapter _fallbackAdapter;

  CompositePublishingAdapter({
    Map<PlatformType, PublishingAdapter>? platformAdapters,
    PublishingAdapter? fallbackAdapter,
    String? instagramDefaultAccessToken,
  })  : _fallbackAdapter = fallbackAdapter ?? InstagramPublishingAdapter(),
        _platformAdapters = platformAdapters ?? {
          PlatformType.instagram: InstagramPublishingAdapter(
            defaultAccessToken: instagramDefaultAccessToken,
          ),
          PlatformType.linkedin: LinkedInPublishingAdapter(),
          PlatformType.x: XPublishingAdapter(),
          PlatformType.threads: ThreadsPublishingAdapter(),
          PlatformType.youtube: YouTubePublishingAdapter(),
        };

  PublishingAdapter _adapterFor(SocialAccount account) {
    return _platformAdapters[account.platform] ?? _fallbackAdapter;
  }

  @override
  List<String> getCapabilities(SocialAccount account) {
    return _adapterFor(account).getCapabilities(account);
  }

  @override
  PreflightResult validateDraft({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    List<MediaAsset> attachedMedia = const [],
  }) {
    return _adapterFor(account).validateDraft(
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
  }) {
    return _adapterFor(account).publishNow(
      post: post,
      variant: variant,
      account: account,
      idempotencyKey: idempotencyKey,
      attachedMedia: attachedMedia,
    );
  }

  @override
  Future<PublishExecutionResult> reconcileAmbiguousOutcome({
    required SocialAccount account,
    required PublishAttempt attempt,
  }) {
    return _adapterFor(account).reconcileAmbiguousOutcome(
      account: account,
      attempt: attempt,
    );
  }

  @override
  Future<bool> refreshConnection(SocialAccount account) {
    return _adapterFor(account).refreshConnection(account);
  }
}
