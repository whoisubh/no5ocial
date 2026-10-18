import 'package:flutter/material.dart';

import 'package:no5ocial/core/extensions/l10n_extension.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/screens/composer/manual_handoff_sheet.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';
import 'package:no5ocial/core/services/sync_service.dart';
import '../analytics/analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;
  final void Function(int index)? onNavigate;

  const HomeScreen({
    super.key,
    required this.appState,
    this.onNavigate,
  });

  void _openComposer(BuildContext context) {
    if (appState.accounts.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please integrate at least one social channel first before creating a post.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Connect Channel',
            onPressed: () => onNavigate?.call(3),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ComposerScreen(appState: appState)),
    );
  }

  void _handleManualHandoff(BuildContext context, PublishJob job) {
    final post = appState.postRepository.getPostById(job.contentPostId);
    final account = appState.getAccountById(job.socialAccountId);
    final variant = appState.postRepository.getVariant(
      job.contentPostId,
      job.socialAccountId,
    );

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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('Retry Anyway'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await appState.retryJob(
          jobId: job.id,
          forceDuplicateWarningAccepted: true,
        );
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
        if (!appState.isLoggedIn) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pendingJobs = appState.pendingAndFailedJobs;
        final failedJobs = pendingJobs
            .where(
              (j) =>
                  j.status == PublishJobStatus.actionRequired ||
                  j.status == PublishJobStatus.failed,
            )
            .toList();

        final scheduledJobs = appState.allJobs
            .where((j) => j.status == PublishJobStatus.scheduled)
            .toList();

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;
        final l10n = context.l10n;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  title: Image.asset(
                    appState.isDarkMode
                        ? 'assets/logo/no5ocial_white.png'
                        : 'assets/logo/no5ocial.png',
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text('no5ocial'),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.auto_graph_rounded, size: 20),
                      tooltip: 'Audience & Growth Analytics',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnalyticsScreen(appState: appState),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        appState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 20,
                      ),
                      tooltip: appState.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      onPressed: appState.toggleTheme,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 32 : 16,
              20,
              isDesktop ? 32 : 16,
              isDesktop ? 20 : 88,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. Live Centralization Sync Indicator
                ListenableBuilder(
                  listenable: SyncService.instance,
                  builder: (context, _) {
                    final sync = SyncService.instance;
                    final isSyncing = sync.status == SyncStatus.syncing;
                    final isOffline = sync.status == SyncStatus.offline;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOffline
                            ? AppColors.warning.withAlpha(20)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOffline ? AppColors.warning : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSyncing
                                ? Icons.sync
                                : isOffline
                                    ? Icons.cloud_off
                                    : Icons.cloud_done_outlined,
                            size: 16,
                            color: isOffline
                                ? AppColors.warning
                                : isSyncing
                                    ? AppColors.accent
                                    : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSyncing
                                  ? 'Synchronizing local changes with central cloud...'
                                  : isOffline
                                      ? 'Working in offline mode. Changes saved locally.'
                                      : 'Centralization Active • Last synced: ${sync.formattedLastSync}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () => SyncService.instance.syncNow(),
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Sync Now', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 1. Executive Operations Hero Card
                _buildHeroBanner(context, l10n),
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
                              child: const Icon(
                                Icons.priority_high,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.actionRequiredTitle(failedJobs.length),
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
                          l10n.actionRequiredSub,
                          style: AppTypography.bodySecondary.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...failedJobs
                            .take(3)
                            .map((job) => _buildFailedJobRow(context, job)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Operational Summary Metrics
                if (isDesktop)
                  Row(
                    children: [
                      _buildMetricCard(
                        l10n.metricDrafts,
                        appState.draftCount,
                        Icons.edit_note_rounded,
                        AppColors.textSecondary,
                        l10n.metricDraftsSub,
                        onTap: () => onNavigate?.call(1),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        l10n.metricScheduled,
                        appState.scheduledCount,
                        Icons.event_available_rounded,
                        AppColors.accent,
                        l10n.metricScheduledSub,
                        onTap: () => onNavigate?.call(2),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        l10n.metricPublished,
                        appState.publishedCount,
                        Icons.check_circle_rounded,
                        AppColors.success,
                        l10n.metricPublishedSub,
                        onTap: () => onNavigate?.call(1),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        l10n.metricNeedsReview,
                        appState.actionRequiredCount,
                        Icons.warning_amber_rounded,
                        AppColors.warning,
                        l10n.metricNeedsReviewSub,
                        onTap: () => onNavigate?.call(0),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          _buildMetricCard(
                            l10n.metricDrafts,
                            appState.draftCount,
                            Icons.edit_note_rounded,
                            AppColors.textSecondary,
                            l10n.metricDraftsSub,
                            onTap: () => onNavigate?.call(1),
                          ),
                          const SizedBox(width: 12),
                          _buildMetricCard(
                            l10n.metricScheduled,
                            appState.scheduledCount,
                            Icons.event_available_rounded,
                            AppColors.accent,
                            l10n.metricScheduledSub,
                            onTap: () => onNavigate?.call(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMetricCard(
                            l10n.metricPublished,
                            appState.publishedCount,
                            Icons.check_circle_rounded,
                            AppColors.success,
                            l10n.metricPublishedSub,
                            onTap: () => onNavigate?.call(1),
                          ),
                          const SizedBox(width: 12),
                          _buildMetricCard(
                            l10n.metricNeedsReview,
                            appState.actionRequiredCount,
                            Icons.warning_amber_rounded,
                            AppColors.warning,
                            l10n.metricNeedsReviewSub,
                            onTap: () => onNavigate?.call(0),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // 3.4 Audience & Growth Analytics Widget
                _buildAnalyticsGrowthCard(context),
                const SizedBox(height: 24),

                // 3.5 Active Channel Groups & Product Profiles
                _buildChannelGroupsSection(context),
                const SizedBox(height: 24),

                // 4. Scheduled Jobs Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDesktop ? l10n.queueSectionTitle : 'Publishing Queue',
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        appState.userTimezone,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (scheduledJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 20,
                    ),
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
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              size: 28,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.queueEmptyTitle,
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.queueEmptySubtitle,
                            style: AppTypography.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (appState.accounts.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () => onNavigate?.call(3),
                              icon: const Icon(Icons.add_link_rounded, size: 16),
                              label: const Text('Connect Channel First'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _openComposer(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.btnCreatePost),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  ...scheduledJobs.map((job) => _buildJobCard(context, job)),
                const SizedBox(height: 24),

                // 5. Recent Published Activity
                Text(
                  l10n.recentActivityTitle,
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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

  Widget _buildHeroBanner(BuildContext context, dynamic l10n) {
    final userName = appState.localUserName?.trim();
    const title = 'Welcome to your publishing workspace';
    final description = userName != null && userName.isNotEmpty && userName != 'Local Admin'
        ? 'Signed in as $userName. Plan, schedule, and track posts across your connected channels.'
        : 'Plan, schedule, and track posts across your connected channels seamlessly.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: isCompact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeroAvatar(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (appState.accounts.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () => onNavigate?.call(3),
                        icon: const Icon(
                          Icons.add_link_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Connect Channel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _openComposer(context),
                        icon: const Icon(
                          Icons.add_circle,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          l10n.btnComposePost,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroAvatar() {
    final photoUrl = appState.localUserPhotoUrl;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (photoUrl != null && photoUrl.isNotEmpty)
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/logo/no5ocial_N.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.hub, color: AppColors.accent),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/logo/no5ocial_N.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.hub, color: AppColors.accent),
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    String label,
    int count,
    IconData icon,
    Color color,
    String sublabel, {
    VoidCallback? onTap,
  }) {
    final isDark = appState.isDarkMode;
    return Expanded(
      child: Material(
        color: isDark ? const Color(0xFF101522) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF222C40) : AppColors.border),
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
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
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrowthCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 22,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Audience Growth & Velocity',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.trending_up, size: 14, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  appState.accounts.isEmpty
                      ? 'Link your channels to view organic reach and subscriber metrics.'
                      : 'Tracking ${appState.accounts.length} connected destination${appState.accounts.length > 1 ? 's' : ''} on-device.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalyticsScreen(appState: appState),
                ),
              );
            },
            icon: const Icon(Icons.auto_graph_rounded, size: 14),
            label: const Text('View Analytics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelGroupsSection(BuildContext context) {
    final groups = appState.groups;
    if (groups.isEmpty) return const SizedBox.shrink();

    // Wrap in LayoutBuilder to adjust padding based on width
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  size: 16,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Channel Groups',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Bundle profiles across networks for 1-click publishing',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => onNavigate?.call(3),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (groups.length == 1)
            _buildGroupItemCard(context, groups.first, isFullWidth: true)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: groups.map((g) => _buildGroupItemCard(context, g)).toList(),
              ),
            ),
        ],
      ),
    );
  },
);
}

  Widget _buildGroupItemCard(
    BuildContext context,
    ChannelGroup g, {
    bool isFullWidth = false,
  }) {
    final brand = appState.getBrandById(g.brandId);
    final bundledAccounts = g.accountIds
        .map((id) => appState.getAccountById(id))
        .whereType<SocialAccount>()
        .toList();

    return Container(
      width: isFullWidth ? double.infinity : 280,
      margin: isFullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: GroupBadge(
                  group: g,
                  isCompact: true,
                ),
              ),
              if (brand != null) ...[
                const SizedBox(width: 8),
                CompanyBadge(
                  brand: brand,
                  isCompact: true,
                ),
              ],
            ],
          ),
          if (g.description != null && g.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              g.description!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: bundledAccounts.take(4).map((acc) {
                  final pColor = PlatformLogo.getBrandColor(acc.platform);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: pColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: PlatformLogo(
                        platform: acc.platform,
                        size: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
              InkWell(
                onTap: () => _openComposer(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Compose',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
          if (account != null)
            PlatformIconChip(account: account, isCompact: true),
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
          if (account != null)
            PlatformIconChip(account: account, isCompact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (brand != null) ...[
                      CompanyBadge(
                        brand: brand,
                        isCompact: true,
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
                        style: AppTypography.bodySecondary.copyWith(
                          fontSize: 11,
                        ),
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
                        const Icon(
                          Icons.link,
                          size: 12,
                          color: AppColors.accent,
                        ),
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
