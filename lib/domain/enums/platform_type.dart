/// Supported social platform targets in no5ocial.
enum PlatformType {
  instagram(
    displayName: 'Instagram',
    iconName: 'instagram',
    maxCaptionLength: 2200,
    maxHashtags: 30,
    supportsTextOnly: false,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: true,
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
  ),
  tiktok(
    displayName: 'TikTok',
    iconName: 'tiktok',
    maxCaptionLength: 4000,
    maxHashtags: 30,
    supportsTextOnly: false,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: true,
  ),
  pinterest(
    displayName: 'Pinterest',
    iconName: 'pinterest',
    maxCaptionLength: 500,
    maxHashtags: 20,
    supportsTextOnly: false,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: false,
    defaultRequiresMedia: true,
  ),
  threads(
    displayName: 'Threads',
    iconName: 'threads',
    maxCaptionLength: 500,
    maxHashtags: 10,
    supportsTextOnly: true,
    supportsImage: true,
    supportsVideo: true,
    supportsCarousel: true,
    defaultRequiresMedia: false,
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
      case PlatformType.pinterest:
        return 'Profile';
      case PlatformType.tiktok:
        return 'Account';
    }
  }

  /// Full target name (e.g. 'YouTube Channel', 'Instagram Profile', 'Facebook Page').
  String get fullTargetName => '$displayName $accountNoun';

  /// Platform-specific button CTA (e.g. 'Authenticate YouTube Channel', 'Authenticate Instagram Profile').
  String get authenticateCta => 'Authenticate $displayName $accountNoun';
}
