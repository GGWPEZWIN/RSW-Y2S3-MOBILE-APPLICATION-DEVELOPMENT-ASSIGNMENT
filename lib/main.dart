import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ← add this
import 'google_login.dart';
import 'services/google_sign_in_service.dart'; // ← add this (adjust path if needed)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
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
      home: const GoogleLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}