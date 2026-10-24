import 'package:flutter/material.dart';

import 'package:no5ocial/core/extensions/l10n_extension.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/core/services/oauth_callback_service.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/presentation/widgets/dialogs/entity_dialogs.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';

class AccountsScreen extends StatefulWidget {
  final AppState appState;

  const AccountsScreen({super.key, required this.appState});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // 0: Social Channels, 1: Channel Groups, 2: Brand Portfolio
  int _activeTab = 0;
  String? _selectedBrandFilterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OAuthCallbackService.instance.checkWebOAuthCallback();
    });
  }

  void _handleStatusToggle(BuildContext context, SocialAccount account) {
    final newStatus = account.connectionStatus == ConnectionStatus.connected
        ? ConnectionStatus.expired
        : ConnectionStatus.connected;

    widget.appState.updateAccountConnection(account.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${account.handle} status updated to: ${newStatus.label}',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, SocialAccount account) async {
    final confirm = await AppSheets.showConfirmationSheet(
      context,
      title: 'Disconnect ${account.platform.displayName} ${account.platform.accountNoun}',
      message: 'Are you sure you want to disconnect ${account.handle} (${account.displayName})? Historical posts referencing this ${account.platform.accountNoun.toLowerCase()} will remain saved.',
      confirmLabel: 'Disconnect ${account.platform.accountNoun}',
      isDestructive: true,
    );

    if (confirm) {
      widget.appState.deleteAccount(account.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account.handle} disconnected.'),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    }
  }

  Future<void> _showChangeGroupSheet(BuildContext context, SocialAccount account, Brand brand) async {
    final availableGroups = widget.appState.groups;
    final currentGroup = widget.appState.getGroupForAccount(account.id);
    String selectedValue = currentGroup?.id ?? 'standalone';
    final newGroupNameCtrl = TextEditingController();

    await AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          const Icon(Icons.folder_open_outlined, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Group Assignment: ${account.displayName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      builder: (sheetCtx, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign "${account.displayName}" (${account.handle}) to a broadcast group for 1-click group publishing, or keep it standalone under ${brand.name}.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedValue,
              decoration: const InputDecoration(
                labelText: 'Channel Group (Optional)',
                prefixIcon: Icon(Icons.folder_outlined, size: 18),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'standalone',
                  child: Row(
                    children: [
                      Icon(Icons.hub_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('None (Standalone under Company)'),
                    ],
                  ),
                ),
                ...availableGroups.map((g) {
                  final gBrand = widget.appState.getBrandById(g.brandId);
                  final isSameBrand = g.brandId == brand.id;
                  return DropdownMenuItem(
                    value: g.id,
                    child: Row(
                      children: [
                        const Icon(Icons.folder_special_outlined, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          isSameBrand
                              ? 'Group: ${g.name} (${g.accountIds.length} channels)'
                              : 'Group: ${g.name} [${gBrand?.name ?? 'Other'}] (${g.accountIds.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }),
                const DropdownMenuItem(
                  value: '__new__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('+ Create New Product Group...'),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setSheetState(() => selectedValue = val);
              },
            ),
            if (selectedValue == '__new__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: newGroupNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Group Name *',
                  hintText: 'e.g. ChatMore (Product Bundle)',
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Channels in a group can still be posted to individually, and standalone channels can still be posted to simultaneously with all other channels.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        );
      },
      actionsBuilder: (sheetCtx) => [
        TextButton(
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedValue == '__new__') {
              final newName = newGroupNameCtrl.text.trim();
              if (newName.isEmpty) return;
              final newGroup = widget.appState.createGroup(
                brandId: brand.id,
                name: newName,
                accountIds: [account.id],
              );
              widget.appState.setAccountGroup(account.id, newGroup.id);
            } else if (selectedValue == 'standalone') {
              widget.appState.setAccountGroup(account.id, null);
            } else {
              widget.appState.setAccountGroup(account.id, selectedValue);
            }
            Navigator.of(sheetCtx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  selectedValue == 'standalone'
                      ? '${account.displayName} is now a Standalone channel under ${brand.name}.'
                      : '${account.displayName} assigned to group successfully.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Group Assignment'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteBrand(BuildContext context, Brand brand) async {
    final confirm = await AppSheets.showConfirmationSheet(
      context,
      title: 'Delete Company / Brand',
      message: 'Are you sure you want to delete "${brand.name}"? This will permanently remove this company workspace and all its associated channels and channel groups.',
      confirmLabel: 'Delete Company',
      isDestructive: true,
    );

    if (confirm) {
      widget.appState.deleteBrand(brand.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company "${brand.name}" deleted.'),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    }
  }

  void _showAccountDetails(
    BuildContext context,
    SocialAccount account,
    Brand? brand,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E2E) : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PlatformLogo.getBrandColor(account.platform).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PlatformLogo.getBrandColor(account.platform).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: PlatformLogo(platform: account.platform, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName.isNotEmpty ? account.displayName : account.handle,
                        style: AppTypography.titleMedium.copyWith(fontSize: 16),
                      ),
                      Text(
                        '${account.handle.startsWith('@') ? account.handle : "@${account.handle}"} • ${brand?.name ?? "Independent"}',
                        style: AppTypography.bodySecondary,
                      ),
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
            _buildDetailRow('Target Sub-type', account.subtypeLabel),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'Group / Bundle',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.appState.getGroupForAccount(account.id)?.name ?? 'None (Standalone)',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showChangeGroupSheet(context, account, brand ?? widget.appState.brands.first);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Assign Group', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow('Handle', account.handle),
            _buildDetailRow('Status', account.connectionStatus.label),
            _buildDetailRow(
              'Workflow Mode',
              account.isManualOnly
                  ? 'Manual Handoff'
                  : 'Direct API + Manual Fallback',
            ),
            if (account.defaultPrivacy != null)
              _buildDetailRow('Default Privacy', account.defaultPrivacy!.toUpperCase()),
            _buildDetailRow(
              'Last Verified',
              account.lastVerifiedAtUtc != null
                  ? DateFormatter.formatToLocal(account.lastVerifiedAtUtc)
                  : 'Not verified yet',
            ),
            _buildDetailRow('Capabilities', account.capabilities.join(', ')),
            if (account.scopes.isNotEmpty)
              _buildDetailRow('OAuth Scopes', account.scopes.join(', ')),

            const SizedBox(height: 20),
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
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDeleteAccount(context, account);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  label: const Text('Disconnect', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorBorder),
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
            width: 130,
            child: Text(label, style: AppTypography.labelMedium),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  // --- Modal Dialog: Register Brand / Company ---
  void _showRegisterBrandDialog(BuildContext context, {Brand? existingBrand}) {
    EntityDialogs.showRegisterCompanyDialog(
      context,
      widget.appState,
      existingBrand: existingBrand,
    );
  }

  // --- Modal Dialog: Connect Social Channel ---
  void _showConnectChannelDialog(BuildContext context, {String? preselectedBrandId}) {
    EntityDialogs.showConnectChannelDialog(
      context,
      widget.appState,
      preselectedBrandId: preselectedBrandId,
    );
    return;
  }

  // --- Modal Dialog: Create Channel Group ---
  void _showCreateGroupDialog(BuildContext context, {ChannelGroup? existingGroup}) {
    EntityDialogs.showCreateGroupDialog(
      context,
      widget.appState,
      existingGroup: existingGroup,
    );
    return;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final brands = widget.appState.brands;
        final groups = widget.appState.groups;
        final allAccounts = widget.appState.accounts;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;
        final l10n = context.l10n;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: widget.appState.isDarkMode ? const Color(0xFF101522) : AppColors.surface,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Channels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.appState.isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${allAccounts.length} Connected • ${brands.length} Workspace${brands.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                      tooltip: 'Quick Actions',
                      onPressed: () => _showMobileActionMenu(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: isDesktop ? 20 : 12,
            ).copyWith(
              bottom: isDesktop ? 40 : 100, // Generous clearance so FAB never overlaps content on mobile
            ),
            children: [
              if (isDesktop)
                _buildDesktopHeroCard(context, l10n, allAccounts, brands)
              else
                _buildMobileWorkspaceHeader(context, brands, allAccounts),

              const SizedBox(height: 14),

              // Segmented Tab Filter
              _buildTabBar(isDesktop, l10n, allAccounts.length, groups.length, brands.length),
              const SizedBox(height: 16),

              // Tab 0: Channels by Brand
              if (_activeTab == 0) ...[
                if (brands.isEmpty)
                  _buildEmptyState(
                    title: l10n.noCompaniesTitle,
                    message: l10n.noCompaniesSub,
                    buttonText: l10n.btnRegisterCompany,
                    onAction: () => _showRegisterBrandDialog(context),
                  )
                else
                  ...brands
                      .where((b) => _selectedBrandFilterId == null || b.id == _selectedBrandFilterId)
                      .map((brand) => _buildBrandChannelsCard(context, brand, isDesktop)),
              ],

              // Tab 1: Channel Groups
              if (_activeTab == 1) ...[
                _buildGroupsSection(context, groups, brands, isDesktop),
              ],

              // Tab 2: Company Portfolio
              if (_activeTab == 2) ...[
                if (brands.isEmpty)
                  _buildEmptyState(
                    title: l10n.noCompaniesTitle,
                    message: l10n.noCompaniesSub,
                    buttonText: l10n.btnRegisterCompany,
                    onAction: () => _showRegisterBrandDialog(context),
                  )
                else
                  ...brands.map((brand) => _buildBrandPortfolioCard(context, brand, isDesktop)),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMobileActionMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161E2E) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_link, color: Colors.white, size: 20),
                ),
                title: const Text('Connect Channel', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Link Instagram, X, LinkedIn, or YouTube profile', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _showConnectChannelDialog(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Create Channel Group', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Bundle multiple profiles for 1-click publishing', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _showCreateGroupDialog(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.business_outlined, color: AppColors.accent, size: 20),
                ),
                title: const Text('Register Company', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Add a new brand workspace portfolio', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _showRegisterBrandDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileWorkspaceHeader(
    BuildContext context,
    List<Brand> brands,
    List<SocialAccount> allAccounts,
  ) {
    if (brands.isEmpty) return const SizedBox.shrink();

    if (brands.length > 1) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: Text('All (${allAccounts.length})'),
              selected: _selectedBrandFilterId == null,
              onSelected: (_) => setState(() => _selectedBrandFilterId = null),
              selectedColor: AppColors.ink,
              labelStyle: TextStyle(
                color: _selectedBrandFilterId == null ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            ...brands.map((b) {
              final isSelected = _selectedBrandFilterId == b.id;
              final bAccounts = allAccounts.where((a) => a.brandId == b.id).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  avatar: const Icon(Icons.business, size: 14),
                  label: Text('${b.name} ($bAccounts)'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedBrandFilterId = isSelected ? null : b.id),
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14, color: AppColors.accent),
              label: const Text('Add Company', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              onPressed: () => _showRegisterBrandDialog(context),
            ),
          ],
        ),
      );
    }

    // Single brand compact header banner
    final brand = brands.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  brand.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${allAccounts.length} channel${allAccounts.length == 1 ? '' : 's'} connected',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showConnectChannelDialog(context, preselectedBrandId: brand.id),
            icon: const Icon(Icons.add_link, size: 14),
            label: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    bool isDesktop,
    AppLocalizations l10n,
    int accountsCount,
    int groupsCount,
    int brandsCount,
  ) {
    if (isDesktop) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabPill(0, l10n.tabSocialChannels(accountsCount), Icons.share_rounded),
            const SizedBox(width: 8),
            _buildTabPill(1, l10n.tabChannelGroups(groupsCount), Icons.folder_rounded),
            const SizedBox(width: 8),
            _buildTabPill(2, l10n.tabCompanyPortfolio(brandsCount), Icons.business_rounded),
          ],
        ),
      );
    }

    // Modern Native Mobile Segmented Tab Bar (Full responsive width, no overflow)
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildMobileTabSegment(0, 'Channels', accountsCount, Icons.share_rounded),
          ),
          Expanded(
            child: _buildMobileTabSegment(1, 'Groups', groupsCount, Icons.folder_rounded),
          ),
          Expanded(
            child: _buildMobileTabSegment(2, 'Companies', brandsCount, Icons.business_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabSegment(int index, String label, int count, IconData icon) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentLight : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedPlatformBadge(String name, PlatformType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformLogo(platform: type, size: 14),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeroCard(
    BuildContext context,
    AppLocalizations l10n,
    List<SocialAccount> allAccounts,
    List<Brand> brands,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/logo/no5ocial_cropped.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.hub, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        const Text(
                          'Connected Social Workspace',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.successBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 11,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${allAccounts.length} Channels Active',
                                style: const TextStyle(
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
                    const SizedBox(height: 6),
                    const Text(
                      'Manage all your multi-platform identities, bundle same-product profiles into Groups, and publish seamlessly to Instagram, X (Twitter), LinkedIn, and YouTube.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          // Main Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showConnectChannelDialog(context),
                icon: const Icon(Icons.add_link, size: 16),
                label: Text(l10n.btnConnectChannel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context),
                icon: const Icon(Icons.folder_rounded, size: 16),
                label: Text(l10n.btnCreateChannelGroup),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showRegisterBrandDialog(context),
                icon: const Icon(Icons.business_outlined, size: 16),
                label: Text(l10n.btnRegisterCompany),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if (brands.any((b) => b.id.startsWith('brand-')))
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Purge Sample Demo Data'),
                        content: const Text(
                          'This will delete pre-seeded sample brands (Boofer, Favtunes, Shaadow demo accounts) so only your real company accounts appear in the dashboard.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Purge Demo Data'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.appState.purgeDemoData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demo sample brands removed.'),
                            backgroundColor: AppColors.ink,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: AppColors.error),
                  label: const Text('Purge Sample Brands', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
            ],
          ),
          if (brands.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Active Companies:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                ...brands.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 12, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Text(
                        b.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChannelsCard(BuildContext context, Brand brand, bool isDesktop) {
    final brandAccounts = widget.appState.accounts
        .where((a) => a.brandId == brand.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        brand.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: brandAccounts.isNotEmpty ? AppColors.success : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${brandAccounts.length} connected channel${brandAccounts.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: brandAccounts.isNotEmpty ? AppColors.success : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (brand.websiteUrl != null && brand.websiteUrl!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                brand.websiteUrl!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  IconButton(
                    tooltip: 'Edit Company Details',
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                    onPressed: () => _showRegisterBrandDialog(context, existingBrand: brand),
                  ),
                  IconButton(
                    tooltip: 'Delete Company',
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    onPressed: () => _confirmDeleteBrand(context, brand),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showConnectChannelDialog(context, preselectedBrandId: brand.id),
                    icon: const Icon(Icons.add_link, size: 14),
                    label: const Text('Connect Channel', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                  ),
                ] else ...[
                  // Clean Mobile Action Popup Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    tooltip: 'Company Options',
                    onSelected: (val) {
                      if (val == 'connect') {
                        _showConnectChannelDialog(context, preselectedBrandId: brand.id);
                      } else if (val == 'edit') {
                        _showRegisterBrandDialog(context, existingBrand: brand);
                      } else if (val == 'delete') {
                        _confirmDeleteBrand(context, brand);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'connect',
                        child: Row(
                          children: [
                            Icon(Icons.add_link, size: 18, color: AppColors.accent),
                            SizedBox(width: 10),
                            Text('Connect Channel'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit Company Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 10),
                            Text('Delete Company', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (brand.description != null && brand.description!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                brand.description!,
                style: AppTypography.bodySecondary.copyWith(fontSize: 12),
              ),
            ),
          ],

          // Accounts list
          if (brandAccounts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.accentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_outlined, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No channels connected yet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        'Link your social media profiles to start publishing and scheduling content for ${brand.name}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSupportedPlatformBadge('Instagram', PlatformType.instagram),
                        _buildSupportedPlatformBadge('X (Twitter)', PlatformType.x),
                        _buildSupportedPlatformBadge('LinkedIn', PlatformType.linkedin),
                        _buildSupportedPlatformBadge('YouTube', PlatformType.youtube),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: isDesktop ? 260 : double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _showConnectChannelDialog(context, preselectedBrandId: brand.id),
                        icon: const Icon(Icons.add_link, size: 18),
                        label: const Text(
                          'Connect Channel',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
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
                final accountGroup = widget.appState.getGroupForAccount(acc.id);

                final hasDistinctName = acc.displayName.isNotEmpty &&
                    acc.displayName.toLowerCase() != acc.handle.toLowerCase() &&
                    acc.displayName.toLowerCase() != '@${acc.handle.toLowerCase()}';
                final titleText = hasDistinctName
                    ? acc.displayName
                    : (acc.handle.startsWith('@') ? acc.handle : '@${acc.handle}');
                final subtitleText = hasDistinctName
                    ? '${acc.handle.startsWith('@') ? acc.handle : "@${acc.handle}"} • ${acc.subtypeLabel}'
                    : acc.subtypeLabel;

                return InkWell(
                  onTap: () => _showAccountDetails(context, acc, brand),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: PlatformLogo.getBrandColor(acc.platform).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PlatformLogo.getBrandColor(acc.platform).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Center(
                            child: PlatformLogo(platform: acc.platform, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titleText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildConnectionChip(acc.connectionStatus, acc.isManualOnly),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      subtitleText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (accountGroup != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.folder_outlined,
                                            size: 10,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            accountGroup.name,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                          tooltip: 'Channel Actions',
                          onSelected: (val) {
                            if (val == 'details') {
                              _showAccountDetails(context, acc, brand);
                            } else if (val == 'change_group') {
                              _showChangeGroupSheet(context, acc, brand);
                            } else if (val == 'toggle') {
                              _handleStatusToggle(context, acc);
                            } else if (val == 'disconnect') {
                              _confirmDeleteAccount(context, acc);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16),
                                  SizedBox(width: 8),
                                  Text('Channel Details'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'change_group',
                              child: Row(
                                children: [
                                  const Icon(Icons.folder_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(accountGroup != null ? 'Change Group (Current: ${accountGroup.name})' : 'Assign to Group...'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    acc.connectionStatus == ConnectionStatus.connected
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    acc.connectionStatus == ConnectionStatus.connected
                                        ? 'Simulate Expiry'
                                        : 'Reconnect Channel',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'disconnect',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Disconnect Channel', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGroupsSection(
    BuildContext context,
    List<ChannelGroup> groups,
    List<Brand> brands,
    bool isDesktop,
  ) {
    if (groups.isEmpty) {
      return _buildEmptyState(
        title: 'No Channel Groups Created Yet',
        message: 'Groups let you bundle multiple social profiles (e.g. IG + X + LinkedIn) for the same product to publish to all of them with a single click!',
        buttonText: 'Create First Channel Group',
        onAction: () => _showCreateGroupDialog(context),
      );
    }

    return Column(
      children: groups.map((g) {
        final brand = widget.appState.getBrandById(g.brandId);
        final bundledAccounts = g.accountIds
            .map((id) => widget.appState.getAccountById(id))
            .whereType<SocialAccount>()
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                g.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (brand != null) ...[
                              const SizedBox(width: 8),
                              CompanyBadge(brand: brand, isCompact: true),
                            ],
                          ],
                        ),
                        if (g.description != null)
                          Text(
                            g.description!,
                            style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Group',
                      onPressed: () => _showCreateGroupDialog(context, existingGroup: g),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      tooltip: 'Delete Group',
                      onPressed: () async {
                        final confirm = await AppSheets.showConfirmationSheet(
                          context,
                          title: 'Delete Channel Group',
                          message: 'Are you sure you want to delete group "${g.name}"? The individual accounts will not be deleted.',
                          confirmLabel: 'Delete Group',
                          isDestructive: true,
                        );
                        if (confirm) {
                          widget.appState.deleteGroup(g.id);
                        }
                      },
                    ),
                  ] else ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Group Actions',
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _showCreateGroupDialog(context, existingGroup: g);
                        } else if (val == 'delete') {
                          final confirm = await AppSheets.showConfirmationSheet(
                            context,
                            title: 'Delete Channel Group',
                            message: 'Are you sure you want to delete group "${g.name}"? The individual accounts will not be deleted.',
                            confirmLabel: 'Delete Group',
                            isDestructive: true,
                          );
                          if (confirm) {
                            widget.appState.deleteGroup(g.id);
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Group'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete Group', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                'Bundled Channels (${bundledAccounts.length}):',
                style: AppTypography.labelMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bundledAccounts.map((acc) {
                  return ChannelBadge(
                    account: acc,
                    isCompact: true,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBrandPortfolioCard(BuildContext context, Brand brand, bool isDesktop) {
    final brandAccounts = widget.appState.accounts.where((a) => a.brandId == brand.id).toList();
    final brandGroups = widget.appState.getGroupsByBrand(brand.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (brand.websiteUrl != null)
                      Text(
                        brand.websiteUrl!,
                        style: const TextStyle(fontSize: 11, color: AppColors.accent),
                      ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Edit Company Details',
                  onPressed: () => _showRegisterBrandDialog(context, existingBrand: brand),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  tooltip: 'Delete Company',
                  onPressed: () => _confirmDeleteBrand(context, brand),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: () => _showConnectChannelDialog(context, preselectedBrandId: brand.id),
                  icon: const Icon(Icons.add_link, size: 14),
                  label: const Text('Add Channel'),
                ),
              ] else ...[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  tooltip: 'Company Actions',
                  onSelected: (val) {
                    if (val == 'add') {
                      _showConnectChannelDialog(context, preselectedBrandId: brand.id);
                    } else if (val == 'edit') {
                      _showRegisterBrandDialog(context, existingBrand: brand);
                    } else if (val == 'delete') {
                      _confirmDeleteBrand(context, brand);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add_link, size: 18, color: AppColors.accent),
                          SizedBox(width: 10),
                          Text('Connect Channel'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Edit Company Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text('Delete Company', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (brand.description != null) ...[
            const SizedBox(height: 8),
            Text(brand.description!, style: AppTypography.bodySecondary),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Connected Channels', '${brandAccounts.length}'),
              const SizedBox(width: 16),
              _buildMiniStat('Channel Groups', '${brandGroups.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub_outlined, size: 28, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: AppTypography.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 16),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
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
        child: const Text(
          'Manual',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final isConnected = status == ConnectionStatus.connected;
    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            status.label,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
