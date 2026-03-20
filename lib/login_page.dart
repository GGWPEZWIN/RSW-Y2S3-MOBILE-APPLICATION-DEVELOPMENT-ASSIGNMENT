import 'package:flutter/material.dart';
import 'email_login_page.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Matches the soft background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // --- Header Logo ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work, color: Color(0xFF425AE2), size: 30),
                  const SizedBox(width: 8),
                  const Text(
                    "JobBuddy",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // --- Main Illustration ---
              Image.asset(
                'assets/LoginPic.jpg',
                height: 220,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 30),

              // --- Login Method ---
              const Center(
                child: Text(
                  "Find the right job",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF425AE2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Build your career",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // --- Google Button ---
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFD1D1EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder for Google G icon
                    const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                    const SizedBox(width: 8),
                    const Text(
                      "Continue with Google",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // --- Email Button ---
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmailLoginPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFD1D1EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Continue with email",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),

              // --- Register Link ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? ", style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () {}, // Add registration navigation here
                    child: const Text(
                      "Register",
                      style: TextStyle(color: Color(0xFF1A37CC), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // --- Footer ---
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Recruitment? Visit ", style: TextStyle(fontSize: 14)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "here",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A37CC),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}