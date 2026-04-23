import 'dart:convert'; // Required for base64Decode
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
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
    // 1. Initialize l10n
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    // 2. Safety check
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // Translated 'Profile'
        title: Text(l10n.profileTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          if (snapshot.hasError) return Center(child: Text(l10n.errorLoadingProfile));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final employerData = snapshot.data?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HEADER ---
                GestureDetector(
                  onTap: () {
                    if (user != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditBasicProfilePage(
                        user: user,
                        currentName: employerData?['companyName'] ?? '',
                        currentPhone: employerData?['phone'] ?? '',
                        currentLocation: employerData?['location'] ?? '',
                      )));
                    }
                  },
                  child: _buildHeader(employerData, user),
                ),

                const SizedBox(height: 24),
                // Translated 'Employer Settings'
                Text(l10n.employerSettings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(thickness: 1, height: 24),

                // --- 2. COMPANY BACKGROUND ---
                _buildSectionHeader(l10n.companyBackground, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EditBackgroundPage(
                    currentBackground: employerData?['background'] ?? "",
                  )));
                }),
                _buildContentCard(
                  title: l10n.backgroundLabel,
                  subtitle: employerData?['background'] ?? l10n.noBackgroundSet,
                  icon: Icons.business_outlined,
                ),

                const SizedBox(height: 24),

                // --- 3. COMPANY INFORMATION ---
                _buildSectionHeader(l10n.companyInfo, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EditCompanyInfo(
                    currentIndustry: employerData?['industry'] ?? "",
                    currentWebsite: employerData?['website'] ?? "",
                  )));
                }),
                _buildDetailBox(
                  industry: employerData?['industry'] ?? l10n.notSpecified,
                  website: employerData?['website'] ?? l10n.noWebsiteAdded,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(Map<String, dynamic>? data, User? user) {

    // Determine the Logo Provider (Base64 vs Network)
    ImageProvider? imageProvider;
    final String? photoUrl = data?['photoUrl'];

    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        imageProvider = NetworkImage(photoUrl);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(photoUrl));
        } catch (e) {
          debugPrint("Error decoding employer logo: $e");
          imageProvider = null;
        }
      }
    }


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
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(Icons.business, size: 40, color: kPrimaryBlue)
            : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    data?['companyName'] ?? 'Company Name',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Safe for long names
                    maxLines: 1,
                  ),

                const SizedBox(height: 6),
                _buildHeaderRow(Icons.email_outlined, data?['email'] ?? user?.email ?? ''),
                _buildHeaderRow(Icons.phone_outlined, data?['phone'] ?? 'Add phone'),
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
          // --- FIXED OVERFLOW ---
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
        border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Industry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(industry, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 12),
          const Text("Website", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(
            website,
            style: const TextStyle(color: kPrimaryBlue, fontSize: 13, decoration: TextDecoration.underline),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}