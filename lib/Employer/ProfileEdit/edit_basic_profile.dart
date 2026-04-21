import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class EditBasicProfilePage extends StatefulWidget {
  final User user;
  final String currentName;
  final String currentPhone;
  final String currentLocation; // Added location parameter

  const EditBasicProfilePage({
    super.key, // Updated to super parameter
    required this.user,
    required this.currentName,
    required this.currentPhone,
    required this.currentLocation,
  });

  @override
  State<EditBasicProfilePage> createState() => _EditBasicProfilePageState();
}

class _EditBasicProfilePageState extends State<EditBasicProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController; // Added location controller
  final MapController _mapController = MapController();
  bool _isLocating = false;
  final Location _location = Location();

  // Password Controllers for Local Auth
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  static const Color brandBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _locationController = TextEditingController(text: widget.currentLocation);
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

  LatLng _getMapCenter() {
    if (_locationController.text.contains(',')) {
      try {
        final parts = _locationController.text.split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      } catch (_) {}
    }
    return const LatLng(3.140853, 101.693207); // Default
  }

  void _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final data = await _location.getLocation();
      if (data.latitude != null && data.longitude != null) {
        final myLocation = LatLng(data.latitude!, data.longitude!);

        setState(() {
          _locationController.text =
          "${data.latitude!.toStringAsFixed(6)}, ${data.longitude!.toStringAsFixed(6)}";
        });

        _mapController.move(myLocation, 15);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // Verification logic for password changes
  Future<bool> _reauthenticate(String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: password,
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
      String? photoUrl;

      // 1. Password Change Logic
      if (_newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          throw "Enter current password to verify identity.";
        }
        bool success = await _reauthenticate(_currentPasswordController.text.trim());
        if (!success) throw "Current password verification failed.";
        await widget.user.updatePassword(_newPasswordController.text.trim());
      }

      // 2. Image Upload
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('employer_logos/${widget.user.uid}.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // 3. Update Firestore (Using Set with Merge to be safe)
      Map<String, dynamic> data = {
        'companyName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      };
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
        title: const Text('Edit Basic Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildLogoPicker(),
              const SizedBox(height: 32),

              _buildLabel("Company Name"),
              _buildTextField(_nameController, "e.g. Jabil", Icons.business),

              const SizedBox(height: 20),
              _buildLabel("Contact Email (Read Only)"),
              _buildTextField(_emailController, "Email", Icons.lock_outline, enabled: false),

              const SizedBox(height: 20),
              _buildLabel("Company Phone"),
              _buildTextField(_phoneController, "e.g. +604...", Icons.phone_android_outlined),

              const SizedBox(height: 20),
              _buildLabel("Company Location"),
              _buildTextField(
                _locationController,
                "e.g. 123 Business Park, Penang",
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),

              Stack(
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialZoom: 13,
                          initialCenter: _getMapCenter(),
                          onTap: (tapPos, point) {
                            setState(() {
                              _locationController.text =
                              "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.jobbuddy',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_locationController.text.contains(','))
                                Marker(
                                  point: _getMapCenter(),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── FLOATING GPS BUTTON (Matches Schedule Interview) ──
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: FloatingActionButton.small(
                      heroTag: "btn_profile_gps", // Unique tag to avoid errors
                      backgroundColor: Colors.white,
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      child: _isLocating
                          ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B4FD8))
                      )
                          : const Icon(Icons.my_location, color: Color(0xFF3B4FD8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue)),
              ),
              const SizedBox(height: 16),
              _buildTextField(_currentPasswordController, "Current Password", Icons.lock_open_outlined, isPassword: true),
              const SizedBox(height: 16),
              _buildTextField(_newPasswordController, "New Password", Icons.lock_outline, isPassword: true),

              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
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
                ? const Icon(Icons.add_a_photo_outlined, size: 35, color: brandBlue) : null,
          ),
          Positioned(
              bottom: 0, right: 0,
              child: CircleAvatar(radius: 18, backgroundColor: brandBlue, child: const Icon(Icons.edit, size: 15, color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ),
  );

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      {bool enabled = true, bool isPassword = false, Widget? suffixIcon} // Add suffixIcon here
      ) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        suffixIcon: suffixIcon, // Add this line
        filled: !enabled,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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