import 'package:flutter/material.dart';
import '../JobListing/create_job_page.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 0;

  static const Color _primaryBlue = Color(0xFF3B4FD8);

  // Sample recent job post (Figma shows 1 card)
  final Map<String, dynamic> _recentJob = {
    'title': 'Software Tester',
    'tags': ['Full Time', 'Remote'],
    'location': 'Penang, Malaysia',
    'timePosted': 'Posted 2 days ago',
  };

  // Dashboard stats matching Figma
  final List<Map<String, dynamic>> _stats = [
    {
      'value': '254',
      'label': 'Jobs Posted',
      'icon': Icons.assignment_outlined,
      'bg': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE07B39),
    },
    {
      'value': '2545',
      'label': 'Applicants',
      'icon': Icons.group_outlined,
      'bg': Color(0xFFF0F2FF),
      'iconColor': Color(0xFF3B4FD8),
    },
    {
      'value': '220',
      'label': 'Jobs Closed',
      'icon': Icons.receipt_long_outlined,
      'bg': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE07B39),
    },
    {
      'value': '60%',
      'label': 'Hired Success',
      'icon': Icons.bar_chart_rounded,
      'bg': Color(0xFFE8FBF0),
      'iconColor': Color(0xFF2CB06A),
    },
    {
      'value': '12',
      'label': 'Upcoming Interviews',
      'icon': Icons.event_note_outlined,
      'bg': Color(0xFFF0F2FF),
      'iconColor': Color(0xFF3B4FD8),
    },
    {
      'value': '8',
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
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (JobBuddy Employer) ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Logo icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: _primaryBlue,
                      size: 24,
                    ),
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
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'Employer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    // ── Search bar ────────────────────────────────────
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
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Dashboard title ───────────────────────────────
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Stats grid (3 columns × 2 rows) ───────────────
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

                    // ── Recent job post header ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent job post',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: const [
                              Text(
                                'view all',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right,
                                  size: 18, color: Colors.black54),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Recent job card (blue) ────────────────────────
                    _buildRecentJobCard(_recentJob),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom nav bar ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) _navigateToCreateJob();
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Applications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border_rounded),
              activeIcon: Icon(Icons.star_rounded),
              label: 'Interviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat card widget ──────────────────────────────────────────────────
  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat['icon'] as IconData,
              color: stat['iconColor'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stat['value'] as String,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              stat['label'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF888888),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent job card (dark blue) ───────────────────────────────────────
  Widget _buildRecentJobCard(Map<String, dynamic> job) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + edit icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToCreateJob,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tags
                Row(
                  children: (job['tags'] as List<String>).map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      job['location'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Time posted
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      job['timePosted'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Check out applicants row ──────────────────────────────
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Check out applicants',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}