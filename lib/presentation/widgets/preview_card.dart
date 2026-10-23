import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';
import 'package:no5ocial/core/services/video_thumbnail_service.dart';

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
    final previewUrl = media.localPreviewUrl;
    final isVideo = media.mediaType == MediaType.video;

    if (!isVideo && previewUrl != null && previewUrl.isNotEmpty) {
      Widget imageWidget;
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        imageWidget = Image.network(
          previewUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildMediaFallback(media),
        );
      } else if (!kIsWeb) {
        final file = File(previewUrl);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildMediaFallback(media),
          );
        } else {
          imageWidget = _buildMediaFallback(media);
        }
      } else {
        imageWidget = _buildMediaFallback(media);
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
      );
    }

    if (isVideo) {
      Widget videoFallback = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${media.fileName} (${media.formattedSize})',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      Widget videoDisplay;
      if (previewUrl != null && previewUrl.isNotEmpty) {
        final isImageExt = previewUrl.endsWith('.jpg') ||
            previewUrl.endsWith('.jpeg') ||
            previewUrl.endsWith('.png') ||
            previewUrl.endsWith('.webp');

        if (isImageExt && (previewUrl.startsWith('http://') || previewUrl.startsWith('https://'))) {
          videoDisplay = Stack(
            fit: StackFit.expand,
            children: [
              Image.network(previewUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => videoFallback),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            ],
          );
        } else {
          // Local video file path or network video: query video thumbnail extractor
          videoDisplay = FutureBuilder<Uint8List?>(
            future: VideoThumbnailService.getThumbnail(previewUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(snapshot.data!, fit: BoxFit.cover),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${media.fileName} (${media.formattedSize})',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return videoFallback;
            },
          );
        }
      } else {
        videoDisplay = videoFallback;
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: videoDisplay,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _buildMediaFallback(media),
    );
  }

  Widget _buildMediaFallback(MediaAsset media) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            media.mediaType == MediaType.video
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
    );
  }
}
