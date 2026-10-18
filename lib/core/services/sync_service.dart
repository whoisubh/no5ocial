import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:no5ocial/data/database/app_database.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.errorMessage,
    required this.timestamp,
  });
}

/// Unified Local-First Synchronization Engine.
///
/// Principles:
/// 1. Local SQLite remains the instant, offline authority.
/// 2. Pushes local dirty changes (`updated_at_utc > synced_at_utc`) to `/api/sync`.
/// 3. Pulls remote updates and resolves conflicts via Last-Write-Wins (LWW).
/// 4. Provides reactive sync status for top-level UI indicators.
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  http.Client _httpClient = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _httpClient = client;

  static const String _prefLastSyncTimeKey = 'sync_service_last_sync_utc';
  static const String defaultSyncEndpoint = '/api/sync';

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _autoSyncTimer;

  /// Initializes the sync engine and loads last sync state
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTime = prefs.getString(_prefLastSyncTimeKey);
    if (rawTime != null) {
      _lastSyncedAt = DateTime.tryParse(rawTime);
    }
    // Start periodic background auto-sync check every 5 minutes
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncNow();
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  /// Triggers an immediate delta synchronization
  Future<SyncResult> syncNow({String? userToken}) async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync is already in progress.',
        timestamp: DateTime.now(),
      );
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final db = AppDatabase.instance;

      // 1. Gather all dirty local outbox records
      final dirtyBrands = await db.getUnsyncedRecords('brands');
      final dirtyGroups = await db.getUnsyncedRecords('channel_groups');
      final dirtyAccounts = await db.getUnsyncedRecords('social_accounts');
      final dirtyPosts = await db.getUnsyncedRecords('content_posts');
      final dirtyVariants = await db.getUnsyncedRecords('post_variants');

      final totalPushed = dirtyBrands.length +
          dirtyGroups.length +
          dirtyAccounts.length +
          dirtyPosts.length +
          dirtyVariants.length;

      final payload = {
        'timestamp_utc': nowUtc,
        'since_utc': _lastSyncedAt?.toIso8601String(),
        'delta': {
          'brands': dirtyBrands,
          'channel_groups': dirtyGroups,
          'social_accounts': dirtyAccounts,
          'content_posts': dirtyPosts,
          'post_variants': dirtyVariants,
        },
      };

      final headers = {
        'Content-Type': 'application/json',
        if (userToken != null && userToken.isNotEmpty)
          'Authorization': 'Bearer $userToken',
      };

      // 2. Call backend /api/sync
      final uri = defaultSyncEndpoint.startsWith('http')
          ? Uri.parse(defaultSyncEndpoint)
          : Uri.parse('http://localhost$defaultSyncEndpoint');
      final response = await _httpClient
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body) as Map<String, dynamic>;

        // A. Mark local dirty records as successfully synced
        if (dirtyBrands.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'brands',
            recordIds: dirtyBrands.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }
        if (dirtyGroups.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'channel_groups',
            recordIds: dirtyGroups.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }
        if (dirtyAccounts.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'social_accounts',
            recordIds: dirtyAccounts.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }
        if (dirtyPosts.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'content_posts',
            recordIds: dirtyPosts.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }
        if (dirtyVariants.isNotEmpty) {
          await db.markRecordsAsSynced(
            tableName: 'post_variants',
            recordIds: dirtyVariants.map((r) => r['id'] as String).toList(),
            syncedAtUtc: nowUtc,
          );
        }

        // B. Ingest remote delta (changes from other devices)
        int totalPulled = 0;
        final remoteDelta = resData['remote_delta'] as Map<String, dynamic>?;
        if (remoteDelta != null) {
          final rBrands = (remoteDelta['brands'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final rGroups = (remoteDelta['channel_groups'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final rAccounts = (remoteDelta['social_accounts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final rPosts = (remoteDelta['content_posts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final rVariants = (remoteDelta['post_variants'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

          totalPulled = rBrands.length + rGroups.length + rAccounts.length + rPosts.length + rVariants.length;

          await db.upsertRemoteDelta(tableName: 'brands', records: rBrands, syncedAtUtc: nowUtc);
          await db.upsertRemoteDelta(tableName: 'channel_groups', records: rGroups, syncedAtUtc: nowUtc);
          await db.upsertRemoteDelta(tableName: 'social_accounts', records: rAccounts, syncedAtUtc: nowUtc);
          await db.upsertRemoteDelta(tableName: 'content_posts', records: rPosts, syncedAtUtc: nowUtc);
          await db.upsertRemoteDelta(tableName: 'post_variants', records: rVariants, syncedAtUtc: nowUtc);
        }

        _lastSyncedAt = DateTime.parse(nowUtc);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLastSyncTimeKey, nowUtc);

        _status = SyncStatus.synced;
        notifyListeners();

        return SyncResult(
          success: true,
          pushedCount: totalPushed,
          pulledCount: totalPulled,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      _status = SyncStatus.offline;
      _lastError = 'Sync request timed out (working in offline mode).';
      notifyListeners();
      return SyncResult(
        success: false,
        errorMessage: _lastError,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      notifyListeners();
      return SyncResult(
        success: false,
        errorMessage: _lastError,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Human-readable time since last sync
  String get formattedLastSync {
    if (_lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().toUtc().difference(_lastSyncedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
