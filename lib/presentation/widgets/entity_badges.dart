import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';

/// Standardized Company / Brand Badge.
/// Always renders a distinct company building icon so the user immediately
/// identifies this label as a Company / Brand.
class CompanyBadge extends StatelessWidget {
  final Brand? brand;
  final String? companyName;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showBorder;

  const CompanyBadge({
    super.key,
    this.brand,
    this.companyName,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = companyName ?? brand?.name ?? 'Company';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? AppColors.accent
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));

    final borderColor = isSelected
        ? AppColors.accent
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B));

    final iconColor = isSelected
        ? Colors.white
        : AppColors.accent;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withAlpha(40) : AppColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.business_rounded,
              size: isCompact ? 11 : 13,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: badge,
    );
  }
}

/// Standardized Group Badge.
/// Always renders a distinct folder icon so the user immediately
/// identifies this label as a Channel Group / Product Bundle.
class GroupBadge extends StatelessWidget {
  final ChannelGroup? group;
  final String? groupName;
  final int? channelCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showBorder;

  const GroupBadge({
    super.key,
    this.group,
    this.groupName,
    this.channelCount,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = groupName ?? group?.name ?? 'Group';
    final count = channelCount ?? group?.accountIds.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const groupColor = Color(0xFF6366F1); // Indigo theme for groups/folders

    final bgColor = isSelected
        ? groupColor
        : (isDark ? const Color(0xFF1E1E38) : const Color(0xFFEEF2FF));

    final borderColor = isSelected
        ? groupColor
        : (isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFE0E7FF) : const Color(0xFF312E81));

    final iconColor = isSelected
        ? Colors.white
        : groupColor;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withAlpha(40) : groupColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.folder_rounded,
              size: isCompact ? 11 : 13,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5)),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: badge,
    );
  }
}

/// Standardized Channel Badge.
/// Always renders the official platform brand icon (Instagram icon for Instagram,
/// YouTube icon for YouTube, X icon for X, LinkedIn icon for LinkedIn, etc.).
class ChannelBadge extends StatelessWidget {
  final SocialAccount? account;
  final PlatformType? platform;
  final String? handle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showBorder;

  const ChannelBadge({
    super.key,
    this.account,
    this.platform,
    this.handle,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePlatform = platform ?? account?.platform ?? PlatformType.instagram;
    final displayHandle = handle ?? account?.handle ?? effectivePlatform.displayName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pColor = PlatformLogo.getBrandColor(effectivePlatform);

    final bgColor = isSelected
        ? pColor.withAlpha(isDark ? 50 : 25)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    final borderColor = isSelected
        ? pColor
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformLogo(
            platform: effectivePlatform,
            size: isCompact ? 12 : 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              displayHandle,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (account != null && account!.isManualOnly) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'Manual',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: badge,
    );
  }
}
