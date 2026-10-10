import '../enums/error_category.dart';
import '../enums/publish_status.dart';

/// An individual execution attempt for a PublishJob.
/// Recorded prior to any network or manual action to guarantee auditability.
class PublishAttempt {
  final String id;
  final String publishJobId;
  final DateTime startedAtUtc;
  final DateTime? finishedAtUtc;
  final PublishJobStatus outcomeStatus;
  final ErrorCategory? errorCategory;
  final String? sanitizedError;
  final String? providerRequestId;

  const PublishAttempt({
    required this.id,
    required this.publishJobId,
    required this.startedAtUtc,
    this.finishedAtUtc,
    required this.outcomeStatus,
    this.errorCategory,
    this.sanitizedError,
    this.providerRequestId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'publish_job_id': publishJobId,
        'started_at_utc': startedAtUtc.toIso8601String(),
        'finished_at_utc': finishedAtUtc?.toIso8601String(),
        'outcome_status': outcomeStatus.name,
        'error_category': errorCategory?.name,
        'sanitized_error': sanitizedError,
        'provider_request_id': providerRequestId,
      };

  factory PublishAttempt.fromJson(Map<String, dynamic> json) => PublishAttempt(
        id: json['id'] as String,
        publishJobId: json['publish_job_id'] as String,
        startedAtUtc: DateTime.parse(json['started_at_utc'] as String),
        finishedAtUtc: json['finished_at_utc'] != null
            ? DateTime.parse(json['finished_at_utc'] as String)
            : null,
        outcomeStatus: PublishJobStatus.values.byName(json['outcome_status'] as String),
        errorCategory: json['error_category'] != null
            ? ErrorCategory.values.byName(json['error_category'] as String)
            : null,
        sanitizedError: json['sanitized_error'] as String?,
        providerRequestId: json['provider_request_id'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishAttempt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
