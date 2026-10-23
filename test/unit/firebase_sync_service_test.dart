import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/core/services/firebase_sync_service.dart';
import 'package:no5ocial/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('FirebaseSyncService Tests', () {
    test('Initializes with default idle status and null last sync', () {
      final service = FirebaseSyncService.instance;
      expect(service.status, equals(FirebaseSyncStatus.idle));
      expect(service.lastError, isNull);
    });

    test('Formatted last sync displays human readable intervals', () {
      final service = FirebaseSyncService.instance;
      expect(service.formattedLastSync, equals('Never synced'));
    });

    test('syncUserWorkspace handles empty user id safely', () async {
      final service = FirebaseSyncService.instance;
      final result = await service.syncUserWorkspace('');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('User ID cannot be empty'));
    });

    test('SyncService bridges with FirebaseSyncService cleanly', () async {
      final sync = SyncService.instance;
      await sync.init();
      expect(sync.status, equals(SyncStatus.idle));
    });
  });
}
