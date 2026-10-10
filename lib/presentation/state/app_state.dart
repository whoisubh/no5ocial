import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:no5ocial/core/utils/string_sanitizer.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/publishing_adapter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/audit_event.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_attempt.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';

class AppState extends ChangeNotifier {
  final BrandRepository brandRepository;
  final AccountRepository accountRepository;
  final PostRepository postRepository;
  final JobRepository jobRepository;
  final AuditRepository auditRepository;
  final PublishingAdapter? publishingAdapter;

  final _uuid = const Uuid();

  // Active filters and settings
  String? selectedBrandFilterId;
  PublishJobStatus? selectedStatusFilter;
  String searchQuery = '';
  String userTimezone = 'Local (UTC+5:30)';

  AppState({
    required this.brandRepository,
    required this.accountRepository,
    required this.postRepository,
    required this.jobRepository,
    required this.auditRepository,
    this.publishingAdapter,
  });

  // Accessors
  List<Brand> get brands => brandRepository.getAllBrands();
  List<SocialAccount> get accounts => accountRepository.getAllAccounts();
  List<MediaAsset> get mediaAssets => postRepository.getAllMediaAssets();

  List<ContentPost> get allPosts => postRepository.getAllPosts();

  List<ContentPost> get filteredPosts {
    var list = postRepository.getAllPosts();

    if (selectedBrandFilterId != null) {
      list = list.where((p) => p.brandId == selectedBrandFilterId).toList();
    }

    if (selectedStatusFilter != null) {
      list = list.where((p) => p.status == selectedStatusFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.defaultCaption.toLowerCase().contains(query) ||
            (p.campaign?.toLowerCase().contains(query) ?? false) ||
            p.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    return list;
  }

  List<PublishJob> get allJobs => jobRepository.getAllJobs();

  List<PublishJob> get pendingAndFailedJobs {
    return allJobs
        .where((j) =>
            j.status == PublishJobStatus.actionRequired ||
            j.status == PublishJobStatus.failed ||
            j.status == PublishJobStatus.scheduled)
        .toList();
  }

  List<PublishJob> getJobsForPost(String postId) {
    return jobRepository.getJobsByPostId(postId);
  }

  List<PostVariant> getVariantsForPost(String postId) {
    return postRepository.getVariantsForPost(postId);
  }

  Brand? getBrandById(String id) => brandRepository.getBrandById(id);
  SocialAccount? getAccountById(String id) => accountRepository.getAccountById(id);
  MediaAsset? getMediaAssetById(String id) => postRepository.getMediaAssetById(id);

  // Summary Metrics
  int get draftCount =>
      allPosts.where((p) => p.status == PublishJobStatus.draft).length;
  int get scheduledCount =>
      allPosts.where((p) => p.status == PublishJobStatus.scheduled).length;
  int get publishedCount =>
      allPosts.where((p) => p.status == PublishJobStatus.published).length;
  int get actionRequiredCount => allJobs
      .where((j) =>
          j.status == PublishJobStatus.actionRequired ||
          j.status == PublishJobStatus.failed)
      .length;

  // Filter modifiers
  void setBrandFilter(String? brandId) {
    selectedBrandFilterId = brandId;
    notifyListeners();
  }

  void setStatusFilter(PublishJobStatus? status) {
    selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // --- Core CRUD Operations ---

  /// Creates or updates a ContentPost along with its per-destination variants.
  ContentPost saveDraft({
    String? postId,
    required String brandId,
    required String title,
    required String defaultCaption,
    List<String> destinationAccountIds = const [],
    List<String> mediaAssetIds = const [],
    List<String> tags = const [],
    String? campaign,
    DateTime? scheduledAtUtc,
    Map<String, String>? captionOverridesByAccount,
  }) {
    final now = DateTime.now().toUtc();
    final effectiveId = postId ?? _uuid.v4();

    final post = ContentPost(
      id: effectiveId,
      brandId: brandId,
      title: title,
      defaultCaption: defaultCaption,
      destinationAccountIds: destinationAccountIds,
      mediaAssetIds: mediaAssetIds,
      tags: tags,
      campaign: campaign,
      status: scheduledAtUtc != null ? PublishJobStatus.scheduled : PublishJobStatus.draft,
      scheduledAtUtc: scheduledAtUtc,
      createdAtUtc: now,
      updatedAtUtc: now,
    );

    postRepository.savePost(post);

    // Save or update variants
    for (final accId in destinationAccountIds) {
      final override = captionOverridesByAccount?[accId];
      final existingVariant = postRepository.getVariant(effectiveId, accId);

      final variant = PostVariant(
        id: existingVariant?.id ?? _uuid.v4(),
        contentPostId: effectiveId,
        socialAccountId: accId,
        captionOverride: override,
        mediaAssetIds: mediaAssetIds,
      );
      postRepository.saveVariant(variant);
    }

    _recordAudit(
      eventType: postId == null ? 'DRAFT_CREATED' : 'DRAFT_UPDATED',
      entityType: 'ContentPost',
      entityId: effectiveId,
      description: 'Draft "$title" saved with ${destinationAccountIds.length} destination(s).',
    );

    notifyListeners();
    return post;
  }

  /// Initiates independent publishing or queueing across all selected destinations.
  /// Enforces: Each destination has an independent publish job and status.
  /// A failed destination must NOT erase successful publishes to other destinations.
  Future<List<PublishJob>> publishOrQueuePost({
    required ContentPost post,
    Map<String, String>? captionOverridesByAccount,
    bool isScheduled = false,
  }) async {
    final now = DateTime.now().toUtc();
    final createdJobs = <PublishJob>[];
    final postBrand = brandRepository.getBrandById(post.brandId);

    // Save/update the post
    postRepository.savePost(post.copyWith(
      status: isScheduled ? PublishJobStatus.scheduled : PublishJobStatus.publishing,
      updatedAtUtc: now,
    ));

    final attachedMedia = post.mediaAssetIds
        .map((id) => postRepository.getMediaAssetById(id))
        .whereType<MediaAsset>()
        .toList();

    for (final accountId in post.destinationAccountIds) {
      final account = accountRepository.getAccountById(accountId);
      if (account == null) continue;

      final variant = postRepository.getVariant(post.id, accountId) ??
          PostVariant(
            id: _uuid.v4(),
            contentPostId: post.id,
            socialAccountId: accountId,
            captionOverride: captionOverridesByAccount?[accountId],
            mediaAssetIds: post.mediaAssetIds,
          );
      postRepository.saveVariant(variant);

      // Preflight validation
      final preflight = PreflightValidator.validate(
        post: post,
        variant: variant,
        account: account,
        postBrand: postBrand,
        accountBrand: brandRepository.getBrandById(account.brandId),
        attachedMedia: attachedMedia,
      );

      final jobId = _uuid.v4();
      final idempotencyKey = _uuid.v4();

      if (!preflight.isValid) {
        // Blocked by preflight
        final firstBlocker = preflight.blockers.first;
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.actionRequired,
          isManual: account.isManualOnly,
          idempotencyKey: idempotencyKey,
          lastErrorCode: firstBlocker.code,
          lastErrorCategory: ErrorCategory.validation,
          lastErrorMessage: firstBlocker.message,
          lastErrorAtUtc: now,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      if (isScheduled) {
        // Enqueue scheduled job
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.scheduled,
          isManual: account.isManualOnly,
          scheduledAtUtc: post.scheduledAtUtc ?? now.add(const Duration(hours: 2)),
          idempotencyKey: idempotencyKey,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      if (account.isManualOnly) {
        // Needs manual handoff
        final job = PublishJob(
          id: jobId,
          contentPostId: post.id,
          postVariantId: variant.id,
          socialAccountId: accountId,
          status: PublishJobStatus.actionRequired,
          isManual: true,
          idempotencyKey: idempotencyKey,
          lastErrorCode: 'MANUAL_HANDOFF_REQUIRED',
          lastErrorCategory: ErrorCategory.unknown,
          lastErrorMessage: 'Manual publishing handoff required for ${account.platform.displayName}.',
          lastErrorAtUtc: now,
          createdAtUtc: now,
          updatedAtUtc: now,
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
        continue;
      }

      // Live publishing attempt via adapter
      final initialJob = PublishJob(
        id: jobId,
        contentPostId: post.id,
        postVariantId: variant.id,
        socialAccountId: accountId,
        status: PublishJobStatus.publishing,
        attemptCount: 1,
        idempotencyKey: idempotencyKey,
        createdAtUtc: now,
        updatedAtUtc: now,
      );
      jobRepository.saveJob(initialJob);

      // Record pre-execution attempt per ARCHITECTURE.md
      jobRepository.recordAttempt(
        PublishAttempt(
          id: _uuid.v4(),
          publishJobId: jobId,
          startedAtUtc: now,
          outcomeStatus: PublishJobStatus.publishing,
          providerRequestId: 'req_$idempotencyKey',
        ),
      );

      if (publishingAdapter != null) {
        try {
          final result = await publishingAdapter!.publishNow(
            post: post,
            variant: variant,
            account: account,
            idempotencyKey: idempotencyKey,
            attachedMedia: attachedMedia,
          );

          final finishedNow = DateTime.now().toUtc();
          if (result.isSuccess) {
            final finishedJob = initialJob.copyWith(
              status: PublishJobStatus.published,
              publishedAtUtc: finishedNow,
              externalPostId: result.externalPostId,
              externalUrl: result.externalUrl,
              updatedAtUtc: finishedNow,
            );
            jobRepository.saveJob(finishedJob);
            createdJobs.add(finishedJob);

            jobRepository.recordAttempt(
              PublishAttempt(
                id: _uuid.v4(),
                publishJobId: jobId,
                startedAtUtc: now,
                finishedAtUtc: finishedNow,
                outcomeStatus: PublishJobStatus.published,
                providerRequestId: result.externalPostId,
              ),
            );
          } else {
            final failedJob = initialJob.copyWith(
              status: PublishJobStatus.failed,
              lastErrorCode: result.rawErrorCode,
              lastErrorCategory: result.errorCategory,
              lastErrorMessage: result.sanitizedErrorMessage,
              lastErrorAtUtc: finishedNow,
              updatedAtUtc: finishedNow,
            );
            jobRepository.saveJob(failedJob);
            createdJobs.add(failedJob);

            jobRepository.recordAttempt(
              PublishAttempt(
                id: _uuid.v4(),
                publishJobId: jobId,
                startedAtUtc: now,
                finishedAtUtc: finishedNow,
                outcomeStatus: PublishJobStatus.failed,
                errorCategory: result.errorCategory,
                sanitizedError: result.sanitizedErrorMessage,
              ),
            );
          }
        } catch (e) {
          final finishedNow = DateTime.now().toUtc();
          final failedJob = initialJob.copyWith(
            status: PublishJobStatus.failed,
            lastErrorCode: 'EXCEPTION',
            lastErrorCategory: ErrorCategory.unknown,
            lastErrorMessage: StringSanitizer.redact(e.toString()),
            lastErrorAtUtc: finishedNow,
            updatedAtUtc: finishedNow,
          );
          jobRepository.saveJob(failedJob);
          createdJobs.add(failedJob);
        }
      } else {
        // No adapter connected, mark as action required
        final job = initialJob.copyWith(
          status: PublishJobStatus.actionRequired,
          lastErrorMessage: 'No live publishing adapter configured for this platform.',
        );
        jobRepository.saveJob(job);
        createdJobs.add(job);
      }
    }

    _updateMasterPostStatus(post.id);
    notifyListeners();
    return createdJobs;
  }

  /// Completes a manual publishing handoff.
  /// Enforces: "Mark as manually published only after user confirmation; optionally capture the post URL. Clearly label it Manual, never pretend it was API-published."
  PublishJob confirmManualHandoff({
    required String jobId,
    String? externalPostUrl,
  }) {
    final updated = jobRepository.markJobManuallyPublished(
      jobId: jobId,
      externalUrl: externalPostUrl,
      externalPostId: 'manual_${_uuid.v4().substring(0, 8)}',
    );

    _recordAudit(
      eventType: 'MANUAL_PUBLISH_CONFIRMED',
      entityType: 'PublishJob',
      entityId: jobId,
      description: 'Operator confirmed manual publication. URL: ${externalPostUrl ?? "N/A"}',
      metadata: {'is_manual': true, 'url': externalPostUrl},
    );

    _updateMasterPostStatus(updated.contentPostId);
    notifyListeners();
    return updated;
  }

  /// Retries a failed publish job after verifying duplicate safety.
  Future<PublishJob?> retryJob({
    required String jobId,
    bool forceDuplicateWarningAccepted = false,
  }) async {
    final job = jobRepository.getJobById(jobId);
    if (job == null) return null;

    if (job.hasDuplicateRiskOnRetry && !forceDuplicateWarningAccepted) {
      throw StateError(
        'DUPLICATE_RISK: Outcome is ambiguous. Confirmation required to prevent duplicate post.',
      );
    }

    final now = DateTime.now().toUtc();
    final retryingJob = job.copyWith(
      status: PublishJobStatus.publishing,
      attemptCount: job.attemptCount + 1,
      updatedAtUtc: now,
    );
    jobRepository.saveJob(retryingJob);
    notifyListeners();

    final account = accountRepository.getAccountById(job.socialAccountId);
    final post = postRepository.getPostById(job.contentPostId);
    final variant = postRepository.getVariant(job.contentPostId, job.socialAccountId);

    if (publishingAdapter != null && account != null && post != null && variant != null) {
      final attachedMedia = post.mediaAssetIds
          .map((id) => postRepository.getMediaAssetById(id))
          .whereType<MediaAsset>()
          .toList();

      final result = await publishingAdapter!.publishNow(
        post: post,
        variant: variant,
        account: account,
        idempotencyKey: '${job.idempotencyKey}_retry_${job.attemptCount + 1}',
        attachedMedia: attachedMedia,
      );

      final finishedNow = DateTime.now().toUtc();
      if (result.isSuccess) {
        final finished = retryingJob.copyWith(
          status: PublishJobStatus.published,
          publishedAtUtc: finishedNow,
          externalPostId: result.externalPostId,
          externalUrl: result.externalUrl,
          updatedAtUtc: finishedNow,
        );
        jobRepository.saveJob(finished);
        _updateMasterPostStatus(post.id);
        notifyListeners();
        return finished;
      } else {
        final failed = retryingJob.copyWith(
          status: PublishJobStatus.failed,
          lastErrorCode: result.rawErrorCode,
          lastErrorCategory: result.errorCategory,
          lastErrorMessage: result.sanitizedErrorMessage,
          lastErrorAtUtc: finishedNow,
          updatedAtUtc: finishedNow,
        );
        jobRepository.saveJob(failed);
        _updateMasterPostStatus(post.id);
        notifyListeners();
        return failed;
      }
    }

    notifyListeners();
    return retryingJob;
  }

  void updateAccountConnection(String accountId, ConnectionStatus status) {
    accountRepository.updateConnectionStatus(accountId, status);
    _recordAudit(
      eventType: 'ACCOUNT_STATUS_CHANGED',
      entityType: 'SocialAccount',
      entityId: accountId,
      description: 'Account status updated to ${status.label}.',
    );
    notifyListeners();
  }

  void deletePost(String postId) {
    postRepository.deletePost(postId);
    final jobs = jobRepository.getJobsByPostId(postId);
    for (final j in jobs) {
      jobRepository.deleteJob(j.id);
    }
    _recordAudit(
      eventType: 'POST_DELETED',
      entityType: 'ContentPost',
      entityId: postId,
      description: 'Deleted post and associated jobs.',
    );
    notifyListeners();
  }

  void setTimezone(String tz) {
    userTimezone = tz;
    notifyListeners();
  }

  void _updateMasterPostStatus(String postId) {
    final post = postRepository.getPostById(postId);
    if (post == null) return;

    final jobs = jobRepository.getJobsByPostId(postId);
    if (jobs.isEmpty) return;

    final allPublished = jobs.every((j) => j.status == PublishJobStatus.published);
    final anyFailed = jobs.any((j) => j.status == PublishJobStatus.failed);
    final anyAction = jobs.any((j) => j.status == PublishJobStatus.actionRequired);
    final anyPublishing = jobs.any((j) => j.status == PublishJobStatus.publishing);
    final anyScheduled = jobs.any((j) => j.status == PublishJobStatus.scheduled);

    PublishJobStatus overall;
    if (allPublished) {
      overall = PublishJobStatus.published;
    } else if (anyFailed || anyAction) {
      overall = PublishJobStatus.actionRequired;
    } else if (anyPublishing) {
      overall = PublishJobStatus.publishing;
    } else if (anyScheduled) {
      overall = PublishJobStatus.scheduled;
    } else {
      overall = PublishJobStatus.draft;
    }

    postRepository.savePost(post.copyWith(
      status: overall,
      updatedAtUtc: DateTime.now().toUtc(),
    ));
  }

  void _recordAudit({
    required String eventType,
    required String entityType,
    required String entityId,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) {
    auditRepository.recordEvent(
      AuditEvent(
        id: _uuid.v4(),
        actor: 'operator@shaadow.io',
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        description: description,
        metadataSanitized: metadata,
        createdAtUtc: DateTime.now().toUtc(),
      ),
    );
  }
}
