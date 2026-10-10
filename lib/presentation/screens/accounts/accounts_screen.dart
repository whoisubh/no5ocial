import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';

class AccountsScreen extends StatelessWidget {
  final AppState appState;

  const AccountsScreen({super.key, required this.appState});

  void _handleStatusToggle(BuildContext context, SocialAccount account) {
    final newStatus = account.connectionStatus == ConnectionStatus.connected
        ? ConnectionStatus.expired
        : ConnectionStatus.connected;

    appState.updateAccountConnection(account.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${account.handle} status updated to: ${newStatus.label}',
        ),
      ),
    );
  }

  void _showAccountDetails(BuildContext context, SocialAccount account, Brand? brand) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PlatformIconChip(account: account, isCompact: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.displayName, style: AppTypography.titleMedium),
                      Text('Brand: ${brand?.name ?? "N/A"}', style: AppTypography.bodySecondary),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            _buildDetailRow('Platform', account.platform.displayName),
            _buildDetailRow('Handle', account.handle),
            _buildDetailRow('Status', account.connectionStatus.label),
            _buildDetailRow('Workflow Mode', account.isManualOnly ? 'Manual Handoff' : 'Direct API + Manual Fallback'),
            _buildDetailRow(
              'Last Verified',
              account.lastVerifiedAtUtc != null
                  ? DateFormatter.formatToLocal(account.lastVerifiedAtUtc)
                  : 'Not verified yet',
            ),
            _buildDetailRow(
              'Capabilities',
              account.capabilities.join(', '),
            ),
            if (account.scopes.isNotEmpty)
              _buildDetailRow('OAuth Scopes', account.scopes.join(', ')),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleStatusToggle(context, account);
                    },
                    child: Text(
                      account.connectionStatus == ConnectionStatus.connected
                          ? 'Simulate Expired Token'
                          : 'Re-authenticate / Connect',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.labelMedium),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyMedium),
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
        final brands = appState.brands;
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
                      height: 26,
                      errorBuilder: (_, _, _) => const Icon(Icons.hub),
                    ),
                  ),
                  title: const Text('Brand & Channel Registry'),
                ),
          body: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            children: [
              // Hero channel status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/logo/no5ocial_white.png',
                                height: 26,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Text(
                                  'No5ocial Channels',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 11, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active Registry',
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
                          const SizedBox(height: 8),
                          const Text(
                            'Configurable brand identity matrix. Each destination enforces individual preflight checks, platform quotas, and manual handoffs.',
                            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Brand Cards List
              ...brands.map((brand) {
                final brandAccounts = appState.accounts.where((a) => a.brandId == brand.id).toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              brand.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (brand.description != null)
                              Expanded(
                                child: Text(
                                  brand.description!,
                                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${brandAccounts.length} profiles',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Accounts list
                    if (brandAccounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No social accounts registered for this brand.',
                          style: AppTypography.bodySecondary,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: brandAccounts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (c, aIdx) {
                          final acc = brandAccounts[aIdx];
                          return InkWell(
                            onTap: () => _showAccountDetails(context, acc, brand),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  PlatformIconChip(account: acc, isCompact: true),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(acc.displayName, style: AppTypography.titleMedium.copyWith(fontSize: 13)),
                                        Text(
                                          'Verified: ${acc.lastVerifiedAtUtc != null ? DateFormatter.formatRelative(acc.lastVerifiedAtUtc) : "Never"}',
                                          style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildConnectionChip(acc.connectionStatus, acc.isManualOnly),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

  Widget _buildConnectionChip(ConnectionStatus status, bool isManual) {
    if (isManual) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Manual',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
        ),
      );
    }

    final isConnected = status == ConnectionStatus.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isConnected ? AppColors.successBorder : AppColors.warningBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.check : Icons.warning_amber_rounded,
            size: 10,
            color: isConnected ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: isConnected ? AppColors.success : AppColors.warning,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
