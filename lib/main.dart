import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // Ensure path matches your folder
import 'login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';

// Global notifier for language changes
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    await FCMService().initialize();
    await GoogleSignInService.initialize();
    debugPrint('All services initialized successfully');
  } catch (e) {
    debugPrint('Initialization Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'JobBuddy',
          debugShowCheckedModeBanner: false,
          locale: locale,

          // CRITICAL FIX: Added AppLocalizations.delegate
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'),
            Locale('ms'),
            Locale('zh'),
          ],

          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.white,
          ),

          home: const LoginPage(),
        );
      },
    );
  }
}