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
import 'package:no5ocial/domain/models/platform_target_config.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/core/services/instagram_service.dart';
import 'package:no5ocial/core/services/linkedin_service.dart';
import 'package:no5ocial/core/services/x_service.dart';
import 'package:no5ocial/core/services/youtube_service.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';
import 'package:no5ocial/core/services/oauth_callback_service.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/presentation/widgets/dialogs/entity_dialogs.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
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
    final availableGroups = widget.appState.getGroupsByBrand(brand.id);
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
              'Assign "${account.displayName}" (${account.handle}) to a product group for 1-click group publishing, or keep it as a standalone channel under ${brand.name}.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedValue,
              decoration: const InputDecoration(
                labelText: 'Product / Campaign Group (Optional)',
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
                ...availableGroups.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_special_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('Group: ${g.name} (${g.accountIds.length} channels)'),
                    ],
                  ),
                )),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName,
                        style: AppTypography.titleMedium.copyWith(fontSize: 16),
                      ),
                      Text(
                        'Company: ${brand?.name ?? "Independent"}',
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
            _buildDetailRow(
              'Group / Bundle',
              widget.appState.getGroupForAccount(account.id)?.name ?? 'None (Standalone under Company)',
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
    final brands = widget.appState.brands;
    if (brands.isEmpty) {
      _showRegisterBrandDialog(context);
      return;
    }

    String selectedBrandId = preselectedBrandId ?? brands.first.id;
    PlatformType selectedPlatform = PlatformType.youtube;
    PlatformSubtype selectedSubtype = PlatformConfigRegistry.getDefaultSubtype(selectedPlatform);
    List<String> selectedFormats = List<String>.from(selectedSubtype.defaultFormats);
    String selectedPrivacy = 'unlisted'; // For YouTube

    final nicknameCtrl = TextEditingController();
    final newGroupNameCtrl = TextEditingController();

    bool isIntegrated = false;
    String? externalAccountId;
    String? apiVerifiedTitle;
    String? apiVerifiedHandle;

    // Group selection: 'standalone', existing groupId, or '__new__'
    String selectedGroupValue = 'standalone';

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.add_link, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Connect Channel / Destination'),
        ],
      ),
      builder: (ctx, setDialogState) {
        final availableGroups = widget.appState.groups
            .where((g) => g.brandId == selectedBrandId)
            .toList();
        final availableSubtypes = PlatformConfigRegistry.getSubtypes(selectedPlatform);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company / Workspace Selector
            DropdownButtonFormField<String>(
              initialValue: selectedBrandId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Company / Workspace',
                prefixIcon: Icon(Icons.business, size: 18),
              ),
              items: brands.map((b) => DropdownMenuItem(
                value: b.id,
                child: Text(b.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() {
                    selectedBrandId = val;
                    selectedGroupValue = 'standalone';
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Social Platform Selector
            DropdownButtonFormField<PlatformType>(
              initialValue: selectedPlatform,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Social Platform',
                prefixIcon: Icon(Icons.hub_outlined, size: 18),
              ),
              items: PlatformType.values.map((p) => DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    PlatformLogo(platform: p, size: 18),
                    const SizedBox(width: 8),
                    Text(p.displayName),
                  ],
                ),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() {
                    selectedPlatform = val;
                    selectedSubtype = PlatformConfigRegistry.getDefaultSubtype(val);
                    selectedFormats = List<String>.from(selectedSubtype.defaultFormats);
                    isIntegrated = false;
                    apiVerifiedTitle = null;
                    apiVerifiedHandle = null;
                    externalAccountId = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Target Sub-type / Entity Selector
            DropdownButtonFormField<PlatformSubtype>(
              initialValue: selectedSubtype,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Target Sub-type *',
                prefixIcon: Icon(Icons.alt_route, size: 18),
              ),
              items: availableSubtypes.map((st) => DropdownMenuItem(
                value: st,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      st.requiresAdminRole
                          ? Icons.business_outlined
                          : Icons.account_circle_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      st.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() {
                    selectedSubtype = val;
                    selectedFormats = List<String>.from(val.defaultFormats);
                    isIntegrated = false;
                    apiVerifiedTitle = null;
                    apiVerifiedHandle = null;
                    externalAccountId = null;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Linking Conditions & Policy Requirements Advisory Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selectedSubtype.isManualOnly ? Icons.info_outline : Icons.shield_outlined,
                        size: 15,
                        color: selectedSubtype.isManualOnly ? AppColors.warning : AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Prerequisites for ${selectedSubtype.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            color: selectedSubtype.isManualOnly ? AppColors.warning : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedSubtype.requiresAdminRole) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Admin Role', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedSubtype.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  ...selectedSubtype.linkingConditions.map((cond) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            cond,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.25),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (selectedSubtype.policyNotice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notice: ${selectedSubtype.policyNotice!}',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: selectedSubtype.isManualOnly ? AppColors.warning : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content Formats Multi-Select ("What You Will Post")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'What will you post on this channel?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: PlatformConfigRegistry.formatLabels.entries.map((entry) {
                    final isSupported = selectedSubtype.supportedFormats.contains(entry.key);
                    final isSelected = selectedFormats.contains(entry.key);
                    final icon = PlatformConfigRegistry.formatIcons[entry.key];

                    return FilterChip(
                      avatar: icon != null
                          ? Icon(
                              icon,
                              size: 14,
                              color: isSupported
                                  ? (isSelected ? Colors.white : AppColors.textSecondary)
                                  : AppColors.textMuted,
                            )
                          : null,
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSupported
                              ? (isSelected ? Colors.white : AppColors.textPrimary)
                              : AppColors.textMuted,
                        ),
                      ),
                      selected: isSelected && isSupported,
                      onSelected: isSupported
                          ? (checked) {
                              setDialogState(() {
                                if (checked) {
                                  selectedFormats.add(entry.key);
                                } else {
                                  if (selectedFormats.length > 1) {
                                    selectedFormats.remove(entry.key);
                                  }
                                }
                              });
                            }
                          : null,
                      selectedColor: AppColors.accent,
                      checkmarkColor: Colors.white,
                      backgroundColor: isSupported ? AppColors.surface : AppColors.surfaceSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected && isSupported ? AppColors.accent : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // YouTube Default Privacy Configuration
            if (selectedPlatform == PlatformType.youtube) ...[
              DropdownButtonFormField<String>(
                initialValue: selectedPrivacy,
                decoration: const InputDecoration(
                  labelText: 'Default Video Privacy Status *',
                  prefixIcon: Icon(Icons.lock_outline, size: 18),
                  helperText: 'Safeguard: videos upload as Unlisted so team can review before making public.',
                  helperMaxLines: 2,
                ),
                items: const [
                  DropdownMenuItem(value: 'unlisted', child: Text('Unlisted (Recommended for Review)')),
                  DropdownMenuItem(value: 'public', child: Text('Public (Instant Release)')),
                  DropdownMenuItem(value: 'private', child: Text('Private (Hidden Draft)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPrivacy = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Authentication Section
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _openPlatformAuthDialog(
                    context: ctx,
                    platform: selectedPlatform,
                    subtype: selectedSubtype,
                    onSuccess: (name, handle, id) {
                      setDialogState(() {
                        isIntegrated = true;
                        apiVerifiedTitle = name;
                        apiVerifiedHandle = handle;
                        externalAccountId = id;
                      });
                    },
                  );
                },
                icon: Icon(isIntegrated ? Icons.check_circle : Icons.link, size: 18),
                label: Text(
                  isIntegrated
                      ? '${selectedSubtype.name} Verified'
                      : 'Authenticate ${selectedSubtype.name}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIntegrated ? AppColors.success : AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            // Successful Integration Profile Card
            if (isIntegrated) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    PlatformLogo(platform: selectedPlatform, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apiVerifiedTitle ?? selectedSubtype.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            '${apiVerifiedHandle ?? ''} • ${selectedSubtype.name} (ID: ${externalAccountId ?? 'verified'})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Nickname (Optional)
            TextField(
              controller: nicknameCtrl,
              decoration: InputDecoration(
                labelText: 'Nickname (Optional)',
                hintText: isIntegrated
                    ? 'Defaults to "${apiVerifiedTitle ?? selectedSubtype.name}"'
                    : 'e.g. Primary ${selectedSubtype.name}',
              ),
            ),

            const SizedBox(height: 14),

            // Group Selection (Dropdown) - Optional
            DropdownButtonFormField<String>(
              initialValue: selectedGroupValue,
              decoration: const InputDecoration(
                labelText: 'Product / Campaign Group (Optional)',
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
                ...availableGroups.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Row(
                    children: [
                      const Icon(Icons.folder_special_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('Group: ${g.name} (${g.accountIds.length} channels)'),
                    ],
                  ),
                )),
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
                if (val != null) setDialogState(() => selectedGroupValue = val);
              },
            ),

            if (selectedGroupValue == '__new__') ...[
              const SizedBox(height: 10),
              TextField(
                controller: newGroupNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Group Name *',
                  hintText: 'e.g. ChatMore (Product Bundle)',
                  isDense: true,
                ),
              ),
            ],

            const SizedBox(height: 6),
            const Text(
              'Groups are optional. Use them to bundle related handles for a product (e.g. ChatMore) for 1-click group posting. Standalone channels can still be published to individually or selected alongside other channels.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isIntegrated
              ? () {
                  final effectiveHandle = apiVerifiedHandle ??
                      '@${(nicknameCtrl.text.trim().isNotEmpty ? nicknameCtrl.text.trim() : selectedSubtype.name).replaceAll(RegExp(r'\s+'), '').toLowerCase()}';

                  final effectiveName = nicknameCtrl.text.trim().isNotEmpty
                      ? nicknameCtrl.text.trim()
                      : (apiVerifiedTitle ?? '${selectedPlatform.displayName} ${selectedSubtype.name}');

                  String? targetGroupId;
                  String? newGroupName;

                  if (selectedGroupValue != 'standalone' && selectedGroupValue != '__new__') {
                    targetGroupId = selectedGroupValue;
                  } else if (selectedGroupValue == '__new__') {
                    newGroupName = newGroupNameCtrl.text.trim().isNotEmpty
                        ? newGroupNameCtrl.text.trim()
                        : '$effectiveName Group';
                  }

                  final finalCapabilities = [
                    ...selectedFormats,
                    'subtype:${selectedSubtype.id}',
                    if (selectedPlatform == PlatformType.youtube) 'privacy:$selectedPrivacy',
                  ];

                  widget.appState.connectAccount(
                    brandId: selectedBrandId,
                    platform: selectedPlatform,
                    displayName: effectiveName,
                    handle: effectiveHandle,
                    externalAccountId: externalAccountId ?? 'ext_${selectedSubtype.id}',
                    isManualOnly: false,
                    targetGroupId: targetGroupId,
                    newGroupName: newGroupName,
                    capabilities: finalCapabilities,
                    scopes: selectedSubtype.scopes,
                  );

                  Navigator.of(ctx).pop();

                  AppSheets.showChannelLinkedSheet(
                    context,
                    platformName: '${selectedPlatform.displayName} (${selectedSubtype.name})',
                    handle: effectiveHandle,
                    displayName: effectiveName,
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Channel'),
        ),
      ],
    );
  }

  // --- Modal Dialog: Platform Integration ---
  Future<void> _openPlatformAuthDialog({
    required BuildContext context,
    required PlatformType platform,
    required PlatformSubtype subtype,
    required void Function(String name, String handle, String id) onSuccess,
  }) async {
    final tokenCtrl = TextEditingController();
    bool isSubmitting = false;

    await AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          PlatformLogo(platform: platform, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Integrate ${platform.displayName} ${subtype.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      builder: (authCtx, setAuthState) {
        String tokenLabel = 'Access Token / Bearer Token';
        String tokenHint = 'Paste official OAuth token';
        String apiDescription = '';

        switch (platform) {
          case PlatformType.youtube:
            if (subtype.id == 'youtube_brand') {
              tokenLabel = 'Google OAuth Token (Brand Channel)';
              tokenHint = 'Paste token with youtube.upload scope';
              apiDescription = 'Uses YouTube Data API v3 with Brand Channel picker to upload videos.';
            } else {
              tokenLabel = 'Google OAuth Access Token';
              tokenHint = 'Paste Google OAuth token or sign in';
              apiDescription = 'Uses YouTube Data API v3 (GET /youtube/v3/channels?mine=true) to upload to standard channel.';
            }
            break;
          case PlatformType.linkedin:
            if (subtype.id == 'linkedin_page') {
              tokenLabel = 'LinkedIn Page Admin OAuth Access Token';
              tokenHint = 'Paste token with w_organization_social scope';
              apiDescription = 'Uses LinkedIn Organizations API to publish officially as verified company page (urn:li:organization).';
            } else {
              tokenLabel = 'LinkedIn Member OAuth Access Token';
              tokenHint = 'Paste token with openid, profile, w_member_social';
              apiDescription = 'Uses LinkedIn OpenID Connect (GET /v2/userinfo) to publish directly to member profile.';
            }
            break;
          case PlatformType.x:
            tokenLabel = 'X / Twitter API v2 Bearer Token';
            tokenHint = 'Paste OAuth 2.0 User Access Token';
            apiDescription = subtype.id == 'x_premium'
                ? 'Uses Twitter API v2 with extended limits for X Premium profile.'
                : 'Uses Twitter API v2 (GET /2/users/me) to auto-extract account name and handle.';
            break;
          case PlatformType.instagram:
            tokenLabel = 'Meta / Instagram Graph API Access Token';
            tokenHint = 'Paste Instagram Graph token';
            apiDescription = 'Uses Meta Graph API (GET /me?fields=id,username) to publish to Instagram Professional account.';
            break;
          case PlatformType.facebook:
            tokenLabel = subtype.id == 'facebook_page' ? 'Facebook Page Access Token' : 'Facebook Graph API Token';
            tokenHint = 'Paste Page token with pages_manage_posts scope';
            apiDescription = 'Uses Facebook Graph API (GET /me/accounts) to manage and publish to Facebook Pages.';
            break;
          case PlatformType.tiktok:
            tokenLabel = 'TikTok Content Posting API Token';
            tokenHint = 'Paste TikTok OAuth Access Token';
            apiDescription = 'Uses TikTok Creator API (POST /v2/post/publish/video/init/) for direct video publishing.';
            break;
          case PlatformType.pinterest:
            tokenLabel = 'Pinterest API v5 Bearer Token';
            tokenHint = 'Paste Pinterest OAuth Access Token';
            apiDescription = 'Uses Pinterest API v5 (GET /v5/user_account) to create pins and manage boards.';
            break;
          case PlatformType.threads:
            tokenLabel = 'Threads API Access Token';
            tokenHint = 'Paste Threads OAuth Access Token';
            apiDescription = 'Uses Meta Threads API (GET /me/threads) to publish thread updates and carousels.';
            break;
        }

        Future<void> verifyWithToken(String token) async {
          if (token.trim().isEmpty) {
            ScaffoldMessenger.of(authCtx).showSnackBar(
              const SnackBar(
                content: Text('Please enter an access token to verify with official API.'),
                backgroundColor: AppColors.warning,
              ),
            );
            return;
          }

          setAuthState(() => isSubmitting = true);
          try {
            String name = '';
            String handle = '';
            String id = '';

            switch (platform) {
              case PlatformType.youtube:
                final info = await YouTubeService.instance.fetchMyChannel(accessToken: token);
                name = info.title;
                handle = info.handle;
                id = info.id;
                break;
              case PlatformType.linkedin:
                final info = await LinkedInService.instance.fetchMemberProfile(accessToken: token);
                name = subtype.id == 'linkedin_page' ? '${info.name} (Company Page)' : info.name;
                handle = info.handle;
                id = info.id;
                break;
              case PlatformType.x:
                final info = await XService.instance.fetchUserProfile(accessToken: token);
                name = info.name;
                handle = info.handle;
                id = info.id;
                break;
              case PlatformType.instagram:
                final info = await InstagramService.instance.fetchProfile(accessToken: token);
                name = info.name;
                handle = info.handle;
                id = info.id;
                break;
              case PlatformType.facebook:
              case PlatformType.tiktok:
              case PlatformType.pinterest:
              case PlatformType.threads:
                throw Exception(
                  '${platform.displayName} direct API automated verification is currently pending official provider app review.',
                );
            }

            onSuccess(name, handle, id);
            if (authCtx.mounted) Navigator.of(authCtx).pop();
          } catch (e, st) {
            if (authCtx.mounted) {
              AppErrorHandler.showError(authCtx, e, stackTrace: st);
            }
          } finally {
            if (authCtx.mounted) setAuthState(() => isSubmitting = false);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(apiDescription, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            if (platform == PlatformType.youtube) ...[
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final channel = await YouTubeService.instance.fetchMyChannel();
                          onSuccess(channel.title, channel.handle, channel.id);
                          if (authCtx.mounted) Navigator.of(authCtx).pop();
                        } catch (e) {
                          if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.account_circle, size: 18),
                label: const Text('Sign in with Google OAuth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final brandId = widget.appState.brands.isNotEmpty
                              ? widget.appState.brands.first.id
                              : 'default';
                          final launched = await YouTubeService.instance.launchOAuthConnection(
                            brandId: brandId,
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open web browser for YouTube OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) {
                            AppErrorHandler.showError(authCtx, e, stackTrace: st);
                          }
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('Sign in via Browser (Web OAuth)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR USE ACCESS TOKEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (platform == PlatformType.instagram) ...[
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final brandId = widget.appState.brands.isNotEmpty
                              ? widget.appState.brands.first.id
                              : 'default';
                          final launched = await InstagramService.instance.launchOAuthConnection(
                            brandId: brandId,
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open web browser for Instagram OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Opening Instagram Login in browser to authorize your account...'),
                                backgroundColor: AppColors.instagram,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) {
                            AppErrorHandler.showError(authCtx, e, stackTrace: st);
                          }
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('Sign in with Instagram (Meta OAuth)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.instagram,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR USE GRAPH API ACCESS TOKEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (platform == PlatformType.linkedin) ...[
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final brandId = widget.appState.brands.isNotEmpty
                              ? widget.appState.brands.first.id
                              : 'default';
                          final isPage = subtype.id == 'linkedin_page';
                          final launched = await LinkedInService.instance.launchOAuthConnection(
                            brandId: brandId,
                            accountType: isPage ? 'page' : 'personal',
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open web browser for LinkedIn OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              SnackBar(
                                content: Text('Opening LinkedIn OAuth in browser to authorize ${isPage ? "Company Page" : "Personal Profile"}...'),
                                backgroundColor: AppColors.linkedin,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) {
                            AppErrorHandler.showError(authCtx, e, stackTrace: st);
                          }
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text(subtype.id == 'linkedin_page'
                    ? 'Sign in with LinkedIn (Company Page)'
                    : 'Sign in with LinkedIn (Member Profile)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.linkedin,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR USE REST API ACCESS TOKEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: tokenCtrl,
              decoration: InputDecoration(
                labelText: tokenLabel,
                hintText: tokenHint,
                prefixIcon: const Icon(Icons.key, size: 16),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : () => verifyWithToken(tokenCtrl.text),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified, size: 16),
                  label: Text(isSubmitting ? 'Verifying...' : 'Verify & Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      actionsBuilder: (authCtx) => [
        TextButton(
          onPressed: () => Navigator.of(authCtx).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  // --- Modal Dialog: Create Channel Group ---
  void _showCreateGroupDialog(BuildContext context, {ChannelGroup? existingGroup}) {
    final brands = widget.appState.brands;
    if (brands.isEmpty) {
      _showRegisterBrandDialog(context);
      return;
    }

    String selectedBrandId = existingGroup?.brandId ?? brands.first.id;
    final nameCtrl = TextEditingController(text: existingGroup?.name ?? '');
    final descCtrl = TextEditingController(text: existingGroup?.description ?? '');
    final Set<String> selectedAccountIds = Set.from(existingGroup?.accountIds ?? []);

    AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          const Icon(Icons.folder_rounded, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              existingGroup == null ? 'Create Channel Group' : 'Edit Channel Group',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      builder: (ctx, setDialogState) {
        final eligibleAccounts = widget.appState.accounts
            .where((a) => a.brandId == selectedBrandId)
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                    const Text(
                      'Group multiple profiles for the same company or product across different platforms (e.g. IG + X + LinkedIn + YouTube). When composing, select the group to auto-target all bundled profiles at once!',
                      style: AppTypography.bodySecondary,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBrandId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Company / Brand *',
                      ),
                      items: brands.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedBrandId = val;
                            selectedAccountIds.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group Name *',
                        hintText: 'e.g. Flagship Launch Squad or Creator Memes',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. All primary multi-platform channels for Product X',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Channels to Bundle (${selectedAccountIds.length} selected):',
                      style: AppTypography.titleMedium.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (eligibleAccounts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No social channels connected for this brand yet. Connect channels first.',
                          style: AppTypography.bodySecondary,
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: eligibleAccounts.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final acc = eligibleAccounts[idx];
                            final isChecked = selectedAccountIds.contains(acc.id);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              title: Row(
                                children: [
                                  PlatformIconChip(account: acc, isCompact: true),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${acc.displayName} (${acc.handle})',
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedAccountIds.add(acc.id);
                                  } else {
                                    selectedAccountIds.remove(acc.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
              actionsBuilder: (ctx) => [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    if (existingGroup != null) {
                      widget.appState.updateGroup(
                        existingGroup.copyWith(
                          brandId: selectedBrandId,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                          accountIds: selectedAccountIds.toList(),
                        ),
                      );
                    } else {
                      widget.appState.createGroup(
                        brandId: selectedBrandId,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                        accountIds: selectedAccountIds.toList(),
                      );
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "${nameCtrl.text.trim()}" saved!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(existingGroup == null ? 'Create Group' : 'Save Changes'),
                ),
              ],
            );
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.registryTitle),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.border,
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
                  '#${brand.slug} • ${allAccounts.length} channel${allAccounts.length == 1 ? '' : 's'} connected',
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
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentLight : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
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
                  'assets/logo/no5ocial_N.png',
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
                            content: Text('Demo sample brands purged from SQLite database.'),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              brand.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '#${brand.slug}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
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
                          Text(
                            '${brandAccounts.length} connected channel${brandAccounts.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: brandAccounts.isNotEmpty ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (brand.websiteUrl != null && brand.websiteUrl!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(width: 8),
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

                return InkWell(
                  onTap: () => _showAccountDetails(context, acc, brand),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        PlatformIconChip(account: acc, isCompact: false),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      acc.displayName.isNotEmpty ? acc.displayName : acc.handle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildConnectionChip(acc.connectionStatus, acc.isManualOnly),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: accountGroup != null
                                          ? AppColors.accent.withValues(alpha: 0.12)
                                          : AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: accountGroup != null
                                            ? AppColors.accent.withValues(alpha: 0.3)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          accountGroup != null ? Icons.folder_special : Icons.hub_outlined,
                                          size: 10,
                                          color: accountGroup != null ? AppColors.accent : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          accountGroup != null ? 'Group: ${accountGroup.name}' : 'Standalone',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: accountGroup != null ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${acc.subtypeLabel} • ${acc.handle.startsWith('@') ? acc.handle : "@${acc.handle}"}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
        child: Text(
          'Manual',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      );
    }

    final isConnected = status == ConnectionStatus.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isConnected
              ? AppColors.successBorder
              : AppColors.warningBorder,
        ),
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
