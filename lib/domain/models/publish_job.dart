import '../enums/error_category.dart';
import '../enums/publish_status.dart';

/// Independent publish job for a specific destination account.
/// Enforces: "A multi-destination publish tracks each destination independently."
class PublishJob {
  final String id;
  final String contentPostId;
  final String postVariantId;
  final String socialAccountId;
  final PublishJobStatus status;
  final bool isManual;
  final DateTime? scheduledAtUtc;
  final DateTime? publishedAtUtc;
  final int attemptCount;
  final String idempotencyKey;
  final String? externalPostId;
  final String? externalUrl;
  final String? lastErrorCode;
  final ErrorCategory? lastErrorCategory;
  final String? lastErrorMessage;
  final DateTime? lastErrorAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  const PublishJob({
    required this.id,
    required this.contentPostId,
    required this.postVariantId,
    required this.socialAccountId,
    this.status = PublishJobStatus.draft,
    this.isManual = false,
    this.scheduledAtUtc,
    this.publishedAtUtc,
    this.attemptCount = 0,
    required this.idempotencyKey,
    this.externalPostId,
    this.externalUrl,
    this.lastErrorCode,
    this.lastErrorCategory,
    this.lastErrorMessage,
    this.lastErrorAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  /// True if retry is safe and advised (transient failure without duplicate danger).
  bool get canSafelyRetry =>
      status == PublishJobStatus.failed &&
      (lastErrorCategory?.isRetryable ?? false) &&
      !(lastErrorCategory?.duplicateRiskOnRetry ?? false);

  /// True if retrying carries potential duplicate risk (e.g. ambiguous timeout).
  bool get hasDuplicateRiskOnRetry =>
      status == PublishJobStatus.failed &&
      (lastErrorCategory?.duplicateRiskOnRetry ?? false);

  PublishJob copyWith({
    String? id,
    String? contentPostId,
    String? postVariantId,
    String? socialAccountId,
    PublishJobStatus? status,
    bool? isManual,
    DateTime? scheduledAtUtc,
    DateTime? publishedAtUtc,
    int? attemptCount,
    String? idempotencyKey,
    String? externalPostId,
    String? externalUrl,
    String? lastErrorCode,
    ErrorCategory? lastErrorCategory,
    String? lastErrorMessage,
    DateTime? lastErrorAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return PublishJob(
      id: id ?? this.id,
      contentPostId: contentPostId ?? this.contentPostId,
      postVariantId: postVariantId ?? this.postVariantId,
      socialAccountId: socialAccountId ?? this.socialAccountId,
      status: status ?? this.status,
      isManual: isManual ?? this.isManual,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      publishedAtUtc: publishedAtUtc ?? this.publishedAtUtc,
      attemptCount: attemptCount ?? this.attemptCount,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      externalPostId: externalPostId ?? this.externalPostId,
      externalUrl: externalUrl ?? this.externalUrl,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorCategory: lastErrorCategory ?? this.lastErrorCategory,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      lastErrorAtUtc: lastErrorAtUtc ?? this.lastErrorAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content_post_id': contentPostId,
        'post_variant_id': postVariantId,
        'social_account_id': socialAccountId,
        'status': status.name,
        'is_manual': isManual,
        'scheduled_at_utc': scheduledAtUtc?.toIso8601String(),
        'published_at_utc': publishedAtUtc?.toIso8601String(),
        'attempt_count': attemptCount,
        'idempotency_key': idempotencyKey,
        'external_post_id': externalPostId,
        'external_url': externalUrl,
        'last_error_code': lastErrorCode,
        'last_error_category': lastErrorCategory?.name,
        'last_error_message': lastErrorMessage,
        'last_error_at_utc': lastErrorAtUtc?.toIso8601String(),
        'created_at_utc': createdAtUtc.toIso8601String(),
        'updated_at_utc': updatedAtUtc.toIso8601String(),
      };

  factory PublishJob.fromJson(Map<String, dynamic> json) => PublishJob(
        id: json['id'] as String,
        contentPostId: json['content_post_id'] as String,
        postVariantId: json['post_variant_id'] as String,
        socialAccountId: json['social_account_id'] as String,
        status: PublishJobStatus.values.byName(json['status'] as String),
        isManual: json['is_manual'] as bool? ?? false,
        scheduledAtUtc: json['scheduled_at_utc'] != null
            ? DateTime.parse(json['scheduled_at_utc'] as String)
            : null,
        publishedAtUtc: json['published_at_utc'] != null
            ? DateTime.parse(json['published_at_utc'] as String)
            : null,
        attemptCount: json['attempt_count'] as int? ?? 0,
        idempotencyKey: json['idempotency_key'] as String,
        externalPostId: json['external_post_id'] as String?,
        externalUrl: json['external_url'] as String?,
        lastErrorCode: json['last_error_code'] as String?,
        lastErrorCategory: json['last_error_category'] != null
            ? ErrorCategory.values.byName(json['last_error_category'] as String)
            : null,
        lastErrorMessage: json['last_error_message'] as String?,
        lastErrorAtUtc: json['last_error_at_utc'] != null
            ? DateTime.parse(json['last_error_at_utc'] as String)
            : null,
        createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
        updatedAtUtc: DateTime.parse(json['updated_at_utc'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PublishJob && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
