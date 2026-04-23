import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../../l10n/app_localizations.dart';
import '../JobApplication/ApplicationServices/C-B-F_Machine_Learning.dart';
import '../JobApplication/ApplicationUI/job_details_screen.dart';
import '../JobApplication/ApplicationUI/jobseeker_notification_page.dart';
import '../Widgets/nav_bar_widget.dart';
import 'AI_Matching.dart';
import 'jobseeker_profile.dart';
import '../JobApplication/ApplicationUI/saved_job_list.dart';
import '../JobApplication/ApplicationUI/applied_job_list.dart';
import 'jobseeker_search.dart';

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
  Set<String> _savedJobs   = {};

  // ── Content-based filtering ML ───────────────────────────────────────────
  final RecommendationService _recommendationService =
  RecommendationService('AIzaSyD-Yx8hfxWsIbavmxL6Pr3CQhoxqsvgAq0');
  List<JobRecommendation>? _aiRecommendations;
  bool _isAiLoading = false;

  static const Color _blue = Color(0xFF3B52E8);

  final List<String> _categories = [
    'All Jobs', 'Design', 'IT', 'Marketing', 'Sales',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
    _loadSavedJobs();
    _fetchAiRecommendations();
  }

  // ── Fetch AI recommendations ─────────────────────────────────────────────
  Future<void> _fetchAiRecommendations() async {
    if (!mounted) return;
    setState(() => _isAiLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final jobsSnap =
      await FirebaseFirestore.instance.collection('jobs').get();
      final allJobs =
      jobsSnap.docs.map((d) => {...d.data(), 'id': d.id}).toList();

      final results = await _recommendationService.recommendJobs(
        userData: userData,
        allJobs: allJobs,
      );

      if (mounted) {
        setState(() {
          _aiRecommendations = results;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AI Recommendation Error: $e");
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<void> _loadAppliedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (mounted) {
      setState(() {
        _appliedJobs = snap.docs
            .where((doc) {
          final data = doc.data();
          return data['status'] != 'withdrawn';
        })
            .map((d) => d['jobId'] as String)
            .toSet();
      });
    }
  }

  // ── Load saved jobs ──────────────────────────────────────────────────────
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
  Future<void> _toggleSave(Job job, Map<String, dynamic> fullData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (job.id == null || job.id!.isEmpty) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedJobs')
        .doc(job.id);

    if (_savedJobs.contains(job.id)) {
      await ref.delete();
      if (mounted) setState(() => _savedJobs.remove(job.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job removed from saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await ref.set({
        'jobId':           job.id,
        'jobTitle':        job.title,
        'company':         job.company,
        'location':        job.location,
        'workType':        job.workType,
        'workplace':       job.workplace,
        'salary':          job.salary,
        'description':     fullData['description']     ?? '',
        'requirements':    fullData['requirements']    ?? '',
        'benefits':        fullData['benefits']        ?? '',
        'experienceLevel': fullData['experienceLevel'] ?? '',
        'educationLevel':  fullData['educationLevel']  ?? '',
        'savedAt':         FieldValue.serverTimestamp(),
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

  // ── Helpers ──────────────────────────────────────────────────────────────
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    // 1. Initialize l10n
    final l10n = AppLocalizations.of(context);

    // 2. Safety check
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                            Text(
                              l10n.findDreamJob,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(_getGreetingEmoji(),
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Text(
                                  '${_getGreeting()}, ${_getFirstName()}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Notification bell
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
                                  right: 8,
                                  top: 8,
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child:
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JobSearchScreen()),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.searchJobsHint,
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            suffixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
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

                    // ── Recommendations header + tabs ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.recommendationsTitle,
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

                    // ── "How it works" info card ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 17, color: _blue),
                              const SizedBox(width: 8),
                              Text(l10n.howItWorks,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87)),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              l10n.matchingDescription,
                              style: const TextStyle(
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
                              child: Row(children: [
                                Text(l10n.learnMore,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: _blue,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: _blue),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Category chips ────────────────────────────────────
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final active = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? _blue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
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

                    // ── Switch between All Jobs & AI tab ──────────────────
                    _selectedTab == 'New to you'
                        ? _buildAiSection()
                        : _buildAllJobsStream(),

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
              MaterialPageRoute(builder: (_) => const SavedJobsScreen()),
            ).then((_) => _loadSavedJobs());
            return;
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppliedJobsScreen()),
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

  // ── AI section with loading + empty states ────────────────────────────────
  Widget _buildAiSection() {
    if (_isAiLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _blue),
              SizedBox(height: 16),
              Text(
                'Analysing your profile...',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Finding your best matches',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_aiRecommendations == null || _aiRecommendations!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined,
                  size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No AI matches found yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile and upload your resume to get personalised job recommendations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return _buildAiList();
  }

  // ── Firestore stream for All Jobs ─────────────────────────────────────────
  Widget _buildAllJobsStream() {
    return StreamBuilder<QuerySnapshot>(
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
        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;

          final pub = (d['publishDate'] as Timestamp?)?.toDate();
          if (pub != null && pub.isAfter(now)) return false;

          final exp = (d['expiryDate'] as Timestamp?)?.toDate();
          if (exp != null && exp.isBefore(now)) return false;

          if (_selectedCategory != 'All Jobs') {
            final category = (d['category'] ?? '').toString().toLowerCase();
            if (!category.contains(_selectedCategory.toLowerCase())) {
              return false;
            }
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
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc  = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final job = Job(
              id:         doc.id,
              title:      data['title']     ?? 'Untitled',
              companyId:  data['companyId'] ?? '',
              company:    data['company']   ?? 'Company',
              location:   data['location']  ?? '',
              workType:   data['workType']  ?? 'Full-time',
              workplace:  data['workplace'] ?? 'On-site',
              salary:     data['salary']    ?? 'Salary not specified',
              postedTime: data['postedTime'] ?? '',
              applicants: _parseApplicants(data['applicants']),
              createdAt:  (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );

            final benefits = (data['benefits'] ?? '') as String;
            final benefitLines = benefits
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .take(3)
                .toList();

            final hasApplied = _appliedJobs.contains(job.id);
            final isSaved    = _savedJobs.contains(job.id);

            return _jobCard(
                context, job, benefitLines, hasApplied, isSaved, data);
          },
        );
      },
    );
  }

  // ── AI recommendations list ───────────────────────────────────────────────
  Widget _buildAiList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _aiRecommendations!.length,
      itemBuilder: (context, index) {
        final rec  = _aiRecommendations![index];
        final data = rec.jobData;

        final job = Job(
          id:         data['id'],
          title:      data['title']     ?? 'Untitled',
          companyId:  data['companyId'] ?? '',
          company:    data['company']   ?? 'Company',
          location:   data['location']  ?? '',
          workType:   data['workType']  ?? 'Full-time',
          workplace:  data['workplace'] ?? 'On-site',
          salary:     data['salary']    ?? 'N/A',
          postedTime: '',
          applicants: '',
          createdAt:  (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        );

        final matchPercent =
        (rec.similarityScore * 100).toStringAsFixed(0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _matchGradient(rec.similarityScore),
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _matchGradient(rec.similarityScore)
                        .first
                        .withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '$matchPercent% Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _jobCard(
              context,
              job,
              [],
              _appliedJobs.contains(job.id),
              _savedJobs.contains(job.id),
              data,
            ),
          ],
        );
      },
    );
  }

  // ── Match badge gradient based on score ──────────────────────────────────
  List<Color> _matchGradient(double score) {
    if (score >= 0.75) {
      return [const Color(0xFF16A34A), const Color(0xFF22C55E)];
    } else if (score >= 0.5) {
      return [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
    } else {
      return [const Color(0xFFCA8A04), const Color(0xFFEAB308)];
    }
  }

  // ── Job card ─────────────────────────────────────────────────────────────
  Widget _jobCard(
      BuildContext context,
      Job job,
      List<String> benefits,
      bool hasApplied,
      bool isSaved,
      Map<String, dynamic> fullData,
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
                  GestureDetector(
                    onTap: () => _toggleSave(job, fullData),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
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
                        color:
                        isSaved ? const Color(0xFF1A1A2E) : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Company logo + title
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
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
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
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
                    final text =
                    b.startsWith('•') ? b.substring(1).trim() : b;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Expanded(
                            child: Text(text,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.white60),
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  // ── Tag chip ─────────────────────────────────────────────────────────────
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