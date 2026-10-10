/// Categorization of provider or client errors.
/// Used to enforce retry rules and prevent duplicate post creation.
enum ErrorCategory {
  validation('Validation Error', isRetryable: false, duplicateRiskOnRetry: false),
  authentication('Authentication Expired', isRetryable: false, duplicateRiskOnRetry: false),
  permission('Permission Denied', isRetryable: false, duplicateRiskOnRetry: false),
  policy('Platform Policy Violation', isRetryable: false, duplicateRiskOnRetry: false),
  rateLimit('Rate Limit Exceeded', isRetryable: true, duplicateRiskOnRetry: false),
  transientNetwork('Network Connectivity', isRetryable: true, duplicateRiskOnRetry: false),
  ambiguousTimeout('Ambiguous Timeout', isRetryable: false, duplicateRiskOnRetry: true),
  providerDown('Provider Outage (5xx)', isRetryable: true, duplicateRiskOnRetry: false),
  userCancelled('Cancelled by User', isRetryable: false, duplicateRiskOnRetry: false),
  unknown('Unknown System Error', isRetryable: false, duplicateRiskOnRetry: true);

  const ErrorCategory(
    this.label, {
    required this.isRetryable,
    required this.duplicateRiskOnRetry,
  });

  final String label;
  final bool isRetryable;
  final bool duplicateRiskOnRetry;
}
