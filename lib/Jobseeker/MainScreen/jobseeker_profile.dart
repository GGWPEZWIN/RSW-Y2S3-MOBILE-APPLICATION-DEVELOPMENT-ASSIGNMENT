import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
// If you have a state manager for themes/language:
import '../../services/app_state_manager.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  const ProfilePage({Key? key, this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color kPrimaryBlue = Color(0xFF2563EB);
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

  // --- AUTOMATIC UPDATE LOGIC (FOR SKILLS & LANGUAGES) ---
  Future<void> _autoUpdateProfile(List<String> newSkills, List<String> newLanguages) async {
    if (newSkills.isEmpty && newLanguages.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.user?.uid);
      Map<String, dynamic> updates = {};
      if (newSkills.isNotEmpty) updates['skills'] = FieldValue.arrayUnion(newSkills);
      if (newLanguages.isNotEmpty) updates['languages'] = FieldValue.arrayUnion(newLanguages);
      await docRef.update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI updated your skills & languages!"), backgroundColor: Color(0xFF0BA87E), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      debugPrint("Auto update failed: $e");
    }
  }

  // --- AI SAVE LOGIC ---
  Future<void> _addItemFromAI(Map<String, dynamic> item, String collectionPath) async {
    try {
      Map<String, dynamic> data = {'timestamp': FieldValue.serverTimestamp()};
      if (collectionPath == 'education_history') {
        data['course'] = item['title'] ?? "Course Name";
        data['institution'] = item['subtitle'] ?? "Not Specified";
        data['year'] = (item['details'] != null) ? item['details'] : "-";
      } else {
        data['role'] = item['title'] ?? "Job Role";
        data['company'] = item['subtitle'] ?? "Not Specified";
        data['duration'] = (item['details'] != null) ? item['details'] : "-";
        data['description'] = item['details'] ?? "Added via AI analysis";
      }
      await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).collection(collectionPath).add(data);
      if (mounted) {
        setState(() => _aiSuggestions.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item['title']} added!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("AI Add error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage())),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final List<dynamic> currentSkills = userData?['skills'] ?? [];
              final List<dynamic> currentLanguages = userData?['languages'] ?? [];
              final String photoUrl = userData?['photoUrl'] ?? widget.user?.photoURL ?? "";
              final String? resumeUrl = userData?['resumeUrl'];
              final String resumeName = userData?['resumeFileName'] ?? "Resume.png";

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
                    ..._aiSuggestions.where((i) => i['category'].toString().toLowerCase().contains('edu')).map((item) => _buildAICard(item, 'education_history')).toList(),

                    const SizedBox(height: 24),

                    // 2. EXPERIENCE
                    _buildSectionHeader("Working Experience", onAction: "Add", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditExperiencePage(user: widget.user!)));
                    }),
                    _buildDynamicList(context, 'experience_history', Icons.work_outline, (data, id) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditExperiencePage(user: widget.user!, experienceData: data, docId: id)));
                    }),
                    ..._aiSuggestions.where((i) => i['category'].toString().toLowerCase().contains('exp')).map((item) => _buildAICard(item, 'experience_history')).toList(),

                    const SizedBox(height: 24),

                    // 3. SKILLS
                    _buildSectionHeader("Skills", onAction: "Edit", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: widget.user!, currentSkills: currentSkills, currentLanguages: currentLanguages)));
                    }),
                    Wrap(spacing: 8, runSpacing: 4, children: currentSkills.map((s) => _buildChip(s.toString())).toList()),

                    const SizedBox(height: 24),

                    // 4. LANGUAGES
                    _buildSectionHeader("Languages", onAction: "Edit", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: widget.user!, currentSkills: currentSkills, currentLanguages: currentLanguages)));
                    }),
                    Wrap(spacing: 8, runSpacing: 4, children: currentLanguages.map((l) => _buildChip(l.toString(), isLanguage: true)).toList()),

                    const SizedBox(height: 24),

                    // 5. RESUME
                    _buildSectionHeader("Resume", onAction: "Upload", onTap: () async {
                      final results = await ResumeService().uploadResume(context, (isLoading) => setState(() => _isAnalyzing = isLoading));
                      if (results.isNotEmpty) {
                        List<Map<String, dynamic>> manualList = [];
                        List<String> autoSkills = [], autoLangs = [];
                        for (var item in results) {
                          String cat = item['category'].toString().toLowerCase();
                          String title = item['title'].toString().trim();
                          if (cat.contains('skill')) autoSkills.add(title);
                          else if (cat.contains('lang')) autoLangs.add(title);
                          else manualList.add(item);
                        }
                        await _autoUpdateProfile(autoSkills, autoLangs);
                        setState(() => _aiSuggestions = manualList);
                      }
                    }),
                    if (resumeUrl != null)
                      _buildContentCard(context, title: resumeName, subtitle: "AI Processed Resume", icon: Icons.description_outlined, onDelete: () async {
                        await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({'resumeUrl': FieldValue.delete()});
                      })
                    else
                      const Text("No resume uploaded.", style: TextStyle(color: kTextSecondary, fontSize: 13)),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          if (_isAnalyzing) _buildLoadingOverlay(),
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [CircularProgressIndicator(), SizedBox(height: 16), Text("AI Scanning Resume...")],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? userData, String photoUrl) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfilePage(user: widget.user!))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            CircleAvatar(radius: 40, backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null, child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40) : null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userData?['name'] ?? widget.user?.displayName ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Row(children: [Icon(icon, size: 14, color: kPrimaryBlue), const SizedBox(width: 8), Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 12))]);
  }

  Widget _buildAICard(Map<String, dynamic> item, String path) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimaryBlue)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI SUGGESTION", style: TextStyle(color: kPrimaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(item['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => setState(() => _aiSuggestions.remove(item)), child: const Text("Cancel")),
              ElevatedButton(onPressed: () => _addItemFromAI(item, path), child: const Text("Add")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDynamicList(BuildContext context, String path, IconData icon, Function(Map<String, dynamic>, String) onEdit) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).collection(path).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No records.", style: TextStyle(color: kTextSecondary, fontSize: 12));
        return Column(children: snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _buildContentCard(context, title: data['course'] ?? data['role'] ?? "No Title", subtitle: data['institution'] ?? data['company'] ?? "", icon: icon, onEdit: () => onEdit(data, doc.id), onDelete: () => _deleteEntry(path, doc.id));
        }).toList());
      },
    );
  }

  Widget _buildSectionHeader(String title, {String? onAction, VoidCallback? onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), if (onAction != null) TextButton(onPressed: onTap, child: Text(onAction))]);
  }

  Widget _buildContentCard(BuildContext context, {required String title, required String subtitle, required IconData icon, VoidCallback? onEdit, required VoidCallback onDelete}) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
      onTap: onEdit,
    );
  }

  Widget _buildChip(String label, {bool isLanguage = false}) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 12)), backgroundColor: isLanguage ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9));
  }
}