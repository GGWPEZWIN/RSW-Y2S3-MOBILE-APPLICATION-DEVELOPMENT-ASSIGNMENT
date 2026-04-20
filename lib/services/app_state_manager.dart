import 'package:flutter/material.dart';

class AppStateManager with ChangeNotifier {
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