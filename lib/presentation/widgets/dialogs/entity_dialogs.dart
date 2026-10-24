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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : AppColors.surface;
    final handleColor = isDark ? const Color(0xFF334155) : AppColors.border;

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
            child: Material(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: availableHeight * 0.88,
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
                                color: handleColor,
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
            // Organization details header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune_outlined, size: 14, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Organization Details (Optional)',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apiVerifiedTitle ?? selectedSubtype.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            '${apiVerifiedHandle ?? '@official'} · Connected',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    // Null filter means show all workspace accounts
    String? filterBrandId;

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
        final allAccounts = appState.accounts;
        final displayedAccounts = filterBrandId == null
            ? allAccounts
            : allAccounts.where((a) => a.brandId == filterBrandId).toList();

        final allFilteredSelected = displayedAccounts.isNotEmpty &&
            displayedAccounts.every((a) => selectedAccountIds.contains(a.id));

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bundle multiple channels across platforms and products into a 1-tap broadcast group. When creating posts, picking this group auto-targets all assigned channels simultaneously!',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 16),

            // Owning Company / Brand
            DropdownButtonFormField<String>(
              initialValue: selectedBrandId,
              decoration: const InputDecoration(
                labelText: 'Primary Company / Workspace *',
                prefixIcon: Icon(Icons.business_rounded, size: 18),
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
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                hintText: 'e.g. Flagship Launch Squad or Multi-Network Comms',
                prefixIcon: Icon(Icons.drive_file_rename_outline, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. All primary social handles bundled for coordinated publishing',
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 18),

            // Channel Assignment Header with Select All Action
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Assign Channels (${selectedAccountIds.length} of ${allAccounts.length} selected):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                  ),
                ),
                if (displayedAccounts.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        if (allFilteredSelected) {
                          for (final a in displayedAccounts) {
                            selectedAccountIds.remove(a.id);
                          }
                        } else {
                          for (final a in displayedAccounts) {
                            selectedAccountIds.add(a.id);
                          }
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      allFilteredSelected ? 'Clear Filtered' : 'Select All Filtered',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Brand Filter Chips
            if (brands.length > 1 && allAccounts.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All Channels (${allAccounts.length})'),
                      selected: filterBrandId == null,
                      onSelected: (val) {
                        if (val) setDialogState(() => filterBrandId = null);
                      },
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: filterBrandId == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    ...brands.map((b) {
                      final count = allAccounts.where((a) => a.brandId == b.id).length;
                      final isSelected = filterBrandId == b.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${b.name} ($count)'),
                          selected: isSelected,
                          onSelected: (val) {
                            setDialogState(() => filterBrandId = val ? b.id : null);
                          },
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Channels List
            if (allAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No connected social accounts found in this workspace yet. Connect social profiles in Accounts first!',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else if (displayedAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_off_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No connected accounts for this specific filter.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setDialogState(() => filterBrandId = null),
                      child: const Text('Show All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: displayedAccounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, idx) {
                      final acc = displayedAccounts[idx];
                      final isChecked = selectedAccountIds.contains(acc.id);
                      final accBrand = appState.getBrandById(acc.brandId);
                      final existingGroupForAcc = appState.getGroupForAccount(acc.id);
                      final isInAnotherGroup = existingGroupForAcc != null &&
                          existingGroupForAcc.id != existingGroup?.id;

                      return Material(
                        color: isChecked ? AppColors.accent.withAlpha(15) : Colors.transparent,
                        child: CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          activeColor: AppColors.accent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          secondary: PlatformLogo(platform: acc.platform, size: 22),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  acc.displayName.isNotEmpty ? acc.displayName : acc.handle,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (accBrand != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    accBrand.name,
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  acc.handle.startsWith('@') ? acc.handle : '@${acc.handle}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isInAnotherGroup) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'In: ${existingGroupForAcc.name}',
                                    style: const TextStyle(fontSize: 9.5, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
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
                        ),
                      );
                    },
                  ),
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

            // Sync account memberships: remove these accounts from other groups
            for (final accId in selectedAccountIds) {
              for (final otherG in appState.groups) {
                if (otherG.id != savedGroup.id && otherG.accountIds.contains(accId)) {
                  appState.updateGroup(otherG.copyWith(
                    accountIds: otherG.accountIds.where((id) => id != accId).toList(),
                  ));
                }
              }
            }

            Navigator.of(ctx).pop();
            onSaved?.call(savedGroup);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Channel group "${savedGroup.name}" saved with ${savedGroup.accountIds.length} assigned profiles.'),
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
    bool showAdvancedToken = false;

    _showAdaptiveModal(
      context,
      title: Row(
        children: [
          PlatformLogo(platform: platform, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect ${platform.displayName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      contentBuilder: (authCtx, setAuthState, isMobile) {
        String tokenLabel = 'Access Token';
        String tokenHint = 'Enter authorized token';
        String description = '';

        switch (platform) {
          case PlatformType.youtube:
            tokenLabel = 'Google Access Token';
            tokenHint = 'Enter Google access token';
            description = 'Connect your official YouTube channel to schedule and publish videos seamlessly.';
            break;
          case PlatformType.instagram:
            tokenLabel = 'Instagram Access Token';
            tokenHint = 'Enter Instagram access token';
            description = 'Connect your Instagram Professional or Creator account to publish photos, reels, and stories.';
            break;
          case PlatformType.linkedin:
            tokenLabel = 'LinkedIn Access Token';
            tokenHint = 'Enter LinkedIn access token';
            description = 'Connect your LinkedIn company page or member profile to share company updates and articles.';
            break;
          case PlatformType.x:
            tokenLabel = 'X Bearer Token';
            tokenHint = 'Enter X OAuth token';
            description = 'Connect your official X account to publish posts, threads, and media.';
            break;
          case PlatformType.threads:
            tokenLabel = 'Threads Access Token';
            tokenHint = 'Enter Threads access token';
            description = 'Connect your Threads account to broadcast posts and media.';
            break;
          default:
            description = 'Connect your ${platform.displayName} account to start publishing.';
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(description, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 18),

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
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
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
                                content: Text('Could not open browser for authorization.'),
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
                label: const Text('Authorize via Browser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
                                content: Text('Could not open browser for authorization.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Opening Instagram authorization in browser...'),
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
                label: const Text('Sign in with Instagram'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.instagram,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
                                content: Text('Could not open browser for authorization.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              SnackBar(
                                content: Text('Opening LinkedIn in browser to authorize ${isPage ? "Company Page" : "Personal Profile"}...'),
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
                    : 'Sign in with LinkedIn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.linkedin,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
                                content: Text('Could not open browser for authorization.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              SnackBar(
                                content: Text('Opening X in browser to authorize ${isPremium ? "Premium Account" : "Account"}...'),
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
                    : 'Sign in with X'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.x,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
                                content: Text('Could not open browser for authorization.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else if (authCtx.mounted) {
                            ScaffoldMessenger.of(authCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Opening Threads in browser...'),
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
                label: const Text('Sign in with Threads'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.threads,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            const SizedBox(height: 16),
            InkWell(
              onTap: () => setAuthState(() => showAdvancedToken = !showAdvancedToken),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showAdvancedToken ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showAdvancedToken ? 'Hide Custom Token' : 'Advanced: Custom Token',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showAdvancedToken) ...[
              const SizedBox(height: 10),
              TextField(
                controller: tokenCtrl,
                decoration: InputDecoration(
                  labelText: tokenLabel,
                  hintText: tokenHint,
                  prefixIcon: const Icon(Icons.key, size: 16),
                  isDense: true,
                ),
              ),
            ],
          ],
        );
      },
      actionsBuilder: (authCtx, setAuthState, isMobile) => [
        TextButton(
          onPressed: () => Navigator.of(authCtx).pop(),
          child: Text(showAdvancedToken ? 'Cancel' : 'Close'),
        ),
        if (showAdvancedToken)
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
                          throw Exception('Token verification not supported for ${platform.displayName}.');
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
                : const Icon(Icons.check, size: 16),
            label: Text(isSubmitting ? 'Verifying...' : 'Verify Token'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
