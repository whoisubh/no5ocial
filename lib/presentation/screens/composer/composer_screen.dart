import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/core/utils/number_formatter.dart';
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
import 'package:no5ocial/presentation/widgets/platform_logo.dart';
import 'package:no5ocial/presentation/widgets/preflight_checklist_view.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';
import 'package:no5ocial/presentation/widgets/preview_card.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:no5ocial/core/services/video_thumbnail_service.dart';
import 'package:no5ocial/core/services/monetization_service.dart';

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
  String _activeContentTab = 'master';

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
  String? _activePublishError;
  bool _isWatchingAdInComposer = false;
  bool _isActivatingPassInComposer = false;

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

    _fbTextController.text = caption;
    _threadsTextController.text = caption;
  }

  bool _isSyncing = false;

  void _syncCaptionToOthers(TextEditingController sourceCtrl, String text) {
    if (!_sameCaptionEverywhere || _isSyncing) return;
    _isSyncing = true;
    try {
      _sharedCaptionController.text = text;
      void syncOne(TextEditingController target) {
        if (target != sourceCtrl && target.text != text) {
          target.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
      syncOne(_ytDescriptionController);
      syncOne(_igCaptionController);
      syncOne(_xTextController);
      syncOne(_liCommentaryController);
      syncOne(_fbTextController);
      syncOne(_threadsTextController);
    } finally {
      _isSyncing = false;
    }
  }

  void _syncTitleToOthers(TextEditingController sourceCtrl, String title) {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      _titleController.text = title;
      void syncOne(TextEditingController target) {
        if (target != sourceCtrl && target.text != title) {
          target.value = TextEditingValue(
            text: title,
            selection: TextSelection.collapsed(offset: title.length),
          );
        }
      }
      syncOne(_ytTitleController);
    } finally {
      _isSyncing = false;
    }
  }

  void _onSharedCaptionChanged() {
    if (_isSyncing) return;
    _syncCaptionToOthers(_sharedCaptionController, _sharedCaptionController.text);
  }

  void _onSharedTitleChanged() {
    if (_isSyncing) return;
    _syncTitleToOthers(_titleController, _titleController.text);
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
        if (_activeContentTab == accountId) {
          _activeContentTab = 'master';
        }
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


  void _selectAllCompanyChannels(List<SocialAccount> companyAccounts) {
    setState(() {
      final allIds = companyAccounts.map((a) => a.id).toSet();
      final isAllSelected = allIds.isNotEmpty && allIds.every((id) => _selectedAccountIds.contains(id));
      if (isAllSelected) {
        _selectedAccountIds.clear();
        _activePreviewAccountId = null;
        _activeContentTab = 'master';
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
        if (_activeContentTab != 'master' && groupIds.contains(_activeContentTab)) {
          _activeContentTab = 'master';
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
      _activeContentTab = 'master';
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

  String _resolveDerivedPostTitle() {
    if (_ytTitleController.text.trim().isNotEmpty) {
      return _ytTitleController.text.trim();
    }
    if (_titleController.text.trim().isNotEmpty) {
      return _titleController.text.trim();
    }
    if (_campaignController.text.trim().isNotEmpty) {
      return _campaignController.text.trim();
    }
    final caption = _sharedCaptionController.text.trim();
    if (caption.isNotEmpty) {
      final firstLine = caption.split('\n').first.trim();
      return firstLine.length > 55 ? '${firstLine.substring(0, 52)}...' : firstLine;
    }
    if (_selectedMediaIds.isNotEmpty) {
      final firstAsset = _attachedMediaAssets.firstOrNull;
      return firstAsset != null ? 'Media (${firstAsset.fileName})' : 'Media Post';
    }
    return 'Draft ${DateTime.now().toIso8601String().substring(0, 10)}';
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

    // Only YouTube requires an explicit external video title
    final effectiveTitle = account.platform == PlatformType.youtube
        ? (_ytTitleController.text.trim().isNotEmpty
            ? _ytTitleController.text.trim()
            : _titleController.text.trim())
        : _resolveDerivedPostTitle();

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
      title: _resolveDerivedPostTitle(),
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
      setState(() => _activePublishError = 'Please select a company in the destination lobby above before publishing.');
      return;
    }

    if (_selectedAccountIds.isEmpty) {
      setState(() => _activePublishError = 'Please select at least one destination channel in the lobby above.');
      return;
    }

    final hasAnyCaption = _sharedCaptionController.text.trim().isNotEmpty ||
        _selectedAccountIds.any((id) => _getCaptionForAccount(id).trim().isNotEmpty);
    if (!hasAnyCaption && _selectedMediaIds.isEmpty) {
      setState(() => _activePublishError = 'Cannot publish an empty post. Please enter a caption/description or attach media files.');
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
      setState(() => _activePublishError = 'Platform Validation Blockers:\n• ${blockers.join('\n• ')}');
      return;
    }

    setState(() => _activePublishError = null);

    final isScheduled = _scheduledDateTime != null;

    // --- 2-Day Publishing Pass (10 Coins = 2 Posts over 2 Days) Gatekeeper ---
    final access = MonetizationService.instance.evaluatePublishingAccess(
      userId: widget.appState.localUserId,
    );

    bool needsPassActivation = false;

    if (!access.canPublish) {
      if (access.canActivatePass) {
        // User has no active pass, but has >= 10 Coins in DB wallet
        final shouldActivate = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.confirmation_number_rounded, color: Color(0xFF059669), size: 22),
                SizedBox(width: 8),
                Text('Activate 2-Day Pass?'),
              ],
            ),
            content: Text(
              'In no5ocial, publishing requires an active 2-Day Pass (10 Coins = 2 posts over 2 days).\n\n'
              'You have ${MonetizationService.instance.postCoins} Coins in your verified database wallet.\n\n'
              'Spend 10 Coins to activate your 2-Day Pass and publish this post now? (1 post will remain valid for 48 hours).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Activate Pass & Post (10 Coins)'),
              ),
            ],
          ),
        );

        if (shouldActivate == true) {
          needsPassActivation = true;
        } else {
          return;
        }
      } else {
        // User has < 10 Coins: show prompt to watch rewarded video ads
        final watched = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 22),
                SizedBox(width: 8),
                Text('Need 10 Coins to Post'),
              ],
            ),
            content: Text(
              'In no5ocial, 10 Coins unlocks a 2-Day Pass allowing 2 multi-platform posts over 2 days.\n\n'
              'You currently have ${MonetizationService.instance.postCoins} Coins (${access.coinsNeeded} more needed).\n\n'
              'Watch partner video ads to earn Coins!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                label: const Text('Watch Ad (+2 Coins)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (watched == true) {
          final res = await MonetizationService.instance.watchAdForCoins(
            rewardAmount: 2,
            userId: widget.appState.localUserId,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res.message),
                backgroundColor: res.success ? const Color(0xFF059669) : AppColors.error,
              ),
            );
          }
        }
        return;
      }
    }

    if (!mounted) return;
    final canPublish = widget.appState.canPublishDirectly;
    final actionText = !canPublish
        ? 'Submit for Review'
        : (isScheduled ? 'Schedule' : 'Publish');

    final passInfo = needsPassActivation
        ? '\n\n🪙 10 Coins will activate a 2-Day Pass (Post 1 of 2 will be used).'
        : (access.activePass != null
            ? '\n\n🎫 Will use Post ${access.activePass!.postsUsed + 1} of 2 on your active 2-Day Pass (${access.activePass!.remainingTimeString}).'
            : '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText (${_selectedAccountIds.length} Channels)'),
        content: Text(
          !canPublish
              ? 'As an Uploader, this post will be submitted to your workspace review queue for a Social Media Manager or Administrator to approve.'
              : (isScheduled
                  ? 'Are you sure you want to schedule this post for ${DateFormatter.formatToLocal(_scheduledDateTime)} across ${_selectedAccountIds.length} target channels?$passInfo'
                  : 'Are you sure you want to immediately publish this post to ${_selectedAccountIds.length} target channels?$passInfo'),
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
      title: _resolveDerivedPostTitle(),
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

      if (!canPublish) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft "${post.title}" submitted to review queue for approval!'),
            backgroundColor: AppColors.success,
          ),
        );
        return;
      }

      if (canPublish) {
        if (needsPassActivation) {
          await MonetizationService.instance.activateTwoDayPass(
            userId: widget.appState.localUserId,
          );
        }
        await MonetizationService.instance.consumePostOnPass(
          userId: widget.appState.localUserId,
          postId: post.id,
        );
      }

      if (!mounted) return;
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

  // --- WhatsApp-Style Minimal Attach Media Modal & Sub-Sheets ---
  void _showAttachMediaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header & Close
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Attach Media',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(ctx).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Click on below buttons to add your media files.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),

            // Supported Format Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text(
                    'We support images, videos, and PDFs',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Minimal 3 Row x 2 Column WhatsApp-Style Grid
            // Row 1: Upload | Google Drive
            Row(
              children: [
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.upload_file_rounded,
                    label: 'Upload',
                    subtitle: 'Device & Gallery',
                    bgColor: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF4F46E5),
                    borderColor: const Color(0xFFC7D2FE),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _handleSystemUpload();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.add_to_drive_rounded,
                    label: 'Google Drive',
                    subtitle: 'Cloud Storage',
                    bgColor: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFD97706),
                    borderColor: const Color(0xFFFDE68A),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showGoogleDriveSheet();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Google Photos | Stock Photos
            Row(
              children: [
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Google Photos',
                    subtitle: 'Account Library',
                    bgColor: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    borderColor: const Color(0xFFFECACA),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showGooglePhotosSheet();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.image_search_rounded,
                    label: 'Stock Photos',
                    subtitle: 'Unsplash CDN',
                    bgColor: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    borderColor: const Color(0xFFA7F3D0),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showStockPhotosSheet();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: AI Image | Direct Web URL
            Row(
              children: [
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Image',
                    subtitle: 'DALL-E / Gemini',
                    bgColor: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    borderColor: const Color(0xFFDDD6FE),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showAiImageSheet();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWhatsAppMediaActionBtn(
                    icon: Icons.link_rounded,
                    label: 'Direct Web URL',
                    subtitle: 'Link & Preview',
                    bgColor: const Color(0xFFF0F9FF),
                    iconColor: const Color(0xFF0284C7),
                    borderColor: const Color(0xFFBAE6FD),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showDirectWebUrlSheet();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppMediaActionBtn({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: iconColor.withAlpha(200),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Direct System Upload (Android Gallery/Photos picker & Windows File Picker)
  Future<void> _handleSystemUpload() async {
    try {
      final List<PlatformFile> pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'pdf'],
      );

      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final path = file.path;
          final name = file.name;
          final ext = (file.extension ?? '').toLowerCase();
          final isVideo = ['mp4', 'mov', 'm4v', 'avi', 'mkv'].contains(ext);
          final isPdf = ext == 'pdf';
          final mediaType = isVideo ? MediaType.video : MediaType.image;
          final mimeType = isPdf
              ? 'application/pdf'
              : (isVideo ? 'video/mp4' : 'image/${ext == "png" ? "png" : "jpeg"}');

          final newAsset = MediaAsset(
            id: 'media_upload_${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode.abs()}',
            fileName: name,
            mimeType: mimeType,
            sizeBytes: file.lengthSync() ?? 1024 * 1024 * 2,
            mediaType: mediaType,
            localPreviewUrl: path,
            createdAtUtc: DateTime.now().toUtc(),
          );
          widget.appState.addMediaAsset(newAsset);
          _selectedMediaIds.add(newAsset.id);
        }
        setState(() => _activePublishError = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached ${pickedFiles.length} media item(s) from device picker.'),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 2. Real Google Drive Dedicated Sheet
  void _showGoogleDriveSheet() {
    bool isLoading = true;
    String? errorMessage;
    List<Map<String, dynamic>> driveFiles = [];
    bool hasInitialized = false;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.add_to_drive_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 8),
          Text('Google Drive Media'),
        ],
      ),
      builder: (ctx, setSheetState) {
        Future<void> fetchDriveFiles() async {
          setSheetState(() {
            isLoading = true;
            errorMessage = null;
          });

          try {
            final token = await GoogleAuthService.instance.getOrRequestAccessToken(
              additionalScopes: ['https://www.googleapis.com/auth/drive.readonly'],
            );

            if (token == null || token.isEmpty) {
              setSheetState(() {
                isLoading = false;
                errorMessage = 'Google Drive authorization was not granted. Please approve Drive read access to load your files.';
              });
              return;
            }

            final query = Uri.encodeComponent("trashed = false and (mimeType contains 'image/' or mimeType contains 'video/' or mimeType = 'application/pdf')");
            final url = Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=$query&fields=files(id,name,mimeType,size,thumbnailLink,webContentLink,createdTime)&pageSize=30',
            );

            final response = await http.get(
              url,
              headers: {'Authorization': 'Bearer $token'},
            ).timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              final List files = data['files'] as List? ?? [];
              setSheetState(() {
                isLoading = false;
                driveFiles = files.cast<Map<String, dynamic>>();
              });
            } else {
              String errorDetail;
              try {
                final errorBody = jsonDecode(response.body);
                errorDetail = errorBody['error']?['message'] ?? 'Status: ${response.statusCode}';
              } catch (_) {
                errorDetail = 'HTTP ${response.statusCode}: ${response.body}';
              }
              setSheetState(() {
                isLoading = false;
                errorMessage = 'Google Drive API error: $errorDetail';
              });
            }
          } catch (e) {
            setSheetState(() {
              isLoading = false;
              errorMessage = 'Connection error: $e';
            });
          }
        }

        if (!hasInitialized) {
          hasInitialized = true;
          fetchDriveFiles();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account: ${widget.appState.localUserEmail ?? "Connected Google Account"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                  if (!isLoading)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Color(0xFFD97706)),
                      tooltip: 'Refresh Drive Files',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => fetchDriveFiles(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFD97706)),
                      SizedBox(height: 12),
                      Text('Connecting to Google Drive...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ] else if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Text('Google Drive Setup / Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(errorMessage!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => fetchDriveFiles(),
                      icon: const Icon(Icons.lock_open_rounded, size: 16),
                      label: const Text('Authorize & Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ] else if (driveFiles.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('No media files found in Drive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
                    SizedBox(height: 4),
                    Text('Upload photos, videos, or PDFs to your Google Drive to attach them here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ] else ...[
              Text('Files in Drive (${driveFiles.length}):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...driveFiles.map((file) {
                final isVideo = (file['mimeType'] as String? ?? '').contains('video');
                final isPdf = (file['mimeType'] as String? ?? '').contains('pdf');
                final sizeInt = int.tryParse(file['size']?.toString() ?? '') ?? (1024 * 1024 * 2);
                final sizeStr = (sizeInt / (1024 * 1024)).toStringAsFixed(1);
                final thumb = file['thumbnailLink'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: thumb != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              thumb,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                isVideo ? Icons.videocam_rounded : (isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded),
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          )
                        : Icon(
                            isVideo ? Icons.videocam_rounded : (isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded),
                            color: const Color(0xFFD97706),
                          ),
                    title: Text(file['name'] as String? ?? 'Untitled', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    subtitle: Text('$sizeStr MB • ${file['mimeType'] ?? "Media"}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        final newAsset = MediaAsset(
                          id: 'media_drive_${file['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                          fileName: file['name'] as String? ?? 'drive_file',
                          mimeType: file['mimeType'] as String? ?? (isVideo ? 'video/mp4' : 'image/jpeg'),
                          sizeBytes: sizeInt,
                          mediaType: isVideo ? MediaType.video : MediaType.image,
                          localPreviewUrl: file['thumbnailLink'] ?? file['webContentLink'],
                          createdAtUtc: DateTime.now().toUtc(),
                        );
                        widget.appState.addMediaAsset(newAsset);
                        setState(() {
                          _selectedMediaIds.add(newAsset.id);
                          _activePublishError = null;
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Attach', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    );
  }

  // 3. Real Google Photos Dedicated Sheet
  void _showGooglePhotosSheet() {
    bool isLoading = true;
    String? errorMessage;
    String? pickerUri;
    String? pickerSessionId;
    List<Map<String, dynamic>> photoItems = [];
    bool hasInitialized = false;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.photo_library_rounded, color: Color(0xFFDC2626), size: 22),
          SizedBox(width: 8),
          Text('Google Photos Library'),
        ],
      ),
      builder: (ctx, setSheetState) {
        Future<void> fetchPhotos({bool forceReauth = false}) async {
          setSheetState(() {
            isLoading = true;
            errorMessage = null;
          });

          try {
            final token = await GoogleAuthService.instance.getOrRequestAccessToken(
              additionalScopes: [
                'https://www.googleapis.com/auth/photospicker.mediaitems.readonly',
                'https://www.googleapis.com/auth/photoslibrary.readonly',
              ],
              forceRefresh: forceReauth,
            );

            if (token == null || token.isEmpty) {
              setSheetState(() {
                isLoading = false;
                errorMessage = 'Google Photos authorization was not granted. Please approve access to connect your library.';
              });
              return;
            }

            // 1. If we already opened a picker session, check if media was selected
            if (pickerSessionId != null) {
              try {
                final getPickedRes = await http.get(
                  Uri.parse('https://photospicker.googleapis.com/v1/mediaItems?sessionId=$pickerSessionId'),
                  headers: {'Authorization': 'Bearer $token'},
                ).timeout(const Duration(seconds: 12));

                if (getPickedRes.statusCode == 200) {
                  final data = jsonDecode(getPickedRes.body) as Map<String, dynamic>;
                  final List items = data['mediaItems'] as List? ?? [];
                  if (items.isNotEmpty) {
                    final normalized = items.map<Map<String, dynamic>>((it) {
                      final mf = it['mediaFile'] as Map<String, dynamic>? ?? {};
                      final isVideo = (mf['mimeType'] as String? ?? '').startsWith('video/');
                      return {
                        'id': it['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        'filename': mf['filename'] ?? (isVideo ? 'google_video.mp4' : 'google_photo.jpg'),
                        'baseUrl': mf['baseUrl'] ?? '',
                        'isVideo': isVideo,
                      };
                    }).where((m) => (m['baseUrl'] as String).isNotEmpty).toList();

                    setSheetState(() {
                      isLoading = false;
                      photoItems = normalized;
                    });
                    return;
                  }
                }
              } catch (_) {}
            }

            // 2. Attempt Google Photos Picker API Session creation
            try {
              final sessionRes = await http.post(
                Uri.parse('https://photospicker.googleapis.com/v1/sessions'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({}),
              ).timeout(const Duration(seconds: 12));

              if (sessionRes.statusCode == 200) {
                final sessionData = jsonDecode(sessionRes.body) as Map<String, dynamic>;
                pickerUri = sessionData['pickerUri'] as String?;
                pickerSessionId = sessionData['id'] as String?;
              }
            } catch (_) {}

            // 3. Attempt direct query to Photos Library API (if enabled/authorized)
            final url = Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems?pageSize=30');
            final response = await http.get(
              url,
              headers: {'Authorization': 'Bearer $token'},
            ).timeout(const Duration(seconds: 12));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              final List items = data['mediaItems'] as List? ?? [];
              final normalized = items.map<Map<String, dynamic>>((it) {
                return {
                  'id': it['id'] ?? '',
                  'filename': it['filename'] ?? 'photo.jpg',
                  'baseUrl': it['baseUrl'] ?? '',
                  'isVideo': (it['mediaMetadata']?['video'] != null),
                };
              }).toList();

              setSheetState(() {
                isLoading = false;
                photoItems = normalized;
              });
              return;
            }

            // 4. If session created, show Picker CTA
            if (pickerUri != null && pickerUri!.isNotEmpty) {
              setSheetState(() {
                isLoading = false;
              });
              return;
            }

            // 5. Format informative error
            String errorDetail;
            try {
              final errorBody = jsonDecode(response.body);
              errorDetail = errorBody['error']?['message'] ?? 'Status: ${response.statusCode}';
            } catch (_) {
              errorDetail = 'HTTP ${response.statusCode}: ${response.body}';
            }

            setSheetState(() {
              isLoading = false;
              errorMessage = errorDetail;
            });
          } catch (e) {
            setSheetState(() {
              isLoading = false;
              errorMessage = 'Connection error: $e';
            });
          }
        }

        if (!hasInitialized) {
          hasInitialized = true;
          fetchPhotos();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account: ${widget.appState.localUserEmail ?? "Connected Google Account"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                  if (!isLoading)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Color(0xFFDC2626)),
                      tooltip: 'Refresh Photos',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => fetchPhotos(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFDC2626)),
                      SizedBox(height: 12),
                      Text('Connecting to Google Photos...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ] else if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Text('Google Photos Access Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => fetchPhotos(forceReauth: true),
                          icon: const Icon(Icons.lock_open_rounded, size: 16),
                          label: const Text('Authorize & Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://console.cloud.google.com/apis/library');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_browser, size: 16),
                          label: const Text('Cloud Console'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (pickerUri != null && pickerUri!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.photo_library_outlined, color: Color(0xFF2563EB), size: 18),
                          SizedBox(width: 8),
                          Text('Google Photos Picker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select photos from your Google account via Google’s secure picker, then tap "Import Selected" below.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(pickerUri!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Pick Photos in Google'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => fetchPhotos(),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Import Selected'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              if (photoItems.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 36, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('No media found in Google Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
                      SizedBox(height: 4),
                      Text('Take or upload photos to your Google Photos account or pick them above.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ] else ...[
                Text('Google Photos (${photoItems.length}):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...photoItems.map((item) {
                  final filename = item['filename'] as String? ?? 'photo.jpg';
                  final baseUrl = item['baseUrl'] as String? ?? '';
                  final isVideo = (item['isVideo'] == true);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: baseUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                '$baseUrl=w100-h100',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(isVideo ? Icons.videocam : Icons.photo, color: const Color(0xFFDC2626)),
                              ),
                            )
                          : Icon(isVideo ? Icons.videocam : Icons.photo, color: const Color(0xFFDC2626)),
                      title: Text(filename, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: Text(isVideo ? 'Video' : 'Photo'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          final newAsset = MediaAsset(
                            id: 'media_photo_${item['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                            fileName: filename,
                            mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
                            sizeBytes: 1024 * 1024 * 2,
                            mediaType: isVideo ? MediaType.video : MediaType.image,
                            localPreviewUrl: baseUrl,
                            createdAtUtc: DateTime.now().toUtc(),
                          );
                          widget.appState.addMediaAsset(newAsset);
                          setState(() {
                            _selectedMediaIds.add(newAsset.id);
                            _activePublishError = null;
                          });
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Attach', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    );
  }

  // 4. Real Stock Photos Dedicated Sheet (Live Unsplash API Integration)
  void _showStockPhotosSheet() {
    final searchCtrl = TextEditingController(text: 'minimal tech');
    final apiKeyCtrl = TextEditingController(text: EnvConfig.get('UNSPLASH_ACCESS_KEY'));
    String selectedCategory = 'Tech';
    bool isSearching = false;
    bool hasInitialized = false;
    String? searchError;
    bool showKeyInput = false;
    List<Map<String, String>> currentPhotos = [];

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.image_search_rounded, color: Color(0xFF059669), size: 22),
          SizedBox(width: 8),
          Text('Stock Imagery (Unsplash)'),
        ],
      ),
      builder: (ctx, setSheetState) {
        Future<void> executeLiveSearch(String query) async {
          if (query.trim().isEmpty) return;
          setSheetState(() {
            isSearching = true;
            searchError = null;
          });

          var unsplashKey = EnvConfig.get('UNSPLASH_ACCESS_KEY');
          if (unsplashKey.isEmpty) {
            await EnvConfig.init();
            unsplashKey = EnvConfig.get('UNSPLASH_ACCESS_KEY');
          }

          if (unsplashKey.isEmpty) {
            setSheetState(() {
              isSearching = false;
              showKeyInput = true;
              searchError = 'Unsplash Access Key not detected. Enter your Unsplash Access Key below or configure UNSPLASH_ACCESS_KEY in .env.';
            });
            return;
          }

          try {
            final res = await http.get(
              Uri.parse('https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}&per_page=20&client_id=$unsplashKey'),
            ).timeout(const Duration(seconds: 12));

            if (res.statusCode == 200) {
              final json = jsonDecode(res.body) as Map<String, dynamic>;
              final results = json['results'] as List? ?? [];
              final mapped = results.map<Map<String, String>>((r) => {
                'title': (r['description'] ?? r['alt_description'] ?? 'Stock Photo') as String,
                'url': (r['urls']?['regular'] ?? r['urls']?['small'] ?? '') as String,
                'photographer': (r['user']?['name'] ?? 'Unsplash Contributor') as String,
              }).where((m) => (m['url'] ?? '').isNotEmpty).toList();

              setSheetState(() {
                isSearching = false;
                showKeyInput = false;
                currentPhotos = mapped;
              });
            } else {
              String errorMsg = 'HTTP ${res.statusCode}';
              try {
                final errorBody = jsonDecode(res.body);
                if (errorBody['errors'] is List) {
                  errorMsg = (errorBody['errors'] as List).join(', ');
                }
              } catch (_) {}
              setSheetState(() {
                isSearching = false;
                showKeyInput = true;
                searchError = 'Unsplash API error ($errorMsg)';
              });
            }
          } catch (e) {
            setSheetState(() {
              isSearching = false;
              searchError = 'Connection failed: $e';
            });
          }
        }

        if (!hasInitialized) {
          hasInitialized = true;
          executeLiveSearch(searchCtrl.text);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search high-res photos on Unsplash...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF059669)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF059669)),
                  onPressed: () => executeLiveSearch(searchCtrl.text),
                ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) => executeLiveSearch(val),
            ),
            const SizedBox(height: 10),

            // Quick Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tech', 'Business', 'Creative', 'Nature', 'Workspace', 'Architecture'].map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF059669),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setSheetState(() => selectedCategory = cat);
                          searchCtrl.text = cat.toLowerCase();
                          executeLiveSearch(cat.toLowerCase());
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // API Key prompt if missing or failed
            if (showKeyInput || searchError != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            searchError ?? 'Configure Unsplash API Key',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: apiKeyCtrl,
                            decoration: InputDecoration(
                              hintText: 'Paste Unsplash Access Key...',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final key = apiKeyCtrl.text.trim();
                            if (key.isNotEmpty) {
                              await EnvConfig.set('UNSPLASH_ACCESS_KEY', key);
                              executeLiveSearch(searchCtrl.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                          child: const Text('Save & Search', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (isSearching) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF059669)),
                      SizedBox(height: 12),
                      Text('Searching Unsplash live photo library...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ] else if (currentPhotos.isEmpty && searchError == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.image_search_outlined, size: 36, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text('No stock photos found for "${searchCtrl.text}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    const Text('Try searching with different keywords like "workspace", "nature", or "tech".', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ] else ...[
              Text('Unsplash Results (${currentPhotos.length} photos):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...currentPhotos.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['url']!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 64,
                              height: 64,
                              color: AppColors.border,
                              child: const Icon(Icons.broken_image, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Photo by ${item['photographer']} • Unsplash',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final newAsset = MediaAsset(
                              id: 'media_stock_${DateTime.now().millisecondsSinceEpoch}',
                              fileName: '${item['title']!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}.jpg',
                              mimeType: 'image/jpeg',
                              sizeBytes: 1024 * 1024 * 2,
                              mediaType: MediaType.image,
                              localPreviewUrl: item['url']!,
                              createdAtUtc: DateTime.now().toUtc(),
                            );
                            widget.appState.addMediaAsset(newAsset);
                            setState(() {
                              _selectedMediaIds.add(newAsset.id);
                              _activePublishError = null;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Attach', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    );
  }

  // 5. Real AI Image Generation Dedicated Sheet (Direct OpenAI DALL-E & Gemini API)
  void _showAiImageSheet() {
    final promptCtrl = TextEditingController();
    final apiKeyCtrl = TextEditingController(
      text: EnvConfig.get('OPENAI_API_KEY').isNotEmpty
          ? EnvConfig.get('OPENAI_API_KEY')
          : EnvConfig.get('GEMINI_API_KEY'),
    );
    String selectedProvider = 'OpenAI (DALL-E 3)';
    String selectedAspect = '1:1 Square';
    bool isGenerating = false;
    String? apiError;
    bool obscureKey = true;

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 22),
          SizedBox(width: 8),
          Text('AI Image Generation'),
        ],
      ),
      builder: (ctx, setSheetState) {
        Future<void> generateRealAiImage() async {
          final prompt = promptCtrl.text.trim();
          final apiKey = apiKeyCtrl.text.trim();

          if (prompt.isEmpty) {
            setSheetState(() => apiError = 'Please enter an image prompt description.');
            return;
          }
          if (apiKey.isEmpty) {
            setSheetState(() => apiError = 'API Key is required to call the AI image generation model.');
            return;
          }

          setSheetState(() {
            isGenerating = true;
            apiError = null;
          });

          try {
            if (selectedProvider.contains('OpenAI')) {
              // Real OpenAI DALL-E 3 API Request
              final size = selectedAspect.contains('1:1')
                  ? '1024x1024'
                  : (selectedAspect.contains('16:9') ? '1792x1024' : '1024x1792');

              final response = await http.post(
                Uri.parse('https://api.openai.com/v1/images/generations'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $apiKey',
                },
                body: jsonEncode({
                  'model': 'dall-e-3',
                  'prompt': prompt,
                  'n': 1,
                  'size': size,
                  'quality': 'standard',
                }),
              ).timeout(const Duration(seconds: 45));

              if (response.statusCode == 200) {
                final json = jsonDecode(response.body) as Map<String, dynamic>;
                final dataList = json['data'] as List? ?? [];
                if (dataList.isNotEmpty && dataList[0]['url'] != null) {
                  final realImageUrl = dataList[0]['url'] as String;
                  final newAsset = MediaAsset(
                    id: 'media_ai_${DateTime.now().millisecondsSinceEpoch}',
                    fileName: 'dalle_${DateTime.now().millisecondsSinceEpoch}.png',
                    mimeType: 'image/png',
                    sizeBytes: 1024 * 1024 * 3,
                    mediaType: MediaType.image,
                    localPreviewUrl: realImageUrl,
                    createdAtUtc: DateTime.now().toUtc(),
                  );
                  widget.appState.addMediaAsset(newAsset);
                  setState(() {
                    _selectedMediaIds.add(newAsset.id);
                    _activePublishError = null;
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  return;
                }
              }

              // Parse OpenAI error
              String errDetail;
              try {
                final errJson = jsonDecode(response.body);
                errDetail = errJson['error']?['message'] ?? 'HTTP ${response.statusCode}';
              } catch (_) {
                errDetail = 'HTTP ${response.statusCode}: ${response.body}';
              }
              setSheetState(() {
                isGenerating = false;
                apiError = 'OpenAI Error: $errDetail';
              });
            } else {
              // Google Gemini Imagen
              setSheetState(() {
                isGenerating = false;
                apiError = 'Google Imagen 3 API endpoint requires Vertex AI or Google Cloud service credentials. Please select OpenAI (DALL-E 3) with an API key.';
              });
            }
          } catch (e) {
            setSheetState(() {
              isGenerating = false;
              apiError = 'Generation failed: $e';
            });
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct Model Invocation: Calls official AI synthesis endpoints using your API key. Zero fake placeholders.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5B21B6), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (apiError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Text(
                  apiError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                ),
              ),
            ],

            // Model selector
            DropdownButtonFormField<String>(
              initialValue: selectedProvider,
              decoration: const InputDecoration(labelText: 'AI Model / Engine', isDense: true),
              items: const [
                DropdownMenuItem(value: 'OpenAI (DALL-E 3)', child: Text('OpenAI (DALL-E 3)')),
                DropdownMenuItem(value: 'Google (Imagen 3)', child: Text('Google (Imagen 3)')),
              ],
              onChanged: (val) {
                if (val != null) setSheetState(() => selectedProvider = val);
              },
            ),
            const SizedBox(height: 12),

            // API Key
            TextField(
              controller: apiKeyCtrl,
              obscureText: obscureKey,
              decoration: InputDecoration(
                labelText: 'API Secret Key *',
                hintText: selectedProvider.contains('OpenAI') ? 'sk-proj-...' : 'AIzaSy...',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setSheetState(() => obscureKey = !obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Aspect Ratio
            const Text('Aspect Ratio:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['1:1 Square', '16:9 Landscape', '9:16 Vertical'].map((aspect) {
                final isSelected = selectedAspect == aspect;
                return ChoiceChip(
                  label: Text(aspect),
                  selected: isSelected,
                  selectedColor: const Color(0xFF7C3AED),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.ink, fontSize: 11.5),
                  onSelected: (val) {
                    if (val) setSheetState(() => selectedAspect = aspect);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Prompt
            TextField(
              controller: promptCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prompt Description *',
                hintText: 'e.g. Minimalist clean tech workstation with subtle ambient lighting, hyperrealistic...',
              ),
            ),
            const SizedBox(height: 16),

            if (isGenerating) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF7C3AED)),
                      SizedBox(height: 10),
                      Text('Synthesizing image with DALL-E 3...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => generateRealAiImage(),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Generate Real AI Image & Attach'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
      ],
    );
  }

  // 6. Direct Web URL Dedicated Sheet (With Real-Time In-Sheet Live Preview)
  void _showDirectWebUrlSheet() {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    bool isValidMediaUrl(String url) {
      final trimmed = url.trim().toLowerCase();
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) return false;
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !uri.hasAbsolutePath) return false;
      final path = uri.path.toLowerCase();
      return path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.webp') ||
          path.endsWith('.gif') ||
          path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.pdf');
    }

    MediaType detectMediaType(String url) {
      final path = Uri.tryParse(url.trim().toLowerCase())?.path.toLowerCase() ?? '';
      if (path.endsWith('.mp4') || path.endsWith('.mov')) return MediaType.video;
      return MediaType.image;
    }

    AppSheets.showAdaptiveFormSheet(
      context,
      title: const Row(
        children: [
          Icon(Icons.link_rounded, color: Color(0xFF0284C7), size: 22),
          SizedBox(width: 8),
          Text('Attach Direct Web URL'),
        ],
      ),
      builder: (ctx, setSheetState) {
        final url = urlCtrl.text.trim();
        final isValid = isValidMediaUrl(url);
        final detectedType = detectMediaType(url);
        final isPdf = url.toLowerCase().endsWith('.pdf');

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste an absolute web URL ending with an extension (.jpg, .png, .mp4, .pdf) to preview and attach directly.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'Absolute Media URL *',
                hintText: 'https://example.com/media/banner.jpg',
                isDense: true,
                suffixIcon: url.isNotEmpty
                    ? Icon(
                        isValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: isValid ? AppColors.accent : AppColors.warning,
                        size: 20,
                      )
                    : null,
              ),
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File Label (Optional)',
                hintText: 'e.g. promo_header.jpg',
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // Live In-Sheet Preview Box
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValid ? const Color(0xFF0284C7) : AppColors.border,
                  width: isValid ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: isValid
                  ? (isPdf
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 48, color: Color(0xFFDC2626)),
                              SizedBox(height: 8),
                              Text('PDF Document Attached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Click Attach to include in post assets', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : (detectedType == MediaType.video
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_filled_rounded, size: 48, color: Color(0xFF0284C7)),
                                  const SizedBox(height: 8),
                                  const Text('Web MP4 Video Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(url, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          : Image.network(
                              url,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 36, color: AppColors.error),
                                    SizedBox(height: 6),
                                    Text('Unable to load image preview from URL', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                  ],
                                ),
                              ),
                            )))
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_outlined, size: 32, color: AppColors.textSecondary),
                          SizedBox(height: 6),
                          Text(
                            'Live Preview Appears Here',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                          Text(
                            'Must end with .jpg, .png, .webp, .mp4, or .pdf',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final url = urlCtrl.text.trim();
            if (!isValidMediaUrl(url)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter an absolute URL ending with a media extension (.jpg, .png, .mp4, .pdf).'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');
            final isPdf = url.toLowerCase().endsWith('.pdf');
            final mediaType = isVideo ? MediaType.video : MediaType.image;
            final fileName = nameCtrl.text.trim().isNotEmpty
                ? nameCtrl.text.trim()
                : (Uri.tryParse(url)?.pathSegments.isNotEmpty == true
                    ? Uri.tryParse(url)!.pathSegments.last
                    : 'web_asset.png');

            final newAsset = MediaAsset(
              id: 'media_url_${DateTime.now().millisecondsSinceEpoch}',
              fileName: fileName,
              mimeType: isPdf ? 'application/pdf' : (isVideo ? 'video/mp4' : 'image/png'),
              sizeBytes: 1024 * 1024 * 2,
              mediaType: mediaType,
              localPreviewUrl: url,
              createdAtUtc: DateTime.now().toUtc(),
            );
            widget.appState.addMediaAsset(newAsset);
            setState(() {
              _selectedMediaIds.add(newAsset.id);
              _activePublishError = null;
            });
            Navigator.of(ctx).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
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

        final companyAccounts = _selectedBrandId != null
            ? allAccounts.where((a) => a.brandId == _selectedBrandId).toList()
            : allAccounts;

        final selectedAccounts = _selectedAccountIds
            .map((id) => widget.appState.getAccountById(id))
            .whereType<SocialAccount>()
            .toList();

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
              // Active Role Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      widget.appState.currentRole.label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // "My Drafts" Header Action with Count Badge
              Builder(
                builder: (context) {
                  final draftCount = widget.appState.allPosts
                      .where((p) =>
                          p.status == PublishJobStatus.draft ||
                          p.status == PublishJobStatus.needsApproval)
                      .length;
                  return Badge.count(
                    count: draftCount,
                    isLabelVisible: draftCount > 0,
                    backgroundColor: AppColors.accent,
                    child: OutlinedButton.icon(
                      onPressed: _showMyDraftsSheet,
                      icon: const Icon(Icons.drafts_outlined, size: 15),
                      label: const Text('My Drafts'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  child: _buildPublishActionBar(
                    isMobile: true,
                    activeAccount: activeAccount,
                    activePreflight: activePreflight,
                  ),
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

                      // Role Guardrail Banners
                      if (widget.appState.isReadOnly) ...[
                        _buildAnalystReadOnlyBanner(),
                        const SizedBox(height: 14),
                      ] else if (!widget.appState.canPublishDirectly) ...[
                        _buildUploaderQueueNoticeBanner(),
                        const SizedBox(height: 14),
                      ],

                      // Condition Guardrail Check (Google profile must have >=1 company & >=1 channel)
                      if (brands.isEmpty || allAccounts.isEmpty) ...[
                        _buildGuardrailRequirementBanner(brands, allAccounts),
                        const SizedBox(height: 16),
                      ],

                      // 2-Day Publishing Pass Status & Watch Ad Action Card
                      _buildPublishingPassCard(),

                      // WhatsApp-Style Destination Trigger Bar (opens destination & customizer lobby)
                      _buildWhatsAppDestinationBar(
                        brands: brands,
                        brandGroups: brandGroups,
                        allAccounts: allAccounts,
                        companyAccounts: companyAccounts,
                      ),
                      if (_activePublishError != null) ...[
                        const SizedBox(height: 12),
                        _buildActiveErrorBanner(_activePublishError!),
                      ],
                      const SizedBox(height: 18),

                      if (isDesktop) ...[
                        // Dual-Column on desktop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Content Composer & Attached Media Tray
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildContentComposerCard(
                                    selectedAccounts: selectedAccounts,
                                    activeAccount: activeAccount,
                                    allMedia: allMedia,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildPublishActionBar(
                                    activeAccount: activeAccount,
                                    activePreflight: activePreflight,
                                  ),
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
                        // Mobile Layout: Clean stream (Preview button lives in the bottom action bar)
                        _buildContentComposerCard(
                          selectedAccounts: selectedAccounts,
                          activeAccount: activeAccount,
                          allMedia: allMedia,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  // --- Active Publish Error Banner (Rendered below lobby button) ---
  Widget _buildActiveErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Action Required Before Publishing',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  error,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _activePublishError = null),
          ),
        ],
      ),
    );
  }

  // --- 2-Day Publishing Pass Status Card (Shows available posts, coins, and Watch Ad button) ---
  Widget _buildPublishingPassCard() {
    return ListenableBuilder(
      listenable: MonetizationService.instance,
      builder: (context, _) {
        final monetization = MonetizationService.instance;
        final pass = monetization.activePass;
        final isPassActive = pass != null && pass.isValid;
        final coins = monetization.postCoins;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPassActive ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              width: 1.2,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isPassActive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPassActive
                          ? Icons.confirmation_number_rounded
                          : Icons.monetization_on_rounded,
                      color: isPassActive
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isPassActive
                                  ? '2-Day Pass Active'
                                  : 'Publishing Pass Required',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPassActive
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isPassActive
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Text(
                                isPassActive
                                    ? '${pass.postsRemaining} of ${pass.maxPosts} Available'
                                    : '10 Coins = 2 Posts',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isPassActive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPassActive
                              ? 'Valid for multi-platform publishing • Expires in ${pass.remainingTimeString}'
                              : 'In 10 Coins you can post 2 times in 2 days across all channels.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Coin Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 12)),
                        Text(
                          NumberFormatter.formatInt(coins, locale: widget.appState.currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isPassActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: List.generate(pass.maxPosts, (index) {
                    final isUsed = index < pass.postsUsed;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == pass.maxPosts - 1 ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isUsed ? AppColors.surfaceSecondary : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isUsed ? AppColors.border : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUsed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: isUsed ? AppColors.textSecondary : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Post ${index + 1}: ${isUsed ? "Used" : "Available"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isUsed ? AppColors.textSecondary : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ] else ...[
                const SizedBox(height: 10),
                if (coins < 10) ...[
                  // User has less coins -> show Watch Ad button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'You have $coins Coins (${10 - coins} more needed). Watch short ads to earn coins.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isWatchingAdInComposer
                            ? null
                            : () async {
                                setState(() => _isWatchingAdInComposer = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final res = await monetization.watchAdForCoins(
                                  rewardAmount: 2,
                                  userId: widget.appState.localUserId,
                                );
                                if (mounted) {
                                  setState(() => _isWatchingAdInComposer = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? const Color(0xFF059669) : AppColors.error,
                                    ),
                                  );
                                }
                              },
                        icon: _isWatchingAdInComposer
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_circle_filled_rounded, size: 15),
                        label: Text(
                          _isWatchingAdInComposer ? 'Watching...' : 'Watch Ad (+2 Coins)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // User has >= 10 coins -> show Activate Pass button
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ready to activate! Spend 10 Coins for 2 posts over 2 days.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isActivatingPassInComposer
                            ? null
                            : () async {
                                setState(() => _isActivatingPassInComposer = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final res = await monetization.activateTwoDayPass(
                                  userId: widget.appState.localUserId,
                                );
                                if (mounted) {
                                  setState(() => _isActivatingPassInComposer = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? const Color(0xFF059669) : AppColors.error,
                                    ),
                                  );
                                }
                              },
                        icon: _isActivatingPassInComposer
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.bolt_rounded, size: 15),
                        label: Text(
                          _isActivatingPassInComposer ? 'Activating...' : 'Activate Pass (10 Coins)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
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

  // --- Destinations Selection Bar (Compact Company & Channel Avatars) ---
  // --- Role Guardrail Banners ---
  Widget _buildAnalystReadOnlyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral.withAlpha(80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, size: 20, color: AppColors.neutral),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyst Role (Read-Only Mode)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral),
                ),
                Text(
                  'You have read-only access in this workspace. Publishing, scheduling, and editing are disabled.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploaderQueueNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.pending_actions_outlined, size: 20, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Queue Active (Uploader Role)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning),
                ),
                Text(
                  'Posts created by Uploaders are submitted to the review queue for SMM or Manager approval before going live.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WhatsApp Style Destination Bar ---
  Widget _buildWhatsAppDestinationBar({
    required List<Brand> brands,
    required List<ChannelGroup> brandGroups,
    required List<SocialAccount> allAccounts,
    required List<SocialAccount> companyAccounts,
  }) {
    final totalSelected = _selectedAccountIds.length;
    final selectedAccounts = companyAccounts.where((a) => _selectedAccountIds.contains(a.id)).toList();
    final selectedBrand = brands.where((b) => b.id == _selectedBrandId).firstOrNull ?? brands.firstOrNull;

    ChannelGroup? matchedGroup;
    for (final g in brandGroups) {
      if (g.accountIds.isNotEmpty &&
          g.accountIds.length == totalSelected &&
          g.accountIds.every((id) => _selectedAccountIds.contains(id))) {
        matchedGroup = g;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: totalSelected > 0 ? const Color(0xFF25D366).withAlpha(120) : AppColors.border,
          width: totalSelected > 0 ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showWhatsAppDestinationLobby(
            brands: brands,
            brandGroups: brandGroups,
            allAccounts: allAccounts,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar Cluster or WhatsApp Lobby Icon
                _buildAvatarCluster(selectedAccounts),
                const SizedBox(width: 14),

                // Destination Summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              totalSelected == 0
                                  ? 'No destinations selected'
                                  : '$totalSelected Target Channel${totalSelected > 1 ? 's' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: totalSelected == 0 ? AppColors.textSecondary : AppColors.ink,
                              ),
                            ),
                          ),
                          if (totalSelected > 0) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  matchedGroup != null
                                      ? matchedGroup.name
                                      : (selectedAccounts.length == companyAccounts.length && companyAccounts.isNotEmpty
                                          ? 'All Channels'
                                          : 'Custom Target'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF075E54),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalSelected == 0
                            ? 'Tap to open WhatsApp destination lobby & customize targets'
                            : '${selectedBrand?.name ?? 'Company'} • ${selectedAccounts.map((a) => a.displayName).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Manage Destinations Pill / Trigger Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF075E54),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF075E54).withAlpha(40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Lobby',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white70),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCluster(List<SocialAccount> selectedAccounts) {
    if (selectedAccounts.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF075E54).withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF075E54).withAlpha(60)),
        ),
        child: const Icon(Icons.hub_outlined, color: Color(0xFF075E54), size: 22),
      );
    }

    const maxToShow = 3;
    final displayAccounts = selectedAccounts.take(maxToShow).toList();
    final remaining = selectedAccounts.length - maxToShow;

    return SizedBox(
      width: 40.0 + (displayAccounts.length - 1) * 16.0 + (remaining > 0 ? 20.0 : 0.0),
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < displayAccounts.length; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: Center(
                  child: PlatformLogo(platform: displayAccounts[i].platform, size: 16),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayAccounts.length * 16.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF075E54),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WhatsApp-Style Destination Lobby Sheet ---
  void _showWhatsAppDestinationLobby({
    required List<Brand> brands,
    required List<ChannelGroup> brandGroups,
    required List<SocialAccount> allAccounts,
  }) {
    String searchQuery = '';
    String? filterBrandId = _selectedBrandId ?? (brands.isNotEmpty ? brands.first.id : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLobbyState) {
          final scopedAccounts = allAccounts.where((a) {
            final matchesBrand = filterBrandId == null || a.brandId == filterBrandId;
            final matchesQuery = searchQuery.isEmpty ||
                a.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                a.handle.toLowerCase().contains(searchQuery.toLowerCase()) ||
                a.platform.displayName.toLowerCase().contains(searchQuery.toLowerCase());
            return matchesBrand && matchesQuery;
          }).toList();

          final currentCompanyAccounts = allAccounts.where((a) => a.brandId == filterBrandId).toList();
          final allCompanySelected = currentCompanyAccounts.isNotEmpty &&
              currentCompanyAccounts.every((a) => _selectedAccountIds.contains(a.id));

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. WhatsApp Themed Header Bar (#075E54)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF075E54),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Target Channels',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_selectedAccountIds.length} of ${allAccounts.length} channels selected',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        // Platform Specs & Limit Guide Icon
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                          tooltip: 'Platform Specs & Publishing Limits',
                          onPressed: _showAllPlatformSpecsDialog,
                        ),
                        // Select All / Deselect All for current company
                        TextButton(
                          onPressed: () {
                            setLobbyState(() {
                              if (allCompanySelected) {
                                _clearSelection();
                              } else {
                                _selectAllCompanyChannels(currentCompanyAccounts);
                              }
                            });
                          },
                          child: Text(
                            allCompanySelected ? 'Deselect All' : 'Select All',
                            style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. WhatsApp Search Bar
                Container(
                  color: const Color(0xFF075E54),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setLobbyState(() => searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search channel or platform...',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => setLobbyState(() => searchQuery = ''),
                            child: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),

                // 3. Tier 1: Companies / Brands Pills Bar (WhatsApp Community Style)
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        ...brands.map((b) {
                          final isSelectedBrand = filterBrandId == b.id;
                          final brandAccounts = allAccounts.where((a) => a.brandId == b.id).length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              selected: isSelectedBrand,
                              label: Text('${b.name} ($brandAccounts)'),
                              selectedColor: const Color(0xFF075E54),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelectedBrand ? Colors.white : AppColors.textPrimary,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setLobbyState(() {
                                    filterBrandId = b.id;
                                    setState(() => _selectedBrandId = b.id);
                                  });
                                }
                              },
                            ),
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: const Text('Add Company'),
                          onPressed: () {
                            EntityDialogs.showRegisterCompanyDialog(
                              context,
                              widget.appState,
                              onSaved: (nb) {
                                setLobbyState(() {
                                  filterBrandId = nb.id;
                                  setState(() => _selectedBrandId = nb.id);
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Tier 2: Channel Groups Preset Strip
                Container(
                  color: AppColors.surfaceSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open_outlined, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        const Text('Groups: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ...brandGroups.map((g) {
                          final isGroupActive = g.accountIds.isNotEmpty &&
                              g.accountIds.every((id) => _selectedAccountIds.contains(id));
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              selected: isGroupActive,
                              label: Text('${g.name} (${g.accountIds.length})'),
                              selectedColor: const Color(0xFF6366F1).withAlpha(40),
                              checkmarkColor: const Color(0xFF6366F1),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isGroupActive ? const Color(0xFF6366F1) : AppColors.textPrimary,
                              ),
                              onSelected: (val) {
                                setLobbyState(() {
                                  _toggleGroupChannels(g);
                                });
                              },
                            ),
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: const Text('Add Group'),
                          onPressed: () {
                            EntityDialogs.showCreateGroupDialog(
                              context,
                              widget.appState,
                              preselectedBrandId: filterBrandId,
                              onSaved: (newG) {
                                setLobbyState(() {});
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Tier 3: WhatsApp Chat-Style Channel Rows
                Expanded(
                  child: scopedAccounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sensors_off_outlined, size: 44, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No channels match "$searchQuery"'
                                    : 'No social channels registered for this company.',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  EntityDialogs.showConnectChannelDialog(
                                    context,
                                    widget.appState,
                                    preselectedBrandId: filterBrandId,
                                    onSaved: (acc) {
                                      setLobbyState(() {
                                        setState(() {
                                          _selectedAccountIds.add(acc.id);
                                          _activePreviewAccountId = acc.id;
                                        });
                                      });
                                    },
                                  );
                                },
                                icon: const Icon(Icons.add_link),
                                label: const Text('Connect Channel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF075E54),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: scopedAccounts.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                          itemBuilder: (ctx, idx) {
                            final acc = scopedAccounts[idx];
                            final isSelected = _selectedAccountIds.contains(acc.id);
                            final channelGroup = widget.appState.getGroupForAccount(acc.id);
                            final hasOverride = _overrideControllers[acc.id]?.text.trim().isNotEmpty == true &&
                                _overrideControllers[acc.id]?.text.trim() != _sharedCaptionController.text.trim();

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _getPlatformColor(acc.platform).withAlpha(25),
                                    child: Text(
                                      acc.displayName.isNotEmpty ? acc.displayName.substring(0, 1).toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getPlatformColor(acc.platform),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: PlatformLogo(platform: acc.platform, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      acc.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPlatformColor(acc.platform).withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      acc.platform.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getPlatformColor(acc.platform),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      acc.handle.isNotEmpty ? acc.handle : 'Connected Channel',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (channelGroup != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withAlpha(20),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        channelGroup.name,
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                      ),
                                    ),
                                  ],
                                  if (hasOverride) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366).withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Customized Copy',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF075E54)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Override pencil tool
                                  IconButton(
                                    icon: Icon(
                                      hasOverride ? Icons.edit_note : Icons.edit_outlined,
                                      size: 20,
                                      color: hasOverride ? const Color(0xFF075E54) : AppColors.textSecondary,
                                    ),
                                    tooltip: 'Customize copy for this channel',
                                    onPressed: () => _showChannelCustomizerSheet(acc),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: const Color(0xFF25D366),
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setLobbyState(() {
                                        _toggleAccountSelection(acc.id);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setLobbyState(() {
                                  _toggleAccountSelection(acc.id);
                                });
                              },
                            );
                          },
                        ),
                ),

                // 6. Bottom WhatsApp Confirm Destinations FAB Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _selectedAccountIds.isEmpty
                            ? 'Dismiss (No Targets Selected)'
                            : 'Confirm Destinations (${_selectedAccountIds.length} Selected)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Channel-Specific Customizer Sheet ---
  void _showChannelCustomizerSheet(SocialAccount account) {
    if (!_overrideControllers.containsKey(account.id)) {
      _overrideControllers[account.id] = TextEditingController(
        text: _sharedCaptionController.text,
      );
    }
    final ctrl = _overrideControllers[account.id]!;
    final platform = account.platform;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCustomizerState) {
          final maxChars = platform.maxCaptionLength;
          final currentLength = ctrl.text.length;
          final isExceeded = currentLength > maxChars;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      PlatformLogo(platform: platform, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize for ${account.displayName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                            ),
                            Text(
                              '${platform.displayName} • Max $maxChars characters',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Platform specific title for YouTube
                  if (platform == PlatformType.youtube) ...[
                    TextField(
                      controller: _ytTitleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'YouTube Video Title *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Caption Override Box
                  TextField(
                    controller: ctrl,
                    maxLines: 5,
                    onChanged: (_) => setCustomizerState(() {}),
                    decoration: InputDecoration(
                      labelText: '${platform.displayName} Caption Override',
                      hintText: 'Enter platform-tailored caption or leave blank to follow master copy...',
                      border: const OutlineInputBorder(),
                      helperText: '${ctrl.text.length} / $maxChars characters',
                      helperStyle: TextStyle(
                        color: isExceeded ? AppColors.error : AppColors.textSecondary,
                        fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ctrl.text = _sharedCaptionController.text;
                          setState(() {});
                          setCustomizerState(() {});
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset to Master Copy'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sameCaptionEverywhere = false;
                            if (!_selectedAccountIds.contains(account.id)) {
                              _selectedAccountIds.add(account.id);
                            }
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Custom copy saved for ${account.displayName}!'),
                              backgroundColor: const Color(0xFF075E54),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF075E54),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Override'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- "My Drafts" Adaptive Slide-Over Sheet ---
  void _showMyDraftsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDraftsState) {
          final allDrafts = widget.appState.allPosts
              .where((p) =>
                  p.status == PublishJobStatus.draft ||
                  p.status == PublishJobStatus.needsApproval ||
                  p.status == PublishJobStatus.scheduled)
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drafts_outlined, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'My Saved Drafts & Queue (${allDrafts.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Drafts List
                Expanded(
                  child: allDrafts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withAlpha(120)),
                              const SizedBox(height: 12),
                              const Text(
                                'No saved drafts found.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "Save Draft" in the top bar to save any work in progress.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: allDrafts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final draft = allDrafts[idx];
                            final brand = widget.appState.getBrandById(draft.brandId);
                            final isCurrent = widget.initialPost?.id == draft.id;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.accent.withAlpha(10) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent ? AppColors.accent : AppColors.border,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          draft.title.isNotEmpty ? draft.title : 'Untitled Draft',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(status: draft.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    draft.defaultCaption.isNotEmpty
                                        ? draft.defaultCaption
                                        : 'No caption written yet.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (brand != null) ...[
                                        const Icon(Icons.business_outlined, size: 13, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          brand.name,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      const Icon(Icons.hub_outlined, size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${draft.destinationAccountIds.length} target(s)',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const Spacer(),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        tooltip: 'Delete Draft',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('Delete Draft'),
                                              content: Text('Are you sure you want to delete "${draft.title}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(c).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(c).pop(true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            widget.appState.deletePost(draft.id);
                                            setDraftsState(() {});
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      // Load button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _loadDraftIntoComposer(draft);
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Loaded draft "${draft.title}" into composer.'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.upload_file_outlined, size: 14),
                                        label: const Text('Load'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.ink,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _loadDraftIntoComposer(ContentPost post) {
    setState(() {
      _selectedBrandId = post.brandId;
      _titleController.text = post.title;
      _sharedCaptionController.text = post.defaultCaption;
      _campaignController.text = post.campaign ?? '';
      _tagsController.text = post.tags.join(', ');
      _selectedAccountIds.clear();
      _selectedAccountIds.addAll(post.destinationAccountIds);
      _selectedMediaIds.clear();
      _selectedMediaIds.addAll(post.mediaAssetIds);
      _scheduledDateTime = post.scheduledAtUtc;

      _initPlatformControllers(post.title, post.defaultCaption, post.tags.join(', '));

      final variants = widget.appState.getVariantsForPost(post.id);
      _overrideControllers.clear();
      for (final v in variants) {
        if (v.hasCaptionOverride) {
          _overrideControllers[v.socialAccountId] = TextEditingController(
            text: v.captionOverride,
          );
          _sameCaptionEverywhere = false;
        }
      }
      _ensureOverrideControllers();
      if (_selectedAccountIds.isNotEmpty) {
        _activePreviewAccountId = _selectedAccountIds.first;
      }
    });
  }

  // --- Mobile Dedicated Live Preview Sheet ---
  void _showMobilePreviewSheet(SocialAccount? activeAccount, PreflightResult? activePreflight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final effectiveAccount = _activePreviewAccountId != null
              ? widget.appState.getAccountById(_activePreviewAccountId!)
              : activeAccount;
          final preflight = effectiveAccount != null ? _getPreflightForAccount(effectiveAccount) : null;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Platform Preview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Platform Switcher Chips
                if (_selectedAccountIds.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.surfaceSecondary,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedAccountIds.map((accId) {
                          final acc = widget.appState.getAccountById(accId);
                          if (acc == null) return const SizedBox.shrink();
                          final isActive = _activePreviewAccountId == accId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              selected: isActive,
                              avatar: PlatformLogo(platform: acc.platform, size: 14, color: isActive ? Colors.white : null),
                              label: Text(acc.displayName),
                              selectedColor: AppColors.ink,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : AppColors.textPrimary,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _activePreviewAccountId = accId);
                                  setSheetState(() {});
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Preview Mockup & Checklist
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (effectiveAccount != null) ...[
                          PreviewCard(
                            account: effectiveAccount,
                            caption: _getCaptionForAccount(effectiveAccount.id),
                            postTitle: effectiveAccount.platform == PlatformType.youtube
                                ? _ytTitleController.text
                                : _titleController.text,
                            mediaAssets: _attachedMediaAssets,
                          ),
                          const SizedBox(height: 16),
                          if (preflight != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Preflight Checklist (${effectiveAccount.platform.displayName})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: !preflight.isValid ? AppColors.errorBg : AppColors.successBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    !preflight.isValid ? 'BLOCKED' : 'READY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: !preflight.isValid ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            PreflightChecklistView(result: preflight),
                          ],
                        ] else ...[
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
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Color _getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return AppColors.instagram;
      case PlatformType.youtube:
        return AppColors.youtube;
      case PlatformType.linkedin:
        return AppColors.linkedin;
      case PlatformType.x:
        return AppColors.x;
      case PlatformType.facebook:
        return AppColors.facebook;
      case PlatformType.threads:
        return AppColors.threads;
    }
  }

  // --- Dynamic Content Composer Card with Modern Toolbar & Contextual Alerts ---
  Widget _buildContentComposerCard({
    required List<SocialAccount> selectedAccounts,
    required SocialAccount? activeAccount,
    required List<MediaAsset> allMedia,
  }) {
    final activeTabAccount = selectedAccounts.where((a) => a.id == _activeContentTab).firstOrNull;
    final hasYouTube = selectedAccounts.any((a) => a.platform == PlatformType.youtube);
    final hasNonYouTube = selectedAccounts.any((a) => a.platform != PlatformType.youtube);
    final nonYouTubeNames = selectedAccounts
        .where((a) => a.platform != PlatformType.youtube)
        .map((a) => a.platform.displayName)
        .toSet()
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Channel Customization Tabs & Personalize Switch
          if (selectedAccounts.length > 1) ...[
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPlatformTabItem(
                          tabId: 'master',
                          label: 'Shared Post',
                          icon: const Icon(Icons.language, size: 14, color: AppColors.accent),
                          isSelected: _activeContentTab == 'master',
                          onTap: () => setState(() => _activeContentTab = 'master'),
                        ),
                        if (!_sameCaptionEverywhere) ...[
                          ...selectedAccounts.map((acc) {
                            final isSelected = _activeContentTab == acc.id;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildPlatformTabItem(
                                tabId: acc.id,
                                label: acc.displayName,
                                icon: PlatformLogo(
                                  platform: acc.platform,
                                  size: 14,
                                  color: isSelected ? Colors.white : null,
                                ),
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _activeContentTab = acc.id;
                                    _activePreviewAccountId = acc.id;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Personalize',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: !_sameCaptionEverywhere,
                        activeTrackColor: AppColors.accent,
                        onChanged: (val) {
                          setState(() {
                            _sameCaptionEverywhere = !val;
                            if (val) _ensureOverrideControllers();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Editor Body
          if (_activeContentTab == 'master') ...[
            // 1. YouTube Video Title & Tags (Dedicated, only if YouTube selected)
            if (hasYouTube) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PlatformLogo(platform: PlatformType.youtube, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'YouTube Settings',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Video Title Input
                    TextField(
                      controller: _titleController,
                      maxLength: 100,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: 'Video Title *',
                        hintText: 'Enter YouTube video headline...',
                        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        counterText: '${_titleController.text.length} / 100',
                        counterStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _titleController.text.length > 100 ? AppColors.error : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                        ),
                      ),
                      onChanged: (val) {
                        _syncTitleToOthers(_titleController, val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),

                    // Video Tags Input
                    TextField(
                      controller: _ytTagsController,
                      maxLength: 500,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: 'Video Tags (Optional)',
                        hintText: 'Comma-separated (e.g. tech, tutorial, news, product)...',
                        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        counterText: '${_ytTagsController.text.length} / 500',
                        counterStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _ytTagsController.text.length > 500 ? AppColors.error : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                        ),
                      ),
                      onChanged: (val) {
                        _tagsController.text = val;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],

            // 2. Post Copy / Caption Area (Clean, Expansive)
            TextField(
              controller: _sharedCaptionController,
              minLines: 5,
              maxLines: 12,
              style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hasYouTube && hasNonYouTube
                    ? "Write your post... For YouTube, this becomes the video description; for $nonYouTubeNames, it's the post copy. Use #hashtags inline."
                    : (hasYouTube
                        ? 'Describe your video, insert links, timestamps, and discovery #hashtags...'
                        : "What's on your mind? Type # to add hashtags..."),
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onChanged: (val) {
                _syncCaptionToOthers(_sharedCaptionController, val);
                setState(() {});
              },
            ),

            // 3. Integrated Media Attachment Gallery
            _buildIntegratedMediaTray(allMedia, activeAccount),

            // 4. Editor Bottom Action Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: Row(
                children: [
                  // 📷 Add Media
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _selectedMediaIds.isNotEmpty,
                      label: Text('${_selectedMediaIds.length}'),
                      backgroundColor: AppColors.accent,
                      child: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                    ),
                    tooltip: 'Attach Media',
                    color: _selectedMediaIds.isNotEmpty ? AppColors.accent : AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    onPressed: _showAttachMediaModal,
                  ),

                  const Spacer(),

                  // Strictest Limit Counter Pill
                  _buildCompactLimitPill(selectedAccounts),
                ],
              ),
            ),
          ] else if (activeTabAccount != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  PlatformLogo(platform: activeTabAccount.platform, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tailoring copy specifically for ${activeTabAccount.displayName} (${activeTabAccount.platform.displayName}).',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            _buildPlatformDynamicForm(activeTabAccount.platform, activeTabAccount),
            _buildIntegratedMediaTray(allMedia, activeTabAccount),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactLimitPill(List<SocialAccount> selectedAccounts) {
    if (selectedAccounts.isEmpty) return const SizedBox.shrink();

    final textLen = _sharedCaptionController.text.length;
    // Find the most restrictive platform
    PlatformType? strictestPlatform;
    int minLimit = 999999;
    for (final acc in selectedAccounts) {
      if (acc.platform.maxCaptionLength < minLimit) {
        minLimit = acc.platform.maxCaptionLength;
        strictestPlatform = acc.platform;
      }
    }

    if (strictestPlatform == null) return const SizedBox.shrink();

    final isExceeded = textLen > minLimit;
    final isClose = !isExceeded && (minLimit - textLen <= 25);
    final Color badgeColor = isExceeded
        ? AppColors.error
        : (isClose ? AppColors.warning : AppColors.textSecondary);
    final Color badgeBg = isExceeded
        ? AppColors.errorBg
        : (isClose ? AppColors.warningBg : AppColors.surfaceSecondary);

    return InkWell(
      onTap: () => _showPlatformLimitationsDialog(strictestPlatform!),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformLogo(platform: strictestPlatform, size: 12),
            const SizedBox(width: 5),
            Text(
              '$textLen / $minLimit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isExceeded || isClose ? FontWeight.bold : FontWeight.w600,
                color: badgeColor,
              ),
            ),
            if (isExceeded) ...[
              const SizedBox(width: 4),
              const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }



  Widget _buildPlatformTabItem({
    required String tabId,
    required String label,
    Widget? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showPlatformLimitationsDialog(PlatformType platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            PlatformLogo(platform: platform, size: 20),
            const SizedBox(width: 8),
            Text('${platform.displayName} Limits & Specs', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpecRow('Character Limit', '${platform.maxCaptionLength} characters'),
            _buildSpecRow('Hashtags', '${platform.maxHashtags} ${platform == PlatformType.threads ? '(Strict API limit)' : 'maximum'}'),
            _buildSpecRow('Media Support', platform.supportsTextOnly ? 'Text & Media supported' : 'Media strictly required'),
            _buildSpecRow('Photos / Carousel', platform.maxImages > 0 ? 'Up to ${platform.maxImages} photos (Max ${platform.maxImageSizeMb}MB)' : 'Images not supported for uploads'),
            _buildSpecRow('Video Duration', 'Up to ${platform.maxVideoDurationMinutes} mins (Max ${platform.maxVideoSizeBytes ~/ (1024 * 1024)}MB)'),
            _buildSpecRow('Separate Title?', platform == PlatformType.youtube ? 'Yes (Video Title required, max 100 chars)' : 'No (Post copy used directly)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  void _showAllPlatformSpecsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rule_folder_outlined, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Social Platform Publishing Specs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: PlatformType.values.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                          PlatformLogo(platform: p, size: 16),
                          const SizedBox(width: 6),
                          Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                          const Spacer(),
                          Text(
                            p.supportsTextOnly ? 'Text + Media' : 'Media Required',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: p.supportsTextOnly ? const Color(0xFF0D9488) : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Copy: ${p.maxCaptionLength} chars max\n'
                        '• Hashtags: ${p.maxHashtags} max ${p == PlatformType.threads ? '(API restricted to 1)' : ''}\n'
                        '• Media: ${p.maxImages > 0 ? 'Up to ${p.maxImages} photos (${p.maxImageSizeMb}MB)' : 'Video only'}\n'
                        '• Video: Max ${p.maxVideoDurationMinutes} mins (${p.maxVideoSizeBytes ~/ (1024 * 1024)}MB limit)\n'
                        '• Title: ${p == PlatformType.youtube ? 'Video Title required (max 100)' : 'No title field (feed post)'}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  // --- Integrated Media Attachment Tray (Compact & Horizontal Scroll) ---
  Widget _buildIntegratedMediaTray(List<MediaAsset> allMedia, SocialAccount? targetAccount) {
    final attachedAssets = _attachedMediaAssets;

    if (attachedAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 84,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...attachedAssets.map((asset) => _buildMediaAssetTile(asset)),
            // Add More Tile
            InkWell(
              onTap: _showAttachMediaModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 76,
                height: 84,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20, color: AppColors.accent),
                    SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaAssetTile(MediaAsset asset) {
    final isVideo = asset.mediaType == MediaType.video;
    final previewUrl = asset.localPreviewUrl;

    Widget content;
    if (!isVideo && previewUrl != null && previewUrl.isNotEmpty) {
      Widget img;
      if (previewUrl.startsWith('http://') || previewUrl.startsWith('https://')) {
        img = Image.network(
          previewUrl,
          fit: BoxFit.cover,
          width: 104,
          height: 84,
          errorBuilder: (_, _, _) => _buildFallbackTileContent(asset),
        );
      } else if (!kIsWeb) {
        final f = File(previewUrl);
        if (f.existsSync()) {
          img = Image.file(
            f,
            fit: BoxFit.cover,
            width: 104,
            height: 84,
            errorBuilder: (_, _, _) => _buildFallbackTileContent(asset),
          );
        } else {
          img = _buildFallbackTileContent(asset);
        }
      } else {
        img = _buildFallbackTileContent(asset);
      }

      content = Stack(
        fit: StackFit.expand,
        children: [
          img,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: Colors.black.withValues(alpha: 0.65),
              child: Text(
                '${asset.fileName} • ${asset.formattedSize}',
                style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    } else if (isVideo) {
      Widget videoFallback = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 22),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black.withValues(alpha: 0.7),
                child: Text(
                  '${asset.fileName} • ${asset.formattedSize}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );

      if (previewUrl != null && previewUrl.isNotEmpty) {
        final isImageExt = previewUrl.endsWith('.jpg') ||
            previewUrl.endsWith('.jpeg') ||
            previewUrl.endsWith('.png') ||
            previewUrl.endsWith('.webp');

        if (isImageExt && (previewUrl.startsWith('http://') || previewUrl.startsWith('https://'))) {
          content = Stack(
            fit: StackFit.expand,
            children: [
              Image.network(previewUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => videoFallback),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Text(
                    '${asset.fileName} • ${asset.formattedSize}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Native video thumbnail extraction from local video file
          content = FutureBuilder<Uint8List?>(
            future: VideoThumbnailService.getThumbnail(previewUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(snapshot.data!, fit: BoxFit.cover),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Text(
                          '${asset.fileName} • ${asset.formattedSize}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return videoFallback;
            },
          );
        }
      } else {
        content = videoFallback;
      }
    } else {
      content = _buildFallbackTileContent(asset);
    }

    return Container(
      width: 104,
      height: 84,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isVideo ? Colors.black87 : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _toggleMediaSelection(asset.id),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTileContent(MediaAsset asset) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            asset.mediaType == MediaType.video ? Icons.videocam : Icons.image_outlined,
            size: 22,
            color: asset.mediaType == MediaType.video ? Colors.redAccent : AppColors.accent,
          ),
          const SizedBox(height: 4),
          Text(
            asset.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          Text(
            asset.formattedSize,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
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
          onChanged: (val) => _syncTitleToOthers(_ytTitleController, val),
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
          onChanged: (val) => _syncCaptionToOthers(_ytDescriptionController, val),
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
                onChanged: (val) => _tagsController.text = val,
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
          onChanged: (val) => _syncCaptionToOthers(_igCaptionController, val),
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
            _syncCaptionToOthers(_xTextController, val);
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
          onChanged: (val) => _syncCaptionToOthers(_liCommentaryController, val),
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
          onChanged: (val) => _syncCaptionToOthers(_fbTextController, val),
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
            _syncCaptionToOthers(_threadsTextController, val);
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
                  : _titleController.text,
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
  // --- Publish & Schedule Action Bar ---
  Widget _buildPublishActionBar({
    bool isMobile = false,
    SocialAccount? activeAccount,
    PreflightResult? activePreflight,
  }) {
    final isReadOnly = widget.appState.isReadOnly;
    final isScheduled = _scheduledDateTime != null;
    final canPublish = widget.appState.canPublishDirectly;
    final isPendingApproval = widget.initialPost?.status == PublishJobStatus.needsApproval;

    final String actionLabel;
    final IconData actionIcon;

    if (isReadOnly) {
      actionLabel = 'Read-Only (Analyst)';
      actionIcon = Icons.lock_outline;
    } else if (!canPublish) {
      actionLabel = isScheduled ? 'Submit Schedule' : 'Submit for Review';
      actionIcon = Icons.rate_review_outlined;
    } else if (isPendingApproval) {
      actionLabel = isScheduled ? 'Approve & Schedule' : 'Approve & Publish';
      actionIcon = Icons.check_circle_outline;
    } else {
      actionLabel = isScheduled ? 'Schedule' : 'Publish Now';
      actionIcon = isScheduled ? Icons.schedule_send : Icons.send;
    }

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
                      onPressed: isReadOnly ? null : () => setState(() => _scheduledDateTime = null),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                // Dedicated Live Preview Sheet Trigger on Mobile (Icon only)
                IconButton.outlined(
                  onPressed: () => _showMobilePreviewSheet(activeAccount, activePreflight),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'Preview',
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),

                // Save Draft (Icon only)
                IconButton.outlined(
                  onPressed: isReadOnly ? null : _saveDraft,
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  tooltip: 'Save Draft',
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(12),
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
                      color: isReadOnly ? AppColors.surfaceSecondary : AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                      border: isReadOnly ? Border.all(color: AppColors.border) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isReadOnly ? null : _submitPublish,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    actionIcon,
                                    size: 16,
                                    color: isReadOnly ? AppColors.textSecondary : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    actionLabel,
                                    style: TextStyle(
                                      color: isReadOnly ? AppColors.textSecondary : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isReadOnly) ...[
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
                    onPressed: isReadOnly ? null : () => setState(() => _scheduledDateTime = null),
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
              // Save Draft Button (Icon only)
              IconButton.outlined(
                onPressed: isReadOnly ? null : _saveDraft,
                icon: const Icon(Icons.bookmark_outline, size: 18),
                tooltip: 'Save Draft',
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(12),
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
                  color: isReadOnly ? AppColors.surfaceSecondary : AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  border: isReadOnly ? Border.all(color: AppColors.border) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: isReadOnly ? null : _submitPublish,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        child: Row(
                          children: [
                            Icon(
                              actionIcon,
                              size: 16,
                              color: isReadOnly ? AppColors.textSecondary : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              actionLabel,
                              style: TextStyle(
                                color: isReadOnly ? AppColors.textSecondary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isReadOnly) ...[
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
