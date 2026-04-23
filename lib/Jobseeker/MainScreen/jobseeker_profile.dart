import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../edit_profile.dart';
import '../../l10n/app_localizations.dart';
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
  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kTextSecondary = Color(0xFF64748B);

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

  // --- VIEW RESUME LOGIC ---
  void _viewResume(String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text("Resume View", style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(base64String),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text("Could not display resume image", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- AUTOMATIC UPDATE LOGIC (FOR SKILLS/LANGS) ---
  Future<void> _autoUpdateProfile(List<String> newSkills, List<String> newLanguages) async {
    if (newSkills.isEmpty && newLanguages.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(widget.user?.uid);
      Map<String, dynamic> updates = {};
      if (newSkills.isNotEmpty) updates['skills'] = FieldValue.arrayUnion(newSkills);
      if (newLanguages.isNotEmpty) updates['languages'] = FieldValue.arrayUnion(newLanguages);
      await docRef.update(updates);
    } catch (e) {
      debugPrint("Auto update failed: $e");
    }
  }

  // --- SAVE SUGGESTIONS TO FIRESTORE ---
  Future<void> _saveSuggestionsToFirestore(List<Map<String, dynamic>> suggestions) async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user?.uid)
        .collection('ai_suggestions');

    for (var item in suggestions) {
      final docRef = collection.doc();
      batch.set(docRef, {
        ...item,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // --- AI SAVE LOGIC ---
  Future<void> _addItemFromAI(Map<String, dynamic> item, String suggestionId, String targetPath) async {
    try {
      Map<String, dynamic> data = {'timestamp': FieldValue.serverTimestamp()};
      if (targetPath == 'education_history') {
        data['course'] = item['title'] ?? "Course Name";
        data['institution'] = item['subtitle'] ?? "Not Specified";
        data['year'] = item['details'] ?? "-";
      } else {
        data['role'] = item['title'] ?? "Job Role";
        data['company'] = item['subtitle'] ?? "Not Specified";
        data['duration'] = item['details'] ?? "-";
        data['description'] = item['details'] ?? "Added via AI analysis";
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).collection(targetPath).add(data);
      await _deleteEntry('ai_suggestions', suggestionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("AI Add error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;

    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Text(l10n.profileTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final List<dynamic> currentSkills = userData?['skills'] ?? [];
              final List<dynamic> currentLanguages = userData?['languages'] ?? [];
              final String? photoData = userData?['photoUrl'];
              final String? resumeUrl = userData?['resumeUrl'];
              final String resumeName = userData?['resumeFileName'] ?? l10n.myResume;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(userData, photoData),
                    const SizedBox(height: 24),
                    Text(l10n.improveMatches, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(thickness: 1, height: 24),

                    // 1. EDUCATION
                    _buildSectionHeader(l10n.educationLabel, onAction: l10n.actionAdd, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditEducationPage(user: user!)));
                    }),
                    _buildDynamicList(context, 'education_history', Icons.school_outlined, (data, id) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditEducationPage(user: user!, educationData: data, docId: id)));
                    }),
                    _buildAISuggestionList('education'),

                    const SizedBox(height: 24),

                    // 2. EXPERIENCE
                    _buildSectionHeader(l10n.workingExperience, onAction: l10n.actionAdd, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditExperiencePage(user: user!)));
                    }),
                    _buildDynamicList(context, 'experience_history', Icons.work_outline, (data, id) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditExperiencePage(user: user!, experienceData: data, docId: id)));
                    }),
                    _buildAISuggestionList('experience'),

                    const SizedBox(height: 24),

                    // 3. SKILLS & LANGUAGES
                    _buildSectionHeader(l10n.skillsLabel, onAction: l10n.actionEdit, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: user!, currentSkills: currentSkills, currentLanguages: currentLanguages)));
                    }),
                    Wrap(spacing: 8, runSpacing: 4, children: currentSkills.map((s) => _buildChip(s.toString())).toList()),
                    const SizedBox(height: 16),
                    _buildSectionHeader(l10n.languagesLabel, onAction: l10n.actionEdit, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => EditSkillsPage(user: user!, currentSkills: currentSkills, currentLanguages: currentLanguages)));
                    }),
                    Wrap(spacing: 8, runSpacing: 4, children: currentLanguages.map((l) => _buildChip(l.toString(), isLanguage: true)).toList()),

                    const SizedBox(height: 24),

                    // 5. RESUME (MODIFIED LOGIC BELOW)
                    _buildSectionHeader(l10n.resumeLabel, onAction: l10n.actionUpload, onTap: () async {
                      // 1. Trigger the upload and AI Scan
                      final results = await ResumeService().uploadResume(
                          context,
                              (isLoading) => setState(() => _isAnalyzing = isLoading)
                      );

                      // 2. If results found (your 12 items), save them to Firestore
                      if (results != null && results.isNotEmpty) {
                        // Separate Skills/Languages for auto-update and Education/Experience for suggestions
                        List<String> aiSkills = [];
                        List<String> aiLangs = [];
                        List<Map<String, dynamic>> aiHistories = [];

                        for (var item in results) {
                          String cat = item['category'].toString();
                          if (cat == 'Skill') aiSkills.add(item['title']);
                          else if (cat == 'Language') aiLangs.add(item['title']);
                          else aiHistories.add(item);
                        }

                        // Save suggestions (Cards)
                        if (aiHistories.isNotEmpty) {
                          await _saveSuggestionsToFirestore(aiHistories);
                        }

                        // Auto update simple chips
                        await _autoUpdateProfile(aiSkills, aiLangs);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Scan complete! Found ${results.length} items."), backgroundColor: Colors.green)
                          );
                        }
                      }
                    }),
                    if (resumeUrl != null && resumeUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _viewResume(resumeUrl),
                        child: _buildContentCard(
                            context,
                            title: resumeName,
                            subtitle: l10n.tapToViewResume,
                            icon: Icons.description_outlined,
                            onDelete: () async {
                              await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({'resumeUrl': FieldValue.delete()});
                            }
                        ),
                      )
                    else
                      Text(l10n.noResumeUploaded, style: const TextStyle(color: Colors.grey, fontSize: 13)),

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

  // --- STREAM BUILDER FOR AI SUGGESTIONS ---
  Widget _buildAISuggestionList(String categoryFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user?.uid)
          .collection('ai_suggestions')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final cat = (doc.data() as Map<String, dynamic>)['category'].toString().toLowerCase();
          return cat.contains(categoryFilter);
        }).toList();

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final targetPath = categoryFilter == 'education' ? 'education_history' : 'experience_history';
            return _buildAICard(data, doc.id, targetPath);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAICard(Map<String, dynamic> item, String docId, String targetPath) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimaryBlue)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI SUGGESTION", style: TextStyle(color: kPrimaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(item['title'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(item['subtitle'] ?? "", style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => _deleteEntry('ai_suggestions', docId), child: const Text("Cancel")),
              ElevatedButton(onPressed: () => _addItemFromAI(item, docId, targetPath), child: const Text("Add")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? userData, String? photoData) {
    ImageProvider? imageProvider;
    if (photoData != null && photoData.isNotEmpty) {
      if (photoData.startsWith('http')) imageProvider = NetworkImage(photoData);
      else {
        try { imageProvider = MemoryImage(base64Decode(photoData)); } catch (e) { imageProvider = null; }
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfilePage(user: widget.user!))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            CircleAvatar(radius: 40, backgroundColor: const Color(0xFFF1F5F9), backgroundImage: imageProvider, child: imageProvider == null ? const Icon(Icons.person, size: 40, color: kPrimaryBlue) : null),
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
    return Row(children: [Icon(icon, size: 14, color: kPrimaryBlue), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1))]);
  }

  Widget _buildDynamicList(BuildContext context, String path, IconData icon, Function(Map<String, dynamic>, String) onEdit) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).collection(path).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(l10n.noRecords, style: const TextStyle(color: kTextSecondary, fontSize: 12)));
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
    return ListTile(leading: Icon(icon, color: kPrimaryBlue), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: onDelete), onTap: onEdit);
  }

  Widget _buildChip(String label, {bool isLanguage = false}) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 12)), backgroundColor: isLanguage ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9));
  }

  Widget _buildLoadingOverlay() {
    return Container(color: Colors.black45, child: Center(child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: const [CircularProgressIndicator(), SizedBox(height: 16), Text("AI Scanning Resume...")])))));
  }
}