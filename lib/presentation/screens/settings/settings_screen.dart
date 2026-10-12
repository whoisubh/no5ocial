import 'package:flutter/material.dart';
import 'package:no5ocial/core/extensions/l10n_extension.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';

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
                const Text(
                  'Audit & Event Log',
                  style: AppTypography.titleLarge,
                ),
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
                      child: Text(
                        'No audit events recorded yet.',
                        style: AppTypography.bodySecondary,
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final e = events[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            e.eventType,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            '${e.description}\nActor: ${e.actor} • ${DateFormatter.formatRelative(e.createdAtUtc)}',
                            style: AppTypography.bodySecondary.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.entityType,
                              style: AppTypography.code.copyWith(fontSize: 10),
                            ),
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

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.schedule, size: 20, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Select Display Timezone'),
        ],
      ),
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: timezones.map((tz) {
          final isSelected = appState.userTimezone == tz;
          return ListTile(
            dense: true,
            title: Text(
              tz,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, size: 18, color: AppColors.accent)
                : null,
            onTap: () {
              appState.setTimezone(tz);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.wipeConfirmTitle),
          ],
        ),
        content: Text(
          l10n.wipeConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.dbWipedSnack),
                    backgroundColor: AppColors.ink,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.btnConfirmWipe),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(l10n.settingsTitle),
                  actions: [
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Operational Console Profile (Real Authenticated User)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    if (appState.localUserPhotoUrl != null &&
                        appState.localUserPhotoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          appState.localUserPhotoUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildInitialsAvatar(appState),
                        ),
                      )
                    else
                      _buildInitialsAvatar(appState),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  appState.localUserName?.isNotEmpty == true
                                      ? appState.localUserName!
                                      : 'Authenticated User',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.successBorder),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 10, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active Session',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            appState.localUserEmail?.isNotEmpty == true
                                ? appState.localUserEmail!
                                : 'Authenticated via Google Identity',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await appState.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 14, color: AppColors.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Preferences & Localization (l10n)'),
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
                      const Icon(
                        Icons.schedule,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configured Timezone',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              'Stored as UTC; rendered as ${appState.userTimezone}',
                              style: AppTypography.bodySecondary.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Language & Localization tile
              AnimatedBuilder(
                animation: appState,
                builder: (context, _) {
                  final currentCode = appState.currentLocale.languageCode;
                  final currentName = AppState.localeDisplayNames[currentCode] ?? currentCode;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.language,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Application Language',
                                style: AppTypography.titleMedium,
                              ),
                              Text(
                                'EN · ES · AR · FR — tap to change',
                                style: AppTypography.bodySecondary.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Switch language',
                          offset: const Offset(0, 36),
                          color: AppColors.surfaceSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border),
                          ),
                          onSelected: (code) {
                            final locale = AppState.supportedLocales.firstWhere(
                              (l) => l.languageCode == code,
                            );
                            appState.setLocale(locale);
                          },
                          itemBuilder: (_) => AppState.supportedLocales.map((locale) {
                            final code = locale.languageCode;
                            final name = AppState.localeDisplayNames[code] ?? code;
                            final isActive = code == currentCode;
                            return PopupMenuItem<String>(
                              value: code,
                              child: Row(
                                children: [
                                  if (isActive)
                                    const Icon(Icons.check, size: 14, color: AppColors.accent)
                                  else
                                    const SizedBox(width: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isActive ? AppColors.accent : AppColors.textPrimary,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Security & Compliance'),
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
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'View Audit Events',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              '${appState.auditRepository.getAllEvents().length} events recorded in audit log',
                              style: AppTypography.bodySecondary.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(l10n.dbManagementTitle),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dbManagementTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dbManagementSub,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _confirmResetData(context),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.error),
                          label: Text(l10n.btnClearAllData, style: const TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.errorBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
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
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(fontSize: 12),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySecondary.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(AppState appState) {
    final name = appState.localUserName?.trim();
    final initials = (name != null && name.isNotEmpty)
        ? (name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase())
        : (appState.localUserEmail?.isNotEmpty == true
            ? appState.localUserEmail![0].toUpperCase()
            : 'U');

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
