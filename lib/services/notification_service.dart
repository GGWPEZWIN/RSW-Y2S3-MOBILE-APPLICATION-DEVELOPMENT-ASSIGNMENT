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

  /// Call this once in main() or before using notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap — you can navigate here if needed
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request Android 13+ permission
    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  // ─── Notification Channel Details ─────────────────────────────────────────

  NotificationDetails get _interviewNotificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'interview_channel',       // channel id
          'Interview Notifications', // channel name
          channelDescription: 'Notifications for scheduled interviews',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF425AE2),
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Show an immediate notification when an interview is scheduled.
  /// Call this from the Employer side when they schedule an interview.
  Future<void> sendInterviewScheduledNotification({
    required String candidateName,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String location,
    String? meetingLink,
  }) async {
    await initialize();

    final isOnline = meetingLink != null && meetingLink.isNotEmpty;
    final locationText =
    isOnline ? 'Online — $meetingLink' : 'Location: $location';

    await _notifications.show(
      _generateId(),
      '📅 Interview Scheduled — $jobTitle',
      'Hi $candidateName! Your interview for $jobTitle is on $interviewDate at $interviewTime. $locationText',
      _interviewNotificationDetails,
      payload: 'interview_scheduled',
    );
  }

  /// Schedule a reminder notification X minutes before the interview.
  Future<void> scheduleInterviewReminder({
    required String candidateName,
    required String jobTitle,
    required DateTime interviewDateTime,
    int minutesBefore = 60,
  }) async {
    await initialize();

    final reminderTime = interviewDateTime.subtract(
      Duration(minutes: minutesBefore),
    );

    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Reminder time is in the past, skipping scheduled reminder.');
      return;
    }

    await _notifications.zonedSchedule(
      _generateId(),
      '⏰ Interview Reminder — $jobTitle',
      'Hi $candidateName! Your interview starts in $minutesBefore minutes. Good luck!',
      tz.TZDateTime.from(reminderTime, tz.local),
      _interviewNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'interview_reminder',
    );
  }

  /// Cancel all pending notifications (e.g. if interview is cancelled).
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification by id.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  int _generateId() =>
      DateTime.now().millisecondsSinceEpoch.remainder(100000);
}