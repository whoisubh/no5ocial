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

  /// Trigger the official Google Sign-In flow
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await client.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In SDK error: $e');
      rethrow;
    }
  }

  /// Request access token with optional extra scopes (e.g. YouTube Data API)
  Future<String?> getOrRequestAccessToken({
    List<String> additionalScopes = const [],
  }) async {
    try {
      GoogleSignInAccount? user = client.currentUser;
      if (user == null) {
        user = await signIn();
        if (user == null) return null;
      }

      if (additionalScopes.isNotEmpty) {
        try {
          final hasScopes = await client.canAccessScopes(additionalScopes);
          if (!hasScopes) {
            final granted = await client.requestScopes(additionalScopes);
            if (!granted) {
              debugPrint('User did not grant additional requested scopes: $additionalScopes');
            }
          }
        } catch (e) {
          debugPrint('canAccessScopes check error (may not be supported on web): $e');
        }
      }

      final auth = await user.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('Error getting Google access token: $e');
      return null;
    }
  }

  /// Sign out from Google Identity Services and disconnect OAuth credentials.
  /// Calling both signOut() and disconnect() revokes granted OAuth access
  /// so Google prompts the account chooser on next login rather than auto-signing in.
  Future<void> signOut() async {
    try {
      await client.signOut().timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }
    try {
      await client.disconnect().timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      debugPrint('Google disconnect error (can be ignored if already disconnected): $e');
    }
    _googleSignIn = null;
  }
}
