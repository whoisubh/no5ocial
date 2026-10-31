import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central Google Firebase Crashlytics service for crash reporting and ANR diagnostics.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _initialized = false;

  /// Initializes Google Firebase Crashlytics error hooks if running on supported native platforms.
  Future<void> init() async {
    if (_initialized) return;

    // Crashlytics is supported on Android, iOS, macOS. On Web/Desktop it is a no-op.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('CrashlyticsService: Firebase not initialized. Crashlytics disabled.');
        return;
      }

      final crashlytics = FirebaseCrashlytics.instance;

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        crashlytics.recordFlutterFatalError(details);
        originalOnError?.call(details);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      // Enable collection in release/prod mode
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      _initialized = true;
      debugPrint('CrashlyticsService: Google Firebase Crashlytics successfully initialized.');
    } catch (e) {
      debugPrint('CrashlyticsService: Warning initializing Crashlytics: $e');
    }
  }

  /// Records a non-fatal caught exception with an optional stack trace and reason.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (kIsWeb || !_initialized) {
      debugPrint('Crashlytics (Non-fatal): $exception\n$stack');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (_) {}
  }

  /// Sets the user identifier for crash reporting.
  Future<void> setUserIdentifier(String identifier) async {
    if (kIsWeb || !_initialized) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (_) {}
  }

  /// Sets a custom key-value pair for enhanced crash context.
  Future<void> setCustomKey(String key, Object value) async {
    if (kIsWeb || !_initialized) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {}
  }

  /// Logs a custom message that will appear in the next crash report.
  void log(String message) {
    if (kIsWeb || !_initialized) {
      debugPrint('[Crashlytics Log]: $message');
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }
}
