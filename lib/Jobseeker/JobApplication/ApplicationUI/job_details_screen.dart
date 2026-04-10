import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../../../Employer/JobListing/ApplicationUI/create_job_screen.dart';
import '../../JobApplication/ApplicationServices/apply_job_service.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../../Widgets/nav_bar_widget.dart';
import 'job_application_screen.dart';

class JobDetailsPage extends StatefulWidget {
  final Job job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  int _currentIndex = 0;
  bool _isSaved      = false;
  bool _isEmployer   = false;
  bool _isLoading    = true;
  bool _hasApplied   = false;
  bool _isApplying   = false;
  String? _userCompanyId;
  int _applicantCount = 0;

  String _fetchedEducation = '';
  String _fetchedExperience = '';

  static const Color _blue  = Color(0xFF2563EB);
  static const Color _green = Color(0xFF0BA87E);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadApplicantCount();
  }

  Future<void> _loadApplicantCount() async {
    final count = await ApplyJobService.getApplicantCount(widget.job.id!);
    if (mounted) {
      setState(() {
        _applicantCount = count;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      ApplyJobService.hasApplied(widget.job.id!),
    ]);

    final userDoc    = results[0] as DocumentSnapshot;
    final hasApplied = results[1] as bool;
    final companyId  = (userDoc.data() as Map<String, dynamic>?)?['companyId'];

    if (mounted) {
      setState(() {
        _isEmployer   = companyId != null;
        _userCompanyId = companyId as String?;
        _hasApplied   = hasApplied;
        _isLoading    = false;
      });
    }
  }

  //Future<void> _handleApply() async {
  //  if (_hasApplied || _isApplying) return;
  //  setState(() => _isApplying = true);
  //  final success = await ApplyJobService.applyForJob(jobId: widget.job.id!);
  //  if (!mounted) return;
  //  setState(() {
  //    _isApplying = false;
  //    if (success) {
  //      _hasApplied = true;
  //      _applicantCount++;
  //    }
  //  });
  //  ScaffoldMessenger.of(context).showSnackBar(
  //    SnackBar(
  //      content: Text(
  //        success
  //            ? 'Application submitted! The employer will review it soon.'
  //            : 'You have already applied for this job.',
  //      ),
  //      backgroundColor: success ? _green : Colors.orange,
  //      duration: const Duration(seconds: 3),
  //    ),
  //  );
  //}

  Future<void> _handleApply() async {
    if (_hasApplied) return;

    final updatedJob = widget.job.copyWith(
      educationLevel: _fetchedEducation,
      experienceLevel: _fetchedExperience,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobApplicationScreen(
          jobId: updatedJob.id!,
          jobTitle: updatedJob.title,
          company: updatedJob.company,
          companyId: updatedJob.companyId,
          job: updatedJob,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _hasApplied = true;
        _applicantCount++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted! The employer will review it soon.'),
          backgroundColor: _green, // Using your green constant
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0)    return '${diff.inDays}d ago';
    if (diff.inHours > 0)   return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final job        = widget.job;
    final bool isOwnJob = _userCompanyId != null && job.companyId == _userCompanyId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── White top card ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Company logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        job.company.isNotEmpty ? job.company[0].toUpperCase() : 'J',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Job title
                  Text(
                    job.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Company + location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(job.company,
                          style: const TextStyle(
                              color: _blue, fontWeight: FontWeight.w600, fontSize: 15)),
                      const Text('  •  ', style: TextStyle(color: Color(0xFF64748B))),
                      Text(job.location,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info cards
                  Row(children: [
                    _infoCard('SALARY',    job.salary),
                    _infoCard('JOB TYPE',  job.workType),
                    _infoCard('WORKPLACE', job.workplace),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Meta row with live applicant count
                  Row(children: [
                    const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(_getTimeAgo(job.createdAt),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.people_outline, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('$_applicantCount applied',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ]),
                  const SizedBox(height: 20),

                  _sectionTitle('Job Description'),
                  const SizedBox(height: 10),

                  // Fetch full job data
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('jobs')
                        .doc(job.id)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      String description       = 'No description provided.';
                      String requirements      = '';
                      String benefits          = '';
                      String experience        = '';
                      String education         = '';
                      String applicationMethod = 'In-app';

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        description       = data['description']       ?? 'No description provided.';
                        requirements      = data['requirements']      ?? '';
                        benefits          = data['benefits']          ?? '';
                        experience        = data['experienceLevel']   ?? '';
                        education         = data['educationLevel']    ?? '';
                        applicationMethod = data['applicationMethod'] ?? 'In-app';

                        _fetchedEducation = education;
                        _fetchedExperience = experience;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(description,
                              style: const TextStyle(
                                  color: Color(0xFF475569), fontSize: 14, height: 1.6)),
                          const SizedBox(height: 24),

                          // Experience + Education badges
                          if (experience.isNotEmpty || education.isNotEmpty) ...[
                            Wrap(
                              spacing: 10, runSpacing: 8,
                              children: [
                                if (experience.isNotEmpty)
                                  _badgeChip(Icons.trending_up_rounded, experience),
                                if (education.isNotEmpty)
                                  _badgeChip(Icons.school_outlined, education),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Requirements
                          if (requirements.isNotEmpty) ...[
                            _sectionTitle('Requirements'),
                            const SizedBox(height: 10),
                            _bulletSection(requirements),
                            const SizedBox(height: 24),
                          ],

                          // Benefits
                          if (benefits.isNotEmpty) ...[
                            _sectionTitle('Benefits'),
                            const SizedBox(height: 10),
                            _benefitsSection(benefits),
                            const SizedBox(height: 24),
                          ],

                          // In-app info banner
                          if (applicationMethod == 'In-app') ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: _blue),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Apply directly through the JobBuddy app.',
                                      style: TextStyle(fontSize: 13, color: _blue)),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Location placeholder
                          _sectionTitle('Office Location'),
                          const SizedBox(height: 10),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.grey[300],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                                  const SizedBox(width: 6),
                                  Text(job.location,
                                      style: TextStyle(
                                          color: Colors.grey[700], fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────
            if (!_isLoading && !_isEmployer) ...[
              // Job Seeker: Show Save + Apply buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Row(children: [

                  // Save button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isSaved = !_isSaved),
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                      ),
                      label: Text(_isSaved ? 'Saved' : 'Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isSaved ? const Color(0xFF1D4ED8) : _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Apply Now / Applied button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_hasApplied || _isApplying) ? null : _handleApply,
                      icon: _isApplying
                          ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : Icon(
                        _hasApplied
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _hasApplied
                            ? 'Applied'
                            : _isApplying
                            ? 'Submitting...'
                            : 'Apply Now',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _hasApplied ? _green : _blue,
                        disabledBackgroundColor:
                        _hasApplied ? _green : _blue.withOpacity(0.6),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ] else if (!_isLoading && _isEmployer && isOwnJob) ...[
              // Employer sees their own job → Show Edit button only
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateJobPage(jobToEdit: job)),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ] else if (!_isLoading && _isEmployer && !isOwnJob) ...[
              // Employer viewing another company's job → Show message only
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'You cannot apply to jobs from other companies.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      bottomNavigationBar: NavBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigation Logic:
          if (index == 0) {
            Navigator.pop(context);
          } else if(index == 1) {
            // TODO: saved route
          }
          else if(index == 2) {
            // TODO: Applied route
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser)),
            );
          }
        },
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
  );

  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFA790CC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _badgeChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _bulletSection(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final text = line.startsWith('•') ? line.substring(1).trim() : line;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF2563EB), size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: Color(0xFF475569), fontSize: 14, height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _benefitsSection(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: lines.map((line) {
        final text = line.startsWith('•') ? line.substring(1).trim() : line;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline,
                size: 13, color: Color(0xFF16A34A)),
            const SizedBox(width: 5),
            Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList(),
    );
  }
}