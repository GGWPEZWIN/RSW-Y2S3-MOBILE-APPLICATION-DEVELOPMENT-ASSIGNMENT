import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../login.dart'; // Ensure this path correctly points to your login screen

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // --- SIGN OUT LOGIC ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  // --- DELETE ACCOUNT LOGIC ---
  Future<void> _handleDeleteAccount(BuildContext context, String inputEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if the typed email matches the current user
    if (inputEmail.trim().toLowerCase() != user.email?.toLowerCase()) {
      _showSnackBar(context, "Email does not match. Please try again.", Colors.orange);
      return;
    }

    try {
      // 1. Delete data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 2. Delete user from Firebase Auth
      await user.delete();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      if (context.mounted) {
        _showSnackBar(context, "Session expired. Please re-login to delete account.", Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating
      ),
    );
  }

  // --- SIGN OUT CONFIRMATION DIALOG ---
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut(context);
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _showDeleteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This is permanent. All profile data will be lost.'),
            const SizedBox(height: 12),
            Text('Type your email to confirm:',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)
            ),
            Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _handleDeleteAccount(context, emailController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Spacer(),
            // SIGN OUT BUTTON
            ElevatedButton(
              onPressed: () => _showSignOutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text("Sign Out",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
            const SizedBox(height: 16),
            // DELETE ACCOUNT BUTTON
            TextButton(
              onPressed: () => _showDeleteDialog(context),
              child: const Text("Delete Account",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
          ],
        ),
      ),
    );
  }
}