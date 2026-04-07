import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../../Widgets/nav_bar_widget.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({Key? key}) : super(key: key);

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  int _navIndex = 2;
  bool _showWithdrawn = false;

  static const Color _cardColor      = Color(0xFF2D3A8C);
  static const Color _cardColorDeep  = Color(0xFF1E2A6E);
  static const Color _blue           = Color(0xFF3B52E8);
  static const Color _navBlue        = Color(0xFF3B52E8);
  static const Color _bg             = Color(0xFFF4F5FA);

  // ── Status helpers ───────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shortlisted':  return const Color(0xFF22C55E);
      case 'pending review':
      case 'unprocessed':  return const Color(0xFFF59E0B);
      case 'under review': return const Color(0xFF60A5FA);
      case 'rejected':     return const Color(0xFFEF4444);
      case 'withdrawn':    return const Color(0xFF94A3B8);
      default:             return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'unprocessed':  return 'PENDING REVIEW';
      case 'shortlisted':  return 'SHORTLISTED';
      case 'under review': return 'UNDER REVIEW';
      case 'rejected':     return 'REJECTED';
      case 'withdrawn':    return 'WITHDRAWN';
      default:             return status.toUpperCase();
    }
  }

  bool _isWithdrawn(String status) =>
      status.toLowerCase() == 'withdrawn';

  String _timeAgo(dynamic appliedAt) {
    if (appliedAt == null) return 'Recently';
    DateTime dt;
    if (appliedAt is Timestamp) {
      dt = appliedAt.toDate();
    } else {
      return appliedAt.toString();
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7)    return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
    if (diff.inDays > 0)     return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0)    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0)  return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
          'My Applied Jobs',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Tab toggle ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _tabBtn('Applied Jobs', !_showWithdrawn),
                  _tabBtn('Withdrawned', _showWithdrawn),
                ],
              ),
            ),
          ),

          // ── Job list ──────────────────────────────────────────────────
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in to see applications.'))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('appliedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!.docs;

                // Filter by tab
                final docs = all.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString();
                  return _showWithdrawn
                      ? _isWithdrawn(status)
                      : !_isWithdrawn(status);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_off_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          _showWithdrawn
                              ? 'No withdrawn applications.'
                              : 'No applications yet.\nStart applying!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    return _jobCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 2, // This screen is the 'Applied' tab
        onTabSelected: (index) {
          if (index == 2) return; // Stay here if already on Applied

          // Navigation Logic:
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            //TODO: Saved job route
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser)),
            );
          }
        },
      ),
    );
  }

  // ── Tab button ───────────────────────────────────────────────────────────

  Widget _tabBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showWithdrawn = label == 'Withdrawn'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.black : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  // ── Job card ─────────────────────────────────────────────────────────────

  Widget _jobCard(Map<String, dynamic> data) {
    final title     = data['jobTitle']  ?? 'Unknown Job';
    final company   = data['company']   ?? '';
    final location  = data['workplace'] ?? data['location'] ?? '';
    final appliedAt = data['appliedAt'];
    final status    = (data['status']   ?? 'unprocessed').toString();

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final showViewDetails = status.toLowerCase() != 'shortlisted' &&
        status.toLowerCase() != 'withdrawn';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardColor, _cardColorDeep],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _cardColorDeep.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card body ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + bookmark
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          color: Colors.white70, size: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Company
                Text(company,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),

                // Location
                if (location.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(location,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]),
                const SizedBox(height: 4),

                // Applied time
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text('Applied ${_timeAgo(appliedAt)}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ]),
              ],
            ),
          ),

          // ── Status strip ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Status dot + label
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: statusColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),

                // View Details button (not shown for Shortlisted)
                if (showViewDetails)
                  GestureDetector(
                    onTap: () {
                      // TODO: navigate to application detail page
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav2() {
    final items = [
      {'icon': Icons.home_outlined,           'active': Icons.home_rounded,      'label': 'Home'},
      {'icon': Icons.bookmark_border_outlined, 'active': Icons.bookmark_rounded,  'label': 'Saved'},
      {'icon': Icons.work_outline,             'active': Icons.work_rounded,      'label': 'Applied'},
      {'icon': Icons.person_outline,           'active': Icons.person_rounded,    'label': 'Profile'},
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
                onTap: () => setState(() => _navIndex = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                          ? items[i]['active'] as IconData
                          : items[i]['icon'] as IconData,
                      size: 24,
                      color: active ? _navBlue : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        active ? FontWeight.w700 : FontWeight.normal,
                        color: active ? _navBlue : const Color(0xFF94A3B8),
                      ),
                    ),
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