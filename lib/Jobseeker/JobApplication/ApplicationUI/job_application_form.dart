import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/applicant_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const JobApplicationScreen(),
    );
  }
}

class JobApplicationScreen extends StatefulWidget {
  const JobApplicationScreen({super.key});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _coverLetterController = TextEditingController();

  static const Color kBlue = Color(0xFF2F6FED);
  static const Color kBlueDark = Color(0xFF1A57D4);
  static const Color kBlueLight = Color(0xFFEEF3FD);
  static const Color kTextPrimary = Color(0xFF0F1624);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kTextPlaceholder = Color(0xFFADBAC7);
  static const Color kBorder = Color(0xFFE4E9F0);
  static const Color kBg = Color(0xFFF5F7FA);
  static const Color kAiGreen = Color(0xFF0BA87E);
  static const Color kAiPurple = Color(0xFF7C3AED);

  // Applicant state
  // These fields map 1-to-1 with Applicant class fields
  String _resumePath = '';
  String _resumeFileName = '';
  bool _isSubmitting = false;

  // Applicant.skills — pre-populated from profile
  final List<String> _skills = ['UI Design', 'Prototyping', 'Figma', 'React'];

  // ── Lifecycle
  @override
  void dispose() {
    _portfolioController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  // ── Build Applicant object from current UI state
  // Collects all form values and constructs Applicant using its constructor
  Applicant _buildApplicant() {
    return Applicant(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // replace with DB-generated ID
      jobTitle: 'Senior Product Designer',
      company: 'TechFlow Inc.',
      resume: _resumePath,
      portfolioUrl: _portfolioController.text.trim(),
      coverLetter: _coverLetterController.text.trim(),
      skills: List<String>.from(_skills),
      submittedAt: DateTime.now().toIso8601String(),
    );
  }

  // Submit handler
  // 1. Build the Applicant object
  // 2. Call applicant.validate() to check required fields
  // 3. Call applicant.toMap() to get Map ready for database
  Future<void> _handleSubmit() async {
    final applicant = _buildApplicant();

    // Uses Applicant.validate() method
    if (!applicant.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a resume, write a cover letter, and select at least one skill.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate async save — replace with:
    // await FirebaseFirestore.instance.collection('applications').add(applicant.toMap());
    await Future.delayed(const Duration(seconds: 2));

    // Uses Applicant.toMap() — prints what would be sent to DB
    debugPrint('Saving applicant: ${applicant.toMap()}');
    // Uses Applicant.toString() — for readable debugging
    debugPrint('Submitted: $applicant');

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF0BA87E),
        ),
      );
    }
  }

  // AI Draft handler
  // Uses copyWith() pattern — updates only coverLetter, keeps everything else
  void _handleAiDraft() {
    final draft = _buildApplicant().copyWith(
      coverLetter:
      'I am excited to apply for the Senior Product Designer role at TechFlow Inc. '
          'With my expertise in ${_skills.join(', ')}, I am confident I can deliver '
          'exceptional user experiences that align with your product vision.',
    );
    // Apply the AI draft back to the controller
    _coverLetterController.text = draft.coverLetter;
  }

  // Build
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
                    // Resume / CV — uses ResumeUploadWidget
                    // onFileSelected sets _resumePath → Applicant.resume
                    ResumeUploadWidget(
                      initialFileName: 'example.pdf',
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
              color: Color(0x0A0F1624), blurRadius: 16, offset: Offset(0, 4)),
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
                'Senior Product Designer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'TechFlow Inc. • San Francisco, CA',
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w400,
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

  // Binds to: Applicant.portfolioUrl via _portfolioController
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
              prefixIcon:
              Icon(Icons.link_rounded, color: kTextPlaceholder, size: 20),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Binds to: Applicant.skills via _skills List<String>
  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Profile Skills', trailing: _buildAiVerifiedBadge()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) => _buildSkillChip(skill)).toList(),
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
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
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

  // Binds to: Applicant.coverLetter via _coverLetterController
  // AI DRAFT button uses copyWith() to generate a draft without mutating state
  Widget _buildCoverLetterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Cover Letter',
          trailing: _buildAiDraftBadge(),
        ),
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
        const Icon(Icons.info_outline_rounded, size: 14, color: kTextSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Applications are usually reviewed within 48 hours. Your profile details will be shared with TechFlow Inc.',
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

  // Triggers the full Applicant lifecycle:
  // _buildApplicant() → validate() → toMap() → save to DB
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

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
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

class ResumeUploadWidget extends StatefulWidget {
  /// Called when the user picks or replaces a file.
  /// [filePath] — absolute path on device (use this for Applicant.resume)
  /// [fileName] — display name e.g. "Lee_resume_2026.pdf"
  final void Function(String filePath, String fileName) onFileSelected;

  /// Optional: pre-fill with an already-uploaded file
  final String? initialFileName;
  final String? initialFilePath;

  const ResumeUploadWidget({
    super.key,
    required this.onFileSelected,
    this.initialFileName,
    this.initialFilePath,
  });

  @override
  State<ResumeUploadWidget> createState() => _ResumeUploadWidgetState();
}

class _ResumeUploadWidgetState extends State<ResumeUploadWidget> {
  // Constants
  static const Color kBlue          = Color(0xFF2F6FED);
  static const Color kBorder        = Color(0xFFE4E9F0);
  static const Color kTextPrimary   = Color(0xFF0F1624);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kIconBg        = Color(0xFFF0F3F8);

  // state
  String? _fileName;
  String? _filePath;
  String? _uploadedAgo;
  bool   _isLoading = false;
  String? _errorMessage;

  // Lifecycle
  @override
  void initState() {
    super.initState();
    // Pre-fill if initial values are provided
    if (widget.initialFileName != null) {
      _fileName    = widget.initialFileName;
      _filePath    = widget.initialFilePath;
      _uploadedAgo = 'N/A';
    }
  }

  // Upload logic
  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final picked = result.files.single;

      // Validate file size (max 5 MB)
      if (picked.size > 5 * 1024 * 1024) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'File too large. Maximum size is 5 MB.';
        });
        return;
      }

      final path = picked.path;
      if (path == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not read file path. Please try again.';
        });
        return;
      }

      final fileName = picked.name;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes/$fileName'); // folder "resumes/"

      // Upload file
      final uploadTask = storageRef.putFile(File(path));

      // Wait for completion
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _fileName = fileName;
        _filePath = downloadUrl; // <-- THIS IS THE URL TO STORE
        _uploadedAgo = 'Uploaded just now';
        _isLoading = false;
        _errorMessage = null;
      });

      // Notify parent
      widget.onFileSelected(downloadUrl, fileName);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
      debugPrint('Upload error: $e');
    }
  }

  // Helpers
  String get _displayName => _fileName ?? 'No file selected';
  bool   get _hasFile     => _fileName != null;

  // Build
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        const Text(
          'Resume / CV',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 8),

        // File card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasFile ? kBlue.withOpacity(0.4) : kBorder,
              width: _hasFile ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: file info + button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File name
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _hasFile ? kTextPrimary : kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Timestamp
                    if (_hasFile) ...[
                      const SizedBox(height: 3),
                      Text(
                        _uploadedAgo ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Replace / Upload button
                    _isLoading
                        ? const SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBlue,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              fontSize: 13,
                              color: kBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text(_hasFile ? 'Replace File' : 'Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right: file icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _hasFile
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: _hasFile ? kBlue : kTextSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],

        // Accepted formats hint
        const SizedBox(height: 6),
        const Text(
          'Accepted formats: PDF, DOC, DOCX — max 5 MB',
          style: TextStyle(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }
}