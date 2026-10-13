import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/passkey_credential.dart';

/// Centralized session persistence and security settings service backed by
/// SharedPreferences (browser localStorage on Web, persistent XML prefs on Android).
class SessionService {
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Session Lifetimes ---
  /// Web session lifetime: 1 week (7 days)
  static const Duration webSessionDuration = Duration(days: 7);

  /// Mobile/Android session lifetime: 2 weeks (14 days)
  static const Duration mobileSessionDuration = Duration(days: 14);

  /// Applicable maximum session lifetime for the current platform
  Duration get maxSessionDuration => kIsWeb ? webSessionDuration : mobileSessionDuration;

  // --- Preference Keys ---
  static const String _kIsLoggedIn = 'auth_is_logged_in';
  static const String _kUserId = 'auth_user_id';
  static const String _kUserName = 'auth_user_name';
  static const String _kUserEmail = 'auth_user_email';
  static const String _kUserPhotoUrl = 'auth_user_photo_url';
  static const String _kUserProvider = 'auth_user_provider';
  static const String _kUserRawData = 'auth_user_raw_data';
  static const String _kSessionCreatedAtUtc = 'auth_session_created_at_utc';
  static const String _kHasCompletedOnboarding = 'auth_has_completed_onboarding';
  static const String _kBrandsCache = 'auth_brands_cache';

  static const String _kBiometricEnabled = 'security_biometric_lock_enabled';
  static const String _kLockTimeoutSeconds = 'security_lock_timeout_seconds';
  static const String _kRegisteredPasskeys = 'security_registered_passkeys';

  // --- Onboarding & Workspace Cache ---

  /// Check whether the user has completed or bypassed initial onboarding
  Future<bool> hasCompletedOnboarding() async {
    final p = await prefs;
    return p.getBool(_kHasCompletedOnboarding) ?? false;
  }

  /// Record onboarding completion status
  Future<void> setCompletedOnboarding(bool completed) async {
    final p = await prefs;
    await p.setBool(_kHasCompletedOnboarding, completed);
  }

  /// Persist serialized workspace brands cache so workspace identities survive app restarts
  Future<void> saveBrandsCache(List<Brand> brands) async {
    final p = await prefs;
    final jsonList = brands.map((b) => b.toJson()).toList();
    await p.setString(_kBrandsCache, jsonEncode(jsonList));
  }

  /// Retrieve cached workspace brands
  Future<List<Brand>> getBrandsCache() async {
    final p = await prefs;
    final raw = p.getString(_kBrandsCache);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => Brand.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error decoding brands cache: $e');
    }
    return const [];
  }

  // --- Session Management ---

  /// Save active user session details and stamp current UTC time
  Future<void> saveSession({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    String provider = 'google',
    Map<String, dynamic>? rawData,
  }) async {
    final p = await prefs;
    await p.setBool(_kIsLoggedIn, true);
    await p.setString(_kUserId, id);
    await p.setString(_kUserName, name);
    await p.setString(_kUserEmail, email);
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await p.setString(_kUserPhotoUrl, photoUrl);
    } else {
      await p.remove(_kUserPhotoUrl);
    }
    await p.setString(_kUserProvider, provider);
    if (rawData != null) {
      await p.setString(_kUserRawData, jsonEncode(rawData));
    } else {
      await p.remove(_kUserRawData);
    }

    // Preserve original creation time if already set, otherwise record now
    if (!p.containsKey(_kSessionCreatedAtUtc)) {
      await p.setString(_kSessionCreatedAtUtc, DateTime.now().toUtc().toIso8601String());
    }
  }

  /// Retrieve stored session map or null if not logged in
  Future<Map<String, dynamic>?> getSession() async {
    final p = await prefs;
    final loggedIn = p.getBool(_kIsLoggedIn) ?? false;
    if (!loggedIn) return null;

    final id = p.getString(_kUserId);
    final email = p.getString(_kUserEmail);
    if (id == null || email == null) return null;

    Map<String, dynamic>? rawData;
    final rawJson = p.getString(_kUserRawData);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          rawData = decoded;
        }
      } catch (_) {}
    }

    return {
      'id': id,
      'name': p.getString(_kUserName) ?? '',
      'email': email,
      'photo_url': p.getString(_kUserPhotoUrl),
      'provider': p.getString(_kUserProvider) ?? 'google',
      'raw_data': rawData,
      'created_at_utc': p.getString(_kSessionCreatedAtUtc),
    };
  }

  /// Returns when the current active session was created
  Future<DateTime?> getSessionCreatedAt() async {
    final p = await prefs;
    final timeStr = p.getString(_kSessionCreatedAtUtc);
    if (timeStr == null || timeStr.isEmpty) return null;
    return DateTime.tryParse(timeStr)?.toUtc();
  }

  /// Checks if the current session has surpassed its platform lifetime
  /// (7 days on web, 14 days on android/other platforms).
  Future<bool> isSessionExpired() async {
    final p = await prefs;
    final loggedIn = p.getBool(_kIsLoggedIn) ?? false;
    if (!loggedIn) return false;

    final timeStr = p.getString(_kSessionCreatedAtUtc);
    if (timeStr == null || timeStr.isEmpty) return false;

    final createdAt = DateTime.tryParse(timeStr)?.toUtc();
    if (createdAt == null) return false;

    final elapsed = DateTime.now().toUtc().difference(createdAt);
    return elapsed > maxSessionDuration;
  }

  /// Formats an email into a secure masked string:
  /// e.g. `surya@gmail.com` -> `su***a@gmail.com`, `user@domain.com` -> `us***r@domain.com`
  String getMaskedEmail(String? email) {
    if (email == null || email.trim().isEmpty || !email.contains('@')) {
      return 'your email address';
    }
    final parts = email.split('@');
    final user = parts[0];
    final domain = parts[1];

    if (user.length <= 2) {
      return '${user[0]}***@$domain';
    } else if (user.length <= 4) {
      return '${user.substring(0, 1)}***${user.substring(user.length - 1)}@$domain';
    } else {
      return '${user.substring(0, 2)}***${user.substring(user.length - 1)}@$domain';
    }
  }

  /// Clear active session data on logout
  Future<void> clearSession() async {
    final p = await prefs;
    await p.remove(_kIsLoggedIn);
    await p.remove(_kUserId);
    await p.remove(_kUserName);
    await p.remove(_kUserEmail);
    await p.remove(_kUserPhotoUrl);
    await p.remove(_kUserProvider);
    await p.remove(_kUserRawData);
    await p.remove(_kSessionCreatedAtUtc);
  }

  // --- Biometric & Screen Lock Settings ---

  /// Check whether biometric screen lock is enabled
  Future<bool> isBiometricLockEnabled() async {
    final p = await prefs;
    return p.getBool(_kBiometricEnabled) ?? false;
  }

  /// Toggle biometric screen lock on/off
  Future<void> setBiometricLockEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_kBiometricEnabled, enabled);
  }

  /// Get lock delay in seconds:
  /// 0 = Lock immediately
  /// 120 = Lock after 2 minutes
  Future<int> getLockTimeoutSeconds() async {
    final p = await prefs;
    return p.getInt(_kLockTimeoutSeconds) ?? 0;
  }

  /// Set lock delay in seconds (0 for immediate, 120 for 2 minutes)
  Future<void> setLockTimeoutSeconds(int seconds) async {
    final p = await prefs;
    await p.setInt(_kLockTimeoutSeconds, seconds);
  }

  // --- Passkeys Storage ---

  /// Retrieve list of registered passkey credentials
  Future<List<PasskeyCredential>> getRegisteredPasskeys() async {
    final p = await prefs;
    final jsonStr = p.getString(_kRegisteredPasskeys) ?? '';
    return PasskeyCredential.listFromJson(jsonStr);
  }

  /// Save or update a registered passkey credential
  Future<void> savePasskeyCredential(PasskeyCredential credential) async {
    final p = await prefs;
    final list = await getRegisteredPasskeys();
    final index = list.indexWhere((c) => c.id == credential.id);
    if (index >= 0) {
      list[index] = credential;
    } else {
      list.add(credential);
    }
    await p.setString(_kRegisteredPasskeys, PasskeyCredential.listToJson(list));
  }

  /// Delete a registered passkey credential
  Future<void> deletePasskeyCredential(String credentialId) async {
    final p = await prefs;
    final list = await getRegisteredPasskeys();
    list.removeWhere((c) => c.id == credentialId);
    await p.setString(_kRegisteredPasskeys, PasskeyCredential.listToJson(list));
  }

  /// Update last used timestamp for a passkey
  Future<void> updatePasskeyLastUsed(String credentialId) async {
    final p = await prefs;
    final list = await getRegisteredPasskeys();
    final index = list.indexWhere((c) => c.id == credentialId);
    if (index >= 0) {
      list[index] = list[index].copyWith(lastUsedAtUtc: DateTime.now().toUtc());
      await p.setString(_kRegisteredPasskeys, PasskeyCredential.listToJson(list));
    }
  }
}
