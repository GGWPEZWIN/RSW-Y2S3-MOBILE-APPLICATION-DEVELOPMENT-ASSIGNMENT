import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_login.dart';
import 'package:assignment/Jobseeker/JobApplication/ApplicationUI/job_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
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
      //home: GoogleLogin(), // Remove 'const' here
      home: JobDetailsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}