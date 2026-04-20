import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Interview/schedule_interview_page.dart'; // adjust path
import 'package:firebase_auth/firebase_auth.dart';

class ApplicantsInterviewScreen extends StatelessWidget {
  const ApplicantsInterviewScreen({super.key});

  static const Color kBlue    = Color(0xFF3B4FD8);
  static const Color kBg      = Color(0xFFF3F4F8);
  static const Color kText    = Color(0xFF1A1A2E);
  static const Color kSubtext = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Interviews',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('employerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .where('status', isEqualTo: 'interview')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc  = snap.data!.docs[i];
              return _InterviewCard(
                  applicationId: doc.id,
                  appData: doc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.event_note_outlined, size: 40, color: kBlue),
      ),
      const SizedBox(height: 16),
      const Text('No interviews scheduled',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
      const SizedBox(height: 6),
      const Text('Move applicants to "Interview" status\nto see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kSubtext)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERVIEW CARD — streams the interviews doc live so status/reason update
// without a page reload
// ══════════════════════════════════════════════════════════════════════════════
class _InterviewCard extends StatelessWidget {
  final String applicationId;
  final Map<String, dynamic> appData;

  const _InterviewCard({required this.applicationId, required this.appData});

  static const Color kBlue   = Color(0xFF3B4FD8);
  static const Color kText   = Color(0xFF1A1A2E);
  static const Color kSubtext= Color(0xFF64748B);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kGreen  = Color(0xFF2E7D32);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kRed    = Color(0xFFEF4444);
  static const Color kPurple = Color(0xFF8B5CF6);

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTs(Timestamp ts) {
    final dt = ts.toDate();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  void _openSchedule(BuildContext context, {
    required String name,
    required String email,
    required String jobTitle,
    required Map<String, dynamic>? existing,
    String? rescheduleReason,
  }) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScheduleInterviewPage(
        applicationId:    applicationId,
        candidateUserId:  appData['userId'] as String? ?? '',
        jobId:            appData['jobId']  as String? ?? '',
        jobTitle:         jobTitle,
        candidateName:    name,
        candidateEmail:   email,
        existingInterview: existing,
        rescheduleReason:  rescheduleReason,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final jobId    = appData['jobId']    as String? ?? '';
    final userId   = appData['userId']   as String? ?? '';
    final workType = appData['workType'] as String? ?? '';
    final workplace= appData['workplace'] as String? ?? '';
    final salary   = appData['salary']   as String? ?? '';

    // Join jobs + users + stream interviews live
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
      ]),
      builder: (context, futureSnap) {
        if (!futureSnap.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: const Center(child: CircularProgressIndicator(color: kBlue, strokeWidth: 2)),
          );
        }

        final jobDoc  = futureSnap.data![0];
        final userDoc = futureSnap.data![1];

        final jobData  = jobDoc.exists  ? jobDoc.data()  as Map<String, dynamic> : {};
        final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};

        final jobTitle = jobData['title']   as String? ?? 'Unknown Job';
        final location = jobData['location'] as String? ?? '';
        final name     = userData['name']   as String? ?? 'Unknown';
        final email    = userData['email']  as String? ?? '';

        // Stream the interviews doc so reschedule status updates live
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('interviews').doc(applicationId).snapshots(),
          builder: (context, ivSnap) {
            final interviewData = (ivSnap.hasData && ivSnap.data!.exists)
                ? ivSnap.data!.data() as Map<String, dynamic>
                : null;

            final ivStatus      = interviewData?['status'] as String? ?? 'scheduled';
            final ts            = interviewData?['interviewTimestamp'] as Timestamp?;
            final locType       = interviewData?['locationType']   as String? ?? '';
            final locDetail     = interviewData?['locationDetail'] as String? ?? '';
            final reschedReason = interviewData?['rescheduleReason'] as String? ?? '';

            final isReschedulePending = ivStatus == 'reschedule_pending';
            final isCancelled         = ivStatus == 'cancelled';

            // Border colour based on interview status
            Color borderColor = kBorder;
            double borderWidth = 1;
            if (isReschedulePending) { borderColor = kOrange.withOpacity(0.6); borderWidth = 1.5; }
            if (isCancelled)         { borderColor = kRed.withOpacity(0.4);    borderWidth = 1.5; }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(children: [

                // ── Card body ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: kBlue.withOpacity(0.1),
                        child: Text(_initials(name),
                            style: const TextStyle(
                                color: kBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(width: 14),

                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Name + status badge
                        Row(children: [
                          Expanded(child: Text(name, style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold, color: kText))),
                          _statusBadge(ivStatus),
                        ]),
                        const SizedBox(height: 3),
                        Text(email, style: const TextStyle(fontSize: 12, color: kSubtext)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.work_outline_rounded, size: 13, color: kSubtext),
                          const SizedBox(width: 4),
                          Expanded(child: Text(jobTitle,
                              style: const TextStyle(fontSize: 12, color: kSubtext),
                              overflow: TextOverflow.ellipsis)),
                        ]),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: kSubtext),
                            const SizedBox(width: 4),
                            Expanded(child: Text(location,
                                style: const TextStyle(fontSize: 12, color: kSubtext),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                        if (workType.isNotEmpty || workplace.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            if (workType.isNotEmpty)  _chip(workType),
                            if (workplace.isNotEmpty) _chip(workplace),
                          ]),
                        ],
                        if (salary.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.payments_outlined, size: 13, color: kSubtext),
                            const SizedBox(width: 4),
                            Text(salary, style: const TextStyle(fontSize: 12, color: kSubtext)),
                          ]),
                        ],
                      ])),

                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kSubtext),
                    ]),

                    // ── Scheduled time box ──────────────────────────────────
                    if (ts != null && !isCancelled) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kGreen.withOpacity(0.25)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: kGreen),
                            const SizedBox(width: 6),
                            Text(_formatTs(ts), style: const TextStyle(
                                fontSize: 12, color: kGreen, fontWeight: FontWeight.w600)),
                          ]),
                          if (locDetail.isNotEmpty || locType.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: kGreen),
                              const SizedBox(width: 6),
                              Expanded(child: Text(
                                  locDetail.isNotEmpty ? locDetail : locType,
                                  style: const TextStyle(fontSize: 11, color: kGreen))),
                            ]),
                          ],
                        ]),
                      ),
                    ],

                    // ── Reschedule pending banner + reason ──────────────────
                    if (isReschedulePending) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kOrange.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kOrange.withOpacity(0.35)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.schedule_rounded, size: 15, color: kOrange),
                            const SizedBox(width: 6),
                            const Text('Reschedule Requested',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kOrange)),
                          ]),
                          if (reschedReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('"$reschedReason"', style: const TextStyle(
                                fontSize: 12, color: kOrange,
                                fontStyle: FontStyle.italic, height: 1.4)),
                          ],
                          const SizedBox(height: 8),
                          const Text('Tap "Review & Reschedule" to propose a new time.',
                              style: TextStyle(fontSize: 11, color: kSubtext)),
                        ]),
                      ),
                    ],

                    // ── Cancelled banner ────────────────────────────────────
                    if (isCancelled) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kRed.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kRed.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.cancel_outlined, size: 15, color: kRed),
                          const SizedBox(width: 6),
                          const Expanded(child: Text('Interview cancelled.',
                              style: TextStyle(fontSize: 12, color: kRed))),
                        ]),
                      ),
                    ],
                  ]),
                ),

                // ── Action buttons ─────────────────────────────────────────
                if (!isCancelled) ...[
                  const Divider(height: 1, color: kBorder),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: isReschedulePending
                    // Reschedule pending → "Review & Reschedule" full-width
                        ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openSchedule(context,
                          name: name, email: email, jobTitle: jobTitle,
                          existing: interviewData,
                          rescheduleReason: reschedReason.isNotEmpty ? reschedReason : null,
                        ),
                        icon: const Icon(Icons.schedule_rounded,
                            size: 16, color: Colors.white),
                        label: const Text('Review & Reschedule',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    )
                    // Scheduled → Edit Interview button
                        : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openSchedule(context,
                          name: name, email: email, jobTitle: jobTitle,
                          existing: interviewData,
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded,
                            size: 16, color: kBlue),
                        label: const Text('Edit Interview',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.bold, color: kBlue)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kBlue),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'reschedule_pending':
        color = kOrange; label = 'Reschedule Pending'; break;
      case 'cancelled':
        color = kRed; label = 'Cancelled'; break;
      case 'reschedule_proposed':
        color = kPurple; label = 'Time Proposed'; break;
      default:
        color = kGreen; label = 'Scheduled';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: kBlue.withOpacity(0.07), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: kBlue)),
  );
}