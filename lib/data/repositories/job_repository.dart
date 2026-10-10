import 'package:uuid/uuid.dart';
import 'package:no5ocial/data/local/seed_data.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/publish_attempt.dart';
import 'package:no5ocial/domain/models/publish_job.dart';

abstract class JobRepository {
  List<PublishJob> getAllJobs();
  List<PublishJob> getJobsByPostId(String postId);
  List<PublishJob> getJobsByStatus(PublishJobStatus status);
  PublishJob? getJobById(String id);
  void saveJob(PublishJob job);
  void deleteJob(String id);

  // Attempts
  void recordAttempt(PublishAttempt attempt);
  List<PublishAttempt> getAttemptsForJob(String jobId);

  // Manual handoff confirmation
  PublishJob markJobManuallyPublished({
    required String jobId,
    String? externalUrl,
    String? externalPostId,
  });
}

class InMemoryJobRepository implements JobRepository {
  final Map<String, PublishJob> _jobs = {};
  final List<PublishAttempt> _attempts = [];
  final _uuid = const Uuid();

  InMemoryJobRepository({List<PublishJob>? initialJobs}) {
    for (final job in (initialJobs ?? SeedData.initialJobs)) {
      _jobs[job.id] = job;
    }
  }

  @override
  List<PublishJob> getAllJobs() {
    final list = _jobs.values.toList();
    list.sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
    return list;
  }

  @override
  List<PublishJob> getJobsByPostId(String postId) =>
      _jobs.values.where((j) => j.contentPostId == postId).toList();

  @override
  List<PublishJob> getJobsByStatus(PublishJobStatus status) =>
      _jobs.values.where((j) => j.status == status).toList();

  @override
  PublishJob? getJobById(String id) => _jobs[id];

  @override
  void saveJob(PublishJob job) {
    _jobs[job.id] = job;
  }

  @override
  void deleteJob(String id) {
    _jobs.remove(id);
    _attempts.removeWhere((a) => a.publishJobId == id);
  }

  @override
  void recordAttempt(PublishAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  List<PublishAttempt> getAttemptsForJob(String jobId) =>
      _attempts.where((a) => a.publishJobId == jobId).toList();

  @override
  PublishJob markJobManuallyPublished({
    required String jobId,
    String? externalUrl,
    String? externalPostId,
  }) {
    final existing = _jobs[jobId];
    if (existing == null) {
      throw StateError('Job $jobId not found');
    }

    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      status: PublishJobStatus.published,
      isManual: true,
      publishedAtUtc: now,
      externalUrl: externalUrl,
      externalPostId: externalPostId,
      updatedAtUtc: now,
    );

    _jobs[jobId] = updated;

    // Record an audit attempt
    recordAttempt(
      PublishAttempt(
        id: _uuid.v4(),
        publishJobId: jobId,
        startedAtUtc: now,
        finishedAtUtc: now,
        outcomeStatus: PublishJobStatus.published,
        providerRequestId: 'manual_handoff_user_confirmed',
      ),
    );

    return updated;
  }
}
