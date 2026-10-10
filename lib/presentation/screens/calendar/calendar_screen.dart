import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';

class CalendarScreen extends StatelessWidget {
  final AppState appState;

  const CalendarScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final scheduledJobs = appState.allJobs
            .where((j) => j.status == PublishJobStatus.scheduled && j.scheduledAtUtc != null)
            .toList();

        // Sort by scheduled time
        scheduledJobs.sort((a, b) => a.scheduledAtUtc!.compareTo(b.scheduledAtUtc!));

        // Group by day header
        final grouped = <String, List<PublishJob>>{};
        for (final job in scheduledJobs) {
          final dayHeader = DateFormatter.formatDayHeader(job.scheduledAtUtc!);
          grouped.putIfAbsent(dayHeader, () => []).add(job);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Publishing Calendar'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    appState.userTimezone,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          body: scheduledJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available_outlined, size: 54, color: AppColors.textMuted),
                      const SizedBox(height: 14),
                      const Text('Queue is empty', style: AppTypography.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        'No upcoming posts scheduled in ${appState.userTimezone}.',
                        style: AppTypography.bodySecondary,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ComposerScreen(appState: appState),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Schedule a Post'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${entry.value.length} jobs)',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((job) => _buildScheduledJobCard(context, job)),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildScheduledJobCard(BuildContext context, PublishJob job) {
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
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateFormatter.formatTime(job.scheduledAtUtc),
              style: AppTypography.code.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (account != null) PlatformIconChip(account: account, isCompact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brand != null)
                  Text(
                    brand.name,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                  ),
                Text(
                  post?.title ?? 'Untitled Post',
                  style: AppTypography.titleMedium.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: job.status, isManual: job.isManual, isCompact: true),
        ],
      ),
    );
  }
}
