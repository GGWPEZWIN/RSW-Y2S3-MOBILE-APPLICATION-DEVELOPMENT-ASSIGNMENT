import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'app_state_manager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _pushQueueSub;

  static const String _channelId   = 'jobbuddy_high_priority_alerts';
  static const String _channelName = 'JobBuddy Notifications';

  // ─── Initialize (call once in main.dart) ─────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        debugPrint('Notification tapped: ${r.payload}');
      },
    );

    if (Platform.isAndroid) {
      final impl = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Job application and interview updates',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    _isInitialized = true;
  }

  // ─── Show a local popup banner on THIS device immediately ────────────────

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF3B52E8),
          ticker: 'ticker',
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ─── Cross‑device push listener ─────────────────────────────────────────

  void startListeningToFirestore(String userId) {
    _db.collection('push_notifications_queue')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {

      // --- THE BOUNCER CHECK ---
      final isEnabled = AppStateManager.instance?.notificationsEnabled ?? true;
      if (!isEnabled) {
        debugPrint("Firestore Notification ignored: Toggle is OFF");
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          showNotification(
            title: data?['title'] ?? '',
            body: data?['body'] ?? '',
          );
        }
      }
    });
  }
  void stopListening() {
    _pushQueueSub?.cancel();
    _pushQueueSub = null;
  }

  // ─── Legacy / helper methods ────────────────────────────────────────────

  Future<void> sendInterviewScheduledNotification({
    required String candidateName,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String location,
    String? meetingLink,
  }) async {
    final locText = (meetingLink != null && meetingLink.isNotEmpty)
        ? 'Online — $meetingLink'
        : 'Location: $location';
    await showNotification(
      title: '📅 Interview Scheduled — $jobTitle',
      body: 'Hi $candidateName! Your interview for $jobTitle is on $interviewDate at $interviewTime. $locText',
      payload: 'interview_scheduled',
    );
  }

  Future<void> scheduleInterviewReminder({
    required String candidateName,
    required String jobTitle,
    required DateTime interviewDateTime,
    int minutesBefore = 60,
  }) async {
    await initialize();
    final reminderTime = interviewDateTime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    // ✅ FIX: add the required parameter uiLocalNotificationDateInterpretation
    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⏰ Interview Reminder — $jobTitle',
      'Hi $candidateName! Your interview starts in $minutesBefore minutes. Good luck!',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'interview_reminder',
    );
  }

  Future<void> cancelAllNotifications() => _notifications.cancelAll();
  Future<void> cancelNotification(int id) => _notifications.cancel(id);
}