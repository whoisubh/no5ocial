import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:no5ocial/core/config/env_config.dart';

/// Central Firebase Initialization Service
/// Provides unified, fail-safe Firebase configuration across Android, Web, and Desktop.
class FirebaseConfig {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes Firebase using either native platform assets (google-services.json on Android)
  /// or dynamic environment options (Web, Desktop, or configured .env).
  ///
  /// Returns `true` if Firebase initialized successfully, `false` otherwise.
  /// Never throws unhandled exceptions so the offline SQLite engine continues to operate.
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        return true;
      }

      if (kIsWeb) {
        final options = getPlatformOptions();
        await Firebase.initializeApp(options: options);
        _isInitialized = true;
        debugPrint('FirebaseConfig: Initialized for Web with platform options.');
        return true;
      } else {
        // Android / iOS native initialization
        try {
          await Firebase.initializeApp();
          _isInitialized = true;
          debugPrint('FirebaseConfig: Initialized natively via google-services.');
          return true;
        } catch (nativeErr) {
          debugPrint('FirebaseConfig: Native init note: $nativeErr. Initializing with platform options...');
          final options = getPlatformOptions();
          await Firebase.initializeApp(options: options);
          _isInitialized = true;
          debugPrint('FirebaseConfig: Initialized successfully with platform options.');
          return true;
        }
      }
    } catch (e) {
      debugPrint('FirebaseConfig: Note: Firebase initialization error: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  /// Resolve FirebaseOptions dynamically from EnvConfig or google-services.json configuration
  static FirebaseOptions getPlatformOptions() {
    final apiKey = EnvConfig.get('FIREBASE_API_KEY');
    final appId = EnvConfig.get('FIREBASE_APP_ID');
    final projectId = EnvConfig.get('FIREBASE_PROJECT_ID');
    final messagingSenderId = EnvConfig.get('FIREBASE_MESSAGING_SENDER_ID');
    final storageBucket = EnvConfig.get('FIREBASE_STORAGE_BUCKET');

    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) {
      throw StateError(
        'Firebase configuration is missing. Set FIREBASE_API_KEY, FIREBASE_APP_ID, '
        'FIREBASE_PROJECT_ID, and FIREBASE_MESSAGING_SENDER_ID environment variables.',
      );
    }
    final authDomain = EnvConfig.get('FIREBASE_AUTH_DOMAIN');

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
      authDomain: authDomain.isNotEmpty ? authDomain : null,
    );
  }
}
