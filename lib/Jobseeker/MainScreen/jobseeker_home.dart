import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Employer/models/job_model.dart';
import '../JobApplication/ApplicationUI/job_details_screen.dart';
import '../JobApplication/ApplicationServices/apply_job_service.dart';
import 'jobseeker_profile.dart';

class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;
  String _selectedTab = 'All';
  String _selectedCategory = 'All Jobs';
  Set<String> _appliedJobs = {};

  static const Color _blue = Color(0xFF3B52E8);

  final List<String> _categories = [
    'All Jobs',
    'Design',
    'IT',
    'Marketing',
    'Sales',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  Future<void> _loadAppliedJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final applications = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .get();
    setState(() {
      _appliedJobs =
          applications.docs.map((doc) => doc['jobId'] as String).toSet();
    });
  }

  String _parseApplicants(dynamic raw) {
    if (raw == null) return '0 applied';
    if (raw is int) return '$raw applied';
    if (raw is String && raw.isNotEmpty) return raw;
    return '${raw.toString()} applied';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️';
    if (hour >= 12 && hour < 17) return '🌤️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }

  String _getFirstName() {
    final displayName = widget.user?.displayName ?? '';
    if (displayName.trim().isEmpty) return 'there';
    return displayName.trim().split(RegExp(r'\s+')).first;
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

  Future<void> _handleApply(String jobId, String jobTitle) async {
    if (_appliedJobs.contains(jobId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already applied for this job.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Applying...'),
      duration: Duration(seconds: 1),
    ));
    final success = await ApplyJobService.applyForJob(jobId: jobId);
    if (mounted) {
      if (success) {
        setState(() => _appliedJobs.add(jobId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Applied to $jobTitle!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to apply. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero Header ──────────────────────────────────────────
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
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Find Your\n',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Dream Job',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/icons/homedeco.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 130, height: 130),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for jobs ......',
                        hintStyle:
                        TextStyle(color: Colors.grey[500], fontSize: 14),
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

            // ── Scrollable Body ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Recommendations header + tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recommendations',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          Row(
                            children: ['All', 'New to you'].map((tab) {
                              final active = _selectedTab == tab;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = tab),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.black
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
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
                              'These matches are generated based on your skills, resume analysis, and past application preferences to find your perfect fit.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            Row(children: const [
                              Text('Learn more',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _blue,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: _blue),
                            ]),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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

                    // ── Job cards with publish/expiry filtering ────────
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

                        // ── Filter: only show live jobs ─────────────────
                        final docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          // Hide if publishDate is in the future (scheduled)
                          final publishDate =
                          (data['publishDate'] as Timestamp?)?.toDate();
                          if (publishDate != null &&
                              publishDate.isAfter(now)) {
                            return false;
                          }

                          // Hide if expiryDate has already passed (expired)
                          final expiryDate =
                          (data['expiryDate'] as Timestamp?)?.toDate();
                          if (expiryDate != null &&
                              expiryDate.isBefore(now)) {
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
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data =
                            doc.data() as Map<String, dynamic>;

                            final job = Job(
                              id: doc.id,
                              title: data['title'] ?? 'Untitled',
                              company: data['company'] ?? 'Company',
                              location: data['location'] ?? '',
                              workType: data['workType'] ?? 'Full-time',
                              workplace: data['workplace'] ?? 'On-site',
                              salary: data['salary'] ??
                                  'Salary not specified',
                              postedTime: data['postedTime'] ?? '',
                              applicants:
                              _parseApplicants(data['applicants']),
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

                            return _jobCard(
                                context, job, benefitLines, hasApplied);
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _jobCard(BuildContext context, Job job, List<String> benefits,
      bool hasApplied) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailsPage(job: job)),
      ),
      child: Container(
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
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          color: Colors.white, size: 18),
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

                  // Location
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

                  // Salary
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

                  // Benefits
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
                  onTap: () => _handleApply(job.id!, job.title),
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
                        color: hasApplied ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
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

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.bookmark_border_outlined, 'active': Icons.bookmark_rounded, 'label': 'Saved'},
      {'icon': Icons.work_outline, 'active': Icons.work_rounded, 'label': 'Applied'},
      {'icon': Icons.person_outline, 'active': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = _navIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _navIndex = i);
                  if (i == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfilePage(user: widget.user)),
                    ).then((_) => setState(() => _navIndex = 0));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                          ? items[i]['active'] as IconData
                          : items[i]['icon'] as IconData,
                      size: 24,
                      color: active ? _blue : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                          active ? FontWeight.w700 : FontWeight.normal,
                          color: active ? _blue : const Color(0xFF94A3B8),
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}