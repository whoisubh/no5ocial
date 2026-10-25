import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanySettingsScreen extends StatefulWidget {
  final AppState appState;

  const CompanySettingsScreen({super.key, required this.appState});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descController;
  late TextEditingController _websiteController;

  String? _selectedIndustry;
  String? _selectedCompanySize;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSlugCustomized = false;

  static const List<String> _industryOptions = [
    'Technology & Software',
    'Media & Publishing',
    'E-Commerce & Retail',
    'Marketing & Agency',
    'Creator & Influencer',
    'Education & Learning',
    'Finance & Fintech',
    'Healthcare & Wellness',
    'Entertainment & Gaming',
    'Non-Profit & Community',
    'Other',
  ];

  static const List<String> _companySizeOptions = [
    'Solo Creator (1 person)',
    '2-10 (Early Startup)',
    '11-50 (Small Business)',
    '51-200 (Mid-Market)',
    '201-500 (Enterprise)',
    '500+ (Large Enterprise)',
  ];

  @override
  void initState() {
    super.initState();
    final brand = widget.appState.primaryBrand;
    _nameController = TextEditingController(text: brand?.name ?? '');
    _slugController = TextEditingController(text: brand?.slug ?? '');
    _descController = TextEditingController(text: brand?.description ?? '');
    _websiteController = TextEditingController(text: brand?.websiteUrl ?? '');
    _selectedIndustry = brand?.industry;
    _selectedCompanySize = brand?.companySize;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _resetForm(Brand? brand) {
    setState(() {
      _nameController.text = brand?.name ?? '';
      _slugController.text = brand?.slug ?? '';
      _descController.text = brand?.description ?? '';
      _websiteController.text = brand?.websiteUrl ?? '';
      _selectedIndustry = brand?.industry;
      _selectedCompanySize = brand?.companySize;
      _isSlugCustomized = false;
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentBrand = widget.appState.primaryBrand;
      final cleanName = InputValidator.sanitize(_nameController.text.trim());
      final cleanSlug = InputValidator.sanitize(_slugController.text.trim().toLowerCase());
      final cleanDesc = _descController.text.trim().isNotEmpty
          ? InputValidator.sanitize(_descController.text.trim())
          : null;
      final cleanUrl = _websiteController.text.trim().isNotEmpty
          ? InputValidator.sanitize(_websiteController.text.trim())
          : null;

      if (currentBrand != null) {
        final updatedBrand = currentBrand.copyWith(
          name: cleanName,
          slug: cleanSlug,
          description: cleanDesc,
          websiteUrl: cleanUrl,
          industry: _selectedIndustry,
          companySize: _selectedCompanySize,
        );
        widget.appState.updateBrand(updatedBrand);
      } else {
        widget.appState.createBrand(
          name: cleanName,
          slug: cleanSlug,
          description: cleanDesc,
          websiteUrl: cleanUrl,
          industry: _selectedIndustry,
          companySize: _selectedCompanySize,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update company: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openWebsite(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;
    final uri = Uri.tryParse(clean.startsWith('http://') || clean.startsWith('https://') ? clean : 'https://$clean');
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $clean'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final brand = widget.appState.primaryBrand;
        final isDark = widget.appState.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF161E2E) : AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Settings',
              onPressed: () {
                if (_isEditing) {
                  _resetForm(brand);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              _isEditing ? 'Edit Company Profile' : 'Company & Organization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            actions: [
              if (!_isEditing && brand != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _nameController.text = brand.name;
                      _slugController.text = brand.slug;
                      _descController.text = brand.description ?? '';
                      _websiteController.text = brand.websiteUrl ?? '';
                      _selectedIndustry = brand.industry;
                      _selectedCompanySize = brand.companySize;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (_isEditing)
                TextButton(
                  onPressed: () => _resetForm(brand),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  if (_isEditing)
                    _buildEditForm(brand, isDark)
                  else
                    _buildViewProfile(brand, isDark, isDesktop),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewProfile(Brand? brand, bool isDark, bool isDesktop) {
    final companyName = brand?.name.isNotEmpty == true ? brand!.name : 'Your Company';
    final companySlug = brand?.slug.isNotEmpty == true ? brand!.slug : 'workspace';
    final description = brand?.description;
    final website = brand?.websiteUrl;
    final industry = brand?.industry ?? 'Technology & Software';
    final companySize = brand?.companySize ?? 'Solo Workspace';
    final channelCount = widget.appState.accounts.length;
    final groupCount = widget.appState.groups.length;

    final initials = companyName.isNotEmpty
        ? (companyName.length >= 2 ? companyName.substring(0, 2).toUpperCase() : companyName[0].toUpperCase())
        : 'CO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Brand Profile Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo / Initials Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.glowShadow,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.successBorder),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'Primary Workspace',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _copyToClipboard('@$companySlug', 'Company handle'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '@$companySlug',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy, size: 12, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Badges & Quick Attributes
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildProfileChip(
                    icon: Icons.category_outlined,
                    label: industry,
                    isDark: isDark,
                  ),
                  _buildProfileChip(
                    icon: Icons.people_outline,
                    label: companySize,
                    isDark: isDark,
                  ),
                  if (website != null && website.isNotEmpty)
                    InkWell(
                      onTap: () => _openWebsite(website),
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProfileChip(
                        icon: Icons.language,
                        label: website.replaceFirst(RegExp(r'^https?://'), ''),
                        isLink: true,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),
              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      if (brand != null) {
                        _nameController.text = brand.name;
                        _slugController.text = brand.slug;
                        _descController.text = brand.description ?? '';
                        _websiteController.text = brand.websiteUrl ?? '';
                        _selectedIndustry = brand.industry;
                        _selectedCompanySize = brand.companySize;
                      }
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Edit Company Details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Workspace Statistics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 460;
            final cardChannels = _buildStatCard(
              title: 'Connected Channels',
              value: '$channelCount',
              subtitle: channelCount == 1 ? '1 active social channel' : '$channelCount active social channels',
              icon: Icons.hub_outlined,
              color: const Color(0xFF6366F1),
              isDark: isDark,
            );
            final cardGroups = _buildStatCard(
              title: 'Channel Groups',
              value: '$groupCount',
              subtitle: groupCount == 1 ? '1 broadcast group' : '$groupCount broadcast groups',
              icon: Icons.folder_special_outlined,
              color: const Color(0xFF10B981),
              isDark: isDark,
            );

            if (isNarrow) {
              return Column(
                children: [
                  cardChannels,
                  const SizedBox(height: 10),
                  cardGroups,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cardChannels),
                const SizedBox(width: 12),
                Expanded(child: cardGroups),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Detailed Metadata Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workspace Identity Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _buildDetailItem(
                label: 'Internal Brand ID',
                value: brand?.id ?? 'default_brand',
                isMonospace: true,
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 15),
                  tooltip: 'Copy ID',
                  onPressed: () => _copyToClipboard(brand?.id ?? 'default_brand', 'Brand ID'),
                ),
              ),
              const Divider(height: 20),
              _buildDetailItem(
                label: 'Created Date',
                value: brand != null
                    ? '${DateFormatter.formatDate(brand.createdAtUtc)} (${DateFormatter.formatRelative(brand.createdAtUtc)})'
                    : 'Initial Setup',
              ),
              const Divider(height: 20),
              _buildDetailItem(
                label: 'Publishing Scope',
                value: 'Universal workspace publishing enabled for all connected channels',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Brand? brand, bool isDark) {
    final existingSlugs = widget.appState.brands
        .where((b) => b.id != brand?.id)
        .map((b) => b.slug)
        .toList();

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Company Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Update your organization name, slug, website, and industry details.',
                        style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Company Name
            const Text(
              'Company / Organization Name *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Shaadow or Acme Corp',
                prefixIcon: Icon(Icons.apartment_rounded, size: 20),
              ),
              validator: InputValidator.validateBrandName,
              onChanged: (val) {
                if (!_isSlugCustomized) {
                  final newSlug = InputValidator.generateDynamicSlug(
                    name: val,
                    existingSlugs: existingSlugs,
                  );
                  _slugController.text = newSlug;
                }
              },
            ),
            const SizedBox(height: 18),

            // Company Slug
            const Text(
              'Workspace Slug / Handle *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                hintText: 'e.g. shaadow',
                prefixText: '@',
                prefixIcon: Icon(Icons.alternate_email, size: 18),
                helperText: 'Lowercase letters, numbers, and hyphens only.',
              ),
              validator: (val) => InputValidator.validateBrandSlug(val, existingSlugs: existingSlugs),
              onChanged: (_) => _isSlugCustomized = true,
            ),
            const SizedBox(height: 18),

            // Tagline / Description
            const Text(
              'Description / Tagline',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Brief summary of what your company or organization does...',
              ),
              validator: InputValidator.validateDescription,
            ),
            const SizedBox(height: 10),

            // Official Website URL
            const Text(
              'Official Website URL',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.language, size: 18),
              ),
              validator: InputValidator.validateWebsiteUrl,
            ),
            const SizedBox(height: 18),

            // Industry & Company Size (Responsive with isExpanded to prevent overflow)
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 500;

                final industryField = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Industry',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedIndustry,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, size: 18),
                      ),
                      hint: const Text('Select Industry', overflow: TextOverflow.ellipsis),
                      items: _industryOptions.map((ind) {
                        return DropdownMenuItem(
                          value: ind,
                          child: Text(ind, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedIndustry = val),
                    ),
                  ],
                );

                final companySizeField = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Size',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedCompanySize,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.people_outline, size: 18),
                      ),
                      hint: const Text('Select Team Size', overflow: TextOverflow.ellipsis),
                      items: _companySizeOptions.map((sz) {
                        return DropdownMenuItem(
                          value: sz,
                          child: Text(sz, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCompanySize = val),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    children: [
                      industryField,
                      const SizedBox(height: 18),
                      companySizeField,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: industryField),
                    const SizedBox(width: 14),
                    Expanded(child: companySizeField),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : () => _resetForm(brand),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isSaving ? 'Saving Changes...' : 'Save Company Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip({
    required IconData icon,
    required String label,
    bool isLink = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLink
              ? AppColors.accent.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : AppColors.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isLink ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLink ? AppColors.accent : (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
          ),
          if (isLink) ...[
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 11, color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    bool isMonospace = false,
    Widget? trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: isMonospace ? 'monospace' : null,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: isMonospace ? 'monospace' : null,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        );
      },
    );
  }
}
