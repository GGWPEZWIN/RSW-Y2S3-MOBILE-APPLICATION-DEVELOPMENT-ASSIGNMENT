import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

/// Background handler — must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db        = FirebaseFirestore.instance;

  // ─── Call once in main.dart ───────────────────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
        alert: true, badge: true, sound: true);

    await NotificationService().initialize();

    // Show banner for true FCM messages while app is open
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      NotificationService().showNotification(
        title:   n.title ?? '',
        body:    n.body  ?? '',
        payload: message.data.toString(),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  // ─── Save FCM token — call after login for BOTH roles ────────────────────

  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(userId).set(
        {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      debugPrint('FCM token saved for $userId');
      _messaging.onTokenRefresh.listen((t) {
        _db.collection('users').doc(userId)
            .update({'fcmToken': t, 'updatedAt': FieldValue.serverTimestamp()});
      });
    } catch (e) {
      debugPrint('saveToken error: $e');
    }
  }

  // Alias so old callers compile
  Future<void> saveCandidateToken(String userId) => saveToken(userId);

  // ─── Queue a push notification for another user ───────────────────────────
  //
  // Writes a 'pending' doc to push_notifications_queue.
  // NotificationService.startListeningToFirestore() on the RECIPIENT's device
  // picks this up instantly and shows a local banner.

  Future<void> sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (recipientId.isEmpty) return;
    try {
      await _db.collection('push_notifications_queue').add({
        'recipientId': recipientId,
        'title':       title,
        'body':        body,
        'data':        data ?? {},
        'status':      'pending',
        'createdAt':   FieldValue.serverTimestamp(),
      });
      debugPrint('Push queued → $recipientId: $title');
    } catch (e) {
      debugPrint('sendPushNotification error: $e');
    }
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
        return 'Hi $name! The employer wants to interview you for $jobTitle. Check the app for details.';
    }
  }
}