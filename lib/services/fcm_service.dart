import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ─── Call once in main.dart after Firebase.initializeApp() ───────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup flutter_local_notifications (foreground banners on Android)
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'application_status_channel',
        'Application Status',
        description: 'Job application status updates from employers',
        importance: Importance.max,
      ),
    );

    // Show banner when app is OPEN (foreground)
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  // ─── SAVE TOKEN after login (Works for both User and Employer) ──────────

  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _db.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('FCM token saved for $userId');

      _messaging.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('saveToken error: $e');
    }
  }

  // ─── Trigger Cloud Function via doc write (Payload Pattern) ─────────────

  Future<void> sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This write triggers a Cloud Function (if you have one)
    // or you can handle it via a collection listener.
    // For a pure client-side implementation without server-side keys,
    // we use Firestore as a 'trigger'.
    await _db.collection('push_notifications_queue').add({
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Show banner while app is open ───────────────────────────────────────

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _localNotifications.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'application_status_channel',
          'Application Status',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF425AE2),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

// ─── ApplicationStatus enum ───────────────────────────────────────────────────

enum ApplicationStatus { accepted, rejected, shortlisted, interview }

extension ApplicationStatusX on ApplicationStatus {
  String get firestoreValue {
    switch (this) {
      case ApplicationStatus.accepted:    return 'accepted';
      case ApplicationStatus.rejected:    return 'rejected';
      case ApplicationStatus.shortlisted: return 'shortlisted';
      case ApplicationStatus.interview:   return 'interview';
    }
  }

  String notificationTitle(String jobTitle) {
    switch (this) {
      case ApplicationStatus.accepted:
        return '🎉 Application Accepted — $jobTitle';
      case ApplicationStatus.rejected:
        return '📋 Application Update — $jobTitle';
      case ApplicationStatus.shortlisted:
        return '⭐ You\'ve Been Shortlisted — $jobTitle';
      case ApplicationStatus.interview:
        return '📅 Interview Invitation — $jobTitle';
    }
  }

  String notificationBody(String name, String jobTitle, {String? reason}) {
    switch (this) {
      case ApplicationStatus.accepted:
        return 'Congratulations $name! Your application for $jobTitle has been accepted.';
      case ApplicationStatus.rejected:
        return (reason != null && reason.isNotEmpty)
            ? 'Hi $name, your application for $jobTitle was not successful. Reason: $reason'
            : 'Hi $name, your application for $jobTitle was not successful this time.';
      case ApplicationStatus.shortlisted:
        return 'Great news $name! You\'ve been shortlisted for $jobTitle.';
      case ApplicationStatus.interview:
        return 'Hi $name, the employer wants to interview you for $jobTitle. Check details in the app.';
    }
  }
}