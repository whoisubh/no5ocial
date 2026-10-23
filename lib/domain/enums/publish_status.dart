/// Explicit status for ContentPost and per-destination PublishJob.
enum PublishJobStatus {
  draft('Draft'),
  needsApproval('Needs Approval'),
  scheduled('Scheduled'),
  publishing('Publishing'),
  published('Published'),
  actionRequired('Action Required'),
  failed('Failed'),
  cancelled('Cancelled');

  const PublishJobStatus(this.label);

  final String label;

  bool get isTerminal =>
      this == PublishJobStatus.published ||
      this == PublishJobStatus.failed ||
      this == PublishJobStatus.cancelled;

  bool get isSuccessful => this == PublishJobStatus.published;
  bool get isFailedOrActionNeeded =>
      this == PublishJobStatus.failed || this == PublishJobStatus.actionRequired;
}
