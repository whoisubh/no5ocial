import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  void _showAuditLog(BuildContext context) {
    final events = appState.auditRepository.getAllEvents();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Audit & Event Log', style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: events.isEmpty
                  ? const Center(
                      child: Text('No audit events recorded yet.', style: AppTypography.bodySecondary),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final e = events[idx];
                        return ListTile(
                          dense: true,
                          title: Text(e.eventType, style: AppTypography.titleMedium.copyWith(fontSize: 12)),
                          subtitle: Text(
                            '${e.description}\nActor: ${e.actor} • ${DateFormatter.formatRelative(e.createdAtUtc)}',
                            style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(e.entityType, style: AppTypography.code.copyWith(fontSize: 10)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimezoneSelector(BuildContext context) {
    final timezones = [
      'Local (UTC+5:30)',
      'UTC',
      'US/Eastern (UTC-5:00)',
      'US/Pacific (UTC-8:00)',
      'Europe/London (UTC+0:00)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Display Timezone'),
        children: timezones.map((tz) {
          final isSelected = appState.userTimezone == tz;
          return SimpleDialogOption(
            onPressed: () {
              appState.setTimezone(tz);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tz, style: AppTypography.bodyLarge),
                if (isSelected) const Icon(Icons.check, size: 18, color: AppColors.accent),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('System Settings & Diagnostics'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Operational Console Profile
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.ink,
                      child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shaadow Internal Operator', style: AppTypography.titleMedium),
                          Text('No5ocial v1.0.0-beta • Zero-Seat-Cost Engine', style: AppTypography.bodySecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Preferences & Timezone'),
              InkWell(
                onTap: () => _showTimezoneSelector(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Configured Timezone', style: AppTypography.titleMedium),
                            Text(
                              'Stored as UTC; rendered as ${appState.userTimezone}',
                              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Security & Compliance (SECURITY.md)'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityItem(
                      Icons.shield_outlined,
                      'Client-Side Credential Safety',
                      'Zero OAuth client secrets or long-lived refresh tokens stored on client.',
                    ),
                    const SizedBox(height: 10),
                    _buildSecurityItem(
                      Icons.lock_clock_outlined,
                      'Publishing Idempotency & Duplicate Guards',
                      'Durable client & server idempotency keys prevent accidental multi-publish.',
                    ),
                    const SizedBox(height: 10),
                    _buildSecurityItem(
                      Icons.visibility_off_outlined,
                      'Secret Redaction Engine',
                      'Bearer tokens and authorization headers redacted prior to audit serialization.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Operations & Audit Logs'),
              InkWell(
                onTap: () => _showAuditLog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: AppColors.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('View Audit Events', style: AppTypography.titleMedium),
                            Text(
                              '${appState.auditRepository.getAllEvents().length} events recorded in audit log',
                              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 12)),
              Text(subtitle, style: AppTypography.bodySecondary.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
