import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job_model.dart';
import './create_job_screen.dart';
import '../../../Jobseeker/JobApplication/ApplicationUI/job_details_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});
  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2A3BB8);

  // ✅ employerId = current user uid — matches Firebase index
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _deleteJob(String jobId) async {
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
  }

  void _showDeleteDialog(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFFF2D55), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Delete job', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Are you sure want to delete "${job.title}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1D5DB), foregroundColor: Colors.black, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('No, keep it.', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async { Navigator.pop(context); await _deleteJob(job.id!); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55), foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Yes, Delete!', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _navigateToEditJob(Job job) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateJobPage(jobToEdit: job)));
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Map<String, dynamic> _getJobStatus(Map<String, dynamic> data) {
    final now         = DateTime.now();
    final publishDate = (data['publishDate'] as Timestamp?)?.toDate();
    final expiryDate  = (data['expiryDate']  as Timestamp?)?.toDate();
    if (expiryDate != null && expiryDate.isBefore(now)) {
      return {'label': 'Expired',                                     'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE)};
    }
    if (publishDate != null && publishDate.isAfter(now)) {
      return {'label': 'Scheduled · ${publishDate.day}/${publishDate.month}/${publishDate.year}',
        'color': const Color(0xFFE07B39), 'bg': const Color(0xFFFFF3E0)};
    }
    return {'label': '● Live', 'color': const Color(0xFF2CB06A), 'bg': const Color(0xFFE8FBF0)};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: const Text('My Job List', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateJobPage())),
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ employerId — matches Firebase index (same field create_job_screen.dart saves)
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('employerId', isEqualTo: _currentUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.work_outline_rounded, size: 40, color: _blue1),
              ),
              const SizedBox(height: 16),
              const Text('No jobs posted yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Tap + to create your first job', style: TextStyle(color: Colors.grey)),
            ]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final benefits     = (data['benefits'] ?? '') as String;
              final benefitLines = benefits.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).take(3).toList();

              final job = Job(
                id:         doc.id,
                title:      data['title']     ?? '',
                companyId:  data['companyId'] ?? '',
                company:    data['company']   ?? '',
                location:   data['location']  ?? '',
                workType:   data['workType']  ?? '',
                workplace:  data['workplace'] ?? '',
                salary:     data['salary']    ?? '',
                postedTime: data['postedTime'] ?? '',
                applicants: data['applicants']?.toString() ?? '0 applied',
                createdAt:  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );

              return _jobCard(job, benefitLines, _getJobStatus(data));
            },
          );
        },
      ),
    );
  }

  Widget _jobCard(Job job, List<String> benefitLines, Map<String, dynamic> status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue1, _blue2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _blue1.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tag(job.workType),
              const SizedBox(width: 8),
              if (job.workplace.isNotEmpty) _tag(job.workplace),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: status['bg'] as Color, borderRadius: BorderRadius.circular(12)),
                child: Text(status['label'] as String,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: status['color'] as Color)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _navigateToEditJob(job),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showDeleteDialog(context, job),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 15),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(
                  job.company.isNotEmpty ? job.company[0].toUpperCase() : 'J',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _blue1),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(job.company, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(child: Text(job.location, style: const TextStyle(color: Colors.white70, fontSize: 13))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.sell_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(job.salary, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            if (benefitLines.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...benefitLines.map((b) {
                final text = b.startsWith('•') ? b.substring(1).trim() : b;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ]),
                );
              }),
            ],
          ]),
        ),
        Divider(color: Colors.white.withOpacity(0.2), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white60),
            const SizedBox(width: 4),
            Text(_getTimeAgo(job.createdAt), style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(width: 14),
            const Icon(Icons.people_outline, size: 14, color: Colors.white60),
            const SizedBox(width: 4),
            Text(job.applicants, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsPage(job: job))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF5C842), borderRadius: BorderRadius.circular(20)),
                child: const Text('View details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  );
}