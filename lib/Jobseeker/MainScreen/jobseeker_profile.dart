import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../edit_profile.dart';
import '../../services/resume_service.dart';
import '../../settings_page.dart';
import '../JobApplication/ApplicationUI/applied_job_list.dart';
import '../JobApplication/ApplicationUI/saved_job_list.dart';
import '../Profile/edit_education_page.dart';
import '../Profile/edit_experience_page.dart';
import '../Profile/edit_skills_page.dart';
import '../Widgets/nav_bar_widget.dart';
import 'jobseeker_home.dart';


class ProfilePage extends StatefulWidget {
  final User? user;
  const ProfilePage({Key? key, this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kBackground = Colors.white;
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kBorderColor = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _isAnalyzing = false;

  // --- DELETE LOGIC ---
  Future<void> _deleteEntry(String collectionPath, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user?.uid)
          .collection(collectionPath)
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Delete failed: $e");
    }
  }

  // --- AI SAVE LOGIC ---
  Future<void> _addItemFromAI(Map<String, dynamic> item, String collectionPath) async {
    try {
      if (collectionPath == 'users') {
        await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({
          'skills': FieldValue.arrayUnion([item['title']])
        });
      } else {
        Map<String, dynamic> data = {
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (collectionPath == 'education_history') {
          data['course'] = item['title'] ?? "Course Name";
          data['institution'] = item['subtitle'] ?? "Not Specified";
          data['year'] = item['details'] ?? "";
        } else if (collectionPath == 'experience_history') {
          data['role'] = item['title'] ?? "Job Role";
          data['company'] = item['subtitle'] ?? "Not Specified";
          data['duration'] = item['details'] ?? "";
          data['description'] = "Added via AI Resume Image Analysis";
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user?.uid)
            .collection(collectionPath)
            .add(data);
      }

      if (mounted) {
        setState(() {
          _aiSuggestions.remove(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item['title']} added to profile!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("AI Add error: $e");
    }
  }

  Future<void> _viewResume(BuildContext context, String data, bool isBase64) async {
    if (data.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Resume Data"),
        content: const Text("Your resume image is stored securely as Base64 data in Firestore."),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage())),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading profile"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final String photoUrl = userData?['photoUrl'] ?? widget.user?.photoURL ?? "";
              final List<dynamic> skills = userData?['skills'] ?? [];
              final List<dynamic> languages = userData?['languages'] ?? [];
              final String? resumeUrl = userData?['resumeUrl'];
              final String resumeName = userData?['resumeFileName'] ?? "Resume_Image.png";
              final bool isBase64 = userData?['isBase64'] ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(userData, photoUrl),
                    const SizedBox(height: 24),
                    const Text("Improve your job matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(thickness: 1, height: 24),

                    // 1. EDUCATION
                    _buildSectionHeader("Education", onAction: "Add", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditEducationPage(user: widget.user!)));
                    }),
                    _buildDynamicList(context, 'education_history', Icons.school_outlined, (data, id) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditEducationPage(user: widget.user!, educationData: data, docId: id)));
                    }),
                    ..._aiSuggestions
                        .where((i) => (i['category'] ?? '').toString().toLowerCase().contains('edu'))
                        .map((item) => _buildAICard(item, 'education_history'))
                        .toList(),

                    const SizedBox(height: 24),

                    // 2. EXPERIENCE
                    _buildSectionHeader("Working Experience", onAction: "Add", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditExperiencePage(user: widget.user!)));
                    }),
                    _buildDynamicList(context, 'experience_history', Icons.work_outline, (data, id) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditExperiencePage(user: widget.user!, experienceData: data, docId: id)));
                    }),
                    ..._aiSuggestions
                        .where((i) => (i['category'] ?? '').toString().toLowerCase().contains('exp'))
                        .map((item) => _buildAICard(item, 'experience_history'))
                        .toList(),

                    const SizedBox(height: 24),

                    // 3. SKILLS
                    _buildSectionHeader("Skills", onAction: "Edit", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: widget.user!, currentSkills: skills, currentLanguages: languages)));
                    }),
                    Wrap(spacing: 8, children: skills.map((s) => _buildChip(s.toString())).toList()),
                    ..._aiSuggestions
                        .where((i) => (i['category'] ?? '').toString().toLowerCase().contains('skill'))
                        .map((item) => _buildAICard(item, 'users'))
                        .toList(),

                    const SizedBox(height: 24),

                    // 4. LANGUAGES
                    _buildSectionHeader("Languages", onAction: "Edit", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: widget.user!, currentSkills: skills, currentLanguages: languages)));
                    }),
                    Wrap(spacing: 8, children: languages.map((l) => _buildChip(l.toString(), isLanguage: true)).toList()),

                    const SizedBox(height: 24),

                    // 5. RESUME SECTION
                    _buildSectionHeader("Resume", onAction: "Upload", onTap: () async {
                      final newSuggestions = await ResumeService().uploadResume(
                          context,
                              (isLoading) => setState(() => _isAnalyzing = isLoading)
                      );

                      if (newSuggestions.isNotEmpty) {
                        setState(() {
                          _aiSuggestions = newSuggestions;
                        });
                      }
                    }),

                    if (resumeUrl != null && resumeUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _viewResume(context, resumeUrl, isBase64),
                        child: _buildContentCard(
                          context,
                          title: resumeName,
                          subtitle: "Resume processed by JobBuddy AI",
                          icon: Icons.image_outlined,
                          onDelete: () async {
                            // IMPROVED DELETE LOGIC:
                            await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({
                              'resumeUrl': FieldValue.delete(),
                              'resumeFileName': FieldValue.delete(),
                              'isBase64': FieldValue.delete(),
                              'fileType': FieldValue.delete(),
                              'resumeUploadedAt': FieldValue.delete(),
                            });
                            // Clear suggestions when resume is deleted
                            setState(() {
                              _aiSuggestions = [];
                            });
                          },
                        ),
                      )
                    else
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("No resume uploaded.", style: TextStyle(color: kTextSecondary, fontSize: 13))),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),

          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kPrimaryBlue),
                        SizedBox(height: 20),
                        Text("JobBuddy AI is scanning your resume...", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Identifying missing skills and education", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index == 3) return;
          if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(user: widget.user)));
          if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SavedJobsScreen()));
          if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppliedJobsScreen()));
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAICard(Map<String, dynamic> item, String collectionPath) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kPrimaryBlue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(6)),
            child: const Text("AI SUGGESTION", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(item['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (item['subtitle'] != null && item['subtitle'] != "")
            Text(item['subtitle'], style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => setState(() => _aiSuggestions.remove(item)),
                  child: const Text("Dismiss", style: TextStyle(color: kTextSecondary))
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addItemFromAI(item, collectionPath),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text("Add to profile", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? userData, String photoUrl) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(user: widget.user!))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            CircleAvatar(radius: 40, backgroundColor: const Color(0xFFF1F5F9), backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null, child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: kPrimaryBlue) : null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userData?['name'] ?? widget.user?.displayName ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildHeaderInfoRow(Icons.email_outlined, userData?['email'] ?? widget.user?.email ?? ''),
                  _buildHeaderInfoRow(Icons.phone_outlined, userData?['phone'] ?? 'Add phone'),
                  _buildHeaderInfoRow(Icons.location_on_outlined, userData?['location'] ?? 'Add location'),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: kPrimaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(IconData icon, String text) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(children: [Icon(icon, size: 14, color: kPrimaryBlue), const SizedBox(width: 8), Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)]));
  }

  Widget _buildDynamicList(BuildContext context, String collectionPath, IconData icon, Function(Map<String, dynamic>, String) onEdit) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).collection(collectionPath).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child: Text("No records added.", style: TextStyle(color: kTextSecondary, fontSize: 13)));
        return Column(children: snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _buildContentCard(context, title: data['course'] ?? data['role'] ?? "No Title", subtitle: data['institution'] ?? data['company'] ?? "No Institution", trailingText: data['year'] ?? data['duration'] ?? "", icon: icon, onEdit: () => onEdit(data, doc.id), onDelete: () => _deleteEntry(collectionPath, doc.id));
        }).toList());
      },
    );
  }

  Widget _buildSectionHeader(String title, {String? onAction, VoidCallback? onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), if (onAction != null) TextButton(onPressed: onTap, child: Text(onAction, style: const TextStyle(color: kPrimaryBlue)))]);
  }

  Widget _buildContentCard(BuildContext context, {required String title, required String subtitle, String? trailingText, required IconData icon, bool showMenu = true, VoidCallback? onEdit, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Row(children: [
        Icon(icon, color: kPrimaryBlue),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: kTextSecondary, fontSize: 12)), if (trailingText != null) Text(trailingText, style: const TextStyle(color: kTextSecondary, fontSize: 12))])),
        if (showMenu) PopupMenuButton<String>(onSelected: (val) { if (val == 'delete') onDelete(); if (val == 'edit' && onEdit != null) onEdit(); }, itemBuilder: (context) => [if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text("Edit")), const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red)))], icon: const Icon(Icons.more_horiz, color: kTextSecondary)),
      ]),
    );
  }

  Widget _buildChip(String label, {bool isLanguage = false}) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 12)), backgroundColor: isLanguage ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9), labelStyle: TextStyle(color: isLanguage ? kPrimaryBlue : Colors.black), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
  }
}