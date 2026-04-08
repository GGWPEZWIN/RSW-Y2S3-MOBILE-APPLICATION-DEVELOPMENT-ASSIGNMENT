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
    String salary = '',
    String workType = '',
    String workplace = '',
    String education = '',
    String experienceLevel = '',
  }) {
    return Applicant(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      companyId: companyId,
      resume: resumePath,
      portfolioUrl: portfolioUrl.trim(),
      coverLetter: coverLetter.trim(),
      skills: List<String>.from(skills),
      submittedAt: DateTime.now().toIso8601String(),
      salary: salary,
      workType: workType,
      workplace: workplace,
      education: education,
      experienceLevel: experienceLevel
    );
  }

  static Future<bool> submitApplicant(Applicant applicant) async {
    if (!applicant.validate()) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final data = applicant.toMap();

      // Add user + status metadata
      data['userId'] = user.uid;
      data['candidateName'] = user.displayName ?? '';
      data['candidateEmail'] = user.email ?? '';
      data['status'] = 'unprocessed';
      data['appliedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('applications')
          .add(data);
      return true;
    } catch (e) {
      debugPrint('Error saving application: $e');
      return false;
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