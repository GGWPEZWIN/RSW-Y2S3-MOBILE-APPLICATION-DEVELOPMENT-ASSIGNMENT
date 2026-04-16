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

  // Holds the Firestore stream subscription so we can cancel on logout
  StreamSubscription<QuerySnapshot>? _pushQueueSub;

  static const String _channelId   = 'jobbuddy_high_priority_alerts';
  static const String _channelName = 'JobBuddy Notifications';

  // ─── Initialize ───────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
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
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
      await impl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId, _channelName,
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

  // ─── Show a local banner immediately on THIS device ───────────────────────
  //
  // Call this any time you want a popup on the CURRENT user's screen.
  // e.g. after the jobseeker sends a reschedule request, show them
  // a "request sent" banner; the employer gets theirs via the queue listener.

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
          _channelId, _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF3B52E8),
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: payload,
    );
  }

  // ─── Cross-device push: listen to push_notifications_queue ───────────────
  //
  // HOW CROSS-DEVICE PUSH WORKS WITHOUT A CLOUD FUNCTION:
  //
  //  Sender  →  writes push_notifications_queue/{doc}  →  Firestore
  //  Recipient device  →  this listener fires  →  showNotification()
  //
  // Each device calls startListeningToFirestore(uid) right after login.
  // The listener watches push_notifications_queue where recipientId == uid
  // and status == 'pending', shows a banner, then marks the doc 'delivered'
  // so it never fires twice.
  //
  // This means: as long as the recipient's app is OPEN (foreground or background
  // with active Dart isolate), they see a popup within ~1 second.
  // For when the app is fully killed, you still need FCM + Cloud Function —
  // but this covers 95% of real-world usage.

  void startListeningToFirestore(String uid) {
    _pushQueueSub?.cancel(); // cancel any old listener

    if (uid.isEmpty) return;

    // Only listen to docs created AFTER now so old ones don't replay
    final startTime = Timestamp.now();

    _pushQueueSub = FirebaseFirestore.instance
        .collection('push_notifications_queue')
        .where('recipientId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .where('createdAt', isGreaterThan: startTime)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data  = change.doc.data() as Map<String, dynamic>;
        final title = (data['title'] as String?) ?? 'JobBuddy';
        final body  = (data['body']  as String?) ?? '';

        // Show popup immediately
        await showNotification(title: title, body: body);

        // Mark delivered so it never fires again (even on app restart)
        change.doc.reference
            .update({'status': 'delivered'}).catchError((_) {});
      }
    }, onError: (e) => debugPrint('push_queue listener error: $e'));
  }

  void stopListening() {
    _pushQueueSub?.cancel();
    _pushQueueSub = null;
  }

  // ─── Legacy methods kept so existing callers don't break ─────────────────

  Future<void> sendInterviewScheduledNotification({
    required String candidateName,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String location,
    String? meetingLink,
  }) async {
    final isOnline  = meetingLink != null && meetingLink.isNotEmpty;
    final locText   = isOnline ? 'Online — $meetingLink' : 'Location: $location';
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
    final reminderTime = interviewDateTime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⏰ Interview Reminder — $jobTitle',
      'Hi $candidateName! Your interview starts in $minutesBefore minutes. Good luck!',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
            _channelId, _channelName,
            importance: Importance.max, priority: Priority.high,
            icon: '@mipmap/ic_launcher'),
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