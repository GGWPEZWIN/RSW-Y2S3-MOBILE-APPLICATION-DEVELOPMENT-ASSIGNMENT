import 'package:assignment/services/app_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'email_signup.dart';
import 'email_login.dart';
import 'employer_login.dart';
import 'main.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';
import 'Jobseeker/MainScreen/jobseeker_home.dart';
import 'l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isLoading = false;

  // --- LANGUAGE SELECTION DIALOG ---
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Select Language / 选择语言"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langTile("🇺🇸", "English", const Locale('en'), context),
            _langTile("🇲🇾", "Bahasa Melayu", const Locale('ms'), context),
            _langTile("🇨🇳", "中文", const Locale('zh'), context),
          ],
        ),
      ),
    );
  }

  Widget _langTile(String flag, String label, Locale locale, BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      onTap: () {
        final stateManager = Provider.of<AppStateManager>(context, listen: false);

        // Update the language using the code (e.g., 'en', 'ms', 'zh')
        stateManager.setLanguage(locale.languageCode);

        Navigator.pop(context);
      },
    );
  }

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
    // 1. Get the localizations (safety check for null)
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // --- TOP ROW WITH LOGO AND LANGUAGE SELECTOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/icons/JobBuddyLogo.png', height: 50, width: 50),
                      const SizedBox(width: 8),
                      const Text('JobBuddy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  // LANGUAGE BUTTON
                  IconButton(
                    icon: const Icon(Icons.language, color: Color(0xFF7B4DFF)),
                    onPressed: () => _showLanguageDialog(context),
                  ),
                ],
              ),

              const Spacer(flex: 2),
              Image.asset('assets/icons/LoginPic.png', height: 220),
              const SizedBox(height: 30),

              // --- TRANSLATED TEXT ---
              Center(
                child: Text(l10n.findTheRightJob, // Example key from your .arb
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF425AE2))),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(l10n.buildYourCareer, // Using existing keys for testing
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),

              const Spacer(flex: 2),

              // Google button
              _isLoading
                  ? const Center(child: SpinKitThreeBounce(color: Color(0xFF7B4DFF), size: 24))
                  : OutlinedButton(
                onPressed: _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF7B4DFF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 24, height: 24, child: Image.asset('assets/icons/google.webp')),
                    const SizedBox(width: 12),
                    Text(l10n.continueWithGoogle, // Translates "Continue with Google" if you add the key
                        style: const TextStyle(color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Email button
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailLoginPage())),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF7B4DFF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 25, height: 25, child: Image.asset('assets/icons/email.png')),
                    const SizedBox(width: 12),
                    Text(l10n.continueWithEmail, style: TextStyle(color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${l10n.dontHaveAnAccount} ", style: const TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailSignUpScreen())),
                    child: Text(l10n.registerLink, style: const TextStyle(color: Color(0xFF1A37CC), fontWeight: FontWeight.bold)),
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
                    Text(l10n.recruitmentVisit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _navigateToEmployer,
                      child: Text(l10n.hereLink, style: const TextStyle(fontSize: 14, color: Color(0xFF1A37CC), decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
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