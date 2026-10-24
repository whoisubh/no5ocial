import 'package:flutter/material.dart';

import 'package:no5ocial/core/extensions/l10n_extension.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/core/utils/number_formatter.dart';
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
import 'package:no5ocial/core/services/firebase_sync_service.dart';
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
    if (appState.isReadOnly) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your role (Analyst) has read-only access. You can view metrics and calendar, but cannot create posts.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

  bool get _isDark => appState.isDarkMode;
  Color get _surfaceColor => _isDark ? const Color(0xFF101522) : AppColors.surface;
  Color get _surfaceSecColor => _isDark ? const Color(0xFF161F30) : AppColors.surfaceSecondary;
  Color get _borderColor => _isDark ? const Color(0xFF1E293B) : AppColors.border;
  Color get _textPrimaryColor => _isDark ? Colors.white : AppColors.textPrimary;
  Color get _textSecColor => _isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

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
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        appState.isDarkMode
                            ? 'assets/logo/no5ocial_white.png'
                            : 'assets/logo/no5ocial.png',
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text('no5ocial'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
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
                // 0. Status indicator (Only shown when offline or actively syncing)
                ListenableBuilder(
                  listenable: Listenable.merge([SyncService.instance, FirebaseSyncService.instance]),
                  builder: (context, _) {
                    final fbSync = FirebaseSyncService.instance;
                    final sync = SyncService.instance;
                    final isSyncing = fbSync.status == FirebaseSyncStatus.syncing || sync.status == SyncStatus.syncing;
                    final isOffline = fbSync.status == FirebaseSyncStatus.offline && sync.status == SyncStatus.offline;

                    if (!isOffline && !isSyncing) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOffline
                            ? AppColors.warning.withAlpha(20)
                            : AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOffline ? AppColors.warning.withAlpha(80) : AppColors.accent.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSyncing ? Icons.sync : Icons.cloud_off,
                            size: 16,
                            color: isOffline ? AppColors.warning : AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSyncing
                                  ? 'Synchronizing workspace...'
                                  : 'Offline Mode — Changes will sync automatically when reconnected.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOffline ? AppColors.warning : AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
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
                      color: _isDark ? const Color(0xFF1F1215) : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isDark ? const Color(0xFF4A1D24) : AppColors.errorBorder),
                      boxShadow: _isDark ? [] : AppColors.cardShadow,
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
                            color: _textSecColor,
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
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              isDesktop ? l10n.queueSectionTitle : 'Publishing Queue',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1E2D4A) : AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${scheduledJobs.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _isDark ? const Color(0xFF60A5FA) : AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _surfaceSecColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Text(
                        appState.userTimezone,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _textSecColor,
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
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor),
                      boxShadow: _isDark ? [] : AppColors.cardShadow,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _surfaceSecColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 28,
                              color: _textSecColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.queueEmptyTitle,
                            style: AppTypography.titleMedium.copyWith(color: _textPrimaryColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.queueEmptySubtitle,
                            style: AppTypography.bodySecondary.copyWith(color: _textSecColor),
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
                    color: _textPrimaryColor,
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

  String _getGreetingWish(String? rawName, String langCode) {
    final now = DateTime.now();
    final hour = now.hour;
    final firstName = (rawName != null && rawName.isNotEmpty && rawName != 'Local Admin')
        ? rawName.split(' ').first
        : null;

    final hasName = firstName != null && firstName.isNotEmpty;

    switch (langCode) {
      case 'hi':
        if (hour >= 5 && hour < 12) return hasName ? 'शुभ प्रभात, $firstName 🌅' : 'शुभ प्रभात 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'नमस्ते, $firstName ☀️' : 'नमस्ते ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'शुभ संध्या, $firstName 🌆' : 'शुभ संध्या 🌆';
        return hasName ? 'शुभ रात्रि, $firstName 🌙' : 'शुभ रात्रि 🌙';

      case 'es':
        if (hour >= 5 && hour < 12) return hasName ? '¡Buenos días, $firstName! 🌅' : '¡Buenos días! 🌅';
        if (hour >= 12 && hour < 17) return hasName ? '¡Buenas tardes, $firstName! ☀️' : '¡Buenas tardes! ☀️';
        if (hour >= 17 && hour < 22) return hasName ? '¡Buenas noches, $firstName! 🌆' : '¡Buenas noches! 🌆';
        return hasName ? '¡Buenas noches, $firstName! 🌙' : '¡Buenas noches! 🌙';

      case 'de':
        if (hour >= 5 && hour < 12) return hasName ? 'Guten Morgen, $firstName 🌅' : 'Guten Morgen 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'Guten Tag, $firstName ☀️' : 'Guten Tag ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'Guten Abend, $firstName 🌆' : 'Guten Abend 🌆';
        return hasName ? 'Gute Nacht, $firstName 🌙' : 'Gute Nacht 🌙';

      case 'ja':
        if (hour >= 5 && hour < 12) return hasName ? 'おはようございます、$firstNameさん 🌅' : 'おはようございます 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'こんにちは、$firstNameさん ☀️' : 'こんにちは ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'こんばんは、$firstNameさん 🌆' : 'こんばんは 🌆';
        return hasName ? 'おやすみなさい、$firstNameさん 🌙' : 'おやすみなさい 🌙';

      case 'fr':
        if (hour >= 5 && hour < 12) return hasName ? 'Bonjour, $firstName 🌅' : 'Bonjour 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'Bon après-midi, $firstName ☀️' : 'Bon après-midi ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'Bonsoir, $firstName 🌆' : 'Bonsoir 🌆';
        return hasName ? 'Bonne nuit, $firstName 🌙' : 'Bonne nuit 🌙';

      case 'ar':
        if (hour >= 5 && hour < 12) return hasName ? 'صباح الخير، $firstName 🌅' : 'صباح الخير 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'مساء الخير، $firstName ☀️' : 'مساء الخير ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'مساء النور، $firstName 🌆' : 'مساء النور 🌆';
        return hasName ? 'طابت ليلتك، $firstName 🌙' : 'طابت ليلتك 🌙';

      case 'pt':
        if (hour >= 5 && hour < 12) return hasName ? 'Bom dia, $firstName 🌅' : 'Bom dia 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'Boa tarde, $firstName ☀️' : 'Boa tarde ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'Boa noite, $firstName 🌆' : 'Boa noite 🌆';
        return hasName ? 'Boa noite, $firstName 🌙' : 'Boa noite 🌙';

      default: // English ('en') and other languages
        if (hour >= 5 && hour < 12) return hasName ? 'Good morning, $firstName 🌅' : 'Good morning 🌅';
        if (hour >= 12 && hour < 17) return hasName ? 'Good afternoon, $firstName ☀️' : 'Good afternoon ☀️';
        if (hour >= 17 && hour < 22) return hasName ? 'Good evening, $firstName 🌆' : 'Good evening 🌆';
        return hasName ? 'Good night, $firstName 🌙' : 'Good night 🌙';
    }
  }

  Widget _buildHeroBanner(BuildContext context, dynamic l10n) {
    final userName = appState.localUserName?.trim();
    final title = _getGreetingWish(userName, appState.currentLocale.languageCode);
    final scheduledCount = appState.scheduledCount;
    final description = scheduledCount > 0
        ? 'You have ${NumberFormatter.formatInt(scheduledCount, locale: appState.currentLocale.languageCode)} post${scheduledCount == 1 ? "" : "s"} scheduled in your pipeline today. Track or publish across connected channels.'
        : 'Welcome to your publishing workspace. Plan, schedule, and track posts across your connected channels seamlessly.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
            boxShadow: _isDark ? [] : AppColors.cardShadow,
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
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _textPrimaryColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: _textSecColor,
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
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimaryColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: _textSecColor,
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
        color: _surfaceSecColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: (photoUrl != null && photoUrl.isNotEmpty)
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/logo/no5ocial_cropped.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.hub, color: AppColors.accent),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/logo/no5ocial_cropped.png',
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
                      NumberFormatter.formatInt(count, locale: appState.currentLocale.languageCode),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecColor,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        final iconBox = Container(
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
        );

        final textColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Audience Growth & Velocity',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: _textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.trending_up, size: 14, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              appState.accounts.isEmpty
                  ? 'Link your channels to view organic reach and subscriber metrics.'
                  : 'Tracking ${appState.accounts.length} connected destination${appState.accounts.length > 1 ? 's' : ''} on-device.',
              style: TextStyle(
                fontSize: 11.5,
                color: _textSecColor,
              ),
            ),
          ],
        );

        final button = ElevatedButton.icon(
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
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: button,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              iconBox,
              const SizedBox(width: 14),
              Expanded(child: textColumn),
              const SizedBox(width: 10),
              button,
            ],
          ),
        );
      },
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
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
            border: Border.all(color: _borderColor),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Channel Groups',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Bundle profiles across networks for 1-click publishing',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecColor,
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
        color: _surfaceSecColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
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
              style: TextStyle(
                fontSize: 11,
                color: _textSecColor,
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
        color: _surfaceColor,
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
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 12,
                    color: _textPrimaryColor,
                  ),
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
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
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
                      color: _textSecColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.status == PublishJobStatus.published
                            ? 'Published ${DateFormatter.formatRelative(job.publishedAtUtc)}'
                            : 'Scheduled for ${DateFormatter.formatRelative(job.scheduledAtUtc)}',
                        style: AppTypography.bodySecondary.copyWith(
                          fontSize: 11,
                          color: _textSecColor,
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
