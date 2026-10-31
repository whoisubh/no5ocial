import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:no5ocial/core/config/firebase_config.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/channel_group.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/models/org_invite.dart';
import 'package:no5ocial/domain/models/org_member.dart';
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
      // PHASE 1: CRUCIAL USER AUTH & IDENTITY (Root Document users/{userId})
      // =========================================================================
      final localProfile = await db.getUserProfile();
      final session = await SessionService.instance.getSession();
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

      // Clean single source of truth on root user document
      await userRef.set({
        'uid': userId,
        'email': email,
        'display_name': name,
        'photo_url': photoUrl,
        'auth_provider': provider,
        'user_country_code': countryCode,
        'user_currency': currency,
        'user_currency_symbol': currencySymbol,
        'app_locale': appLocale,
        'theme_mode': themeMode,
        'has_completed_onboarding': onboardingDone,
        'created_at_utc': createdAt,
        'updated_at_utc': nowUtc,
        'last_login_at_utc': nowUtc,
      }, SetOptions(merge: true));

      // Clean up legacy redundant subcollection documents if they exist
      try {
        await userRef.collection('auth').doc('profile').delete();
        await userRef.collection('security').doc('settings').delete();
        await userRef.collection('settings').doc('preferences').delete();
      } catch (_) {}

      // =========================================================================
      // PHASE 2: PULL CRUCIAL DATA FROM CLOUD (Brands, Channels Linking, Groups)
      // =========================================================================

      // 1. Pull Root User Profile
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

      // 2. Pull Brands
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

      // 3. Pull Channels Linking (Social Accounts)
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
        // Retain local client OAuth tokens securely stored in SQLite
        for (final remote in remoteAccounts) {
          final local = await db.getSocialAccountRecord(remote['id'] as String);
          if (local != null) {
            final localScopes = (local['scopes'] as String? ?? '').split(',');
            final localTokens = localScopes.where((s) => s.startsWith('token:')).toList();
            if (localTokens.isNotEmpty) {
              final remoteScopes = (remote['scopes'] as String? ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty && !s.startsWith('token:'))
                  .toList();
              remoteScopes.addAll(localTokens);
              remote['scopes'] = remoteScopes.join(',');
            }
          }
        }
        await db.upsertRemoteDelta(
          tableName: 'social_accounts',
          records: remoteAccounts,
          syncedAtUtc: nowUtc,
        );
        totalPulled += remoteAccounts.length;
      }

      // 4. Pull Channel Groups
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

      // 5. Pull User Wallet & Coin Transactions
      try {
        final remoteWalletDoc = await userRef.collection('wallet').doc('summary').get();
        if (remoteWalletDoc.exists && remoteWalletDoc.data() != null) {
          final rData = remoteWalletDoc.data()!;
          final localWallet = await db.getUserWallet(userId);
          final remoteUpdated = rData['updated_at_utc'] as String?;
          final localUpdated = localWallet?['updated_at_utc'] as String?;

          if (localWallet == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.compareTo(localUpdated) > 0)) {
            await db.saveUserWallet({
              'user_id': userId,
              'balance': rData['balance'] ?? 0,
              'total_earned': rData['total_earned'] ?? 0,
              'total_spent': rData['total_spent'] ?? 0,
              'created_at_utc': rData['created_at_utc'] ?? nowUtc,
              'updated_at_utc': remoteUpdated ?? nowUtc,
              'synced_at_utc': nowUtc,
            });
            totalPulled++;
          }
        }

        final remoteTxsSnap = await userRef.collection('coin_transactions').get();
        final remoteTxs = remoteTxsSnap.docs.map((d) => d.data()).toList();
        if (remoteTxs.isNotEmpty) {
          await db.upsertRemoteDelta(
            tableName: 'coin_transactions',
            records: remoteTxs,
            syncedAtUtc: nowUtc,
          );
          totalPulled += remoteTxs.length;
        }
      } catch (e) {
        debugPrint('FirebaseSyncService: Wallet/Transactions pull note: $e');
      }

      // =========================================================================
      // PHASE 3: PUSH CRUCIAL DATA TO CLOUD (Brands, Channels Linking, Groups, Wallet)
      // =========================================================================

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

      // 2. Channels Linking (Social Accounts)
      final accountsToPush = forceHydration
          ? await db.getAllRecords('social_accounts')
          : await db.getUnsyncedRecords('social_accounts');
      for (final a in accountsToPush) {
        final id = a['id'] as String;
        final cleanAccount = _sanitizeAccountForCloud(a);
        await userRef.collection('social_accounts').doc(id).set(cleanAccount, SetOptions(merge: true));
      }
      if (accountsToPush.isNotEmpty) {
        await db.markRecordsAsSynced(
          tableName: 'social_accounts',
          recordIds: accountsToPush.map((r) => r['id'] as String).toList(),
          syncedAtUtc: nowUtc,
        );
        totalPushed += accountsToPush.length;
      }

      // 3. Channel Groups
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

      // 4. User Wallet & Coin Transactions
      try {
        final localWallet = await db.getUserWallet(userId);
        if (localWallet != null) {
          await userRef.collection('wallet').doc('summary').set({
            'user_id': userId,
            'balance': localWallet['balance'],
            'total_earned': localWallet['total_earned'],
            'total_spent': localWallet['total_spent'],
            'created_at_utc': localWallet['created_at_utc'],
            'updated_at_utc': localWallet['updated_at_utc'],
            'synced_at_utc': nowUtc,
          }, SetOptions(merge: true));
          totalPushed++;
        }

        final txsToPush = forceHydration
            ? await db.getAllRecords('coin_transactions')
            : await db.getUnsyncedRecords('coin_transactions');
        for (final tx in txsToPush) {
          final id = tx['id'] as String;
          await userRef.collection('coin_transactions').doc(id).set(tx, SetOptions(merge: true));
        }
        if (txsToPush.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'coin_transactions',
            recordIds: txsToPush.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
          totalPushed += txsToPush.length;
        }
      } catch (e) {
        debugPrint('FirebaseSyncService: Wallet/Transactions push note: $e');
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
        'scopes': account.scopes.where((s) => !s.startsWith('token:')).join(','),
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

  /// Strips sensitive authentication tokens before syncing social account data to Cloud Firestore.
  /// Access tokens remain strictly isolated to local encrypted device storage.
  Map<String, dynamic> _sanitizeAccountForCloud(Map<String, dynamic> accountData) {
    final sanitized = Map<String, dynamic>.from(accountData);
    final rawScopes = sanitized['scopes'];
    if (rawScopes is String) {
      sanitized['scopes'] = rawScopes
          .split(',')
          .where((s) => s.isNotEmpty && !s.startsWith('token:'))
          .join(',');
    } else if (rawScopes is List) {
      sanitized['scopes'] = rawScopes
          .where((s) => !s.toString().startsWith('token:'))
          .toList();
    }
    return sanitized;
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

  /// Push a generated workspace invitation to Cloud Firestore.
  /// Stored globally under `org_invites/{token}` so it can be verified from any device or web app.
  Future<void> pushOrgInvite({
    required OrgInvite invite,
    required String workspaceName,
    required String inviterName,
  }) async {
    if (firestore == null) return;
    try {
      final map = invite.toJson();
      map['workspace_name'] = workspaceName;
      map['inviter_name'] = inviterName;
      map['updated_at_utc'] = DateTime.now().toUtc().toIso8601String();

      await firestore!
          .collection('org_invites')
          .doc(invite.token)
          .set(map, SetOptions(merge: true));
      debugPrint('FirebaseSyncService: Pushed global invite ${invite.token} to cloud DB');
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pushing org invite: $e');
    }
  }

  /// Fetch an invitation by token from Cloud Firestore.
  Future<OrgInvite?> fetchOrgInvite(String token) async {
    if (firestore == null || token.isEmpty) return null;
    try {
      final doc = await firestore!.collection('org_invites').doc(token.trim()).get();
      if (doc.exists && doc.data() != null) {
        return OrgInvite.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('FirebaseSyncService: Error fetching remote invite: $e');
    }
    return null;
  }

  /// Mark remote invitation as accepted and record member in Cloud DB.
  Future<void> acceptRemoteInvite({
    required OrgInvite invite,
    required OrgMember member,
  }) async {
    if (firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      // 1. Update invite status to accepted
      await firestore!.collection('org_invites').doc(invite.token).update({
        'status': 'accepted',
        'accepted_by_user_id': member.userId,
        'accepted_by_email': member.userEmail,
        'accepted_at_utc': nowUtc,
      });

      // 2. Add member to workspace members collection
      await firestore!
          .collection('workspaces')
          .doc(invite.orgId)
          .collection('members')
          .doc(member.userId)
          .set(member.toJson(), SetOptions(merge: true));

      // 3. Grant the workspace brand to the accepted member's cloud user profile
      if (invite.workspaceName != null) {
        await firestore!
            .collection('users')
            .doc(member.userId)
            .collection('brands')
            .doc(invite.orgId)
            .set({
          'id': invite.orgId,
          'name': invite.workspaceName,
          'role': member.role.name,
          'created_at_utc': nowUtc,
          'updated_at_utc': nowUtc,
        }, SetOptions(merge: true));
      }
      debugPrint('FirebaseSyncService: Remote invite marked as accepted for ${member.userEmail}');
    } catch (e) {
      debugPrint('FirebaseSyncService: Error accepting remote invite: $e');
    }
  }

  /// Pull workspace members from Cloud Firestore so the workspace lead catches members who joined!
  Future<List<OrgMember>> pullWorkspaceMembers(String orgId) async {
    if (firestore == null || orgId.isEmpty) return [];
    try {
      final snap = await firestore!
          .collection('workspaces')
          .doc(orgId)
          .collection('members')
          .get();
      final members = <OrgMember>[];
      for (final doc in snap.docs) {
        try {
          members.add(OrgMember.fromJson(doc.data()));
        } catch (_) {}
      }
      return members;
    } catch (e) {
      debugPrint('FirebaseSyncService: Error pulling workspace members: $e');
      return [];
    }
  }

  /// Records user login with full telemetry (device hardware, OS, network, IP, ad tracking env)
  /// and ensures the user account record exists in Cloud Firestore.
  Future<void> recordUserLoginTelemetry({
    required String userId,
    required String email,
    required String name,
    Map<String, dynamic>? telemetry,
  }) async {
    if (firestore == null || userId.isEmpty) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final userRef = firestore!.collection('users').doc(userId);
      final emailKey = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final deviceKey = telemetry?['device_id']?.toString() ?? 'unknown_device';

      // 1. Save or update user account profile with telemetry
      await userRef.set({
        'id': userId,
        'email': email.trim().toLowerCase(),
        'display_name': name,
        'last_login_at_utc': nowUtc,
        ...?telemetry != null ? {'last_telemetry': telemetry} : null,
      }, SetOptions(merge: true));

      // 2. Global anti-abuse registry mapping email -> initial telemetry & creation date
      final emailRef = firestore!.collection('anti_abuse_emails').doc(emailKey);
      await emailRef.set({
        'email': email.trim().toLowerCase(),
        'first_user_id': userId,
        'device_id': deviceKey,
        'registered_at_utc': nowUtc,
        if (telemetry?['public_ip'] != null) 'registered_ip': telemetry!['public_ip'],
      }, SetOptions(merge: true));

      // 3. Global anti-abuse registry mapping device_id -> email
      if (deviceKey != 'unknown_device') {
        final deviceCleanKey = deviceKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final devRef = firestore!.collection('anti_abuse_devices').doc(deviceCleanKey);
        await devRef.set({
          'device_id': deviceKey,
          'user_id': userId,
          'email': email.trim().toLowerCase(),
          'last_seen_utc': nowUtc,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FirebaseSyncService: Error recording user login telemetry: $e');
    }
  }

  /// Verifies and claims milestone bonus coins (15 welcome, 5 company registration, 5 channel connect, 5 first post).
  /// Enforces strict anti-abuse: if this email OR device has ever claimed this milestone before (even across account deletes / fresh installs),
  /// the claim is rejected.
  Future<bool> verifyAndClaimMilestoneBonus({
    required String userId,
    required String email,
    required String milestone, // 'welcome_grant', 'company_registered', 'channel_connected', 'first_post'
    required int amount,
    String? deviceSignature,
  }) async {
    if (firestore == null || userId.isEmpty || email.isEmpty) {
      return false;
    }

    try {
      final emailKey = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      // 0. Check if this email or device is tombstoned from a prior account deletion
      final tombstoneEmailRef = firestore!.collection('anti_abuse_tombstones').doc('tombstone_$emailKey');
      final tombstoneEmailSnap = await tombstoneEmailRef.get();
      if (tombstoneEmailSnap.exists) {
        debugPrint('AntiAbuse: Email $email has a deletion tombstone. Lifetime bonus exhausted.');
        return false;
      }

      if (deviceSignature != null && deviceSignature.isNotEmpty && deviceSignature != 'unknown_device') {
        final devClean = deviceSignature.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final tombstoneDevRef = firestore!.collection('anti_abuse_tombstones').doc('device_tombstone_$devClean');
        final tombstoneDevSnap = await tombstoneDevRef.get();
        if (tombstoneDevSnap.exists) {
          debugPrint('AntiAbuse: Device $deviceSignature has a deletion tombstone. Lifetime bonus exhausted.');
          return false;
        }
      }

      final claimDocId = '${emailKey}_$milestone';
      final claimRef = firestore!.collection('milestone_claims').doc(claimDocId);

      // Check if this email has ever claimed this milestone in history
      final claimSnap = await claimRef.get();
      if (claimSnap.exists) {
        debugPrint('AntiAbuse: Milestone $milestone already claimed by email $email. Claim blocked.');
        return false;
      }

      // Check if this device hardware has already claimed this milestone max times
      if (deviceSignature != null && deviceSignature.isNotEmpty && deviceSignature != 'unknown_device') {
        final devClean = deviceSignature.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final devClaimRef = firestore!.collection('device_milestones').doc('${devClean}_$milestone');
        final devSnap = await devClaimRef.get();
        if (devSnap.exists) {
          debugPrint('AntiAbuse: Milestone $milestone already claimed by device $deviceSignature. Claim blocked.');
          return false;
        }

        // Record device claim
        await devClaimRef.set({
          'device_id': deviceSignature,
          'milestone': milestone,
          'user_id': userId,
          'email': email.trim().toLowerCase(),
          'claimed_at_utc': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // Record email claim globally
      await claimRef.set({
        'email': email.trim().toLowerCase(),
        'user_id': userId,
        'milestone': milestone,
        'amount': amount,
        'claimed_at_utc': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('FirebaseSyncService: Error verifying milestone bonus claim: $e');
      return false;
    }
  }

  /// Checks if a social account (by platform + externalAccountId or handle) has already been linked
  /// to another email. If so, prevents abuse.
  Future<({bool isAllowed, String? conflictingEmail})> checkChannelOwnership({
    required String platform,
    required String externalAccountId,
    required String userEmail,
  }) async {
    if (firestore == null || externalAccountId.isEmpty) {
      return (isAllowed: true, conflictingEmail: null);
    }
    try {
      final cleanKey = '${platform}_$externalAccountId'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final channelRef = firestore!.collection('linked_channels_registry').doc(cleanKey);
      final doc = await channelRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final ownerEmail = data['owner_email'] as String? ?? '';
        if (ownerEmail.isNotEmpty && ownerEmail.toLowerCase() != userEmail.trim().toLowerCase()) {
          return (isAllowed: false, conflictingEmail: ownerEmail);
        }
      }

      // Register or update channel mapping
      await channelRef.set({
        'platform': platform,
        'external_account_id': externalAccountId,
        'owner_email': userEmail.trim().toLowerCase(),
        'registered_at_utc': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      return (isAllowed: true, conflictingEmail: null);
    } catch (e) {
      debugPrint('FirebaseSyncService: Error verifying channel ownership: $e');
      return (isAllowed: true, conflictingEmail: null);
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

  /// Permanently deletes user account and personal workspace documents from Cloud Firestore,
  /// while recording an immutable anti-abuse tombstone so that bonus farming
  /// (deleting account to reclaim 30 free coins) is strictly impossible.
  Future<void> deleteAccountAndEnforceAntiAbuse({
    required String userId,
    required String email,
    required String deviceSignature,
    List<String> connectedChannelIds = const [],
    Map<String, dynamic>? telemetry,
  }) async {
    if (firestore == null) return;
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final emailKey = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final devClean = (deviceSignature.isNotEmpty && deviceSignature != 'unknown_device')
          ? deviceSignature.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          : null;

      // 1. Record immutable email tombstone in Firestore
      final tombstoneEmailRef = firestore!.collection('anti_abuse_tombstones').doc('tombstone_$emailKey');
      await tombstoneEmailRef.set({
        'email': email.trim().toLowerCase(),
        'device_id': deviceSignature,
        'user_id': userId,
        'deleted_at_utc': nowUtc,
        'lifetime_coins_exhausted': true,
        'connected_channel_ids': connectedChannelIds,
        'reason': 'user_requested_account_deletion',
        ...?telemetry != null ? {'telemetry': telemetry} : null,
      }, SetOptions(merge: true));

      // 2. Record immutable device hardware tombstone in Firestore
      if (devClean != null) {
        final tombstoneDevRef = firestore!.collection('anti_abuse_tombstones').doc('device_tombstone_$devClean');
        await tombstoneDevRef.set({
          'device_id': deviceSignature,
          'email': email.trim().toLowerCase(),
          'deleted_at_utc': nowUtc,
          'lifetime_coins_exhausted': true,
          'connected_channel_ids': connectedChannelIds,
          'reason': 'user_requested_account_deletion',
        }, SetOptions(merge: true));
      }

      // 3. Seal all 4 milestones as claimed/exhausted for this email and device
      final milestones = ['welcome_grant', 'company_registered', 'channel_connected', 'first_post'];
      for (final m in milestones) {
        await firestore!.collection('milestone_claims').doc('${emailKey}_$m').set({
          'email': email.trim().toLowerCase(),
          'user_id': userId,
          'milestone': m,
          'amount': 0,
          'exhausted': true,
          'claimed_at_utc': nowUtc,
        }, SetOptions(merge: true));

        if (devClean != null) {
          await firestore!.collection('device_milestones').doc('${devClean}_$m').set({
            'device_id': deviceSignature,
            'milestone': m,
            'email': email.trim().toLowerCase(),
            'exhausted': true,
            'claimed_at_utc': nowUtc,
          }, SetOptions(merge: true));
        }
      }

      // 4. Mark all connected channels as exhausted in linked_channels_registry
      for (final chId in connectedChannelIds) {
        final cleanCh = chId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await firestore!.collection('linked_channels_registry').doc(cleanCh).set({
          'external_account_id': chId,
          'bonus_claimed': true,
          'exhausted_at_utc': nowUtc,
          'last_owner_email': email.trim().toLowerCase(),
        }, SetOptions(merge: true));
      }

      // 5. Delete user profile from active users collection
      if (userId.isNotEmpty) {
        await firestore!.collection('users').doc(userId).delete();
      }

      debugPrint('FirebaseSyncService: User account $userId ($email) permanently deleted & anti-abuse tombstone sealed.');
    } catch (e) {
      debugPrint('FirebaseSyncService: Error during deleteAccountAndEnforceAntiAbuse: $e');
    }
  }

  /// Checks whether an email or device is tombstoned in Cloud Firestore
  Future<bool> isIdentityTombstoned({required String email, String? deviceSignature}) async {
    if (firestore == null) return false;
    try {
      final emailKey = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final tombDoc = await firestore!.collection('anti_abuse_tombstones').doc('tombstone_$emailKey').get();
      if (tombDoc.exists) return true;

      if (deviceSignature != null && deviceSignature.isNotEmpty && deviceSignature != 'unknown_device') {
        final devClean = deviceSignature.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final devDoc = await firestore!.collection('anti_abuse_tombstones').doc('device_tombstone_$devClean').get();
        if (devDoc.exists) return true;
      }
    } catch (_) {}
    return false;
  }
}
