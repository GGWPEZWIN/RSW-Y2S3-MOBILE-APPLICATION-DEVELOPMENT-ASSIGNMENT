import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../ApplicationServices/apply_job_service.dart';
import 'jobseeker_notification_page.dart';
import 'saved_job_list.dart';
import 'applied_job_list.dart';

class JobDetailsPage extends StatefulWidget {
  final Job job;
  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  bool _isLoading = true;
  bool _isEmployer = false;
  bool _hasApplied = false;
  bool _isSaved = false;
  String? _userCompanyId;
  Map<String, dynamic>? _jobData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadJobData();
  }

  Future<void> _loadJobData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.id)
          .get();
      if (doc.exists) {
        setState(() {
          _jobData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading job data: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final companyId = (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      final role = (userDoc.data() as Map<String, dynamic>?)?['role'] as String?;

      // Check if user has already applied
      final appSnap = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('jobId', isEqualTo: widget.job.id)
          .get();

      // Check if job is saved
      final savedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedJobs')
          .doc(widget.job.id)
          .get();

      if (mounted) {
        setState(() {
          _isEmployer = role == 'employer' && companyId != null && companyId.isNotEmpty;
          _userCompanyId = _isEmployer ? companyId : null;
          _hasApplied = appSnap.docs.isNotEmpty;
          _isSaved = savedDoc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login to save jobs', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedJobs')
          .doc(widget.job.id);

      if (_isSaved) {
        await ref.delete();
        setState(() => _isSaved = false);
        _showSnackBar('Job removed from saved', isError: false);
      } else {
        await ref.set({
          'jobId': widget.job.id,
          'jobTitle': widget.job.title,
          'company': widget.job.company,
          'location': widget.job.location,
          'workType': widget.job.workType,
          'workplace': widget.job.workplace,
          'salary': widget.job.salary,
          'savedAt': FieldValue.serverTimestamp(),
        });
        setState(() => _isSaved = true);
        _showSnackBar('Job saved!', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyForJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login to apply', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ApplyJobService.applyForJob(jobId: widget.job.id!);
      if (success) {
        setState(() => _hasApplied = true);
        _showSnackBar('Applied successfully!', isError: false);
      } else {
        _showSnackBar('Failed to apply. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.job.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Save button
          IconButton(
            onPressed: _isEmployer ? null : _toggleSave,
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? const Color(0xFFF5C842) : Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B4FD8), Color(0xFF2A3BB8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.company,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        widget.job.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work_outline_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.job.workType} · ${widget.job.workplace}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        widget.job.salary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Job Description
            const Text(
              'Job Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _jobData?['description'] ?? widget.job.description ?? 'No description provided.',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Requirements
            if ((_jobData?['requirements'] ?? '').isNotEmpty) ...[
              const Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jobData?['requirements'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],

            // Benefits
            if ((_jobData?['benefits'] ?? '').isNotEmpty) ...[
              const Text(
                'Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jobData?['benefits'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],

            // Apply Button (only for jobseekers who haven't applied)
            if (!_isEmployer && !_hasApplied)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _applyForJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B4FD8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Already Applied message
            if (!_isEmployer && _hasApplied)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Center(
                  child: Text(
                    '✓ You have already applied for this job',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

            // Employer message
            if (_isEmployer)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Center(
                  child: Text(
                    'You are viewing as an employer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}