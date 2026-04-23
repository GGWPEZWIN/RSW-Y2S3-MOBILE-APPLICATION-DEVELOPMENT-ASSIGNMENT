import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_login.dart';
import 'l10n/app_localizations.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  static const Color _primaryBlue = Color(0xFF3B52E8);
  static const Color _bg          = Color(0xFFF5F6FA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      // 2. Update display name
      await user.updateDisplayName(_nameController.text.trim());

      // 3. Write to Firestore with role:'jobseeker'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid':       user.uid,
        'name':      _nameController.text.trim(),
        'email':     _emailController.text.trim(),
        'role':      'jobseeker',
        'photoUrl':  '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Send email verification
      await user.sendEmailVerification();

      // 5. Sign out until verified
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: const [
            Icon(Icons.mark_email_read_outlined,
                color: Color(0xFF22C55E), size: 28),
            SizedBox(width: 10),
            Text('Verify Your Email',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A verification email has been sent to:',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                _emailController.text.trim(),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B3E),
                    fontSize: 14),
              ),
              const SizedBox(height: 14),
              const Text(
                'Please verify your email before logging in.',
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: Color(0xFF475569)),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmailLoginPage()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Go to Login',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Try again.';
      if (e.code == 'email-already-in-use') message = 'This email is already registered.';
      if (e.code == 'weak-password')        message = 'Password is too weak.';
      if (e.code == 'invalid-email')        message = 'Invalid email address.';
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initialize the localization object
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.createAccount, // Changed
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.joinJobBuddy, // Changed
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(l10n.createJobseekerAccount, // Changed
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDeco(
                      label: l10n.fullName, // Changed
                      hint: 'e.g. Ahmad Faris',
                      icon: Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.nameRequired // Changed
                      : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco(
                      label: l10n.email, // Changed
                      hint: 'you@example.com',
                      icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return l10n.emailRequired; // Changed
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return l10n.validEmail; // Changed
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDeco(
                    label: l10n.password, // Changed
                    hint: l10n.atLeast8Chars, // Changed
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passRequired; // Changed
                    if (v.length < 8)
                      return l10n.passMinLength; // Changed
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(l10n.use8OrMore, // Changed
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: _inputDeco(
                    label: l10n.confirmPassword, // Changed
                    hint: l10n.reEnterPassword, // Changed
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return l10n.confirmPassRequired; // Changed
                    if (v != _passwordController.text)
                      return l10n.passNotMatch; // Changed
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(l10n.createAccount, // Changed
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.alreadyHaveAccount), // Changed
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmailLoginPage()),
                      ),
                      child: Text(l10n.login, // Changed
                          style: const TextStyle(
                              color: _primaryBlue,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primaryBlue),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border:
      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _primaryBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}