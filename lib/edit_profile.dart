import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user}); // Updated to super.key

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isGoogleUser = false;
  final _formKey = GlobalKey<FormState>();
  static const Color brandBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    _isGoogleUser = widget.user.providerData.any((p) => p.providerId == 'google.com');
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['name'] ?? widget.user.displayName ?? '';
          _emailController.text = data?['email'] ?? widget.user.email ?? '';
          _phoneController.text = data?['phone'] ?? '';
          _locationController.text = data?['location'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: currentPassword,
      );
      await widget.user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = widget.user;
      String? photoUrl = user.photoURL;

      // 1. Password Logic
      if (!_isGoogleUser && _newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) throw "Current password required.";
        bool success = await _reauthenticate(_currentPasswordController.text.trim());
        if (!success) throw "Password verification failed.";
        await user.updatePassword(_newPasswordController.text.trim());
      }

      // 2. Image Logic
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // 3. Update Firestore (Using set with merge to keep Role safe)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildProfilePicture()),
              const SizedBox(height: 32),

              _buildLabel("Full Name"),
              _buildTextField(_nameController, "Your Name", Icons.person_outline),

              const SizedBox(height: 16),
              _buildLabel("Email Address (Locked)"),
              // --- FIXED: ENABLED = FALSE ---
              _buildTextField(_emailController, "Email", Icons.lock_outline, enabled: false),

              const SizedBox(height: 16),
              _buildLabel("Phone Number"),
              _buildTextField(_phoneController, "01x-xxxxxxx", Icons.phone_android_outlined),

              const SizedBox(height: 16),
              _buildLabel("Location"),
              _buildTextField(_locationController, "City, State", Icons.location_on_outlined),

              if (!_isGoogleUser) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue, fontSize: 16)),
                const SizedBox(height: 16),
                _buildTextField(_currentPasswordController, "Current Password", Icons.lock_open_outlined, isPassword: true),
                const SizedBox(height: 16),
                _buildTextField(_newPasswordController, "New Password", Icons.lock_outline, isPassword: true),
              ],

              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null) as ImageProvider?,
            child: (_imageFile == null && widget.user.photoURL == null)
                ? const Icon(Icons.person, size: 40, color: brandBlue) : null,
          ),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: brandBlue, child: const Icon(Icons.edit, size: 15, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: !enabled,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}