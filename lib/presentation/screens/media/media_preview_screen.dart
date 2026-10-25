import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/core/services/video_thumbnail_service.dart';

/// Fullscreen Interactive Media Preview Screen for attached Photos and Videos.
///
/// Features:
/// 1. Pan, zoom, and pinch for photos via `InteractiveViewer`.
/// 2. Full video playback controls (play/pause, seek scrubber, mute/unmute, duration timer).
/// 3. Horizontal swipe carousel across all attached post media.
/// 4. Detailed file metadata strip (size, dimensions, format, filename).
/// 5. External opener via system player or web browser.
/// 6. Optional removal of media from the post composer directly from the preview.
class MediaPreviewScreen extends StatefulWidget {
  final List<MediaAsset> assets;
  final int initialIndex;
  final void Function(String assetId)? onRemoveAsset;

  const MediaPreviewScreen({
    super.key,
    required this.assets,
    this.initialIndex = 0,
    this.onRemoveAsset,
  });

  /// Convenient static helper to launch the preview modal route
  static Future<void> show(
    BuildContext context, {
    required List<MediaAsset> assets,
    int initialIndex = 0,
    void Function(String assetId)? onRemoveAsset,
  }) {
    if (assets.isEmpty) return Future.value();
    final clampedIndex = initialIndex.clamp(0, assets.length - 1);

    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, anim1, anim2) => FadeTransition(
          opacity: anim1,
          child: MediaPreviewScreen(
            assets: assets,
            initialIndex: clampedIndex,
            onRemoveAsset: onRemoveAsset,
          ),
        ),
      ),
    );
  }

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<MediaAsset> _activeAssets;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _activeAssets = List<MediaAsset>.from(widget.assets);
    _currentIndex = widget.initialIndex.clamp(0, _activeAssets.isEmpty ? 0 : _activeAssets.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _launchExternal(MediaAsset asset) async {
    final previewUrl = asset.localPreviewUrl;
    if (previewUrl == null || previewUrl.isEmpty) return;

    try {
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        final uri = Uri.parse(previewUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (!kIsWeb) {
        final uri = Uri.file(previewUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('MediaPreviewScreen: Failed to open media externally: $e');
    }
  }

  void _confirmRemove(MediaAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Remove Attachment?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Remove "${asset.fileName}" from this post? The media file remains in your device and library.',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onRemoveAsset?.call(asset.id);

              setState(() {
                _activeAssets.removeAt(_currentIndex);
                if (_activeAssets.isEmpty) {
                  Navigator.of(context).pop();
                } else {
                  if (_currentIndex >= _activeAssets.length) {
                    _currentIndex = _activeAssets.length - 1;
                  }
                  _pageController.jumpToPage(_currentIndex);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentAsset = _activeAssets[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _currentIndex > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                _currentIndex < _activeAssets.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Media Carousel View
              PageView.builder(
                controller: _pageController,
                itemCount: _activeAssets.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final asset = _activeAssets[index];
                  if (asset.mediaType == MediaType.video) {
                    return _VideoMediaItem(
                      asset: asset,
                      showControls: _showControls,
                    );
                  } else {
                    return _PhotoMediaItem(asset: asset);
                  }
                },
              ),

              // Animated Top Navigation & Metadata Bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    MediaQuery.of(context).padding.top + 8,
                    12,
                    14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        tooltip: 'Back to Composer',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      // Title & Counter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentAsset.fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: currentAsset.mediaType == MediaType.video
                                        ? Colors.redAccent.withValues(alpha: 0.3)
                                        : AppColors.accent.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: currentAsset.mediaType == MediaType.video
                                          ? Colors.redAccent
                                          : AppColors.accent,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    currentAsset.mediaType.label.toUpperCase(),
                                    style: TextStyle(
                                      color: currentAsset.mediaType == MediaType.video
                                          ? Colors.redAccent
                                          : AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${currentAsset.formattedSize}  •  ${_currentIndex + 1} of ${_activeAssets.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // External launch action
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Open in External Player/Browser',
                        onPressed: () => _launchExternal(currentAsset),
                      ),
                      // Remove attachment action
                      if (widget.onRemoveAsset != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                          tooltip: 'Remove Attachment',
                          onPressed: () => _confirmRemove(currentAsset),
                        ),
                    ],
                  ),
                ),
              ),

              // Animated Bottom Thumbnail Selector Strip
              if (_activeAssets.length > 1)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  bottom: _showControls ? 0 : -90,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_activeAssets.length, (index) {
                            final asset = _activeAssets[index];
                            final isSelected = index == _currentIndex;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? AppColors.accent : Colors.white24,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildMiniThumbnail(asset),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

              // Navigation Arrow Controls (for desktop / tablets)
              if (_activeAssets.length > 1 && _showControls) ...[
                if (_currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                if (_currentIndex < _activeAssets.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniThumbnail(MediaAsset asset) {
    final previewUrl = asset.localPreviewUrl;
    if (asset.mediaType == MediaType.image && previewUrl != null && previewUrl.isNotEmpty) {
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        return Image.network(previewUrl, fit: BoxFit.cover);
      } else if (!kIsWeb) {
        return Image.file(File(previewUrl), fit: BoxFit.cover);
      }
    }
    return Container(
      color: const Color(0xFF1E293B),
      child: Icon(
        asset.mediaType == MediaType.video ? Icons.play_arrow_rounded : Icons.image_rounded,
        size: 18,
        color: asset.mediaType == MediaType.video ? Colors.redAccent : AppColors.accent,
      ),
    );
  }
}

/// Photo Media View with Pinch, Pan, and Interactive Zoom
class _PhotoMediaItem extends StatefulWidget {
  final MediaAsset asset;

  const _PhotoMediaItem({required this.asset});

  @override
  State<_PhotoMediaItem> createState() => _PhotoMediaItemState();
}

class _PhotoMediaItemState extends State<_PhotoMediaItem> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      // ignore: deprecated_member_use
      _transformController.value = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        // ignore: deprecated_member_use
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.asset.localPreviewUrl;

    Widget imageWidget;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        imageWidget = Image.network(
          previewUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          },
          errorBuilder: (_, _, _) => _buildErrorCard('Could not load online image.'),
        );
      } else if (!kIsWeb) {
        final file = File(previewUrl);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildErrorCard('Could not load local image file.'),
          );
        } else {
          imageWidget = _buildErrorCard('File not found at local path.');
        }
      } else {
        imageWidget = _buildErrorCard('File path format not supported on web.');
      }
    } else {
      imageWidget = _buildErrorCard('No preview URL available for this photo.');
    }

    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.8,
          maxScale: 4.5,
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_rounded, size: 54, color: AppColors.textSecondary),
          const SizedBox(height: 14),
          Text(
            widget.asset.fileName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Video Media View with Real Video Player Controls
class _VideoMediaItem extends StatefulWidget {
  final MediaAsset asset;
  final bool showControls;

  const _VideoMediaItem({
    required this.asset,
    required this.showControls,
  });

  @override
  State<_VideoMediaItem> createState() => _VideoMediaItemState();
}

class _VideoMediaItemState extends State<_VideoMediaItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final previewUrl = widget.asset.localPreviewUrl;
    if (previewUrl == null || previewUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video source path available.';
      });
      return;
    }

    try {
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(previewUrl));
      } else if (!kIsWeb) {
        final f = File(previewUrl);
        if (f.existsSync()) {
          _controller = VideoPlayerController.file(f);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Local video file does not exist.';
          });
          return;
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video preview over direct path not supported on web.';
        });
        return;
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.addListener(_onControllerUpdate);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('MediaPreviewScreen: Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Native video decoder notice: $e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return _buildFallbackThumbnailView();
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    final isPlaying = _controller!.value.isPlaying;
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video playback surface
            VideoPlayer(_controller!),

            // Big Centered Play/Pause Overlay Button (Fades out when playing unless tapped)
            if (!isPlaying || widget.showControls)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),

            // Video Controls Bottom Overlay (Timeline, Timer, Mute)
            if (widget.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video Progress Scrubber
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.redAccent,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _togglePlayPause,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _toggleMute,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_controller!.value.size.width.toInt()}x${_controller!.value.size.height.toInt()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnailView() {
    final previewUrl = widget.asset.localPreviewUrl;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail extraction attempt
            if (previewUrl != null && previewUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: FutureBuilder<Uint8List?>(
                    future: VideoThumbnailService.getThumbnail(previewUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(snapshot.data!, fit: BoxFit.cover),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              ),
                            ),
                          ],
                        );
                      }
                      return Container(
                        color: Colors.black54,
                        child: const Icon(Icons.videocam_rounded, size: 54, color: Colors.redAccent),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.asset.fileName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.asset.formattedSize} • ${widget.asset.mediaType.label}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
