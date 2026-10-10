import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/social_account.dart';

class PlatformIconChip extends StatelessWidget {
  final SocialAccount account;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showConnectionState;
  final bool isCompact;

  const PlatformIconChip({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
    this.showConnectionState = true,
    this.isCompact = false,
  });

  static IconData getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return Icons.camera_alt_outlined;
      case PlatformType.youtube:
        return Icons.play_circle_outline;
      case PlatformType.linkedin:
        return Icons.business_outlined;
      case PlatformType.x:
        return Icons.tag_outlined;
    }
  }

  static Color getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return AppColors.instagram;
      case PlatformType.youtube:
        return AppColors.youtube;
      case PlatformType.linkedin:
        return AppColors.linkedin;
      case PlatformType.x:
        return AppColors.x;
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformColor = getPlatformColor(account.platform);
    final isConnected = account.connectionStatus == ConnectionStatus.connected;

    final border = isSelected
        ? Border.all(color: AppColors.accent, width: 1.5)
        : Border.all(color: AppColors.border, width: 1);

    final bg = isSelected ? AppColors.accentLight : AppColors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCompact ? 18 : 22,
                height: isCompact ? 18 : 22,
                decoration: BoxDecoration(
                  color: platformColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    getPlatformIcon(account.platform),
                    size: isCompact ? 11 : 13,
                    color: platformColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                account.handle,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontSize: isCompact ? 12 : 13,
                ),
              ),
              if (account.isManualOnly) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Manual',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (showConnectionState && !isConnected && !account.isManualOnly) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
