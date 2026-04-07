// lib/Jobseeker/JobApplication/ApplicationServices/apply_job_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApplyJobService {
  /// Call this when user taps "Apply".
  /// Saves application to Firestore and increments job applicant count.
  /// Returns true on success, false on failure.
  static Future<bool> applyForJob({
    required String jobId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('ApplyJobService: no logged-in user');
        return false;
      }

      // ── 1. Fetch job document ───────────────────────────────────────────
      final jobSnap = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();

      if (!jobSnap.exists) {
        debugPrint('ApplyJobService: job $jobId not found');
        return false;
      }

      final job = jobSnap.data()!;

      // ── 2. Fetch user profile ───────────────────────────────────────────
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userSnap.data() ?? {};

      final candidateName = userData['displayName'] as String? ??
          userData['name'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          'Unknown';

      final education = userData['education'] as String? ??
          userData['educationLevel'] as String? ??
          '—';

      // ── 3. Check for duplicate application ─────────────────────────────
      final existing = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('ApplyJobService: already applied to job $jobId');
        return false;
      }

      // ── 4. Save application ─────────────────────────────────────────────
      await FirebaseFirestore.instance.collection('applications').add({
        // Who applied
        'userId':         user.uid,
        'candidateName':  candidateName,
        'candidateEmail': user.email ?? '',

        // Which job
        'jobId':     jobId,
        'jobTitle':  job['title']           ?? '',
        'jobLevel':  job['experienceLevel'] ?? '',
        'company':   job['company']         ?? '',
        'companyId': job['companyId'],

        // Job details for employer card
        'workType':  job['workType']  ?? '',
        'workplace': job['workplace'] ?? '',
        'salary':    job['salary']    ?? '—',

        // Applicant details
        'education': education,

        // Status — employer manages this
        'status': 'unprocessed',

        // Timestamps
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // ── 5. Increment applicants count as int ────────────────────────────
      // home_page.dart handles displaying it safely via _parseApplicants().
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .update({'applicants': FieldValue.increment(1)});

      debugPrint(
          'ApplyJobService: application saved for $candidateName → ${job['title']}');
      return true;
    } catch (e) {
      debugPrint('ApplyJobService error: $e');
      return false;
    }
  }

  /// Check if the current user has already applied to a job.
  static Future<bool> hasApplied(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Get the current applicant count for a job as an int.
  static Future<int> getApplicantCount(String jobId) async {
    final jobSnap = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();

    if (!jobSnap.exists) return 0;
    final raw = jobSnap.data()?['applicants'];
    if (raw == null) return 0;
    if (raw is int) return raw;
    // Handle legacy String values like "5 applied"
    return int.tryParse(raw.toString().split(' ').first) ?? 0;
  }
}