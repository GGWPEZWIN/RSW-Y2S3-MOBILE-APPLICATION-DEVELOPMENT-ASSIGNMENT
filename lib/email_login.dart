import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Jobseeker/MainScreen/jobseeker_home.dart';
import 'Employer/MainScreen/employer_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Authentication
      final UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null && mounted) {
        // 1. Fetch role from Firestore users/{uid}
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final role = userDoc.data()?['role'] as String? ?? 'jobseeker';

        if (!mounted) return;

        // 2. Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user.displayName ?? "User"}!'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 3. Redirect based on role — pushAndRemoveUntil prevents going back to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => role == 'employer'
                ? const EmployerDashboard()
                : HomePage(user: user),
          ),
              (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      String msg = "Login failed. Please check your credentials.";
      if (e.code == 'user-not-found') msg = "No user found with this email.";
      if (e.code == 'wrong-password') msg = "Incorrect password.";
      if (e.code == 'invalid-credential') msg = "Invalid email or password.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Log in to continue your job search.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Email Field
                _buildLabel("Email Address"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: "you@example.com",
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildLabel("Password"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    hint: "••••••••",
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B52E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                        "Login",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for consistent styling
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF3B52E8)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}