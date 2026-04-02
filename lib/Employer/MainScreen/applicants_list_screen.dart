import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Model ──────────────────────────────────────────────────────────────────
class ApplicantModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String jobLevel;
  final String candidateName;
  final String salary;
  final String education;
  final String workType;
  final String workplace;
  final String status;
  final DateTime appliedAt;

  const ApplicantModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.jobLevel,
    required this.candidateName,
    required this.salary,
    required this.education,
    required this.workType,
    required this.workplace,
    required this.status,
    required this.appliedAt,
  });

  factory ApplicantModel.fromMap(String id, Map<String, dynamic> data) {
    return ApplicantModel(
      id:            id,
      jobId:         data['jobId']         ?? '',
      jobTitle:      data['jobTitle']      ?? 'Untitled',
      jobLevel:      data['jobLevel']      ?? '',
      candidateName: data['candidateName'] ?? 'Unknown',
      salary:        data['salary']        ?? '—',
      education:     data['education']     ?? '—',
      workType:      data['workType']      ?? '',
      workplace:     data['workplace']     ?? '',
      status:        data['status']        ?? 'unprocessed',
      appliedAt:     (data['appliedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN — decides whether to show all jobs or single job applicants
// ══════════════════════════════════════════════════════════════════════════════
class ApplicantsListScreen extends StatelessWidget {
  final String? filterJobId;      // If provided, show only this job's applicants
  final String? filterJobTitle;   // Job title for the app bar

  const ApplicantsListScreen({
    super.key,
    this.filterJobId,
    this.filterJobTitle,
  });

  static const Color _primaryBlue = Color(0xFF3B4FD8);
  static const Color _bgGrey      = Color(0xFFF3F4F8);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textGrey    = Color(0xFF6B7280);

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    // If filtering by a specific job, go directly to applicants for that job
    if (filterJobId != null && filterJobId!.isNotEmpty) {
      return ApplicantsByJobScreen(
        jobId: filterJobId!,
        jobTitle: filterJobTitle ?? 'Job',
      );
    }

    // Otherwise, show all jobs with applicant counts (for Applications tab)
    return _buildAllJobsScreen(context);
  }

  Widget _buildAllJobsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Applications by Job',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, jobSnap) {
          if (jobSnap.hasError) {
            return Center(child: Text('Error: ${jobSnap.error}'));
          }
          if (!jobSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primaryBlue));
          }

          final jobs = jobSnap.data!.docs;

          if (jobs.isEmpty) {
            return _buildEmpty();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .snapshots(),
            builder: (context, appSnap) {
              // Build a map of jobId → applicant count
              final Map<String, int> countMap = {};
              final Map<String, Map<String, int>> statusMap = {};

              if (appSnap.hasData) {
                for (final doc in appSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final jobId = data['jobId'] as String? ?? '';
                  countMap[jobId] = (countMap[jobId] ?? 0) + 1;

                  final status = data['status'] as String? ?? 'unprocessed';
                  statusMap[jobId] ??= {};
                  statusMap[jobId]![status] =
                      (statusMap[jobId]![status] ?? 0) + 1;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: jobs.length,
                itemBuilder: (_, i) {
                  final doc  = jobs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final jobId     = doc.id;
                  final title     = data['title']     ?? 'Untitled';
                  final company   = data['company']   ?? '';
                  final workType  = data['workType']  ?? '';
                  final workplace = data['workplace'] ?? '';
                  final location  = data['location']  ?? '';
                  final createdAt =
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                  final totalApplicants = countMap[jobId] ?? 0;
                  final jobStatuses     = statusMap[jobId] ?? {};

                  return _JobCard(
                    jobId:           jobId,
                    title:           title,
                    company:         company,
                    workType:        workType,
                    workplace:       workplace,
                    location:        location,
                    timeAgo:         _getTimeAgo(createdAt),
                    totalApplicants: totalApplicants,
                    statusCounts:    jobStatuses,
                    onViewApplicants: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicantsByJobScreen(
                            jobId:    jobId,
                            jobTitle: title,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline_rounded,
              size: 60, color: Color(0xFF3B4FD8)),
          SizedBox(height: 16),
          Text('No jobs posted yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          SizedBox(height: 6),
          Text('Create a job to start receiving applications',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

// ── Job Card widget ────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final String jobId;
  final String title;
  final String company;
  final String workType;
  final String workplace;
  final String location;
  final String timeAgo;
  final int totalApplicants;
  final Map<String, int> statusCounts;
  final VoidCallback onViewApplicants;

  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2A3BB8);

  const _JobCard({
    required this.jobId,
    required this.title,
    required this.company,
    required this.workType,
    required this.workplace,
    required this.location,
    required this.timeAgo,
    required this.totalApplicants,
    required this.statusCounts,
    required this.onViewApplicants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue1, _blue2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue1.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tags ──────────────────────────────────────────────
                Row(children: [
                  if (workType.isNotEmpty) _tag(workType),
                  if (workplace.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _tag(workplace),
                  ],
                ]),
                const SizedBox(height: 14),

                // ── Company avatar + title ────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          company.isNotEmpty
                              ? company[0].toUpperCase()
                              : 'J',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _blue1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (company.isNotEmpty)
                            Text(company,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.75))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Location + time ───────────────────────────────────
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                  const Icon(Icons.access_time,
                      size: 13, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(timeAgo,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ]),
                const SizedBox(height: 14),

                // ── Applicant count + status badges ───────────────────
                Row(children: [
                  const Icon(Icons.people_outline,
                      size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    '$totalApplicants applicant${totalApplicants != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
                if (statusCounts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: statusCounts.entries.map((e) {
                      return _statusBadge(e.key, e.value);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Bottom strip — View Applicants button ──────────────────
          GestureDetector(
            onTap: onViewApplicants,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Applicants',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C842),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Open',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _statusBadge(String status, int count) {
    const colors = {
      'unprocessed': Color(0xFFEF6C00),
      'shortlisted': Color(0xFF1565C0),
      'interview':   Color(0xFF2E7D32),
      'declined':    Color(0xFFC62828),
    };
    final color = colors[status] ?? Colors.grey;
    final label = '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — Applicants filtered by job (with status filter chips)
// ══════════════════════════════════════════════════════════════════════════════
class ApplicantsByJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplicantsByJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplicantsByJobScreen> createState() => _ApplicantsByJobScreenState();
}

class _ApplicantsByJobScreenState extends State<ApplicantsByJobScreen> {
  static const Color _primaryBlue = Color(0xFF3B4FD8);
  static const Color _bgGrey      = Color(0xFFF3F4F8);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textGrey    = Color(0xFF6B7280);

  String _selectedFilter = 'all';
  String _searchQuery    = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ApplicantModel> _filtered(List<ApplicantModel> all) {
    var list = all;
    if (_selectedFilter != 'all') {
      list = list.where((a) => a.status == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) => a.candidateName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Map<String, int> _counts(List<ApplicantModel> all) {
    final m = <String, int>{};
    for (final a in all) {
      m[a.status] = (m[a.status] ?? 0) + 1;
    }
    return m;
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(id)
        .update({'status': status});
  }

  void _showStatusSheet(ApplicantModel a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusSheet(
        applicant: a,
        onSelected: (status) async {
          Navigator.pop(context);
          await _updateStatus(a.id, status);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${a.candidateName} moved to ${status[0].toUpperCase()}${status.substring(1)}'),
              backgroundColor: _primaryBlue,
              duration: const Duration(seconds: 2),
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.jobTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16),
            ),
            const Text(
              'Applicants',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('jobId', isEqualTo: widget.jobId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primaryBlue));
          }

          final all = snap.data!.docs
              .map((d) =>
              ApplicantModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          final counts   = _counts(all);
          final filtered = _filtered(all);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search candidates ......',
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
              ),

              // ── Filter by label ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Filter by',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────
              _buildFilterChips(counts),
              const SizedBox(height: 14),

              // ── Result count ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${filtered.length} applicant${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _textGrey,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),

              // ── Cards list ───────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ApplicantCard(
                    applicant: filtered[i],
                    onViewDetails: () =>
                        _showStatusSheet(filtered[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(Map<String, int> counts) {
    final filters = [
      {'key': 'unprocessed', 'label': 'Unprocessed',
        'count': counts['unprocessed'] ?? 0},
      {'key': 'shortlisted',  'label': 'Shortlisted',
        'count': counts['shortlisted']  ?? 0},
      {'key': 'interview',    'label': 'Interview',
        'count': counts['interview']    ?? 0},
      {'key': 'declined',     'label': 'Declined',
        'count': counts['declined']     ?? 0},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final key    = filters[i]['key'] as String;
          final label  = filters[i]['label'] as String;
          final count  = filters[i]['count'] as int;
          final active = _selectedFilter == key;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedFilter = active ? 'all' : key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? _primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: active
                    ? [
                  BoxShadow(
                      color: _primaryBlue.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
                    : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _textGrey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 40, color: _primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text('No applicants found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'all'
                ? 'No one has applied to this job yet'
                : 'No applicants in this category',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _textGrey),
          ),
        ],
      ),
    );
  }
}

// ── Applicant Card ──────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final ApplicantModel applicant;
  final VoidCallback onViewDetails;

  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2A3BB8);

  const _ApplicantCard({
    required this.applicant,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue1, _blue2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue1.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tags + bookmark ──────────────────────────────────────
            Row(children: [
              if (applicant.workType.isNotEmpty) _tag(applicant.workType),
              if (applicant.workplace.isNotEmpty) ...[
                const SizedBox(width: 8),
                _tag(applicant.workplace),
              ],
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bookmark_outline_rounded,
                    color: Colors.white, size: 18),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Candidate name ───────────────────────────────────────
            Text(
              applicant.candidateName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            if (applicant.jobLevel.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(applicant.jobLevel,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75))),
            ],
            const SizedBox(height: 12),

            // ── Status chip ──────────────────────────────────────────
            _statusChip(applicant.status),
            const SizedBox(height: 10),

            // ── Salary + education ───────────────────────────────────
            Row(children: [
              const Text('\$ ',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(applicant.salary,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 20),
              Icon(Icons.school_outlined,
                  size: 15, color: Colors.white.withOpacity(0.75)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(applicant.education,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 16),

            // ── View details button ──────────────────────────────────
            GestureDetector(
              onTap: onViewDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C842),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    const colors = {
      'unprocessed': Color(0xFFEF6C00),
      'shortlisted': Color(0xFF1565C0),
      'interview':   Color(0xFF2E7D32),
      'declined':    Color(0xFFC62828),
    };
    final color = colors[status] ?? Colors.grey;
    final label = '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    );
  }
}

// ── Status Bottom Sheet ─────────────────────────────────────────────────────
class _StatusSheet extends StatelessWidget {
  final ApplicantModel applicant;
  final ValueChanged<String> onSelected;

  static const Map<String, Color> _statusColor = {
    'unprocessed': Color(0xFFEF6C00),
    'shortlisted': Color(0xFF1565C0),
    'interview':   Color(0xFF2E7D32),
    'declined':    Color(0xFFC62828),
  };
  static const Map<String, Color> _statusBg = {
    'unprocessed': Color(0xFFFFF3E0),
    'shortlisted': Color(0xFFE3F2FD),
    'interview':   Color(0xFFE8F5E9),
    'declined':    Color(0xFFFFEBEE),
  };

  const _StatusSheet({required this.applicant, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'unprocessed', 'label': 'Unprocessed',
        'icon': Icons.hourglass_empty_rounded,
        'desc': 'Move back to unprocessed queue'},
      {'key': 'shortlisted', 'label': 'Shortlisted',
        'icon': Icons.star_outline_rounded,
        'desc': 'Candidate looks promising'},
      {'key': 'interview',   'label': 'Interview',
        'icon': Icons.video_call_outlined,
        'desc': 'Schedule an interview'},
      {'key': 'declined',    'label': 'Declined',
        'icon': Icons.cancel_outlined,
        'desc': 'Not suitable for this role'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Update Status',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('${applicant.candidateName} · ${applicant.jobTitle}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          ...statuses.map((s) {
            final key      = s['key'] as String;
            final isActive = applicant.status == key;
            final sColor   = _statusColor[key]!;
            final sBg      = _statusBg[key]!;
            return GestureDetector(
              onTap: () => onSelected(key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? sBg : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isActive ? sColor : Colors.grey[200]!,
                      width: isActive ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? sColor.withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s['icon'] as IconData,
                        size: 18,
                        color: isActive ? sColor : Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['label'] as String,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? sColor
                                    : const Color(0xFF1A1A2E))),
                        Text(s['desc'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle_rounded,
                        color: sColor, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}