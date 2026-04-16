import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:assignment/Jobseeker/models/applicant_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApplicantService {

  static const String _AImodel = 'gemini-3-flash-preview';
  static const String _apiKey = 'AIzaSyD-Yx8hfxWsIbavmxL6Pr3CQhoxqsvgAq0';

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

  static Future<String> generateAiDraft(Applicant applicant) async {
    try {
      // Initialize the model (using Flash for speed)
      final model = GenerativeModel(
        model: _AImodel,
        apiKey: _apiKey,
      );

      // We create a "Prompt" that gives the AI instructions and data
      final prompt = """
        Write a professional and concise cover letter (min 100 words, max 150 words).
        
        Job: ${applicant.jobTitle} at ${applicant.company}
        Candidate Skills: ${applicant.skills.join(', ')}
        
        Requirements:
        1. Be professional and enthusiastic.
        2. Specifically mention how the skills align with the role.
        3. Do NOT include placeholders like [Your Name].
        4. End with a professional closing.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Return the generated text or a fallback if it fails
      return response.text ?? "I'm excited to apply for this role and bring my skills to your team.";

    } catch (e) {
      debugPrint("AI Draft Error: $e");
      return "Error generating draft. Please write your cover letter manually.";
    }
  }
}