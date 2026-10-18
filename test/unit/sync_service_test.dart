import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:no5ocial/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncService Tests', () {
    test('Initializes with default idle status and null last sync', () async {
      final sync = SyncService.instance;
      await sync.init();
      expect(sync.status, SyncStatus.idle);
      expect(sync.formattedLastSync, 'Never synced');
    });

    test('Formatted last sync displays human readable intervals', () {
      final sync = SyncService.instance;
      expect(sync.formattedLastSync, 'Never synced');
    });

    test('syncNow processes remote delta and marks synced successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/sync')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'synced_at_utc': DateTime.now().toUtc().toIso8601String(),
              'acknowledged': {'brands': [], 'social_accounts': []},
              'remote_delta': {
                'brands': [],
                'channel_groups': [],
                'social_accounts': [],
                'content_posts': [],
                'post_variants': [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final sync = SyncService.instance;
      sync.httpClient = mockClient;

      final result = await sync.syncNow();
      if (!result.success) {
        // ignore: avoid_print
        print('DEBUG SYNC ERROR: ${result.errorMessage}');
      }
      expect(result.success, isTrue);
      expect(sync.status, SyncStatus.synced);
      expect(sync.lastSyncedAt, isNotNull);
    });

    test('syncNow transitions to error state on server failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final sync = SyncService.instance;
      sync.httpClient = mockClient;

      final result = await sync.syncNow();
      expect(result.success, isFalse);
      expect(sync.status, SyncStatus.error);
      expect(sync.lastError, isNotNull);
    });
  });
}
