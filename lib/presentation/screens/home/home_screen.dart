import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/screens/composer/manual_handoff_sheet.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  void _openComposer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(appState: appState),
      ),
    );
  }

  void _handleManualHandoff(BuildContext context, PublishJob job) {
    final post = appState.postRepository.getPostById(job.contentPostId);
    final account = appState.getAccountById(job.socialAccountId);
    final variant = appState.postRepository.getVariant(job.contentPostId, job.socialAccountId);

    if (post != null && account != null && variant != null) {
      final attachedMedia = post.mediaAssetIds
          .map((id) => appState.getMediaAssetById(id))
          .whereType<dynamic>()
          .toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ManualHandoffSheet(
          appState: appState,
          post: post,
          account: account,
          variant: variant,
          job: job,
          attachedMedia: attachedMedia.cast(),
        ),
      );
    }
  }

  Future<void> _handleRetry(BuildContext context, PublishJob job) async {
    if (job.hasDuplicateRiskOnRetry) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Duplicate Post Warning'),
            ],
          ),
          content: const Text(
            'The previous attempt timed out after submission. '
            'Retrying may result in a DUPLICATE post if the provider processed it. '
            'Please verify on the platform before proceeding.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel & Inspect'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: const Text('Retry Anyway'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await appState.retryJob(jobId: job.id, forceDuplicateWarningAccepted: true);
      }
    } else {
      await appState.retryJob(jobId: job.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pendingJobs = appState.pendingAndFailedJobs;
        final failedJobs = pendingJobs
            .where((j) =>
                j.status == PublishJobStatus.actionRequired ||
                j.status == PublishJobStatus.failed)
            .toList();

        final scheduledJobs = appState.allJobs
            .where((j) => j.status == PublishJobStatus.scheduled)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('No5ocial Operations Console'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Create Post',
                onPressed: () => _openComposer(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Action Required / Blockers Banner (Top of home per DESIGN.md)
                if (failedJobs.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              'Action Required (${failedJobs.length} destination issues)',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One or more publishing jobs failed or require manual handoff. Review below:',
                          style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        ...failedJobs.take(3).map((job) => _buildFailedJobRow(context, job)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Operational Summary Row
                Row(
                  children: [
                    _buildMetricCard('Drafts', appState.draftCount, Icons.edit_note_outlined, AppColors.textSecondary),
                    const SizedBox(width: 10),
                    _buildMetricCard('Scheduled', appState.scheduledCount, Icons.event_outlined, AppColors.accent),
                    const SizedBox(width: 10),
                    _buildMetricCard('Published', appState.publishedCount, Icons.check_circle_outline, AppColors.success),
                    const SizedBox(width: 10),
                    _buildMetricCard('Action Needed', appState.actionRequiredCount, Icons.warning_amber_rounded, AppColors.warning),
                  ],
                ),
                const SizedBox(height: 22),

                // Quick Actions Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prepare New Post', style: AppTypography.titleMedium),
                            const SizedBox(width: 4),
                            Text(
                              'Adapt copy, select destinations, and publish/handoff.',
                              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openComposer(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Post'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Scheduled Jobs Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scheduled Queue', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                    Text(
                      'Timezone: ${appState.userTimezone}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (scheduledJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('Nothing scheduled yet.', style: AppTypography.titleMedium),
                          SizedBox(height: 4),
                          Text(
                            'Create a post and select a schedule date to plan your queue.',
                            style: AppTypography.bodySecondary,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...scheduledJobs.map((job) => _buildJobCard(context, job)),
                const SizedBox(height: 22),

                // Recent Published History
                Text('Recent Published Activity', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                ...appState.allJobs
                    .where((j) => j.status == PublishJobStatus.published)
                    .take(5)
                    .map((job) => _buildJobCard(context, job)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: AppTypography.titleLarge.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedJobRow(BuildContext context, PublishJob job) {
    final account = appState.getAccountById(job.socialAccountId);
    final post = appState.postRepository.getPostById(job.contentPostId);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          if (account != null) PlatformIconChip(account: account, isCompact: true),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post?.title ?? 'Untitled Post',
                  style: AppTypography.titleMedium.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  job.lastErrorMessage ?? 'Action required.',
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.error,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (job.isManual || (account?.isManualOnly ?? false)) ...[
            OutlinedButton(
              onPressed: () => _handleManualHandoff(context, job),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Handoff', style: TextStyle(fontSize: 11)),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => _handleRetry(context, job),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(54, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, PublishJob job) {
    final account = appState.getAccountById(job.socialAccountId);
    final post = appState.postRepository.getPostById(job.contentPostId);
    final brand = post != null ? appState.getBrandById(post.brandId) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (account != null) PlatformIconChip(account: account, isCompact: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (brand != null) ...[
                      Text(
                        brand.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontSize: 10,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    ],
                    Expanded(
                      child: Text(
                        post?.title ?? 'Untitled Post',
                        style: AppTypography.titleMedium.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.status == PublishJobStatus.published
                      ? 'Published: ${DateFormatter.formatRelative(job.publishedAtUtc)}'
                      : 'Scheduled: ${DateFormatter.formatRelative(job.scheduledAtUtc)}',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                ),
                if (job.externalUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      job.externalUrl!,
                      style: AppTypography.code.copyWith(
                        fontSize: 10,
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: job.status, isManual: job.isManual),
        ],
      ),
    );
  }
}
