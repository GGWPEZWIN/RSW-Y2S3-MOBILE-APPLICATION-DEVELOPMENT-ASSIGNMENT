import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../ApplicationUI/job_details_screen.dart';
import '../../InterviewPractice/interview_practice_screen.dart';
import '../../Widgets/nav_bar_widget.dart';
import 'applied_job_list.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({Key? key}) : super(key: key);

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  static const Color _blue = Color(0xFF3B52E8);
  static const Color _bg   = Color(0xFFF4F5FA);

  // Sorting and Filtering State
  String _selectedSort = 'Newest';
  String _searchQuery = '';

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    try { dt = (ts as Timestamp).toDate(); } catch (_) { return ''; }
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return 'Saved ${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0)  return 'Saved ${diff.inDays}d ago';
    if (diff.inHours > 0) return 'Saved ${diff.inHours}h ago';
    return 'Saved just now';
  }

  double _parseSalary(String salary) {
    final clean = salary.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  // --- UPDATED UNSAVE LOGIC WITH UNDO ---
  Future<void> _unsaveJob(String jobId, String uid, Map<String, dynamic> jobData) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedJobs')
        .doc(jobId);

    try {
      await docRef.delete();

      if (mounted) {
        // Clear previous SnackBars so the user sees the new one immediately
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job removed from saved'),
            backgroundColor: const Color(0xFF1E2A6E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFFF5C842), // Matches bookmark yellow
              onPressed: () async {
                // Restore the job data exactly as it was
                await docRef.set(jobData);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Unsave error: $e");
    }
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterviewPracticeJobSelectScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text('Practice', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see saved jobs.'))
          : Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('savedJobs')
                  .orderBy('savedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                List<QueryDocumentSnapshot> docs = snap.data!.docs;

                // Client-side Filtering
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['jobTitle'] ?? data['title'] ?? '').toString().toLowerCase();
                    final company = (data['company'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || company.contains(_searchQuery);
                  }).toList();
                }

                // Sorting
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  if (_selectedSort == 'Salary') {
                    return _parseSalary(dataB['salary'] ?? '').compareTo(_parseSalary(dataA['salary'] ?? ''));
                  } else if (_selectedSort == 'Alphabetical') {
                    return (dataA['jobTitle'] ?? '').toString().compareTo((dataB['jobTitle'] ?? '').toString());
                  }
                  final timeA = dataA['savedAt'] as Timestamp? ?? Timestamp.now();
                  final timeB = dataB['savedAt'] as Timestamp? ?? Timestamp.now();
                  return timeB.compareTo(timeA);
                });

                if (docs.isEmpty) return _buildEmpty();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final jobId = docs[i].id;
                    return _savedJobCard(data, jobId, user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 1) return;
          if (index == 0) Navigator.pop(context);
          else if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppliedJobsScreen()));
          else if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage(user: user)));
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search title or company...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedSort,
              underline: const SizedBox(),
              icon: const Icon(Icons.sort, size: 18, color: _blue),
              items: ['Newest', 'Salary', 'Alphabetical'].map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSort = val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedJobCard(Map<String, dynamic> data, String jobId, String uid) {
    final title     = data['jobTitle']  ?? data['title']   ?? 'Job Title';
    final company   = data['company']   ?? '';
    final location  = data['location']  ?? '';
    final salary    = data['salary']    ?? '';
    final workType  = data['workType']  ?? '';
    final workplace = data['workplace'] ?? '';

    final job = Job(
      id:        jobId,
      title:     title,
      company:   company,
      location:  location,
      workType:  workType,
      workplace: workplace,
      salary:    salary,
      postedTime: '',
      applicants: '0 applied',
      createdAt: DateTime.now(),
    );

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsPage(job: job)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    // PASS DATA TO THE UNSAVE FUNCTION FOR THE UNDO ACTION
                    onTap: () => _unsaveJob(jobId, uid, data),
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
              Text(company, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),

              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),

              if (salary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.payments_outlined, size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(salary, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],

              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 13, color: Colors.white54),
                const SizedBox(width: 4),
                Text(_timeAgo(data['savedAt']), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobDetailsPage(job: job)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C842),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1A1A2E)),
                      SizedBox(width: 6),
                      Text(
                        'View Job Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                    ],
                  ),
                ),
              ),
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
            child: const Icon(Icons.bookmark_border_rounded, size: 40, color: Color(0xFF3B52E8)),
          ),
          const SizedBox(height: 16),
          const Text('No saved jobs yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
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