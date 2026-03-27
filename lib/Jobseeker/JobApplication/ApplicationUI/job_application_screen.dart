import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:assignment/Jobseeker/models/applicant_model.dart';
import 'package:assignment/Jobseeker/JobApplication/ApplicationServices//applicant_service.dart';
import 'package:flutter_svg/svg.dart';
import '../../../services/firestore_services.dart';
import '../Widgets/resume_upload_widget.dart';

class JobApplicationScreen extends StatefulWidget {

  final Applicant? applicant;

  // accept the applicant object from the job detail
  const JobApplicationScreen({super.key, this.applicant});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {

  final FirestoreService<Applicant> _firestoreService = FirestoreService<Applicant>(
    ref: FirebaseFirestore.instance.collection('applications'),
    fromMap: (id, data) => Applicant.fromMap(id, data),
    toMap: (applicant) => applicant.toMap(),
  );

  @override
  void initState() {
    super.initState();

    if (widget.applicant != null) {
      _coverLetterController.text = widget.applicant!.coverLetter;
      _portfolioController.text = widget.applicant!.portfolioUrl;

      String rawResume = widget.applicant!.resume;

      if (rawResume.contains('|')) {
        List<String> parts = rawResume.split('|');
        // We assign values to the class variables here
        _resumeFileName = parts[0];
        _resumePath = parts[1];
      } else if (rawResume.isNotEmpty) {
        _resumePath = rawResume;
        _resumeFileName = "Uploaded Resume";
      }
    }
  }

  // SVG icons
  final List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/saved.svg',
    'assets/icons/applied.svg',
    'assets/icons/profile.svg',
  ];

  final List<String> _labels = ['Home', 'Saved', 'Applied', 'Profile'];

  String? _portfolioError;
  String  _resumePath     = '';
  String  _resumeFileName = '';
  bool    _isSubmitting   = false;
  int _currentIndex = 0;

  // 2. MOVE THE FUNCTION HERE
  bool _isValidUrl(String url) {
    if (url.isEmpty) return true;
    final urlRegExp = RegExp(
      r"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$",
    );
    return urlRegExp.hasMatch(url);
  }

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


  //TODO: NEED TO IMPLEMENT CUSTOM USER ADDED
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
    final combinedResumeData = "${_resumeFileName}|${_resumePath}";

    return Applicant(
      id: widget.applicant?.id ?? '',
      jobTitle: _jobTitle,
      company: _company,
      resume: combinedResumeData, // <--- Store both here (data prefixing)
      portfolioUrl: _portfolioController.text,
      coverLetter: _coverLetterController.text,
      skills: _skills,
      submittedAt: widget.applicant?.submittedAt ?? DateTime.now().toIso8601String(),
    );
  }

  //=====================================================================================
  // HANDLERS
  //=====================================================================================

  Future<void> _handleSubmit() async {
    if (_portfolioError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the Portfolio URL error.')),
      );
      return;
    }

    final draft = _buildApplicant();

    // "Peel off" the filename prefix for the final database entry
    String cleanResume = draft.resume;
    if (cleanResume.contains('|')) {
      cleanResume = cleanResume.split('|')[1];
    }

    // Create a unique ID for this specific application entry
    final String docId = DateTime.now().millisecondsSinceEpoch.toString();

    final finalApplicant = draft.copyWith(
      id: docId,
      resume: cleanResume,
      submittedAt: DateTime.now().toIso8601String(),
    );

    if (!finalApplicant.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume and write a cover letter.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // === THE FIREBASE CALL ===
      await _firestoreService.add(docId, finalApplicant);

      // Success!
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted to Firebase!'),
            backgroundColor: Color(0xFF0BA87E),
          ),
        );

        // Delay slightly so the user can see the success message
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      // Handle errors (like the 1MB Firestore limit)
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
                      // Use the state variables here so the widget "remembers" the selection
                      initialFileName: _resumeFileName.isNotEmpty ? _resumeFileName : null,
                      initialFileBase64: _resumePath.isNotEmpty ? _resumePath : null,

                      onFileSelected: (path, name) {
                        setState(() {
                          _resumePath = path;
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
              onTap: () {
                // Build the applicant object with current text field values
                final currentDraft = _buildApplicant();
                Navigator.pop(context, currentDraft); // Pass the draft back
              },
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
        TextField(
          controller: _portfolioController,
          onChanged: (value) {
            setState(() {
              if (value.isNotEmpty && !_isValidUrl(value)) {
                _portfolioError = 'Please enter a valid URL (e.g., https://...)';
              } else {
                _portfolioError = null;
              }
            });
          },
          style: const TextStyle(fontSize: 14, color: kTextPrimary),
          decoration: InputDecoration(
            hintText: 'https://portfolio.com',
            hintStyle: const TextStyle(fontSize: 14, color: kTextPlaceholder),
            prefixIcon: const Icon(Icons.link_rounded, color: kTextPlaceholder, size: 20),

            // Styling to match your existing design
            filled: true,
            fillColor: Colors.white,
            errorText: _portfolioError, // This displays the red text automatically
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

            // Border logic
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
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
    // Add 'return' and a parent widget (like Container)
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            final isActive = _currentIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    _icons[index],
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
