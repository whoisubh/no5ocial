enum PrivacyStatus {
  public('Public', 'Visible to everyone'),
  unlisted('Unlisted', 'Visible only to those with the link'),
  private('Private', 'Visible only to the account owner');

  const PrivacyStatus(this.label, this.description);
  final String label;
  final String description;
}
