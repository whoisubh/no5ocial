import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/calendar_export_helper.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';

/// Real Interactive Publishing Calendar Screen.
/// Displays an interactive Month/2-Weeks/Week calendar with scheduled event markers,
/// day-specific schedule view, Google Calendar event integration, and schedule composer trigger.
class CalendarScreen extends StatefulWidget {
  final AppState appState;

  const CalendarScreen({super.key, required this.appState});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _activeViewMode = 0; // 0 = Selected Day, 1 = All Upcoming Agenda
  bool _showCalendar = false; // controls calendar visibility

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  List<PublishJob> _getJobsForDay(DateTime day, List<PublishJob> scheduledJobs) {
    return scheduledJobs.where((j) {
      if (j.scheduledAtUtc == null) return false;
      final jobLocal = j.scheduledAtUtc!.toLocal();
      return jobLocal.year == day.year &&
          jobLocal.month == day.month &&
          jobLocal.day == day.day;
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _activeViewMode = 0; // Switch to selected day view
    });
  }

  void _openComposerForDate(DateTime date, {ContentPost? existingPost}) {
    if (widget.appState.accounts.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please integrate at least one social channel first before creating a post.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(
          appState: widget.appState,
          initialPost: existingPost,
          initialScheduledDate: date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        // Query real scheduled jobs from database/state (no hardcoded data)
        final scheduledJobs = widget.appState.allJobs
            .where((j) =>
                j.status == PublishJobStatus.scheduled &&
                j.scheduledAtUtc != null)
            .toList();

        // Sort chronologically
        scheduledJobs.sort((a, b) => a.scheduledAtUtc!.compareTo(b.scheduledAtUtc!));

        // Jobs for the currently selected day
        final jobsOnSelectedDay = _getJobsForDay(_selectedDay, scheduledJobs);

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: isDesktop
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  title: const Text('Publishing Schedule'),
                  actions: [
                    IconButton(
                      tooltip: _showCalendar ? 'Hide Calendar' : 'Show Calendar',
                      icon: Icon(
                        _showCalendar
                            ? Icons.calendar_view_month_outlined
                            : Icons.calendar_today_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 14,
              vertical: isDesktop ? 24 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with Timezone and Quick Stats
                _buildTopInfoBar(scheduledJobs.length),
                const SizedBox(height: 14),

                // Interactive Calendar Card
                if (_showCalendar) _buildInteractiveCalendarCard(scheduledJobs),
                if (_showCalendar) const SizedBox(height: 16),
                // View Mode Segmented Controls (Selected Day vs All Upcoming)
                if (_showCalendar) _buildViewModeToggle(jobsOnSelectedDay.length, scheduledJobs.length),
                if (_showCalendar) const SizedBox(height: 14),
                // Scheduled Items List or Empty State
                if (_activeViewMode == 0)
                  _buildSelectedDaySection(jobsOnSelectedDay)
                else
                  _buildAllUpcomingSection(scheduledJobs),

                const SizedBox(height: 80), // Fab padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopInfoBar(int totalScheduled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            widget.appState.userTimezone,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: totalScheduled > 0 ? AppColors.accent.withAlpha(20) : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: totalScheduled > 0 ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalScheduled scheduled',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: totalScheduled > 0 ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCalendarCard(List<PublishJob> scheduledJobs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 6, right: 6),
      child: TableCalendar<PublishJob>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 730)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: (day) => _getJobsForDay(day, scheduledJobs),
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          formatButtonTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.ink, size: 20),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.ink, size: 20),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Color(0xFFE11D48)),
          holidayTextStyle: const TextStyle(color: Color(0xFFE11D48)),
          selectedDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.accent.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(
            color: Color(0xFF6366F1),
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildViewModeToggle(int selectedCount, int totalCount) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 0,
          label: Text('Selected Day ($selectedCount)'),
          icon: const Icon(Icons.calendar_today_outlined, size: 15),
        ),
        ButtonSegment(
          value: 1,
          label: Text('All Upcoming ($totalCount)'),
          icon: const Icon(Icons.view_agenda_outlined, size: 15),
        ),
      ],
      selected: {_activeViewMode},
      onSelectionChanged: (val) => setState(() => _activeViewMode = val.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSelectedDaySection(List<PublishJob> dayJobs) {
    final dayLabel = DateFormatter.formatDayHeader(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              dayLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const Spacer(),
            Text(
              '${dayJobs.length} scheduled',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (dayJobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_available_outlined, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'No posts scheduled for this day',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan ahead by creating a post to publish on ${DateFormatter.formatDate(_selectedDay)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _openComposerForDate(_selectedDay),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Schedule for this Day'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          )
        else
          ...dayJobs.map((job) => _buildScheduledJobCard(job)),
      ],
    );
  }

  Widget _buildAllUpcomingSection(List<PublishJob> allJobs) {
    if (allJobs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_note_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 10),
            const Text(
              'No upcoming scheduled posts',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Posts you schedule from the Composer will automatically appear in your publishing agenda.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _openComposerForDate(DateTime.now()),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('Create Scheduled Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Group jobs by date header
    final grouped = <String, List<PublishJob>>{};
    for (final job in allJobs) {
      final header = DateFormatter.formatDayHeader(job.scheduledAtUtc!);
      grouped.putIfAbsent(header, () => []).add(job);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${entry.value.length} posts)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            ...entry.value.map((job) => _buildScheduledJobCard(job)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildScheduledJobCard(PublishJob job) {
    final account = widget.appState.getAccountById(job.socialAccountId);
    final post = widget.appState.postRepository.getPostById(job.contentPostId);
    final brand = post != null ? widget.appState.getBrandById(post.brandId) : null;
    final scheduledTime = DateFormatter.formatTime(job.scheduledAtUtc);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Scheduled Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  scheduledTime,
                  style: AppTypography.code.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Platform Channel Badge
              if (account != null) ...[
                Expanded(
                  child: ChannelBadge(
                    account: account,
                    isCompact: true,
                  ),
                ),
              ],

              const SizedBox(width: 6),
              StatusBadge(
                status: job.status,
                isManual: job.isManual,
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Post Title & Caption Preview
          if (brand != null) ...[
            CompanyBadge(
              brand: brand,
              isCompact: true,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            post?.title.isNotEmpty == true ? post!.title : 'Untitled Scheduled Post',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (post != null && post.defaultCaption.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              post.defaultCaption,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          // Action Toolbar: Add to Google Calendar & Edit in Composer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Google Calendar Button
              OutlinedButton.icon(
                onPressed: () async {
                  final success = await CalendarExportHelper.openInGoogleCalendar(
                    title: '[Publish] ${post?.title ?? 'Post'} - ${account?.displayName ?? ''}',
                    scheduledAtUtc: job.scheduledAtUtc!,
                    details: 'Publishing destination: ${account?.platform.displayName ?? ''} (${account?.handle ?? ''})\n'
                        'Brand: ${brand?.name ?? ''}\n\n'
                        'Caption:\n${post?.defaultCaption ?? ''}',
                  );
                  if (mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Google Calendar event...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.event_available, size: 13, color: AppColors.accent),
                label: const Text('Add to Google Calendar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 8),

              // Edit in Composer Button
              TextButton.icon(
                onPressed: () {
                  if (post != null) {
                    _openComposerForDate(job.scheduledAtUtc!, existingPost: post);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Edit', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
