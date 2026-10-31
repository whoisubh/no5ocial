import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Central service for Google Play Core In-App Updates on Android.
class PlayUpdateService {
  PlayUpdateService._();
  static final PlayUpdateService instance = PlayUpdateService._();

  AppUpdateInfo? _updateInfo;
  bool _isChecking = false;

  /// Cached update info from the latest check.
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Whether an update is currently available on Google Play.
  bool get isUpdateAvailable =>
      _updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;

  /// Checks Google Play Store for available app updates.
  Future<({bool success, bool updateAvailable, String message, AppUpdateInfo? info})>
      checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return (
        success: false,
        updateAvailable: false,
        message: 'Google Play In-App Updates are only supported on Android devices.',
        info: null,
      );
    }

    if (_isChecking) {
      return (
        success: false,
        updateAvailable: false,
        message: 'Update check already in progress.',
        info: _updateInfo,
      );
    }

    _isChecking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;
      _isChecking = false;

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        return (
          success: true,
          updateAvailable: true,
          message: 'An update (version code ${info.availableVersionCode}) is available on Google Play!',
          info: info,
        );
      } else {
        return (
          success: true,
          updateAvailable: false,
          message: 'You have the latest version installed.',
          info: info,
        );
      }
    } catch (e) {
      _isChecking = false;
      debugPrint('PlayUpdateService: Error checking for update: $e');
      return (
        success: false,
        updateAvailable: false,
        message: 'Could not connect to Google Play Store: $e',
        info: null,
      );
    }
  }

  /// Triggers a flexible background update if supported.
  Future<bool> startFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final status = await InAppUpdate.startFlexibleUpdate();
      return status == AppUpdateResult.success;
    } catch (e) {
      debugPrint('PlayUpdateService: Error starting flexible update: $e');
      return false;
    }
  }

  /// Completes the flexible update by restarting the app.
  Future<void> completeFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('PlayUpdateService: Error completing flexible update: $e');
    }
  }

  /// Triggers an immediate full-screen update for critical patches.
  Future<bool> performImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final status = await InAppUpdate.performImmediateUpdate();
      return status == AppUpdateResult.success;
    } catch (e) {
      debugPrint('PlayUpdateService: Error performing immediate update: $e');
      return false;
    }
  }
}
