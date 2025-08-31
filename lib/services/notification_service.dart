import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:modern_auth_app/services/fcm_token_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService({required this.navigatorKey});

  Future<void> initialize() async {
    // Create notification channels for different types
    await _createNotificationChannels();

    // Initialize local notifications with tap handling
    await _initializeLocalNotifications();

    // Request permissions
    await requestPermissions();

    // Initialize FCM token service
    await FCMTokenService.initialize();

    // Get and log FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    log('FCM Token: $fcmToken', name: 'NotificationService');

    // Handle app launch from terminated state
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'App launched from notification: ${initialMessage.messageId}',
        name: 'NotificationService',
      );
      _handleMessage(initialMessage);
    }

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log(
        'Notification tapped (background): ${message.messageId}',
        name: 'NotificationService',
      );
      _handleMessage(message);
    });

    // Handle foreground messages - show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(
        'Foreground message received: ${message.messageId}',
        name: 'NotificationService',
      );
      _showLocalNotification(message);
    });
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // Default channel for general notifications
      const defaultChannel = AndroidNotificationChannel(
        'nivaran_default_channel',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Channel for comments and status updates
      const commentsChannel = AndroidNotificationChannel(
        'nivaran_comments_channel',
        'Comments & Updates',
        description: 'New comments and status updates on your issues',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Channel for urgent notifications
      const urgentChannel = AndroidNotificationChannel(
        'nivaran_urgent_channel',
        'Urgent Notifications',
        description: 'Urgent notifications requiring immediate attention',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin.createNotificationChannel(defaultChannel);
      await androidPlugin.createNotificationChannel(commentsChannel);
      await androidPlugin.createNotificationChannel(urgentChannel);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    log(
      'Local notification tapped: ${response.payload}',
      name: 'NotificationService',
    );

    if (response.payload != null) {
      final parts = response.payload!.split('|');
      final navigateTo = parts.isNotEmpty ? parts[0] : '/notifications';
      final issueId = parts.length > 1 ? parts[1] : null;

      if (navigateTo == '/issue_details' &&
          issueId != null &&
          issueId.isNotEmpty) {
        _navigateToIssueFromNotification(issueId);
      } else if (navigateTo == '/notifications') {
        _navigateToNotificationsTab();
      } else {
        navigatorKey.currentState?.pushNamed(navigateTo);
      }
    } else {
      _navigateToNotificationsTab();
    }
  }

  void _handleMessage(RemoteMessage message) {
    log(
      'Message handled (tapped): ${message.messageId}',
      name: 'NotificationService',
    );
    log('Message data: ${message.data}', name: 'NotificationService');

    final notificationType = message.data['type'] ?? 'general';
    final issueId = message.data['issueId'];
    final navigateTo = message.data['navigateTo'] ?? '/notifications';

    // Navigate based on notification type and data
    if (navigateTo == '/issue_details' &&
        issueId != null &&
        issueId.isNotEmpty) {
      _navigateToIssueFromNotification(issueId);
    } else if (notificationType == 'new_comment' ||
        notificationType == 'status_update') {
      if (issueId != null && issueId.isNotEmpty) {
        _navigateToIssueFromNotification(issueId);
      } else {
        _navigateToNotificationsTab();
      }
    } else if (navigateTo == '/notifications') {
      _navigateToNotificationsTab();
    } else {
      navigatorKey.currentState?.pushNamed(navigateTo);
    }
  }

  void _navigateToIssueFromNotification(String issueId) {
    log(
      'Navigating to issue details from notification: $issueId',
      name: 'NotificationService',
    );

    // First navigate to main app (notifications tab - index 3)
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/app',
      (route) => false,
      arguments: {'initialTabIndex': 3},
    );

    // Then navigate to issue details after a short delay to ensure main app is loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      log(
        'Navigating to issue details screen with issueId: $issueId',
        name: 'NotificationService',
      );
      navigatorKey.currentState?.pushNamed(
        '/issue_details',
        arguments: issueId,
      );
    });
  }

  void _navigateToNotificationsTab() {
    log('Navigating to notifications tab', name: 'NotificationService');

    // Navigate to main app and switch to notifications tab (index 3)
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/app',
      (route) => false,
      arguments: {'initialTabIndex': 3},
    );
  }

  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationType = message.data['type'] ?? 'general';
    final issueId = message.data['issueId'];
    final navigateTo = message.data['navigateTo'] ?? '/notifications';

    // Create payload for navigation
    final payload = '$navigateTo|${issueId ?? ''}';

    // Determine channel and styling based on notification type
    String channelId = 'nivaran_default_channel';
    String channelName = 'General Notifications';
    Importance importance = Importance.high;
    Priority priority = Priority.high;

    switch (notificationType.toLowerCase()) {
      case 'new_comment':
      case 'status_update':
        channelId = 'nivaran_comments_channel';
        channelName = 'Comments & Updates';
        break;
      case 'urgent':
      case 'new_issue_for_official':
        channelId = 'nivaran_urgent_channel';
        channelName = 'Urgent Notifications';
        importance = Importance.max;
        priority = Priority.max;
        break;
    }

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Nivaran app notifications',
          importance: importance,
          priority: priority,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
            summaryText: 'Nivaran',
          ),
          playSound: true,
          enableVibration: true,
          ticker: notification.title,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          subtitle: notificationType == 'urgent' ? 'Urgent' : null,
        ),
      ),
      payload: payload,
    );

    log(
      'Local notification shown: ${notification.title}',
      name: 'NotificationService',
    );
  }

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log(
      'FCM Permission requested. Status: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // Also request local notification permissions for iOS
    final localNotificationPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (localNotificationPlugin != null) {
      await localNotificationPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Method to get FCM token for backend integration
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      log('Error getting FCM token: $e', name: 'NotificationService');
      return null;
    }
  }

  // Method to subscribe to topics (useful for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic', name: 'NotificationService');
    } catch (e) {
      log('Error subscribing to topic $topic: $e', name: 'NotificationService');
    }
  }

  // Method to unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic', name: 'NotificationService');
    } catch (e) {
      log(
        'Error unsubscribing from topic $topic: $e',
        name: 'NotificationService',
      );
    }
  }
}
