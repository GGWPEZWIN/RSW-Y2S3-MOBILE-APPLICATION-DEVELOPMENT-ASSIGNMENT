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
  }) {
    return Applicant(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      resume: resumePath,
      portfolioUrl: portfolioUrl.trim(),
      coverLetter: coverLetter.trim(),
      skills: List<String>.from(skills),
      jobTitle: jobTitle,
      company: company,
      submittedAt: DateTime.now().toIso8601String(),
    );
  }

  static Future<bool> submitApplicant(Applicant applicant) async {
    if (!applicant.validate()) return false;

    // Simulate async DB save
    await Future.delayed(const Duration(seconds: 2));

    // Print everything the user entered to the console
    printApplicant(applicant);
    return true;
  }

  // Prints every field to the console in a readable format
  static void printApplicant(Applicant applicant) {
    debugPrint('===== APPLICATION SUBMITTED =====');
    debugPrint('ID            : ${applicant.id}');
    debugPrint('Job Title     : ${applicant.jobTitle}');
    debugPrint('Company       : ${applicant.company}');
    debugPrint('Resume        : ${applicant.resume}');
    debugPrint('Portfolio URL : ${applicant.portfolioUrl}');
    debugPrint('Cover Letter  : ${applicant.coverLetter}');
    debugPrint('Skills        : ${applicant.skills.join(', ')}');
    debugPrint('Submitted At  : ${applicant.submittedAt}');
    debugPrint('=================================');
    // Print the raw map (what would go to the DB, and of course lah for debug punya)
    debugPrint('toMap() => ${applicant.toMap()}');
  }

  // Takes full Applicant so it can reference jobTitle and company
  static String generateAiDraft(Applicant applicant) {
    return 'I am excited to apply for the ${applicant.jobTitle} role at '
        '${applicant.company}. With my expertise in '
        '${applicant.skills.join(', ')}, I am confident I can deliver '
        'exceptional results that align with your product vision.';
  }
}