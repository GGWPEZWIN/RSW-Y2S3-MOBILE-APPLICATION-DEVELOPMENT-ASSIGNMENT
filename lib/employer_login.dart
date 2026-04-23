import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Employer/MainScreen/employer_dashboard.dart';
import 'employer_signup.dart';
import 'l10n/app_localizations.dart';
import 'services/fcm_service.dart';          // ✅ Add
import 'services/notification_service.dart'; // ✅ Add

class EmployerLoginScreen extends StatefulWidget {
  const EmployerLoginScreen({super.key});

  @override
  State<EmployerLoginScreen> createState() => _EmployerLoginScreenState();
}

class _EmployerLoginScreenState extends State<EmployerLoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  static const Color _navy    = Color(0xFF0D1B3E);
  static const Color _accent  = Color(0xFF3B52E8);
  static const Color _bg      = Color(0xFFF4F6FB);
  static const Color _border  = Color(0xFFDDE3EF);
  static const Color _text    = Color(0xFF0D1B3E);
  static const Color _subtext = Color(0xFF6B7A99);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('Login failed');

      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _snack('Please verify your email first. Check your inbox.', error: true);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _snack('No employer account found. Please register first.', error: true);
        return;
      }

      final role = userDoc.data()?['role'] as String? ?? '';
      if (role != 'employer') {
        await FirebaseAuth.instance.signOut();
        _snack('This is a jobseeker account. Please use the jobseeker login.', error: true);
        return;
      }

      // ✅ Save FCM token + start cross-device push listener
      await FCMService().saveToken(user.uid);
      NotificationService().startListeningToFirestore(user.uid);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmployerDashboard()),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e.code == 'user-not-found')     msg = 'No account found with this email.';
      if (e.code == 'wrong-password')     msg = 'Incorrect password.';
      if (e.code == 'invalid-credential') msg = 'Invalid email or password.';
      if (e.code == 'too-many-requests')  msg = 'Too many attempts. Try again later.';
      _snack(msg, error: true);
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final ctrl   = TextEditingController(text: _emailCtrl.text);
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 20),
              const Text('Reset Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text)),
              const SizedBox(height: 6),
              const Text('Enter your employer email and we\'ll send a reset link.',
                  style: TextStyle(color: _subtext, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDec(hint: 'company@email.com', icon: Icons.email_outlined),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: sending ? null : () async {
                    final email = ctrl.text.trim();
                    if (email.isEmpty) return;
                    setSheet(() => sending = true);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack('Reset link sent! Check your inbox 📧', error: false);
                    } on FirebaseAuthException catch (e) {
                      _snack(
                        e.code == 'user-not-found'
                            ? 'No account found with this email.'
                            : 'Failed to send reset email.',
                        error: true,
                      );
                    } finally {
                      if (ctx.mounted) setSheet(() => sending = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: sending
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Reset Link',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB8D0), fontSize: 14),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initialize l10n
    final l10n = AppLocalizations.of(context);

    // 2. Safety check
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Dark navy header ──────────────────────────────────────────────
          Container(
            color: _navy,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: _accent, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(children: [
                      const TextSpan(text: 'JobBuddy ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      TextSpan(text: l10n.employerLabel, // Translated 'Employer'
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF9FADC8))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),
                Text(l10n.welcomeBack, // Translated 'Welcome back'
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(l10n.employerLoginSubtitle, // Translated subtitle
                    style: const TextStyle(fontSize: 14, color: Color(0xFF8A99B8), height: 1.4)),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(l10n.workEmailLabel), // Translated 'Work Email'
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDec(hint: 'company@email.com', icon: Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                          return l10n.invalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _fieldLabel(l10n.passwordLabel),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: _inputDec(
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _subtext, size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.passwordRequired : null,
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(l10n.forgotPassword,
                            style: const TextStyle(color: _accent, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          disabledBackgroundColor: _navy.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text(l10n.loginBtn,
                            style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(l10n.orLabel, style: TextStyle(color: _subtext, fontSize: 13)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity, height: 54,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const EmployerSignUpScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _navy, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.createEmployerAccountBtn,
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.bold, color: _navy)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFCBF4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: _accent),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            l10n.employerAccountNotice,
                            style: const TextStyle(fontSize: 12, color: _accent, height: 1.5),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _text));
}