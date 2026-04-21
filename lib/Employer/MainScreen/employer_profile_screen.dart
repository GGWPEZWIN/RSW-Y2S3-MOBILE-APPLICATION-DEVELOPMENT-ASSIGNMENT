import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../settings_page.dart';
import '../ProfileEdit/edit_basic_profile.dart';
import '../ProfileEdit/edit_company_background.dart';
import '../ProfileEdit/edit_company_information.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage())),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading profile"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final employerData = snapshot.data?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HEADER (LINKED TO BASIC PROFILE EDIT) ---
                // Now passes Name, Phone, AND Location to the edit page
                GestureDetector(
                  onTap: () {
                    if (user != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditBasicProfilePage(
                        user: user,
                        currentName: employerData?['companyName'] ?? '',
                        currentPhone: employerData?['phone'] ?? '',
                        currentLocation: employerData?['location'] ?? '', // Pass location here
                      )));
                    }
                  },
                  child: _buildHeader(employerData, user),
                ),

                const SizedBox(height: 24),
                const Text("Employer Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(thickness: 1, height: 24),

                // --- 2. COMPANY BACKGROUND ---
                _buildSectionHeader("Company Background", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EditBackgroundPage(
                    currentBackground: employerData?['background'] ?? "",
                  )));
                }),
                _buildContentCard(
                  title: "Background",
                  subtitle: employerData?['background'] ?? "No background description set.",
                  icon: Icons.business_outlined,
                ),

                const SizedBox(height: 24),

                // --- 3. COMPANY INFORMATION ---
                _buildSectionHeader("Company Information", onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EditCompanyInfo(
                    currentIndustry: employerData?['industry'] ?? "",
                    currentWebsite: employerData?['website'] ?? "",
                  )));
                }),
                _buildDetailBox(
                  industry: employerData?['industry'] ?? "Not Specified",
                  website: employerData?['website'] ?? "No website added",
                ),

                const SizedBox(height: 40),
                // --- BOTTOM LOCATION SECTION REMOVED ---
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(Map<String, dynamic>? data, User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: (data?['photoUrl'] != null) ? NetworkImage(data!['photoUrl']) : null,
            child: (data?['photoUrl'] == null) ? const Icon(Icons.business, size: 40, color: kPrimaryBlue) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data?['companyName'] ?? 'Company Name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildHeaderRow(Icons.email_outlined, data?['email'] ?? user?.email ?? ''),
                _buildHeaderRow(Icons.phone_outlined, data?['phone'] ?? 'Add phone'),
                // Shows the location in the header
                _buildHeaderRow(Icons.location_on_outlined, data?['location'] ?? 'Add office location'),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: kPrimaryBlue),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kPrimaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(onPressed: onTap, icon: const Icon(Icons.edit_outlined, size: 18, color: kTextSecondary)),
      ],
    );
  }

  Widget _buildContentCard({required String title, required String subtitle, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox({required String industry, required String website}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Industry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(industry, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 12),
          const Text("Website", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(website, style: const TextStyle(color: kPrimaryBlue, fontSize: 13, decoration: TextDecoration.underline)),
        ],
      ),
    );
  }
}