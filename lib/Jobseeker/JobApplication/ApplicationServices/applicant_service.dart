import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:assignment/Jobseeker/models/applicant_model.dart';

class ApplicantService {
  static Applicant buildApplicant({
    required String resumePath,
    required String portfolioUrl,
    required String coverLetter,
    required List<String> skills,
    required String jobTitle,
    required String company,
    required String jobId,
    String? companyId,
    String salary          = '',
    String workType        = '',
    String workplace       = '',
    String education       = '',
    String experienceLevel = '',
  }) {
    return Applicant(
      id:              DateTime.now().millisecondsSinceEpoch.toString(),
      jobId:           jobId,
      jobTitle:        jobTitle,
      company:         company,
      companyId:       companyId,
      resume:          resumePath,
      portfolioUrl:    portfolioUrl.trim(),
      coverLetter:     coverLetter.trim(),
      skills:          List<String>.from(skills),
      submittedAt:     DateTime.now().toIso8601String(),
      salary:          salary,
      workType:        workType,
      workplace:       workplace,
      education:       education,
      experienceLevel: experienceLevel,
    );
  }

  /// Returns the Firestore-generated doc ID on success, null on failure.
  /// Changed from bool so callers have the real doc ID for follow-up writes
  /// (e.g. employer_notifications needs applicationId = the real Firestore ID).
  static Future<String?> submitApplicant(Applicant applicant) async {
    if (!applicant.validate()) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final data = applicant.toMap();

      // Auth + status metadata
      data['userId']         = user.uid;
      data['candidateName']  = user.displayName ?? '';
      data['candidateEmail'] = user.email ?? '';
      data['status']         = 'unprocessed';
      data['appliedAt']      = FieldValue.serverTimestamp();

      // .add() returns a DocumentReference — we grab the real generated ID
      final docRef = await FirebaseFirestore.instance
          .collection('applications')
          .add(data);

      return docRef.id; // ← real Firestore ID, e.g. "xT7JFO7KfsmrpGzDhUVz"
    } catch (e) {
      debugPrint('Error saving application: $e');
      return null;
    }
  }

  static void printApplicant(Applicant applicant) {
    debugPrint('===== APPLICATION SUBMITTED =====');
    debugPrint('ID            : ${applicant.id}');
    debugPrint('Job ID        : ${applicant.jobId}');
    debugPrint('Job Title     : ${applicant.jobTitle}');
    debugPrint('Company       : ${applicant.company}');
    debugPrint('Company ID    : ${applicant.companyId}');
    debugPrint('Resume        : ${applicant.resume}');
    debugPrint('Portfolio URL : ${applicant.portfolioUrl}');
    debugPrint('Cover Letter  : ${applicant.coverLetter}');
    debugPrint('Skills        : ${applicant.skills.join(', ')}');
    debugPrint('Submitted At  : ${applicant.submittedAt}');
    debugPrint('=================================');
    debugPrint('toMap() => ${applicant.toMap()}');
  }

  static String generateAiDraft(Applicant applicant) {
    return 'I am excited to apply for the ${applicant.jobTitle} role at '
        '${applicant.company}. With my expertise in '
        '${applicant.skills.join(', ')}, I am confident I can deliver '
        'exceptional results that align with your product vision.';
  }
}