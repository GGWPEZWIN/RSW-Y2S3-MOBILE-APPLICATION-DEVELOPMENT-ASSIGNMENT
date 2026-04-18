import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment/Jobseeker/models/applicant_model.dart';
import 'package:assignment/Jobseeker/JobApplication/ApplicationServices/applicant_service.dart';
import '../../../Employer/models/job_model.dart';
import '../../Widgets/resume_upload_widget.dart';
import '../../../services/fcm_service.dart';

class JobApplicationScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String company;
  final String? companyId;
  final Job? job;

  const JobApplicationScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    this.companyId,
    this.job,
  });

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final TextEditingController _portfolioController   = TextEditingController();
  final TextEditingController _coverLetterController = TextEditingController();

  static const Color kBlue            = Color(0xFF2F6FED);
  static const Color kBlueDark        = Color(0xFF1A57D4);
  static const Color kBlueLight       = Color(0xFFEEF3FD);
  static const Color kTextPrimary     = Color(0xFF0F1624);
  static const Color kTextSecondary   = Color(0xFF6B7280);
  static const Color kTextPlaceholder = Color(0xFFADBAC7);
  static const Color kBorder          = Color(0xFFE4E9F0);
  static const Color kBg              = Color(0xFFF5F7FA);
  static const Color kAiGreen         = Color(0xFF0BA87E);
  static const Color kAiPurple        = Color(0xFF7C3AED);

  String _resumePath     = '';
  String _resumeFileName = '';
  bool   _isSubmitting   = false;
  bool   _isDrafting     = false;
  //int    _currentIndex   = 2;
  String? _portfolioError;

  // TODO: Replace with actual user skills from profile
  final List<String> _skills = [];
  bool _isExtractingSkills = false;

  @override
  void dispose() {
    _portfolioController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Applicant _buildApplicant() {
    return ApplicantService.buildApplicant(
      resumePath:      _resumePath,
      portfolioUrl:    _portfolioController.text,
      coverLetter:     _coverLetterController.text,
      skills:          _skills,
      jobTitle:        widget.jobTitle,
      company:         widget.company,
      jobId:           widget.jobId,
      companyId:       widget.companyId,
      salary:          widget.job?.salary         ?? '',
      workType:        widget.job?.workType        ?? '',
      workplace:       widget.job?.workplace       ?? '',
      education:       widget.job?.educationLevel  ?? '',
      experienceLevel: widget.job?.experienceLevel ?? '',
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final applicant = _buildApplicant();
    final url = _portfolioController.text.trim();

    if (url.isNotEmpty && !Uri.tryParse(url)!.hasAbsolutePath) {
      setState(() => _portfolioError = 'Please enter a valid URL');
      return;
    }

    if (!applicant.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload a resume, write a cover letter, '
                'and select at least one skill.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // submitApplicant now returns the real Firestore doc ID, or null on failure
    final docId = await ApplicantService.submitApplicant(applicant);
    final success = docId != null;

    if (success) {
      // Notify employer with the real Firestore applicationId
      await _notifyEmployer(docId!);
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application submitted successfully!'
              : 'Submission failed. Please try again.',
        ),
        backgroundColor:
        success ? const Color(0xFF0BA87E) : Colors.redAccent,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _processResume(String path) async {
    setState(() => _isExtractingSkills = true);
    try {
      // We only need this ONE call now. It does OCR and Skill picking in one go.
      final extractedSkills = await ApplicantService.extractSkillsWithAi(path);

      setState(() {
        _skills.clear();
        _skills.addAll(extractedSkills);
      });
    } catch (e) {
      debugPrint("Skill extraction failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not extract skills from resume.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExtractingSkills = false);
      }
    }
  }

  // AI cover letter draft
  Future<void> _handleAiDraft() async {
    if (_isDrafting) return;

    setState(() => _isDrafting = true);

    try {
      final applicant = _buildApplicant();
      final draft = await ApplicantService.generateAiDraft(applicant);

      // CRITICAL: Check if the user is still on this screen
      if (!mounted) return;

      setState(() {
        _coverLetterController.text = draft;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate draft: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isDrafting = false);
      }
    }
  }

  // ── Employer notification ──────────────────────────────────────────────────

  Future<void> _notifyEmployer(String applicationDocId) async {
    try {
      final db        = FirebaseFirestore.instance;
      final jobseeker = FirebaseAuth.instance.currentUser;
      final seekerName = jobseeker?.displayName?.isNotEmpty == true
          ? jobseeker!.displayName!
          : jobseeker?.email ?? 'A candidate';

      // Resolve employer uid ─────────────────────────────────────────────────
      // Priority 1: companyId already passed to this screen from job listing
      // Priority 2: read from jobs/{jobId} in Firestore
      String employerId = widget.companyId ?? '';

      if (employerId.isEmpty) {
        final jobDoc = await db.collection('jobs').doc(widget.jobId).get();
        employerId =
        (jobDoc.data()?['companyId'] as String?)?.isNotEmpty == true
            ? jobDoc.data()!['companyId'] as String
            : (jobDoc.data()?['createdBy'] as String?) ?? '';
      }

      if (employerId.isEmpty) {
        debugPrint('_notifyEmployer: employerId not found, skipping.');
        return;
      }

      final title = '📋 New Application — ${widget.jobTitle}';
      final body  = '$seekerName has applied for ${widget.jobTitle}.';

      // 1. In-app notification
      await db.collection('employer_notifications').add({
        'employerId':      employerId,
        'applicationId':   applicationDocId,   // real Firestore doc ID
        'jobId':           widget.jobId,
        'candidateUserId': jobseeker?.uid ?? '',
        'candidateName':   seekerName,
        'jobTitle':        widget.jobTitle,
        'title':           title,
        'body':            body,
        'type':            'new_application',
        'status':          'unprocessed',
        'appliedAt':       FieldValue.serverTimestamp(),
        'isRead':          false,
        'createdAt':       FieldValue.serverTimestamp(),
      });

      // 2. Push Notification
      await FCMService().sendPushNotification(
        recipientId: employerId,
        title:       title,
        body:        body,
        data: {
          'type':          'new_application',
          'applicationId': applicationDocId,
          'jobId':         widget.jobId,
        },
      );

      debugPrint('Employer notification sent to: $employerId');
    } catch (e) {
      // Non-fatal — the application is already saved
      debugPrint('_notifyEmployer error: $e');
    }
  }

  //void _handleAiDraft() {
  //  final applicant = _buildApplicant();
  //  _coverLetterController.text = ApplicantService.generateAiDraft(applicant);
  //}

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobCard(),
                    const SizedBox(height: 20),
                    ResumeUploadWidget(
                      initialFileName: null,
                      onFileSelected: (path, name) {
                        setState(() {
                          _resumePath     = path;
                          _resumeFileName = name;
                        });
                        _processResume(path);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPortfolioSection(),
                    const SizedBox(height: 20),
                    _buildSkillsSection(),
                    const SizedBox(height: 20),
                    _buildCoverLetterSection(),
                    const SizedBox(height: 20),
                    _buildDisclaimerText(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
            //NavBarWidget(
            //  currentIndex: _currentIndex,
            //  onTabSelected: (index) {
            //    if (index == _currentIndex) return;
            //    setState(() => _currentIndex = index);
            //    if (index == 0) {
            //      Navigator.of(context).popUntil((route) => route.isFirst);
            //    } else if (index == 1) {
            //      // TODO: Navigate to Saved Jobs screen
            //    } else if (index == 3) {
            //      Navigator.pushReplacement(
            //        context,
            //        MaterialPageRoute(
            //          builder: (_) => ProfilePage(
            //              user: FirebaseAuth.instance.currentUser),
            //        ),
            //      );
            //    }
            //  },
            //),
          ],
        ),
      ),
    );
  }

  // ── Widget builders — all unchanged from your original ────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorder, width: 1.5),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: kTextPrimary, size: 22),
              ),
            ),
          ),
          const Text(
            'Job Application',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: kTextPrimary, letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F1624), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: kBlue, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.photo_size_select_actual_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.jobTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: kTextPrimary, letterSpacing: -0.2)),
              const SizedBox(height: 3),
              Text(widget.company,
                  style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700,
                color: kTextPrimary, letterSpacing: -0.1)),
        if (trailing != null) trailing,
      ],
    );
  }

  //Widget _buildPortfolioSection() {
  //  return Column(
  //    crossAxisAlignment: CrossAxisAlignment.start,
  //    children: [
  //      _buildSectionLabel('Portfolio URL'),
  //      const SizedBox(height: 8),
  //      Container(
  //        decoration: BoxDecoration(
  //          color: Colors.white,
  //          borderRadius: BorderRadius.circular(12),
  //          border: Border.all(color: kBorder),
  //        ),
  //        child: TextField(
  //          controller: _portfolioController,
  //          style: const TextStyle(fontSize: 14, color: kTextPrimary),
  //          decoration: const InputDecoration(
  //            hintText: 'https://portfolio.com',
  //            hintStyle: TextStyle(fontSize: 14, color: kTextPlaceholder),
  //            prefixIcon: Icon(Icons.link_rounded, color: kTextPlaceholder, size: 20),
  //            border: InputBorder.none,
  //            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  //          ),
  //        ),
  //      ),
  //    ],
  //  );
  //}

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Portfolio URL'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Toggle border color based on error state
            border: Border.all(
              color: _portfolioError == null ? kBorder : Colors.redAccent,
              width: _portfolioError == null ? 1 : 1.5,
            ),
          ),
          child: TextField(
            controller: _portfolioController,
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
            onChanged: (value) {
              // Clear error the moment the user starts typing
              if (_portfolioError != null) {
                setState(() => _portfolioError = null);
              }
            },
            decoration: const InputDecoration(
              hintText: 'https://portfolio.com',
              hintStyle: TextStyle(fontSize: 14, color: kTextPlaceholder),
              prefixIcon: Icon(Icons.link_rounded, color: kTextPlaceholder, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        // Display the error message text
        if (_portfolioError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _portfolioError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Profile Skills', trailing: _buildAiVerifiedBadge()),
        const SizedBox(height: 10),

        // ADD THIS LOADING CHECK:
        if (_isExtractingSkills)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: kAiGreen),
            ),
          )
        else if (_skills.isEmpty)
          const Text(
            "No skills extracted. Try uploading a different resume image.",
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          )
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _skills.map((s) => _buildSkillChip(s)).toList(),
          ),
      ],
    );
  }

  Widget _buildAiVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_awesome_rounded, size: 12, color: kAiGreen),
        SizedBox(width: 4),
        Text('AI VERIFIED',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                color: kAiGreen, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration:
      BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
    );
  }

  Widget _buildCoverLetterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Cover Letter', trailing: _buildAiDraftBadge()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            controller: _coverLetterController,
            maxLines: 6,
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
            decoration: const InputDecoration(
              hintText: 'Explain why you are a good fit for this role...',
              hintStyle: TextStyle(fontSize: 13.5, color: kTextPlaceholder),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDraftBadge() {
    return GestureDetector(
      onTap: _isDrafting ? null : _handleAiDraft,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_isDrafting)
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: kAiPurple),
          )
        else
          const Icon(Icons.auto_awesome_rounded, size: 14, color: kAiPurple),
        const SizedBox(width: 4),
        Text(_isDrafting ? 'GENERATING...' : 'AI DRAFT',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: kAiPurple, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildDisclaimerText() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: kTextSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Applications are usually reviewed within 48 hours. '
                'Your profile details will be shared with ${widget.company}.',
            style: TextStyle(fontSize: 12,
                color: kTextSecondary.withOpacity(0.85), height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kBlue.withOpacity(0.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : const Text('Submit Application',
            style: TextStyle(fontSize: 15.5,
                fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      ),
    );
  }
}