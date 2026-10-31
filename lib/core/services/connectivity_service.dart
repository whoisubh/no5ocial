import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:no5ocial/core/services/sync_service.dart';
import 'package:no5ocial/core/services/schedule_runner_service.dart';

/// Network Connectivity Monitoring Service for No5ocial.
///
/// Features:
/// 1. Real-time network reachability tracking across Wi-Fi, Mobile Data, Ethernet, and VPN.
/// 2. Automatic trigger of background sync (`SyncService.syncNow()`) when device returns online.
/// 3. Reactive status for top-level offline banners and publishing pre-flight guards.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<ConnectivityResult> _currentResults = [ConnectivityResult.wifi];
  List<ConnectivityResult> get currentResults => _currentResults;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes connectivity listener and queries current status
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final initialResults = await _connectivity.checkConnectivity();
      _updateResults(initialResults, notify: false);

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        final wasOffline = !_isOnline;
        _updateResults(results, notify: true);

        // Auto-reconnect sync: when transitioning from offline to online, trigger sync
        if (wasOffline && _isOnline) {
          debugPrint('ConnectivityService: Device back online. Triggering workspace sync & schedule runner...');
          SyncService.instance.syncNow();
          unawaited(ScheduleRunnerService.instance.checkAndExecuteDuePosts());
        }
      });

      _isInitialized = true;
      debugPrint('ConnectivityService: Initialized. isOnline=$_isOnline');
    } catch (e) {
      debugPrint('ConnectivityService: Init warning: $e');
      _isOnline = true;
      _isInitialized = true;
    }
  }

  void _updateResults(List<ConnectivityResult> results, {bool notify = true}) {
    _currentResults = results;
    final online = results.any((r) => r != ConnectivityResult.none);

    if (_isOnline != online) {
      _isOnline = online;
      debugPrint('ConnectivityService: Network state changed to isOnline=$_isOnline ($results)');
      if (notify) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
