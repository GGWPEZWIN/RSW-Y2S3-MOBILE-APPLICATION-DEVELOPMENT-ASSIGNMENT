import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_signup.dart';
import 'email_login.dart';
import 'employer_login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';
import 'Jobseeker/MainScreen/jobseeker_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _googleSignInService.signInWithGoogle();

      if (user == null) {
        _showSnack('Google sign-in cancelled', isError: false);
        return;
      }

      // ✅ 1. Save FCM token immediately
      await FCMService().saveToken(user.uid);

      // ✅ 2. Check if user doc exists in Firestore already
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // ✅ First time Google sign-in — write to Firestore with role:'jobseeker'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid':       user.uid,
          'name':      user.displayName ?? '',
          'email':     user.email ?? '',
          'role':      'jobseeker',   // ✅ Google users are always jobseekers
          'photoUrl':  user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      _showSnack('Welcome ${user.displayName ?? 'User'}! 👋', isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
            (route) => false,
      );
    } catch (e) {
      _showSnack('Error signing in: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _navigateToEmployer() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EmployerLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/JobBuddyLogo.png',
                        height: 50, width: 50),
                    const SizedBox(width: 8),
                    const Text('JobBuddy',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Image.asset('assets/icons/LoginPic.png', height: 220),
              const SizedBox(height: 30),
              const Center(
                child: Text('Find the right job',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF425AE2))),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Build your career',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const Spacer(flex: 2),

              // Google button
              _isLoading
                  ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFF7B4DFF), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: const Center(
                  child: SpinKitThreeBounce(
                      color: Color(0xFF7B4DFF), size: 24),
                ),
              )
                  : OutlinedButton(
                onPressed: _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(
                      color: Color(0xFF7B4DFF), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Image.asset('assets/icons/google.webp'),
                    ),
                    const SizedBox(width: 12),
                    const Text('Continue with Google',
                        style: TextStyle(
                            color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Email button
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailLoginPage()),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(
                      color: Color(0xFF7B4DFF), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 25, height: 25,
                      child: Image.asset('assets/icons/email.png'),
                    ),
                    const SizedBox(width: 12),
                    const Text('Continue with Email',
                        style: TextStyle(color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmailSignUpScreen()),
                    ),
                    child: const Text('Register',
                        style: TextStyle(
                            color: Color(0xFF1A37CC),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // Employer link
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Recruitment? Visit ',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _navigateToEmployer,
                      child: const Text('here',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A37CC),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}