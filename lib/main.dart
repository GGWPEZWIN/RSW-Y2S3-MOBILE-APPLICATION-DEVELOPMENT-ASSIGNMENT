import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login.dart';
import 'services/google_sign_in_service.dart'; // ✅ added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file FIRST
  await dotenv.load();

  await Firebase.initializeApp();

  await GoogleSignInService.initialize(); // ✅ added

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