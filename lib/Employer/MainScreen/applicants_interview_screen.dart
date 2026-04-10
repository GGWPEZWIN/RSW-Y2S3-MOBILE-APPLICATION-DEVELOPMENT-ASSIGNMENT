import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Interview/schedule_interview_page.dart';

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
        title: const Text(
          'Interviews',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('status', isEqualTo: 'interview')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState();
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _InterviewCard(applicationId: doc.id, appData: data);
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
          child: const Icon(Icons.event_note_outlined, size: 40, color: kBlue),
        ),
        const SizedBox(height: 16),
        const Text('No interviews scheduled',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        const Text(
          'Move applicants to "Interview" status\nto see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kSubtext),
        ),
      ]),
    );
  }
}

// ── Interview Card ─────────────────────────────────────────────────────────────
// Reads only the FK fields from the application doc, then joins
// jobs/{jobId} for title and users/{userId} for name/email.

class _InterviewCard extends StatelessWidget {
  final String applicationId;
  final Map<String, dynamic> appData;

  const _InterviewCard({
    required this.applicationId,
    required this.appData,
  });

  static const Color kBlue    = Color(0xFF3B4FD8);
  static const Color kText    = Color(0xFF1A1A2E);
  static const Color kSubtext = Color(0xFF64748B);
  static const Color kBorder  = Color(0xFFE2E8F0);
  static const Color kGreen   = Color(0xFF2E7D32);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    final hour   = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    // FK values from application doc
    final jobId      = appData['jobId']    as String? ?? '';
    final userId     = appData['userId']   as String? ?? '';
    final workType   = appData['workType'] as String? ?? '';
    final workplace  = appData['workplace'] as String? ?? '';
    final salary     = appData['salary']   as String? ?? '';

    // Join jobs/{jobId} and users/{userId} in parallel
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
        FirebaseFirestore.instance.collection('interviews').doc(applicationId).get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: const Center(
                child: CircularProgressIndicator(color: kBlue, strokeWidth: 2)),
          );
        }

        final jobDoc       = snap.data![0];
        final userDoc      = snap.data![1];
        final interviewDoc = snap.data![2];

        // Job data
        final jobData  = jobDoc.exists ? jobDoc.data() as Map<String, dynamic> : {};
        final jobTitle = jobData['title'] as String? ?? 'Unknown Job';
        final location = jobData['location'] as String? ?? '';

        // User data
        final userData  = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
        final name  = userData['name']  as String? ?? 'Unknown';
        final email = userData['email'] as String? ?? '';

        // Interview data (if already scheduled)
        final hasInterview = interviewDoc.exists;
        final interviewData = hasInterview
            ? interviewDoc.data() as Map<String, dynamic>
            : null;

        // Format scheduled time from single interviewTimestamp
        String? scheduledText;
        String? locText;
        if (interviewData != null) {
          final ts = interviewData['interviewTimestamp'] as Timestamp?;
          if (ts != null) scheduledText = _formatTimestamp(ts);
          final locType   = interviewData['locationType']   as String? ?? '';
          final locDetail = interviewData['locationDetail'] as String? ?? '';
          locText = locDetail.isNotEmpty ? locDetail : locType;
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleInterviewPage(
                applicationId:     applicationId,
                candidateUserId:   userId,
                jobId:             jobId,
                // Display-only — not stored in Firestore
                jobTitle:          jobTitle,
                candidateName:     name,
                candidateEmail:    email,
                existingInterview: interviewData,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar — initials from joined user name
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kBlue.withOpacity(0.1),
                  child: Text(_initials(name),
                      style: const TextStyle(
                          color: kBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + scheduled badge
                      Row(children: [
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: kText)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasInterview
                                ? kGreen.withOpacity(0.1)
                                : kBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasInterview
                                  ? kGreen.withOpacity(0.4)
                                  : kBlue.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            hasInterview ? 'Scheduled ✓' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasInterview ? kGreen : kBlue,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),

                      // Email from users join
                      Text(email,
                          style: const TextStyle(
                              fontSize: 12, color: kSubtext)),
                      const SizedBox(height: 6),

                      // Job title from jobs join
                      Row(children: [
                        const Icon(Icons.work_outline_rounded,
                            size: 13, color: kSubtext),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(jobTitle,
                              style: const TextStyle(
                                  fontSize: 12, color: kSubtext),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),

                      // Location from jobs join
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: kSubtext),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(location,
                                style: const TextStyle(
                                    fontSize: 12, color: kSubtext),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],

                      // Work type + workplace chips
                      if (workType.isNotEmpty || workplace.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          if (workType.isNotEmpty)  _chip(workType),
                          if (workplace.isNotEmpty) _chip(workplace),
                        ]),
                      ],

                      // Salary
                      if (salary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.payments_outlined,
                              size: 13, color: kSubtext),
                          const SizedBox(width: 4),
                          Text(salary,
                              style: const TextStyle(
                                  fontSize: 12, color: kSubtext)),
                        ]),
                      ],

                      // Scheduled time (from interviews join via interviewTimestamp)
                      if (scheduledText != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kGreen.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: kGreen.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 13, color: kGreen),
                                const SizedBox(width: 6),
                                Text(scheduledText,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: kGreen,
                                        fontWeight: FontWeight.w600)),
                              ]),
                              if (locText != null && locText.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: kGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(locText,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: kGreen)),
                                  ),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: kSubtext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kBlue.withOpacity(0.07),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(fontSize: 10, color: kBlue)),
  );
}