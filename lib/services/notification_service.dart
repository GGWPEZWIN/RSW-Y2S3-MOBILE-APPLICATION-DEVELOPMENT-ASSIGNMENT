import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

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
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
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

  // ─── Cross-device push: listen to push_notifications_queue ───────────────
  //
  // HOW IT WORKS (no Cloud Function / no server needed):
  //
  //   Sender   → FCMService().sendPushNotification(recipientId, title, body)
  //            → writes {recipientId, title, body, status:'pending'} to Firestore
  //
  //   Recipient device → this listener (started at login) sees the new doc
  //            → calls showNotification() → popup appears
  //            → marks doc status:'delivered' so it never fires again
  //
  // KEY DESIGN:
  //   • Query is ONLY on recipientId + status == 'pending'
  //     No createdAt filter — avoids needing a composite index and avoids the
  //     server-timestamp timing bug where client startTime > server write time.
  //   • Uses DocumentChangeType.added so already-delivered docs are ignored.
  //   • Marks 'delivered' before returning so even if the listener fires twice
  //     (e.g. app restart), the doc is already gone from the query.

  void startListeningToFirestore(String uid) {
    _pushQueueSub?.cancel();
    if (uid.isEmpty) return;

    _pushQueueSub = FirebaseFirestore.instance
        .collection('push_notifications_queue')
        .where('recipientId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snap) async {
        for (final change in snap.docChanges) {
          // Only react to new docs, not existing ones loaded at startup
          if (change.type != DocumentChangeType.added) continue;

          final data  = change.doc.data() as Map<String, dynamic>? ?? {};
          final title = (data['title'] as String?) ?? 'JobBuddy';
          final body  = (data['body']  as String?) ?? '';

          // Mark delivered FIRST to prevent double-firing on reconnect
          await change.doc.reference
              .update({'status': 'delivered'}).catchError((_) {});

          // Then show the popup
          await showNotification(title: title, body: body);
        }
      },
      onError: (e) => debugPrint('push_queue listener error: $e'),
    );
  }

  void stopListening() {
    _pushQueueSub?.cancel();
    _pushQueueSub = null;
  }

  // ─── Legacy methods kept so existing callers compile ─────────────────────

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
      title:   '📅 Interview Scheduled — $jobTitle',
      body:    'Hi $candidateName! Your interview for $jobTitle is on $interviewDate at $interviewTime. $locText',
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
    final reminderTime =
    interviewDateTime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⏰ Interview Reminder — $jobTitle',
      'Hi $candidateName! Your interview starts in $minutesBefore minutes. Good luck!',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'interview_reminder',
    );
  }

  Future<void> cancelAllNotifications() => _notifications.cancelAll();
  Future<void> cancelNotification(int id) => _notifications.cancel(id);
}