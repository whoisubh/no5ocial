import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:no5ocial/core/services/session_service.dart';

/// Service managing device biometric and screen lock state on app cold start and resume.
class BiometricLockService extends ChangeNotifier {
  static final BiometricLockService instance = BiometricLockService._internal();
  BiometricLockService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  DateTime? _lastBackgroundedAt;
  bool _isAuthenticating = false;

  /// Check whether the current device supports hardware local authentication
  Future<bool> isDeviceSupported() async {
    try {
      if (kIsWeb) return false;
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('BiometricLockService.isDeviceSupported error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check whether biometrics are enrolled and available
  Future<bool> canCheckBiometrics() async {
    try {
      if (kIsWeb) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricLockService.canCheckBiometrics error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get list of enrolled biometrics (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (kIsWeb) return [];
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricLockService.getAvailableBiometrics error: $e');
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Record timestamp when the app goes into the background
  void onAppPaused() {
    _lastBackgroundedAt = DateTime.now().toUtc();
  }

  /// Evaluate lock status when app resumes into the foreground
  Future<void> onAppResumed({required bool isUserLoggedIn}) async {
    if (kIsWeb) return;
    if (!isUserLoggedIn) return;

    final isEnabled = await SessionService.instance.isBiometricLockEnabled();
    if (!isEnabled) {
      if (_isLocked) {
        _isLocked = false;
        notifyListeners();
      }
      return;
    }

    final timeoutSeconds = await SessionService.instance.getLockTimeoutSeconds();
    bool shouldLock = false;

    if (_lastBackgroundedAt == null) {
      // Cold start with biometric lock enabled
      shouldLock = true;
    } else {
      final elapsed = DateTime.now().toUtc().difference(_lastBackgroundedAt!).inSeconds;
      if (elapsed >= timeoutSeconds) {
        shouldLock = true;
      }
    }

    if (shouldLock && !_isLocked) {
      _isLocked = true;
      notifyListeners();
      await authenticate();
    }
  }

  /// Request biometric or device credential verification from the operating system
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to unlock no5ocial workspace',
  }) async {
    if (kIsWeb) {
      _isLocked = false;
      notifyListeners();
      return true;
    }

    if (_isAuthenticating) return false;
    _isAuthenticating = true;

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        _isLocked = false;
        _lastBackgroundedAt = null;
        notifyListeners();
        return true;
      } else {
        // User cancelled or authentication did not complete
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Biometric authentication general error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Explicitly lock the workspace
  void lock() {
    _isLocked = true;
    notifyListeners();
  }

  /// Explicitly unlock the workspace
  void unlock() {
    _isLocked = false;
    _lastBackgroundedAt = null;
    notifyListeners();
  }
}
