import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  // Password Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isGoogleUser = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    // Check if the user is a Google user
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

  // --- RE-AUTHENTICATION LOGIC ---
  Future<bool> _reauthenticate(String currentPassword) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: currentPassword,
      );
      await widget.user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint("Re-auth error: $e");
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = widget.user;
      String? photoUrl = user.photoURL;

      // 1. Password Change Logic for App Users
      if (!_isGoogleUser && _newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          throw "Please enter your current password to verify identity.";
        }

        bool isAuthenticated = await _reauthenticate(_currentPasswordController.text.trim());
        if (!isAuthenticated) {
          throw "Current password verification failed.";
        }

        await user.updatePassword(_newPasswordController.text.trim());
      }

      // 2. Handle Image Upload
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
        await user.updatePhotoURL(photoUrl);
      }

      // 3. Update Display Name
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // 4. Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'photoUrl': photoUrl,
      });

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update error: $e");
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
    const Color brandBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfilePicture(brandBlue),
              const SizedBox(height: 32),

              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email Address", Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number", Icons.phone_android_outlined),
              const SizedBox(height: 16),
              _buildTextField(_locationController, "Location (City, State)", Icons.location_on_outlined),

              // --- PASSWORD SECTION (Only for non-Google users) ---
              if (!_isGoogleUser) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue)),
                ),
                const SizedBox(height: 16),
                _buildTextField(_currentPasswordController, "Current Password", Icons.lock_open_outlined, isPassword: true),
                const SizedBox(height: 16),
                _buildTextField(_newPasswordController, "New Password", Icons.lock_outline, isPassword: true),
              ],

              const SizedBox(height: 40),
              _buildSaveButton(brandBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(Color brandBlue) {
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
                ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFF2563EB)) : null,
          ),
          Positioned(
              bottom: 0, right: 0,
              child: CircleAvatar(radius: 18, backgroundColor: brandBlue, child: const Icon(Icons.edit, size: 15, color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color brandBlue) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}