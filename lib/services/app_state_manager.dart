import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

class AppStateManager extends ChangeNotifier {
  static AppStateManager? instance;

  AppStateManager() {
    instance = this;
  }

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();

    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
      // You could also resave the token to Firestore here
    } else {
      // This tells the Firebase servers: "Don't send anything to this phone"
      await FirebaseMessaging.instance.unsubscribeFromTopic('all_users');

      // Optional: Clear existing notifications from the tray immediately
      await NotificationService().cancelAllNotifications();
    }
  }

  // Default values
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en'); // Default to English

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  // Function to change Theme
  void setTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Refreshes the whole app
  }

  // Function to change Language
  void setLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners(); // Refreshes the whole app
  }


}