import 'package:flutter/material.dart';
import 'package:assignment/Jobseeker/models/applicant_model.dart';
import 'package:assignment/Jobseeker/JobApplication/ApplicationServices//applicant_service.dart';
import '../Widgets/resume_upload_widget.dart';

class JobApplicationScreen extends StatefulWidget {
  const JobApplicationScreen({super.key});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {

  //=====================================================================================
  // TEXT CONTROLLERS
  //=====================================================================================

  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _coverLetterController = TextEditingController();

  //=====================================================================================
  // CONSTANTS
  //=====================================================================================

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

  // Job details (swap these out for route arguments in a real app)
  static const String _jobTitle = 'Senior Product Designer';
  static const String _company  = 'TechFlow Inc.';

  //=====================================================================================
  // STATE
  //=====================================================================================

  String _resumePath     = '';
  String _resumeFileName = '';
  bool   _isSubmitting   = false;

  // Pre-populated from user profile — user cannot edit these in this screen
  final List<String> _skills = ['UI Design', 'Prototyping', 'Figma', 'React'];

  //=====================================================================================
  // LIFECYCLE
  //=====================================================================================

  @override
  void dispose() {
    _portfolioController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  //=====================================================================================
  // HELPERS — build Applicant from current UI state
  //=====================================================================================

  Applicant _buildApplicant() {
    return ApplicantService.buildApplicant(
      resumePath:   _resumePath,
      portfolioUrl: _portfolioController.text,
      coverLetter:  _coverLetterController.text,
      skills:       _skills,
      jobTitle:     _jobTitle,
      company:      _company,
    );
  }

  //=====================================================================================
  // HANDLERS
  //=====================================================================================

  Future<void> _handleSubmit() async {
    final applicant = _buildApplicant();

    // validate() checks: resume, coverLetter, skills all non-empty
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

    // submitApplicant prints every field to the console on success
    final success = await ApplicantService.submitApplicant(applicant);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application submitted successfully!'
              : 'Submission failed. Please try again.',
        ),
        backgroundColor: success ? const Color(0xFF0BA87E) : Colors.redAccent,
      ),
    );
  }

  void _handleAiDraft() {
    final applicant = _buildApplicant();
    // generateAiDraft uses jobTitle, company, and skills from the applicant
    _coverLetterController.text = ApplicantService.generateAiDraft(applicant);
  }

  //=====================================================================================
  // BUILD
  //=====================================================================================

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
                      initialFileName: null, // no pre-filled file
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
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  //=====================================================================================
  // WIDGET BUILDERS
  //=====================================================================================

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
            offset: Offset(0, 4),
          ),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _jobTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '$_company • San Francisco, CA',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                ),
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
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
            letterSpacing: -0.1,
          ),
        ),
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
              hintStyle: TextStyle(fontSize: 14, color: kTextPlaceholder),
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
          Text(
            'AI VERIFIED',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: kAiGreen,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
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
      onTap: _handleAiDraft,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: kAiPurple),
          SizedBox(width: 4),
          Text(
            'AI DRAFT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kAiPurple,
              letterSpacing: 0.3,
            ),
          ),
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
                'Your profile details will be shared with $_company.',
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
            color: Colors.white,
            strokeWidth: 2.5,
          ),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', isActive: true),
          _buildNavItem(Icons.bookmark_border_rounded, 'Saved'),
          _buildNavItem(Icons.work_outline_rounded, 'Applied'),
          _buildNavItem(Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label,
      {bool isActive = false}) {
    final color = isActive ? kBlue : kTextSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}
