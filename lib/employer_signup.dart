// lib/Employer/Auth/employer_signup_screen.dart
//
// Employer registration — JobStreet/Seek Employer style
// Step 1: Account details (name, work email, password)
// Step 2: Company info (company name, industry, company size, position)
// • Saves role:'employer' + all company fields to Firestore
// • Sends email verification
// • On success navigates to EmployerDashboard

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Employer/MainScreen/employer_dashboard.dart';
import 'employer_login.dart';

class EmployerSignUpScreen extends StatefulWidget {
  const EmployerSignUpScreen({super.key});

  @override
  State<EmployerSignUpScreen> createState() => _EmployerSignUpScreenState();
}

class _EmployerSignUpScreenState extends State<EmployerSignUpScreen> {

  // ── Steps ─────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = Account  |  1 = Company

  // ── Step 1 controllers ────────────────────────────────────────────────────
  final _step1Key      = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _obscurePw      = true;
  bool _obscureConfirm = true;

  // ── Step 2 controllers ────────────────────────────────────────────────────
  final _step2Key      = GlobalKey<FormState>();
  final _companyCtrl   = TextEditingController();
  final _positionCtrl  = TextEditingController();
  String? _selectedIndustry;
  String? _selectedSize;

  bool _isLoading = false;

  // ── Options ───────────────────────────────────────────────────────────────
  static const List<String> _industries = [
    'Technology & IT',
    'Finance & Banking',
    'Healthcare & Medical',
    'Manufacturing',
    'Retail & E-commerce',
    'Education',
    'Hospitality & Tourism',
    'Construction & Real Estate',
    'Media & Communications',
    'Logistics & Transportation',
    'Oil & Gas',
    'Government & Public Sector',
    'Other',
  ];

  static const List<String> _companySizes = [
    '1–10 employees',
    '11–50 employees',
    '51–200 employees',
    '201–500 employees',
    '501–1,000 employees',
    '1,001–5,000 employees',
    '5,000+ employees',
  ];

  // ── Password regex ────────────────────────────────────────────────────────
  final RegExp _pwRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,15}$');

  // ── Brand colours ─────────────────────────────────────────────────────────
  static const Color _navy     = Color(0xFF0D1B3E);
  static const Color _accent   = Color(0xFF3B52E8);
  static const Color _bg       = Color(0xFFF4F6FB);
  static const Color _border   = Color(0xFFDDE3EF);
  static const Color _text     = Color(0xFF0D1B3E);
  static const Color _subtext  = Color(0xFF6B7A99);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_step2Key.currentState!.validate()) return;
    if (_selectedIndustry == null) {
      _snack('Please select your industry', error: true);
      return;
    }
    if (_selectedSize == null) {
      _snack('Please select your company size', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = credential.user!;
      await user.updateDisplayName(_nameCtrl.text.trim());

      // 2. Save to Firestore — role:'employer' is critical
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name':        _nameCtrl.text.trim(),
        'email':       _emailCtrl.text.trim(),
        'role':        'employer',              // ✅ employer role
        'companyName': _companyCtrl.text.trim(),
        'industry':    _selectedIndustry,
        'companySize': _selectedSize,
        'position':    _positionCtrl.text.trim(),
        'photoUrl':    '',
        'createdAt':   FieldValue.serverTimestamp(),
      });

      // 3. Send email verification
      await user.sendEmailVerification();

      // 4. Sign out until they verify
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      _showVerificationDialog();

    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed.';
      if (e.code == 'email-already-in-use') msg = 'This email is already registered.';
      if (e.code == 'weak-password')        msg = 'Password must be at least 6 characters.';
      if (e.code == 'invalid-email')        msg = 'Invalid email address.';
      _snack(msg, error: true);
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.mark_email_read_outlined, color: Color(0xFF22C55E), size: 28),
          SizedBox(width: 10),
          Text('Check Your Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification email has been sent to:',
              style: TextStyle(color: _subtext, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              _emailCtrl.text.trim(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _navy, fontSize: 14),
            ),
            const SizedBox(height: 14),
            const Text(
              'Please verify your email before signing in to your employer account.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
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
                      builder: (_) => const EmployerLoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Go to Login',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
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

  InputDecoration _inputDec({required String hint, required IconData icon, Widget? suffix}) {
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
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _fieldLabel(String text, {bool required = true}) {
    return Row(children: [
      Text(text,
          style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: _text)),
      if (required)
        const Text(' *',
            style: TextStyle(color: Colors.redAccent, fontSize: 13.5)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Dark navy header ────────────────────────────────────────────
          Container(
            color: _navy,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + brand
                Row(children: [
                  GestureDetector(
                    onTap: () {
                      if (_step == 1) {
                        setState(() => _step = 0);
                      } else {
                        Navigator.pop(context);
                      }
                    },
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
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(text: 'JobBuddy ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      TextSpan(text: 'Employer',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF9FADC8))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),

                Text(
                  _step == 0 ? 'Create Employer Account' : 'Company Details',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _step == 0
                      ? 'Start hiring top talent on JobBuddy.'
                      : 'Tell us about your company so candidates know who they\'re applying to.',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8A99B8), height: 1.4),
                ),
                const SizedBox(height: 20),

                // ── Step indicator ──────────────────────────────────────
                Row(children: [
                  _stepDot(0, 'Account'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _step >= 1
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  _stepDot(1, 'Company'),
                ]),
              ],
            ),
          ),

          // ── Form content ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: _step == 0 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final active = _step >= index;
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: active && _step > index
              ? const Icon(Icons.check_rounded, size: 16, color: _navy)
              : Text('${index + 1}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? _navy : Colors.white.withOpacity(0.5))),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: active ? Colors.white : Colors.white.withOpacity(0.4),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Account details
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Full name
          _fieldLabel('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDec(hint: 'e.g. Ahmad Faris', icon: Icons.badge_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 18),

          // Work email
          _fieldLabel('Work Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDec(hint: 'company@email.com', icon: Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          Row(children: const [
            Icon(Icons.info_outline_rounded, size: 13, color: _subtext),
            SizedBox(width: 5),
            Text('Use your work or company email.',
                style: TextStyle(fontSize: 11, color: _subtext)),
          ]),
          const SizedBox(height: 18),

          // Password
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePw,
            decoration: _inputDec(
              hint: 'Min 8 chars, include A–Z, 0–9, @\$!%*?&',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_obscurePw
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                    color: _subtext, size: 20),
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (!_pwRegex.hasMatch(v)) {
                return 'Must be 8–15 chars with uppercase, lowercase, number & special char';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Confirm password
          _fieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: _inputDec(
              hint: 'Re-enter password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                    color: _subtext, size: 20),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (_step1Key.currentState!.validate()) {
                  setState(() => _step = 1);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Text('Continue',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Login link
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EmployerLoginScreen()),
              ),
              child: RichText(
                text: const TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: _subtext, fontSize: 14),
                  children: [
                    TextSpan(text: 'Sign In',
                        style: TextStyle(
                            color: _accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Company details
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Company name
          _fieldLabel('Company Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDec(
                hint: 'e.g. Jabil Circuit Sdn Bhd',
                icon: Icons.business_outlined),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
          ),
          const SizedBox(height: 18),

          // Industry
          _fieldLabel('Industry'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedIndustry,
            hint: const Text('Select your industry',
                style: TextStyle(color: Color(0xFFADB8D0), fontSize: 14)),
            decoration: _inputDec(
                hint: '',
                icon: Icons.category_outlined),
            items: _industries.map((ind) =>
                DropdownMenuItem(value: ind, child: Text(ind, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _selectedIndustry = v),
            validator: (v) => v == null ? 'Please select industry' : null,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 18),

          // Company size
          _fieldLabel('Company Size'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSize,
            hint: const Text('Select number of employees',
                style: TextStyle(color: Color(0xFFADB8D0), fontSize: 14)),
            decoration: _inputDec(
                hint: '',
                icon: Icons.people_outline_rounded),
            items: _companySizes.map((s) =>
                DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _selectedSize = v),
            validator: (v) => v == null ? 'Please select company size' : null,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 18),

          // Your position
          _fieldLabel('Your Position / Job Title'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _positionCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDec(
                hint: 'e.g. HR Manager, Talent Acquisition Lead',
                icon: Icons.work_outline_rounded),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Your position is required' : null,
          ),
          const SizedBox(height: 28),

          // Terms notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D08A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.gavel_rounded, size: 15, color: Color(0xFF92710D)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'By creating an account you agree to JobBuddy\'s Terms of Service '
                        'and confirm that you are authorised to post jobs on behalf of your company.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B5200), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create account button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
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
                  : const Text('Create Employer Account',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}