import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../edit_profile.dart';
import '../../login.dart';
import '../../services/notification_service.dart';

class ProfilePage extends StatelessWidget {
  final User? user;

  const ProfilePage({Key? key, this.user}) : super(key: key);

  static const Color kPrimary = Color(0xFF425AE2);

// ── Delete account dialog ─────────────────────────────────────────────────
  Future<void> _showDeleteDialog(BuildContext context) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Account'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action is permanent. Please enter your password to confirm.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final password = passwordCtrl.text.trim();
                if (password.isEmpty) {
                  setDialogState(() => errorText = 'Password required');
                  return;
                }

                try {
                  // 1. Re-authenticate to prevent 'requires-recent-login' error
                  final credential = EmailAuthProvider.credential(
                    email: user?.email ?? '',
                    password: password,
                  );
                  await user?.reauthenticateWithCredential(credential);

                  // 2. Close the password dialog
                  if (ctx.mounted) Navigator.pop(ctx);

                  // 3. CALL THE CLEAN DELETE
                  await _deleteAccount(context);

                } on FirebaseAuthException catch (e) {
                  setDialogState(() => errorText = 'Incorrect password or error.');
                }
              },
              child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // Show loading indicator
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logging out...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              // Sign out from Firebase
              await FirebaseAuth.instance.signOut();
              NotificationService().stopListening();

              // Navigate to login screen and remove all previous routes
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final uid = user?.uid;
      if (uid == null) return;

      // 1. EXIT THE PAGE IMMEDIATELY
      // This unmounts ProfilePage so it stops listening to the user object.
      // Use your specific login route or widget here.
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

      // 2. Perform deletions in the background
      final db = FirebaseFirestore.instance;

      // Delete applications
      final apps = await db.collection('applications').where('userId', isEqualTo: uid).get();
      for (final doc in apps.docs) { await doc.reference.delete(); }

      // Delete User Doc
      await db.collection('users').doc(uid).delete();

      // 3. Final step: Delete the Auth user
      // Since we navigated away, this won't trigger a red screen on the ProfilePage.
      await user?.delete();

    } catch (e) {
      debugPrint("Background delete failed: $e");
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person,
                            size: 60, color: kPrimary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: kPrimary),
                  title: const Text('Name'),
                  subtitle: Text(user?.displayName ?? 'Not set'),
                ),
              ),

              // Email
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email, color: kPrimary),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not set'),
                ),
              ),

              // Member since
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: kPrimary),
                  title: const Text('Member Since'),
                  subtitle: Text(
                    user?.metadata.creationTime
                        ?.toString()
                        .split(' ')[0] ??
                        'Not available',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Edit Profile
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(user: user!),
                        ),
                      ).then((_) {
                        (context as Element).markNeedsBuild();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Edit Profile',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delete Account
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showDeleteDialog(context),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}