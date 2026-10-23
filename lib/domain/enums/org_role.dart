/// Role-Based Access Control (RBAC) levels for organizations.
/// Modelled on granular channel management hierarchies (like YouTube permissions).
enum OrgRole {
  owner('Owner', 5, 'Full control over the organization, billing, and team ownership.'),
  manager('Manager', 4, 'Manage all brands, channels, and invite team members up to SMM level.'),
  smm('Social Media Manager', 3, 'Create, schedule, and publish posts. Link and manage channels and groups.'),
  uploader('Uploader', 2, 'Upload media and create drafts. Submissions enter the review queue for approval.'),
  analyst('Analyst', 1, 'Read-only access to view growth, metrics, calendar, and published posts.');

  const OrgRole(this.label, this.level, this.description);

  final String label;
  final int level;
  final String description;

  /// Whether this role can publish posts directly to live social networks.
  bool get canPublishDirectly => level >= 3;

  /// Whether this role can create drafts and upload media.
  bool get canCreateDrafts => level >= 2;

  /// Whether this role can edit other team members' draft posts.
  bool get canEditOthersDrafts => level >= 3;

  /// Whether this role can approve drafts submitted by Uploaders.
  bool get canApproveSubmissions => level >= 3;

  /// Whether this role can link and configure social accounts and channel groups.
  bool get canManageChannels => level >= 3;

  /// Whether this role can invite or remove members up to SMM level.
  bool get canInviteMembers => level >= 4;

  /// Whether this role can invite or promote other Managers.
  bool get canInviteManagers => level >= 5;

  /// Whether this role can register or delete brands/companies.
  bool get canManageBrands => level >= 4;

  /// Whether this role can delete the organization or transfer ownership.
  bool get canDeleteOrg => level >= 5;

  /// Whether this role has read-only restrictions.
  bool get isReadOnly => level <= 1;

  static OrgRole fromString(String? value) {
    if (value == null) return OrgRole.owner;
    return OrgRole.values.firstWhere(
      (r) => r.name.toLowerCase() == value.toLowerCase() || r.label.toLowerCase() == value.toLowerCase(),
      orElse: () => OrgRole.uploader,
    );
  }
}
