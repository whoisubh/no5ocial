import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';

class PreviewCard extends StatelessWidget {
  final SocialAccount account;
  final String caption;
  final String postTitle;
  final List<MediaAsset> mediaAssets;

  const PreviewCard({
    super.key,
    required this.account,
    required this.caption,
    required this.postTitle,
    required this.mediaAssets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated preview banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                PlatformLogo(
                  platform: account.platform,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${account.platform.displayName} Preview (Simulated)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  account.handle,
                  style: AppTypography.code.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Body depending on platform
          Padding(
            padding: const EdgeInsets.all(14),
            child: switch (account.platform) {
              PlatformType.x => _buildXPreview(),
              PlatformType.instagram => _buildInstagramPreview(),
              PlatformType.youtube => _buildYouTubePreview(),
              PlatformType.linkedin => _buildLinkedInPreview(),
              PlatformType.facebook => _buildFacebookPreview(),
              PlatformType.threads => _buildThreadsPreview(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildXPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inkLight,
              child: Text(
                account.displayName.isNotEmpty ? account.displayName[0] : 'X',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: AppTypography.titleMedium.copyWith(fontSize: 13),
                ),
                Text(
                  account.handle,
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          caption.isEmpty ? '(Empty caption)' : caption,
          style: AppTypography.bodyLarge.copyWith(fontSize: 14),
        ),
        if (mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(mediaAssets.first),
        ],
      ],
    );
  }

  Widget _buildInstagramPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.purple, Colors.pink],
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Text(
                  account.displayName.isNotEmpty ? account.displayName[0] : 'I',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              account.handle,
              style: AppTypography.titleMedium.copyWith(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (mediaAssets.isNotEmpty)
          _buildMediaPlaceholder(mediaAssets.first, aspectRatio: 1.0)
        else
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Text(
                '⚠️ Instagram requires an image or video asset',
                style: AppTypography.bodySecondary,
              ),
            ),
          ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${account.handle} ',
                style: AppTypography.titleMedium.copyWith(fontSize: 13),
              ),
              TextSpan(
                text: caption.isEmpty ? '(Empty caption)' : caption,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mediaAssets.isNotEmpty)
          _buildMediaPlaceholder(mediaAssets.first, aspectRatio: 16 / 9)
        else
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '⚠️ YouTube requires video asset',
                style: AppTypography.bodySecondary,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          postTitle.isEmpty ? 'Untitled Video' : postTitle,
          style: AppTypography.titleMedium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${account.displayName} • 0 views • Just now',
          style: AppTypography.bodySecondary.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            caption.isEmpty ? 'Description...' : caption,
            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedInPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.linkedin,
              child: const Icon(Icons.business, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: AppTypography.titleMedium.copyWith(fontSize: 13),
                ),
                Text(
                  '14,820 followers • Just now',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          caption.isEmpty ? '(Empty post copy)' : caption,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
        ),
        if (mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(mediaAssets.first, aspectRatio: 16 / 9),
        ],
      ],
    );
  }

  Widget _buildFacebookPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.facebook,
              child: const Icon(Icons.thumb_up, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: AppTypography.titleMedium.copyWith(fontSize: 13),
                ),
                Text(
                  'Sponsored / Page Post • Public',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          caption.isEmpty ? '(Empty post copy)' : caption,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
        ),
        if (mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(mediaAssets.first, aspectRatio: 16 / 9),
        ],
      ],
    );
  }

  Widget _buildThreadsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Text(
                account.displayName.isNotEmpty ? account.displayName[0] : '@',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              account.handle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          caption.isEmpty ? 'Start a thread...' : caption,
          style: const TextStyle(fontSize: 13),
        ),
        if (mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMediaPlaceholder(mediaAssets.first, aspectRatio: 4 / 3),
        ],
      ],
    );
  }

  Widget _buildMediaPlaceholder(
    MediaAsset media, {
    double aspectRatio = 16 / 9,
  }) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  media.mediaType.name == 'video'
                      ? Icons.play_circle_fill
                      : Icons.image_outlined,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  media.fileName,
                  style: AppTypography.labelMedium.copyWith(fontSize: 11),
                ),
                Text(
                  '${media.formattedSize} • ${media.mediaType.label}',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
