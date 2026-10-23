/// Workspace operational mode chosen during onboarding or organization settings.
enum WorkspaceMode {
  solo('Just Me', 'I solely manage all content, channels, and scheduling myself.'),
  team('Team Hierarchy', 'I will collaborate with others and invite team members with specific roles.');

  const WorkspaceMode(this.label, this.description);

  final String label;
  final String description;

  bool get isTeam => this == WorkspaceMode.team;
  bool get isSolo => this == WorkspaceMode.solo;

  static WorkspaceMode fromString(String? value) {
    if (value == null) return WorkspaceMode.solo;
    return WorkspaceMode.values.firstWhere(
      (m) => m.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkspaceMode.solo,
    );
  }
}
