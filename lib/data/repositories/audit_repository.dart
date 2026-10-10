import 'package:no5ocial/domain/models/audit_event.dart';

abstract class AuditRepository {
  List<AuditEvent> getAllEvents();
  void recordEvent(AuditEvent event);
}

class InMemoryAuditRepository implements AuditRepository {
  final List<AuditEvent> _events = [];

  @override
  List<AuditEvent> getAllEvents() {
    final list = List<AuditEvent>.from(_events);
    list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return list;
  }

  @override
  void recordEvent(AuditEvent event) {
    _events.add(event);
  }
}
