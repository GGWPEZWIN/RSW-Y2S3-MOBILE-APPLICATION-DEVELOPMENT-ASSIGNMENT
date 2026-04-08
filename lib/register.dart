import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ── Route imports — adjust paths to match your project structure ──────────────
// import '../Employer/employer_dashboard.dart';
// import '../Jobseeker/home_page.dart';
// import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {

  // ── Form ───────────────────────────────────────────────────────────────────
  final _formKey             = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  String   _role             = 'jobseeker'; // 'jobseeker' | 'employer'
  File?    _profileImage;
  bool     _isLoading        = false;
  bool     _obscurePassword  = true;
  bool     _obscureConfirm   = true;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animController;
  late final Animation<double>   _fadeAnim;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color kBlue       = Color(0xFF3B52E8);
  static const Color kBlueDark   = Color(0xFF2A3BC4);
  static const Color kBg         = Color(0xFFF5F6FA);
  static const Color kCard       = Colors.white;
  static const Color kText       = Color(0xFF0F172A);
  static const Color kSubtext    = Color(0xFF64748B);
  static const Color kBorder     = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Pick profile photo ─────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // ── Upload photo to Firebase Storage ──────────────────────────────────────
  Future<String?> _uploadProfilePhoto(String uid) async {
    if (_profileImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/$uid.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Photo upload error: $e');
      return null;
    }
  }

  // ── Register handler ───────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user!;
      final uid  = user.uid;

      // 2. Upload profile photo (optional)
      final photoUrl = await _uploadProfilePhoto(uid);

      // 3. Update Auth display name + photoURL
      await user.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);

      // 4. Save user document to Firestore
      //    Fields: name, email, photoUrl, createdAt, role
      //    Note: password is NOT stored in Firestore (Firebase Auth handles it)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name':      _nameController.text.trim(),
        'email':     _emailController.text.trim(),
        'photoUrl':  photoUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'role':      _role,               // 'jobseeker' or 'employer'
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Account created! Welcome aboard 🎉'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // 5. Navigate based on role
      // Replace these with your actual routes:
      if (_role == 'employer') {
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => const CompanyRegistrationPage()));
      } else {
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => HomePage(user: user)));
      }

      // Temporary: just pop back to login
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered.';
          break;
        case 'weak-password':
          msg = 'Password must be at least 6 characters.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        default:
          msg = e.message ?? 'Registration failed. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Back button ────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: kText),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Title ──────────────────────────────────────────────
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: kText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join JobBuddy and find your next opportunity.',
                    style: TextStyle(fontSize: 14, color: kSubtext),
                  ),
                  const SizedBox(height: 32),

                  // ── Profile photo picker ───────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEEF0FD),
                              border: Border.all(color: kBlue, width: 2.5),
                              image: _profileImage != null
                                  ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? const Icon(Icons.person_rounded,
                                size: 44, color: kBlue)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kBlue,
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Tap to add profile photo',
                      style: TextStyle(fontSize: 12, color: kSubtext),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Role selector ──────────────────────────────────────
                  _sectionLabel('I am a...'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _roleCard(
                          label: 'Job Seeker',
                          subtitle: 'Looking for work',
                          icon: Icons.work_outline_rounded,
                          value: 'jobseeker',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _roleCard(
                          label: 'Employer',
                          subtitle: 'Hiring talent',
                          icon: Icons.business_center_outlined,
                          value: 'employer',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Full Name ──────────────────────────────────────────
                  _sectionLabel('Full Name'),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _nameController,
                    hint: 'e.g. Ahmad Faris',
                    icon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Full name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Email ──────────────────────────────────────────────
                  _sectionLabel('Email Address'),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _emailController,
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password ───────────────────────────────────────────
                  _sectionLabel('Password'),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _passwordController,
                    hint: 'Minimum 6 characters',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: kSubtext,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm Password ───────────────────────────────────
                  _sectionLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _confirmController,
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: kSubtext,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm password';
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Register button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        disabledBackgroundColor: kBlue.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                          : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Login link ─────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: kSubtext, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: kBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Role card widget ───────────────────────────────────────────────────────
  Widget _roleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? kBlue.withOpacity(0.06) : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kBlue : kBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 22,
                    color: isSelected ? kBlue : kSubtext),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? kBlue : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? kBlue : kBorder,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? kBlue : kText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: kSubtext),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: kText,
      ),
    );
  }

  // ── Reusable text field ────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFADBAC7)),
        prefixIcon: Icon(icon, size: 20, color: kBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kCard,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}