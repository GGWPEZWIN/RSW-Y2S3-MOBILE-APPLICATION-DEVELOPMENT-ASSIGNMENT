import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditBackgroundPage extends StatefulWidget {
  final String currentBackground;
  const EditBackgroundPage({super.key, required this.currentBackground});

  @override
  State<EditBackgroundPage> createState() => _EditBackgroundPageState();
}

class _EditBackgroundPageState extends State<EditBackgroundPage> {
  late TextEditingController _bgController;
  bool _isLoading = false;
  static const Color brandBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _bgController = TextEditingController(text: widget.currentBackground);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _saveBackground() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'background': _bgController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Background updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit background",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text("Company Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            TextField(
              controller: _bgController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: "Enter company description...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandBlue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // The "Middle" Save Button (Pill shaped)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBackground,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}