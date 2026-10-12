import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/media_type.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';
import 'package:no5ocial/presentation/screens/composer/manual_handoff_sheet.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/core/errors/app_error_handler.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/presentation/widgets/dialogs/entity_dialogs.dart';
import 'package:no5ocial/presentation/widgets/entity_badges.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';
import 'package:no5ocial/presentation/widgets/preflight_checklist_view.dart';
import 'package:no5ocial/presentation/widgets/preview_card.dart';

class ComposerScreen extends StatefulWidget {
  final AppState appState;
  final ContentPost? initialPost;
  final DateTime? initialScheduledDate;

  const ComposerScreen({
    super.key,
    required this.appState,
    this.initialPost,
    this.initialScheduledDate,
  });

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedBrandId;
  String? _selectedGroupId;
  int _dropdownEpoch = 0;
  int _mobileTabIndex = 0;

  // General Post Details
  final _titleController = TextEditingController();
  final _sharedCaptionController = TextEditingController();
  final _campaignController = TextEditingController();
  final _tagsController = TextEditingController();

  // Platform-Personalized Controllers
  // YouTube
  final _ytTitleController = TextEditingController();
  final _ytDescriptionController = TextEditingController();
  final _ytTagsController = TextEditingController();
  String _ytVisibility = 'public';

  // Instagram
  final _igCaptionController = TextEditingController();
  final _igFirstCommentController = TextEditingController();

  // X (Twitter)
  final _xTextController = TextEditingController();

  // LinkedIn
  final _liCommentaryController = TextEditingController();

  // TikTok
  final _ttCaptionController = TextEditingController();
  bool _ttAllowComments = true;
  bool _ttAllowDuet = true;
  bool _ttAllowStitch = true;

  // Pinterest
  final _pinTitleController = TextEditingController();
  final _pinDescriptionController = TextEditingController();
  final _pinUrlController = TextEditingController();

  // Facebook
  final _fbTextController = TextEditingController();

  // Threads
  final _threadsTextController = TextEditingController();

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

      // Initialize platform controllers from default post data
      _initPlatformControllers(post.title, post.defaultCaption, post.tags.join(', '));

      final variants = widget.appState.getVariantsForPost(post.id);
      for (final v in variants) {
        if (v.hasCaptionOverride) {
          _overrideControllers[v.socialAccountId] = TextEditingController(
            text: v.captionOverride,
          );
          _sameCaptionEverywhere = false;
        }
      }
    } else {
      final brands = widget.appState.brands;
      _selectedBrandId = brands.isNotEmpty ? brands.first.id : null;
      _titleController.text = '';
      _sharedCaptionController.text = '';
      _initPlatformControllers('', '', '');

      // Pre-select accounts from the initial brand if available
      if (_selectedBrandId != null) {
        final accounts = widget.appState.accounts
            .where((a) => a.brandId == _selectedBrandId)
            .toList();
        if (accounts.isNotEmpty) {
          _selectedAccountIds.add(accounts.first.id);
        }
      }

      if (widget.initialScheduledDate != null) {
        _scheduledDateTime = widget.initialScheduledDate;
      }
    }

    _ensureOverrideControllers();
    if (_selectedAccountIds.isNotEmpty) {
      _activePreviewAccountId = _selectedAccountIds.first;
    }

    // Attach listeners so shared edits mirror across platform controllers unless overridden
    _sharedCaptionController.addListener(_onSharedCaptionChanged);
    _titleController.addListener(_onSharedTitleChanged);
  }

  void _initPlatformControllers(String title, String caption, String tags) {
    _ytTitleController.text = title;
    _ytDescriptionController.text = caption;
    _ytTagsController.text = tags;

    _igCaptionController.text = caption;
    _xTextController.text = caption;
    _liCommentaryController.text = caption;
    _ttCaptionController.text = caption;

    _pinTitleController.text = title;
    _pinDescriptionController.text = caption;

    _fbTextController.text = caption;
    _threadsTextController.text = caption;
  }

  void _onSharedCaptionChanged() {
    if (_sameCaptionEverywhere) {
      final text = _sharedCaptionController.text;
      _ytDescriptionController.text = text;
      _igCaptionController.text = text;
      _xTextController.text = text;
      _liCommentaryController.text = text;
      _ttCaptionController.text = text;
      _pinDescriptionController.text = text;
      _fbTextController.text = text;
      _threadsTextController.text = text;
    }
  }

  void _onSharedTitleChanged() {
    final title = _titleController.text;
    if (_ytTitleController.text.isEmpty || _ytTitleController.text == title) {
      _ytTitleController.text = title;
    }
    if (_pinTitleController.text.isEmpty || _pinTitleController.text == title) {
      _pinTitleController.text = title;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onSharedTitleChanged);
    _sharedCaptionController.removeListener(_onSharedCaptionChanged);

    _titleController.dispose();
    _sharedCaptionController.dispose();
    _campaignController.dispose();
    _tagsController.dispose();

    _ytTitleController.dispose();
    _ytDescriptionController.dispose();
    _ytTagsController.dispose();

    _igCaptionController.dispose();
    _igFirstCommentController.dispose();

    _xTextController.dispose();
    _liCommentaryController.dispose();
    _ttCaptionController.dispose();

    _pinTitleController.dispose();
    _pinDescriptionController.dispose();
    _pinUrlController.dispose();

    _fbTextController.dispose();
    _threadsTextController.dispose();

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

  void _selectGroup(ChannelGroup? group, {bool exclusive = true}) {
    setState(() {
      _selectedGroupId = group?.id;
      if (group != null) {
        if (exclusive) {
          _selectedAccountIds.clear();
        }
        for (final id in group.accountIds) {
          _selectedAccountIds.add(id);
          if (!_overrideControllers.containsKey(id)) {
            _overrideControllers[id] = TextEditingController(
              text: _sharedCaptionController.text,
            );
          }
        }
        if (group.accountIds.isNotEmpty) {
          _activePreviewAccountId = group.accountIds.first;
        }
      }
    });
  }

  void _selectAllCompanyChannels(List<SocialAccount> companyAccounts) {
    setState(() {
      final allIds = companyAccounts.map((a) => a.id).toSet();
      final isAllSelected = allIds.isNotEmpty && allIds.every((id) => _selectedAccountIds.contains(id));
      if (isAllSelected) {
        _selectedAccountIds.clear();
        _activePreviewAccountId = null;
      } else {
        _selectedAccountIds.clear();
        for (final acc in companyAccounts) {
          _selectedAccountIds.add(acc.id);
          if (!_overrideControllers.containsKey(acc.id)) {
            _overrideControllers[acc.id] = TextEditingController(
              text: _sharedCaptionController.text,
            );
          }
        }
        if (companyAccounts.isNotEmpty) {
          _activePreviewAccountId = companyAccounts.first.id;
        }
      }
    });
  }

  void _toggleGroupChannels(ChannelGroup group) {
    setState(() {
      final groupIds = group.accountIds.toSet();
      final isFullySelected = groupIds.isNotEmpty && groupIds.every((id) => _selectedAccountIds.contains(id));
      if (isFullySelected) {
        _selectedAccountIds.removeAll(groupIds);
        if (_activePreviewAccountId != null && groupIds.contains(_activePreviewAccountId)) {
          _activePreviewAccountId = _selectedAccountIds.firstOrNull;
        }
        if (_selectedGroupId == group.id) {
          _selectedGroupId = null;
        }
      } else {
        _selectedGroupId = group.id;
        for (final id in group.accountIds) {
          _selectedAccountIds.add(id);
          if (!_overrideControllers.containsKey(id)) {
            _overrideControllers[id] = TextEditingController(
              text: _sharedCaptionController.text,
            );
          }
        }
        if (group.accountIds.isNotEmpty) {
          _activePreviewAccountId = group.accountIds.first;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAccountIds.clear();
      _activePreviewAccountId = null;
      _selectedGroupId = null;
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
    final account = widget.appState.getAccountById(accountId);
    if (account == null) return _sharedCaptionController.text;

    if (!_sameCaptionEverywhere) {
      final overrideText = _overrideControllers[accountId]?.text;
      if (overrideText != null && overrideText.isNotEmpty) {
        return overrideText;
      }
    }

    // Platform-personalized fallback
    switch (account.platform) {
      case PlatformType.youtube:
        return _ytDescriptionController.text.isNotEmpty
            ? _ytDescriptionController.text
            : _sharedCaptionController.text;
      case PlatformType.instagram:
        return _igCaptionController.text.isNotEmpty
            ? _igCaptionController.text
            : _sharedCaptionController.text;
      case PlatformType.x:
        return _xTextController.text.isNotEmpty
            ? _xTextController.text
            : _sharedCaptionController.text;
      case PlatformType.linkedin:
        return _liCommentaryController.text.isNotEmpty
            ? _liCommentaryController.text
            : _sharedCaptionController.text;
      case PlatformType.tiktok:
        return _ttCaptionController.text.isNotEmpty
            ? _ttCaptionController.text
            : _sharedCaptionController.text;
      case PlatformType.pinterest:
        return _pinDescriptionController.text.isNotEmpty
            ? _pinDescriptionController.text
            : _sharedCaptionController.text;
      case PlatformType.facebook:
        return _fbTextController.text.isNotEmpty
            ? _fbTextController.text
            : _sharedCaptionController.text;
      case PlatformType.threads:
        return _threadsTextController.text.isNotEmpty
            ? _threadsTextController.text
            : _sharedCaptionController.text;
    }
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

    final effectiveTitle = account.platform == PlatformType.youtube && _ytTitleController.text.isNotEmpty
        ? _ytTitleController.text
        : (account.platform == PlatformType.pinterest && _pinTitleController.text.isNotEmpty
            ? _pinTitleController.text
            : _titleController.text);

    final post = ContentPost(
      id: widget.initialPost?.id ?? 'temp_post',
      brandId: _selectedBrandId ?? (widget.appState.brands.firstOrNull?.id ?? ''),
      title: effectiveTitle,
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      createdAtUtc: DateTime.now().toUtc(),
      updatedAtUtc: DateTime.now().toUtc(),
    );

    return PreflightValidator.validate(
      account: account,
      variant: variant,
      post: post,
      attachedMedia: _attachedMediaAssets,
    );
  }

  void _saveDraft() {
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final overrides = <String, String>{};
    for (final accId in _selectedAccountIds) {
      final caption = _getCaptionForAccount(accId);
      overrides[accId] = caption;
    }

    final post = widget.appState.saveDraft(
      postId: widget.initialPost?.id,
      brandId: _selectedBrandId ?? (widget.appState.brands.firstOrNull?.id ?? 'default'),
      title: _titleController.text.trim().isEmpty ? 'Untitled Post' : _titleController.text.trim(),
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      tags: tags,
      campaign: _campaignController.text.trim().isNotEmpty ? _campaignController.text.trim() : null,
      captionOverridesByAccount: overrides,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft "${post.title}" saved locally.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _submitPublish() async {
    // Condition Guardrails: Profile must have at least 1 company and 1 channel
    if (widget.appState.brands.isEmpty || widget.appState.accounts.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Publishing Requirement'),
            ],
          ),
          content: const Text(
            'Before creating, publishing, or scheduling posts, your workspace must have at least 1 registered company and at least 1 connected channel.',
          ),
          actions: [
            if (widget.appState.brands.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  EntityDialogs.showRegisterCompanyDialog(context, widget.appState);
                },
                icon: const Icon(Icons.business),
                label: const Text('Register Company'),
              ),
            if (widget.appState.accounts.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  EntityDialogs.showConnectChannelDialog(context, widget.appState);
                },
                icon: const Icon(Icons.add_link),
                label: const Text('Connect Channel'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedBrandId == null || _selectedBrandId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or register a company before publishing.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedAccountIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one destination channel.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Preflight check all accounts
    final blockers = <String>[];
    for (final accId in _selectedAccountIds) {
      final account = widget.appState.getAccountById(accId);
      if (account != null) {
        final result = _getPreflightForAccount(account);
        if (!result.isValid) {
          blockers.add('${account.displayName} (${account.platform.displayName}): ${result.blockers.first.message}');
        }
      }
    }

    if (blockers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Platform Validation Issues'),
            ],
          ),
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
              child: const Text('Close & Adjust'),
            ),
          ],
        ),
      );
      return;
    }

    final isScheduled = _scheduledDateTime != null;
    final actionText = isScheduled ? 'Schedule' : 'Publish';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText Post to ${_selectedAccountIds.length} Channels'),
        content: Text(
          isScheduled
              ? 'Are you sure you want to schedule this post for ${DateFormatter.formatToLocal(_scheduledDateTime)} across ${_selectedAccountIds.length} target channels?'
              : 'Are you sure you want to immediately publish this post to ${_selectedAccountIds.length} target channels?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: Text('Confirm $actionText'),
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
    for (final accId in _selectedAccountIds) {
      overrides[accId] = _getCaptionForAccount(accId);
    }

    final post = widget.appState.saveDraft(
      postId: widget.initialPost?.id,
      brandId: _selectedBrandId!,
      title: _titleController.text.trim().isEmpty ? 'Untitled Post' : _titleController.text.trim(),
      defaultCaption: _sharedCaptionController.text,
      destinationAccountIds: _selectedAccountIds.toList(),
      mediaAssetIds: _selectedMediaIds.toList(),
      tags: tags,
      campaign: _campaignController.text.trim().isNotEmpty ? _campaignController.text.trim() : null,
      captionOverridesByAccount: overrides,
    );

    try {
      await widget.appState.publishOrQueuePost(
        post: post,
        captionOverridesByAccount: overrides,
        isScheduled: isScheduled,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      Navigator.of(context).pop();
      AppSheets.showPostSuccessSheet(
        context,
        title: post.title,
        destinationCount: post.destinationAccountIds.length,
        scheduledDate: isScheduled ? _scheduledDateTime : null,
      );
    } catch (e, st) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      AppErrorHandler.showError(context, e, stackTrace: st);
    }
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
      brandId: _selectedBrandId ?? (widget.appState.brands.firstOrNull?.id ?? 'unassigned'),
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
      initialDate: _scheduledDateTime?.toLocal() ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _scheduledDateTime != null
            ? TimeOfDay(hour: _scheduledDateTime!.toLocal().hour, minute: _scheduledDateTime!.toLocal().minute)
            : const TimeOfDay(hour: 12, minute: 0),
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

  // --- Attach Media Modal (Device, Google Drive, Google Photos, Unsplash, URL) ---
  void _showAttachMediaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.perm_media_outlined, color: AppColors.accent),
                  const SizedBox(width: 10),
                  const Text('Attach Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select sources to attach media assets tailored to your destination platform requirements.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMediaSourceCard(
                    icon: Icons.computer_outlined,
                    label: 'Upload from Device',
                    subtext: 'Browse local disk photos & videos',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showDeviceUploadDialog();
                    },
                  ),
                  _buildMediaSourceCard(
                    icon: Icons.add_to_drive,
                    label: 'Google Drive',
                    subtext: 'Import cloud assets from Drive',
                    color: Colors.amber.shade700,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showCloudDrivePicker('Google Drive');
                    },
                  ),
                  _buildMediaSourceCard(
                    icon: Icons.photo_library_outlined,
                    label: 'Google Photos',
                    subtext: 'Sync from Google Photos library',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showCloudDrivePicker('Google Photos');
                    },
                  ),
                  _buildMediaSourceCard(
                    icon: Icons.image_search_outlined,
                    label: 'Stock Photos',
                    subtext: 'High-res royalty-free imagery',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showStockPicker();
                    },
                  ),
                  _buildMediaSourceCard(
                    icon: Icons.link,
                    label: 'Direct Web URL',
                    subtext: 'Paste direct asset image/video link',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showUrlUploadDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSourceCard({
    required IconData icon,
    required String label,
    required String subtext,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceUploadDialog() {
    final nameCtrl = TextEditingController(text: 'device_media_${DateTime.now().millisecondsSinceEpoch}.jpg');
    MediaType selectedType = MediaType.image;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: AppColors.accent, size: 20),
          SizedBox(width: 8),
          Text('Upload from Device'),
        ],
      ),
      builder: (ctx, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'File Name', hintText: 'e.g. product_launch.mp4'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('File Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Image (JPEG/PNG)'),
                selected: selectedType == MediaType.image,
                onSelected: (val) {
                  if (val) setDialogState(() => selectedType = MediaType.image);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Video (MP4)'),
                selected: selectedType == MediaType.video,
                onSelected: (val) {
                  if (val) setDialogState(() => selectedType = MediaType.video);
                },
              ),
            ],
          ),
        ],
      ),
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final newAsset = MediaAsset(
              id: 'media_${DateTime.now().millisecondsSinceEpoch}',
              fileName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'upload.png',
              mimeType: selectedType == MediaType.video ? 'video/mp4' : 'image/jpeg',
              sizeBytes: selectedType == MediaType.video ? 1024 * 1024 * 15 : 1024 * 1024 * 2,
              mediaType: selectedType,
              createdAtUtc: DateTime.now().toUtc(),
            );
            widget.appState.addMediaAsset(newAsset);
            setState(() => _selectedMediaIds.add(newAsset.id));
            Navigator.of(ctx).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          child: const Text('Upload & Attach'),
        ),
      ],
    );
  }

  void _showCloudDrivePicker(String providerName) {
    final sampleCloudFiles = [
      {'name': 'Q4_Product_Video_Final.mp4', 'type': MediaType.video, 'size': 1024 * 1024 * 18},
      {'name': 'Campaign_Banner_1080x1080.jpg', 'type': MediaType.image, 'size': 1024 * 1024 * 3},
      {'name': 'Brand_Logo_White.png', 'type': MediaType.image, 'size': 1024 * 512},
    ];

    AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          Icon(providerName == 'Google Drive' ? Icons.add_to_drive : Icons.photo_library_outlined, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Import from $providerName'),
        ],
      ),
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connected to Google Account. Select assets to import:', style: AppTypography.bodySecondary),
          const SizedBox(height: 12),
          ...sampleCloudFiles.map((file) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(file['type'] == MediaType.video ? Icons.videocam : Icons.image, color: AppColors.accent),
                title: Text(file['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${((file['size'] as int) / (1024 * 1024)).toStringAsFixed(1)} MB • Cloud storage'),
                trailing: ElevatedButton(
                  onPressed: () {
                    final newAsset = MediaAsset(
                      id: 'media_cloud_${DateTime.now().millisecondsSinceEpoch}',
                      fileName: file['name'] as String,
                      mimeType: file['type'] == MediaType.video ? 'video/mp4' : 'image/jpeg',
                      sizeBytes: file['size'] as int,
                      mediaType: file['type'] as MediaType,
                      createdAtUtc: DateTime.now().toUtc(),
                    );
                    widget.appState.addMediaAsset(newAsset);
                    setState(() => _selectedMediaIds.add(newAsset.id));
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  child: const Text('Attach'),
                ),
              )),
        ],
      ),
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    );
  }

  void _showStockPicker() {
    final stockItems = [
      {'title': 'Modern Workspace Neon', 'file': 'stock_neon_workspace.jpg'},
      {'title': 'Minimal 3D Geometry', 'file': 'stock_3d_geometry.png'},
      {'title': 'Dynamic Team Strategy', 'file': 'stock_team_strategy.jpg'},
    ];

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.image_search, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Stock Imagery (Unsplash)'),
        ],
      ),
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('High-resolution royalty-free media library:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          ...stockItems.map((item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_outlined, color: Colors.teal),
                title: Text(item['title']!),
                subtitle: Text(item['file']!),
                trailing: ElevatedButton(
                  onPressed: () {
                    final newAsset = MediaAsset(
                      id: 'media_stock_${DateTime.now().millisecondsSinceEpoch}',
                      fileName: item['file']!,
                      mimeType: 'image/jpeg',
                      sizeBytes: 1024 * 1024 * 2,
                      mediaType: MediaType.image,
                      createdAtUtc: DateTime.now().toUtc(),
                    );
                    widget.appState.addMediaAsset(newAsset);
                    setState(() => _selectedMediaIds.add(newAsset.id));
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  child: const Text('Use Image'),
                ),
              )),
        ],
      ),
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
      ],
    );
  }

  void _showUrlUploadDialog() {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    MediaType selectedType = MediaType.image;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.link, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Attach via Direct URL'),
        ],
      ),
      builder: (ctx, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(labelText: 'Asset URL *', hintText: 'https://example.com/media.jpg'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Display Name (Optional)', hintText: 'e.g. promo_banner.jpg'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Image'),
                selected: selectedType == MediaType.image,
                onSelected: (val) {
                  if (val) setDialogState(() => selectedType = MediaType.image);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Video'),
                selected: selectedType == MediaType.video,
                onSelected: (val) {
                  if (val) setDialogState(() => selectedType = MediaType.video);
                },
              ),
            ],
          ),
        ],
      ),
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (urlCtrl.text.trim().isEmpty) return;
            final newAsset = MediaAsset(
              id: 'media_url_${DateTime.now().millisecondsSinceEpoch}',
              fileName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'web_asset.png',
              mimeType: selectedType == MediaType.video ? 'video/mp4' : 'image/png',
              sizeBytes: 1024 * 1024 * 2,
              mediaType: selectedType,
              localPreviewUrl: urlCtrl.text.trim(),
              createdAtUtc: DateTime.now().toUtc(),
            );
            widget.appState.addMediaAsset(newAsset);
            setState(() => _selectedMediaIds.add(newAsset.id));
            Navigator.of(ctx).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          child: const Text('Attach URL'),
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
        final allAccounts = widget.appState.accounts;
        final allMedia = widget.appState.mediaAssets;

        if (brands.isNotEmpty && (_selectedBrandId == null || !brands.any((b) => b.id == _selectedBrandId))) {
          _selectedBrandId = brands.first.id;
        } else if (brands.isEmpty) {
          _selectedBrandId = null;
        }

        final brandGroups = _selectedBrandId != null
            ? widget.appState.getGroupsByBrand(_selectedBrandId!)
            : <ChannelGroup>[];

        final activeAccount = _activePreviewAccountId != null
            ? widget.appState.getAccountById(_activePreviewAccountId!)
            : null;

        final activePreflight = activeAccount != null
            ? _getPreflightForAccount(activeAccount)
            : null;

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              widget.initialPost != null ? 'Edit Post' : 'Create Post',
              style: AppTypography.titleLarge,
            ),
            actions: [
              TextButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.bookmark_outline, size: 16),
                label: const Text('Save Draft'),
              ),
              const SizedBox(width: 12),
            ],
            bottom: isDesktop
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: SegmentedButton<int>(
                        segments: [
                          const ButtonSegment(
                            value: 0,
                            label: Text('Compose'),
                            icon: Icon(Icons.edit_note_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Live Preview'),
                                if (activeAccount != null) ...[
                                  const SizedBox(width: 6),
                                  PlatformLogo(platform: activeAccount.platform, size: 12),
                                ],
                              ],
                            ),
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                          ),
                        ],
                        selected: {_mobileTabIndex},
                        onSelectionChanged: (val) => setState(() => _mobileTabIndex = val.first),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  child: _buildPublishActionBar(isMobile: true),
                ),
          body: _isSubmitting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing multi-platform publishing jobs...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: isDesktop ? 24 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Condition Guardrail Check (Google profile must have >=1 company & >=1 channel)
                      if (brands.isEmpty || allAccounts.isEmpty) ...[
                        _buildGuardrailRequirementBanner(brands, allAccounts),
                        const SizedBox(height: 16),
                      ],

                      if (isDesktop) ...[
                        // 1st ROW: Company, Group, Platform Individual Dropdown Selection + Create Button
                        _buildFirstRowSelectors(brands, brandGroups, allAccounts),
                        const SizedBox(height: 20),
                        // Dual-Column on desktop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Personalized Composer Forms
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTargetChannelsSelectionBar(allAccounts, brandGroups),
                                  const SizedBox(height: 16),
                                  _buildPersonalizedContentCard(activeAccount),
                                  const SizedBox(height: 16),
                                  _buildAttachMediaCard(allMedia, activeAccount),
                                  const SizedBox(height: 20),
                                  _buildPublishActionBar(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right: Platform-Tailored Live Preview & Preflight
                            Expanded(
                              flex: 4,
                              child: _buildRightPreviewColumn(activeAccount, activePreflight),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile Layout: Tabbed Flow
                        if (_mobileTabIndex == 0) ...[
                          _buildFirstRowSelectors(brands, brandGroups, allAccounts),
                          const SizedBox(height: 16),
                          _buildTargetChannelsSelectionBar(allAccounts, brandGroups),
                          const SizedBox(height: 16),
                          _buildPersonalizedContentCard(activeAccount),
                          const SizedBox(height: 16),
                          _buildAttachMediaCard(allMedia, activeAccount),
                          const SizedBox(height: 16),
                        ] else ...[
                          _buildRightPreviewColumn(activeAccount, activePreflight),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  // --- Guardrail Banner ---
  Widget _buildGuardrailRequirementBanner(List<Brand> brands, List<SocialAccount> accounts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.warning, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Readiness Requirement',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Every user profile must have at least 1 registered company and 1 connected social channel before publishing or scheduling posts.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (brands.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () => EntityDialogs.showRegisterCompanyDialog(
                          context,
                          widget.appState,
                          onSaved: (b) => setState(() => _selectedBrandId = b.id),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Register Company'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    if (accounts.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () => EntityDialogs.showConnectChannelDialog(
                          context,
                          widget.appState,
                          preselectedBrandId: _selectedBrandId,
                          onSaved: (acc) => setState(() {
                            _selectedAccountIds.add(acc.id);
                            _activePreviewAccountId = acc.id;
                          }),
                        ),
                        icon: const Icon(Icons.add_link, size: 16),
                        label: const Text('Connect Channel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1st ROW: Company, Group, Platform Dropdowns with Inline Create (+) Buttons ---
  Widget _buildFirstRowSelectors(
    List<Brand> brands,
    List<ChannelGroup> brandGroups,
    List<SocialAccount> allAccounts,
  ) {
    final eligibleChannels = _selectedBrandId != null
        ? allAccounts.where((a) => a.brandId == _selectedBrandId).toList()
        : allAccounts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_outlined, size: 16, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'Company',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;

              // 1. Company Dropdown with inline create option
              final companyDropdown = DropdownButtonFormField<String>(
                key: ValueKey('company_${_selectedBrandId}_$_dropdownEpoch'),
                initialValue: brands.any((b) => b.id == _selectedBrandId) ? _selectedBrandId : null,
                decoration: const InputDecoration(
                  labelText: 'Company *',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Select Company'),
                items: [
                  ...brands.map((b) => DropdownMenuItem(
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
                            Flexible(child: Text(b.name, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
                  const DropdownMenuItem(
                    value: '__create_company__',
                    child: Row(
                      children: [
                        Icon(Icons.add_business_outlined, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          '+ Register New Company...',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__create_company__') {
                    setState(() => _dropdownEpoch++);
                    EntityDialogs.showRegisterCompanyDialog(
                      context,
                      widget.appState,
                      onSaved: (b) => setState(() {
                        _selectedBrandId = b.id;
                        _selectedGroupId = null;
                        _selectedAccountIds.clear();
                        _activePreviewAccountId = null;
                        _dropdownEpoch++;
                      }),
                    );
                  } else if (val != null) {
                    setState(() {
                      _selectedBrandId = val;
                      _selectedGroupId = null;
                      final brandAccounts = widget.appState.getAccountsByBrand(val);
                      _selectedAccountIds.removeWhere((id) => !brandAccounts.any((a) => a.id == id));
                      if (_selectedAccountIds.isEmpty && brandAccounts.isNotEmpty) {
                        _selectedAccountIds.add(brandAccounts.first.id);
                        _activePreviewAccountId = brandAccounts.first.id;
                      }
                    });
                  }
                },
              );

              // 2. Group Dropdown with inline create option
              final groupDropdown = DropdownButtonFormField<String>(
                key: ValueKey('group_${_selectedGroupId}_$_dropdownEpoch'),
                initialValue: brandGroups.any((g) => g.id == _selectedGroupId) ? _selectedGroupId : null,
                decoration: const InputDecoration(
                  labelText: 'Group (Optional)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('None (All / Standalone channels)'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None (All / Standalone channels)'),
                  ),
                  ...brandGroups.map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.folder_rounded, size: 13, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text('${g.name} (${g.accountIds.length})', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      )),
                  const DropdownMenuItem(
                    value: '__create_group__',
                    child: Row(
                      children: [
                        Icon(Icons.create_new_folder_outlined, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          '+ Create Channel Group...',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__create_group__') {
                    setState(() => _dropdownEpoch++);
                    EntityDialogs.showCreateGroupDialog(
                      context,
                      widget.appState,
                      preselectedBrandId: _selectedBrandId,
                      onSaved: (g) {
                        _selectGroup(g);
                        setState(() => _dropdownEpoch++);
                      },
                    );
                  } else {
                    final selectedGroup = brandGroups.where((g) => g.id == val).firstOrNull;
                    _selectGroup(selectedGroup);
                  }
                },
              );

              // 3. Platform / Channel Dropdown with inline connect option
              final channelDropdown = DropdownButtonFormField<String>(
                key: ValueKey('channel_${_activePreviewAccountId}_$_dropdownEpoch'),
                initialValue: eligibleChannels.any((a) => a.id == _activePreviewAccountId)
                    ? _activePreviewAccountId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Active Channel / Platform',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Select Channel'),
                items: [
                  ...eligibleChannels.map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(
                          children: [
                            PlatformLogo(platform: a.platform, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${a.displayName} (${a.handle})', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      )),
                  const DropdownMenuItem(
                    value: '__connect_channel__',
                    child: Row(
                      children: [
                        Icon(Icons.add_link, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          '+ Connect New Channel...',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__connect_channel__') {
                    setState(() => _dropdownEpoch++);
                    EntityDialogs.showConnectChannelDialog(
                      context,
                      widget.appState,
                      preselectedBrandId: _selectedBrandId,
                      onSaved: (acc) => setState(() {
                        _selectedAccountIds.add(acc.id);
                        _activePreviewAccountId = acc.id;
                        _dropdownEpoch++;
                      }),
                    );
                  } else if (val != null) {
                    setState(() {
                      _selectedAccountIds.add(val);
                      _activePreviewAccountId = val;
                    });
                  }
                },
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    companyDropdown,
                    const SizedBox(height: 12),
                    groupDropdown,
                    const SizedBox(height: 12),
                    channelDropdown,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: companyDropdown),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: groupDropdown),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: channelDropdown),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Target Channels Selection (Chips & Group Presets) ---
  Widget _buildTargetChannelsSelectionBar(
    List<SocialAccount> allAccounts,
    List<ChannelGroup> brandGroups,
  ) {
    final companyAccounts = _selectedBrandId != null
        ? allAccounts.where((a) => a.brandId == _selectedBrandId).toList()
        : allAccounts;

    // Identify which accounts belong to any group in this company
    final groupedAccountIds = brandGroups.expand((g) => g.accountIds).toSet();
    final standaloneAccounts = companyAccounts.where((a) => !groupedAccountIds.contains(a.id)).toList();

    final totalSelected = _selectedAccountIds.length;
    final totalCompany = companyAccounts.length;
    final isAllSelected = totalCompany > 0 && companyAccounts.every((a) => _selectedAccountIds.contains(a.id));

    ChannelGroup? matchedGroup;
    if (brandGroups.isNotEmpty) {
      for (final g in brandGroups) {
        if (g.accountIds.isNotEmpty &&
            g.accountIds.length == totalSelected &&
            g.accountIds.every((id) => _selectedAccountIds.contains(id))) {
          matchedGroup = g;
          break;
        }
      }
    }

    // Determine current publishing mode
    final String modeTitle;
    final String modeDescription;
    final IconData modeIcon;
    final Color modeColor;
    final Color modeBg;

    if (totalSelected == 0) {
      modeTitle = 'No Channels Selected';
      modeDescription = 'Tap an individual channel below, a group preset, or "Post to All" to choose your publishing target.';
      modeIcon = Icons.info_outline;
      modeColor = AppColors.textSecondary;
      modeBg = AppColors.surfaceSecondary;
    } else if (totalSelected == 1) {
      final singleAcc = companyAccounts.where((a) => _selectedAccountIds.contains(a.id)).firstOrNull ??
          allAccounts.where((a) => _selectedAccountIds.contains(a.id)).firstOrNull;
      final accName = singleAcc != null ? '${singleAcc.displayName} (${singleAcc.platform.displayName})' : '1 channel';
      final subtypeInfo = singleAcc != null ? ' · ${singleAcc.subtypeLabel}' : '';
      modeTitle = 'Individual Channel Publishing';
      modeDescription = 'Targeting only $accName$subtypeInfo. No other accounts will receive this post.';
      modeIcon = Icons.person_pin_circle_outlined;
      modeColor = const Color(0xFF0D9488);
      modeBg = const Color(0xFF0D9488).withAlpha(20);
    } else if (isAllSelected) {
      modeTitle = 'Simultaneous Publishing (All Channels)';
      modeDescription = 'Publishing simultaneously across all $totalSelected channels linked under this company.';
      modeIcon = Icons.bolt;
      modeColor = AppColors.accent;
      modeBg = AppColors.accent.withAlpha(20);
    } else if (matchedGroup != null) {
      modeTitle = 'Group-Wise Publishing ("${matchedGroup.name}")';
      modeDescription = 'Targeting all $totalSelected channels bundled under product group "${matchedGroup.name}".';
      modeIcon = Icons.folder_special_outlined;
      modeColor = const Color(0xFF6366F1);
      modeBg = const Color(0xFF6366F1).withAlpha(20);
    } else {
      modeTitle = 'Custom Multi-Channel Publishing';
      modeDescription = 'Publishing simultaneously to $totalSelected selected channels.';
      modeIcon = Icons.call_split;
      modeColor = const Color(0xFF2563EB);
      modeBg = const Color(0xFF2563EB).withAlpha(20);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.send_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Publish Destinations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
              if (totalSelected > 0)
                TextButton.icon(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Clear Selection', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Mode Card / Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: modeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: modeColor.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(modeIcon, size: 18, color: modeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modeTitle,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: modeColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modeDescription,
                        style: TextStyle(fontSize: 11, color: AppColors.ink.withAlpha(200)),
                      ),
                    ],
                  ),
                ),
                if (totalSelected > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: modeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalSelected active',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Presets Bar (1-Click Shortcuts)
          if (companyAccounts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Quick Presets:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                // 1. Post to All Channels preset
                FilterChip(
                  avatar: const Icon(Icons.bolt, size: 14, color: Colors.amber),
                  label: Text('Post to All Channels ($totalCompany)'),
                  selected: isAllSelected,
                  selectedColor: AppColors.accent.withAlpha(25),
                  checkmarkColor: AppColors.accent,
                  onSelected: (_) => _selectAllCompanyChannels(companyAccounts),
                ),
                // 2. Group presets (if groups exist)
                ...brandGroups.map((g) {
                  final groupCount = g.accountIds.length;
                  final isGroupActive = g.accountIds.isNotEmpty &&
                      g.accountIds.every((id) => _selectedAccountIds.contains(id));
                  return FilterChip(
                    avatar: const Icon(Icons.folder_outlined, size: 14, color: Color(0xFF6366F1)),
                    label: Text('Group: ${g.name} ($groupCount)'),
                    selected: isGroupActive,
                    selectedColor: const Color(0xFF6366F1).withAlpha(25),
                    checkmarkColor: const Color(0xFF6366F1),
                    onSelected: (_) => _toggleGroupChannels(g),
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
          ],

          // Content: Empty State OR Categorized Channel Chips
          if (companyAccounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No channels connected for this company yet. Use "+ Connect New Channel" above to link a channel.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else ...[
            // 1. Render Group Sections (if groups exist)
            if (brandGroups.isNotEmpty) ...[
              for (final group in brandGroups) ...[
                Builder(
                  builder: (context) {
                    final groupAccs = companyAccounts.where((a) => group.accountIds.contains(a.id)).toList();
                    final isGroupFull = groupAccs.isNotEmpty &&
                        groupAccs.every((a) => _selectedAccountIds.contains(a.id));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GroupBadge(
                                group: group,
                                channelCount: groupAccs.length,
                                isCompact: true,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _toggleGroupChannels(group),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                                child: Text(
                                  isGroupFull ? 'Deselect Group' : 'Select Group',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (groupAccs.isEmpty)
                            const Text(
                              'No channels in this group yet.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: groupAccs.map((acc) => _buildChannelChip(acc)).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],

            // 2. Render Standalone Channels (Channels without a group)
            if (standaloneAccounts.isNotEmpty) ...[
              if (brandGroups.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Text(
                      'Standalone Channels (Direct under Company)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${standaloneAccounts.length} channels',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: standaloneAccounts.map((acc) => _buildChannelChip(acc)).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChannelChip(SocialAccount acc) {
    final isSelected = _selectedAccountIds.contains(acc.id);
    final isActivePreview = _activePreviewAccountId == acc.id;

    return FilterChip(
      selected: isSelected,
      avatar: PlatformLogo(platform: acc.platform, size: 14),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${acc.displayName} (${acc.handle})'),
          if (acc.subtypeLabel.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                acc.subtypeLabel,
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (isActivePreview && isSelected) ...[
            const SizedBox(width: 4),
            const Icon(Icons.visibility, size: 12, color: AppColors.accent),
          ],
        ],
      ),
      selectedColor: AppColors.accent.withAlpha(25),
      checkmarkColor: AppColors.accent,
      onSelected: (_) => _toggleAccountSelection(acc.id),
    );
  }

  // --- Dynamic Platform Personalized Content Card ---
  Widget _buildPersonalizedContentCard(SocialAccount? activeAccount) {
    final platform = activeAccount?.platform ?? PlatformType.youtube;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Post Content (${platform.displayName} Personalized)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const Spacer(),
              // Toggle: Same caption everywhere
              Row(
                children: [
                  const Text('Sync across platforms', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
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
            ],
          ),
          const SizedBox(height: 12),

          // Platform-Specific Dynamic Form
          _buildPlatformDynamicForm(platform, activeAccount),
        ],
      ),
    );
  }

  Widget _buildPlatformDynamicForm(PlatformType platform, SocialAccount? account) {
    switch (platform) {
      case PlatformType.youtube:
        return _buildYouTubeForm();
      case PlatformType.instagram:
        return _buildInstagramForm();
      case PlatformType.x:
        return _buildXTwitterForm();
      case PlatformType.linkedin:
        return _buildLinkedInForm();
      case PlatformType.tiktok:
        return _buildTikTokForm();
      case PlatformType.pinterest:
        return _buildPinterestForm();
      case PlatformType.facebook:
        return _buildFacebookForm();
      case PlatformType.threads:
        return _buildThreadsForm();
    }
  }

  // 1. YouTube Form: Separate Video Title (max 100), Description (max 5000), Tags, Visibility
  Widget _buildYouTubeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.youtube,
          note: 'YouTube requires separate Video Title, Description, and Tags. Video attachment required.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ytTitleController,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: 'Video Title *',
            hintText: 'Catchy, searchable video headline',
            suffixText: '${_ytTitleController.text.length}/100',
          ),
          onChanged: (val) => setState(() => _titleController.text = val),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ytDescriptionController,
          maxLength: 5000,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Video Description',
            hintText: 'Explain your video, include timestamps, links, and hashtags (#tag)...',
            alignLabelWithHint: true,
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ytTagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (Comma-separated)',
                  hintText: 'e.g. podcast, tutorial, tech review',
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _tagsController.text = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _ytVisibility,
                decoration: const InputDecoration(labelText: 'Privacy Status', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _ytVisibility = val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Instagram Form: Unified Caption (max 2200, hashtag counter), First Comment
  Widget _buildInstagramForm() {
    final caption = _igCaptionController.text;
    final hashtagCount = RegExp(r'#[a-zA-Z0-9_]+').allMatches(caption).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.instagram,
          note: 'Instagram combines post copy and hashtags into one single caption (max 2,200 chars). Media required.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _igCaptionController,
          maxLength: 2200,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Instagram Caption *',
            hintText: 'Write your story and include your #hashtags here...',
            alignLabelWithHint: true,
            helperText: '$hashtagCount / 30 hashtags used',
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _igFirstCommentController,
          decoration: const InputDecoration(
            labelText: 'First Comment (Optional)',
            hintText: 'Keep main caption clean by placing additional hashtags or links in 1st comment',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            _buildQuickTagChip(_igCaptionController, '#photography'),
            _buildQuickTagChip(_igCaptionController, '#creator'),
            _buildQuickTagChip(_igCaptionController, '#dailyvibe'),
            _buildQuickTagChip(_igCaptionController, '#instagood'),
          ],
        ),
      ],
    );
  }

  // 3. X (Twitter) Form: Short Post Text (max 280 countdown)
  Widget _buildXTwitterForm() {
    final remaining = 280 - _xTextController.text.length;
    final isExceeded = remaining < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.x,
          note: 'X (Twitter) requires concise micro-updates (280 characters limit). Supports up to 4 images or 1 video.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _xTextController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Post Text (Tweet) *',
            hintText: 'What is happening?!',
            alignLabelWithHint: true,
            errorText: isExceeded ? 'Exceeded by ${remaining.abs()} characters' : null,
            helperText: '$remaining characters remaining',
            helperStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: remaining <= 20 ? AppColors.warning : AppColors.textSecondary,
            ),
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
      ],
    );
  }

  // 4. LinkedIn Form: Post Commentary (max 3000)
  Widget _buildLinkedInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.linkedin,
          note: 'LinkedIn is optimized for professional insights, thought leadership commentary, and industry articles.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _liCommentaryController,
          maxLength: 3000,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Post Commentary *',
            hintText: 'Share professional insights, case studies, or company milestones...',
            alignLabelWithHint: true,
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
      ],
    );
  }

  // 5. TikTok Form: Video Caption (max 4000) + Interactive Settings
  Widget _buildTikTokForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.tiktok,
          note: 'TikTok requires vertical 9:16 video upload and caption with relevant trending hashtags.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ttCaptionController,
          maxLength: 4000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'TikTok Video Caption *',
            hintText: 'Describe your clip, tag collaborators, add #fyp #trending...',
            alignLabelWithHint: true,
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _ttAllowComments,
                    onChanged: (v) => setState(() => _ttAllowComments = v ?? true),
                  ),
                  const Text('Comments', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _ttAllowDuet,
                    onChanged: (v) => setState(() => _ttAllowDuet = v ?? true),
                  ),
                  const Text('Duet', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _ttAllowStitch,
                    onChanged: (v) => setState(() => _ttAllowStitch = v ?? true),
                  ),
                  const Text('Stitch', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Pinterest Form: Pin Title (max 100), Description (max 500), Destination URL
  Widget _buildPinterestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.pinterest,
          note: 'Pinterest Pins require an Image or Video, Title, and Destination Website URL.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinTitleController,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Pin Title *', hintText: 'Inspiring, searchable pin title'),
          onChanged: (val) => setState(() => _titleController.text = val),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pinDescriptionController,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Pin Description',
            hintText: 'Tell pinners what your pin is about...',
            alignLabelWithHint: true,
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pinUrlController,
          decoration: const InputDecoration(
            labelText: 'Destination Link / URL *',
            hintText: 'https://yourwebsite.com/product',
            isDense: true,
          ),
        ),
      ],
    );
  }

  // 7. Facebook Form: Post Status
  Widget _buildFacebookForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.facebook,
          note: 'Facebook Page status update. Supports text, link sharing, and multi-photo/video albums.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fbTextController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Post Update *',
            hintText: 'What is on your mind? Share updates with your followers...',
            alignLabelWithHint: true,
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
      ],
    );
  }

  // 8. Threads Form: Thread Text (max 500)
  Widget _buildThreadsForm() {
    final remaining = 500 - _threadsTextController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlatformBadge(
          platform: PlatformType.threads,
          note: 'Threads text update (max 500 characters). Share conversational ideas and media.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _threadsTextController,
          maxLength: 500,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Thread Text *',
            hintText: 'Start a thread...',
            alignLabelWithHint: true,
            helperText: '$remaining characters remaining',
          ),
          onChanged: (val) {
            if (_sameCaptionEverywhere) _sharedCaptionController.text = val;
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildPlatformBadge({required PlatformType platform, required String note}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          PlatformLogo(platform: platform, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTagChip(TextEditingController controller, String tag) {
    return InkWell(
      onTap: () {
        controller.text = controller.text.isEmpty ? tag : '${controller.text} $tag';
        setState(() {});
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // --- Attach Media Card (Renamed to "Attach Media") ---
  Widget _buildAttachMediaCard(List<MediaAsset> allMedia, SocialAccount? activeAccount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.perm_media_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text(
                'Attach Media',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAttachMediaModal,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Media'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload from device or cloud (Google Drive, Photos, Stock, URL). Select attached files to include in this post:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (allMedia.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No media attached. Click "+ Add Media" to upload photos or videos from your device or cloud.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allMedia.map((m) {
                final isAttached = _selectedMediaIds.contains(m.id);
                return FilterChip(
                  selected: isAttached,
                  avatar: Icon(
                    m.mediaType == MediaType.video ? Icons.play_circle_outline : Icons.image_outlined,
                    size: 16,
                    color: isAttached ? AppColors.accent : AppColors.textSecondary,
                  ),
                  label: Text('${m.fileName} (${m.formattedSize})'),
                  selectedColor: AppColors.accent.withAlpha(30),
                  checkmarkColor: AppColors.accent,
                  onSelected: (_) => _toggleMediaSelection(m.id),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Right Column: Live Media Preview as per Platform ---
  Widget _buildRightPreviewColumn(SocialAccount? activeAccount, PreflightResult? activePreflight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Preview Header
          Row(
            children: [
              const Icon(Icons.preview_outlined, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Live Media Preview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (activeAccount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      PlatformLogo(platform: activeAccount.platform, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        activeAccount.platform.displayName,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Platform Switcher Chips for Live Preview
          if (_selectedAccountIds.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedAccountIds.map((accId) {
                final acc = widget.appState.getAccountById(accId);
                if (acc == null) return const SizedBox.shrink();
                final isActive = _activePreviewAccountId == accId;
                return ChoiceChip(
                  selected: isActive,
                  avatar: PlatformLogo(
                    platform: acc.platform,
                    size: 14,
                    color: isActive ? Colors.white : null,
                  ),
                  label: Text(acc.displayName),
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _activePreviewAccountId = accId);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Realistic Social Preview Mockup (Displays preview as per platform)
          if (activeAccount != null)
            PreviewCard(
              account: activeAccount,
              caption: _getCaptionForAccount(activeAccount.id),
              postTitle: activeAccount.platform == PlatformType.youtube
                  ? _ytTitleController.text
                  : (activeAccount.platform == PlatformType.pinterest
                      ? _pinTitleController.text
                      : _titleController.text),
              mediaAssets: _attachedMediaAssets,
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Select a destination channel to preview realistic social feed render.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Preflight Validation Checklist
          if (activePreflight != null && activeAccount != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Platform Preflight (${activeAccount.platform.displayName})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: !activePreflight.isValid ? AppColors.errorBg : AppColors.successBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    !activePreflight.isValid ? 'BLOCKED' : 'READY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: !activePreflight.isValid ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PreflightChecklistView(result: activePreflight),
          ],
        ],
      ),
    );
  }

  // --- Publish & Schedule Action Bar ---
  Widget _buildPublishActionBar({bool isMobile = false}) {
    final isScheduled = _scheduledDateTime != null;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isScheduled) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled: ${DateFormatter.formatToLocal(_scheduledDateTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Cancel Schedule',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _scheduledDateTime = null),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.bookmark_outline, size: 16),
                  label: const Text('Draft'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (_selectedAccountIds.any((id) => widget.appState.getAccountById(id)?.isManualOnly ?? false)) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.accent),
                    tooltip: 'Manual Handoff',
                    onPressed: () {
                      final manualAccId = _selectedAccountIds.firstWhere(
                        (id) => widget.appState.getAccountById(id)?.isManualOnly ?? false,
                      );
                      final manualAcc = widget.appState.getAccountById(manualAccId);
                      if (manualAcc != null) _openManualHandoffForAccount(manualAcc);
                    },
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _submitPublish,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isScheduled ? Icons.schedule_send : Icons.send,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isScheduled ? 'Schedule' : 'Publish Now',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 24, color: Colors.white24),
                        IconButton(
                          icon: Icon(
                            isScheduled ? Icons.event_available : Icons.calendar_month,
                            color: Colors.white,
                            size: 18,
                          ),
                          tooltip: isScheduled ? 'Change Scheduled Time' : 'Schedule for Later',
                          onPressed: _pickScheduleTime,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Schedule Status Pill (if scheduled)
          if (isScheduled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled: ${DateFormatter.formatToLocal(_scheduledDateTime)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Cancel Schedule',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _scheduledDateTime = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Save Draft Button
              OutlinedButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.bookmark_outline, size: 16),
                label: const Text('Save Draft'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              if (_selectedAccountIds.any((id) => widget.appState.getAccountById(id)?.isManualOnly ?? false))
                OutlinedButton.icon(
                  onPressed: () {
                    final manualAccId = _selectedAccountIds.firstWhere(
                      (id) => widget.appState.getAccountById(id)?.isManualOnly ?? false,
                    );
                    final manualAcc = widget.appState.getAccountById(manualAccId);
                    if (manualAcc != null) _openManualHandoffForAccount(manualAcc);
                  },
                  icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.accent),
                  label: const Text('Manual Handoff Sheet'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

              // Publish Now with Schedule Icon Button (no button label on schedule)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Publish Action ("Publish Now")
                    InkWell(
                      onTap: _submitPublish,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        child: Row(
                          children: [
                            Icon(isScheduled ? Icons.schedule_send : Icons.send, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isScheduled ? 'Schedule Post' : 'Publish Now',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    Container(width: 1, height: 24, color: Colors.white24),
                    // Schedule Button (No button label, icon only)
                    IconButton(
                      icon: Icon(
                        isScheduled ? Icons.event_available : Icons.calendar_month,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: isScheduled ? 'Change Scheduled Time' : 'Schedule for Later',
                      onPressed: _pickScheduleTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
