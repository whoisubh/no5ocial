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
import 'package:no5ocial/presentation/screens/media/media_preview_screen.dart';

class PreviewCard extends StatefulWidget {
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
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  bool _showSafeZone = false;
  bool _isVerticalFormat = false;

  bool get _isVerticalCandidate =>
      widget.account.platform == PlatformType.youtube ||
      widget.account.platform == PlatformType.instagram;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.surfaceOf(context);
    final surfaceSecColor = AppColors.surfaceSecOf(context);
    final borderColor = AppColors.borderOf(context);
    final textSecColor = AppColors.textSecOf(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated preview banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceSecColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                PlatformLogo(
                  platform: widget.account.platform,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.account.platform.displayName} Preview',
                  style: AppTypography.labelSmall.copyWith(
                    color: textSecColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Format switcher for YouTube & Instagram (Feed vs Shorts/Reels)
                if (_isVerticalCandidate) ...[
                  InkWell(
                    onTap: () => setState(() => _isVerticalFormat = !_isVerticalFormat),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isVerticalFormat ? AppColors.accent.withAlpha(30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isVerticalFormat ? AppColors.accent : borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isVerticalFormat ? Icons.stay_current_portrait : Icons.crop_16_9,
                            size: 11,
                            color: _isVerticalFormat ? AppColors.accent : textSecColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isVerticalFormat
                                ? (widget.account.platform == PlatformType.youtube ? 'Short (9:16)' : 'Reel (9:16)')
                                : 'Standard',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: _isVerticalFormat ? AppColors.accent : textSecColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Safe Zone Guide Toggle
                  InkWell(
                    onTap: () => setState(() => _showSafeZone = !_showSafeZone),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _showSafeZone ? const Color(0xFF0D9488).withAlpha(30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _showSafeZone ? const Color(0xFF0D9488) : borderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security_outlined,
                            size: 11,
                            color: _showSafeZone ? const Color(0xFF0D9488) : textSecColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Safe Zone',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: _showSafeZone ? const Color(0xFF0D9488) : textSecColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.account.handle,
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
            child: switch (widget.account.platform) {
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
                widget.account.displayName.isNotEmpty ? widget.account.displayName[0] : 'X',
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
                  widget.account.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textOf(context),
                  ),
                ),
                Text(
                  widget.account.handle,
                  style: AppTypography.bodySecondary.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          widget.caption.isEmpty ? '(Empty caption)' : widget.caption,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 14,
            color: AppColors.textOf(context),
          ),
        ),
        if (widget.mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(widget.mediaAssets.first),
        ],
      ],
    );
  }

  Widget _buildInstagramPreview() {
    final effectiveAspect = _isVerticalFormat ? (9 / 16) : 1.0;

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
                backgroundColor: AppColors.surfaceOf(context),
                child: Text(
                  widget.account.displayName.isNotEmpty ? widget.account.displayName[0] : 'I',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOf(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.account.handle,
              style: AppTypography.titleMedium.copyWith(
                fontSize: 13,
                color: AppColors.textOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.mediaAssets.isNotEmpty)
          _buildMediaPlaceholder(
            widget.mediaAssets.first,
            aspectRatio: effectiveAspect,
            isVertical: _isVerticalFormat,
          )
        else
          Container(
            height: _isVerticalFormat ? 260 : 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderOf(context),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                '⚠️ Instagram requires an image or video asset',
                style: AppTypography.bodySecondary.copyWith(
                  color: AppColors.textSecOf(context),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.account.handle} ',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 13,
                  color: AppColors.textOf(context),
                ),
              ),
              TextSpan(
                text: widget.caption.isEmpty ? '(Empty caption)' : widget.caption,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePreview() {
    final effectiveAspect = _isVerticalFormat ? (9 / 16) : (16 / 9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.mediaAssets.isNotEmpty)
          _buildMediaPlaceholder(
            widget.mediaAssets.first,
            aspectRatio: effectiveAspect,
            isVertical: _isVerticalFormat,
          )
        else
          Container(
            height: _isVerticalFormat ? 260 : 130,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecOf(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '⚠️ YouTube requires video asset',
                style: AppTypography.bodySecondary.copyWith(
                  color: AppColors.textSecOf(context),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          widget.postTitle.isEmpty ? 'Untitled Video' : widget.postTitle,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 14,
            color: AppColors.textOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.account.displayName} • 0 views • Just now',
          style: AppTypography.bodySecondary.copyWith(
            fontSize: 11,
            color: AppColors.textSecOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecOf(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.caption.isEmpty ? 'Description...' : widget.caption,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              color: AppColors.textOf(context),
            ),
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
                  widget.account.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textOf(context),
                  ),
                ),
                Text(
                  'Sponsored / Page Post • Just now',
                  style: AppTypography.bodySecondary.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          widget.caption.isEmpty ? '(Empty post copy)' : widget.caption,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.textOf(context),
          ),
        ),
        if (widget.mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(widget.mediaAssets.first, aspectRatio: 16 / 9),
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
                  widget.account.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textOf(context),
                  ),
                ),
                Text(
                  'Sponsored / Page Post • Public',
                  style: AppTypography.bodySecondary.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          widget.caption.isEmpty ? '(Empty post copy)' : widget.caption,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.textOf(context),
          ),
        ),
        if (widget.mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildMediaPlaceholder(widget.mediaAssets.first, aspectRatio: 16 / 9),
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
                widget.account.displayName.isNotEmpty ? widget.account.displayName[0] : '@',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.account.handle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.caption.isEmpty ? 'Start a thread...' : widget.caption,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textOf(context),
          ),
        ),
        if (widget.mediaAssets.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMediaPlaceholder(widget.mediaAssets.first, aspectRatio: 4 / 3),
        ],
      ],
    );
  }

  Widget _buildMediaPlaceholder(
    MediaAsset media, {
    double aspectRatio = 16 / 9,
    bool isVertical = false,
  }) {
    final previewUrl = media.localPreviewUrl;
    final isVideo = media.mediaType == MediaType.video;

    Widget rawDisplay;

    if (!isVideo && previewUrl != null && previewUrl.isNotEmpty) {
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        rawDisplay = Image.network(
          previewUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildMediaFallback(media),
        );
      } else if (!kIsWeb) {
        final file = File(previewUrl);
        if (file.existsSync()) {
          rawDisplay = Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildMediaFallback(media),
          );
        } else {
          rawDisplay = _buildMediaFallback(media);
        }
      } else {
        rawDisplay = _buildMediaFallback(media);
      }
    } else if (isVideo) {
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
                  color: Colors.white.withAlpha(40),
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

      if (previewUrl != null && previewUrl.isNotEmpty) {
        final isImageExt = previewUrl.endsWith('.jpg') ||
            previewUrl.endsWith('.jpeg') ||
            previewUrl.endsWith('.png') ||
            previewUrl.endsWith('.webp');

        if (isImageExt && (previewUrl.startsWith('http://') || previewUrl.startsWith('https://'))) {
          rawDisplay = Stack(
            fit: StackFit.expand,
            children: [
              Image.network(previewUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => videoFallback),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            ],
          );
        } else {
          rawDisplay = FutureBuilder<Uint8List?>(
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
                          color: Colors.black.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
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
        rawDisplay = videoFallback;
      }
    } else {
      rawDisplay = _buildMediaFallback(media);
    }

    final decoratedDisplay = _buildSafeZoneOverlay(
      child: rawDisplay,
      platform: widget.account.platform,
      isVertical: isVertical,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () {
                final idx = widget.mediaAssets.indexOf(media);
                MediaPreviewScreen.show(
                  context,
                  assets: widget.mediaAssets,
                  initialIndex: idx >= 0 ? idx : 0,
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: decoratedDisplay,
              ),
            ),
          ),
        ),
        if (_showSafeZone) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF0D9488).withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF0D9488)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Safe Zone Active: Keep key subtitles, hooks & faces inside the cyan box to avoid native app button overlap.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSafeZoneOverlay({
    required Widget child,
    required PlatformType platform,
    required bool isVertical,
  }) {
    if (!_showSafeZone) return child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        // Simulated native gradient scrim
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(110),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(170),
                ],
                stops: const [0.0, 0.16, 0.65, 1.0],
              ),
            ),
          ),
        ),
        // Safe Action Zone dashed border (Cyan)
        Positioned(
          top: isVertical ? 38 : 16,
          bottom: isVertical ? 76 : 28,
          left: 12,
          right: isVertical ? 48 : 16,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.cyanAccent.withAlpha(230),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withAlpha(230),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: const Text(
                  'SAFE CONTENT ZONE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Native Platform UI Controls Mockup (Right Rail)
        if (isVertical) ...[
          Positioned(
            right: 8,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMockIcon(
                  platform == PlatformType.youtube ? Icons.thumb_up_alt_rounded : Icons.favorite_rounded,
                  platform == PlatformType.youtube ? '84K' : '142K',
                ),
                const SizedBox(height: 10),
                _buildMockIcon(Icons.chat_bubble_rounded, '1.4K'),
                const SizedBox(height: 10),
                _buildMockIcon(Icons.share_rounded, 'Share'),
                const SizedBox(height: 10),
                _buildMockIcon(Icons.more_vert_rounded, ''),
                const SizedBox(height: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                    color: Colors.black87,
                  ),
                  child: const Icon(Icons.music_note_rounded, size: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          // Top Platform Header Mockup
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Text(
                  platform == PlatformType.youtube ? 'Shorts' : 'Reels',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
              ],
            ),
          ),
          // Bottom Caption & Creator Scrim Mockup
          Positioned(
            left: 12,
            right: 56,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.account.displayName.isNotEmpty ? widget.account.displayName[0] : 'U',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.account.handle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white60, width: 0.8),
                      ),
                      child: Text(
                        platform == PlatformType.youtube ? 'Subscribe' : 'Follow',
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.caption.isNotEmpty
                      ? widget.caption
                      : (widget.postTitle.isNotEmpty ? widget.postTitle : 'Captivating hook...'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.white70, size: 10),
                    SizedBox(width: 3),
                    Text(
                      'Original Audio • Trending',
                      style: TextStyle(color: Colors.white70, fontSize: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMockIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaFallback(MediaAsset media) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            media.mediaType == MediaType.video
                ? Icons.play_circle_fill
                : Icons.image_outlined,
            size: 36,
            color: AppColors.textSecOf(context),
          ),
          const SizedBox(height: 6),
          Text(
            media.fileName,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 11,
              color: AppColors.textOf(context),
            ),
          ),
          Text(
            '${media.formattedSize} • ${media.mediaType.label}',
            style: AppTypography.bodySecondary.copyWith(
              fontSize: 10,
              color: AppColors.textSecOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
