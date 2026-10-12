import 'dart:convert';
/// Audit log event tracking operational modifications, manual confirmations, and status transitions.
class AuditEvent {
  final String id;
  final String actor;
  final String eventType;
  final String entityType;
  final String entityId;
  final String description;
  final Map<String, dynamic> metadataSanitized;
  final DateTime createdAtUtc;

  const AuditEvent({
    required this.id,
    required this.actor,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.description,
    this.metadataSanitized = const {},
    required this.createdAtUtc,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor': actor,
        'event_type': eventType,
        'entity_type': entityType,
        'entity_id': entityId,
        'description': description,
        'metadata_sanitized': metadataSanitized,
        'created_at_utc': createdAtUtc.toIso8601String(),
      };

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> meta = {};
    final rawMeta = json['metadata_sanitized'] ?? json['metadata_json'];
    if (rawMeta is Map) {
      meta = rawMeta.cast<String, dynamic>();
    } else if (rawMeta is String) {
      try {
        final dec = jsonDecode(rawMeta);
        if (dec is Map) meta = dec.cast<String, dynamic>();
      } catch (_) {}
    }

    return AuditEvent(
      id: json['id'] as String,
      actor: json['actor'] as String? ?? 'System',
      eventType: json['event_type'] as String? ?? 'UNKNOWN',
      entityType: json['entity_type'] as String? ?? 'UNKNOWN',
      entityId: json['entity_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      metadataSanitized: meta,
      createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '') ?? DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
