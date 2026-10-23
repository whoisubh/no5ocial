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

  bool _isInitialized = false;
  DateTime? _lastBackgroundedAt;
  DateTime? _lastAuthenticatedAt;
  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  String? _lastError;
  String? get lastError => _lastError;

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

  /// Check whether biometrics are enrolled and available or device credentials exist
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
    // If the system biometric dialog itself caused the app to pause, do not mark as user backgrounding
    if (_isAuthenticating) return;
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
        _lastError = null;
        notifyListeners();
      }
      return;
    }

    // If currently in the middle of authenticating, do not interrupt or relock
    if (_isAuthenticating) return;

    // Grace window: If authentication succeeded just a moment ago (e.g. prompt just dismissed), do not relock
    if (_lastAuthenticatedAt != null) {
      final sinceAuth = DateTime.now().toUtc().difference(_lastAuthenticatedAt!).inMilliseconds;
      if (sinceAuth < 3500) {
        return;
      }
    }

    bool shouldLock = false;

    if (!_isInitialized) {
      // Cold start / initial app launch with biometric lock enabled
      _isInitialized = true;
      shouldLock = true;
    } else if (_lastBackgroundedAt != null) {
      final timeoutSeconds = await SessionService.instance.getLockTimeoutSeconds();
      final elapsed = DateTime.now().toUtc().difference(_lastBackgroundedAt!).inSeconds;
      if (elapsed >= timeoutSeconds) {
        shouldLock = true;
      }
      _lastBackgroundedAt = null;
    }

    if (shouldLock) {
      _isLocked = true;
      _lastError = null;
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
      _lastError = null;
      notifyListeners();
      return true;
    }

    if (_isAuthenticating) return false;
    _isAuthenticating = true;
    _lastError = null;
    notifyListeners();

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        _isLocked = false;
        _lastBackgroundedAt = null;
        _lastAuthenticatedAt = DateTime.now().toUtc();
        _lastError = null;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Verification cancelled. Please try again.';
        notifyListeners();
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'NotEnrolled') {
        _lastError = 'No biometric or screen lock enrolled on device.';
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        _lastError = 'Too many attempts. Screen lock temporarily disabled.';
      } else {
        _lastError = e.message ?? 'Authentication error';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Biometric authentication general error: $e');
      _lastError = 'Authentication error. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Explicitly mark the session as authenticated (e.g. right after user turns on toggle in settings)
  void markAuthenticated() {
    _isLocked = false;
    _lastBackgroundedAt = null;
    _lastAuthenticatedAt = DateTime.now().toUtc();
    _lastError = null;
    notifyListeners();
  }

  /// Explicitly lock the workspace
  void lock() {
    _isLocked = true;
    _lastError = null;
    notifyListeners();
  }

  /// Explicitly unlock the workspace
  void unlock() {
    _isLocked = false;
    _lastBackgroundedAt = null;
    _lastAuthenticatedAt = DateTime.now().toUtc();
    _lastError = null;
    notifyListeners();
  }
}
