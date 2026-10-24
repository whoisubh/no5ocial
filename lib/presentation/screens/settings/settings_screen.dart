import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/biometric_lock_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/presentation/widgets/passkey_management_sheet.dart';
import 'package:no5ocial/presentation/widgets/team_management_sheet.dart';
import 'package:no5ocial/presentation/screens/settings/monetization_settings_view.dart';
import 'package:no5ocial/core/services/currency_service.dart';
import 'package:no5ocial/core/services/country_service.dart';

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
                  'Activity & Security Log',
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
                        'No activity recorded yet.',
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

  void _showCountrySelector(BuildContext context) {
    String searchQuery = '';
    final countries = CountryService.supportedCountries;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.public_rounded, size: 20, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Select Country & Region'),
        ],
      ),
      builder: (ctx, setSheetState) {
        final filtered = countries.where((c) {
          final q = searchQuery.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q) ||
              c.languageName.toLowerCase().contains(q) ||
              c.currencyCode.toLowerCase().contains(q) ||
              c.currencyName.toLowerCase().contains(q);
        }).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecting your country automatically sets your app language, local currency, and formatting, saved securely in your database.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search country or currency (e.g. India, Germany, USD)...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setSheetState(() => searchQuery = val.trim()),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final c = filtered[idx];
                  final isSelected = appState.selectedCountry.code == c.code;
                  return ListTile(
                    dense: true,
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Row(
                      children: [
                        Text(
                          c.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.code,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${c.languageName} • ${c.currencyCode} (${c.currencySymbol})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.accent)
                        : null,
                    onTap: () {
                      appState.setSelectedCountry(c.code);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reset Local Workspace Cache'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear your local workspace cache? Your connected channels and workspace data are securely stored and will reload upon sign-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.clearAllData();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: appState.isDarkMode ? const Color(0xFF101522) : AppColors.surface,
                  title: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: appState.isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 460;
                  final avatar = (appState.localUserPhotoUrl != null &&
                          appState.localUserPhotoUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            appState.localUserPhotoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildInitialsAvatar(appState),
                          ),
                        )
                      : _buildInitialsAvatar(appState);

                  final userDetails = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            appState.localUserName?.isNotEmpty == true
                                ? appState.localUserName!
                                : 'Authenticated User',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                  );

                  final signOutBtn = OutlinedButton.icon(
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
                  );

                  if (isNarrow) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              avatar,
                              const SizedBox(width: 12),
                              Expanded(child: userDetails),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: signOutBtn,
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        avatar,
                        const SizedBox(width: 14),
                        Expanded(child: userDetails),
                        const SizedBox(width: 10),
                        signOutBtn,
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Workspace & Team Access'),
              AnimatedBuilder(
                animation: appState,
                builder: (context, _) {
                  final isTeam = appState.isTeamMode;
                  final currentRole = appState.currentRole;
                  final membersCount = appState.teamMembers.length;
                  final pendingInvitesCount = appState.pendingInvites.where((i) => i.isValid).length;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 460;
                      final teamIcon = Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.groups_rounded, color: AppColors.accent, size: 20),
                      );

                      final teamDetails = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                isTeam ? 'Team Hierarchy' : 'Solo Workspace',
                                style: AppTypography.titleMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  currentRole.label,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTeam
                                ? '$membersCount ${membersCount == 1 ? 'member' : 'members'} · $pendingInvitesCount pending invite${pendingInvitesCount == 1 ? '' : 's'}'
                                : 'Operating in solo mode · tap to configure hierarchy',
                            style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                          ),
                        ],
                      );

                      final manageBtn = ElevatedButton.icon(
                        onPressed: () => TeamManagementSheet.show(context, appState),
                        icon: const Icon(Icons.tune_rounded, size: 14),
                        label: const Text('Manage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );

                      if (isNarrow) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  teamIcon,
                                  const SizedBox(width: 12),
                                  Expanded(child: teamDetails),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: manageBtn,
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            teamIcon,
                            const SizedBox(width: 12),
                            Expanded(child: teamDetails),
                            const SizedBox(width: 10),
                            manageBtn,
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Publishing Coins & Daily Quota'),
              MonetizationSettingsView(appState: appState),
              const SizedBox(height: 20),

              _buildSectionTitle('Preferences & Regional Settings'),
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
                              'Display Timezone',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              'Active timezone: ${appState.userTimezone}',
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

              // Unified Country & Regional Settings tile
              AnimatedBuilder(
                animation: appState,
                builder: (context, _) {
                  final country = appState.selectedCountry;
                  return InkWell(
                    onTap: () => _showCountrySelector(context),
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
                            Icons.public_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Country & Region',
                                  style: AppTypography.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${country.flag} ${country.name} • ${country.languageName} • ${country.currencyCode} (${country.currencySymbol})',
                                  style: AppTypography.bodySecondary.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${country.flag} ${country.code}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Passkeys & Biometric Security'),
              // Passkey Management Tile
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    PasskeyManagementSheet.show(context, appState: appState)
                        .then((_) => appState.refreshPasskeysCount());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.vpn_key_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Passkeys & Security Keys',
                                style: AppTypography.titleMedium,
                              ),
                              Text(
                                '${appState.registeredPasskeysCount} passkey${appState.registeredPasskeysCount == 1 ? '' : 's'} registered • Fast & secure sign-in',
                                style: AppTypography.bodySecondary.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Biometric & Screen Lock Tile
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      secondary: const Icon(
                        Icons.fingerprint,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      title: const Text(
                        'Biometric / Screen Lock',
                        style: AppTypography.titleMedium,
                      ),
                      subtitle: Text(
                        kIsWeb
                            ? 'Screen lock handled by device passkeys on Web'
                            : 'Require fingerprint, face, or PIN to unlock workspace on open',
                        style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                      ),
                      value: appState.isBiometricLockEnabled,
                      activeThumbColor: AppColors.accent,
                      onChanged: kIsWeb
                          ? null
                          : (enabled) async {
                              if (enabled) {
                                final isSupported = await BiometricLockService.instance.canCheckBiometrics();
                                if (!isSupported) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Biometric or screen lock is not set up on this device.'),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final authenticated = await BiometricLockService.instance.authenticate(
                                  localizedReason: 'Verify biometrics to enable screen lock for no5ocial',
                                );
                                if (authenticated) {
                                  BiometricLockService.instance.markAuthenticated();
                                  await appState.setBiometricLockEnabled(true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Screen lock enabled successfully.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    final err = BiometricLockService.instance.lastError ?? 'Biometric verification cancelled or failed.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(err),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                await appState.setBiometricLockEnabled(false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Screen lock disabled.'),
                                    ),
                                  );
                                }
                              }
                            },
                    ),

                    if (appState.isBiometricLockEnabled && !kIsWeb) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'Lock Inactivity Timeout',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => appState.setLockTimeoutSeconds(0),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: appState.lockTimeoutSeconds == 0
                                            ? AppColors.accentLight
                                            : AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: appState.lockTimeoutSeconds == 0
                                              ? AppColors.accent
                                              : AppColors.border,
                                          width: appState.lockTimeoutSeconds == 0 ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            appState.lockTimeoutSeconds == 0
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            size: 16,
                                            color: appState.lockTimeoutSeconds == 0
                                                ? AppColors.accent
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Lock Immediately',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: appState.lockTimeoutSeconds == 0
                                                  ? AppColors.accent
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => appState.setLockTimeoutSeconds(120),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: appState.lockTimeoutSeconds == 120
                                            ? AppColors.accentLight
                                            : AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: appState.lockTimeoutSeconds == 120
                                              ? AppColors.accent
                                              : AppColors.border,
                                          width: appState.lockTimeoutSeconds == 120 ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            appState.lockTimeoutSeconds == 120
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            size: 16,
                                            color: appState.lockTimeoutSeconds == 120
                                                ? AppColors.accent
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'After 2 minutes',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: appState.lockTimeoutSeconds == 120
                                                  ? AppColors.accent
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Security & Privacy'),
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
                      'Encrypted Account Access',
                      'Connected social channels and tokens are encrypted with device-level security protection.',
                    ),
                    const SizedBox(height: 10),
                    _buildSecurityItem(
                      Icons.verified_user_outlined,
                      'Duplicate Post Safeguards',
                      'Preflight validation prevents accidental duplicate posts across your channels.',
                    ),
                    const SizedBox(height: 10),
                    _buildSecurityItem(
                      Icons.privacy_tip_outlined,
                      'Privacy Focused',
                      'Your workspace drafts, media, and publishing schedules are private and never shared.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Activity History'),
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
                              'View Activity Logs',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              '${appState.auditRepository.getAllEvents().length} events recorded in workspace history',
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

              _buildSectionTitle('Workspace Storage'),
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
                    const Text(
                      'Local Workspace Cache',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Clear temporary cached drafts and local offline data on this device.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _confirmResetData(context),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.error),
                          label: const Text('Reset Workspace Cache', style: TextStyle(color: AppColors.error)),
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

