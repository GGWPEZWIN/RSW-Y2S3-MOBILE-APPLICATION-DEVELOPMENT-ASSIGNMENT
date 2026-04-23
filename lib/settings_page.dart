import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../login.dart';
import '../../../main.dart';
import 'l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const Color kPrimaryBlue = Color(0xFF2563EB);

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
  Future<void> _handleDeleteAccount(BuildContext context, String inputEmail, AppLocalizations l10n) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (inputEmail.trim().toLowerCase() != user.email?.toLowerCase()) {
      _showSnackBar(context, "Email does not match.", Colors.orange);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Session expired. Re-login to delete.", Colors.red);
      }
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ms': return "Bahasa Melayu";
      case 'zh': return "中文 (Chinese)";
      default: return "English";
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // --- LANGUAGE SELECTION DIALOG ---
  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(l10n.selectLanguage), // FIXED: Using l10n parameter
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langTile("🇺🇸", "English", const Locale('en'), context),
            _langTile("🇲🇾", "Bahasa Melayu", const Locale('ms'), context),
            _langTile("🇨🇳", "中文", const Locale('zh'), context),
          ],
        ),
      ),
    );
  }

  Widget _langTile(String flag, String label, Locale locale, BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
    );
  }

  // --- SIGN OUT CONFIRMATION DIALOG ---
  void _showSignOutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(l10n.signOutBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _signOut(context); },
            child: const Text('Sign Out', style: TextStyle(color: kPrimaryBlue)),
          ),
        ],
      ),
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _showDeleteDialog(BuildContext context, AppLocalizations l10n) {
    final emailController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(l10n.deleteAccBtn, style: const TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is permanent.'),
            TextField(controller: emailController, decoration: const InputDecoration(hintText: "Enter email")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _handleDeleteAccount(context, emailController.text, l10n),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initialize l10n here
    final l10n = AppLocalizations.of(context)!;

    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(l10n.langLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            ValueListenableBuilder<Locale>(
              valueListenable: appLocale,
              builder: (context, locale, _) {
                return InkWell(
                  onTap: () => _showLanguageDialog(context, l10n), // Pass l10n here
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: kPrimaryBlue),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_getLanguageName(locale.languageCode))),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _showSignOutDialog(context, l10n),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, minimumSize: const Size(double.infinity, 55)),
              child: Text(l10n.signOutBtn, style: const TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => _showDeleteDialog(context, l10n),
              child: Text(l10n.deleteAccBtn, style: const TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}