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
  static const Color _blue = Color(0xFF3B52E8);
  static const Color _bg   = Color(0xFFF4F5FA);

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

  Future<void> _unsaveJob(String jobId, String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedJobs')
        .doc(jobId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job removed from saved'), duration: Duration(seconds: 2)),
      );
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

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['jobTitle'] ?? data['title'] ?? '').toString().toLowerCase();
                    final company = (data['company'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || company.contains(_searchQuery);
                  }).toList();
                }

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
          else if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser)));
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
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),

            if (location.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align icon with the first line of text
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded( // 👈 This prevents the overflow
                    child: Text(
                      location,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      softWrap: true, // Allows text to wrap to the next line
                    ),
                  ),
                ],
              ),

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
              const Icon(Icons.access_time, size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text(_timeAgo(data['savedAt']),
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ]),

            const SizedBox(height: 14),

            // ✅ FIXED: Use Column instead of Row to prevent overflow
            Column(
              children: [
                // Practice Interview Button - Full width
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => InterviewPracticeSessionScreen(savedJobData: data),
                  ),
    ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C842),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.record_voice_over_rounded,
                            size: 16, color: Color(0xFF1A1A2E)),
                        SizedBox(width: 8),
                        Text(
                          'Practice Interview',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // View Details Button - Full width
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JobDetailsPage(job: job)),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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