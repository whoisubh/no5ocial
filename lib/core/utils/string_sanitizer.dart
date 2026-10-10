/// Utilities to sanitize and redact sensitive strings, tokens, and authorization headers.
/// Enforces requirements from SECURITY.md and AGENTS.md.
abstract final class StringSanitizer {
  static final RegExp _bearerPattern = RegExp(
    r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final RegExp _tokenParamPattern = RegExp(
    r'(access_token|refresh_token|client_secret|client_id|token|secret|password|api_key|apikey)=([^\s&]+)',
    caseSensitive: false,
  );

  static final RegExp _authorizationHeaderPattern = RegExp(
    r'("?authorization"?\s*:\s*"?)[^"\r\n]+("?)',
    caseSensitive: false,
  );

  /// Redacts sensitive bearer tokens, query parameters, and passwords from [raw].
  static String redact(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    String sanitized = raw;

    // Redact Bearer tokens
    sanitized = sanitized.replaceAllMapped(_bearerPattern, (match) {
      return '${match.group(1)}[REDACTED_TOKEN]';
    });

    // Redact query parameter or json key secrets
    sanitized = sanitized.replaceAllMapped(_tokenParamPattern, (match) {
      final key = match.group(1);
      return '$key=[REDACTED]';
    });

    // Redact Authorization headers
    sanitized = sanitized.replaceAllMapped(_authorizationHeaderPattern, (match) {
      final prefix = match.group(1);
      final suffix = match.group(2) ?? '';
      return '$prefix[REDACTED_AUTH]$suffix';
    });

    return sanitized;
  }

  /// Truncates string cleanly with ellipsis if it exceeds [maxLength].
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}…';
  }
}
