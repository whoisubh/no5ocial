/// Structured numeric error IDs and codes for predictable, traceable operations.
/// Follows industry-standard 5-digit error categorization:
/// - 10000..19999: Authentication & Session
/// - 20000..29999: Network & Connectivity
/// - 30000..39999: Publishing & Social Provider APIs
/// - 40000..49999: Media & Storage Assets
/// - 50000..59999: Database & Local SQLite Persistence
/// - 60000..69999: Monetization & 2-Day Publishing Pass
/// - 90000..99999: System & Unhandled Exceptions
class AppErrorCode {
  // 10xxx: Auth & Session
  static const int authFailedId = 12003; // Industry-standard OAuth/credential failure
  static const int authSessionExpiredId = 10002;
  static const int authPermissionDeniedId = 10003;
  static const int authAccountMissingId = 10004;
  static const int authBiometricFailedId = 10005;

  static const String authFailed = 'ERR_AUTH_12003';
  static const String authSessionExpired = 'ERR_AUTH_10002';
  static const String authPermissionDenied = 'ERR_AUTH_10003';

  // 20xxx: Network & Connectivity
  static const int networkUnavailableId = 20001;
  static const int networkTimeoutId = 20002;
  static const int networkServerErrorId = 20003;
  static const int networkHostLookupFailedId = 20004;

  static const String networkUnavailable = 'ERR_NET_20001';
  static const String networkTimeout = 'ERR_NET_20002';
  static const String networkServerError = 'ERR_NET_20003';

  // 30xxx: Publishing & Social Providers
  static const int publishPreflightFailedId = 30001;
  static const int publishDispatchFailedId = 30002;
  static const int publishTimeoutAmbiguousId = 30003;
  static const int publishRateLimitedId = 30004;
  static const int publishTokenExpiredId = 30005;
  static const int publishPolicyRejectionId = 30006;

  static const String publishPreflightFailed = 'ERR_PUB_30001';
  static const String publishDispatchFailed = 'ERR_PUB_30002';
  static const String publishTimeoutAmbiguous = 'ERR_PUB_30003';

  // 40xxx: Media & Assets
  static const int mediaMissingId = 40001;
  static const int mediaSizeExceededId = 40002;
  static const int mediaFormatUnsupportedId = 40003;
  static const int mediaReadFailedId = 40004;

  static const String storageError = 'ERR_IO_40001';

  // 50xxx: Database & Local SQLite Persistence
  static const int databaseErrorId = 50001;
  static const int databaseConstraintId = 50002;
  static const int databaseSerializationId = 50003;

  static const String databaseError = 'ERR_DB_50001';

  // 60xxx: Monetization & Pass
  static const int monetizationPassRequiredId = 60001;
  static const int monetizationCoinsInsufficientId = 60002;
  static const int monetizationRewardFailedId = 60003;

  // 90xxx: System & Unhandled
  static const int internalUnknownId = 90001;
  static const String internalUnknown = 'ERR_SYS_90001';

  // Legacy string alias mappings for backward compatibility
  static const String validationFailed = 'ERR_VAL_30001';
  static const String validationDuplicate = 'ERR_VAL_30002';
  static const String channelConnectionFailed = 'ERR_CHN_30004';
  static const String channelTokenExpired = 'ERR_CHN_30005';
  static const String channelRateLimited = 'ERR_CHN_30006';
}

/// Core application exception that pairs an immutable numeric [errorId]
/// with distinct user-facing (production) and developer-facing (diagnostics) messages.
class AppException implements Exception {
  final int errorId;
  final String code;
  final String title;
  final String userMessage;
  final String? devDetails;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException({
    required this.errorId,
    String? code,
    required this.title,
    required this.userMessage,
    this.devDetails,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  })  : code = code ?? 'ERR_$errorId',
        timestamp = timestamp ?? DateTime.now().toUtc();

  /// Returns the appropriate message string based on environment flavor.
  /// Production displays polite, actionable guidance with the Error ID for support.
  /// Development displays full technical exceptions and stack context.
  String getEffectiveMessage({required bool isDev}) {
    if (isDev && devDetails != null && devDetails!.isNotEmpty) {
      return '[$errorId] $devDetails';
    }
    return '[$errorId] $userMessage';
  }

  /// Build a safe AppException from any arbitrary caught error.
  factory AppException.from(dynamic error, {StackTrace? stackTrace, String? fallbackTitle, int? overrideErrorId}) {
    if (error is AppException) {
      return error;
    }

    final errStr = error.toString();
    final st = stackTrace ?? (error is Error ? error.stackTrace : null);

    // Network / Socket detection
    if (errStr.contains('SocketException') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('NetworkImageLoadException') ||
        errStr.contains('Connection refused') ||
        errStr.contains('HandshakeException')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.networkUnavailableId,
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
        errorId: overrideErrorId ?? AppErrorCode.networkTimeoutId,
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
        (errStr.contains('sign_in') ||
            errStr.contains('ApiException') ||
            errStr.contains('10:') ||
            errStr.contains('12500') ||
            errStr.contains('GoogleSignIn'))) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.authFailedId,
        code: AppErrorCode.authFailed,
        title: 'Authentication Failed',
        userMessage: 'Sign-in could not be completed with Google. Please check your credentials or contact support with Error ID ${AppErrorCode.authFailedId}.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    if (errStr.contains('401') || errStr.contains('Unauthorized') || errStr.contains('token expired')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.authSessionExpiredId,
        code: AppErrorCode.authSessionExpired,
        title: 'Session Expired',
        userMessage: 'Your active session or access token has expired. Please sign in again to continue.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    if (errStr.contains('403') || errStr.contains('Forbidden') || errStr.contains('permission_denied')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.authPermissionDeniedId,
        code: AppErrorCode.authPermissionDenied,
        title: 'Permission Denied',
        userMessage: 'You do not have permission to perform this action. Contact your workspace administrator.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Rate Limiting (429)
    if (errStr.contains('429') || errStr.contains('Rate limit') || errStr.contains('quota')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.publishRateLimitedId,
        code: 'ERR_RATE_LIMIT_30004',
        title: 'Rate Limit Reached',
        userMessage: 'Platform rate limit reached. Please wait a few minutes before trying again.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Database / Storage detection
    if (errStr.contains('SqliteException') ||
        errStr.contains('database') ||
        errStr.contains('UNIQUE constraint') ||
        errStr.contains('no such table')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.databaseErrorId,
        code: AppErrorCode.databaseError,
        title: 'Local Database Error',
        userMessage: 'A local data operation could not be completed. Your records remain secure.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // File / Media IO detection
    if (errStr.contains('FileSystemException') || errStr.contains('FileNotFoundException') || errStr.contains('PathNotFoundException')) {
      return AppException(
        errorId: overrideErrorId ?? AppErrorCode.mediaMissingId,
        code: AppErrorCode.storageError,
        title: 'Media Asset Missing',
        userMessage: 'The selected media file could not be accessed from disk. Please re-attach the file.',
        devDetails: errStr,
        originalError: error,
        stackTrace: st,
      );
    }

    // Default unknown error
    return AppException(
      errorId: overrideErrorId ?? AppErrorCode.internalUnknownId,
      code: AppErrorCode.internalUnknown,
      title: fallbackTitle ?? 'Unexpected Error',
      userMessage: 'An unexpected issue occurred while processing your request. Please try again or provide Error ID ${overrideErrorId ?? AppErrorCode.internalUnknownId}.',
      devDetails: errStr,
      originalError: error,
      stackTrace: st,
    );
  }

  @override
  String toString() => '[$errorId] $title: $userMessage (dev: $devDetails)';
}
