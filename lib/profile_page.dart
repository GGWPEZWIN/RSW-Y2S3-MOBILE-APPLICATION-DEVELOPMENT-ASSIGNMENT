import 'package:flutter/material.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40),
            const SizedBox(height: 10),

            const Text("John Doe", style: TextStyle(fontSize: 18)),
            const Text("johndoe@gmail.com"),

            const SizedBox(height: 20),

            ListTile(
              title: const Text("Personal Summary"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
            ListTile(
              title: const Text("CV"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
            ListTile(
              title: const Text("Education"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              },
              child: const Text("Go to Settings"),
            )
          ],
        ),
      ),
    );
  }
}