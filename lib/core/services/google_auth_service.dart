import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:no5ocial/core/config/env_config.dart';

/// Official Google Identity Services Authentication Service
class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._internal();
  GoogleAuthService._internal();

  /// Web OAuth Client ID loaded dynamically from environment (ZERO hardcoded strings)
  static String get webClientId => EnvConfig.googleWebClientId;

  /// Android OAuth Client ID loaded dynamically from environment (ZERO hardcoded strings)
  static String get androidClientId => EnvConfig.googleAndroidClientId;

  /// Server Client ID loaded dynamically from environment (ZERO hardcoded strings)
  static String get serverClientId => EnvConfig.googleServerClientId;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get client {
    _googleSignIn ??= GoogleSignIn(
      clientId: kIsWeb ? (webClientId.isNotEmpty ? webClientId : null) : null,
      serverClientId: kIsWeb ? null : (serverClientId.isNotEmpty ? serverClientId : null),
      scopes: const <String>[
        'email',
        'profile',
      ],
    );
    return _googleSignIn!;
  }

  GoogleSignInAccount? get currentUser => client.currentUser;

  /// Trigger the official Google Sign-In flow.
  /// Always signs out first to force the account-picker popup — this prevents
  /// the plugin from silently reusing a stale cached account after device wipe.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Force-clear any cached account so the system account picker always shows
      try {
        await client.signOut();
      } catch (_) {}

      final account = await client.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Google Sign-In timed out');
          return null;
        },
      );
      return account;
    } catch (e) {
      debugPrint('Google Sign-In SDK error: $e');
      rethrow;
    }
  }

  /// Request access token with optional extra scopes (e.g. YouTube Data API, Photos, Drive)
  Future<String?> getOrRequestAccessToken({
    List<String> additionalScopes = const [],
    bool forceRefresh = false,
  }) async {
    try {
      GoogleSignInAccount? user = client.currentUser;
      if (user == null) {
        user = await signIn();
        if (user == null) return null;
      }

      if (additionalScopes.isNotEmpty) {
        bool hasScopes = false;
        try {
          hasScopes = await client.canAccessScopes(additionalScopes);
        } catch (_) {
          // canAccessScopes() is not implemented on Android; safely assume scopes must be requested
          hasScopes = false;
        }

        if (!hasScopes || forceRefresh) {
          try {
            final granted = await client.requestScopes(additionalScopes);
            if (!granted) {
              debugPrint('User did not grant additional requested scopes: $additionalScopes');
            }
          } catch (e) {
            debugPrint('requestScopes error: $e');
          }
        }
      }

      final activeUser = client.currentUser ?? user;
      if (forceRefresh || additionalScopes.isNotEmpty) {
        try {
          await activeUser.clearAuthCache();
        } catch (_) {}
      }
      final auth = await activeUser.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('Error getting Google access token: $e');
      return null;
    }
  }

  /// Sign out from Google Identity Services (app-level session only).
  Future<void> signOut() async {
    try {
      await client.signOut().timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }
    _googleSignIn = null;
  }

  /// Fully disconnect and revoke the OAuth token — clears native platform cache.
  /// Must be called on device reset / "Reset Device & Logout" to ensure the
  /// next signIn() always shows the account picker and never loops silently.
  Future<void> disconnect() async {
    try {
      await client.disconnect().timeout(const Duration(seconds: 6), onTimeout: () => null);
    } catch (e) {
      debugPrint('Google Disconnect error (non-fatal): $e');
    }
    try {
      await client.signOut().timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (_) {}
    _googleSignIn = null;
  }
}
