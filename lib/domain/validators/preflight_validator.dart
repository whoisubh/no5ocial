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
    if (platform == PlatformType.threads && hashtagCount > 1) {
      issues.add(
        ValidationIssue(
          severity: ValidationSeverity.blocker,
          code: 'TOO_MANY_HASHTAGS_THREADS',
          message: 'Meta Threads officially permits only 1 hashtag/topic tag per post (found $hashtagCount).',
          remedy: 'Keep only 1 main hashtag for Threads to avoid API rejection.',
        ),
      );
    } else if (platform == PlatformType.instagram && hashtagCount > platform.maxHashtags) {
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
              'YouTube ignores all hashtags if more than 15 are included in the description (found $hashtagCount).',
          remedy: 'Keep hashtags under 15 for optimal discovery.',
        ),
      );
    }

    // 7. Media requirements and counts per platform
    final imageAssets = attachedMedia.where((m) => m.mediaType == MediaType.image).toList();
    final videoAssets = attachedMedia.where((m) => m.mediaType == MediaType.video).toList();

    if (platform == PlatformType.x) {
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
      if (imageAssets.isNotEmpty && videoAssets.isNotEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'MIXED_MEDIA_X',
            message: 'X does not support mixing photos and videos in a single tweet.',
            remedy: 'Attach either up to 4 images OR 1 video.',
          ),
        );
      }
      if (imageAssets.length > 4) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_IMAGES_X',
            message: 'X supports a maximum of 4 images per tweet (found ${imageAssets.length}).',
            remedy: 'Remove ${imageAssets.length - 4} images to comply with the 4-image limit.',
          ),
        );
      }
      if (videoAssets.length > 1) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_VIDEOS_X',
            message: 'X supports a maximum of 1 video per tweet (found ${videoAssets.length}).',
            remedy: 'Select only 1 video asset.',
          ),
        );
      }
    } else if (platform == PlatformType.instagram) {
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
      if (attachedMedia.length > 10) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_ITEMS_INSTAGRAM',
            message: 'Instagram carousels support a maximum of 10 media items (found ${attachedMedia.length}).',
            remedy: 'Select 10 or fewer media items.',
          ),
        );
      }
      for (final img in imageAssets) {
        final ext = img.fileName.contains('.') ? img.fileName.split('.').last.toLowerCase() : '';
        if (ext != 'jpg' && ext != 'jpeg') {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.warning,
              code: 'NON_JPEG_INSTAGRAM',
              message: 'Instagram Content Publishing API recommends JPEG format for "${img.fileName}". PNG/WEBP may fail container creation.',
              remedy: 'Convert "${img.fileName}" to JPEG for guaranteed API publishing.',
            ),
          );
        }
      }
    } else if (platform == PlatformType.youtube) {
      if (videoAssets.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'VIDEO_REQUIRED_YOUTUBE',
            message: 'YouTube requires a video asset. Text and image-only uploads are unsupported.',
            remedy: 'Attach a supported video file.',
          ),
        );
      } else if (videoAssets.length > 1) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_VIDEOS_YOUTUBE',
            message: 'YouTube Data API uploads 1 video per request (found ${videoAssets.length}).',
            remedy: 'Select only 1 video asset.',
          ),
        );
      }
      if (imageAssets.isNotEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.warning,
            code: 'IMAGES_IGNORED_YOUTUBE',
            message: 'YouTube Data API does not accept images for video uploads. Images will be excluded.',
            remedy: 'Only the video asset will be published to YouTube.',
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
    } else if (platform == PlatformType.threads) {
      if (effectiveCaption.trim().isEmpty && attachedMedia.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'EMPTY_POST_THREADS',
            message: 'Threads posts require either text copy or media.',
            remedy: 'Enter copy or attach media.',
          ),
        );
      }
      if (attachedMedia.length > 20) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_ITEMS_THREADS',
            message: 'Threads carousel supports up to 20 media items (found ${attachedMedia.length}).',
            remedy: 'Select 20 or fewer media items.',
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
      if (imageAssets.length > 20) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_IMAGES_LINKEDIN',
            message: 'LinkedIn supports a maximum of 20 images per post (found ${imageAssets.length}).',
            remedy: 'Select 20 or fewer images.',
          ),
        );
      }
      if (videoAssets.length > 1) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_VIDEOS_LINKEDIN',
            message: 'LinkedIn supports a maximum of 1 video per post (found ${videoAssets.length}).',
            remedy: 'Select only 1 video asset.',
          ),
        );
      }
    } else if (platform == PlatformType.facebook) {
      if (effectiveCaption.trim().isEmpty && attachedMedia.isEmpty) {
        issues.add(
          const ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'EMPTY_POST_FACEBOOK',
            message: 'Facebook posts require either text copy or media.',
            remedy: 'Enter copy or attach media.',
          ),
        );
      }
      if (attachedMedia.length > 10) {
        issues.add(
          ValidationIssue(
            severity: ValidationSeverity.blocker,
            code: 'TOO_MANY_ITEMS_FACEBOOK',
            message: 'Facebook carousel supports up to 10 media items (found ${attachedMedia.length}).',
            remedy: 'Select 10 or fewer media items.',
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
        final maxVideoMb = platform.maxVideoSizeBytes ~/ (1024 * 1024);
        if (platform != PlatformType.youtube && media.sizeBytes > platform.maxVideoSizeBytes) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'VIDEO_TOO_LARGE',
              message: 'Video "${media.fileName}" (${media.formattedSize}) exceeds ${platform.displayName}\'s ${maxVideoMb}MB limit.',
              remedy: 'Compress video under ${maxVideoMb}MB prior to publishing.',
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
        final maxImageMb = platform.maxImageSizeMb;
        if (maxImageMb > 0 && media.sizeBytes > maxImageMb * 1024 * 1024) {
          issues.add(
            ValidationIssue(
              severity: ValidationSeverity.blocker,
              code: 'IMAGE_TOO_LARGE',
              message: 'Image "${media.fileName}" (${media.formattedSize}) exceeds ${platform.displayName}\'s ${maxImageMb}MB limit.',
              remedy: 'Resize or compress image under ${maxImageMb}MB.',
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
