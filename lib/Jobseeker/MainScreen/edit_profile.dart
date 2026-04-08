import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();

  // State
  File? _imageFile;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pick Image Logic
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // Main Update Function
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = widget.user;

      // 1. Update Name
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // 2. Update Email
      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // 3. Update Password (only if field isn't empty)
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      // 4. Update Profile Picture
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putFile(_imageFile!);
        final url = await ref.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: const Color(0xFF425AE2)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with Edit Icon
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null) as ImageProvider?,
                      child: (_imageFile == null && widget.user.photoURL == null)
                          ? const Icon(Icons.camera_alt, size: 40) : null,
                    ),
                    const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, child: Icon(Icons.edit, size: 15))),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField(_nameController, "Full Name", Icons.person),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email Address", Icons.email),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "New Password (Leave blank to keep current)", Icons.lock, isPassword: true),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF425AE2)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}