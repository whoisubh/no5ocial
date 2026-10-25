import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:no5ocial/core/config/firebase_config.dart';
import 'package:no5ocial/core/services/firebase_sync_service.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Must be annotated with `@pragma('vm:entry-point')` so the Flutter engine can execute it
/// in an isolated background runner when notifications arrive while app is terminated/in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await FirebaseConfig.initialize();
    }
    debugPrint(
      'FcmNotificationService [Background]: Received message ID=${message.messageId}, '
      'title=${message.notification?.title ?? message.data['title']}',
    );
  } catch (e) {
    debugPrint('FcmNotificationService [Background]: Error in background handler: $e');
  }
}

/// Core Push Notification and Local Alert Service for No5ocial.
///
/// Features:
/// 1. Unified FCM push notification reception (foreground, background, terminated).
/// 2. Heads-up banners on Android/iOS via `FlutterLocalNotificationsPlugin` when app is active.
/// 3. Device push token generation, refresh listeners, and cloud syncing with Firestore.
/// 4. Local notification dispatcher for publishing outcomes, scheduled post triggers, and workspace sync events.
class FcmNotificationService extends ChangeNotifier {
  static final FcmNotificationService instance = FcmNotificationService._internal();
  FcmNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _defaultChannelId = 'no5ocial_alerts';
  static const String _defaultChannelName = 'No5ocial Publishing & Workspace Alerts';
  static const String _defaultChannelDescription =
      'Real-time updates on scheduled posts, publishing outcomes, and team collaborations.';

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    _defaultChannelId,
    _defaultChannelName,
    description: _defaultChannelDescription,
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  NotificationSettings? _permissionSettings;
  NotificationSettings? get permissionSettings => _permissionSettings;

  bool get hasPermission =>
      _permissionSettings?.authorizationStatus == AuthorizationStatus.authorized ||
      _permissionSettings?.authorizationStatus == AuthorizationStatus.provisional;

  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Initializes FCM and Local Notification channels.
  /// Fail-safe: Returns cleanly without throwing if device or platform lacks Google Play Services or permissions.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Flutter Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTapResponse,
      );

      // Create Android Notification Channel
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // 2. Initialize Firebase Messaging if Firebase is initialized
      if (FirebaseConfig.isInitialized || Firebase.apps.isNotEmpty) {
        await _setupFirebaseMessaging();
      } else {
        debugPrint('FcmNotificationService: Firebase not initialized. Local notifications enabled.');
      }

      _isInitialized = true;
      notifyListeners();
      debugPrint('FcmNotificationService: Initialized successfully.');
    } catch (e) {
      debugPrint('FcmNotificationService: Init warning: $e');
      _isInitialized = true;
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Register background handler on mobile platforms
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // Configure iOS foreground notification presentation
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request Push Notification Permissions
      _permissionSettings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Register device for FCM and retrieve initial token
      try {
        await messaging.register();
        // ignore: deprecated_member_use
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null) {
          debugPrint('FcmNotificationService: Device Token acquired: ${_fcmToken!.substring(0, 12)}...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_device_token', _fcmToken!);
        }
      } catch (tokenErr) {
        debugPrint('FcmNotificationService: Token retrieval notice: $tokenErr');
      }

      // Listen to Token Refreshes
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onRegistered.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FcmNotificationService: Device Token refreshed.');
        notifyListeners();
      });

      // Handle Foreground Messages
      _foregroundMessageSub?.cancel();
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FcmNotificationService: Foreground message received: ${message.messageId}');
        _showForegroundNotification(message);
      });

      // Handle message when user tapped notification to open app from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FcmNotificationService: Opened app from notification: ${message.messageId}');
        _handleNotificationPayload(message.data);
      });

      // Check if opened from a terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FcmNotificationService: App launched from terminated state via message: ${initialMessage.messageId}');
        _handleNotificationPayload(initialMessage.data);
      }
    } catch (e) {
      debugPrint('FcmNotificationService: _setupFirebaseMessaging warning: $e');
    }
  }

  /// Displays a rich local notification banner when a message is received in the foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'No5ocial Alert';
    final body = notification?.body ?? message.data['body'] ?? '';

    await showNotification(
      id: message.hashCode.abs(),
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  /// Displays an immediate local notification (used internally or by publishers, scheduled tasks, etc.)
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? _defaultChannelId,
        channelName ?? _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('FcmNotificationService: Failed to display notification: $e');
    }
  }

  /// Syncs the current FCM registration token with the authenticated user profile in Cloud Firestore
  Future<void> syncTokenWithUser(String userId) async {
    if (_fcmToken == null || userId.isEmpty) return;

    try {
      final firestore = FirebaseSyncService.instance.firestore;
      if (firestore != null) {
        await firestore.collection('users').doc(userId).collection('fcm_tokens').doc(_fcmToken).set({
          'token': _fcmToken,
          'platform': defaultTargetPlatform.name,
          'is_web': kIsWeb,
          'last_updated_utc': DateTime.now().toUtc().toIso8601String(),
        });
        debugPrint('FcmNotificationService: Synced device token to user $userId');
      }
    } catch (e) {
      debugPrint('FcmNotificationService: Error syncing token with Firestore: $e');
    }
  }

  /// Request permissions manually (e.g. from a Settings or Notifications toggle UI)
  Future<bool> requestPermission() async {
    try {
      if (FirebaseConfig.isInitialized || Firebase.apps.isNotEmpty) {
        _permissionSettings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        notifyListeners();
        return hasPermission;
      }
    } catch (e) {
      debugPrint('FcmNotificationService: Request permission error: $e');
    }
    return false;
  }

  /// Cancels all active notifications
  Future<void> cancelAll() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('FcmNotificationService: cancelAll error: $e');
    }
  }

  void _handleNotificationTapResponse(NotificationResponse response) {
    debugPrint('FcmNotificationService: Notification tapped with payload: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationPayload(data);
      } catch (_) {
        // Raw string payload
      }
    }
  }

  void _handleNotificationPayload(Map<String, dynamic> data) {
    debugPrint('FcmNotificationService: Processing notification payload: $data');
    final screen = data['screen'];
    final jobId = data['job_id'];
    final postId = data['post_id'];

    if (screen != null || jobId != null || postId != null) {
      // In-app deep route dispatching
      debugPrint('FcmNotificationService: Deep link navigation requested for target=$screen, job=$jobId, post=$postId');
    }
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    _tokenRefreshSub?.cancel();
    super.dispose();
  }
}
