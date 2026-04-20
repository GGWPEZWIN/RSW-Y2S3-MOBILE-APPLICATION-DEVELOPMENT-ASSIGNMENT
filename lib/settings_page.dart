import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // IMPORTANT: Add this import
import '../../../login.dart';
import '../../services/app_state_manager.dart'; // Update this path to your manager file

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

  // --- DELETE LOGIC (EMAIL VERIFICATION) ---
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
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // --- SIGN OUT CONFIRMATION ---
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
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- THEME DIALOG ---
  void _showThemeDialog(BuildContext context) {
    // Get the state manager without listening
    final stateManager = Provider.of<AppStateManager>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Theme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.orange),
              title: const Text("Light Theme"),
              trailing: stateManager.themeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
              onTap: () {
                stateManager.setTheme(false); // false = Light
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.indigo),
              title: const Text("Dark Theme"),
              trailing: stateManager.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
              onTap: () {
                stateManager.setTheme(true); // true = Dark
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- LANGUAGE DIALOG ---
  void _showLanguageDialog(BuildContext context) {
    final stateManager = Provider.of<AppStateManager>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("English"),
              trailing: stateManager.locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
              onTap: () {
                stateManager.setLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Bahasa Melayu"),
              trailing: stateManager.locale.languageCode == 'ms'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
              onTap: () {
                stateManager.setLanguage('ms');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("中文 (Chinese)"),
              trailing: stateManager.locale.languageCode == 'zh'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB)) : null,
              onTap: () {
                stateManager.setLanguage('zh');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DELETE DIALOG (EMAIL CHECK) ---
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
            const SizedBox(height: 10),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _handleDeleteAccount(context, emailController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimaryBlue = Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSettingTile(Icons.language, "Language", onTap: () => _showLanguageDialog(context)),
          _buildSettingTile(Icons.palette_outlined, "Theme", onTap: () => _showThemeDialog(context)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showSignOutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: const Text("Sign Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showDeleteDialog(context),
                  child: const Text("Delete Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }
}