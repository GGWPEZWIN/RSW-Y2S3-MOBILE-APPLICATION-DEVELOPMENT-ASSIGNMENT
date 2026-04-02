// lib/Jobseeker/models/applicant_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Applicant {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String? companyId;
  final String resume;
  final String portfolioUrl;
  final String coverLetter;
  final List<String> skills;
  final String submittedAt;

  Applicant({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    this.companyId,
    required this.resume,
    required this.portfolioUrl,
    required this.coverLetter,
    required this.skills,
    required this.submittedAt,
  });

  // Update specific fields without recreating the whole object
  Applicant copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? company,
    String? companyId,
    String? resume,
    String? portfolioUrl,
    String? coverLetter,
    List<String>? skills,
    String? submittedAt,
  }) {
    return Applicant(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      companyId: companyId ?? this.companyId,
      resume: resume ?? this.resume,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      coverLetter: coverLetter ?? this.coverLetter,
      skills: skills ?? this.skills,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  // Validate before allowing submit
  bool validate() {
    return resume.isNotEmpty && coverLetter.isNotEmpty && skills.isNotEmpty;
  }

  // For debugging
  @override
  String toString() => 'Applicant($id, $jobTitle @ $company)';

  // Convert Applicant object → Map (for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'company': company,
      if (companyId != null) 'companyId': companyId,
      'resume': resume,
      'portfolioUrl': portfolioUrl,
      'coverLetter': coverLetter,
      'skills': skills,
      'submittedAt': submittedAt,
    };
  }

  // Convert Map → Applicant object (for reading from database)
  factory Applicant.fromMap(String id, Map<String, dynamic> map) {
    return Applicant(
      id: id,
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      company: map['company'] ?? '',
      companyId: map['companyId'],
      resume: map['resume'] ?? '',
      portfolioUrl: map['portfolioUrl'] ?? '',
      coverLetter: map['coverLetter'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      submittedAt: map['submittedAt'] ?? '',
    );
  }
}