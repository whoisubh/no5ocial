/// Structured error codes for predictable, traceable operations.
class AppErrorCode {
  static const String authFailed = 'ERR_AUTH_001';
  static const String authSessionExpired = 'ERR_AUTH_002';
  static const String authPermissionDenied = 'ERR_AUTH_003';

  static const String networkUnavailable = 'ERR_NET_001';
  static const String networkTimeout = 'ERR_NET_002';
  static const String networkServerError = 'ERR_NET_003';

  static const String validationFailed = 'ERR_VAL_001';
  static const String validationDuplicate = 'ERR_VAL_002';

  static const String channelConnectionFailed = 'ERR_CHN_001';
  static const String channelTokenExpired = 'ERR_CHN_002';
  static const String channelRateLimited = 'ERR_CHN_003';

  static const String publishPreflightFailed = 'ERR_PUB_001';
  static const String publishDispatchFailed = 'ERR_PUB_002';
  static const String publishTimeoutAmbiguous = 'ERR_PUB_003';

  static const String databaseError = 'ERR_DB_001';
  static const String storageError = 'ERR_IO_001';

  static const String internalUnknown = 'ERR_SYS_500';
}

/// Core application exception that sanitizes errors for production
/// while retaining rich diagnostics in development/debug mode.
class AppException implements Exception {
  final String code;
  final String title;
  final String userMessage;
  final String? devDetails;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException({
    required this.code,
    required this.title,
    required this.userMessage,
    this.devDetails,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Build a safe AppException from any arbitrary caught error.
  factory AppException.from(dynamic error, {StackTrace? stackTrace, String? fallbackTitle}) {
    if (error is AppException) {
      return error;
    }

    final errStr = error.toString();
    final st = stackTrace ?? (error is Error ? error.stackTrace : null);

    // Network / Socket detection
    if (errStr.contains('SocketException') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('NetworkImageLoadException') ||
        errStr.contains('Connection refused')) {
      return AppException(
        code: AppErrorCode.networkUnavailable,
        title: 'Network Unavailable',
        userMessage: 'Unable to connect to the network. Please verify your internet connection and retry.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    if (errStr.contains('TimeoutException') || errStr.contains('timed out')) {
      return AppException(
        code: AppErrorCode.networkTimeout,
        title: 'Request Timed Out',
        userMessage: 'The server took too long to respond. Please try again in a few moments.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Auth / Permission detection
    if (errStr.contains('PlatformException') &&
        (errStr.contains('sign_in') || errStr.contains('ApiException') || errStr.contains('10:') || errStr.contains('12500'))) {
      return AppException(
        code: AppErrorCode.authFailed,
        title: 'Authentication Unsuccessful',
        userMessage: 'Sign-in could not be completed with Google. Please check your account configuration.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    if (errStr.contains('401') || errStr.contains('Unauthorized')) {
      return AppException(
        code: AppErrorCode.authSessionExpired,
        title: 'Session Expired',
        userMessage: 'Your active session has expired. Please sign in again to continue.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Database / Storage detection
    if (errStr.contains('SqliteException') || errStr.contains('database') || errStr.contains('UNIQUE constraint')) {
      return AppException(
        code: AppErrorCode.databaseError,
        title: 'Data Storage Error',
        userMessage: 'A local data operation could not be completed. Your existing records remain secure.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Default unknown error
    return AppException(
      code: AppErrorCode.internalUnknown,
      title: fallbackTitle ?? 'Unexpected Error',
      userMessage: 'An unexpected issue occurred while processing your request. Please try again.',
      devDetails: errStr,
      originalError: error,
      stackTrace: st,
    );
  }

  @override
  String toString() => '[$code] $title: $userMessage (dev: $devDetails)';
}
