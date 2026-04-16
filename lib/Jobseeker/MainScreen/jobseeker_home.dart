import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../JobApplication/ApplicationUI/job_details_screen.dart';
import '../JobApplication/ApplicationServices/apply_job_service.dart';
import '../JobApplication/ApplicationUI/jobseeker_notification_page.dart';
import '../Widgets/nav_bar_widget.dart';
import 'AI_Matching.dart';
import 'jobseeker_profile.dart';
import '../JobApplication/ApplicationUI/saved_job_list.dart';
import '../JobApplication/ApplicationUI/applied_job_list.dart';

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedTab      = 'All';
  String _selectedCategory = 'All Jobs';
  Set<String> _appliedJobs = {};
  Set<String> _savedJobs   = {}; // ✅ track saved job IDs

  static const Color _blue = Color(0xFF3B52E8);

  final List<String> _categories = [
    'All Jobs', 'Design', 'IT', 'Marketing', 'Sales',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
    _loadSavedJobs(); // ✅ load saved on init
  }

  // ── Load applied jobs ────────────────────────────────────────────────────
  Future<void> _loadAppliedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .get();
    if (mounted) {
      setState(() {
        _appliedJobs = snap.docs.map((d) => d['jobId'] as String).toSet();
      });
    }
  }

  // ── Load saved jobs from subcollection ───────────────────────────────────
  Future<void> _loadSavedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedJobs')
        .get();
    if (mounted) {
      setState(() {
        _savedJobs = snap.docs.map((d) => d.id).toSet();
      });
    }
  }

  // ── Toggle save / unsave ─────────────────────────────────────────────────
  // Saves ALL job fields needed by SavedJobsScreen + InterviewPractice
  Future<void> _toggleSave(Job job, Map<String, dynamic> fullData) async {
    final user = FirebaseAuth.instance.currentUser;

    print("DEBUG: Saving job for user: ${user?.uid}"); // Check if this matches Firestore
    print("DEBUG: Job ID being saved: ${job.id}");

    if (user == null) {
      print("DEBUG: No user logged in!");
      return;
    }

    if (job.id == null || job.id!.isEmpty) {
      print('job.id is null or empty — cannot save');
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedJobs')
        .doc(job.id);

    if (_savedJobs.contains(job.id)) {
      // ── Unsave ───────────────────────────────────────────────────────────
      await ref.delete();
      if (mounted) setState(() => _savedJobs.remove(job.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job removed from saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // ── Save — store FULL job data so interview practice can use it ──────
      await ref.set({
        // Basic display fields
        'jobId':     job.id,
        'jobTitle':  job.title,
        'company':   job.company,
        'location':  job.location,
        'workType':  job.workType,
        'workplace': job.workplace,
        'salary':    job.salary,
        'description':     fullData['description']     ?? '',
        'requirements':    fullData['requirements']    ?? '',
        'benefits':        fullData['benefits']        ?? '',
        'experienceLevel': fullData['experienceLevel'] ?? '',
        'educationLevel':  fullData['educationLevel']  ?? '',
        // Metadata
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _savedJobs.add(job.id!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job saved! You can practice interviews from Saved Jobs.'),
          backgroundColor: Color(0xFF3B4FD8),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _parseApplicants(dynamic raw) {
    if (raw == null) return '0 applied';
    if (raw is int) return '$raw applied';
    if (raw is String && raw.isNotEmpty) return raw;
    return '${raw.toString()} applied';
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }

  String _getGreetingEmoji() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return '☀️';
    if (h >= 12 && h < 17) return '🌤️';
    if (h >= 17 && h < 21) return '🌆';
    return '🌙';
  }

  String _getFirstName() {
    final name = widget.user?.displayName ?? '';
    if (name.trim().isEmpty) return 'user';
    return name.trim().split(RegExp(r'\s+')).first;
  }

  String _getTimeAgo(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0)
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0)
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Find Your\nDream Job',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text(_getGreetingEmoji(),
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                '${_getGreeting()}, ${_getFirstName()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('notifications')
                                .where('isRead', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final unread = snapshot.hasData
                                  ? snapshot.data!.docs.length
                                  : 0;
                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                            const JobseekerNotificationsPage()),
                                      ).then((_) {
                                        if (mounted) setState(() {});
                                      });
                                    },
                                    icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.black,
                                        size: 28),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: 8, top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                            minWidth: 16, minHeight: 16),
                                        child: Center(
                                          child: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          Image.asset(
                            'assets/icons/homedeco.png',
                            width: 80, height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 80, height: 80),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for jobs ......',
                        hintStyle: TextStyle(
                            color: Colors.grey[500], fontSize: 14),
                        suffixIcon: Icon(Icons.search,
                            color: Colors.grey[500], size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Recommendations + tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recommendations',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          Row(
                            children: ['All', 'New to you'].map((tab) {
                              final active = _selectedTab == tab;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = tab),
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.black
                                        : Colors.transparent,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active
                                          ? Colors.black
                                          : const Color(0xFFDDDDDD),
                                    ),
                                  ),
                                  child: Text(tab,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? Colors.white
                                            : Colors.black54,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // How it works card
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 17, color: _blue),
                              SizedBox(width: 8),
                              Text('How it works',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87)),
                            ]),
                            const SizedBox(height: 8),
                            const Text(
                              'These matches are generated based on your skills, resume analysis, and past application preferences.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const AiMatchingScreen())),
                              child: Row(children: const [
                                Text('Learn more',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _blue,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: _blue),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category chips
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final active = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 150),
                              margin:
                              const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                active ? _blue : Colors.white,
                                borderRadius:
                                BorderRadius.circular(20),
                                border: Border.all(
                                    color: active
                                        ? _blue
                                        : const Color(0xFFDDDDDD)),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : Colors.black54,
                                  )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job cards from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('jobs')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final now = DateTime.now();
                        final docs =
                        snapshot.data!.docs.where((doc) {
                          final d =
                          doc.data() as Map<String, dynamic>;
                          final pub =
                          (d['publishDate'] as Timestamp?)
                              ?.toDate();
                          if (pub != null && pub.isAfter(now)) {
                            return false;
                          }
                          final exp =
                          (d['expiryDate'] as Timestamp?)
                              ?.toDate();
                          if (exp != null && exp.isBefore(now)) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (docs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No jobs available yet.'),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc  = docs[index];
                            final data =
                            doc.data() as Map<String, dynamic>;

                            final job = Job(
                              id:        doc.id,
                              title:     data['title']     ?? 'Untitled',
                              companyId: data['companyId'] ?? '',
                              company:   data['company']   ?? 'Company',
                              location:  data['location']  ?? '',
                              workType:  data['workType']  ?? 'Full-time',
                              workplace: data['workplace'] ?? 'On-site',
                              salary:    data['salary']    ?? 'Salary not specified',
                              postedTime: data['postedTime'] ?? '',
                              applicants: _parseApplicants(
                                  data['applicants']),
                              createdAt:
                              (data['createdAt'] as Timestamp?)
                                  ?.toDate() ??
                                  DateTime.now(),
                            );

                            final benefits =
                            (data['benefits'] ?? '') as String;
                            final benefitLines = benefits
                                .split('\n')
                                .map((l) => l.trim())
                                .where((l) => l.isNotEmpty)
                                .take(3)
                                .toList();

                            final hasApplied =
                            _appliedJobs.contains(job.id);
                            final isSaved =
                            _savedJobs.contains(job.id);

                            return _jobCard(context, job,
                                benefitLines, hasApplied, isSaved,
                                data); // ✅ pass full data for saving
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SavedJobsScreen()),
            ).then((_) => _loadSavedJobs());
            return;
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AppliedJobsScreen()),
            ).then((_) => _loadAppliedJobs());
            return;
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfilePage(user: widget.user)),
            );
          }
        },
      ),
    );
  }

  Widget _jobCard(
      BuildContext context,
      Job job,
      List<String> benefits,
      bool hasApplied,
      bool isSaved,
      Map<String, dynamic> fullData, // ✅ needed for saving rich fields
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B4FD8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags + bookmark
                Row(children: [
                  _tag(job.workType),
                  const SizedBox(width: 8),
                  _tag(job.workplace),
                  const Spacer(),

                  // ✅ FIXED: bookmark with onTap to save/unsave
                  GestureDetector(
                    onTap: () => _toggleSave(job, fullData),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: isSaved
                            ? const Color(0xFFF5C842)
                            : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isSaved
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Company logo + title
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        job.company.isNotEmpty
                            ? job.company[0].toUpperCase()
                            : 'J',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B4FD8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(job.company,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(job.location,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 4),

                Row(children: [
                  const Icon(Icons.payments_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(job.salary,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),

                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...benefits.map((b) {
                    final text = b.startsWith('•')
                        ? b.substring(1).trim()
                        : b;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                          Expanded(
                            child: Text(text,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Bottom strip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.access_time,
                  size: 13, color: Colors.white60),
              const SizedBox(width: 4),
              Text(_getTimeAgo(job.createdAt),
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.people_outline,
                  size: 13, color: Colors.white60),
              const SizedBox(width: 4),
              Text(job.applicants,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => JobDetailsPage(job: job)),
                  );
                  _loadAppliedJobs();
                  _loadSavedJobs();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasApplied
                        ? const Color(0xFF2CB06A)
                        : const Color(0xFFF0C040),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasApplied ? 'Applied ✓' : 'Apply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasApplied
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    );
  }
}