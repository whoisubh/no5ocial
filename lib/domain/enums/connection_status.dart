/// Connection state of a connected social account.
enum ConnectionStatus {
  connected('Connected', 'Account is active and ready to publish.'),
  expired('Token Expired', 'OAuth token expired. Re-authorization required.'),
  actionRequired('Action Required', 'Missing permission or verification on platform.'),
  disconnected('Disconnected', 'Account connection severed or logged out.');

  const ConnectionStatus(this.label, this.description);

  final String label;
  final String description;

  bool get isPublishable => this == ConnectionStatus.connected;
}
