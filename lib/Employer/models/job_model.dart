import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  String? id;
  final String title;
  final String company;
  final String? companyId;
  final String location;
  final String workType;
  final String workplace;
  final String salary;
  final String postedTime;
  final String applicants;
  final DateTime createdAt;

  // Additional fields from the create job form
  final String? description;
  final String? requirements;
  final String? benefits;
  final int? vacancies;
  final String? experienceLevel;
  final String? educationLevel;
  final DateTime? publishDate;
  final DateTime? expiryDate;
  final String? applicationMethod;
  final String? applicationUrl;
  final String? applicationEmail;
  final String? payType;
  final String? showPayOnAd;

  Job({
    this.id,
    required this.title,
    required this.company,
    this.companyId,
    required this.location,
    required this.workType,
    required this.workplace,
    required this.salary,
    required this.postedTime,
    required this.applicants,
    required this.createdAt,
    this.description,
    this.requirements,
    this.benefits,
    this.vacancies,
    this.experienceLevel,
    this.educationLevel,
    this.publishDate,
    this.expiryDate,
    this.applicationMethod,
    this.applicationUrl,
    this.applicationEmail,
    this.payType,
    this.showPayOnAd,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      if (companyId != null) 'companyId': companyId,
      'location': location,
      'workType': workType,
      'workplace': workplace,
      'salary': salary,
      'postedTime': postedTime,
      'applicants': applicants,
      'createdAt': createdAt,
      if (description != null) 'description': description,
      if (requirements != null) 'requirements': requirements,
      if (benefits != null) 'benefits': benefits,
      if (vacancies != null) 'vacancies': vacancies,
      if (experienceLevel != null) 'experienceLevel': experienceLevel,
      if (educationLevel != null) 'educationLevel': educationLevel,
      if (publishDate != null) 'publishDate': publishDate,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (applicationMethod != null) 'applicationMethod': applicationMethod,
      if (applicationUrl != null) 'applicationUrl': applicationUrl,
      if (applicationEmail != null) 'applicationEmail': applicationEmail,
      if (payType != null) 'payType': payType,
      if (showPayOnAd != null) 'showPayOnAd': showPayOnAd,
    };
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    return Job(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      companyId: map['companyId'],
      location: map['location'] ?? '',
      workType: map['workType'] ?? '',
      workplace: map['workplace'] ?? '',
      salary: map['salary'] ?? '',
      postedTime: map['postedTime'] ?? '',
      applicants: map['applicants'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      requirements: map['requirements'],
      benefits: map['benefits'],
      vacancies: map['vacancies'],
      experienceLevel: map['experienceLevel'],
      educationLevel: map['educationLevel'],
      publishDate: (map['publishDate'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      applicationMethod: map['applicationMethod'],
      applicationUrl: map['applicationUrl'],
      applicationEmail: map['applicationEmail'],
      payType: map['payType'],
      showPayOnAd: map['showPayOnAd'],
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? companyId,
    String? location,
    String? workType,
    String? workplace,
    String? salary,
    String? postedTime,
    String? applicants,
    DateTime? createdAt,
    String? description,
    String? requirements,
    String? benefits,
    int? vacancies,
    String? experienceLevel,
    String? educationLevel,
    DateTime? publishDate,
    DateTime? expiryDate,
    String? applicationMethod,
    String? applicationUrl,
    String? applicationEmail,
    String? payType,
    String? showPayOnAd,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      companyId: companyId ?? this.companyId,
      location: location ?? this.location,
      workType: workType ?? this.workType,
      workplace: workplace ?? this.workplace,
      salary: salary ?? this.salary,
      postedTime: postedTime ?? this.postedTime,
      applicants: applicants ?? this.applicants,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      vacancies: vacancies ?? this.vacancies,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      educationLevel: educationLevel ?? this.educationLevel,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      applicationEmail: applicationEmail ?? this.applicationEmail,
      payType: payType ?? this.payType,
      showPayOnAd: showPayOnAd ?? this.showPayOnAd,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }
}