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

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Image.asset(
                      'assets/logo/no5ocial_N.png',
                      height: 28,
                      errorBuilder: (_, _, _) => const Icon(Icons.hub, color: AppColors.ink),
                    ),
                  ),
                  title: Image.asset(
                    'assets/logo/no5ocial.png',
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text('No5ocial'),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.accent),
                      tooltip: 'Create Post',
                      onPressed: () => _openComposer(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Executive Operations Hero Card
                _buildHeroBanner(context),
                const SizedBox(height: 20),

                // 2. Action Required / Blockers Banner (Top of home per DESIGN.md)
                if (failedJobs.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.errorBorder),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.priority_high, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Action Required (${failedJobs.length} Destination Issues)',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One or more publishing destinations encountered a timeout or require manual handoff. Review and resolve below:',
                          style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...failedJobs.take(3).map((job) => _buildFailedJobRow(context, job)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Operational Summary Metrics
                Row(
                  children: [
                    _buildMetricCard('Drafts', appState.draftCount, Icons.edit_note_rounded, AppColors.textSecondary, 'Ready to edit'),
                    const SizedBox(width: 12),
                    _buildMetricCard('Scheduled', appState.scheduledCount, Icons.event_available_rounded, AppColors.accent, 'Next in queue'),
                    const SizedBox(width: 12),
                    _buildMetricCard('Published', appState.publishedCount, Icons.check_circle_rounded, AppColors.success, 'Successfully live'),
                    const SizedBox(width: 12),
                    _buildMetricCard('Action Needed', appState.actionRequiredCount, Icons.warning_amber_rounded, AppColors.warning, 'Requires attention'),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Scheduled Jobs Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Scheduled Publication Queue',
                              style: AppTypography.titleLarge.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${scheduledJobs.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Timezone: ${appState.userTimezone}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (scheduledJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          const Text('Nothing scheduled in this queue.', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          const Text(
                            'Create a post and select your destinations to queue automatic or manual publishing.',
                            style: AppTypography.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...scheduledJobs.map((job) => _buildJobCard(context, job)),
                const SizedBox(height: 24),

                // 5. Recent Published Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Published Activity', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                    const Text('Past records', style: AppTypography.labelSmall),
                  ],
                ),
                const SizedBox(height: 12),
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

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/logo/no5ocial_white.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Row(
                        children: [
                          Icon(Icons.hub, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'No5ocial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shaadow Unified Multi-Destination Publishing Hub',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openComposer(context),
                icon: const Icon(Icons.add_circle, size: 18, color: Colors.white),
                label: const Text(
                  'Compose Post',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Feature Capability Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroBadge(Icons.business_center_outlined, '6 Studio Brands'),
              _buildHeroBadge(Icons.hub_outlined, '9 Linked Channels'),
              _buildHeroBadge(Icons.security, 'Zero Secret Leakage'),
              _buildHeroBadge(Icons.bolt, '15s Manual Handoff SLA'),
              _buildHeroBadge(Icons.currency_rupee, '₹0 Extra Schedulers Cost'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2838),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E3E56)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF93C5FD)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int count, IconData icon, Color color, String sublabel) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          if (account != null) PlatformIconChip(account: account, isCompact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (brand != null) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            brand.name,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        post?.title ?? 'Untitled Post',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      job.status == PublishJobStatus.published
                          ? Icons.check_circle_outline
                          : Icons.schedule,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.status == PublishJobStatus.published
                            ? 'Published ${DateFormatter.formatRelative(job.publishedAtUtc)}'
                            : 'Scheduled for ${DateFormatter.formatRelative(job.scheduledAtUtc)}',
                        style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (job.externalUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 12, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Expanded(
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
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(status: job.status, isManual: job.isManual),
        ],
      ),
    );
  }
}
