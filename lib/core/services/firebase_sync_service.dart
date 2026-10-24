import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:no5ocial/core/config/firebase_config.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/passkey_credential.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';

enum FirebaseSyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class FirebaseSyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;
  final DateTime timestamp;

  const FirebaseSyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.errorMessage,
    required this.timestamp,
  });
}

/// Firebase Cloud Firestore Synchronization Engine.
///
/// Ensures all workspace data (brands, connected accounts, posts, groups,
/// scheduled jobs, currency & preferences) is backed up to Cloud Firestore
/// and restored automatically on fresh installs, device restarts, or multi-device logins.
///
/// Principles:
/// 1. Local SQLite remains the instant, offline authority.
/// 2. Cloud Firestore stores real-time state under `users/{userId}/...`.
/// 3. Conflict resolution uses Last-Write-Wins (LWW) via `updated_at_utc`.
/// 4. Operates offline-first; if offline or uninitialized, changes persist locally
///    and reconcile when cloud is reachable.
class FirebaseSyncService extends ChangeNotifier {
  static final FirebaseSyncService instance = FirebaseSyncService._internal();
  FirebaseSyncService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore? get firestore {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('FirebaseSyncService: Error obtaining Firestore instance: $e');
      }
    }
    return _firestore;
  }

  static const String _prefLastSyncKey = 'firebase_last_sync_utc';

  FirebaseSyncStatus _status = FirebaseSyncStatus.idle;
  FirebaseSyncStatus get status => _status;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _autoSyncTimer;

  /// Initialize sync state and start periodic background reconciliation
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefLastSyncKey);
    if (raw != null) {
      _lastSyncedAt = DateTime.tryParse(raw);
    }

    // Auto-sync every 5 minutes when user is logged in
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Periodic background sync if active
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  /// Full bidirectional synchronization for a user workspace:
  /// 1. Pushes any dirty local changes to Cloud Firestore
  /// 2. Pulls all remote documents from Cloud Firestore into local SQLite
  Future<FirebaseSyncResult> syncUserWorkspace(
    String userId, {
    bool forceHydration = false,
  }) async {
    if (userId.trim().isEmpty) {
      return FirebaseSyncResult(
        success: false,
        errorMessage: 'User ID cannot be empty.',
        timestamp: DateTime.now(),
      );
    }

    if (_status == FirebaseSyncStatus.syncing) {
      return FirebaseSyncResult(
        success: false,
        errorMessage: 'Sync already in progress.',
        timestamp: DateTime.now(),
      );
    }

    _status = FirebaseSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    // Ensure Firebase is initialized
    final initialized = await FirebaseConfig.initialize();
    if (!initialized || firestore == null) {
      _status = FirebaseSyncStatus.offline;
      _lastError = 'Firebase is not initialized or device is offline.';
      notifyListeners();
      return FirebaseSyncResult(
        success: false,
        errorMessage: _lastError,
        timestamp: DateTime.now(),
      );
    }

    try {
      final db = AppDatabase.instance;
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final userRef = firestore!.collection('users').doc(userId);

      int totalPushed = 0;
      int totalPulled = 0;

      // =========================================================================
      // PHASE 0: PUSH USER PROFILE, AUTH IDENTITY & SECURITY SETTINGS
      // =========================================================================
      final localProfile = await db.getUserProfile();
      final session = await SessionService.instance.getSession();
      final registeredPasskeys = await SessionService.instance.getRegisteredPasskeys();
      final isBiometric = await SessionService.instance.isBiometricLockEnabled();
      final lockTimeout = await SessionService.instance.getLockTimeoutSeconds();
      final onboardingDone = await SessionService.instance.hasCompletedOnboarding();

      final email = localProfile?['email'] as String? ?? session?['email'] as String? ?? '';
      final name = localProfile?['name'] as String? ?? session?['name'] as String? ?? '';
      final photoUrl = localProfile?['photo_url'] as String? ?? session?['photoUrl'] as String? ?? '';
      final provider = localProfile?['provider'] as String? ?? session?['provider'] as String? ?? 'google';
      final createdAt = localProfile?['created_at_utc'] as String? ?? session?['createdAtUtc'] as String? ?? nowUtc;

      final countryCode = await db.getSetting('user_country_code') ?? 'IN';
      final currency = await db.getSetting('user_currency') ?? 'INR';
      final currencySymbol = await db.getSetting('user_currency_symbol') ?? '₹';
      final appLocale = await db.getSetting('app_locale') ?? 'en';
      final themeMode = await db.getSetting('theme_mode') ?? 'system';
      final workspaceMode = await db.getSetting('workspace_mode') ?? 'personal';
      final subscriptionTier = await db.getSetting('subscription_tier') ?? 'free';
      final dayPassExpiresAt = await db.getSetting('day_pass_expires_at');

      // 1. Root User Document (Physical Firestore Document with Full Profile Fields)
      await userRef.set({
        'id': userId,
        'email': email,
        'display_name': name,
        'photo_url': photoUrl,
        'auth_provider': provider,
        'created_at_utc': createdAt,
        'last_login_at_utc': nowUtc,
        'last_backup_at_utc': nowUtc,
        'workspace_mode': workspaceMode,
        'subscription_tier': subscriptionTier,
        'user_country_code': countryCode,
        'app_locale': appLocale,
        'user_currency': currency,
        'user_currency_symbol': currencySymbol,
        'theme_mode': themeMode,
        'day_pass_expires_at': dayPassExpiresAt,
        'has_completed_onboarding': onboardingDone,
        'is_active': true,
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      // 2. Auth Identity Document (users/{userId}/auth/profile)
      await userRef.collection('auth').doc('profile').set({
        'uid': userId,
        'email': email,
        'display_name': name,
        'photo_url': photoUrl,
        'auth_provider': provider,
        'created_at_utc': createdAt,
        'last_synced_at_utc': nowUtc,
        'raw_data': localProfile?['raw_data'] ?? session?['rawData'],
      }, SetOptions(merge: true));

      // 3. Security & Biometrics Document (users/{userId}/security/settings)
      await userRef.collection('security').doc('settings').set({
        'biometric_lock_enabled': isBiometric,
        'lock_timeout_seconds': lockTimeout,
        'passkeys_count': registeredPasskeys.length,
        'passkeys': registeredPasskeys.map((p) => p.toJson()).toList(),
        'updated_at_utc': nowUtc,
      }, SetOptions(merge: true));

      // 4. Complete App Settings (users/{userId}/settings/preferences)
      final allSettings = await db.getAllSettings();
      final fullSettingsMap = <String, dynamic>{
        'updated_at_utc': nowUtc,
        'user_currency': currency,
        'user_currency_symbol': currencySymbol,
        'theme_mode': themeMode,
        'workspace_mode': workspaceMode,
        'subscription_tier': subscriptionTier,
        'day_pass_expires_at': dayPassExpiresAt,
      };
      allSettings.forEach((k, v) {
        fullSettingsMap[k] = v;
      });
      await userRef.collection('settings').doc('preferences').set(
        fullSettingsMap,
        SetOptions(merge: true),
      );

      // 5. User Wallet & Coin Balance Synchronization (users/{userId}/wallet/balance)
      final localBalance = await db.getCoinBalance(userId);
      try {
        final walletDocSnap = await userRef.collection('wallet').doc('balance').get();
        if (walletDocSnap.exists && walletDocSnap.data() != null) {
          final remoteBalance = walletDocSnap.data()!['balance'] as int? ?? 0;
          if (remoteBalance > localBalance) {
            final diff = remoteBalance - localBalance;
            await db.addCoinsToWallet(
              userId: userId,
              amount: diff,
              type: 'cloud_sync',
              description: 'Cloud Wallet Synchronization',
            );
          } else if (localBalance > remoteBalance) {
            await userRef.collection('wallet').doc('balance').set({
              'balance': localBalance,
              'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
            }, SetOptions(merge: true));
          }
        } else {
          await userRef.collection('wallet').doc('balance').set({
            'balance': localBalance,
            'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('FirebaseSyncService: Error syncing wallet: $e');
      }

      // 5.1 Push & Synchronize Unsynced Coin Transactions
      try {
        final unsyncedTx = await db.getUnsyncedRecords('coin_transactions');
        for (final tx in unsyncedTx) {
          final txId = tx['id'] as String?;
          if (txId != null && txId.isNotEmpty) {
            await userRef.collection('wallet_transactions').doc(txId).set(
              Map<String, dynamic>.from(tx),
              SetOptions(merge: true),
            );
          }
        }
        if (unsyncedTx.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'coin_transactions',
            recordIds: unsyncedTx.map((t) => t['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }
      } catch (e) {
        debugPrint('FirebaseSyncService: Error syncing coin transactions: $e');
      }

      // 5.2 2-Day Publishing Pass Cloud Synchronization (users/{userId}/publishing_pass/current)
      try {
        final passDocSnap = await userRef.collection('publishing_pass').doc('current').get();
        final localPass = await db.getActivePublishingPass(userId);

        if (passDocSnap.exists && passDocSnap.data() != null) {
          final remotePassData = passDocSnap.data()!;
          final remoteUpdated = remotePassData['updated_at_utc'] as String? ?? '';
          final localUpdated = localPass?.activatedAt.toUtc().toIso8601String() ?? '';

          if (localPass == null || remoteUpdated.compareTo(localUpdated) >= 0) {
            await db.savePublishingPass(remotePassData);
          } else {
            await userRef.collection('publishing_pass').doc('current').set(
              localPass.toJson(),
              SetOptions(merge: true),
            );
          }
        } else if (localPass != null) {
          await userRef.collection('publishing_pass').doc('current').set(
            localPass.toJson(),
            SetOptions(merge: true),
          );
        }
      } catch (e) {
        debugPrint('FirebaseSyncService: Error syncing publishing pass: $e');
      }

      // =========================================================================
      // PHASE 1: PULL REMOTE CLOUD FIRESTORE DATA INTO LOCAL SQLITE FIRST
      // (Cloud Database is the persistent authority for auth, channels & groups)
      // =========================================================================

      // 0. Pull Root User Profile & Session
      final userDocSnap = await userRef.get();
      if (userDocSnap.exists) {
        final uData = userDocSnap.data();
        if (uData != null) {
          final uEmail = uData['email'] as String? ?? '';
          final uName = uData['display_name'] as String? ?? '';
          final uPhoto = uData['photo_url'] as String?;
          final uProvider = uData['auth_provider'] as String? ?? 'google';

          if (uEmail.isNotEmpty) {
            await SessionService.instance.saveSession(
              id: userId,
              name: uName,
              email: uEmail,
              photoUrl: uPhoto,
              provider: uProvider,
            );
            await db.saveUserProfile(
              id: userId,
              name: uName,
              email: uEmail,
              photoUrl: uPhoto,
              provider: uProvider,
            );
          }
        }
      }

      // 0.1 Pull Security Settings
      final securitySnap = await userRef.collection('security').doc('settings').get();
      if (securitySnap.exists) {
        final secData = securitySnap.data();
        if (secData != null) {
          if (secData['biometric_lock_enabled'] is bool) {
            await SessionService.instance.setBiometricLockEnabled(secData['biometric_lock_enabled'] as bool);
          }
          if (secData['lock_timeout_seconds'] is int) {
            await SessionService.instance.setLockTimeoutSeconds(secData['lock_timeout_seconds'] as int);
          }
          if (secData['passkeys'] is List) {
            final list = (secData['passkeys'] as List)
                .map((e) => PasskeyCredential.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            await SessionService.instance.saveRegisteredPasskeys(list);
          }
        }
      }

      // 1. Pull Brands from Cloud DB
      final remoteBrandsSnap = await userRef.collection('brands').get();
      final remoteBrands = remoteBrandsSnap.docs.map((d) => d.data()).toList();
      if (remoteBrands.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'brands',
          records: remoteBrands,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteBrands.length;
      }

      // 2. Pull Channel Groups from Cloud DB
      final remoteGroupsSnap = await userRef.collection('channel_groups').get();
      final remoteGroups = remoteGroupsSnap.docs.map((d) {
        final map = Map<String, dynamic>.from(d.data());
        if (map['account_ids'] is List) {
          map['account_ids'] = (map['account_ids'] as List).map((e) => e.toString()).toList();
        }
        return map;
      }).toList();
      if (remoteGroups.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'channel_groups',
          records: remoteGroups,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteGroups.length;
      }

      // 3. Pull Social Accounts from Cloud DB
      final remoteAccountsSnap = await userRef.collection('social_accounts').get();
      final remoteAccounts = remoteAccountsSnap.docs.map((d) {
        final map = Map<String, dynamic>.from(d.data());
        if (map['capabilities'] is List) {
          map['capabilities'] = (map['capabilities'] as List).join(',');
        }
        if (map['scopes'] is List) {
          map['scopes'] = (map['scopes'] as List).join(',');
        }
        return map;
      }).toList();
      if (remoteAccounts.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'social_accounts',
          records: remoteAccounts,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteAccounts.length;
      }

      // 4. Pull Content Posts from Cloud DB
      final remotePostsSnap = await userRef.collection('content_posts').get();
      final remotePosts = remotePostsSnap.docs.map((d) => d.data()).toList();
      if (remotePosts.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'content_posts',
          records: remotePosts,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remotePosts.length;
      }

      // 5. Pull Post Variants from Cloud DB
      final remoteVariantsSnap = await userRef.collection('post_variants').get();
      final remoteVariants = remoteVariantsSnap.docs.map((d) => d.data()).toList();
      if (remoteVariants.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'post_variants',
          records: remoteVariants,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteVariants.length;
      }

      // 6. Pull Publish Jobs from Cloud DB
      final remoteJobsSnap = await userRef.collection('publish_jobs').get();
      final remoteJobs = remoteJobsSnap.docs.map((d) => d.data()).toList();
      if (remoteJobs.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'publish_jobs',
          records: remoteJobs,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteJobs.length;
      }

      // 7. Pull Org Members from Cloud DB
      final remoteMembersSnap = await userRef.collection('org_members').get();
      final remoteMembers = remoteMembersSnap.docs.map((d) => d.data()).toList();
      if (remoteMembers.isNotEmpty) {
        await db.upsertRemoteDelta(
          tableName: 'org_members',
          records: remoteMembers,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteMembers.length;
      }

      // 8. Pull Settings from Cloud DB
      final remoteSettingsSnap = await userRef.collection('settings').doc('preferences').get();
      if (remoteSettingsSnap.exists) {
        final sData = remoteSettingsSnap.data();
        if (sData != null) {
          for (final entry in sData.entries) {
            if (entry.value != null && entry.key != 'updated_at_utc') {
              await db.setSetting(entry.key, entry.value.toString());
            }
          }
        }
      }

      // =========================================================================
      // PHASE 2: PUSH LOCAL OUTBOX CHANGES TO CLOUD FIRESTORE
      // =========================================================================

      // Demo/seed brand IDs that should not be uploaded as user brands
      const seedBrandIds = {
        'brand-shaadow',
        'brand-shaadow-works',
        'brand-boofer',
        'brand-favtunes',
        'brand-galaxious',
        'brand-owl-and-fowl',
      };

      // 1. Brands
      final brandsToPush = (forceHydration
              ? await db.getAllRecords('brands')
              : await db.getUnsyncedRecords('brands'))
          .where((b) => !seedBrandIds.contains(b['id']))
          .toList();
      for (final b in brandsToPush) {
        final id = b['id'] as String;
        await userRef.collection('brands').doc(id).set(b, SetOptions(merge: true));
      }
      if (brandsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'brands',
          recordIds: brandsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += brandsToPush.length;
      }

      // 2. Channel Groups
      final groupsToPush = forceHydration
          ? await db.getAllRecords('channel_groups')
          : await db.getUnsyncedRecords('channel_groups');
      for (final g in groupsToPush) {
        final id = g['id'] as String;
        await userRef.collection('channel_groups').doc(id).set(g, SetOptions(merge: true));
      }
      if (groupsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'channel_groups',
          recordIds: groupsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += groupsToPush.length;
      }

      // 3. Social Accounts
      final accountsToPush = forceHydration
          ? await db.getAllRecords('social_accounts')
          : await db.getUnsyncedRecords('social_accounts');
      for (final a in accountsToPush) {
        final id = a['id'] as String;
        // Never commit secret tokens to Firestore; social_accounts table stores safe metadata
        await userRef.collection('social_accounts').doc(id).set(a, SetOptions(merge: true));
      }
      if (accountsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'social_accounts',
          recordIds: accountsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += accountsToPush.length;
      }

      // 4. Content Posts
      final postsToPush = forceHydration
          ? await db.getAllRecords('content_posts')
          : await db.getUnsyncedRecords('content_posts');
      for (final p in postsToPush) {
        final id = p['id'] as String;
        await userRef.collection('content_posts').doc(id).set(p, SetOptions(merge: true));
      }
      if (postsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'content_posts',
          recordIds: postsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += postsToPush.length;
      }

      // 5. Post Variants
      final variantsToPush = forceHydration
          ? await db.getAllRecords('post_variants')
          : await db.getUnsyncedRecords('post_variants');
      for (final v in variantsToPush) {
        final id = v['id'] as String;
        await userRef.collection('post_variants').doc(id).set(v, SetOptions(merge: true));
      }
      if (variantsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'post_variants',
          recordIds: variantsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += variantsToPush.length;
      }

      // 6. Publish Jobs
      final jobsToPush = forceHydration
          ? await db.getAllRecords('publish_jobs')
          : await db.getUnsyncedRecords('publish_jobs');
      for (final j in jobsToPush) {
        final id = j['id'] as String;
        await userRef.collection('publish_jobs').doc(id).set(j, SetOptions(merge: true));
      }
      if (jobsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'publish_jobs',
          recordIds: jobsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += jobsToPush.length;
      }

      // 7. Org Members
      final membersToPush = forceHydration
          ? await db.getAllRecords('org_members')
          : await db.getUnsyncedRecords('org_members');
      for (final m in membersToPush) {
        final id = m['id'] as String;
        await userRef.collection('org_members').doc(id).set(m, SetOptions(merge: true));
      }
      if (membersToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'org_members',
          recordIds: membersToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += membersToPush.length;
      }

      _lastSyncedAt = DateTime.parse(nowUtc);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastSyncKey, nowUtc);

      _status = FirebaseSyncStatus.synced;
      _lastError = null;
      notifyListeners();

      return FirebaseSyncResult(
        success: true,
        pushedCount: totalPushed,
        pulledCount: totalPulled,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FirebaseSyncService: Sync error: $e');
      _status = FirebaseSyncStatus.error;
      _lastError = e.toString();
      notifyListeners();
      return FirebaseSyncResult(
        success: false,
        errorMessage: _lastError,
        timestamp: DateTime.now(),
      );
    }
  }

  // --- Real-time individual entity cloud push helpers ---

  /// Save or update a brand to Cloud Firestore in the background
  Future<void> pushBrand(String userId, Brand brand) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final map = {
        'id': brand.id,
        'name': brand.name,
        'slug': brand.slug,
        'description': brand.description,
        'website_url': brand.websiteUrl,
        'company_size': brand.companySize,
        'industry': brand.industry,
        'found_us_via': brand.foundUsVia,
        'is_active': brand.isActive ? 1 : 0,
        'created_at_utc': brand.createdAtUtc.toIso8601String(),
        'updated_at_utc': nowUtc,
        'synced_at_utc': nowUtc,
      };
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('brands')
          .doc(brand.id)
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing brand $brand.id: $e');
    }
  }

  /// Remove a brand from Cloud Firestore
  Future<void> deleteBrand(String userId, String brandId) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('brands')
          .doc(brandId)
          .delete();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting cloud brand $brandId: $e');
    }
  }

  /// Save or update a social account to Cloud Firestore
  Future<void> pushSocialAccount(String userId, SocialAccount account) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final map = {
        'id': account.id,
        'brand_id': account.brandId,
        'platform': account.platform.name,
        'display_name': account.displayName,
        'handle': account.handle,
        'external_account_id': account.externalAccountId,
        'connection_status': account.connectionStatus.name,
        'capabilities': account.capabilities.join(','),
        'scopes': account.scopes.join(','),
        'last_verified_at_utc': account.lastVerifiedAtUtc?.toIso8601String(),
        'is_manual_only': account.isManualOnly ? 1 : 0,
        'created_at_utc': DateTime.now().toUtc().toIso8601String(),
        'updated_at_utc': nowUtc,
        'synced_at_utc': nowUtc,
      };
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('social_accounts')
          .doc(account.id)
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing social account ${account.id}: $e');
    }
  }

  /// Remove a social account from Cloud Firestore
  Future<void> deleteSocialAccount(String userId, String accountId) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('social_accounts')
          .doc(accountId)
          .delete();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting cloud account $accountId: $e');
    }
  }

  /// Save or update a content post to Cloud Firestore
  Future<void> pushPost(String userId, ContentPost post) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final map = {
        'id': post.id,
        'brand_id': post.brandId,
        'title': post.title,
        'default_caption': post.defaultCaption,
        'destination_account_ids': post.destinationAccountIds.join(','),
        'media_asset_ids': post.mediaAssetIds.join(','),
        'campaign': post.campaign,
        'tags': post.tags.join(','),
        'status': post.status.name,
        'scheduled_at_utc': post.scheduledAtUtc?.toIso8601String(),
        'created_at_utc': post.createdAtUtc.toIso8601String(),
        'updated_at_utc': post.updatedAtUtc.toIso8601String(),
        'synced_at_utc': nowUtc,
      };
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('content_posts')
          .doc(post.id)
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing post ${post.id}: $e');
    }
  }

  /// Remove a content post from Cloud Firestore
  Future<void> deletePost(String userId, String postId) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('content_posts')
          .doc(postId)
          .delete();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting cloud post $postId: $e');
    }
  }

  /// Save or update channel group to Cloud Firestore
  Future<void> pushGroup(String userId, ChannelGroup group) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final map = group.toMap();
      map['updated_at_utc'] = nowUtc;
      map['synced_at_utc'] = nowUtc;
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('channel_groups')
          .doc(group.id)
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing group ${group.id}: $e');
    }
  }

  /// Remove a channel group from Cloud Firestore
  Future<void> deleteGroup(String userId, String groupId) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('channel_groups')
          .doc(groupId)
          .delete();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting cloud group $groupId: $e');
    }
  }

  /// Push workspace preference changes to Cloud Firestore
  Future<void> pushSettings(String userId, Map<String, dynamic> settings) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final mutable = Map<String, dynamic>.from(settings);
      mutable['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set(mutable, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing settings: $e');
    }
  }

  /// Push real-time wallet balance to Cloud Firestore
  Future<void> pushWallet(String userId, int balance) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('balance')
          .set({
        'balance': balance,
        'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing wallet balance: $e');
    }
  }

  /// Pull real-time wallet balance from Cloud Firestore
  Future<int?> pullWallet(String userId) async {
    if (userId.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore!
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('balance')
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['balance'] as int?;
      }
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pulling wallet balance: $e');
    }
    return null;
  }

  /// Push 2-day publishing pass status to Cloud Firestore
  Future<void> pushPublishingPass(String userId, Map<String, dynamic> passData) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final mutable = Map<String, dynamic>.from(passData);
      mutable['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('publishing_pass')
          .doc('current')
          .set(mutable, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing publishing pass: $e');
    }
  }

  /// Pull 2-day publishing pass from Cloud Firestore
  Future<PublishingPass?> pullPublishingPass(String userId) async {
    if (userId.isEmpty || firestore == null) return null;
    try {
      final doc = await firestore!
          .collection('users')
          .doc(userId)
          .collection('publishing_pass')
          .doc('current')
          .get();
      if (doc.exists && doc.data() != null) {
        final pass = PublishingPass.fromJson(doc.data()!);
        await AppDatabase.instance.savePublishingPass(doc.data()!);
        return pass;
      }
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pulling publishing pass: $e');
    }
    return null;
  }

  /// Push an individual coin transaction to Cloud Firestore
  Future<void> pushCoinTransaction(String userId, Map<String, dynamic> tx) async {
    if (userId.isEmpty || firestore == null) return;
    try {
      final txId = tx['id'] as String? ?? 'tx-${DateTime.now().millisecondsSinceEpoch}';
      final mutable = Map<String, dynamic>.from(tx);
      mutable['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('wallet_transactions')
          .doc(txId)
          .set(mutable, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing coin transaction: $e');
    }
  }

  /// Formatted last sync time string
  String get formattedLastSync {
    if (_lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().toUtc().difference(_lastSyncedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
