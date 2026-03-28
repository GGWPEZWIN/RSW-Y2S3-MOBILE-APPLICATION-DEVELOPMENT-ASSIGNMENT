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

  // ─── CANDIDATE: save FCM token after login ────────────────────────────────

  Future<void> saveCandidateToken(String userId) async {
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
      debugPrint('saveCandidateToken error: $e');
    }
  }

  // ─── EMPLOYER: write status update → Cloud Function sends the push ────────

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String candidateUserId,
    required String candidateName,
    required String jobTitle,
    required ApplicationStatus status,
    String? rejectionReason,
  }) async {
    await _db.collection('applications').doc(applicationId).update({
      'status': status.firestoreValue,
      'candidateUserId': candidateUserId,
      'candidateName': candidateName,
      'jobTitle': jobTitle,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'notificationPayload': {
        'title': status.notificationTitle(jobTitle),
        'body': status.notificationBody(
          candidateName,
          jobTitle,
          reason: rejectionReason,
        ),
        'status': status.firestoreValue,
      },
    });

    debugPrint('Application status → ${status.firestoreValue}');
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

enum ApplicationStatus { accepted, rejected, shortlisted }

extension ApplicationStatusX on ApplicationStatus {
  String get firestoreValue {
    switch (this) {
      case ApplicationStatus.accepted:    return 'accepted';
      case ApplicationStatus.rejected:    return 'rejected';
      case ApplicationStatus.shortlisted: return 'shortlisted';
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
    }
  }

  String notificationBody(String name, String jobTitle, {String? reason}) {
    switch (this) {
      case ApplicationStatus.accepted:
        return 'Congratulations $name! Your application for $jobTitle has been accepted. We\'ll be in touch soon.';
      case ApplicationStatus.rejected:
        return (reason != null && reason.isNotEmpty)
            ? 'Hi $name, your application for $jobTitle was not successful. Reason: $reason'
            : 'Hi $name, your application for $jobTitle was not successful this time. Keep applying!';
      case ApplicationStatus.shortlisted:
        return 'Great news $name! You\'ve been shortlisted for $jobTitle. Stay tuned for next steps.';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.accepted:    return const Color(0xFF22C55E);
      case ApplicationStatus.rejected:    return const Color(0xFFEF4444);
      case ApplicationStatus.shortlisted: return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.accepted:    return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:    return Icons.cancel_rounded;
      case ApplicationStatus.shortlisted: return Icons.star_rounded;
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.accepted:    return 'Accepted';
      case ApplicationStatus.rejected:    return 'Rejected';
      case ApplicationStatus.shortlisted: return 'Shortlisted';
    }
  }
}