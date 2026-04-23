import 'package:assignment/services/app_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Ensure provider is imported
import '../../../login.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

// --- LANGUAGE SELECTION DIALOG ---
  void _showLanguageDialog(BuildContext context) {
    // This will no longer throw an error!
    final stateManager = Provider.of<AppStateManager>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildLanguageOption(context, "English", 'en', stateManager),
            _buildLanguageOption(context, "Bahasa Melayu", 'ms', stateManager),
            _buildLanguageOption(context, "中文 (Chinese)", 'zh', stateManager),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, String code, AppStateManager manager) {
    return ListTile(
      title: Text(title),
      trailing: manager.locale.languageCode == code
          ? const Icon(Icons.check, color: Color(0xFF2563EB))
          : null,
      onTap: () {
        manager.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  // --- SIGN OUT LOGIC ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
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

    if (inputEmail.trim().toLowerCase() != user.email?.toLowerCase()) {
      _showSnackBar(context, "Email does not match. Please try again.", Colors.orange);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      if (mounted) {
        _showSnackBar(context, "Session expired. Please re-login to delete account.", Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // --- SIGN OUT CONFIRMATION DIALOG ---
  void _showSignOutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(l10n.signOutBtn, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut(context);
            },
            child: Text('Sign Out', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
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
        title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This is permanent. All profile data will be lost.'),
            const SizedBox(height: 12),
            Text('Type your email to confirm:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => _handleDeleteAccount(context, emailController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color kPrimaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            // 1. LANGUAGE SELECTION (Triggers your BottomSheet)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                leading: const Icon(Icons.translate, color: kPrimaryBlue),
                title: Text(l10n.selectLanguage, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () => _showLanguageDialog(context),
              ),
            ),

            // 2. NOTIFICATION TOGGLE
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                title: Text(
                  l10n.notificationsLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(l10n.notificationsSubtitle),
                secondary: Icon(
                  _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: _notificationsEnabled ? kPrimaryBlue : Colors.grey,
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() => _notificationsEnabled = value);
                },
                activeColor: kPrimaryBlue,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () => _showSignOutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: Text(l10n.signOutBtn, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: () => _showDeleteDialog(context),
              child: Text(l10n.deleteAccBtn, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}