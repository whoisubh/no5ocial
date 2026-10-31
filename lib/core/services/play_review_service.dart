import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service for Google Play and App Store In-App Reviews and ratings.
class PlayReviewService {
  PlayReviewService._();
  static final PlayReviewService instance = PlayReviewService._();

  static const String _prefLastPromptKey = 'last_store_review_prompt_utc';
  static const int _minDaysBetweenPrompts = 14;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Prompts the user with the native Google Play in-app review modal.
  /// Throttled to at most once every 14 days so users are not spammed.
  Future<bool> requestReview({bool force = false}) async {
    if (kIsWeb) return false;

    try {
      if (!force) {
        final prefs = await SharedPreferences.getInstance();
        final lastPromptStr = prefs.getString(_prefLastPromptKey);
        if (lastPromptStr != null) {
          final lastPrompt = DateTime.tryParse(lastPromptStr);
          if (lastPrompt != null &&
              DateTime.now().difference(lastPrompt).inDays < _minDaysBetweenPrompts) {
            return false;
          }
        }
      }

      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint('PlayReviewService: In-app review is not available on this device.');
        return false;
      }

      await _inAppReview.requestReview();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastPromptKey, DateTime.now().toUtc().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('PlayReviewService: Error requesting in-app review: $e');
      return false;
    }
  }

  /// Opens the official store listing on Google Play Store or Apple App Store.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6740000000', // Apple App Store ID if applicable
      );
    } catch (e) {
      debugPrint('PlayReviewService: Error opening store listing: $e');
    }
  }
}
