import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../services/fcm_service.dart'; // ✅ Add this

// ── Model ──────────────────────────────────────────────────────────────────
class ApplicantModel {
  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String jobLevel;
  final String candidateName;
  final String candidateEmail;
  final String salary;
  final String education;
  final String experienceLevel;
  final String workType;
  final String workplace;
  final String status;
  final String coverLetter;
  final String portfolioUrl;
  final String resume;          // base64 image string
  final List<String> skills;
  final DateTime appliedAt;

  const ApplicantModel({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.jobTitle,
    required this.jobLevel,
    required this.candidateName,
    required this.candidateEmail,
    required this.salary,
    required this.education,
    required this.experienceLevel,
    required this.workType,
    required this.workplace,
    required this.status,
    required this.coverLetter,
    required this.portfolioUrl,
    required this.resume,
    required this.skills,
    required this.appliedAt,
  });

  factory ApplicantModel.fromMap(String id, Map<String, dynamic> data) {
    return ApplicantModel(
      id:              id,
      userId:          data['userId']         ?? '',
      jobId:           data['jobId']          ?? '',
      jobTitle:        data['jobTitle']        ?? 'Untitled',
      jobLevel:        data['jobLevel']        ?? '',
      candidateName:   data['candidateName']   ?? 'Unknown',
      candidateEmail:  data['candidateEmail']  ?? '',
      salary:          data['salary']          ?? '—',
      education:       data['education']       ?? '—',
      experienceLevel: data['experienceLevel'] ?? '—',
      workType:        data['workType']        ?? '',
      workplace:       data['workplace']       ?? '',
      status:          data['status']          ?? 'unprocessed',
      coverLetter:     data['coverLetter']     ?? '',
      portfolioUrl:    data['portfolioUrl']    ?? '',
      resume:          data['resume']          ?? '',
      skills:          List<String>.from(data['skills'] ?? []),
      appliedAt:       (data['appliedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ApplicantsListScreen extends StatelessWidget {
  final String? filterJobId;
  final String? filterJobTitle;
  final String? employerId;

  const ApplicantsListScreen({
    super.key,
    this.filterJobId,
    this.filterJobTitle,
    this.employerId,
  });

  static const Color _primaryBlue = Color(0xFF3B4FD8);
  static const Color _bgGrey      = Color(0xFFF3F4F8);

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (filterJobId != null && filterJobId!.isNotEmpty) {
      return ApplicantsByJobScreen(jobId: filterJobId!, jobTitle: filterJobTitle ?? 'Job');
    }
    return _buildAllJobsScreen(context);
  }

  Widget _buildAllJobsScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // If for some reason it's null, show a placeholder or loader
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(l10n.appsByJobTitle,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: employerId != null && employerId!.isNotEmpty
            ? FirebaseFirestore.instance
            .collection('jobs')
            .where('employerId', isEqualTo: employerId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            : FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, jobSnap) {
          if (jobSnap.hasError) return Center(child: Text('Error: ${jobSnap.error}'));
          if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator(color: _primaryBlue));
          final jobs = jobSnap.data!.docs;
          if (jobs.isEmpty) return _buildEmpty();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('applications').snapshots(),
            builder: (context, appSnap) {
              final Map<String, int> countMap = {};
              final Map<String, Map<String, int>> statusMap = {};
              if (appSnap.hasData) {
                for (final doc in appSnap.data!.docs) {
                  final data  = doc.data() as Map<String, dynamic>;
                  final jobId = data['jobId'] as String? ?? '';
                  countMap[jobId] = (countMap[jobId] ?? 0) + 1;
                  final status = data['status'] as String? ?? 'unprocessed';
                  statusMap[jobId] ??= {};
                  statusMap[jobId]![status] = (statusMap[jobId]![status] ?? 0) + 1;
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
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return _JobCard(
                    jobId: jobId, title: title, company: company,
                    workType: workType, workplace: workplace, location: location,
                    timeAgo: _getTimeAgo(createdAt),
                    totalApplicants: countMap[jobId] ?? 0,
                    statusCounts: statusMap[jobId] ?? {},
                    onViewApplicants: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ApplicantsByJobScreen(jobId: jobId, jobTitle: title))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.work_outline_rounded, size: 60, color: Color(0xFF3B4FD8)),
      SizedBox(height: 16),
      Text('No jobs posted yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      SizedBox(height: 6),
      Text('Create a job to start receiving applications',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
    ]),
  );
}

// ── Job Card ───────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final String jobId, title, company, workType, workplace, location, timeAgo;
  final int totalApplicants;
  final Map<String, int> statusCounts;
  final VoidCallback onViewApplicants;

  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2A3BB8);

  const _JobCard({
    required this.jobId, required this.title, required this.company,
    required this.workType, required this.workplace, required this.location,
    required this.timeAgo, required this.totalApplicants,
    required this.statusCounts, required this.onViewApplicants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue1, _blue2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _blue1.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (workType.isNotEmpty) _tag(workType),
            if (workplace.isNotEmpty) ...[const SizedBox(width: 8), _tag(workplace)],
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(company.isNotEmpty ? company[0].toUpperCase() : 'J',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _blue1)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
              if (company.isNotEmpty) Text(company, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(child: Text(location, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            const Icon(Icons.access_time, size: 13, color: Colors.white60),
            const SizedBox(width: 4),
            Text(timeAgo, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.people_outline, size: 15, color: Colors.white70),
            const SizedBox(width: 6),
            Text('$totalApplicants applicant${totalApplicants != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          if (statusCounts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: statusCounts.entries.map((e) => _statusBadge(e.key, e.value)).toList()),
          ],
        ])),
        GestureDetector(
          onTap: onViewApplicants,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('View Applicants', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF5C842), borderRadius: BorderRadius.circular(20)),
                child: const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
  );

  Widget _statusBadge(String status, int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Text('${status[0].toUpperCase()}${status.substring(1)}: $count',
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — Applicants by job
// ══════════════════════════════════════════════════════════════════════════════
class ApplicantsByJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  const ApplicantsByJobScreen({super.key, required this.jobId, required this.jobTitle});

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
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<ApplicantModel> _filtered(List<ApplicantModel> all) {
    var list = all;
    if (_selectedFilter != 'all') list = list.where((a) => a.status == _selectedFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) => a.candidateName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Map<String, int> _counts(List<ApplicantModel> all) {
    final m = <String, int>{};
    for (final a in all) m[a.status] = (m[a.status] ?? 0) + 1;
    return m;
  }

  Future<void> _updateStatus(ApplicantModel a, String status) async {
    await FirebaseFirestore.instance.collection('applications').doc(a.id).update({'status': status});

    if (a.userId.isNotEmpty) {
      String title = '';
      String body  = '';
      ApplicationStatus? fcmStatus;

      // Add 'hired' to your check
      if (status == 'shortlisted') {
        fcmStatus = ApplicationStatus.shortlisted;
      } else if (status == 'declined') {
        fcmStatus = ApplicationStatus.rejected;
      } else if (status == 'interview') {
        fcmStatus = ApplicationStatus.interview;
      } else if (status == 'hired') {
        // Assuming you add 'hired' to your ApplicationStatus enum
        title = "Congratulations! 🥳";
        body = "You have been hired for the ${a.jobTitle} position!";
      }

      if (fcmStatus != null || status == 'hired') {
        title = title.isEmpty ? fcmStatus!.notificationTitle(a.jobTitle) : title;
        body  = body.isEmpty ? fcmStatus!.notificationBody(a.candidateName, a.jobTitle) : body;

        // In-app Notification
        await FirebaseFirestore.instance
            .collection('users').doc(a.userId)
            .collection('notifications').add({
          'applicationId': a.id,
          'title': title,
          'body': body,
          'type': status == 'hired' ? 'hired' : fcmStatus!.firestoreValue,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Push Notification
        await FCMService().sendPushNotification(
          recipientId: a.userId,
          title: title,
          body: body,
          data: {'type': status, 'applicationId': a.id},
        );
      }
    }
  }

  void _showStatusSheet(ApplicantModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusSheet(
        applicant: a,
        onSelected: (status) async {
          Navigator.pop(context);
          await _updateStatus(a, status);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text('${a.candidateName} moved to ${status[0].toUpperCase()}${status.substring(1)}'),
               backgroundColor: _primaryBlue,
               duration: const Duration(seconds: 2),
            ));
          }
        },
      ),
    );
  }

  void _openApplicantDetail(ApplicantModel a) {

    //if (a.status == 'unprocessed') {
    //  _updateStatus(a, 'under review');
    //}

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ApplicantDetailScreen(
                applicant: a, onStatusUpdate: _updateStatus
            ),
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
          const Text('Applicants', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('applications').where('jobId', isEqualTo: widget.jobId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _primaryBlue));
          final all      = snap.data!.docs.map((d) => ApplicantModel.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
          final counts   = _counts(all);
          final filtered = _filtered(all);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFFF0F1F7), borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search candidates ......',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    suffixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Filter by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
            ),
            _buildFilterChips(counts),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${filtered.length} applicant${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: _textGrey, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _ApplicantCard(
                  applicant:     filtered[i],
                  onViewDetails: () => _showStatusSheet(filtered[i]),
                  onViewProfile: () => _openApplicantDetail(filtered[i]),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildFilterChips(Map<String, int> counts) {
    final filters = [
      {'key': 'unprocessed', 'label': 'Unprocessed',   'count': counts['unprocessed']  ?? 0},
      {'key': 'under review', 'label': 'Under Review', 'count': counts['under review'] ?? 0},
      {'key': 'shortlisted',  'label': 'Shortlisted',  'count': counts['shortlisted']  ?? 0},
      {'key': 'interview',    'label': 'Interview',    'count': counts['interview']    ?? 0},
      {'key': 'hired',        'label': 'Hire Now',     'count': counts['hire']         ?? 0},
      {'key': 'declined',     'label': 'Declined',     'count': counts['declined']     ?? 0},
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
            onTap: () => setState(() => _selectedFilter = active ? 'all' : key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF3B4FD8) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: active
                    ? [BoxShadow(color: const Color(0xFF3B4FD8).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text('$label ($count)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : const Color(0xFF6B7280))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80,
        decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF3B4FD8))),
    const SizedBox(height: 16),
    const Text('No applicants found',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
    const SizedBox(height: 6),
    Text(
      _selectedFilter == 'all' ? 'No one has applied to this job yet' : 'No applicants in this category',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
    ),
  ]));
}

// ── Applicant Card ──────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final ApplicantModel applicant;
  final VoidCallback onViewDetails;
  final VoidCallback onViewProfile;

  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2A3BB8);

  const _ApplicantCard({
    required this.applicant,
    required this.onViewDetails,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue1, _blue2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _blue1.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Tags + bookmark
          Row(children: [
            if (applicant.workType.isNotEmpty) _tag(applicant.workType),
            if (applicant.workplace.isNotEmpty) ...[const SizedBox(width: 8), _tag(applicant.workplace)],
            const Spacer(),
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bookmark_outline_rounded, color: Colors.white, size: 18)),
          ]),
          const SizedBox(height: 14),

          // Name + email + experience
          Text(applicant.candidateName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
          if (applicant.candidateEmail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(applicant.candidateEmail, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.70))),
          ],
          if (applicant.experienceLevel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(applicant.experienceLevel, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
          ],
          const SizedBox(height: 12),

          // Status chip
          _statusChip(applicant.status),
          const SizedBox(height: 10),

          // Salary + education
          Row(children: [
            const Text('💰 ', style: TextStyle(fontSize: 13)),
            Flexible(child: Text(applicant.salary,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 16),
            Icon(Icons.school_outlined, size: 15, color: Colors.white.withOpacity(0.75)),
            const SizedBox(width: 6),
            Expanded(child: Text(applicant.education,
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                overflow: TextOverflow.ellipsis)),
          ]),

          // Skills preview
          if (applicant.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6,
                children: applicant.skills.take(4).map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                )).toList()),
          ],
          const SizedBox(height: 16),

          // Two action buttons
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: onViewProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('View Profile',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3B4FD8)))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: onViewDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF5C842), borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('Update Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _statusChip(String status) {
    final label = '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// APPLICANT DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ApplicantDetailScreen extends StatefulWidget {
  final ApplicantModel applicant;
  final Future<void> Function(ApplicantModel a, String status) onStatusUpdate;

  const ApplicantDetailScreen({super.key, required this.applicant, required this.onStatusUpdate});

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  static const Color _primaryBlue = Color(0xFF3B4FD8);
  static const Color _bgGrey      = Color(0xFFF3F4F8);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textGrey    = Color(0xFF6B7280);

  late String _currentStatus;

  static const Map<String, Color> _statusColor = {
    'unprocessed': Color(0xFFEF6C00),
    'under review': Color(0xFF9C27B0),
    'shortlisted': Color(0xFF1565C0),
    'interview':   Color(0xFF2E7D32),
    'hired':       Color(0xFF16A34A),
    'declined':    Color(0xFFC62828),
  };
  static const Map<String, Color> _statusBg = {
    'unprocessed': Color(0xFFFFF3E0),
    'under review': Color(0xFFF3E5F5),
    'shortlisted': Color(0xFFE3F2FD),
    'interview':   Color(0xFFE8F5E9),
    'hired':       Color(0xFFDCFCE7),
    'declined':    Color(0xFFFFEBEE),
  };

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.applicant.status;
  }

  void _showStatusPicker() {
    final statuses = [
      {'key': 'unprocessed', 'label': 'Unprocessed', 'icon': Icons.hourglass_empty_rounded, 'desc': 'Move back to unprocessed queue'},
      {'key': 'under review', 'label': 'Under Review', 'icon': Icons.visibility_outlined, 'desc': 'Currently reviewing details'},
      {'key': 'shortlisted',  'label': 'Shortlisted',  'icon': Icons.star_outline_rounded,    'desc': 'Candidate looks promising'},
      {'key': 'interview',    'label': 'Interview',    'icon': Icons.video_call_outlined,      'desc': 'Schedule an interview'},
      {'key': 'hired',        'label': 'Hire Now',     'icon': Icons.check_circle_rounded, 'desc': 'Offer employment!'},
      {'key': 'declined',     'label': 'Declined',     'icon': Icons.cancel_outlined,          'desc': 'Not suitable for this role'},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take more space
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        // Use ConstrainedBox to prevent the sheet from being too small/too big
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Wrap with Expanded and ListView to fix Overflow
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: statuses.map((s) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _statusBg[s['key']], borderRadius: BorderRadius.circular(8)),
                      child: Icon(s['icon'] as IconData, color: _statusColor[s['key']], size: 20),
                    ),
                    title: Text(s['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s['desc'] as String, style: const TextStyle(fontSize: 12)),
                    onTap: () async {
                      Navigator.pop(context);
                      await widget.onStatusUpdate(widget.applicant, s['key'] as String);
                      if (mounted) setState(() => _currentStatus = s['key'] as String);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a      = widget.applicant;
    final sColor = _statusColor[_currentStatus] ?? Colors.grey;

    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(slivers: [
        // ── Sliver App Bar ───────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: _primaryBlue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B4FD8), Color(0xFF2A3BB8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(a.candidateName.isNotEmpty ? a.candidateName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.candidateName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (a.candidateEmail.isNotEmpty)
                        Text(a.candidateEmail, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.80))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text('${_currentStatus[0].toUpperCase()}${_currentStatus.substring(1)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ])),
                  ]),
                ]),
              )),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Application Info
            _sectionTitle('Application Info'),
            const SizedBox(height: 12),
            _infoCard([
              _infoRow(Icons.work_outline,             'Job Title',    a.jobTitle),
              _infoRow(Icons.business_center_outlined, 'Work Type',    a.workType),
              _infoRow(Icons.location_on_outlined,      'Workplace',    a.workplace),
              _infoRow(Icons.attach_money_rounded,      'Salary',       a.salary),
              _infoRow(Icons.school_outlined,           'Education',    a.education),
              _infoRow(Icons.timeline_outlined,         'Experience',   a.experienceLevel),
              _infoRow(Icons.calendar_today_outlined,   'Applied',
                  '${a.appliedAt.day}/${a.appliedAt.month}/${a.appliedAt.year}'),
            ]),

            // Skills
            if (a.skills.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Skills'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                  children: a.skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(20)),
                    child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  )).toList()),
            ],

            // Cover Letter
            if (a.coverLetter.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Cover Letter'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(a.coverLetter,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.6)),
              ),
            ],

            // Portfolio URL
            if (a.portfolioUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('Portfolio'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.link_rounded, color: _primaryBlue, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a.portfolioUrl,
                      style: const TextStyle(fontSize: 13, color: _primaryBlue, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],

// CV / Resume
            if (a.resume.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle('CV / Resume'),
              const SizedBox(height: 12),
              _CvViewer(
                base64Image: () {
                  // 1. Remove filename prefix (text before the colon)
                  String raw = a.resume.contains(':') ? a.resume.split(':').last : a.resume;

                  // 2. Remove Data URI prefix (text before the comma, e.g., data:image/png;base64,)
                  if (raw.contains(',')) raw = raw.split(',').last;

                  // 3. Final safety: Remove any whitespace, newlines, or tabs
                  return raw.replaceAll(RegExp(r'\s+'), '');
                }(),
              ),
            ],

            // Update Status button
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showStatusPicker,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Update Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)));

  Widget _infoCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Icon(icon, size: 18, color: _primaryBlue),
      const SizedBox(width: 12),
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
    ]),
  );
}

// ── CV Viewer ──────────────────────────────────────────────────────────────
class _CvViewer extends StatelessWidget {
  final String base64Image;
  const _CvViewer({required this.base64Image});

  @override
  Widget build(BuildContext context) {
    try {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      );
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text("Could not load resume", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CvViewerState extends State<_CvViewer> {
  static const Color _primaryBlue = Color(0xFF3B4FD8);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    late final imageBytes = base64Decode(widget.base64Image);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: _expanded
              ? Image.memory(imageBytes, fit: BoxFit.contain, width: double.infinity,
              errorBuilder: (_, __, ___) => _cvError())
              : SizedBox(height: 280,
              child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => _cvError())),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: _primaryBlue, size: 20),
              const SizedBox(width: 6),
              Text(_expanded ? 'Collapse' : 'View full CV',
                  style: const TextStyle(color: _primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _cvError() => Container(height: 120, color: const Color(0xFFF3F4F8),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.broken_image_outlined, size: 36, color: Color(0xFF6B7280)),
        SizedBox(height: 8),
        Text('Unable to display CV', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
      ])));
}

// ── Status Bottom Sheet ─────────────────────────────────────────────────────
class _StatusSheet extends StatelessWidget {
  final ApplicantModel applicant;
  final ValueChanged<String> onSelected;

  static const Map<String, Color> _statusColor = {
    'unprocessed':  Color(0xFFEF6C00),
    'under review': Color(0xFF9C27B0),
    'shortlisted':  Color(0xFF1565C0),
    'interview':    Color(0xFF2E7D32),
    'hired':        Color(0xFF16A34A),
    'declined':     Color(0xFFC62828),
  };
  static const Map<String, Color> _statusBg = {
    'unprocessed':  Color(0xFFFFF3E0),
    'under review': Color(0xFFF3E5F5),
    'shortlisted':  Color(0xFFE3F2FD),
    'interview':    Color(0xFFE8F5E9),
    'hired':        Color(0xFF16A34A),
    'declined':     Color(0xFFFFEBEE),
  };

  const _StatusSheet({required this.applicant, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'unprocessed', 'label': 'Unprocessed', 'icon': Icons.hourglass_empty_rounded, 'desc': 'Move back to unprocessed queue'},
      {'key': 'under review', 'label': 'Under Review', 'icon': Icons.visibility_outlined, 'desc': 'Currently reviewing details'},
      {'key': 'shortlisted',  'label': 'Shortlisted',  'icon': Icons.star_outline_rounded,    'desc': 'Candidate looks promising'},
      {'key': 'interview',    'label': 'Interview',    'icon': Icons.video_call_outlined,      'desc': 'Schedule an interview'},
      {'key': 'hired',        'label': 'Hire Now',     'icon': Icons.check_circle_rounded, 'desc': 'Finalize employment!'},
      {'key': 'declined',     'label': 'Declined',     'icon': Icons.cancel_outlined,          'desc': 'Not suitable for this role'},
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        Text('${applicant.candidateName} · ${applicant.jobTitle}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? sBg : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? sColor : Colors.grey[200]!, width: isActive ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: isActive ? sColor.withOpacity(0.15) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(s['icon'] as IconData, size: 18, color: isActive ? sColor : Colors.grey[500])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['label'] as String,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: isActive ? sColor : const Color(0xFF1A1A2E))),
                  Text(s['desc'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                if (isActive) Icon(Icons.check_circle_rounded, color: sColor, size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }
}