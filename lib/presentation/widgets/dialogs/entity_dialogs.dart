import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/models/platform_target_config.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';
import 'package:no5ocial/core/services/youtube_service.dart';
import 'package:no5ocial/core/services/instagram_service.dart';
import 'package:no5ocial/core/services/linkedin_service.dart';
import 'package:no5ocial/core/services/x_service.dart';
import 'package:no5ocial/core/services/threads_service.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';

class EntityDialogs {
  /// Adaptive container: renders a native Bottom Sheet on mobile and an AlertDialog on desktop.
  static void _showAdaptiveModal(
    BuildContext context, {
    required Widget title,
    required Widget Function(BuildContext ctx, StateSetter setModalState, bool isMobile) contentBuilder,
    required List<Widget> Function(BuildContext ctx, StateSetter setModalState, bool isMobile) actionsBuilder,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 860 ||
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetCtx) {
          final bottomInset = MediaQuery.of(bottomSheetCtx).viewInsets.bottom;
          final availableHeight = MediaQuery.of(bottomSheetCtx).size.height - bottomInset;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: availableHeight * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: StatefulBuilder(
                  builder: (ctx, setModalState) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Native Drag Handle
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Header
                          Row(
                            children: [
                              Expanded(child: title),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // Content
                          contentBuilder(ctx, setModalState, true),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actionsBuilder(ctx, setModalState, true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setModalState) => AlertDialog(
            title: title,
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: contentBuilder(ctx, setModalState, false),
              ),
            ),
            actions: actionsBuilder(ctx, setModalState, false),
          ),
        ),
      );
    }
  }

  // --- Modal: Register Company (with Local-Only Personalization Survey) ---
  static void showRegisterCompanyDialog(
    BuildContext context,
    AppState appState, {
    Brand? existingBrand,
    void Function(Brand brand)? onSaved,
  }) {
    final nameCtrl = TextEditingController(text: existingBrand?.name ?? '');
    final descCtrl = TextEditingController(text: existingBrand?.description ?? '');
    final urlCtrl = TextEditingController(text: existingBrand?.websiteUrl ?? '');

    String? selectedCompanySize = existingBrand?.companySize;
    String? selectedIndustry = existingBrand?.industry;
    String? selectedFoundUsVia = existingBrand?.foundUsVia;

    final companySizeOptions = [
      '1 (Solo creator)',
      '2-10 team members',
      '11-50 employees',
      '51-200 employees',
      '201+ enterprise',
    ];

    final industryOptions = [
      'Technology / SaaS',
      'Creator / Media / YouTube',
      'E-Commerce / Retail',
      'Agency / Marketing',
      'Education / Non-profit',
      'Other',
    ];

    final foundUsOptions = [
      'Google / Web Search',
      'X (Twitter)',
      'YouTube',
      'LinkedIn',
      'Friend / Colleague Referral',
      'Other',
    ];

    _showAdaptiveModal(
      context,
      title: Row(
        children: [
          const Icon(Icons.business_outlined, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(existingBrand == null ? 'Register Company' : 'Edit Company Details'),
        ],
      ),
      contentBuilder: (ctx, setDialogState, isMobile) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existingBrand == null
                  ? 'Add a company workspace to organize multi-platform accounts and content pipelines.'
                  : 'Update your registered company identity and workspace details.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'e.g. Acme Corporation or Nova Media',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Website / Profile URL (Optional)',
                hintText: 'https://example.com',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the brand or publishing focus',
              ),
            ),

            const SizedBox(height: 20),
            // Privacy Guaranteed Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Personalization Survey — 100% On-Device & Zero Third-Party Leaks',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Survey Field 1: Company Size (Optional)
            DropdownButtonFormField<String>(
              initialValue: selectedCompanySize,
              decoration: const InputDecoration(
                labelText: 'Company Size (Optional)',
                hintText: 'Select company size',
              ),
              items: companySizeOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) => setDialogState(() => selectedCompanySize = val),
            ),
            const SizedBox(height: 14),

            // Survey Field 2: Industry (Optional)
            DropdownButtonFormField<String>(
              initialValue: selectedIndustry,
              decoration: const InputDecoration(
                labelText: 'Industry / Domain (Optional)',
                hintText: 'Select industry',
              ),
              items: industryOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) => setDialogState(() => selectedIndustry = val),
            ),
            const SizedBox(height: 14),

            // Survey Field 3: Found Us Via (Optional)
            DropdownButtonFormField<String>(
              initialValue: selectedFoundUsVia,
              decoration: const InputDecoration(
                labelText: 'How did you find no5ocial? (Optional)',
                hintText: 'Select source',
              ),
              items: foundUsOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) => setDialogState(() => selectedFoundUsVia = val),
            ),
          ],
        );
      },
      actionsBuilder: (ctx, setDialogState, isMobile) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            Brand savedBrand;
            if (existingBrand != null) {
              savedBrand = existingBrand.copyWith(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                websiteUrl: urlCtrl.text.trim().isNotEmpty
                    ? urlCtrl.text.trim()
                    : null,
                companySize: selectedCompanySize,
                industry: selectedIndustry,
                foundUsVia: selectedFoundUsVia,
              );
              appState.updateBrand(savedBrand);
            } else {
              savedBrand = appState.createBrand(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                websiteUrl: urlCtrl.text.trim().isNotEmpty
                    ? urlCtrl.text.trim()
                    : null,
                companySize: selectedCompanySize,
                industry: selectedIndustry,
                foundUsVia: selectedFoundUsVia,
              );
            }
            Navigator.of(ctx).pop();
            onSaved?.call(savedBrand);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Company "${nameCtrl.text.trim()}" ${existingBrand == null ? 'registered' : 'updated'} successfully.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: Text(existingBrand == null ? 'Register Company' : 'Save Changes'),
        ),
      ],
    );
  }

  // --- Modal: Connect Social Channel ---
  static void showConnectChannelDialog(
    BuildContext context,
    AppState appState, {
    String? preselectedBrandId,
    void Function(SocialAccount account)? onSaved,
  }) {
    final brands = appState.brands;
    if (brands.isEmpty) {
      showRegisterCompanyDialog(context, appState, onSaved: (newBrand) {
        showConnectChannelDialog(context, appState, preselectedBrandId: newBrand.id, onSaved: onSaved);
      });
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
    String? verifiedToken;
    String selectedGroupValue = 'standalone';

    _showAdaptiveModal(
      context,
      title: const Row(
        children: [
          Icon(Icons.add_link, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Connect Channel / Destination'),
        ],
      ),
      contentBuilder: (ctx, setDialogState, isMobile) {
        final availableGroups = appState.groups
            .where((g) => g.brandId == selectedBrandId)
            .toList();
        final availableSubtypes = PlatformConfigRegistry.getSubtypes(selectedPlatform);

        final companyDropdown = DropdownButtonFormField<String>(
          initialValue: selectedBrandId,
          decoration: const InputDecoration(
            labelText: 'Company',
            isDense: true,
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
        );

        final platformDropdown = DropdownButtonFormField<PlatformType>(
          initialValue: selectedPlatform,
          decoration: const InputDecoration(
            labelText: 'Platform',
            isDense: true,
          ),
          items: PlatformType.values.map((p) => DropdownMenuItem(
            value: p,
            child: Row(
              children: [
                PlatformLogo(platform: p, size: 16),
                const SizedBox(width: 8),
                Text(p.displayName, overflow: TextOverflow.ellipsis),
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
        );

        final subtypeDropdown = DropdownButtonFormField<PlatformSubtype>(
          initialValue: selectedSubtype,
          decoration: const InputDecoration(
            labelText: 'Destination Sub-type *',
            isDense: true,
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
                  size: 15,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(st.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
        );

        final integrateButton = SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isIntegrated
                ? null
                : () async {
                    await _openPlatformAuthModal(
                      context: ctx,
                      platform: selectedPlatform,
                      subtype: selectedSubtype,
                      brandId: selectedBrandId,
                      onSuccess: (name, handle, id, [token]) {
                        setDialogState(() {
                          isIntegrated = true;
                          externalAccountId = id;
                          apiVerifiedTitle = name;
                          apiVerifiedHandle = handle;
                          verifiedToken = token;
                        });
                      },
                    );
                  },
            icon: Icon(
              isIntegrated ? Icons.check_circle : Icons.sync_lock_outlined,
              size: 16,
            ),
            label: Text(isIntegrated ? 'Verified' : 'Authenticate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isIntegrated ? AppColors.success : AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        );

        final hasMultipleSubtypes = availableSubtypes.length > 1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive layout: Stack on mobile, grid row on desktop
            if (isMobile) ...[
              companyDropdown,
              const SizedBox(height: 10),
              platformDropdown,
              if (hasMultipleSubtypes) ...[
                const SizedBox(height: 10),
                subtypeDropdown,
              ],
              const SizedBox(height: 10),
              integrateButton,
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 3, child: companyDropdown),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: platformDropdown),
                  if (hasMultipleSubtypes) ...[
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: subtypeDropdown),
                  ],
                  const SizedBox(width: 8),
                  integrateButton,
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Linking Conditions & Policy Requirements Card
            Container(
              padding: const EdgeInsets.all(10),
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
                        size: 14,
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedSubtype.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  ...selectedSubtype.linkingConditions.map((cond) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 10.5, color: AppColors.accent, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            cond,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content Formats to Publish ("What You Will Post")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What will you post on this channel?',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: PlatformConfigRegistry.formatLabels.entries.map((entry) {
                    final isSupported = selectedSubtype.supportedFormats.contains(entry.key);
                    final isSelected = selectedFormats.contains(entry.key);
                    final icon = PlatformConfigRegistry.formatIcons[entry.key];

                    return FilterChip(
                      avatar: icon != null
                          ? Icon(
                              icon,
                              size: 13,
                              color: isSupported
                                  ? (isSelected ? Colors.white : AppColors.textSecondary)
                                  : AppColors.textMuted,
                            )
                          : null,
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 10.5,
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
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),


            if (isIntegrated) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OAuth Verified: ${apiVerifiedTitle ?? selectedSubtype.name}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          Text(
                            'Account ID: ${externalAccountId ?? 'ext_oauth'} • Handle: ${apiVerifiedHandle ?? '@official'}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: nicknameCtrl,
              decoration: InputDecoration(
                labelText: 'Nickname (Optional)',
                hintText: apiVerifiedTitle ?? 'Defaults to ${selectedSubtype.name}',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedGroupValue,
              decoration: const InputDecoration(
                labelText: 'Product / Campaign Group (Optional)',
                prefixIcon: Icon(Icons.folder_outlined, size: 16),
                isDense: true,
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
                          Text('Group: ${g.name} (${g.accountIds.length} profiles)'),
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
                if (val != null) {
                  setDialogState(() => selectedGroupValue = val);
                }
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
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        );
      },
      actionsBuilder: (ctx, setDialogState, isMobile) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: !isIntegrated
              ? null
              : () {
                  final handle = apiVerifiedHandle ??
                      '@${(nicknameCtrl.text.trim().isNotEmpty ? nicknameCtrl.text.trim() : selectedSubtype.name).replaceAll(RegExp(r'\s+'), '').toLowerCase()}';

                  final displayName = nicknameCtrl.text.trim().isNotEmpty
                      ? nicknameCtrl.text.trim()
                      : (apiVerifiedTitle ?? '${selectedPlatform.displayName} ${selectedSubtype.name}');

                  final finalCapabilities = [
                    ...selectedFormats,
                    'subtype:${selectedSubtype.id}',
                    if (selectedPlatform == PlatformType.youtube) 'privacy:$selectedPrivacy',
                  ];

                  final accountScopes = List<String>.from(selectedSubtype.scopes);
                  if (verifiedToken != null && verifiedToken!.isNotEmpty) {
                    accountScopes.add('token:$verifiedToken');
                  }

                  final newAccount = appState.connectAccount(
                    brandId: selectedBrandId,
                    platform: selectedPlatform,
                    displayName: displayName,
                    handle: handle,
                    externalAccountId: externalAccountId ?? 'ext_${selectedSubtype.id}',
                    isManualOnly: false,
                    targetGroupId: selectedGroupValue != 'standalone' && selectedGroupValue != '__new__'
                        ? selectedGroupValue
                        : null,
                    newGroupName: selectedGroupValue == '__new__'
                        ? (newGroupNameCtrl.text.trim().isNotEmpty
                            ? newGroupNameCtrl.text.trim()
                            : '$displayName Group')
                        : null,
                    capabilities: finalCapabilities,
                    scopes: accountScopes,
                  );

                  Navigator.of(ctx).pop();
                  onSaved?.call(newAccount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Destination "${newAccount.displayName}" connected successfully.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Destination'),
        ),
      ],
    );
  }

  // --- Modal: Create Channel Group ---
  static void showCreateGroupDialog(
    BuildContext context,
    AppState appState, {
    String? preselectedBrandId,
    ChannelGroup? existingGroup,
    void Function(ChannelGroup group)? onSaved,
  }) {
    final brands = appState.brands;
    if (brands.isEmpty) {
      showRegisterCompanyDialog(context, appState);
      return;
    }

    String selectedBrandId = existingGroup?.brandId ?? preselectedBrandId ?? brands.first.id;
    final nameCtrl = TextEditingController(text: existingGroup?.name ?? '');
    final descCtrl = TextEditingController(text: existingGroup?.description ?? '');
    final Set<String> selectedAccountIds = Set.from(existingGroup?.accountIds ?? []);

    _showAdaptiveModal(
      context,
      title: Row(
        children: [
          const Icon(Icons.folder_rounded, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(existingGroup == null ? 'Create Channel Group' : 'Edit Channel Group'),
        ],
      ),
      contentBuilder: (ctx, setDialogState, isMobile) {
        final eligibleAccounts = appState.accounts
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
              decoration: const InputDecoration(
                labelText: 'Company / Brand *',
              ),
              items: brands.map((b) => DropdownMenuItem(
                value: b.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.business_rounded, size: 13, color: AppColors.accent),
                    ),
                    const SizedBox(width: 8),
                    Text(b.name, overflow: TextOverflow.ellipsis),
                  ],
                ),
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
              'Bundle Connected Channels (${selectedAccountIds.length} selected):',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (eligibleAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No connected channels found for this company. Connect channels first or select another company.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          PlatformLogo(platform: acc.platform, size: 16),
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
      actionsBuilder: (ctx, setDialogState, isMobile) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ChannelGroup savedGroup;
            if (existingGroup != null) {
              savedGroup = existingGroup.copyWith(
                brandId: selectedBrandId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                accountIds: selectedAccountIds.toList(),
              );
              appState.updateGroup(savedGroup);
            } else {
              savedGroup = appState.createGroup(
                brandId: selectedBrandId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                accountIds: selectedAccountIds.toList(),
              );
            }
            Navigator.of(ctx).pop();
            onSaved?.call(savedGroup);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Group "${savedGroup.name}" saved successfully.'),
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

  // --- Modal Dialog: Platform Integration ---
  static Future<void> _openPlatformAuthModal({
    required BuildContext context,
    required PlatformType platform,
    required PlatformSubtype subtype,
    required String brandId,
    required void Function(String name, String handle, String id, [String? token]) onSuccess,
  }) async {
    final tokenCtrl = TextEditingController();
    bool isSubmitting = false;

    _showAdaptiveModal(
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
      contentBuilder: (authCtx, setAuthState, isMobile) {
        String tokenLabel = 'Access Token / Bearer Token';
        String tokenHint = 'Paste official OAuth token';
        String apiDescription = '';

        switch (platform) {
          case PlatformType.youtube:
            tokenLabel = 'Google OAuth Access Token';
            tokenHint = 'Paste Google OAuth token';
            apiDescription = 'Uses YouTube Data API v3 (GET /youtube/v3/channels?mine=true) to upload to standard channel.';
            break;
          case PlatformType.instagram:
            tokenLabel = 'Meta / Instagram Graph API Access Token';
            tokenHint = 'Paste Instagram Graph token';
            apiDescription = 'Uses Meta Graph API (GET /me?fields=id,username) to publish to Instagram Professional account.';
            break;
          case PlatformType.linkedin:
            tokenLabel = 'LinkedIn Member / Page Access Token';
            tokenHint = 'Paste LinkedIn token';
            apiDescription = 'Uses LinkedIn API to publish to verified member profile or company page.';
            break;
          case PlatformType.x:
            tokenLabel = 'X / Twitter API v2 Bearer Token';
            tokenHint = 'Paste OAuth 2.0 User Access Token';
            apiDescription = 'Uses Twitter API v2 (GET /2/users/me) to verify handle.';
            break;
          case PlatformType.threads:
            tokenLabel = 'Threads API Bearer Token';
            tokenHint = 'Paste Threads API Access Token';
            apiDescription = 'Uses Meta Threads Graph API (GET /v1.0/me?fields=id,username) to publish threads and media.';
            break;
          default:
            apiDescription = 'Official API verification for ${platform.displayName}.';
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
                          final launched = await YouTubeService.instance.launchOAuthConnection(
                            brandId: brandId,
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open browser for YouTube OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
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
                          final launched = await InstagramService.instance.launchOAuthConnection(
                            brandId: brandId,
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open browser for Instagram OAuth.'),
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
                          if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
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
                          final isPage = subtype.id == 'linkedin_page';
                          final launched = await LinkedInService.instance.launchOAuthConnection(
                            brandId: brandId,
                            accountType: isPage ? 'page' : 'personal',
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open browser for LinkedIn OAuth.'),
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
                          if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
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
            ] else if (platform == PlatformType.x) ...[
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final isPremium = subtype.id == 'x_premium';
                          final launched = await XService.instance.launchOAuthConnection(
                            brandId: brandId,
                            accountType: isPremium ? 'premium' : 'standard',
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open browser for X (Twitter) OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              SnackBar(
                                content: Text('Opening X OAuth in browser to authorize ${isPremium ? "Premium Profile" : "Standard Profile"}...'),
                                backgroundColor: AppColors.x,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: Text(subtype.id == 'x_premium'
                    ? 'Sign in with X (Premium / Verified)'
                    : 'Sign in with X (Twitter OAuth 2.0)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.x,
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
                    child: Text('OR USE API V2 BEARER TOKEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
            ] else if (platform == PlatformType.threads) ...[
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setAuthState(() => isSubmitting = true);
                        try {
                          final launched = await ThreadsService.instance.launchOAuthConnection(
                            brandId: brandId,
                            returnUrl: '/accounts',
                          );
                          if (!launched && authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open browser for Threads OAuth.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Opening Threads OAuth in browser...'),
                                backgroundColor: AppColors.threads,
                              ),
                            );
                          }
                        } catch (e, st) {
                          if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
                        } finally {
                          if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                        }
                      },
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('Sign in with Threads (Meta OAuth)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.threads,
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
                    child: Text('OR USE THREADS ACCESS TOKEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
          ],
        );
      },
      actionsBuilder: (authCtx, setAuthState, isMobile) => [
        TextButton(
          onPressed: () => Navigator.of(authCtx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isSubmitting
              ? null
              : () async {
                  final token = tokenCtrl.text.trim();
                  if (token.isEmpty) return;
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
                      case PlatformType.instagram:
                        final info = await InstagramService.instance.fetchProfile(accessToken: token);
                        name = info.name;
                        handle = info.handle;
                        id = info.id;
                        break;
                      case PlatformType.linkedin:
                        final info = await LinkedInService.instance.fetchMemberProfile(accessToken: token);
                        name = info.name;
                        handle = info.handle;
                        id = info.id;
                        break;
                      case PlatformType.x:
                        final info = await XService.instance.fetchUserProfile(accessToken: token);
                        name = info.name;
                        handle = info.handle;
                        id = info.id;
                        break;
                      case PlatformType.threads:
                        final info = await ThreadsService.instance.fetchProfile(accessToken: token);
                        name = info.name;
                        handle = info.handle;
                        id = info.id;
                        break;
                      default:
                        throw Exception('API token verification not supported for ${platform.displayName}.');
                    }

                    onSuccess(name, handle, id, token);
                    if (authCtx.mounted) Navigator.of(authCtx).pop();
                  } catch (e, st) {
                    if (authCtx.mounted) AppErrorHandler.showError(authCtx, e, stackTrace: st);
                  } finally {
                    if (authCtx.mounted) setAuthState(() => isSubmitting = false);
                  }
                },
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
    );
  }
}
