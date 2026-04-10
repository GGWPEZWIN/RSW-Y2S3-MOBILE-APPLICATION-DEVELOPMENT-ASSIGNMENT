import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Interview/schedule_interview_page.dart';
import '../MainScreen/applicants_list_screen.dart';

class EmployerNotificationsPage extends StatelessWidget {
  const EmployerNotificationsPage({super.key});

  static const Color kBlue   = Color(0xFF3B4FD8);
  static const Color kBg     = Color(0xFFF3F4F8);
  static const Color kText   = Color(0xFF1A1A2E);
  static const Color kSubtext= Color(0xFF6B7280);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kGreen  = Color(0xFF22C55E);
  static const Color kRed    = Color(0xFFEF4444);
  static const Color kPurple = Color(0xFF7C3AED);

  String get _employerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Colour + icon per notification type ───────────────────────────────────
  Color _typeColor(String type) {
    switch (type) {
      case 'new_application':     return kBlue;
      case 'interview_scheduled': return kGreen;
      case 'reschedule_request':  return kOrange;
      case 'interview_cancelled': return kRed;
      default:                    return kPurple;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_application':     return Icons.assignment_ind_rounded;
      case 'interview_scheduled': return Icons.event_available_rounded;
      case 'reschedule_request':  return Icons.schedule_rounded;
      case 'interview_cancelled': return Icons.event_busy_rounded;
      default:                    return Icons.notifications_rounded;
    }
  }

  Future<void> _markAllRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('employer_notifications')
        .where('employerId', isEqualTo: _employerId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Tap handler — routes to the right screen per type ─────────────────────
  Future<void> _handleTap(BuildContext context, String notifId,
      Map<String, dynamic> data) async {
    // Mark read
    await FirebaseFirestore.instance
        .collection('employer_notifications')
        .doc(notifId)
        .update({'isRead': true});

    final type          = data['type']          as String? ?? '';
    final applicationId = data['applicationId'] as String? ?? '';
    final jobId         = data['jobId']         as String? ?? '';
    final jobTitle      = data['jobTitle']      as String? ?? 'Job';
    final candidateUserId = data['candidateUserId'] as String? ?? '';
    final candidateName   = data['candidateName']   as String? ?? 'Candidate';
    final rescheduleReason = data['rescheduleReason'] as String?;

    if (type == 'new_application') {
      // Open the applicants list filtered to this job
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicantsByJobScreen(
            jobId:    jobId,
            jobTitle: jobTitle,
          ),
        ),
      );
      return;
    }

    if (type == 'reschedule_request' ||
        type == 'interview_scheduled' ||
        type == 'interview_cancelled') {
      if (applicationId.isEmpty) return;

      // Fetch existing interview + display info in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('interviews')
            .doc(applicationId)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(candidateUserId)
            .get(),
      ]);

      final interviewDoc = results[0];
      final userDoc      = results[1];

      final existing = interviewDoc.exists
          ? interviewDoc.data() as Map<String, dynamic>
          : null;
      final email = (userDoc.data() as Map<String, dynamic>?)?['email']
      as String? ?? '';

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScheduleInterviewPage(
            applicationId:     applicationId,
            candidateUserId:   candidateUserId,
            jobId:             jobId,
            jobTitle:          jobTitle,
            candidateName:     candidateName,
            candidateEmail:    email,
            existingInterview: existing,
            // Only pass reason for reschedule requests
            rescheduleReason:  type == 'reschedule_request'
                ? rescheduleReason : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(color: kBlue, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employer_notifications')
            .where('employerId', isEqualTo: _employerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kBlue));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState();
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? '';
              return _EmployerNotifCard(
                notifId:  doc.id,
                data:     data,
                color:    _typeColor(type),
                icon:     _typeIcon(type),
                onTap:    () => _handleTap(context, doc.id, data),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 44, color: kBlue),
        ),
        const SizedBox(height: 16),
        const Text('No notifications yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        const Text('New applications and interview updates\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kSubtext)),
      ]),
    );
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────

class _EmployerNotifCard extends StatelessWidget {
  final String notifId;
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _EmployerNotifCard({
    required this.notifId, required this.data,
    required this.color, required this.icon, required this.onTap,
  });

  static const Color kText   = Color(0xFF1A1A2E);
  static const Color kSubtext= Color(0xFF6B7280);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kOrange = Color(0xFFF59E0B);

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final type    = data['type']            as String? ?? '';
    final title   = data['title']           as String? ?? '';
    final body    = data['body']            as String? ?? '';
    final isRead  = data['isRead']          as bool?   ?? false;
    final reason  = data['rescheduleReason'] as String?;
    final appliedAt = data['appliedAt']     as Timestamp?;
    final createdAt = data['createdAt']     as Timestamp?;
    final ts      = appliedAt ?? createdAt;

    final isReschedule     = type == 'reschedule_request';
    final isNewApplication = type == 'new_application';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? kBorder : color.withOpacity(0.35),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + unread dot
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: kText,
                      )),
                ),
                if (!isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 5),

              Text(body,
                  style: const TextStyle(
                      fontSize: 13, color: kSubtext, height: 1.4)),

              // Applied time for new applications
              if (isNewApplication && ts != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: kSubtext),
                  const SizedBox(width: 4),
                  Text('Applied ${_timeAgo(ts)}',
                      style: const TextStyle(
                          fontSize: 12, color: kSubtext)),
                ]),
              ],

              // Reschedule reason box
              if (isReschedule && reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: kOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('"$reason"',
                            style: const TextStyle(
                                fontSize: 12,
                                color: kOrange,
                                fontStyle: FontStyle.italic,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Bottom row: time + action hint
              Row(children: [
                Text(_timeAgo(ts),
                    style: const TextStyle(fontSize: 11, color: kSubtext)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    isNewApplication  ? 'View Applicant'
                        : isReschedule ? 'Review & Edit'
                        : 'View',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}