import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../../Widgets/nav_bar_widget.dart';
import '../../InterviewPractice/interview_practice_screen.dart';
import 'application_status.dart';
import 'saved_job_list.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({Key? key}) : super(key: key);

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  bool _showWithdrawn = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  // UPDATED: Added 'Newest' as the default time-based sort
  String _sortBy = 'Newest';

  static const Color _cardColor     = Color(0xFF2D3A8C);
  static const Color _cardColorDeep = Color(0xFF1E2A6E);
  static const Color _bg            = Color(0xFFF4F5FA);
  static const Color _blue          = Color(0xFF3B52E8);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shortlisted':  return const Color(0xFF22C55E);
      case 'interview':    return const Color(0xFF8B5CF6);
      case 'unprocessed':  return const Color(0xFFF59E0B);
      case 'under review': return const Color(0xFF60A5FA);
      case 'declined':
      case 'rejected':     return const Color(0xFFEF4444);
      case 'withdrawn':    return const Color(0xFF94A3B8);
      case 'cancelled':    return const Color(0xFFEF4444);
      default:             return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'unprocessed':  return 'PENDING REVIEW';
      case 'shortlisted':  return 'SHORTLISTED';
      case 'interview':    return 'INTERVIEW SCHEDULED';
      case 'under review': return 'UNDER REVIEW';
      case 'declined':
      case 'rejected':     return 'DECLINED';
      case 'withdrawn':    return 'WITHDRAWN';
      case 'cancelled':    return 'CANCELLED';
      default:             return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  bool _isWithdrawn(String s) {
    final status = s.toLowerCase();
    return status == 'withdrawn' || status == 'cancelled';
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return 'Recently';
    final dt   = ts is Timestamp ? ts.toDate() : DateTime.now();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7)   return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0)    return '${diff.inDays}d ago';
    if (diff.inHours > 0)   return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
        title: const Text('My Applied Jobs',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InterviewPracticeJobSelectScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text('Practice', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _tabBtn('Applied Jobs', !_showWithdrawn),
              _tabBtn('Withdrawn',    _showWithdrawn),
            ]),
          ),
        ),

        // Search, Sort, and Status Filter Bar
        _buildAdvancedFilters(),

        Expanded(
          child: user == null
              ? const Center(child: Text('Please log in.'))
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('userId', isEqualTo: user.uid)
                .orderBy('appliedAt', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              List<QueryDocumentSnapshot> docs = snap.data!.docs;

              // 1. Tab Filter
              docs = docs.where((d) {
                final s = ((d.data() as Map)['status'] ?? '').toString();
                return _showWithdrawn ? _isWithdrawn(s) : !_isWithdrawn(s);
              }).toList();

              // 2. Search Filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['jobTitle'] ?? '').toString().toLowerCase();
                  final company = (data['company'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || company.contains(_searchQuery);
                }).toList();
              }

              // 3. Status Filter
              if (_selectedStatusFilter != 'All') {
                docs = docs.where((d) {
                  final s = ((d.data() as Map)['status'] ?? '').toString().toLowerCase();
                  return s == _selectedStatusFilter.toLowerCase();
                }).toList();
              }

              // 4. UPDATED: Sorting Algorithm (Time vs Status)
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                if (_sortBy == 'Newest') {
                  // Primary Sort: appliedAt (Time)
                  final timeA = dataA['appliedAt'] as Timestamp? ?? Timestamp.now();
                  final timeB = dataB['appliedAt'] as Timestamp? ?? Timestamp.now();
                  return timeB.compareTo(timeA);
                } else {
                  // Primary Sort: status (Alphabetical)
                  final statusA = (dataA['status'] ?? '').toString();
                  final statusB = (dataB['status'] ?? '').toString();
                  return statusA.compareTo(statusB);
                }
              });

              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No matching applications.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d    = docs[i].data() as Map<String, dynamic>;
                  final s    = (d['status'] ?? 'unprocessed').toString();
                  final sCol = _statusColor(s);
                  return _card(context, docs[i].id, d, s, sCol);
                },
              );
            },
          ),
        ),
      ]),

      bottomNavigationBar: NavBarWidget(
        currentIndex: 2,
        onTabSelected: (i) {
          if (i == 2) return;
          if (i == 0) Navigator.pop(context);
          else if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SavedJobsScreen()));
          else if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser)));
        },
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    final List<String> statusFilters = ['All', 'Unprocessed', 'Under Review', 'Shortlisted', 'Interview', 'Rejected'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search company...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // UPDATED: Time/Status Sorting Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, size: 18, color: _blue),
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                    items: ['Newest', 'Status'].map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _sortBy = val!),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: statusFilters.map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(status, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: _blue,
                    backgroundColor: _bg,
                    onSelected: (bool selected) {
                      setState(() => _selectedStatusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() {
        _showWithdrawn = (label == 'Withdrawn');
        _selectedStatusFilter = 'All';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: active ? Colors.black : Colors.grey[500])),
      ),
    ),
  );

  Widget _card(BuildContext context, String docId, Map<String, dynamic> d, String status, Color sCol) {
    final title    = d['jobTitle']  ?? 'Unknown Job';
    final company  = d['company']   ?? '';
    final location = d['workplace'] ?? d['location'] ?? '';
    final sLabel   = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_cardColor, _cardColorDeep],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: _cardColorDeep.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.bookmark_border_rounded, color: Colors.white70, size: 17)),
            ]),
            const SizedBox(height: 4),
            Text(company, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            if (location.isNotEmpty) Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text('Applied ${_timeAgo(d['appliedAt'])}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  color: sCol, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: sCol.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
                )),
            const SizedBox(width: 8),
            Text(sLabel, style: TextStyle(color: sCol, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicationStatusScreen(
                        applicationId: docId,
                        applicationData: d
                    ),
                  ),
                );
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Text('View Details',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}