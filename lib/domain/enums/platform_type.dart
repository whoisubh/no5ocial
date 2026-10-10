/// Supported social platform targets in No5ocial.
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
}
