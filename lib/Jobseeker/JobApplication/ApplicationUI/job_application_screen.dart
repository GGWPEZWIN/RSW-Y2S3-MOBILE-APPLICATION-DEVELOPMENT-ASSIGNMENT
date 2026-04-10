import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';              // ← NEW
import 'package:assignment/Jobseeker/models/applicant_model.dart';
import 'package:assignment/Jobseeker/JobApplication/ApplicationServices/applicant_service.dart';
import '../../../Employer/models/job_model.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../../Widgets/resume_upload_widget.dart';
import '../ApplicationServices/applicant_service.dart';
import '../../Widgets/nav_bar_widget.dart';

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
  final TextEditingController _portfolioController  = TextEditingController();
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
  int    _currentIndex   = 2;

  // TODO: Replace with actual user skills from profile
  final List<String> _skills = ['UI Design', 'Prototyping', 'Figma', 'React'];

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

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final applicant = _buildApplicant();

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

    final success = await ApplicantService.submitApplicant(applicant);

    // ── After successful save, notify the employer ─────────────────────────
    if (success) {
      await _notifyEmployer(applicant);
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
      // Pass true back so JobDetailsPage updates the Apply button immediately
      Navigator.pop(context, true);
    }
  }

  // ── Employer notification write ───────────────────────────────────────────
  /// Called only after ApplicantService.submitApplicant() returns true.
  /// Writes one doc to employer_notifications so the employer sees the
  /// new application in their notification inbox immediately.
  Future<void> _notifyEmployer(Applicant applicant) async {
    try {
      final db        = FirebaseFirestore.instance;
      final jobseeker = FirebaseAuth.instance.currentUser;
      final seekerName = jobseeker?.displayName
          ?? jobseeker?.email
          ?? 'A candidate';

      // Resolve employer uid ─────────────────────────────────────────────────
      // 1st choice: companyId passed directly to this screen
      // 2nd choice: look up jobs/{jobId}.companyId or .createdBy
      String employerId = widget.companyId ?? '';

      if (employerId.isEmpty) {
        final jobDoc =
        await db.collection('jobs').doc(widget.jobId).get();
        employerId =
            (jobDoc.data()?['companyId'] as String?) ??
                (jobDoc.data()?['createdBy'] as String?) ??
                '';
      }

      if (employerId.isEmpty) {
        debugPrint('_notifyEmployer: could not resolve employerId, skipping.');
        return;
      }

      // Write notification doc ───────────────────────────────────────────────
      await db.collection('employer_notifications').add({
        'employerId':      employerId,
        'applicationId':   applicant.id,   // set by ApplicantService
        'jobId':           widget.jobId,
        'candidateUserId': jobseeker?.uid ?? '',
        // Pre-rendered display strings (no joins needed in the inbox)
        'candidateName':   seekerName,
        'jobTitle':        widget.jobTitle,
        'title':  '📋 New Application — ${widget.jobTitle}',
        'body':   '$seekerName has applied for ${widget.jobTitle}.',
        'type':   'new_application',
        'status': 'unprocessed',
        'appliedAt': FieldValue.serverTimestamp(),  // matches applications.appliedAt
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Employer notified: $employerId');
    } catch (e) {
      // Non-fatal — the application was already saved successfully
      debugPrint('_notifyEmployer error: $e');
    }
  }

  void _handleAiDraft() {
    final applicant = _buildApplicant();
    _coverLetterController.text = ApplicantService.generateAiDraft(applicant);
  }

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
            NavBarWidget(
              currentIndex: _currentIndex,
              onTabSelected: (index) {
                if (index == _currentIndex) return;
                setState(() => _currentIndex = index);
                if (index == 0) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else if (index == 1) {
                  // TODO: Navigate to Saved Jobs screen
                } else if (index == 3) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(
                          user: FirebaseAuth.instance.currentUser),
                    ),
                  );
                }
              },
            ),
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
                width: 36,
                height: 36,
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
              letterSpacing: -0.3,
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
          BoxShadow(
              color: Color(0x0A0F1624),
              blurRadius: 16,
              offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.photo_size_select_actual_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.jobTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.company,
                style: const TextStyle(
                    fontSize: 13, color: kTextSecondary),
              ),
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
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
              letterSpacing: -0.1,
            )),
        if (trailing != null) trailing,
      ],
    );
  }

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
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            controller: _portfolioController,
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
            decoration: const InputDecoration(
              hintText: 'https://portfolio.com',
              hintStyle:
              TextStyle(fontSize: 14, color: kTextPlaceholder),
              prefixIcon: Icon(Icons.link_rounded,
                  color: kTextPlaceholder, size: 20),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Profile Skills',
            trailing: _buildAiVerifiedBadge()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: kAiGreen),
          SizedBox(width: 4),
          Text('AI VERIFIED',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: kAiGreen,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
          color: kBlue, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white)),
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
              hintText:
              'Explain why you are a good fit for this role...',
              hintStyle:
              TextStyle(fontSize: 13.5, color: kTextPlaceholder),
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
      onTap: _handleAiDraft,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: kAiPurple),
          SizedBox(width: 4),
          Text('AI DRAFT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kAiPurple,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildDisclaimerText() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 14, color: kTextSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Applications are usually reviewed within 48 hours. '
                'Your profile details will be shared with ${widget.company}.',
            style: TextStyle(
              fontSize: 12,
              color: kTextSecondary.withOpacity(0.85),
              height: 1.5,
            ),
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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : const Text(
          'Submit Application',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}