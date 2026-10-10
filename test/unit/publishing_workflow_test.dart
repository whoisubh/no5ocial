import 'package:flutter_test/flutter_test.dart';
import 'package:no5ocial/data/repositories/account_repository.dart';
import 'package:no5ocial/data/repositories/audit_repository.dart';
import 'package:no5ocial/data/repositories/brand_repository.dart';
import 'package:no5ocial/data/repositories/job_repository.dart';
import 'package:no5ocial/data/repositories/post_repository.dart';
import 'package:no5ocial/domain/adapters/fake_publishing_adapter.dart';
import 'package:no5ocial/domain/adapters/publishing_adapter.dart';
import 'package:no5ocial/domain/enums/connection_status.dart';
import 'package:no5ocial/domain/enums/error_category.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/brand.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';
import 'package:no5ocial/domain/models/publish_job.dart';
import 'package:no5ocial/domain/models/social_account.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

void main() {
  group('Publishing Workflow & Resilience Tests', () {
    late InMemoryBrandRepository brandRepo;
    late InMemoryAccountRepository accountRepo;
    late InMemoryPostRepository postRepo;
    late InMemoryJobRepository jobRepo;
    late InMemoryAuditRepository auditRepo;

    final testBrand = Brand(
      id: 'brand-test',
      name: 'Test Brand',
      slug: 'test-brand',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    final acc1 = SocialAccount(
      id: 'acc-1',
      brandId: testBrand.id,
      platform: PlatformType.linkedin,
      displayName: 'LinkedIn Account',
      handle: 'LinkedIn Company',
      connectionStatus: ConnectionStatus.connected,
    );

    final acc2 = SocialAccount(
      id: 'acc-2',
      brandId: testBrand.id,
      platform: PlatformType.x,
      displayName: 'X Account',
      handle: '@x_account',
      connectionStatus: ConnectionStatus.connected,
    );

    setUp(() {
      brandRepo = InMemoryBrandRepository(initialData: [testBrand]);
      accountRepo = InMemoryAccountRepository(initialData: [acc1, acc2]);
      postRepo = InMemoryPostRepository(initialPosts: [], initialVariants: [], initialMedia: []);
      jobRepo = InMemoryJobRepository(initialJobs: []);
      auditRepo = InMemoryAuditRepository();
    });

    test('Partial failure does not roll back successful destinations', () async {
      // Custom fake adapter where acc1 succeeds and acc2 fails
      final selectiveAdapter = _SelectiveFakeAdapter(
        succeedingAccountIds: {acc1.id},
      );

      final appState = AppState(
        brandRepository: brandRepo,
        accountRepository: accountRepo,
        postRepository: postRepo,
        jobRepository: jobRepo,
        auditRepository: auditRepo,
        publishingAdapter: selectiveAdapter,
      );

      final post = appState.saveDraft(
        brandId: testBrand.id,
        title: 'Multi Target Announcement',
        defaultCaption: 'Shared caption content for multi-target',
        destinationAccountIds: [acc1.id, acc2.id],
      );

      final jobs = await appState.publishOrQueuePost(post: post);

      expect(jobs.length, equals(2));

      final job1 = jobs.firstWhere((j) => j.socialAccountId == acc1.id);
      final job2 = jobs.firstWhere((j) => j.socialAccountId == acc2.id);

      // Account 1 must be published
      expect(job1.status, equals(PublishJobStatus.published));
      expect(job1.externalPostId, isNotNull);

      // Account 2 must be failed
      expect(job2.status, equals(PublishJobStatus.failed));

      // Success of Job 1 is intact and persisted independently!
      final retrievedJob1 = jobRepo.getJobById(job1.id);
      expect(retrievedJob1?.status, equals(PublishJobStatus.published));
    });

    test('Ambiguous timeout triggers duplicate-risk protection on retry', () async {
      final timeoutAdapter = const FakePublishingAdapter(
        shouldSimulateTimeout: true,
      );

      final appState = AppState(
        brandRepository: brandRepo,
        accountRepository: accountRepo,
        postRepository: postRepo,
        jobRepository: jobRepo,
        auditRepository: auditRepo,
        publishingAdapter: timeoutAdapter,
      );

      final post = appState.saveDraft(
        brandId: testBrand.id,
        title: 'Timeout Post',
        defaultCaption: 'Caption text',
        destinationAccountIds: [acc1.id],
      );

      final jobs = await appState.publishOrQueuePost(post: post);
      final job = jobs.first;

      expect(job.status, equals(PublishJobStatus.failed));
      expect(job.hasDuplicateRiskOnRetry, isTrue);

      // Attempting blind retry without accepting duplicate warning must throw StateError
      expect(
        () => appState.retryJob(jobId: job.id, forceDuplicateWarningAccepted: false),
        throwsA(isA<StateError>()),
      );

      // Retrying with explicit confirmation succeeds
      final retried = await appState.retryJob(
        jobId: job.id,
        forceDuplicateWarningAccepted: true,
      );
      expect(retried, isNotNull);
      expect(retried?.attemptCount, equals(2));
    });

    test('Manual handoff confirmation captures post URL and labels as manual', () {
      final appState = AppState(
        brandRepository: brandRepo,
        accountRepository: accountRepo,
        postRepository: postRepo,
        jobRepository: jobRepo,
        auditRepository: auditRepo,
      );

      final post = appState.saveDraft(
        brandId: testBrand.id,
        title: 'Manual Post',
        defaultCaption: 'Manual copy',
        destinationAccountIds: [acc2.id],
      );

      final initialJob = PublishJob(
        id: 'job-manual-1',
        contentPostId: post.id,
        postVariantId: 'var-1',
        socialAccountId: acc2.id,
        status: PublishJobStatus.actionRequired,
        isManual: true,
        idempotencyKey: 'idem-1',
        createdAtUtc: DateTime.now().toUtc(),
        updatedAtUtc: DateTime.now().toUtc(),
      );
      jobRepo.saveJob(initialJob);

      final confirmedJob = appState.confirmManualHandoff(
        jobId: initialJob.id,
        externalPostUrl: 'https://x.com/shaadow/status/123456789',
      );

      expect(confirmedJob.status, equals(PublishJobStatus.published));
      expect(confirmedJob.isManual, isTrue);
      expect(confirmedJob.externalUrl, equals('https://x.com/shaadow/status/123456789'));
      expect(confirmedJob.publishedAtUtc, isNotNull);

      // Verify audit trail recorded event
      final auditEvents = auditRepo.getAllEvents();
      expect(auditEvents.any((e) => e.eventType == 'MANUAL_PUBLISH_CONFIRMED'), isTrue);
    });
  });
}

class _SelectiveFakeAdapter extends FakePublishingAdapter {
  final Set<String> succeedingAccountIds;

  const _SelectiveFakeAdapter({required this.succeedingAccountIds});

  @override
  Future<PublishExecutionResult> publishNow({
    required ContentPost post,
    required PostVariant variant,
    required SocialAccount account,
    required String idempotencyKey,
    List<MediaAsset> attachedMedia = const [],
  }) async {
    if (succeedingAccountIds.contains(account.id)) {
      return PublishExecutionResult.success(
        externalPostId: 'success_${account.id}',
        externalUrl: 'https://example.com/post/${account.id}',
      );
    }
    return const PublishExecutionResult.failure(
      errorCategory: ErrorCategory.providerDown,
      rawErrorCode: '500_OUTAGE',
      sanitizedErrorMessage: 'Destination server down. Failure isolated to this account.',
    );
  }
}
