import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:no5ocial/core/services/google_auth_service.dart';
import 'package:no5ocial/core/services/passkey_service.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/core/utils/input_validator.dart';
import 'package:no5ocial/core/utils/string_sanitizer.dart';
import 'package:no5ocial/core/services/currency_service.dart';
import 'package:no5ocial/core/services/country_service.dart';
import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/group_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/publishing_adapter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/audit_event.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_attempt.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';
import 'package:no5ocial/data/repositories/org_member_repository.dart';
import 'package:no5ocial/domain/enums/org_role.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/domain/models/org_member.dart';
import 'package:no5ocial/core/services/firebase_sync_service.dart';
import 'package:no5ocial/core/services/monetization_service.dart';

class AppState extends ChangeNotifier {
  final BrandRepository brandRepository;
  final AccountRepository accountRepository;
  final PostRepository postRepository;
  final JobRepository jobRepository;
  final AuditRepository auditRepository;
  final GroupRepository groupRepository;
  final OrgMemberRepository orgMemberRepository;
  final PublishingAdapter? publishingAdapter;

  final _uuid = const Uuid();

  // Active filters and settings
  String? selectedBrandFilterId;
  PublishJobStatus? selectedStatusFilter;
  String searchQuery = '';
  String userTimezone = 'Local (UTC+5:30)';
  Locale currentLocale = const Locale('en');

  // Country & Regional Settings (Auto-assigned per IP or saved in SQLite)
  CountryProfile _selectedCountry = CountryService.getByCode('IN');
  CountryProfile get selectedCountry => _selectedCountry;
  String get userCountryCode => _selectedCountry.code;

  // Currency settings (Auto-derived from Selected Country, or loaded from DB)
  String _userCurrency = 'USD';
  String _userCurrencySymbol = '\$';
  String get userCurrency => _userCurrency;
  String get userCurrencySymbol => _userCurrencySymbol;

  Future<void> initCountryAndLocalization() async {
    try {
      final country = await CountryService.instance.getOrDetectCountry();
      _selectedCountry = country;
      _userCurrency = country.currencyCode;
      _userCurrencySymbol = country.currencySymbol;

      // Check SQLite for user preference
      final savedLocale = await AppDatabase.instance.getSetting('app_locale');
      final langCode = savedLocale ?? country.defaultLanguageCode;
      currentLocale = supportedLocales.firstWhere(
        (l) => l.languageCode == langCode,
        orElse: () => Locale(country.defaultLanguageCode),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('AppState: Error initializing country & localization: $e');
    }
  }

  Future<void> setSelectedCountry(String countryCode) async {
    final country = CountryService.getByCode(countryCode);
    _selectedCountry = country;
    _userCurrency = country.currencyCode;
    _userCurrencySymbol = country.currencySymbol;
    currentLocale = supportedLocales.firstWhere(
      (l) => l.languageCode == country.defaultLanguageCode,
      orElse: () => const Locale('en'),
    );
    notifyListeners();

    // 1. Authoritative persistent storage in local SQLite database
    await CountryService.instance.saveCountryToDb(country.code);

    // 2. Cloud Firestore multi-device sync
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSettings(localUserId!, {
        'user_country_code': country.code,
        'user_currency': country.currencyCode,
        'user_currency_symbol': country.currencySymbol,
        'app_locale': country.defaultLanguageCode,
      });
    }
  }

  Future<void> initCurrency() => initCountryAndLocalization();

  Future<void> setUserCurrency(String code) async {
    final info = CurrencyService.getByCode(code);
    _userCurrency = info.code;
    _userCurrencySymbol = info.symbol;
    notifyListeners();
    await CurrencyService.instance.saveCurrency(info.code);
    await AppDatabase.instance.setSetting('user_currency', info.code);
    await AppDatabase.instance.setSetting('user_currency_symbol', info.symbol);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSettings(localUserId!, {
        'user_currency': info.code,
        'user_currency_symbol': info.symbol,
      });
    }
  }

  // Theme settings (Default to light mode)
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _saveThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveThemeMode();
  }

  Future<void> _saveThemeMode() async {
    try {
      final modeStr = _themeMode == ThemeMode.dark ? 'dark' : 'light';
      await AppDatabase.instance.setSetting('theme_mode', modeStr);
      if (localUserId != null && localUserId!.isNotEmpty) {
        FirebaseSyncService.instance.pushSettings(localUserId!, {
          'theme_mode': modeStr,
        });
      }
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> loadSavedThemeMode() async {
    try {
      final saved = await AppDatabase.instance.getSetting('theme_mode');
      if (saved != null) {
        _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  // Workspace Mode (Solo vs Team Hierarchy)
  WorkspaceMode _workspaceMode = WorkspaceMode.solo;
  WorkspaceMode get workspaceMode => _workspaceMode;
  bool get isTeamMode => _workspaceMode.isTeam;

  Future<void> setWorkspaceMode(WorkspaceMode mode) async {
    _workspaceMode = mode;
    notifyListeners();
    try {
      await AppDatabase.instance.setSetting('workspace_mode', mode.name);
      if (localUserId != null && localUserId!.isNotEmpty) {
        FirebaseSyncService.instance.pushSettings(localUserId!, {
          'workspace_mode': mode.name,
        });
      }
    } catch (e) {
      debugPrint('Error saving workspace mode: $e');
    }
  }

  Future<void> loadSavedWorkspaceMode() async {
    try {
      final saved = await AppDatabase.instance.getSetting('workspace_mode');
      if (saved != null) {
        _workspaceMode = WorkspaceMode.fromString(saved);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading workspace mode: $e');
    }
  }

  /// Indicates if the workspace welcome popup should be shown on the next dashboard render.
  bool shouldShowWelcomeDialog = false;

  // Local authentication state (Stored in persistent SessionService & local SQLite)
  bool isLoggedIn = false;
  bool isSessionExpired = false;
  String? maskedEmail;
  String? localUserName;
  String? localUserEmail;
  String? localUserPhotoUrl;
  String? localUserId;
  String? localUserProvider;
  Map<String, dynamic>? localUserData;

  // Biometric & Security Settings
  bool isBiometricLockEnabled = false;
  int lockTimeoutSeconds = 0; // 0 = Immediately, 120 = 2 minutes
  int registeredPasskeysCount = 0;
  bool hasCompletedOnboarding = false;

  Future<void> signInLocally({
    required String name,
    required String email,
    String? photoUrl,
    String? id,
    String provider = 'google',
    String? accessToken,
    String? idToken,
    String? serverAuthCode,
    Map<String, dynamic>? rawData,
  }) async {
    final sanitizedName = InputValidator.sanitize(name);
    final safeName = sanitizedName.length > InputValidator.maxBrandNameLength
        ? sanitizedName.substring(0, InputValidator.maxBrandNameLength)
        : sanitizedName;

    final sanitizedEmail = InputValidator.sanitize(email);
    final safeEmail = sanitizedEmail.length > InputValidator.maxEmailLength
        ? sanitizedEmail.substring(0, InputValidator.maxEmailLength)
        : sanitizedEmail;

    final sanitizedId = id != null ? InputValidator.sanitize(id) : null;
    final safeId = (sanitizedId != null && sanitizedId.isNotEmpty)
        ? (sanitizedId.length > 100 ? sanitizedId.substring(0, 100) : sanitizedId)
        : 'local_${DateTime.now().millisecondsSinceEpoch}';

    isLoggedIn = true;
    isSessionExpired = false;
    hasCompletedOnboarding = true;
    localUserName = safeName;
    localUserEmail = safeEmail;
    localUserPhotoUrl = photoUrl;
    localUserId = safeId;
    localUserProvider = provider;
    localUserData = rawData;
    maskedEmail = SessionService.instance.getMaskedEmail(safeEmail);
    notifyListeners();

    try {
      await SessionService.instance.saveSession(
        id: safeId,
        name: safeName,
        email: safeEmail,
        photoUrl: photoUrl,
        provider: provider,
        rawData: rawData,
      );
      await SessionService.instance.setCompletedOnboarding(true);
      await MonetizationService.instance.loadUserWallet(safeId);
      await syncWithCloud(force: true);
      await ensureDefaultBrandExists();
    } catch (e) {
      debugPrint('Error saving session to SessionService: $e');
    }

    try {
      await AppDatabase.instance.saveUserProfile(
        id: safeId,
        name: safeName,
        email: safeEmail,
        photoUrl: photoUrl,
        provider: provider,
        rawData: rawData != null ? jsonEncode(rawData) : null,
      );
    } catch (e) {
      debugPrint('Error saving user profile to SQLite: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleAuthService.instance.signOut();
    } catch (e) {
      debugPrint('GoogleAuthService signOut error: $e');
    }

    isLoggedIn = false;
    isSessionExpired = false;
    localUserName = null;
    localUserEmail = null;
    localUserPhotoUrl = null;
    localUserId = null;
    localUserProvider = null;
    localUserData = null;
    maskedEmail = null;
    MonetizationService.instance.clearUserWallet();
    notifyListeners();

    try {
      await SessionService.instance.clearSession();
    } catch (e) {
      debugPrint('Error clearing session from SessionService: $e');
    }

    try {
      await AppDatabase.instance.clearUserProfile();
    } catch (e) {
      debugPrint('Error clearing user profile from SQLite: $e');
    }
  }

  /// Bidirectional synchronization with Firebase Cloud Firestore.
  /// Pulls remote workspace documents (brands, accounts, posts, groups, settings)
  Future<FirebaseSyncResult?> syncWithCloud({bool force = false}) async {
    final uid = (localUserId != null && localUserId!.isNotEmpty)
        ? localUserId!
        : (localUserEmail != null && localUserEmail!.isNotEmpty)
            ? localUserEmail!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
            : 'default_workspace';
    try {
      final res = await FirebaseSyncService.instance.syncUserWorkspace(
        uid,
        forceHydration: force,
      );
      if (res.success) {
        if (brandRepository is SqliteBrandRepository) {
          await (brandRepository as SqliteBrandRepository).init();
        }
        if (accountRepository is SqliteAccountRepository) {
          await (accountRepository as SqliteAccountRepository).init();
        }
        if (postRepository is SqlitePostRepository) {
          await (postRepository as SqlitePostRepository).init();
        }
        if (jobRepository is SqliteJobRepository) {
          await (jobRepository as SqliteJobRepository).init();
        }
        if (groupRepository is SqliteGroupRepository) {
          await (groupRepository as SqliteGroupRepository).init();
        }
        await loadSavedThemeMode();
        await loadSavedWorkspaceMode();
        await initOrgMembers();
        await initCurrency();
        await MonetizationService.instance.loadUserWallet(uid);
        notifyListeners();
      }
      return res;
    } catch (e) {
      debugPrint('AppState.syncWithCloud error: $e');
      return null;
    }
  }

  Future<void> loadSavedUserProfile() async {
    try {
      // 1. First attempt to load from persistent SessionService (localStorage / XML prefs)
      final session = await SessionService.instance.getSession();
      if (session != null) {
        final expired = await SessionService.instance.isSessionExpired();
        final email = session['email'] as String?;
        maskedEmail = SessionService.instance.getMaskedEmail(email);

        if (expired) {
          isLoggedIn = true; // Retain identity for the expiration notice
          isSessionExpired = true;
        } else {
          isLoggedIn = true;
          isSessionExpired = false;
        }

        localUserId = session['id'] as String?;
        localUserName = session['name'] as String?;
        localUserEmail = email;
        localUserPhotoUrl = session['photo_url'] as String?;
        localUserProvider = session['provider'] as String?;
        localUserData = session['raw_data'] as Map<String, dynamic>?;

        await loadSecuritySettings();
        hasCompletedOnboarding = await SessionService.instance.hasCompletedOnboarding();
        if (localUserId != null && localUserId!.isNotEmpty) {
          await MonetizationService.instance.loadUserWallet(localUserId!);
        }
        await syncWithCloud();
        if (brands.isEmpty) {
          final cachedBrands = await SessionService.instance.getBrandsCache();
          for (final b in cachedBrands) {
            brandRepository.saveBrand(b);
          }
        }
        if (isLoggedIn && brands.isEmpty) {
          await ensureDefaultBrandExists();
        }
        notifyListeners();
        return;
      }

      // 2. Fallback to SQLite (and migrate to SessionService if exists)
      final profile = await AppDatabase.instance.getUserProfile();
      if (profile != null) {
        final email = profile['email'] as String?;
        localUserId = profile['id'] as String?;
        localUserName = profile['name'] as String?;
        localUserEmail = email;
        localUserPhotoUrl = profile['photo_url'] as String?;
        localUserProvider = profile['provider'] as String?;
        if (profile['raw_data'] != null) {
          try {
            final decoded = jsonDecode(profile['raw_data'] as String);
            if (decoded is Map<String, dynamic>) {
              localUserData = decoded;
            }
          } catch (_) {}
        }

        isLoggedIn = true;
        isSessionExpired = false;
        maskedEmail = SessionService.instance.getMaskedEmail(email);

        if (localUserId != null && email != null) {
          await SessionService.instance.saveSession(
            id: localUserId!,
            name: localUserName ?? '',
            email: email,
            photoUrl: localUserPhotoUrl,
            provider: localUserProvider ?? 'google',
            rawData: localUserData,
          );
        }

        await loadSecuritySettings();
        hasCompletedOnboarding = await SessionService.instance.hasCompletedOnboarding();
        if (localUserId != null && localUserId!.isNotEmpty) {
          await MonetizationService.instance.loadUserWallet(localUserId!);
        }
        await syncWithCloud();
        if (brands.isEmpty) {
          final cachedBrands = await SessionService.instance.getBrandsCache();
          for (final b in cachedBrands) {
            brandRepository.saveBrand(b);
          }
        }
        if (isLoggedIn && brands.isEmpty) {
          await ensureDefaultBrandExists();
        }
        _sanitizeBrandNames();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Automatically provision or restore a primary company brand for authenticated users
  Future<void> ensureDefaultBrandExists() async {
    if (brands.isNotEmpty) {
      _sanitizeBrandNames();
      hasCompletedOnboarding = true;
      await SessionService.instance.saveBrandsCache(brands);
      await SessionService.instance.setCompletedOnboarding(true);
      await initOrgMembers();
      await ensureDefaultOrgOwner();
      return;
    }

    final cached = await SessionService.instance.getBrandsCache();
    if (cached.isNotEmpty) {
      for (final b in cached) {
        brandRepository.saveBrand(b);
      }
      _sanitizeBrandNames();
      hasCompletedOnboarding = true;
      await SessionService.instance.setCompletedOnboarding(true);
      await initOrgMembers();
      await ensureDefaultOrgOwner();
      notifyListeners();
      return;
    }

    if (isLoggedIn) {
      final brand = createBrand(
        name: 'Shaadow',
        description: 'Primary company brand',
      );
      hasCompletedOnboarding = true;
      await SessionService.instance.saveBrandsCache([brand]);
      await SessionService.instance.setCompletedOnboarding(true);
      await initOrgMembers();
      await ensureDefaultOrgOwner();
      notifyListeners();
    }
  }

  /// Ensures company names are clean and never corrupted with synthetic "'s Workspace" suffixes
  void _sanitizeBrandNames() {
    for (final b in brands) {
      if (b.name.contains("'s Workspace") || b.name == 'My Workspace' || b.name == 'Personal Workspace') {
        final cleaned = b.name
            .replaceAll(RegExp(r"'s Workspace$| Workspace$"), "")
            .replaceAll('My Workspace', 'Shaadow')
            .replaceAll('Personal Workspace', 'Shaadow')
            .trim();
        final finalName = (cleaned.isEmpty || cleaned == 'My' || cleaned == localUserName?.trim())
            ? 'Shaadow'
            : cleaned;
        final updated = b.copyWith(name: finalName);
        brandRepository.updateBrand(updated);
      }
    }
  }

  Future<void> loadSecuritySettings() async {
    try {
      isBiometricLockEnabled = await SessionService.instance.isBiometricLockEnabled();
      lockTimeoutSeconds = await SessionService.instance.getLockTimeoutSeconds();
      final passkeys = await PasskeyService.instance.getRegisteredPasskeys();
      registeredPasskeysCount = passkeys.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }
  }

  Future<void> setBiometricLockEnabled(bool enabled) async {
    isBiometricLockEnabled = enabled;
    await SessionService.instance.setBiometricLockEnabled(enabled);
    notifyListeners();
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    lockTimeoutSeconds = seconds;
    await SessionService.instance.setLockTimeoutSeconds(seconds);
    notifyListeners();
  }

  Future<void> refreshPasskeysCount() async {
    try {
      final passkeys = await PasskeyService.instance.getRegisteredPasskeys();
      registeredPasskeysCount = passkeys.length;
      notifyListeners();
    } catch (_) {}
  }

  AppState({
    required this.brandRepository,
    required this.accountRepository,
    required this.postRepository,
    required this.jobRepository,
    required this.auditRepository,
    GroupRepository? groupRepository,
    OrgMemberRepository? orgMemberRepository,
    this.publishingAdapter,
  })  : groupRepository = groupRepository ?? InMemoryGroupRepository(),
        orgMemberRepository = orgMemberRepository ?? SqliteOrgMemberRepository();

  // Accessors
  List<Brand> get brands => brandRepository.getAllBrands();
  List<SocialAccount> get accounts => accountRepository.getAllAccounts();
  List<SocialAccount> getAccountsByBrand(String brandId) =>
      accountRepository.getAllAccounts().where((a) => a.brandId == brandId).toList();
  List<MediaAsset> get mediaAssets => postRepository.getAllMediaAssets();
  List<ChannelGroup> get groups => groupRepository.getAllGroups();

  List<ChannelGroup> getGroupsByBrand(String brandId) =>
      groupRepository.getGroupsByBrand(brandId);
  ChannelGroup? getGroupById(String id) => groupRepository.getGroupById(id);

  List<ContentPost> get allPosts => postRepository.getAllPosts();

  List<ContentPost> get filteredPosts {
    var list = postRepository.getAllPosts();

    if (selectedBrandFilterId != null) {
      list = list.where((p) => p.brandId == selectedBrandFilterId).toList();
    }

    if (selectedStatusFilter != null) {
      list = list.where((p) => p.status == selectedStatusFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.defaultCaption.toLowerCase().contains(query) ||
            (p.campaign?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    return list;
  }

  List<PublishJob> get allJobs => jobRepository.getAllJobs();

  List<PublishJob> get pendingAndFailedJobs {
    return allJobs
        .where(
          (j) =>
              j.status == PublishJobStatus.actionRequired ||
              j.status == PublishJobStatus.failed ||
              j.status == PublishJobStatus.scheduled,
        )
        .toList();
  }

  List<PublishJob> getJobsForPost(String postId) {
    return jobRepository.getJobsByPostId(postId);
  }

  List<PostVariant> getVariantsForPost(String postId) {
    return postRepository.getVariantsForPost(postId);
  }

  Brand? getBrandById(String id) => brandRepository.getBrandById(id);
  SocialAccount? getAccountById(String id) =>
      accountRepository.getAccountById(id);
  MediaAsset? getMediaAssetById(String id) =>
      postRepository.getMediaAssetById(id);

  // Summary Metrics
  int get draftCount =>
      allPosts.where((p) => p.status == PublishJobStatus.draft).length;
  int get scheduledCount =>
      allPosts.where((p) => p.status == PublishJobStatus.scheduled).length;
  int get publishedCount =>
      allPosts.where((p) => p.status == PublishJobStatus.published).length;
  int get actionRequiredCount => allJobs
      .where(
        (j) =>
            j.status == PublishJobStatus.actionRequired ||
            j.status == PublishJobStatus.failed,
      )
      .length;

  // Filter modifiers
  void setBrandFilter(String? brandId) {
    selectedBrandFilterId = brandId;
    notifyListeners();
  }

  void setStatusFilter(PublishJobStatus? status) {
    selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // --- Role-Based Access Control (RBAC) & Team Management ---

  String? get activeBrandId => selectedBrandFilterId ?? (brands.isNotEmpty ? brands.first.id : null);

  Brand? get activeBrand =>
      brands.cast<Brand?>().firstWhere((b) => b?.id == activeBrandId, orElse: () => (brands.isNotEmpty ? brands.first : null));

  /// Current user's role in the active organization/workspace
  OrgRole get currentRole {
    if (_workspaceMode == WorkspaceMode.solo) return OrgRole.owner;
    final orgId = activeBrandId;
    final uid = localUserId;
    if (orgId == null || uid == null) return OrgRole.owner;
    final member = orgMemberRepository.getMemberByUser(orgId, uid);
    return member?.role ?? OrgRole.owner;
  }

  /// Whether current role can publish posts directly to live social platforms
  bool get canPublishDirectly => currentRole.canPublishDirectly;

  /// Whether current role can upload media and create drafts
  bool get canCreateDrafts => currentRole.canCreateDrafts;

  /// Whether current role can edit drafts created by other members
  bool get canEditOthersDrafts => currentRole.canEditOthersDrafts;

  /// Whether current role can approve draft submissions from Uploaders
  bool get canApproveSubmissions => currentRole.canApproveSubmissions;

  /// Whether current role can link, reconnect, or manage channels and groups
  bool get canManageChannels => currentRole.canManageChannels;

  /// Whether current role can invite and remove team members (up to SMM)
  bool get canInviteMembers => currentRole.canInviteMembers;

  /// Whether current role can invite or promote other Managers
  bool get canInviteManagers => currentRole.canInviteManagers;

  /// Whether current role can create or delete brands/companies
  bool get canManageBrands => currentRole.canManageBrands;

  /// Whether current role can delete the organization or transfer ownership
  bool get canDeleteOrg => currentRole.canDeleteOrg;

  /// Whether current role is restricted to read-only metrics and calendar viewing
  bool get isReadOnly => currentRole.isReadOnly;

  List<OrgMember> get teamMembers {
    final orgId = activeBrandId;
    if (orgId == null) return const [];
    return orgMemberRepository.getMembers(orgId);
  }

  List<OrgInvite> get pendingInvites {
    final orgId = activeBrandId;
    if (orgId == null) return const [];
    return orgMemberRepository.getInvites(orgId);
  }

  Future<void> initOrgMembers() async {
    final orgId = activeBrandId;
    if (orgId != null && orgMemberRepository is SqliteOrgMemberRepository) {
      await (orgMemberRepository as SqliteOrgMemberRepository).init(orgId);
      notifyListeners();
    }
  }

  /// Automatically provisions the owner membership for the first user
  Future<void> ensureDefaultOrgOwner() async {
    final orgId = activeBrandId;
    final uid = localUserId;
    final email = localUserEmail;
    final name = (localUserName != null && localUserName!.isNotEmpty) ? localUserName! : 'Workspace Lead';
    if (orgId == null || uid == null || email == null) return;

    final existing = orgMemberRepository.getMemberByUser(orgId, uid);
    if (existing == null) {
      final owner = OrgMember(
        id: _uuid.v4(),
        orgId: orgId,
        userId: uid,
        userEmail: email,
        userName: name,
        userPhotoUrl: localUserPhotoUrl,
        role: OrgRole.owner,
        joinedAtUtc: DateTime.now().toUtc(),
      );
      orgMemberRepository.saveMember(owner);
      notifyListeners();
    }
  }

  /// Fetch an invite by its unique token
  Future<OrgInvite?> getInviteByToken(String token) async {
    if (token.trim().isEmpty) return null;
    return await orgMemberRepository.findInviteByToken(token.trim());
  }

  /// Invites a new team member with an assigned role and optional brand scoping.
  /// Returns the newly created OrgInvite so the inviter can copy or share the link.
  Future<OrgInvite?> inviteMember({
    required String email,
    required OrgRole role,
    List<String>? brandScope,
  }) async {
    final orgId = activeBrandId;
    final uid = localUserId ?? 'local_owner';
    if (orgId == null) return null;

    final invite = OrgInvite(
      id: _uuid.v4(),
      orgId: orgId,
      token: _uuid.v4().replaceAll('-', ''),
      invitedEmail: email.trim().toLowerCase(),
      invitedRole: role,
      brandScope: brandScope,
      invitedByUserId: uid,
      createdAtUtc: DateTime.now().toUtc(),
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(days: 7)),
      status: InviteStatus.pending,
    );

    orgMemberRepository.saveInvite(invite);
    notifyListeners();
    return invite;
  }

  /// Accepts an invitation, joins the user to the organization with their assigned role,
  /// and switches active workspace to the invited brand.
  Future<bool> acceptInvite({
    required OrgInvite invite,
    required String userId,
    required String userEmail,
    required String userName,
    String? userPhotoUrl,
  }) async {
    if (invite.invitedEmail.trim().toLowerCase() != userEmail.trim().toLowerCase()) {
      return false;
    }
    if (!invite.isValid) {
      return false;
    }

    final newMember = OrgMember(
      id: _uuid.v4(),
      orgId: invite.orgId,
      userId: userId,
      userEmail: userEmail.trim().toLowerCase(),
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      role: invite.invitedRole,
      brandScope: invite.brandScope,
      invitedByUserId: invite.invitedByUserId,
      joinedAtUtc: DateTime.now().toUtc(),
      isActive: true,
    );

    orgMemberRepository.saveMember(newMember);
    orgMemberRepository.updateInviteStatus(invite.id, InviteStatus.accepted);

    // If invited user does not have this brand loaded in local list yet, fetch from database
    final existingBrand = brands.cast<Brand?>().firstWhere((b) => b?.id == invite.orgId, orElse: () => null);
    if (existingBrand == null) {
      final brandFromDb = await AppDatabase.instance.getBrand(invite.orgId);
      if (brandFromDb != null) {
        brandRepository.saveBrand(brandFromDb);
        await SessionService.instance.saveBrandsCache(brands);
      }
    }

    setBrandFilter(invite.orgId);
    await initOrgMembers();

    auditRepository.recordEvent(
      AuditEvent(
        id: _uuid.v4(),
        actor: userEmail,
        eventType: 'TEAM_INVITE_ACCEPTED',
        entityType: 'ORG_MEMBER',
        entityId: newMember.id,
        description: 'Accepted invitation as ${invite.invitedRole.label}',
        metadataSanitized: {
          'invite_id': invite.id,
          'role': invite.invitedRole.name,
        },
        createdAtUtc: DateTime.now().toUtc(),
      ),
    );

    notifyListeners();
    return true;
  }

  Future<void> revokeInvite(String inviteId) async {
    orgMemberRepository.updateInviteStatus(inviteId, InviteStatus.revoked);
    notifyListeners();
  }

  Future<void> removeTeamMember(String memberId) async {
    orgMemberRepository.removeMember(memberId);
    notifyListeners();
  }

  Future<void> updateMemberRole(String memberId, OrgRole newRole) async {
    final orgId = activeBrandId;
    if (orgId == null) return;
    final members = orgMemberRepository.getMembers(orgId);
    final target = members.cast<OrgMember?>().firstWhere((m) => m?.id == memberId, orElse: () => null);
    if (target != null) {
      final updated = target.copyWith(role: newRole);
      orgMemberRepository.saveMember(updated);
      notifyListeners();
    }
  }

  // --- Core CRUD Operations ---

  /// Creates or updates a ContentPost along with its per-destination variants.
  ContentPost saveDraft({
    String? postId,
    required String brandId,
    required String title,
    required String defaultCaption,
    List<String> destinationAccountIds = const [],
    List<String> mediaAssetIds = const [],
    List<String> tags = const [],
    String? campaign,
    DateTime? scheduledAtUtc,
    PublishJobStatus? status,
    Map<String, String>? captionOverridesByAccount,
  }) {
    final now = DateTime.now().toUtc();
    final effectiveId = postId ?? _uuid.v4();

    final post = ContentPost(
      id: effectiveId,
      brandId: brandId,
      title: title,
      defaultCaption: defaultCaption,
      destinationAccountIds: destinationAccountIds,
      mediaAssetIds: mediaAssetIds,
      tags: tags,
      campaign: campaign,
      status: status ??
          (scheduledAtUtc != null
              ? PublishJobStatus.scheduled
              : PublishJobStatus.draft),
      scheduledAtUtc: scheduledAtUtc,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    postRepository.savePost(post);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushPost(localUserId!, post);
    }

    // Save or update variants
    for (final accId in destinationAccountIds) {
      final override = captionOverridesByAccount?[accId];
      final existingVariant = postRepository.getVariant(effectiveId, accId);

      final variant = PostVariant(
        id: existingVariant?.id ?? _uuid.v4(),
        contentPostId: effectiveId,
        socialAccountId: accId,
        captionOverride: override,
        mediaAssetIds: mediaAssetIds,
      );
      postRepository.saveVariant(variant);
    }

    _recordAudit(
      eventType: postId == null ? 'DRAFT_CREATED' : 'DRAFT_UPDATED',
      entityType: 'ContentPost',
      entityId: effectiveId,
      description:
          'Draft "$title" saved with ${destinationAccountIds.length} destination(s).',
    );

    notifyListeners();
    return post;
  }

  /// Initiates independent publishing or queueing across all selected destinations.
  /// Enforces: Each destination has an independent publish job and status.
  /// A failed destination must NOT erase successful publishes to other destinations.
  Future<List<PublishJob>> publishOrQueuePost({
    required ContentPost post,
    Map<String, String>? captionOverridesByAccount,
    bool isScheduled = false,
  }) async {
    final now = DateTime.now().toUtc();
    final createdJobs = <PublishJob>[];
    final postBrand = brandRepository.getBrandById(post.brandId);

    // Save/update the post
    postRepository.savePost(
      post.copyWith(
        status: isScheduled
            ? PublishJobStatus.scheduled
            : PublishJobStatus.publishing,
        updatedAtUtc: now,
      ),
    );

    final attachedMedia = post.mediaAssetIds
        .map((id) => postRepository.getMediaAssetById(id))
        .whereType<MediaAsset>()
        .toList();

    for (final accountId in post.destinationAccountIds) {
      final account = accountRepository.getAccountById(accountId);
      if (account == null) continue;

      final variant =
          postRepository.getVariant(post.id, accountId) ??
          PostVariant(
            id: _uuid.v4(),
            contentPostId: post.id,
            socialAccountId: accountId,
            captionOverride: captionOverridesByAccount?[accountId],
            mediaAssetIds: post.mediaAssetIds,
          );
      postRepository.saveVariant(variant);

      // Preflight validation
      final preflight = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: account,
        postBrand: postBrand,
        accountBrand: brandRepository.getBrandById(account.brandId),
        attachedMedia: attachedMedia,
      );

      final jobId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      if (!preflight.isValid) {
        // Blocked by preflight
        final firstBlocker = preflight.blockers.first;
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.actionRequired,
          isManual: account.isManualOnly,
          idempotencyKey: idempotencyKey,
          lastErrorCode: firstBlocker.code,
          lastErrorCategory: ErrorCategory.validation,
          lastErrorMessage: firstBlocker.message,
          lastErrorAtUtc: now,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      if (isScheduled) {
        // Enqueue scheduled job
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.scheduled,
          isManual: account.isManualOnly,
          scheduledAtUtc:
              post.scheduledAtUtc ?? now.add(const Duration(hours: 2)),
          idempotencyKey: idempotencyKey,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      if (account.isManualOnly) {
        // Needs manual handoff
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.actionRequired,
          isManual: true,
          idempotencyKey: idempotencyKey,
          lastErrorCode: 'MANUAL_HANDOFF_REQUIRED',
          lastErrorCategory: ErrorCategory.unknown,
          lastErrorMessage:
              'Manual publishing handoff required for ${account.platform.displayName}.',
          lastErrorAtUtc: now,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      // Live publishing attempt via adapter
      final initialJob = PublishJob(
        id: jobId,
        contentPostId: post.id,
        postVariantId: variant.id,
        socialAccountId: accountId,
        status: PublishJobStatus.publishing,
        attemptCount: 1,
        idempotencyKey: idempotencyKey,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
      jobRepository.saveJob(initialJob);

      // Record pre-execution attempt per ARCHITECTURE.md
      jobRepository.recordAttempt(
        PublishAttempt(
          id: _uuid.v4(),
          publishJobId: jobId,
          startedAtUtc: now,
          outcomeStatus: PublishJobStatus.publishing,
          providerRequestId: 'req_$idempotencyKey',
        ),
      );

      if (publishingAdapter != null) {
        try {
          final result = await publishingAdapter!.publishNow(
            post: post,
            variant: variant,
            account: account,
            idempotencyKey: idempotencyKey,
            attachedMedia: attachedMedia,
          );

          final finishedNow = DateTime.now().toUtc();
          if (result.isSuccess) {
            final finishedJob = initialJob.copyWith(
              status: PublishJobStatus.published,
              publishedAtUtc: finishedNow,
              externalPostId: result.externalPostId,
              externalUrl: result.externalUrl,
              updatedAtUtc: finishedNow,
            );
            jobRepository.saveJob(finishedJob);
            createdJobs.add(finishedJob);

            jobRepository.recordAttempt(
              PublishAttempt(
                id: _uuid.v4(),
                publishJobId: jobId,
                startedAtUtc: now,
                finishedAtUtc: finishedNow,
                outcomeStatus: PublishJobStatus.published,
                providerRequestId: result.externalPostId,
              ),
            );
          } else {
            final failedJob = initialJob.copyWith(
              status: PublishJobStatus.failed,
              lastErrorCode: result.rawErrorCode,
              lastErrorCategory: result.errorCategory,
              lastErrorMessage: result.sanitizedErrorMessage,
              lastErrorAtUtc: finishedNow,
              updatedAtUtc: finishedNow,
            );
            jobRepository.saveJob(failedJob);
            createdJobs.add(failedJob);

            jobRepository.recordAttempt(
              PublishAttempt(
                id: _uuid.v4(),
                publishJobId: jobId,
                startedAtUtc: now,
                finishedAtUtc: finishedNow,
                outcomeStatus: PublishJobStatus.failed,
                errorCategory: result.errorCategory,
                sanitizedError: result.sanitizedErrorMessage,
              ),
            );
          }
        } catch (e) {
          final finishedNow = DateTime.now().toUtc();
          final failedJob = initialJob.copyWith(
            status: PublishJobStatus.failed,
            lastErrorCode: 'EXCEPTION',
            lastErrorCategory: ErrorCategory.unknown,
            lastErrorMessage: StringSanitizer.redact(e.toString()),
            lastErrorAtUtc: finishedNow,
            updatedAtUtc: finishedNow,
          );
          jobRepository.saveJob(failedJob);
          createdJobs.add(failedJob);
        }
      } else {
        // No adapter connected, mark as action required
        final job = initialJob.copyWith(
          status: PublishJobStatus.actionRequired,
          lastErrorMessage:
              'No live publishing adapter configured for this platform.',
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
      }
    }

    _updateMasterPostStatus(post.id);
    notifyListeners();
    return createdJobs;
  }

  /// Completes a manual publishing handoff.
  /// Enforces: "Mark as manually published only after user confirmation; optionally capture the post URL. Clearly label it Manual, never pretend it was API-published."
  PublishJob confirmManualHandoff({
    required String jobId,
    String? externalPostUrl,
  }) {
    final updated = jobRepository.markJobManuallyPublished(
      jobId: jobId,
      externalUrl: externalPostUrl,
      externalPostId: 'manual_${_uuid.v4().substring(0, 8)}',
    );

    _recordAudit(
      eventType: 'MANUAL_PUBLISH_CONFIRMED',
      entityType: 'PublishJob',
      entityId: jobId,
      description:
          'Operator confirmed manual publication. URL: ${externalPostUrl ?? "N/A"}',
      metadata: {'is_manual': true, 'url': externalPostUrl},
    );

    _updateMasterPostStatus(updated.contentPostId);
    notifyListeners();
    return updated;
  }

  /// Retries a failed publish job after verifying duplicate safety.
  Future<PublishJob?> retryJob({
    required String jobId,
    bool forceDuplicateWarningAccepted = false,
  }) async {
    final job = jobRepository.getJobById(jobId);
    if (job == null) return null;

    if (job.hasDuplicateRiskOnRetry && !forceDuplicateWarningAccepted) {
      throw StateError(
        'DUPLICATE_RISK: Outcome is ambiguous. Confirmation required to prevent duplicate post.',
      );
    }

    final now = DateTime.now().toUtc();
    final retryingJob = job.copyWith(
      status: PublishJobStatus.publishing,
      attemptCount: job.attemptCount + 1,
      updatedAtUtc: now,
    );
    jobRepository.saveJob(retryingJob);
    notifyListeners();

    final account = accountRepository.getAccountById(job.socialAccountId);
    final post = postRepository.getPostById(job.contentPostId);
    final variant = postRepository.getVariant(
      job.contentPostId,
      job.socialAccountId,
    );

    if (publishingAdapter != null &&
        account != null &&
        post != null &&
        variant != null) {
      final attachedMedia = post.mediaAssetIds
          .map((id) => postRepository.getMediaAssetById(id))
          .whereType<MediaAsset>()
          .toList();

      final result = await publishingAdapter!.publishNow(
        post: post,
        variant: variant,
        account: account,
        idempotencyKey: '${job.idempotencyKey}_retry_${job.attemptCount + 1}',
        attachedMedia: attachedMedia,
      );

      final finishedNow = DateTime.now().toUtc();
      if (result.isSuccess) {
        final finished = retryingJob.copyWith(
          status: PublishJobStatus.published,
          publishedAtUtc: finishedNow,
          externalPostId: result.externalPostId,
          externalUrl: result.externalUrl,
          updatedAtUtc: finishedNow,
        );
        jobRepository.saveJob(finished);
        _updateMasterPostStatus(post.id);
        notifyListeners();
        return finished;
      } else {
        final failed = retryingJob.copyWith(
          status: PublishJobStatus.failed,
          lastErrorCode: result.rawErrorCode,
          lastErrorCategory: result.errorCategory,
          lastErrorMessage: result.sanitizedErrorMessage,
          lastErrorAtUtc: finishedNow,
          updatedAtUtc: finishedNow,
        );
        jobRepository.saveJob(failed);
        _updateMasterPostStatus(post.id);
        notifyListeners();
        return failed;
      }
    }

    notifyListeners();
    return retryingJob;
  }

  void updateAccountConnection(String accountId, ConnectionStatus status) {
    accountRepository.updateConnectionStatus(accountId, status);
    final updated = accountRepository.getAccountById(accountId);
    if (updated != null && localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSocialAccount(localUserId!, updated);
    }
    _recordAudit(
      eventType: 'ACCOUNT_STATUS_CHANGED',
      entityType: 'SocialAccount',
      entityId: accountId,
      description: 'Account status updated to ${status.label}.',
    );
    notifyListeners();
  }

  void updateAccount(SocialAccount account) {
    accountRepository.saveAccount(account);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSocialAccount(localUserId!, account);
    }
    _recordAudit(
      eventType: 'ACCOUNT_UPDATED',
      entityType: 'SocialAccount',
      entityId: account.id,
      description: 'Account ${account.handle} (${account.displayName}) updated.',
    );
    notifyListeners();
  }

  // --- Brand / Company Management ---
  Brand createBrand({
    required String name,
    String? slug,
    String? description,
    String? websiteUrl,
    String? logoUrl,
    String? companySize,
    String? industry,
    String? foundUsVia,
  }) {
    final cleanName = InputValidator.sanitize(name);
    final safeName = cleanName.length > InputValidator.maxBrandNameLength
        ? cleanName.substring(0, InputValidator.maxBrandNameLength)
        : cleanName;

    final resolvedSlug = (slug != null && slug.trim().isNotEmpty)
        ? slug.trim().toLowerCase()
        : InputValidator.generateDynamicSlug(
            name: safeName,
            userHandle: localUserEmail?.split('@').first,
            existingSlugs: brands.map((b) => b.slug).toList(),
          );

    final cleanSlug = InputValidator.sanitize(resolvedSlug).toLowerCase();
    final safeSlug = cleanSlug.length > InputValidator.maxBrandSlugLength
        ? cleanSlug.substring(0, InputValidator.maxBrandSlugLength)
        : cleanSlug;

    final cleanDesc = description != null ? InputValidator.sanitize(description) : null;
    final safeDesc = (cleanDesc != null && cleanDesc.isNotEmpty)
        ? (cleanDesc.length > InputValidator.maxDescriptionLength
            ? cleanDesc.substring(0, InputValidator.maxDescriptionLength)
            : cleanDesc)
        : null;

    final cleanUrl = websiteUrl != null ? InputValidator.sanitize(websiteUrl) : null;
    final safeUrl = (cleanUrl != null && cleanUrl.isNotEmpty)
        ? (cleanUrl.length > InputValidator.maxWebsiteUrlLength
            ? cleanUrl.substring(0, InputValidator.maxWebsiteUrlLength)
            : cleanUrl)
        : null;

    final brand = Brand(
      id: 'brand_${_uuid.v4().substring(0, 8)}',
      name: safeName,
      slug: safeSlug,
      description: safeDesc,
      websiteUrl: safeUrl,
      companySize: companySize,
      industry: industry,
      foundUsVia: foundUsVia,
      createdAtUtc: DateTime.now().toUtc(),
    );
    brandRepository.saveBrand(brand);
    SessionService.instance.saveBrandsCache(brands);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushBrand(localUserId!, brand);
    }
    _recordAudit(
      eventType: 'BRAND_CREATED',
      entityType: 'Brand',
      entityId: brand.id,
      description: 'Registered company ${brand.name} (Size: ${companySize ?? 'unspecified'}, Industry: ${industry ?? 'unspecified'}).',
    );
    notifyListeners();
    return brand;
  }

  void updateBrand(Brand brand) {
    brandRepository.saveBrand(brand);
    SessionService.instance.saveBrandsCache(brands);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushBrand(localUserId!, brand);
    }
    _recordAudit(
      eventType: 'BRAND_UPDATED',
      entityType: 'Brand',
      entityId: brand.id,
      description: 'Updated company/brand ${brand.name}.',
    );
    notifyListeners();
  }

  void deleteBrand(String brandId) {
    final b = brandRepository.getBrandById(brandId);
    brandRepository.deleteBrand(brandId);
    SessionService.instance.saveBrandsCache(brands);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.deleteBrand(localUserId!, brandId);
    }
    _recordAudit(
      eventType: 'BRAND_DELETED',
      entityType: 'Brand',
      entityId: brandId,
      description: 'Deleted brand ${b?.name ?? brandId}.',
    );
    notifyListeners();
  }

  // --- Platform / Account Management ---
  SocialAccount connectAccount({
    required String brandId,
    required PlatformType platform,
    required String displayName,
    required String handle,
    String? avatarUrl,
    String? externalAccountId,
    bool isManualOnly = false,
    String? targetGroupId,
    String? newGroupName,
    List<String> capabilities = const ['post', 'caption', 'image', 'video'],
    List<String> scopes = const ['publish_posts', 'read_insights'],
  }) {
    final cleanDisplayName = InputValidator.sanitize(displayName);
    final safeDisplayName = cleanDisplayName.length > InputValidator.maxDisplayNameLength
        ? cleanDisplayName.substring(0, InputValidator.maxDisplayNameLength)
        : cleanDisplayName;

    final cleanHandle = InputValidator.sanitize(handle);
    final strippedHandle = cleanHandle.startsWith('@') ? cleanHandle.substring(1) : cleanHandle;
    final safeHandlePart = strippedHandle.length > InputValidator.maxHandleLength
        ? strippedHandle.substring(0, InputValidator.maxHandleLength)
        : strippedHandle;
    final formattedHandle = '@$safeHandlePart';

    final account = SocialAccount(
      id: 'acc_${platform.name}_${_uuid.v4().substring(0, 8)}',
      brandId: brandId,
      platform: platform,
      displayName: safeDisplayName,
      handle: formattedHandle,
      externalAccountId: externalAccountId,
      connectionStatus: ConnectionStatus.connected,
      capabilities: isManualOnly ? const ['manual_handoff', 'caption', 'image', 'video'] : capabilities,
      scopes: isManualOnly ? const ['manual_workflow'] : scopes,
      lastVerifiedAtUtc: DateTime.now().toUtc(),
      isManualOnly: isManualOnly,
    );
    accountRepository.saveAccount(account);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSocialAccount(localUserId!, account);
    }

    // If user requested placing this account into an existing or new channel group
    if (targetGroupId != null && targetGroupId.isNotEmpty) {
      addAccountToGroup(targetGroupId, account.id);
    } else if (newGroupName != null && newGroupName.trim().isNotEmpty) {
      createGroup(
        brandId: brandId,
        name: newGroupName.trim(),
        description: 'Auto-created bundle with ${account.displayName}',
        accountIds: [account.id],
      );
    }

    _recordAudit(
      eventType: 'ACCOUNT_CONNECTED',
      entityType: 'SocialAccount',
      entityId: account.id,
      description: 'Connected ${platform.displayName} profile ${account.handle} (${isManualOnly ? "Manual Handoff" : "Live OAuth/API"}).',
    );
    notifyListeners();
    return account;
  }

  void addAccountToGroup(String groupId, String accountId) {
    final group = groupRepository.getGroupById(groupId);
    if (group != null && !group.accountIds.contains(accountId)) {
      final updated = group.copyWith(
        accountIds: [...group.accountIds, accountId],
      );
      updateGroup(updated);
    }
  }

  /// Returns the group that contains this account ID, if any.
  ChannelGroup? getGroupForAccount(String accountId) {
    for (final g in groups) {
      if (g.accountIds.contains(accountId)) return g;
    }
    return null;
  }

  /// Sets or clears the group for an account (moves between groups or makes standalone).
  void setAccountGroup(String accountId, String? targetGroupId) {
    for (final g in groups) {
      if (g.accountIds.contains(accountId)) {
        final updated = g.copyWith(
          accountIds: g.accountIds.where((id) => id != accountId).toList(),
        );
        updateGroup(updated);
      }
    }
    if (targetGroupId != null && targetGroupId.isNotEmpty && targetGroupId != 'standalone') {
      addAccountToGroup(targetGroupId, accountId);
    }
  }

  void deleteAccount(String accountId) {
    final acc = accountRepository.getAccountById(accountId);
    accountRepository.deleteAccount(accountId);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.deleteSocialAccount(localUserId!, accountId);
    }
    for (final g in groups) {
      if (g.accountIds.contains(accountId)) {
        final updatedGroup = g.copyWith(
          accountIds: g.accountIds.where((id) => id != accountId).toList(),
        );
        updateGroup(updatedGroup);
      }
    }
    _recordAudit(
      eventType: 'ACCOUNT_DISCONNECTED',
      entityType: 'SocialAccount',
      entityId: accountId,
      description: 'Disconnected social account ${acc?.handle ?? accountId}.',
    );
    notifyListeners();
  }

  // --- Channel Groups Management ---
  ChannelGroup createGroup({
    required String brandId,
    required String name,
    String? description,
    required List<String> accountIds,
  }) {
    final group = ChannelGroup(
      id: 'group_${_uuid.v4().substring(0, 8)}',
      brandId: brandId,
      name: name.trim(),
      description: description?.trim(),
      accountIds: accountIds,
      createdAtUtc: DateTime.now().toUtc(),
    );
    groupRepository.saveGroup(group);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushGroup(localUserId!, group);
    }
    _recordAudit(
      eventType: 'CHANNEL_GROUP_CREATED',
      entityType: 'ChannelGroup',
      entityId: group.id,
      description: 'Created channel group "${group.name}" with ${accountIds.length} profiles.',
    );
    notifyListeners();
    return group;
  }

  void updateGroup(ChannelGroup group) {
    groupRepository.saveGroup(group);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushGroup(localUserId!, group);
    }
    _recordAudit(
      eventType: 'CHANNEL_GROUP_UPDATED',
      entityType: 'ChannelGroup',
      entityId: group.id,
      description: 'Updated channel group "${group.name}".',
    );
    notifyListeners();
  }

  void deleteGroup(String groupId) {
    final g = groupRepository.getGroupById(groupId);
    groupRepository.deleteGroup(groupId);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.deleteGroup(localUserId!, groupId);
    }
    _recordAudit(
      eventType: 'CHANNEL_GROUP_DELETED',
      entityType: 'ChannelGroup',
      entityId: groupId,
      description: 'Deleted channel group "${g?.name ?? groupId}".',
    );
    notifyListeners();
  }

  // --- Media Asset Registration ---
  void addMediaAsset(MediaAsset asset) {
    postRepository.saveMediaAsset(asset);
    _recordAudit(
      eventType: 'MEDIA_ASSET_UPLOADED',
      entityType: 'MediaAsset',
      entityId: asset.id,
      description: 'Uploaded media asset ${asset.fileName}.',
    );
    notifyListeners();
  }

  void deletePost(String postId) {
    postRepository.deletePost(postId);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.deletePost(localUserId!, postId);
    }
    final jobs = jobRepository.getJobsByPostId(postId);
    for (final j in jobs) {
      jobRepository.deleteJob(j.id);
    }
    _recordAudit(
      eventType: 'POST_DELETED',
      entityType: 'ContentPost',
      entityId: postId,
      description: 'Deleted post and associated jobs.',
    );
    notifyListeners();
  }

  void setTimezone(String tz) {
    userTimezone = tz;
    notifyListeners();
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('ar'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
    Locale('hi'),
    Locale('it'),
    Locale('ru'),
    Locale('nl'),
    Locale('tr'),
    Locale('pl'),
    Locale('id'),
    Locale('sv'),
    Locale('da'),
    Locale('uk'),
    Locale('ms'),
  ];

  static const Map<String, String> localeDisplayNames = {
    'en': 'English',
    'es': 'Español',
    'ar': 'العربية',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'ja': '日本語',
    'zh': '中文',
    'ko': '한국어',
    'hi': 'हिन्दी',
    'it': 'Italiano',
    'ru': 'Русский',
    'nl': 'Nederlands',
    'tr': 'Türkçe',
    'pl': 'Polski',
    'id': 'Bahasa Indonesia',
    'sv': 'Svenska',
    'da': 'Dansk',
    'uk': 'Українська',
    'ms': 'Bahasa Melayu',
  };

  void setLocale(Locale locale) {
    currentLocale = locale;
    notifyListeners();
    AppDatabase.instance.setSetting('app_locale', locale.languageCode);
    if (localUserId != null && localUserId!.isNotEmpty) {
      FirebaseSyncService.instance.pushSettings(localUserId!, {
        'app_locale': locale.languageCode,
      });
    }
  }

  /// Cycles through all supported locales in order.
  void cycleLocale() {
    final currentIndex = supportedLocales.indexWhere(
      (l) => l.languageCode == currentLocale.languageCode,
    );
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    currentLocale = supportedLocales[nextIndex];
    notifyListeners();
  }

  /// Legacy toggle kept for compatibility; now cycles all 4 languages.
  void toggleLocale() => cycleLocale();


  void _updateMasterPostStatus(String postId) {
    final post = postRepository.getPostById(postId);
    if (post == null) return;

    final jobs = jobRepository.getJobsByPostId(postId);
    if (jobs.isEmpty) return;

    final allPublished = jobs.every(
      (j) => j.status == PublishJobStatus.published,
    );
    final anyFailed = jobs.any((j) => j.status == PublishJobStatus.failed);
    final anyAction = jobs.any(
      (j) => j.status == PublishJobStatus.actionRequired,
    );
    final anyPublishing = jobs.any(
      (j) => j.status == PublishJobStatus.publishing,
    );
    final anyScheduled = jobs.any(
      (j) => j.status == PublishJobStatus.scheduled,
    );

    PublishJobStatus overall;
    if (allPublished) {
      overall = PublishJobStatus.published;
    } else if (anyFailed || anyAction) {
      overall = PublishJobStatus.actionRequired;
    } else if (anyPublishing) {
      overall = PublishJobStatus.publishing;
    } else if (anyScheduled) {
      overall = PublishJobStatus.scheduled;
    } else {
      overall = PublishJobStatus.draft;
    }

    postRepository.savePost(
      post.copyWith(status: overall, updatedAtUtc: DateTime.now().toUtc()),
    );
  }

  void _recordAudit({
    required String eventType,
    required String entityType,
    required String entityId,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) {
    auditRepository.recordEvent(
      AuditEvent(
        id: _uuid.v4(),
        actor: localUserEmail ?? 'user',
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        description: description,
        metadataSanitized: metadata,
        createdAtUtc: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> clearAllData() async {
    // 1. Wipe all SQLite tables
    await AppDatabase.instance.clearAllData();

    // 2. Clear in-memory repository caches
    if (brandRepository is SqliteBrandRepository) {
      (brandRepository as SqliteBrandRepository).clearCache();
    }
    if (accountRepository is SqliteAccountRepository) {
      (accountRepository as SqliteAccountRepository).clearCache();
    }
    if (groupRepository is SqliteGroupRepository) {
      (groupRepository as SqliteGroupRepository).clearCache();
    }
    if (postRepository is SqlitePostRepository) {
      (postRepository as SqlitePostRepository).clearCache();
    }
    if (jobRepository is SqliteJobRepository) {
      (jobRepository as SqliteJobRepository).clearCache();
    }
    if (orgMemberRepository is SqliteOrgMemberRepository) {
      (orgMemberRepository as SqliteOrgMemberRepository).clearCache();
    }

    // 3. Clear all SharedPreferences session data
    await SessionService.instance.clearSession();
    await SessionService.instance.setCompletedOnboarding(false);
    await SessionService.instance.saveBrandsCache([]);

    // 4. Revoke Google sign-in token
    try {
      await GoogleAuthService.instance.signOut();
    } catch (e) {
      debugPrint('Google signOut during clearAllData: $e');
    }

    // 5. Reset all in-memory state — triggers auth guard to redirect to login
    isLoggedIn = false;
    isSessionExpired = false;
    hasCompletedOnboarding = false;
    _workspaceMode = WorkspaceMode.solo;
    localUserName = null;
    localUserEmail = null;
    localUserPhotoUrl = null;
    localUserId = null;
    localUserProvider = null;
    localUserData = null;
    maskedEmail = null;
    selectedBrandFilterId = null;
    selectedStatusFilter = null;
    searchQuery = '';
    notifyListeners();
  }

  Future<void> reloadRepositories() async {
    if (brandRepository is SqliteBrandRepository) {
      await (brandRepository as SqliteBrandRepository).init();
    }
    if (accountRepository is SqliteAccountRepository) {
      await (accountRepository as SqliteAccountRepository).init();
    }
    if (groupRepository is SqliteGroupRepository) {
      await (groupRepository as SqliteGroupRepository).init();
    }
    if (postRepository is SqlitePostRepository) {
      await (postRepository as SqlitePostRepository).init();
    }
    if (jobRepository is SqliteJobRepository) {
      await (jobRepository as SqliteJobRepository).init();
    }
    await initOrgMembers();
    notifyListeners();
  }

  Future<void> purgeDemoData() async {
    await AppDatabase.instance.removeSeedDemoData();
    await reloadRepositories();
  }

  Future<void> loadSampleDemoData() async {
    await AppDatabase.instance.seedDemoData();
    await reloadRepositories();
  }
}
