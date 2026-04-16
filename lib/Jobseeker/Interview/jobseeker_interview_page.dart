import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';

class JobseekerInterviewPage extends StatelessWidget {
  const JobseekerInterviewPage({super.key});

  static const Color kBlue    = Color(0xFF2563EB);
  static const Color kBg      = Color(0xFFF5F6FA);
  static const Color kText    = Color(0xFF0F172A);
  static const Color kSubtext = Color(0xFF64748B);

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'My Interviews',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('interviews')
            .where('candidateUserId', isEqualTo: _uid)
            .orderBy('interviewTimestamp', descending: false)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBlue));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final doc  = snap.data!.docs[i];
              return _InterviewCard(
                interviewId: doc.id,
                data:        doc.data() as Map<String, dynamic>,
              );
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
        child: const Icon(Icons.event_available_rounded, size: 44, color: kBlue),
      ),
      const SizedBox(height: 16),
      const Text('No interviews yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
      const SizedBox(height: 6),
      const Text('Scheduled interviews will appear here.',
          style: TextStyle(fontSize: 13, color: kSubtext)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERVIEW CARD
// ══════════════════════════════════════════════════════════════════════════════
class _InterviewCard extends StatefulWidget {
  final String interviewId;
  final Map<String, dynamic> data;

  const _InterviewCard({required this.interviewId, required this.data});

  @override
  State<_InterviewCard> createState() => _InterviewCardState();
}

class _InterviewCardState extends State<_InterviewCard> {
  static const Color kBlue   = Color(0xFF2563EB);
  static const Color kText   = Color(0xFF0F172A);
  static const Color kSubtext= Color(0xFF64748B);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kGreen  = Color(0xFF22C55E);
  static const Color kRed    = Color(0xFFEF4444);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kPurple = Color(0xFF8B5CF6);

  bool _isBusy = false;

  Color _statusColor(String s) {
    switch (s) {
      case 'scheduled':          return kGreen;
      case 'cancelled':          return kRed;
      case 'reschedule_pending': return kOrange;
      case 'reschedule_proposed':return kPurple;
      default:                   return kBlue;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'scheduled':           return 'Scheduled';
      case 'cancelled':           return 'Cancelled';
      case 'reschedule_pending':  return 'Reschedule Pending';
      case 'reschedule_proposed': return 'New Time Proposed';
      default:                    return s;
    }
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  // ── Always fetch employerId fresh from the interview doc ──────────────────
  Future<String> _getEmployerId() async {
    final doc = await FirebaseFirestore.instance
        .collection('interviews').doc(widget.interviewId).get();
    return (doc.data()?['employerId'] as String?) ?? '';
  }

  // ── Write employer_notifications + send push ──────────────────────────────
  Future<void> _notifyEmployer({
    required String employerId,
    required String jobTitle,
    required String type,
    required String title,
    required String body,
    String? rescheduleReason,
  }) async {
    if (employerId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db  = FirebaseFirestore.instance;

    // 1. In-app notification doc (read by NotificationService listener on employer's device)
    final notifData = <String, dynamic>{
      'employerId':      employerId,
      'applicationId':   widget.interviewId,
      'jobId':           widget.data['jobId'] ?? '',
      'candidateUserId': uid,
      'candidateName':   widget.data['candidateName'] ??
          FirebaseAuth.instance.currentUser?.displayName ?? '',
      'jobTitle':        jobTitle,
      'title':           title,
      'body':            body,
      'type':            type,
      'status':          'unread',
      'isRead':          false,
      'createdAt':       FieldValue.serverTimestamp(),
    };
    if (rescheduleReason != null) notifData['rescheduleReason'] = rescheduleReason;
    await db.collection('employer_notifications').add(notifData);

    // 2. Push notification → queued for Cloud Function / local fallback
    await FCMService().sendPushNotification(
      recipientId: employerId,
      title:       title,
      body:        body,
      data: {
        'type':          type,
        'applicationId': widget.interviewId,
        'jobId':         widget.data['jobId'] ?? '',
      },
    );
  }

  // ── CANCEL ────────────────────────────────────────────────────────────────
  Future<void> _confirmCancel(String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Interview?'),
        content: Text('Cancel your interview for $jobTitle?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('Cancel Interview',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final db  = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 1. Update Firestore
      final batch = db.batch();
      batch.update(db.collection('interviews').doc(widget.interviewId),
          {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
      batch.update(db.collection('applications').doc(widget.interviewId),
          {'status': 'shortlisted', 'updatedAt': FieldValue.serverTimestamp()});
      await batch.commit();

      // 2. Self notification (jobseeker's own inbox)
      await db.collection('users').doc(uid).collection('notifications').add({
        'applicationId': widget.interviewId,
        'jobId':         widget.data['jobId'] ?? '',
        'title':         '❌ Interview Cancelled — $jobTitle',
        'body':          'You cancelled your interview for $jobTitle.',
        'type':          'interview_cancelled',
        'isRead':        false,
        'createdAt':     FieldValue.serverTimestamp(),
      });

      // 3. Notify employer (in-app + push) — fetch employerId fresh
      final employerId = await _getEmployerId();
      await _notifyEmployer(
        employerId: employerId,
        jobTitle:   jobTitle,
        type:       'interview_cancelled',
        title:      '❌ Interview Cancelled — $jobTitle',
        body:       'The candidate has cancelled their interview for $jobTitle.',
      );

      // 4. Local banner on THIS device
      await NotificationService().showNotification(
        title: '❌ Interview Cancelled — $jobTitle',
        body:  'You cancelled your interview for $jobTitle.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Interview cancelled. Employer has been notified.'),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── REQUEST RESCHEDULE ────────────────────────────────────────────────────
  Future<void> _requestReschedule(String jobTitle) async {
    final reasonCtrl = TextEditingController();
    final submitted  = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 22),
          SizedBox(width: 8),
          Flexible(child: Text('Request Reschedule')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Tell the employer why you need to reschedule your interview for $jobTitle.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reasonCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. I have a prior commitment on that day...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADBAC7)),
              filled: true, fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Send Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (reason.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final db  = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 1. Update interview doc only — do NOT change applications.status
      //    so the employer's interview list remains intact
      await db.collection('interviews').doc(widget.interviewId).update({
        'status':            'reschedule_pending',
        'rescheduleReason':  reason,
        'rescheduleBy':      'candidate',
        'pendingAcceptance': false,
        'updatedAt':         FieldValue.serverTimestamp(),
      });

      // 2. Notify employer (in-app + push) — always fetch employerId fresh
      final employerId = await _getEmployerId();
      await _notifyEmployer(
        employerId:      employerId,
        jobTitle:        jobTitle,
        type:            'reschedule_request',
        title:           '🔄 Reschedule Request — $jobTitle',
        body:            'A candidate has requested to reschedule their interview for $jobTitle.',
        rescheduleReason: reason,
      );

      // 3. Self notification (jobseeker's inbox)
      await db.collection('users').doc(uid).collection('notifications').add({
        'applicationId': widget.interviewId,
        'jobId':         widget.data['jobId'] ?? '',
        'title':         '🔄 Reschedule Requested — $jobTitle',
        'body':          'Your reschedule request has been sent. Waiting for the employer to respond.',
        'type':          'reschedule_request',
        'isRead':        false,
        'createdAt':     FieldValue.serverTimestamp(),
      });

      // 4. Local banner on THIS device
      await NotificationService().showNotification(
        title: '🔄 Reschedule Requested',
        body:  'Your reschedule request has been sent to the employer.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reschedule request sent to employer.'),
          backgroundColor: kOrange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── ACCEPT employer's proposed new time ───────────────────────────────────
  Future<void> _acceptReschedule(String jobTitle) async {
    setState(() => _isBusy = true);
    try {
      final db  = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      await db.collection('interviews').doc(widget.interviewId).update({
        'status':            'scheduled',
        'pendingAcceptance': false,
        'rescheduleReason':  FieldValue.delete(),
        'rescheduleBy':      FieldValue.delete(),
        'updatedAt':         FieldValue.serverTimestamp(),
      });

      final employerId = await _getEmployerId();
      await _notifyEmployer(
        employerId: employerId,
        jobTitle:   jobTitle,
        type:       'reschedule_accepted',
        title:      '✅ Reschedule Accepted — $jobTitle',
        body:       'The candidate has accepted the new interview time for $jobTitle.',
      );

      await NotificationService().showNotification(
        title: '✅ New Time Confirmed',
        body:  'You accepted the new interview time for $jobTitle.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New interview time accepted ✓'),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── DECLINE employer's proposed new time (with reason) ────────────────────
  Future<void> _declineReschedule(String jobTitle) async {
    final reasonCtrl = TextEditingController();
    final submitted  = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: kRed, size: 22),
          SizedBox(width: 8),
          Flexible(child: Text('Decline New Time')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Tell the employer why this time does not work for you.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. I am also unavailable on that date...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADBAC7)),
              filled: true, fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kRed, width: 1.5)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back',
                  style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Decline & Notify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (reason.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final db  = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Put ball back in employer's court
      await db.collection('interviews').doc(widget.interviewId).update({
        'status':            'reschedule_pending',
        'rescheduleReason':  reason,
        'rescheduleBy':      'candidate',
        'pendingAcceptance': false,
        'updatedAt':         FieldValue.serverTimestamp(),
      });

      final employerId = await _getEmployerId();
      await _notifyEmployer(
        employerId:       employerId,
        jobTitle:         jobTitle,
        type:             'reschedule_request',
        title:            '❌ New Time Declined — $jobTitle',
        body:             'The candidate declined your proposed time and sent a new reschedule request.',
        rescheduleReason: reason,
      );

      await NotificationService().showNotification(
        title: '❌ Time Declined',
        body:  'You declined the proposed time. Waiting for employer to suggest another.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Decline sent — waiting for employer to propose another time.'),
          backgroundColor: kOrange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kRed));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final jobId         = widget.data['jobId']              as String?   ?? '';
    final status        = widget.data['status']             as String?   ?? 'scheduled';
    final locType       = widget.data['locationType']       as String?   ?? '';
    final locDetail     = widget.data['locationDetail']     as String?   ?? '';
    final notes         = widget.data['notes']              as String?   ?? '';
    final ts            = widget.data['interviewTimestamp'] as Timestamp?;
    final reschedReason = widget.data['rescheduleReason']   as String?   ?? '';
    final pendingAcc    = widget.data['pendingAcceptance']  as bool?     ?? false;

    final isCancelled       = status == 'cancelled';
    final isPendingCandidate = status == 'reschedule_pending' && !pendingAcc;
    final isNewTimeProposed  = (status == 'reschedule_pending' && pendingAcc)
        || status == 'reschedule_proposed';
    final isScheduled        = status == 'scheduled';
    final statusColor        = _statusColor(status);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnap) {
        final jobData  = jobSnap.hasData && jobSnap.data!.exists
            ? jobSnap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final jobTitle = jobData['title'] as String? ?? 'Job';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCancelled
                  ? kRed.withOpacity(0.3)
                  : isNewTimeProposed
                  ? kPurple.withOpacity(0.4)
                  : isPendingCandidate
                  ? kOrange.withOpacity(0.4)
                  : kBorder,
              width: (isCancelled || isNewTimeProposed || isPendingCandidate) ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [

            // ── Card body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Job title + status badge
                Row(children: [
                  Expanded(child: Text(jobTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: kText))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(_statusLabel(status),
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 12),

                // Date/time
                _infoRow(Icons.calendar_today_rounded, _formatTs(ts), kBlue),
                const SizedBox(height: 6),

                // Location
                _infoRow(
                  locType == 'Zoom' ? Icons.videocam_outlined
                      : locType == 'Google Meet' ? Icons.meeting_room_outlined
                      : locType == 'Phone Call' ? Icons.phone_outlined
                      : Icons.location_on_outlined,
                  locDetail.isNotEmpty ? locDetail : locType,
                  kSubtext,
                ),

                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow(Icons.notes_rounded, notes, kSubtext),
                ],

                // ── Status banners ──────────────────────────────────────

                // Awaiting employer response
                if (isPendingCandidate) ...[
                  const SizedBox(height: 12),
                  _banner(
                    color: kOrange, bgColor: const Color(0xFFFFFBEB),
                    icon: Icons.schedule_rounded,
                    text: 'Reschedule request sent. Waiting for employer to propose a new time.',
                  ),
                  if (reschedReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _reasonBox(reschedReason, kOrange),
                  ],
                ],

                // New time proposed by employer — Accept / Decline
                if (isNewTimeProposed) ...[
                  const SizedBox(height: 12),
                  _banner(
                    color: kPurple, bgColor: const Color(0xFFF5F3FF),
                    icon: Icons.event_available_rounded,
                    text: 'The employer has proposed a new interview time. Please accept or decline below.',
                  ),
                ],

                // Cancelled
                if (isCancelled) ...[
                  const SizedBox(height: 12),
                  _banner(
                    color: kRed, bgColor: const Color(0xFFFEF2F2),
                    icon: Icons.cancel_outlined,
                    text: 'This interview has been cancelled.',
                  ),
                ],
              ]),
            ),

            // ── Action buttons strip ─────────────────────────────────────
            if (!isCancelled && !isPendingCandidate) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: isNewTimeProposed
                // New time proposed: Accept / Decline
                    ? Row(children: [
                  Expanded(child: _ActionBtn(
                    label: 'Accept',
                    icon:  Icons.check_circle_outline_rounded,
                    color: kGreen,
                    onTap: _isBusy ? null : () => _acceptReschedule(jobTitle),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn(
                    label: 'Decline & Reason',
                    icon:  Icons.cancel_outlined,
                    color: kRed,
                    onTap: _isBusy ? null : () => _declineReschedule(jobTitle),
                  )),
                ])
                // Normal scheduled: Reschedule / Cancel
                    : Row(children: [
                  Expanded(child: _ActionBtn(
                    label: 'Cancel',
                    icon:  Icons.cancel_outlined,
                    color: kRed,
                    onTap: _isBusy ? null : () => _confirmCancel(jobTitle),
                  )),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _ActionBtn(
                    label: 'Request Reschedule',
                    icon:  Icons.schedule_rounded,
                    color: kOrange,
                    onTap: _isBusy ? null : () => _requestReschedule(jobTitle),
                  )),
                ]),
              ),
            ],
          ]),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Row(children: [
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 6),
    Expanded(child: Text(text,
        style: TextStyle(fontSize: 13, color: color),
        overflow: TextOverflow.ellipsis)),
  ]);

  Widget _banner({
    required Color color, required Color bgColor,
    required IconData icon, required String text,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text,
              style: TextStyle(fontSize: 12, color: color,
                  fontWeight: FontWeight.w500, height: 1.4))),
        ]),
      );

  Widget _reasonBox(String reason, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.chat_bubble_outline_rounded, size: 13, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text('"$reason"',
          style: TextStyle(fontSize: 12, color: color,
              fontStyle: FontStyle.italic, height: 1.4))),
    ]),
  );
}

// ── Small action button ───────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(child: Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}