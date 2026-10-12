import 'package:no5ocial/data/database/app_database.dart';
import 'package:no5ocial/domain/models/audit_event.dart';

abstract class AuditRepository {
  List<AuditEvent> getAllEvents();
  void recordEvent(AuditEvent event);
}

class SqliteAuditRepository implements AuditRepository {
  final List<AuditEvent> _events = [];
  final AppDatabase _db = AppDatabase.instance;

  Future<void> init() async {
    final list = await _db.getAllAuditEvents();
    if (list.isNotEmpty) {
      _events.clear();
      _events.addAll(list);
    }
  }

  @override
  List<AuditEvent> getAllEvents() {
    final list = List<AuditEvent>.from(_events);
    list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return list;
  }

  @override
  void recordEvent(AuditEvent event) {
    _events.add(event);
    _db.saveAuditEvent(event).catchError((_) {});
  }
}

class InMemoryAuditRepository extends SqliteAuditRepository {}

