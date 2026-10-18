import '../enums/connection_status.dart';
import '../enums/media_type.dart';
import '../enums/platform_type.dart';
import '../models/brand.dart';
import '../models/content_post.dart';
import '../models/media_asset.dart';
import '../models/post_variant.dart';
import '../models/social_account.dart';

/// Severity of a preflight validation item.
enum ValidationSeverity {
  blocker,
  warning,
  info,
}

/// An individual preflight validation finding.
class ValidationIssue {
  final ValidationSeverity severity;
  final String code;
  final String message;
  final String? remedy;

  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.remedy,
  });

  bool get isBlocker => severity == ValidationSeverity.blocker;
  bool get isWarning => severity == ValidationSeverity.warning;
}

/// Preflight outcome for a single destination account.
class PreflightResult {
  final SocialAccount account;
  final String effectiveCaption;
  final int characterCount;
  final int maxCharacters;
  final int hashtagCount;
  final List<ValidationIssue> issues;

  const PreflightResult({
    required this.account,
    required this.effectiveCaption,
    required this.characterCount,
    required this.maxCharacters,
    required this.hashtagCount,
    required this.issues,
  });

  bool get isValid => issues.every((i) => !i.isBlocker);
  List<ValidationIssue> get blockers => issues.where((i) => i.isBlocker).toList();
  List<ValidationIssue> get warnings => issues.where((i) => i.isWarning).toList();
}

/// Core validation engine implementing platform-specific rules and cross-brand sanity checks.
abstract final class PreflightValidator {
  static final RegExp _hashtagRegex = RegExp(r'#\w+');

  /// Validates a single destination target prior to scheduling or publishing.
  static PreflightResult validate({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    Brand? postBrand,
    Brand? accountBrand,
    List<MediaAsset> attachedMedia = const [],
  }) {
    final issues = <ValidationIssue>[];
    final platform = account.platform;

    // 1. Resolve effective caption
    final effectiveCaption = variant.hasCaptionOverride
        ? variant.captionOverride!
        : post.defaultCaption;

    final charCount = effectiveCaption.length;
    final maxChars = platform.maxCaptionLength;

    // 2. Count hashtags
    final hashtagCount = _hashtagRegex.allMatches(effectiveCaption).length;

    // 3. Brand Mismatch Warning
    if (account.brandId != post.brandId) {
      final postBrandName = postBrand?.name ?? 'selected draft brand';
      final accountBrandName = accountBrand?.name ?? 'account brand';
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'BRAND_MISMATCH',
          message:
              'Account "${account.displayName}" (${account.handle}) belongs to "$accountBrandName", but draft belongs to "$postBrandName".',
          remedy: 'Verify that cross-brand publishing is intentional.',
        ),
      );
    }

    // 4. Connection Status Check
    if (account.connectionStatus != ConnectionStatus.connected && !account.isManualOnly) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'CONNECTION_INVALID',
          message:
              'Account connection status is ${account.connectionStatus.label}.',
          remedy: 'Re-authenticate or verify permissions in Accounts settings.',
        ),
      );
    }

    // 5. Character Limit
    if (charCount > maxChars) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'CAPTION_TOO_LONG',
          message:
              'Caption exceeds ${platform.displayName} limit ($charCount / $maxChars characters).',
          remedy: 'Shorten caption by ${charCount - maxChars} characters.',
        ),
      );
    }

    // 6. Hashtag limits
    if (platform == PlatformType.instagram && hashtagCount > platform.maxHashtags) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'TOO_MANY_HASHTAGS',
          message:
              'Instagram permits a maximum of ${platform.maxHashtags} hashtags (found $hashtagCount).',
          remedy: 'Remove ${hashtagCount - platform.maxHashtags} hashtags to avoid API rejection.',
        ),
      );
    } else if (platform == PlatformType.youtube && hashtagCount > platform.maxHashtags) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'YOUTUBE_HASHTAG_OVERFLOW',
          message:
              'YouTube ignores all hashtags if more than 15 are included (found $hashtagCount).',
          remedy: 'Keep hashtags under 15 for optimal discovery.',
        ),
      );
    }

    // 7. Media requirements per platform
    if (platform == PlatformType.instagram) {
      if (attachedMedia.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'MEDIA_REQUIRED_INSTAGRAM',
            message: 'Instagram requires at least one image or video asset. Text-only posts are unsupported.',
            remedy: 'Attach an image or video asset.',
          ),
        );
      }
    } else if (platform == PlatformType.youtube) {
      final hasVideo = attachedMedia.any((m) => m.mediaType == MediaType.video);
      if (!hasVideo) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'VIDEO_REQUIRED_YOUTUBE',
            message: 'YouTube requires a video asset. Text and image-only uploads are unsupported.',
            remedy: 'Attach a supported video file.',
          ),
        );
      }
      if (post.title.trim().isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TITLE_REQUIRED_YOUTUBE',
            message: 'YouTube uploads require a video title.',
            remedy: 'Provide a title in the post settings.',
          ),
        );
      } else if (post.title.length > 100) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TITLE_TOO_LONG_YOUTUBE',
            message: 'YouTube title exceeds 100 characters (${post.title.length} chars).',
            remedy: 'Shorten post title to 100 characters or less.',
          ),
        );
      }
    } else if (platform == PlatformType.x) {
      if (effectiveCaption.trim().isEmpty && attachedMedia.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'EMPTY_POST_X',
            message: 'Post cannot be empty. X requires either text copy or media.',
            remedy: 'Enter a caption or attach media.',
          ),
        );
      }
    } else if (platform == PlatformType.linkedin) {
      if (effectiveCaption.trim().isEmpty && attachedMedia.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'EMPTY_POST_LINKEDIN',
            message: 'LinkedIn posts require either commentary text or an attachment.',
            remedy: 'Enter text or attach media.',
          ),
        );
      }
    } else if (platform == PlatformType.facebook || platform == PlatformType.threads) {
      if (effectiveCaption.trim().isEmpty && attachedMedia.isEmpty) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'EMPTY_POST_${platform.name.toUpperCase()}',
            message: '${platform.displayName} posts require either text copy or media.',
            remedy: 'Enter copy or attach media.',
          ),
        );
      }
    }

    // 8. Format & file size validation (Strict Misuse Prevention)
    const allowedImageExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    const allowedVideoExts = ['mp4', 'mov', 'webm'];

    for (final media in attachedMedia) {
      final ext = media.fileName.contains('.') ? media.fileName.split('.').last.toLowerCase() : '';
      if (media.mediaType == MediaType.video) {
        if (!allowedVideoExts.contains(ext)) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'UNSUPPORTED_VIDEO_FORMAT',
              message: 'Video format ".$ext" is unsupported for ${platform.displayName}.',
              remedy: 'Use a standard MP4, MOV, or WEBM video.',
            ),
          );
        }
        if (media.sizeBytes > 100 * 1024 * 1024) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'VIDEO_TOO_LARGE',
              message: 'Video "${media.fileName}" (${media.formattedSize}) exceeds the 100MB limit.',
              remedy: 'Compress video under 100MB prior to publishing.',
            ),
          );
        }
      } else {
        if (!allowedImageExts.contains(ext)) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'UNSUPPORTED_IMAGE_FORMAT',
              message: 'Image format ".$ext" is unsupported for ${platform.displayName}.',
              remedy: 'Use JPG, PNG, WEBP, or GIF format.',
            ),
          );
        }
        if (media.sizeBytes > 15 * 1024 * 1024) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'IMAGE_TOO_LARGE',
              message: 'Image "${media.fileName}" (${media.formattedSize}) exceeds the 15MB limit.',
              remedy: 'Resize or compress image under 15MB.',
            ),
          );
        }
      }
    }

    // 9. Manual Handoff Guidance
    if (account.isManualOnly) {
      issues.add(
        const ValidationIssue(
          severity: ValidationSeverity.info,
          code: 'MANUAL_HANDOFF_FLOW',
          message: 'This account uses Manual Publishing Handoff. Copy caption & asset to paste directly.',
        ),
      );
    }

    return PreflightResult(
      account: account,
      effectiveCaption: effectiveCaption,
      characterCount: charCount,
      maxCharacters: maxChars,
      hashtagCount: hashtagCount,
      issues: issues,
    );
  }
}
