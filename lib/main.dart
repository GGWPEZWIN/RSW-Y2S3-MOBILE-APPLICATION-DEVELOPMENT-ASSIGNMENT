import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart'; // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    
    // Initialize FCM Service
    await FCMService().initialize();
    debugPrint('FCM Service initialized');
  } catch (e) {
    debugPrint('Error initializing Firebase/FCM: $e');
  }

  try {
    await GoogleSignIn.instance.initialize();
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}