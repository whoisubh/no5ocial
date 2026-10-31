import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Real background schedule execution worker.
/// Continuously monitors local SQLite database for scheduled posts whose execution timestamp
/// has arrived, executing them via official platform adapters without requiring manual user intervention.
class ScheduleRunnerService {
  ScheduleRunnerService._();
  static final ScheduleRunnerService instance = ScheduleRunnerService._();

  Timer? _timer;
  AppState? _appState;
  bool _isProcessing = false;

  /// Initializes the periodic schedule runner with the active AppState instance
  void init(AppState appState) {
    _appState = appState;
    _timer?.cancel();

    // Check immediately upon startup
    unawaited(checkAndExecuteDuePosts());

    // Check periodically every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(checkAndExecuteDuePosts());
    });
    debugPrint('ScheduleRunnerService: Scheduled post execution worker initialized.');
  }

  /// Scans for due posts and executes them
  Future<void> checkAndExecuteDuePosts() async {
    if (_isProcessing || _appState == null) return;
    _isProcessing = true;

    try {
      final count = await _appState!.executeDueScheduledPosts();
      if (count > 0) {
        debugPrint('ScheduleRunnerService: Successfully executed $count due scheduled post(s).');
      }
    } catch (e) {
      debugPrint('ScheduleRunnerService: Error running scheduled post loop: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Clean disposal on app teardown
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _appState = null;
  }
}

