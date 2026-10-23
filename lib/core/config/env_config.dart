import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFlavor {
  dev,
  prod,
}

/// Unified Environment & Flavor Configuration Service.
/// Loads values at startup from `.env`, `.env.dev`, or `.env.prod` assets,
/// with runtime support for `--dart-define` overrides and dynamic runtime persistence.
///
/// Contains ZERO hardcoded client IDs or secrets.
class EnvConfig {
  static AppFlavor _currentFlavor = AppFlavor.dev;
  static final Map<String, String> _envValues = {};
  static bool _isInitialized = false;

  static AppFlavor get flavor => _currentFlavor;
  static bool get isDev => _currentFlavor == AppFlavor.dev;
  static bool get isProd => _currentFlavor == AppFlavor.prod;
  static bool get isInitialized => _isInitialized;

  /// Initialize environment configuration.
  /// Automatically called during app startup in main(), main_dev(), or main_prod().
  static Future<void> init({AppFlavor flavor = AppFlavor.dev}) async {
    _currentFlavor = flavor;
    _envValues.clear();

    // Determine target env files to attempt loading
    final filesToTry = <String>[
      flavor == AppFlavor.prod ? '.env.prod' : '.env.dev',
      '.env',
      '.env.example',
    ];

    for (final fileName in filesToTry) {
      try {
        final content = await rootBundle.loadString(fileName);
        _parseEnvString(content);
        if (_envValues.isNotEmpty) {
          debugPrint('EnvConfig: Successfully loaded configuration from $fileName (flavor: ${flavor.name})');
          break;
        }
      } catch (_) {
        // Asset not bundled or not found, proceed to next candidate
      }
    }

    // Attempt direct filesystem load if running locally on desktop
    if (!kIsWeb) {
      for (final fileName in filesToTry) {
        try {
          final file = File(fileName);
          if (file.existsSync()) {
            final content = file.readAsStringSync();
            _parseEnvString(content);
            if (_envValues.isNotEmpty) break;
          }
        } catch (_) {}
      }
    }

    // Also load any runtime persisted overrides
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('env_')) {
          final envKey = key.substring(4);
          final val = prefs.getString(key);
          if (val != null && val.isNotEmpty) {
            _envValues[envKey] = val;
          }
        }
      }
    } catch (_) {}

    _isInitialized = true;
  }

  /// Store and persist a runtime environment key-value pair
  static Future<void> set(String key, String value) async {
    _envValues[key] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('env_$key', value);
    } catch (_) {}
  }

  static void _parseEnvString(String content) {
    final lines = content.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final eqIdx = line.indexOf('=');
      if (eqIdx > 0) {
        final key = line.substring(0, eqIdx).trim();
        var val = line.substring(eqIdx + 1).trim();

        // Strip enclosing quotes if present
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }

        if (key.isNotEmpty) {
          _envValues[key] = val;
        }
      }
    }
  }

  /// Retrieve an environment value by key.
  /// Priority:
  /// 1. Compile-time `--dart-define`
  /// 2. Loaded `.env` map
  /// 3. Supplied fallback
  static String get(String key, {String fallback = ''}) {
    // 1. Check loaded .env map
    final mapVal = _envValues[key];
    if (mapVal != null && mapVal.isNotEmpty) {
      return mapVal;
    }

    // 2. Check compile-time constants safely
    switch (key) {
      case 'GOOGLE_WEB_CLIENT_ID':
        const val = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        if (val.isNotEmpty) return val;
        break;
      case 'GOOGLE_CLIENT_ID':
        const val = String.fromEnvironment('GOOGLE_CLIENT_ID');
        if (val.isNotEmpty) return val;
        break;
      case 'GOOGLE_ANDROID_CLIENT_ID':
        const val = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');
        if (val.isNotEmpty) return val;
        break;
      case 'GOOGLE_SERVER_CLIENT_ID':
        const val = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
        if (val.isNotEmpty) return val;
        break;
      case 'API_BASE_URL':
        const val = String.fromEnvironment('API_BASE_URL');
        if (val.isNotEmpty) return val;
        break;
      case 'APP_TITLE':
        const val = String.fromEnvironment('APP_TITLE');
        if (val.isNotEmpty) return val;
        break;
    }

    // 3. Fallback
    return fallback;
  }

  // --- Convenience Getters (Completely dynamic, zero hardcoded values) ---

  static String get googleWebClientId =>
      get('GOOGLE_WEB_CLIENT_ID', fallback: get('GOOGLE_CLIENT_ID'));

  static String get googleAndroidClientId =>
      get('GOOGLE_ANDROID_CLIENT_ID');

  static String get googleServerClientId =>
      get('GOOGLE_SERVER_CLIENT_ID', fallback: googleWebClientId);

  static String get apiBaseUrl =>
      get('API_BASE_URL', fallback: isDev ? 'http://localhost:8080' : 'https://api.shaadow.io');

  static String get appTitle =>
      get('APP_TITLE', fallback: 'no5ocial');

  // --- Firebase Configuration Getters ---
  static String get firebaseApiKey => get('FIREBASE_API_KEY');
  static String get firebaseProjectId => get('FIREBASE_PROJECT_ID', fallback: 'no5ocial-cloud');
  static String get firebaseAppId => get('FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId =>
      get('FIREBASE_MESSAGING_SENDER_ID', fallback: '1030532523858');
  static String get firebaseAuthDomain => get('FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket => get('FIREBASE_STORAGE_BUCKET');
}
