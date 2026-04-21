import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

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
  String? _currentPhotoData; // Stores either Google URL or Base64 string
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
          _phoneController.text = data?['phone'] ?? '';
          _locationController.text = data?['location'] ?? '';

          // --- FIX: Fallback to Google photoURL if Firestore is empty ---
          _currentPhotoData = data?['photoUrl'] ?? widget.user.photoURL;
        });
      } else {
        // Brand new user: use Google photo URL as default
        setState(() {
          _currentPhotoData = widget.user.photoURL;
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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String> _processImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return "";

    // Resize to keep Firestore document size small
    img.Image resizedImage = img.copyResize(originalImage, width: 150);
    return base64Encode(img.encodeJpg(resizedImage, quality: 70));
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
      String? photoToSave = _currentPhotoData;

      // 1. Password Logic
      if (!_isGoogleUser && _newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) throw "Current password required.";
        bool success = await _reauthenticate(_currentPasswordController.text.trim());
        if (!success) throw "Password verification failed.";
        await user.updatePassword(_newPasswordController.text.trim());
      }

      // 2. Image Processing (Convert to Base64 if a new file was picked)
      if (_imageFile != null) {
        photoToSave = await _processImage(_imageFile!);
      }

      // 3. Update Auth Display Name
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // 4. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'photoUrl': photoToSave,
      }, SetOptions(merge: true));

      await user.reload();

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
    ImageProvider? imageProvider;

    if (_imageFile != null) {
      // 1. Show the local file if user just picked one
      imageProvider = FileImage(_imageFile!);
    } else if (_currentPhotoData != null && _currentPhotoData!.isNotEmpty) {
      // 2. Check if data is a URL (Google) or Base64 (Manual)
      if (_currentPhotoData!.startsWith('http')) {
        imageProvider = NetworkImage(_currentPhotoData!);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(_currentPhotoData!));
        } catch (e) {
          imageProvider = null;
        }
      }
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 40, color: brandBlue)
                : null,
          ),
          const Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: brandBlue,
                  child: Icon(Icons.edit, size: 15, color: Colors.white)
              )
          ),
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
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}