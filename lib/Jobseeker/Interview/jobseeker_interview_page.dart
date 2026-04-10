import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Local notifier (reused pattern) ──────────────────────────────────────────
class _LocalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    _ready = true;
  }

  static Future<void> show(String title, String body) async {
    await _init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'interview_channel', 'Interview Notifications',
          importance: Importance.max, priority: Priority.high,
          color: Color(0xFF2563EB), icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
        // Fetch all interviews where candidateUserId == logged-in user
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
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _InterviewCard(
                interviewId: doc.id,
                data:        data,
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
          child: const Icon(Icons.event_available_rounded,
              size: 44, color: kBlue),
        ),
        const SizedBox(height: 16),
        const Text('No interviews yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        const Text('Scheduled interviews will appear here.',
            style: TextStyle(fontSize: 13, color: kSubtext)),
      ]),
    );
  }
}

// ── Interview Card ─────────────────────────────────────────────────────────────

class _InterviewCard extends StatelessWidget {
  final String interviewId; // same as applicationId
  final Map<String, dynamic> data;

  const _InterviewCard({required this.interviewId, required this.data});

  static const Color kBlue   = Color(0xFF2563EB);
  static const Color kText   = Color(0xFF0F172A);
  static const Color kSubtext= Color(0xFF64748B);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kGreen  = Color(0xFF22C55E);
  static const Color kRed    = Color(0xFFEF4444);
  static const Color kOrange = Color(0xFFF59E0B);
  static const Color kGrey   = Color(0xFF94A3B8);

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':          return kGreen;
      case 'cancelled':          return kRed;
      case 'reschedule_pending': return kOrange;
      default:                   return kBlue;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':          return 'Scheduled';
      case 'cancelled':          return 'Cancelled';
      case 'reschedule_pending': return 'Reschedule Pending';
      default:                   return status;
    }
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final jobId      = data['jobId']           as String? ?? '';
    final status     = data['status']          as String? ?? 'scheduled';
    final locType    = data['locationType']    as String? ?? '';
    final locDetail  = data['locationDetail']  as String? ?? '';
    final notes      = data['notes']           as String? ?? '';
    final ts         = data['interviewTimestamp'] as Timestamp?;

    final isCancelled = status == 'cancelled';
    final statusColor = _statusColor(status);

    return FutureBuilder<DocumentSnapshot>(
      // Join jobs/{jobId} to get title
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
              color: isCancelled ? kRed.withOpacity(0.3) : kBorder,
              width: isCancelled ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Title + status badge
                Row(children: [
                  Expanded(
                    child: Text(jobTitle,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kText)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(_statusLabel(status),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 12),

                // Date + time
                _infoRow(Icons.calendar_today_rounded,
                    _formatTs(ts), kBlue),
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
              ]),
            ),

            // Action strip — hidden if cancelled
            if (!isCancelled) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(children: [
                  // Cancel button
                  Expanded(
                    child: _ActionBtn(
                      label: 'Cancel',
                      icon:  Icons.cancel_outlined,
                      color: kRed,
                      onTap: () => _confirmCancel(context, jobTitle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Request reschedule
                  Expanded(
                    flex: 2,
                    child: _ActionBtn(
                      label: 'Request Reschedule',
                      icon:  Icons.schedule_rounded,
                      color: kOrange,
                      onTap: () => _requestReschedule(context, jobTitle),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        );
      },
    );
  }

  // ── Cancel ──────────────────────────────────────────────────────────────

  Future<void> _confirmCancel(BuildContext context, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Interview?'),
        content: Text(
            'Are you sure you want to cancel your interview for $jobTitle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: const Text('Cancel Interview',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db  = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final batch = db.batch();

    // 1. Update interview status
    batch.update(db.collection('interviews').doc(interviewId),
        {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});

    // 2. Update application status back to 'shortlisted'
    batch.update(db.collection('applications').doc(interviewId),
        {'status': 'shortlisted', 'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();

    // 3. Write cancellation notification to jobseeker's own inbox
    final notifTitle = '❌ Interview Cancelled — $jobTitle';
    const notifBody  = 'You have cancelled your interview. '
        'The employer has been notified.';

    await db
        .collection('users').doc(uid)
        .collection('notifications')
        .add({
      'applicationId': interviewId,
      'title':  notifTitle,
      'body':   notifBody,
      'type':   'interview_cancelled',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Notify employer via employer_notifications
    final interviewDoc = await db.collection('interviews').doc(interviewId).get();
    final employerId   = interviewDoc.data()?['employerId'] as String? ?? '';
    if (employerId.isNotEmpty) {
      await db.collection('employer_notifications').add({
        'employerId':    employerId,
        'applicationId': interviewId,
        'jobId':         data['jobId'] ?? '',
        'candidateUserId': uid,
        'title':  '❌ Interview Cancelled — $jobTitle',
        'body':   'The candidate has cancelled their interview for $jobTitle.',
        'type':   'interview_cancelled',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 5. Local device notification
    await _LocalNotifier.show(notifTitle, notifBody);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Interview cancelled.'),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Request reschedule ───────────────────────────────────────────────────

  Future<void> _requestReschedule(
      BuildContext context, String jobTitle) async {
    final reasonCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 22),
          SizedBox(width: 8),
          Text('Request Reschedule'),
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
              hintStyle:
              const TextStyle(fontSize: 13, color: Color(0xFFADBAC7)),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFF59E0B), width: 1.5),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Send Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (submitted != true) return;

    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please write a reason before sending.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    final db  = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 1. Update interview status to reschedule_pending + store reason
    await db.collection('interviews').doc(interviewId).update({
      'status':            'reschedule_pending',
      'rescheduleReason':  reason,
      'rescheduleBy':      uid,
      'updatedAt':         FieldValue.serverTimestamp(),
    });

    // 2. Notify employer via employer_notifications
    final interviewDoc = await db.collection('interviews').doc(interviewId).get();
    final employerId   = interviewDoc.data()?['employerId'] as String? ?? '';

    if (employerId.isNotEmpty) {
      await db.collection('employer_notifications').add({
        'employerId':      employerId,
        'applicationId':   interviewId,
        'jobId':           data['jobId'] ?? '',
        'candidateUserId': uid,
        'rescheduleReason': reason,
        'title':  '🔄 Reschedule Request — $jobTitle',
        'body':   'A candidate has requested to reschedule their interview for $jobTitle.',
        'type':   'reschedule_request',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Write to jobseeker's own inbox as confirmation
    await db
        .collection('users').doc(uid)
        .collection('notifications')
        .add({
      'applicationId': interviewId,
      'title':  '🔄 Reschedule Request Sent — $jobTitle',
      'body':   'Your reschedule request has been sent to the employer. '
          'You will be notified once they update the interview.',
      'type':   'interview',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Local device notification
    await _LocalNotifier.show(
      '🔄 Reschedule Request Sent',
      'Your request for $jobTitle has been sent to the employer.',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reschedule request sent to employer.'),
        backgroundColor: Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 13, color: color),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}