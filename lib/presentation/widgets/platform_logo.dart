import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';

/// Renders official social media brand logos using the standard font_awesome_flutter package.
class PlatformLogo extends StatelessWidget {
  final PlatformType platform;
  final double size;
  final Color? color;

  const PlatformLogo({
    super.key,
    required this.platform,
    this.size = 18,
    this.color,
  });

  static FaIconData getIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return FontAwesomeIcons.instagram;
      case PlatformType.youtube:
        return FontAwesomeIcons.youtube;
      case PlatformType.linkedin:
        return FontAwesomeIcons.linkedin;
      case PlatformType.x:
        return FontAwesomeIcons.xTwitter;
      case PlatformType.facebook:
        return FontAwesomeIcons.facebook;
      case PlatformType.threads:
        return FontAwesomeIcons.threads;
    }
  }

  static Color getBrandColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return AppColors.instagram;
      case PlatformType.youtube:
        return AppColors.youtube;
      case PlatformType.linkedin:
        return AppColors.linkedin;
      case PlatformType.x:
        return AppColors.x;
      case PlatformType.facebook:
        return AppColors.facebook;
      case PlatformType.threads:
        return AppColors.threads;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? getBrandColor(platform);
    return FaIcon(
      getIcon(platform),
      size: size,
      color: iconColor,
    );
  }
}
