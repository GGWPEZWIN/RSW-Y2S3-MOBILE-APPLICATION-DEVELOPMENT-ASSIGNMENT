import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Uncommented as requested
import 'login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env file (Required for your AI Resume Scanning API Keys)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('.env loaded successfully');
  } catch (e) {
    debugPrint('Error loading .env: $e');
  }

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // 3. Initialize FCM (Notifications)
    await FCMService().initialize();
    debugPrint('FCM Service initialized');
  } catch (e) {
    debugPrint('Error initializing Firebase/FCM: $e');
  }

  // 4. Initialize Google Sign-In
  try {
    await GoogleSignInService.initialize();
    debugPrint('GoogleSignIn initialized successfully');
  } catch (e) {
    debugPrint('Error initializing GoogleSignIn: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const LoginPage(),
    );
  }
}