import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../JobListing/ApplicationUI/create_job_screen.dart';
import '../JobListing/ApplicationUI/job_list_screen.dart';
import '../../../services/job_service.dart';
import '../models/job_model.dart';
import 'employer_profile_screen.dart';

// ==================== JobListScreenWrapper ====================

class JobListScreenWrapper extends StatelessWidget {
  const JobListScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final jobs = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Job(
            id: doc.id,
            title: data['title'] ?? '',
            company: data['company'] ?? '',
            location: data['location'] ?? '',
            workType: data['workType'] ?? '',
            workplace: data['workplace'] ?? '',
            salary: data['salary'] ?? '',
            postedTime: data['postedTime'] ?? '',
            applicants: data['applicants'] ?? '',
            createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        return JobListScreen(jobs: jobs);
      },
    );
  }
}

// ==================== EmployerDashboard ====================

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 0;

  static const Color _primaryBlue = Color(0xFF3B4FD8);

  final List<Map<String, dynamic>> _stats = [
    {
      'value': '0',
      'label': 'Jobs Posted',
      'icon': Icons.assignment_outlined,
      'bg': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE07B39),
    },
    {
      'value': '0',
      'label': 'Applicants',
      'icon': Icons.group_outlined,
      'bg': Color(0xFFF0F2FF),
      'iconColor': Color(0xFF3B4FD8),
    },
    {
      'value': '0',
      'label': 'Jobs Closed',
      'icon': Icons.receipt_long_outlined,
      'bg': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE07B39),
    },
    {
      'value': '0%',
      'label': 'Hired Success',
      'icon': Icons.bar_chart_rounded,
      'bg': Color(0xFFE8FBF0),
      'iconColor': Color(0xFF2CB06A),
    },
    {
      'value': '0',
      'label': 'Upcoming Interviews',
      'icon': Icons.event_note_outlined,
      'bg': Color(0xFFF0F2FF),
      'iconColor': Color(0xFF3B4FD8),
    },
    {
      'value': '0',
      'label': 'Notifications',
      'icon': Icons.notifications_outlined,
      'bg': Color(0xFFFFF0EC),
      'iconColor': Color(0xFFE07B39),
    },
  ];

  void _navigateToCreateJob() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobPage()),
    ).then((_) {
      // ✅ Reset nav highlight to Home when returning from any pushed screen
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  void _navigateToAllJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllJobsListScreen()),
    ).then((_) {
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  void _navigateToJobList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JobListScreenWrapper()),
    ).then((_) {
      // ✅ This is the key fix: when back arrow is pressed on JobListScreen,
      // Flutter pops back to EmployerDashboard and this callback fires,
      // resetting the highlight to Home (index 0).
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        color: _primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'JobBuddy ',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Employer',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final jobs = snapshot.data!.docs;
                  final jobCount = jobs.length;
                  final recentJob = jobs.isNotEmpty ? jobs.first : null;

                  _stats[0]['value'] = jobCount.toString();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        // Search bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search anything here ......',
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
                        const SizedBox(height: 24),

                        const Text('Dashboard',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),

                        // Stats grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _stats.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (_, i) => _buildStatCard(_stats[i]),
                        ),
                        const SizedBox(height: 28),

                        // Recent job post header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent job post',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            GestureDetector(
                              onTap: _navigateToAllJobs,
                              child: Row(
                                children: const [
                                  Text('view all',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54)),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right,
                                      size: 18, color: Colors.black54),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Recent job card
                        if (recentJob != null)
                          _buildRecentJobCard(recentJob)
                        else
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Text(
                                'No jobs posted yet.\nClick + to create one!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: stat['bg'] as Color,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(stat['icon'] as IconData,
                color: stat['iconColor'] as Color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(stat['value'] as String,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(stat['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF888888))),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobCard(QueryDocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled';
    final workType = data['workType'] ?? 'Full-time';
    final workplace = data['workplace'] ?? 'On-site';
    final location = data['location'] ?? 'Location not specified';
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: _primaryBlue, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: _navigateToCreateJob,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTag(workType),
                    const SizedBox(width: 8),
                    _buildTag(workplace),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(location,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(timeAgo,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Check out applicants',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
        Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        selectedLabelStyle:
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        onTap: (index) {
          // ✅ Show highlight immediately for visual feedback
          setState(() => _selectedIndex = index);

          switch (index) {
            case 0:
            // Already on dashboard, do nothing
              break;
            case 1:
            // Push JobListScreen; reset to Home on return
              _navigateToJobList();
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Applications - Coming Soon'),
                    backgroundColor: Colors.orange),
              );
              setState(() => _selectedIndex = 0);
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Interviews - Coming Soon'),
                    backgroundColor: Colors.orange),
              );
              setState(() => _selectedIndex = 0);
              break;
            case 4:
            // Navigate to Employer Profile Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployerProfileScreen()),
              ).then((_) {
                // Reset to Home when returning from profile
                if (mounted) setState(() => _selectedIndex = 0);
              });
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Applications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.star_border_rounded),
              activeIcon: Icon(Icons.star_rounded),
              label: 'Interviews'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ==================== AllJobsListScreen ====================

class AllJobsListScreen extends StatelessWidget {
  const AllJobsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Jobs',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3B4FD8),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snapshot.data!.docs;

          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs created yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final data = job.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle:
                  Text('${data['company']} • ${data['location']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}