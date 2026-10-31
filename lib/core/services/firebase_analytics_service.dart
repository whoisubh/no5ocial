import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Central Google Firebase Analytics service for tracking user engagement and events.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();
  static final FirebaseAnalyticsService instance = FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _initialized = false;

  /// Returns the Navigator observer for tracking screen views in MaterialApp.
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Initializes Google Firebase Analytics.
  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('FirebaseAnalyticsService: Firebase not initialized. Analytics disabled.');
        return;
      }

      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      _initialized = true;
      debugPrint('FirebaseAnalyticsService: Google Firebase Analytics successfully initialized.');
    } catch (e) {
      debugPrint('FirebaseAnalyticsService: Warning initializing Analytics: $e');
    }
  }

  /// Sets the user identifier for analytics.
  Future<void> setUserId(String? userId) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.setUserId(id: userId);
    } catch (_) {}
  }

  /// Sets a user property (e.g. plan_tier).
  Future<void> setUserProperty({required String name, required String? value}) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  /// Logs a screen view.
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (_) {}
  }

  /// Logs a custom event with parameters.
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    if (!_initialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  /// Logs post publication event.
  Future<void> logPostPublished({
    required String postId,
    required int destinationCount,
    required bool isManual,
  }) async {
    await logEvent(
      name: 'post_published',
      parameters: {
        'post_id': postId,
        'destination_count': destinationCount,
        'is_manual': isManual,
      },
    );
  }

  /// Logs post scheduled event.
  Future<void> logPostScheduled({
    required String postId,
    required int destinationCount,
  }) async {
    await logEvent(
      name: 'post_scheduled',
      parameters: {
        'post_id': postId,
        'destination_count': destinationCount,
      },
    );
  }

  /// Logs rewarded coin transaction.
  Future<void> logCoinsEarned({
    required String type,
    required int amount,
  }) async {
    await logEvent(
      name: 'coins_earned',
      parameters: {
        'reward_type': type,
        'amount': amount,
      },
    );
  }

  /// Logs publishing pass activation.
  Future<void> logPassActivated({
    required int durationDays,
    required int costCoins,
  }) async {
    await logEvent(
      name: 'pass_activated',
      parameters: {
        'duration_days': durationDays,
        'cost_coins': costCoins,
      },
    );
  }
}
