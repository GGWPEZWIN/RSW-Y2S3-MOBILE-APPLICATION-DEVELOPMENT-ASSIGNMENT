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
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create default channel for Android
    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'default_channel',
        'General Notifications',
        description: 'Standard app notifications',
        importance: Importance.max,
      ),
    );

    _isInitialized = true;
  }

  // ─── Notification Details ─────────────────────────────────────────

  NotificationDetails get _defaultDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'General Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF425AE2),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Show an immediate notification banner on the current device.
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      _generateId(),
      title,
      body,
      _defaultDetails,
      payload: payload,
    );
  }

  /// Show an immediate notification when an interview is scheduled.
  Future<void> sendInterviewScheduledNotification({
    required String candidateName,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String location,
    String? meetingLink,
  }) async {
    final isOnline = meetingLink != null && meetingLink.isNotEmpty;
    final locationText = isOnline ? 'Online — $meetingLink' : 'Location: $location';

    await showNotification(
      title: '📅 Interview Scheduled — $jobTitle',
      body: 'Hi $candidateName! Your interview for $jobTitle is on $interviewDate at $interviewTime. $locationText',
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
    if (!_isInitialized) await initialize();

    final reminderTime = interviewDateTime.subtract(Duration(minutes: minutesBefore));

    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      _generateId(),
      '⏰ Interview Reminder — $jobTitle',
      'Hi $candidateName! Your interview starts in $minutesBefore minutes. Good luck!',
      tz.TZDateTime.from(reminderTime, tz.local),
      _defaultDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'interview_reminder',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch.remainder(100000);
}
