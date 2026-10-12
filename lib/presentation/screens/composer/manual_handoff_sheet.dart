import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';

class ManualHandoffSheet extends StatefulWidget {
  final AppState appState;
  final ContentPost post;
  final SocialAccount account;
  final PostVariant variant;
  final PublishJob? job;
  final List<MediaAsset> attachedMedia;

  const ManualHandoffSheet({
    super.key,
    required this.appState,
    required this.post,
    required this.account,
    required this.variant,
    this.job,
    required this.attachedMedia,
  });

  @override
  State<ManualHandoffSheet> createState() => _ManualHandoffSheetState();
}

class _ManualHandoffSheetState extends State<ManualHandoffSheet> {
  final _urlController = TextEditingController();
  bool _copied = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    if (widget.job?.externalUrl != null) {
      _urlController.text = widget.job!.externalUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String get _effectiveCaption => widget.variant.hasCaptionOverride
      ? widget.variant.captionOverride!
      : widget.post.defaultCaption;

  void _copyCaption() {
    Clipboard.setData(ClipboardData(text: _effectiveCaption));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Caption copied to clipboard! Ready to paste into platform.',
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  void _simulateExportAsset(MediaAsset media) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asset "${media.fileName}" staged for export/share.'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  void _confirmManualPublish() {
    setState(() => _isConfirming = true);

    String? effectiveJobId = widget.job?.id;

    // If no existing job, create one through appState
    if (effectiveJobId == null) {
      final jobs = widget.appState.getJobsForPost(widget.post.id);
      final match = jobs
          .where((j) => j.socialAccountId == widget.account.id)
          .firstOrNull;
      effectiveJobId = match?.id;
    }

    if (effectiveJobId != null) {
      widget.appState.confirmManualHandoff(
        jobId: effectiveJobId,
        externalPostUrl: _urlController.text.trim().isNotEmpty
            ? _urlController.text.trim()
            : null,
      );
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked as Manually Published for ${widget.account.handle}',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  List<String> _getPlatformChecklist(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return [
          'Copy the caption above.',
          'Export or save the attached media to your gallery.',
          'Open Instagram and switch to account: ${widget.account.handle}.',
          'Create post, select the asset, and paste the caption.',
          'Publish and paste the post link below for tracking.',
        ];
      case PlatformType.x:
        return [
          'Copy the formatted post text.',
          'Open X and ensure you are logged into ${widget.account.handle}.',
          'Paste text and attach media if needed.',
          'Review 280-character limit and post.',
          'Optionally capture the tweet URL.',
        ];
      case PlatformType.youtube:
        return [
          'Open YouTube Studio for channel: ${widget.account.displayName}.',
          'Upload video asset: ${widget.attachedMedia.isNotEmpty ? widget.attachedMedia.first.fileName : "Video"}.',
          'Paste video title: "${widget.post.title}".',
          'Paste description from caption field.',
          'Set visibility (Public/Unlisted) and publish.',
        ];
      case PlatformType.linkedin:
        return [
          'Open LinkedIn Company Page admin for ${widget.account.displayName}.',
          'Click "Start a post".',
          'Paste the adapted commentary and attach asset.',
          'Publish and paste the update link below.',
        ];
      case PlatformType.facebook:
        return [
          'Open Facebook Page for ${widget.account.displayName}.',
          'Create a new Page post.',
          'Paste caption and attach media assets.',
          'Publish or schedule via Meta Business Suite.',
        ];
      case PlatformType.tiktok:
        return [
          'Open TikTok Creator Portal or app for ${widget.account.handle}.',
          'Upload vertical video asset.',
          'Paste caption with trending hashtags.',
          'Publish video and record link.',
        ];
      case PlatformType.pinterest:
        return [
          'Open Pinterest for account ${widget.account.displayName}.',
          'Click Create Pin.',
          'Upload pin image or video.',
          'Paste Pin Title, Description, and Destination URL.',
          'Select board and publish.',
        ];
      case PlatformType.threads:
        return [
          'Open Threads app or web for ${widget.account.handle}.',
          'Start a new Thread.',
          'Paste thread text and attach media.',
          'Post update.',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                PlatformIconChip(account: widget.account, isCompact: false),
                const SizedBox(width: 8),
                Text(
                  'Manual Publishing Handoff',
                  style: AppTypography.titleLarge.copyWith(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'no5ocial guides you through manual publishing without pretending to be automated.',
              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Step 1: Caption Copy Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Destination Caption',
                        style: AppTypography.labelSmall,
                      ),
                      Text(
                        '${_effectiveCaption.length} chars',
                        style: AppTypography.code.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _effectiveCaption.isEmpty
                        ? '(Empty caption)'
                        : _effectiveCaption,
                    style: AppTypography.bodyMedium,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _copyCaption,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _copied ? 'Caption Copied!' : 'Copy Caption to Clipboard',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copied
                          ? AppColors.success
                          : AppColors.ink,
                      minimumSize: const Size.fromHeight(38),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Step 2: Attached media export
            if (widget.attachedMedia.isNotEmpty) ...[
              Text(
                'Attached Assets',
                style: AppTypography.titleMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              ...widget.attachedMedia.map((media) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        media.mediaType.name == 'video'
                            ? Icons.video_file_outlined
                            : Icons.image_outlined,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.fileName,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${media.formattedSize} • ${media.mediaType.label}',
                              style: AppTypography.bodySecondary.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _simulateExportAsset(media),
                        icon: const Icon(Icons.share_outlined, size: 14),
                        label: const Text(
                          'Export',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
            ],

            // Step 3: Platform Checklist
            Text(
              'Operator Checklist',
              style: AppTypography.titleMedium.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _getPlatformChecklist(widget.account.platform)
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Step 4: Resulting Post URL
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Resulting Post URL (Optional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link, size: 18),
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Confirmation button
            ElevatedButton(
              onPressed: _isConfirming ? null : _confirmManualPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(
                'I Have Published This Manually',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
