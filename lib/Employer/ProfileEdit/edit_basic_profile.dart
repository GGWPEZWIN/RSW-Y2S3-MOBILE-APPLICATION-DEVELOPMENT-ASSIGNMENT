import 'dart:io';
import 'dart:convert'; // Added for Base64
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:image/image.dart' as img; // Added for resizing

class EditBasicProfilePage extends StatefulWidget {
  final User user;
  final String currentName;
  final String currentPhone;
  final String currentLocation;

  const EditBasicProfilePage({
    super.key,
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
  late TextEditingController _locationController;
  final MapController _mapController = MapController();
  bool _isLocating = false;
  final Location _location = Location();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  String? _currentBase64Logo; // To store existing logo string
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
    _loadExistingLogo();
  }

  // Fetch the Base64 logo from Firestore
  Future<void> _loadExistingLogo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentBase64Logo = doc.data()?['photoUrl'];
        });
      }
    } catch (e) {
      debugPrint("Logo load error: $e");
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

  LatLng _getMapCenter() {
    if (_locationController.text.contains(',')) {
      try {
        final parts = _locationController.text.split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      } catch (_) {}
    }
    return const LatLng(3.140853, 101.693207);
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
          _locationController.text = "${data.latitude!.toStringAsFixed(6)}, ${data.longitude!.toStringAsFixed(6)}";
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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      File file = File(picked.path);
      // Constraint: Same 2MB check as jobseeker side
      if (file.lengthSync() > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logo file too large! Max 2MB.")));
        return;
      }
      setState(() => _imageFile = file);
    }
  }

  // Resizing logic for company logo
  Future<String> _processLogo(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return "";
    img.Image resized = img.copyResize(original, width: 200); // Slightly larger than profile pic
    return base64Encode(img.encodeJpg(resized, quality: 70));
  }

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
      String? photoData = _currentBase64Logo;

      // 1. Password Verification
      if (_newPasswordController.text.isNotEmpty) {
        bool success = await _reauthenticate(_currentPasswordController.text.trim());
        if (!success) throw "Current password verification failed.";
        await widget.user.updatePassword(_newPasswordController.text.trim());
      }

      // 2. Base64 Image Processing
      if (_imageFile != null) {
        photoData = await _processLogo(_imageFile!);
      }

      // 3. Update Firestore (Syncing with jobseeker schema)
      Map<String, dynamic> data = {
        'companyName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'photoUrl': photoData, // Saved as Base64 string
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company Profile Updated!'), backgroundColor: Colors.green),
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
        backgroundColor: Colors.white, elevation: 0, centerTitle: true, foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
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
              _buildTextField(
                _nameController,
                "e.g. Jabil",
                Icons.business,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Company name required" : null,
              ),
              const SizedBox(height: 20),
              _buildLabel("Contact Email (Read Only)"),
              _buildTextField(_emailController, "Email", Icons.lock_outline, enabled: false),
              const SizedBox(height: 20),
              _buildLabel("Company Phone"),
              _buildTextField(
                _phoneController,
                "e.g. 01x-xxxxxxx",
                Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Phone number is required";
                  final phoneRegex = RegExp(r'^01[0-9]{1}-?[0-9]{7,8}$');
                  if (!phoneRegex.hasMatch(v)) return "Enter a valid Malaysian phone number";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel("Company Location"),
              _buildTextField(_locationController, "GPS Coordinates", Icons.location_on_outlined),
              const SizedBox(height: 12),

              // --- MAP VIEW ---
              Container(
                height: 220,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialZoom: 13,
                          initialCenter: _getMapCenter(),
                          onTap: (tapPos, point) {
                            setState(() {
                              _locationController.text = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.jobbuddy',
                          ),                          MarkerLayer(
                            markers: [
                              if (_locationController.text.contains(','))
                                Marker(point: _getMapCenter(), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 10, bottom: 10,
                        child: FloatingActionButton.small(
                          heroTag: "btn_employer_gps",
                          backgroundColor: Colors.white,
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          child: _isLocating
                              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, color: brandBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: brandBlue))),
              const SizedBox(height: 16),
              _buildTextField(
                _currentPasswordController,
                "Current Password",
                Icons.lock_open_outlined,
                isPassword: true,
                validator: (v) {
                  if (_newPasswordController.text.isNotEmpty && (v == null || v.isEmpty)) {
                    return "Current password required to change password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _newPasswordController,
                "New Password",
                Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_currentBase64Logo != null && _currentBase64Logo!.isNotEmpty) {
      if (_currentBase64Logo!.startsWith('http')) {
        imageProvider = NetworkImage(_currentBase64Logo!);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(_currentBase64Logo!));
        } catch (_) {}
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
            child: imageProvider == null ? const Icon(Icons.add_a_photo_outlined, size: 35, color: brandBlue) : null,
          ),
          const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: brandBlue, child: Icon(Icons.edit, size: 15, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      {bool enabled = true,
        bool isPassword = false,
        String? Function(String?)? validator,
        TextInputType? keyboardType}
      ) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}