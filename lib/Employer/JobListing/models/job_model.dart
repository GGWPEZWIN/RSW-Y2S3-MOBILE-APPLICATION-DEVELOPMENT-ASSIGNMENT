import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String? id;
  final String title;
  final String company;
  final String location;
  final String workType;
  final String workplace;
  final String salary;
  final String postedTime;
  final String applicants;
  final DateTime createdAt;

  Job({
    this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.workType,
    required this.workplace,
    required this.salary,
    required this.postedTime,
    required this.applicants,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'workType': workType,
      'workplace': workplace,
      'salary': salary,
      'postedTime': postedTime,
      'applicants': applicants,
      'createdAt': createdAt,
    };
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    return Job(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      workType: map['workType'] ?? '',
      workplace: map['workplace'] ?? '',
      salary: map['salary'] ?? '',
      postedTime: map['postedTime'] ?? '',
      applicants: map['applicants'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
