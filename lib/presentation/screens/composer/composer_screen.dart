import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';
import 'package:no5ocial/presentation/screens/composer/manual_handoff_sheet.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
import 'package:no5ocial/presentation/widgets/preflight_checklist_view.dart';
import 'package:no5ocial/presentation/widgets/preview_card.dart';

class ComposerScreen extends StatefulWidget {
  final AppState appState;
  final ContentPost? initialPost;

  const ComposerScreen({
    super.key,
    required this.appState,
    this.initialPost,
  });

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> with SingleTickerProviderStateMixin {
  late String _selectedBrandId;
  final _titleController = TextEditingController();
  final _sharedCaptionController = TextEditingController();
  final _campaignController = TextEditingController();
  final _tagsController = TextEditingController();

  final Set<String> _selectedAccountIds = {};
  final Set<String> _selectedMediaIds = {};
  final Map<String, TextEditingController> _overrideControllers = {};

  bool _sameCaptionEverywhere = true;
  String? _activePreviewAccountId;
  DateTime? _scheduledDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;

    if (post != null) {
      _selectedBrandId = post.brandId;
      _titleController.text = post.title;
      _sharedCaptionController.text = post.defaultCaption;
      _campaignController.text = post.campaign ?? '';
      _tagsController.text = post.tags.join(', ');
      _selectedAccountIds.addAll(post.destinationAccountIds);
      _selectedMediaIds.addAll(post.mediaAssetIds);
      _scheduledDateTime = post.scheduledAtUtc;

      final variants = widget.appState.getVariantsForPost(post.id);
      for (final v in variants) {
        if (v.hasCaptionOverride) {
          _overrideControllers[v.socialAccountId] =
              TextEditingController(text: v.captionOverride);
          _sameCaptionEverywhere = false;
        }
      }
    } else {
      final brands = widget.appState.brands;
      _selectedBrandId = brands.isNotEmpty ? brands.first.id : 'brand-shaadow';
    }

    _ensureOverrideControllers();
    if (_selectedAccountIds.isNotEmpty) {
      _activePreviewAccountId = _selectedAccountIds.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sharedCaptionController.dispose();
    _campaignController.dispose();
    _tagsController.dispose();
    for (final c in _overrideControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureOverrideControllers() {
    for (final accId in _selectedAccountIds) {
      if (!_overrideControllers.containsKey(accId)) {
        _overrideControllers[accId] = TextEditingController(
          text: _sharedCaptionController.text,
        );
      }
    }
  }

  void _toggleAccountSelection(String accountId) {
    setState(() {
      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
        if (_activePreviewAccountId == accountId) {
          _activePreviewAccountId = _selectedAccountIds.firstOrNull;
        }
      } else {
        _selectedAccountIds.add(accountId);
        if (!_overrideControllers.containsKey(accountId)) {
          _overrideControllers[accountId] = TextEditingController(
            text: _sharedCaptionController.text,
          );
        }
        _activePreviewAccountId ??= accountId;
      }
    });
  }

  void _toggleMediaSelection(String mediaId) {
    setState(() {
      if (_selectedMediaIds.contains(mediaId)) {
        _selectedMediaIds.remove(mediaId);
      } else {
        _selectedMediaIds.add(mediaId);
      }
    });
  }

  List<MediaAsset> get _attachedMediaAssets {
    return _selectedMediaIds
        .map((id) => widget.appState.getMediaAssetById(id))
        .whereType<MediaAsset>()
        .toList();
  }

  String _getCaptionForAccount(String accountId) {
    if (_sameCaptionEverywhere) {
      return _sharedCaptionController.text;
    }
    return _overrideControllers[accountId]?.text ?? _sharedCaptionController.text;
  }

  PreflightResult _getPreflightForAccount(SocialAccount account) {
    final effectiveCaption = _getCaptionForAccount(account.id);
    final variant = PostVariant(
      id: 'preview_variant',
      contentPostId: widget.initialPost?.id ?? 'temp_post',
      socialAccountId: account.id,
      captionOverride: _sameCaptionEverywhere ? null : effectiveCaption,
      mediaAssetIds: _selectedMediaIds.toList(),
    );

    final post = ContentPost(
      id: widget.initialPost?.id ?? 'temp_post',
      brandId: _selectedBrandId,
      title: _titleController.text,
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      createdAtUtc: DateTime.now().toUtc(),
      updatedAtUtc: DateTime.now().toUtc(),
    );

    return PreflightValidator.validate(
      post: post,
      variant: variant,
      account: account,
      postBrand: widget.appState.getBrandById(_selectedBrandId),
      accountBrand: widget.appState.getBrandById(account.brandId),
      attachedMedia: _attachedMediaAssets,
    );
  }

  void _saveDraft() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a post title before saving draft.')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final overrides = <String, String>{};
    if (!_sameCaptionEverywhere) {
      for (final entry in _overrideControllers.entries) {
        if (_selectedAccountIds.contains(entry.key)) {
          overrides[entry.key] = entry.value.text;
        }
      }
    }

    widget.appState.saveDraft(
      postId: widget.initialPost?.id,
      brandId: _selectedBrandId,
      title: _titleController.text.trim(),
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      tags: tags,
      campaign: _campaignController.text.trim().isNotEmpty
          ? _campaignController.text.trim()
          : null,
      scheduledAtUtc: _scheduledDateTime,
      captionOverridesByAccount: overrides,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft "${_titleController.text.trim()}" saved.'),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Future<void> _publishNow() async {
    if (_selectedAccountIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one destination account.')),
      );
      return;
    }

    // Check for any blockers across selected accounts
    final blockers = <String>[];
    for (final accId in _selectedAccountIds) {
      final acc = widget.appState.getAccountById(accId);
      if (acc != null) {
        final preflight = _getPreflightForAccount(acc);
        if (!preflight.isValid) {
          blockers.add('${acc.handle}: ${preflight.blockers.first.message}');
        }
      }
    }

    if (blockers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Validation Blockers Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blockers
                .map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $b', style: AppTypography.bodyMedium),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close & Fix'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation dialog per DESIGN.md
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Multi-Destination Publish'),
        content: Text(
          'Are you ready to publish to ${_selectedAccountIds.length} destination account(s)? '
          'Each account will be published independently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
            child: const Text('Confirm Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final overrides = <String, String>{};
    if (!_sameCaptionEverywhere) {
      for (final entry in _overrideControllers.entries) {
        if (_selectedAccountIds.contains(entry.key)) {
          overrides[entry.key] = entry.value.text;
        }
      }
    }

    final post = widget.appState.saveDraft(
      postId: widget.initialPost?.id,
      brandId: _selectedBrandId,
      title: _titleController.text.trim().isEmpty ? 'Untitled Post' : _titleController.text.trim(),
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      tags: tags,
      campaign: _campaignController.text.trim().isNotEmpty
          ? _campaignController.text.trim()
          : null,
      captionOverridesByAccount: overrides,
    );

    await widget.appState.publishOrQueuePost(
      post: post,
      captionOverridesByAccount: overrides,
      isScheduled: false,
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Publishing jobs processed for ${post.destinationAccountIds.length} destinations.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openManualHandoffForAccount(SocialAccount account) {
    final effectiveCaption = _getCaptionForAccount(account.id);
    final variant = PostVariant(
      id: 'variant_${account.id}',
      contentPostId: widget.initialPost?.id ?? 'temp_post',
      socialAccountId: account.id,
      captionOverride: _sameCaptionEverywhere ? null : effectiveCaption,
      mediaAssetIds: _selectedMediaIds.toList(),
    );

    final post = ContentPost(
      id: widget.initialPost?.id ?? 'temp_post',
      brandId: _selectedBrandId,
      title: _titleController.text.trim().isEmpty ? 'Untitled Post' : _titleController.text.trim(),
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      createdAtUtc: DateTime.now().toUtc(),
      updatedAtUtc: DateTime.now().toUtc(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManualHandoffSheet(
        appState: widget.appState,
        post: post,
        account: account,
        variant: variant,
        attachedMedia: _attachedMediaAssets,
      ),
    );
  }

  Future<void> _pickScheduleTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ).toUtc();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.appState.brands;
    final allAccounts = widget.appState.accounts;
    final allMedia = widget.appState.mediaAssets;

    final activeAccount = _activePreviewAccountId != null
        ? widget.appState.getAccountById(_activePreviewAccountId!)
        : null;

    final activePreflight = activeAccount != null ? _getPreflightForAccount(activeAccount) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialPost != null ? 'Edit Post' : 'New Post Composer',
          style: AppTypography.titleLarge,
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.bookmark_outline, size: 16),
            label: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing destination publish jobs...', style: AppTypography.bodyMedium),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1: Brand Selection
                  _buildSectionHeader('1. Select Brand & Identity'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: brands.map((b) {
                      final isSelected = b.id == _selectedBrandId;
                      return ChoiceChip(
                        label: Text(b.name),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedBrandId = b.id);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Post Metadata (Title, Campaign, Tags)
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Post Title / Internal Reference *',
                      hintText: 'e.g., Q4 Architecture Release or Weekend Dev Meme',
                    ),
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _campaignController,
                          decoration: const InputDecoration(
                            labelText: 'Campaign (Optional)',
                            hintText: 'e.g., Q4 Launch',
                          ),
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                            hintText: 'tech, product, infra',
                          ),
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Step 2: Media Asset Attachment
                  _buildSectionHeader('2. Attach Media Assets'),
                  const SizedBox(height: 6),
                  Text(
                    'Select media to attach. Format rules apply per target platform.',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allMedia.map((m) {
                      final isAttached = _selectedMediaIds.contains(m.id);
                      return FilterChip(
                        selected: isAttached,
                        avatar: Icon(
                          m.mediaType == MediaType.video
                              ? Icons.play_circle_outline
                              : Icons.image_outlined,
                          size: 16,
                          color: isAttached ? AppColors.accent : AppColors.textSecondary,
                        ),
                        label: Text('${m.fileName} (${m.formattedSize})'),
                        onSelected: (_) => _toggleMediaSelection(m.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Step 3: Destination Accounts
                  _buildSectionHeader('3. Select Destination Accounts'),
                  const SizedBox(height: 6),
                  Text(
                    'Select one or more targets. Cross-brand selections display caution notices.',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allAccounts.map((acc) {
                      final isSelected = _selectedAccountIds.contains(acc.id);
                      final isBrandMismatch = acc.brandId != _selectedBrandId;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PlatformIconChip(
                            account: acc,
                            isSelected: isSelected,
                            onTap: () => _toggleAccountSelection(acc.id),
                          ),
                          if (isBrandMismatch && isSelected)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.info, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Step 4: Caption Editing & Overrides
                  _buildSectionHeader('4. Captions & Per-Destination Overrides'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Same caption everywhere',
                          style: AppTypography.titleMedium,
                        ),
                        Switch(
                          value: _sameCaptionEverywhere,
                          activeTrackColor: AppColors.accent,
                          onChanged: (val) {
                            setState(() {
                              _sameCaptionEverywhere = val;
                              if (!val) _ensureOverrideControllers();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_sameCaptionEverywhere) ...[
                    TextField(
                      controller: _sharedCaptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Shared Caption Copy',
                        hintText: 'Enter caption with hashtags and links...',
                        alignLabelWithHint: true,
                      ),
                      style: AppTypography.bodyMedium,
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                    // Per-Destination Tabs
                    if (_selectedAccountIds.isEmpty)
                      const Text(
                        'Select at least one destination account above to configure per-destination captions.',
                        style: AppTypography.bodySecondary,
                      )
                    else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _selectedAccountIds.map((accId) {
                            final acc = widget.appState.getAccountById(accId);
                            if (acc == null) return const SizedBox.shrink();
                            final isTabSelected = _activePreviewAccountId == accId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(acc.handle),
                                selected: isTabSelected,
                                onSelected: (_) {
                                  setState(() => _activePreviewAccountId = accId);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (activeAccount != null) ...[
                        Row(
                          children: [
                            Text(
                              'Customizing caption for ${activeAccount.displayName} (${activeAccount.platform.displayName})',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _overrideControllers[activeAccount.id],
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: '${activeAccount.platform.displayName} Caption Override',
                            hintText: 'Write platform tailored copy...',
                            alignLabelWithHint: true,
                          ),
                          style: AppTypography.bodyMedium,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 22),

                  // Step 5: Live Preflight & Preview
                  if (activeAccount != null && activePreflight != null) ...[
                    _buildSectionHeader('5. Preflight Checklist & Live Preview'),
                    const SizedBox(height: 10),
                    PreflightChecklistView(result: activePreflight),
                    const SizedBox(height: 12),
                    PreviewCard(
                      account: activeAccount,
                      caption: activePreflight.effectiveCaption,
                      postTitle: _titleController.text,
                      mediaAssets: _attachedMediaAssets,
                    ),
                    const SizedBox(height: 12),
                    if (activeAccount.isManualOnly)
                      OutlinedButton.icon(
                        onPressed: () => _openManualHandoffForAccount(activeAccount),
                        icon: const Icon(Icons.handshake_outlined, size: 16),
                        label: Text('Open Manual Handoff Sheet for ${activeAccount.handle}'),
                      ),
                    const SizedBox(height: 22),
                  ],

                  // Step 6: Scheduling & Publishing Actions
                  _buildSectionHeader('6. Publishing Actions'),
                  const SizedBox(height: 10),

                  // Schedule display
                  if (_scheduledDateTime != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scheduled for: ${DateFormatter.formatToLocal(_scheduledDateTime)}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.accent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _scheduledDateTime = null),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickScheduleTime,
                          icon: const Icon(Icons.calendar_month_outlined, size: 16),
                          label: Text(_scheduledDateTime == null ? 'Schedule...' : 'Reschedule'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _publishNow,
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: Text(_scheduledDateTime == null ? 'Publish Now' : 'Schedule Jobs'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
