// lib/Jobseeker/JobApplication/ApplicationUI/saved_job_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../ApplicationUI/job_details_screen.dart';
import '../../InterviewPractice/interview_practice_screen.dart';
import '../../Widgets/nav_bar_widget.dart';
import '../../MainScreen/jobseeker_profile.dart';
import 'applied_job_list.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({Key? key}) : super(key: key);

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  static const Color _blue      = Color(0xFF3B52E8);
  static const Color _cardColor = Color(0xFF2D3A8C);
  static const Color _cardDeep  = Color(0xFF1E2A6E);
  static const Color _bg        = Color(0xFFF4F5FA);

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    try {
      dt = (ts as Timestamp).toDate();
    } catch (_) {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7)
      return 'Saved ${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0)
      return 'Saved ${diff.inDays}d ago';
    if (diff.inHours > 0)
      return 'Saved ${diff.inHours}h ago';
    return 'Saved just now';
  }

  Future<void> _unsaveJob(String jobId, String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    await ref.update({
      'savedJobs': FieldValue.arrayRemove([jobId]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Saved Jobs',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,

        // ── Practice Interview button ──────────────────────────────────
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const InterviewPracticeJobSelectScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B52E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.record_voice_over_rounded,
                        color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Practice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: user == null
          ? const Center(
          child: Text('Please log in to see saved jobs.'))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final userData =
          userSnap.data!.data() as Map<String, dynamic>?;
          final savedIds = List<String>.from(
              userData?['savedJobs'] ?? []);

          if (savedIds.isEmpty) {
            return _buildEmpty();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where(FieldPath.documentId,
                whereIn: savedIds)
                .snapshots(),
            builder: (context, jobSnap) {
              if (!jobSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final docs = jobSnap.data!.docs;

              if (docs.isEmpty) {
                return _buildEmpty();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data =
                  docs[i].data() as Map<String, dynamic>;
                  final jobId = docs[i].id;
                  return _savedJobCard(
                      data, jobId, user.uid);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 1) return;
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AppliedJobsScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(
                    user: FirebaseAuth.instance.currentUser),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _savedJobCard(
      Map<String, dynamic> data, String jobId, String uid) {
    final title    = data['title'] ?? 'Job Title';
    final company  = data['company'] ?? '';
    final location = data['location'] ?? '';
    final salary   = data['salary'] ?? '';
    final workType = data['workType'] ?? '';
    final workplace = data['workplace'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D3A8C), Color(0xFF1E2A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2A6E).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final job = Job(
            id: jobId,
            title: title,
            company: company,
            location: location,
            workType: workType,
            workplace: workplace,
            salary: salary,
            postedTime: '',
            applicants: '0 applied',
            createdAt: (data['createdAt'] as Timestamp?)
                ?.toDate() ??
                DateTime.now(),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => JobDetailsPage(job: job)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + filled bookmark (tap to unsave)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _unsaveJob(jobId, uid),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C842),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bookmark_rounded,
                          color: Color(0xFF1A1A2E), size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Text(company,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),

              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(location,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ]),

              if (salary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.payments_outlined,
                      size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(salary,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ],

              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time,
                    size: 13, color: Colors.white54),
                const SizedBox(width: 4),
                Text(_timeAgo(data['createdAt']),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                size: 40, color: Color(0xFF3B52E8)),
          ),
          const SizedBox(height: 16),
          const Text('No saved jobs yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          const Text(
            'Tap the bookmark icon on any job\nto save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}