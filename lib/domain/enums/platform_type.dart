/// Supported social platform targets in no5ocial.
enum PlatformType {
  instagram(
    displayName: 'Instagram',
    iconName: 'instagram',
    maxCaptionLength: 2200,
    maxHashtags: 5,
    supportsTextOnly: false,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: true,
    maxImages: 10,
    maxVideos: 1,
    maxImageSizeMb: 8,
    maxVideoDurationMinutes: 15,
  ),
  youtube(
    displayName: 'YouTube',
    iconName: 'youtube',
    maxCaptionLength: 5000, // Description
    maxHashtags: 15,
    supportsTextOnly: false,
    supportsImage: false, // In MVP upload context
    supportsVideo: true,
    supportsCarousel: false,
    defaultRequiresMedia: true,
    maxImages: 0,
    maxVideos: 1,
    maxImageSizeMb: 0,
    maxVideoDurationMinutes: 720, // 12 hours
  ),
  linkedin(
    displayName: 'LinkedIn',
    iconName: 'linkedin',
    maxCaptionLength: 3000,
    maxHashtags: 30,
    supportsTextOnly: true,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: false,
    defaultRequiresMedia: false,
    maxImages: 20,
    maxVideos: 1,
    maxImageSizeMb: 8,
    maxVideoDurationMinutes: 10,
  ),
  x(
    displayName: 'X',
    iconName: 'x',
    maxCaptionLength: 280,
    maxHashtags: 10,
    supportsTextOnly: true,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: false,
    defaultRequiresMedia: false,
    maxImages: 4,
    maxVideos: 1,
    maxImageSizeMb: 5,
    maxVideoDurationMinutes: 2, // 140s standard
  ),
  facebook(
    displayName: 'Facebook',
    iconName: 'facebook',
    maxCaptionLength: 63206,
    maxHashtags: 30,
    supportsTextOnly: true,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: false,
    maxImages: 10,
    maxVideos: 1,
    maxImageSizeMb: 10,
    maxVideoDurationMinutes: 20,
  ),
  threads(
    displayName: 'Threads',
    iconName: 'threads',
    maxCaptionLength: 500,
    maxHashtags: 1, // Official Meta Threads API only accepts 1 topic tag / hashtag per post
    supportsTextOnly: true,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: false,
    maxImages: 20,
    maxVideos: 1,
    maxImageSizeMb: 8,
    maxVideoDurationMinutes: 5,
  );

  const PlatformType({
    required this.displayName,
    required this.iconName,
    required this.maxCaptionLength,
    required this.maxHashtags,
    required this.supportsTextOnly,
    required this.supportsImage,
    required this.supportsVideo,
    required this.supportsCarousel,
    required this.defaultRequiresMedia,
    required this.maxImages,
    required this.maxVideos,
    required this.maxImageSizeMb,
    required this.maxVideoDurationMinutes,
  });

  final String displayName;
  final String iconName;
  final int maxCaptionLength;
  final int maxHashtags;
  final bool supportsTextOnly;
  final bool supportsImage;
  final bool supportsVideo;
  final bool supportsCarousel;
  final bool defaultRequiresMedia;
  final int maxImages;
  final int maxVideos;
  final int maxImageSizeMb;
  final int maxVideoDurationMinutes;

  /// Natural platform entity noun (e.g. 'Channel' for YouTube, 'Profile' for Instagram/X/LinkedIn, 'Page' for Facebook).
  String get accountNoun {
    switch (this) {
      case PlatformType.youtube:
        return 'Channel';
      case PlatformType.facebook:
        return 'Page';
      case PlatformType.instagram:
      case PlatformType.x:
      case PlatformType.linkedin:
      case PlatformType.threads:
        return 'Profile';
    }
  }

  /// Full target name (e.g. 'YouTube Channel', 'Instagram Profile', 'Facebook Page').
  String get fullTargetName => '$displayName $accountNoun';

  /// Platform-specific button CTA (e.g. 'Authenticate YouTube Channel', 'Authenticate Instagram Profile').
  String get authenticateCta => 'Authenticate $displayName $accountNoun';

  /// Maximum video upload size in bytes.
  int get maxVideoSizeBytes {
    switch (this) {
      case PlatformType.instagram:
        return 300 * 1024 * 1024; // 300 MB Reels
      case PlatformType.threads:
        return 300 * 1024 * 1024; // 300 MB
      case PlatformType.x:
        return 512 * 1024 * 1024; // 512 MB standard
      case PlatformType.facebook:
        return 1024 * 1024 * 1024; // 1 GB
      case PlatformType.linkedin:
        return 5 * 1024 * 1024 * 1024; // 5 GB
      case PlatformType.youtube:
        return 256 * 1024 * 1024 * 1024; // 256 GB
    }
  }
}
