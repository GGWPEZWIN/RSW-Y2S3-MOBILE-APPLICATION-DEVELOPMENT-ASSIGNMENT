import 'package:assignment/Jobseeker/JobApplication/ApplicationUI/saved_job_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../MainScreen/jobseeker_profile.dart';
import '../../Widgets/nav_bar_widget.dart';
import 'package:flutter/material.dart';
import 'edit_job_application.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// APPLICATION STATUS SCREEN
// ─────────────────────────────────────────────
class ApplicationStatusScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic> applicationData;

  const ApplicationStatusScreen({
    super.key,
    required this.applicationId,
    required this.applicationData,
  });

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _isBusy = false;

  // ── Helpers ──────────────────────────────────────────────────────────────
  String get _status =>
      (widget.applicationData['status'] ?? 'unprocessed').toString().toLowerCase();

  bool get _isWithdrawnOrCancelled =>
      _status == 'withdrawn' || _status == 'cancelled';

  bool get _isInterview => _status == 'interview';

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Unknown date';
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Status display config ────────────────────────────────────────────────
  _StatusConfig get _statusConfig {
    switch (_status) {
      case 'shortlisted':
        return _StatusConfig(
          icon: Icons.star_outline_rounded,
          label: 'Shortlisted',
          message: 'Congratulations! You have been shortlisted for this position.',
          color: const Color(0xFF16A34A),
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
        );
      case 'interview':
        return _StatusConfig(
          icon: Icons.videocam_outlined,
          label: 'Interview Scheduled',
          message: 'An interview has been scheduled. Check the details below.',
          color: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          borderColor: const Color(0xFFDDD6FE),
        );
      case 'under review':
        return _StatusConfig(
          icon: Icons.info_outline,
          label: 'Under Review',
          message: 'The hiring team is currently reviewing your profile.',
          color: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
        );
      case 'declined':
      case 'rejected':
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          label: 'Application Declined',
          message: 'Unfortunately your application was not successful this time.',
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
        );
      case 'withdrawn':
        return _StatusConfig(
          icon: Icons.undo_rounded,
          label: 'Withdrawn',
          message: 'You have withdrawn this application.',
          color: const Color(0xFF64748B),
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
        );
      case 'cancelled':
        return _StatusConfig(
          icon: Icons.block_rounded,
          label: 'Cancelled',
          message: 'This application has been cancelled.',
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
        );
      case 'reschedule_pending':
        return _StatusConfig(
          icon: Icons.schedule_rounded,
          label: 'Reschedule Pending',
          message: 'A reschedule request is pending approval.',
          color: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
        );
      case 'reschedule_proposed':
        return _StatusConfig(
          icon: Icons.event_repeat_rounded,
          label: 'Reschedule Proposed',
          message: 'A new interview time has been proposed. Please review it.',
          color: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          borderColor: const Color(0xFFDDD6FE),
        );
    // unprocessed / default
      default:
        return _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          label: 'Pending Review',
          message: 'Your application has been submitted and is awaiting review.',
          color: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
        );
    }
  }

  // ── Withdraw handler ─────────────────────────────────────────────────────
  Future<void> _handleWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Withdraw',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
        'status': 'withdrawn',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final d      = widget.applicationData;
    final config = _statusConfig;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Application Status',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Job card ──────────────────────────────────────────
            _JobCard(
              jobTitle: d['jobTitle'] ?? 'Unknown Job',
              company:  d['company']  ?? '',
              appliedAt: _formatTimestamp(d['appliedAt']),
            ),
            const SizedBox(height: 12),

            // ── Status banner ─────────────────────────────────────
            _StatusBanner(
              icon:        config.icon,
              label:       config.label,
              message:     config.message,
              color:       config.color,
              bgColor:     config.bgColor,
              borderColor: config.borderColor,
            ),
            const SizedBox(height: 24),

            // ── Tracking timeline ─────────────────────────────────
            const Text(
              'Tracking Timeline',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _TrackingTimeline(
              status: _status,
              applicationData: widget.applicationData, // This passes the Firestore map
            ),
            const SizedBox(height: 32),

            // ── Action buttons ────────────────────────────────────
            if (_status == 'unprocessed') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: const Color(0xFF1A1A2E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Edit Application',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                  ),
                  onPressed: () async {
                    final Map<String, dynamic>? updatedData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UpdateApplicationScreen(
                          applicationId: widget.applicationId,
                          applicationData: widget.applicationData,
                        ),
                      ),
                    );
                    if (updatedData != null && mounted) {
                      setState(() {
                        widget.applicationData.addAll(updatedData);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isInterview) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white,
                      size: 18),
                  label: const Text(
                    'View Interview Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewInterviewScreen(
                        applicationData: widget.applicationData,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (!_isWithdrawnOrCancelled) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFEF4444), size: 18),
                  label: const Text(
                    'Withdraw Application',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _handleWithdraw,
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: NavBarWidget(
        currentIndex: 2,
        onTabSelected: (i) {
          if (i == 2) return;
          if (i == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SavedJobsScreen()),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(
                    user: FirebaseAuth.instance.currentUser),
              ),
            );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VIEW INTERVIEW SCREEN
// ─────────────────────────────────────────────
class ViewInterviewScreen extends StatelessWidget {
  final Map<String, dynamic> applicationData;

  const ViewInterviewScreen({
    super.key,
    required this.applicationData,
  });

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Not set';
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $period';
  }

  Future<void> _respondToInterview(
      BuildContext context, String applicationId, String response) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
        'interviewResponse': response,
        'status': response == 'accepted' ? 'interview' : 'reschedule_pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response == 'accepted'
                ? 'Interview accepted!'
                : 'Reschedule requested.'),
            backgroundColor: response == 'accepted'
                ? const Color(0xFF16A34A)
                : const Color(0xFFD97706),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d             = applicationData;
    final interviewDate = _formatTimestamp(d['interviewDate']);
    final candidateName = d['applicantName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Candidate';
    final location      = d['interviewLocation'] ?? d['interviewType'] ?? 'To be confirmed';
    final applicationId = d['applicationId'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Interview Info',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _InfoField(label: 'Candidate', value: candidateName),
            const SizedBox(height: 16),
            _InfoField(
                label: 'Scheduled Date & Time', value: interviewDate),
            const SizedBox(height: 16),
            _InfoField(label: 'Location / Platform', value: location),
            const SizedBox(height: 16),
            if (d['interviewNotes'] != null &&
                (d['interviewNotes'] as String).isNotEmpty) ...[
              _InfoField(
                  label: 'Notes from Employer',
                  value: d['interviewNotes']),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _respondToInterview(
                          context, applicationId, 'accepted'),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _respondToInterview(
                          context, applicationId, 'reschedule'),
                      child: const Text(
                        'Request Reschedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS CONFIG
// ─────────────────────────────────────────────
class _StatusConfig {
  final IconData icon;
  final String label;
  final String message;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _StatusConfig({
    required this.icon,
    required this.label,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String appliedAt;

  const _JobCard({
    required this.jobTitle,
    required this.company,
    required this.appliedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              company.isNotEmpty ? company[0].toUpperCase() : 'J',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
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
                jobTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                company,
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                    fontSize: 13),
              ),
              const SizedBox(height: 1),
              Text(
                'Applied on $appliedAt',
                style:
                const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String message;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const SizedBox(height: 2),
                Text(message,
                    style: const TextStyle(
                        color: Color(0xFF374151), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────

enum _StepState { done, active, pending }

class _TimelineStep {
  final String title;
  final String subtitle;
  final _StepState state;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

class _TrackingTimeline extends StatelessWidget {
  final String status;
  //const _TrackingTimeline({required this.status});

  final Map<String, dynamic> applicationData;

  const _TrackingTimeline({
    required this.status,
    required this.applicationData // Add this
  });

  String _formatTimelineTime(dynamic ts) {
    if (ts == null) return '';

    // 1. Convert to user's local timezone
    final DateTime localDateTime = (ts is Timestamp)
        ? ts.toDate().toLocal()
        : DateTime.now();

    final String dateStr = DateFormat.yMMMd().format(localDateTime);
    final String timeStr = DateFormat.jm().format(localDateTime);

    return '$dateStr  •  $timeStr';
  }

  // ── Build steps dynamically from real status ──────────────────────────
  List<_TimelineStep> _buildSteps() {
    final appliedTime = _formatTimelineTime(applicationData['appliedAt']);
    final reviewTime = (status != 'unprocessed')
        ? _formatTimelineTime(applicationData['updatedAt'])
        : '';
    final interviewTime = _formatTimelineTime(applicationData['interviewDate']);

    // ✅ New Index Logic for 5 steps
    int activeIndex;
    switch (status) {
      case 'unprocessed':  activeIndex = 0; break;
      case 'under review': activeIndex = 1; break;
      case 'shortlisted':  activeIndex = 2; break;
      case 'interview':    activeIndex = 3; break;
      default:             activeIndex = 4;
    }

    final labels = [
      ('Application Submitted', 'Received: $appliedTime'),
      ('Under Review', reviewTime.isNotEmpty ? 'Updated: $reviewTime' : 'Hiring team is reviewing your profile'),
      ('Shortlisted', 'Selected for the candidate pool'),
      ('Interview', interviewTime.isNotEmpty ? 'Scheduled: $interviewTime' : 'Interviewing with the team'),
      ('Final Decision', _finalDecisionLabel()),
    ];

    return List.generate(labels.length, (i) {
      _StepState state = (i < activeIndex) ? _StepState.done
          : (i == activeIndex) ? _StepState.active
          : _StepState.pending;
      return _TimelineStep(title: labels[i].$1, subtitle: labels[i].$2, state: state);
    });
  }

  String _finalDecisionLabel() {
    switch (status) {
      case 'declined':
      case 'rejected':  return 'Application declined';
      case 'withdrawn': return 'You withdrew this application';
      case 'cancelled': return 'Application cancelled';
      default:          return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Column(
      children: List.generate(steps.length, (i) {
        final step   = steps[i];
        final isLast = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _StepIcon(state: step.state),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: step.state == _StepState.done
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: step.state == _StepState.pending
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final _StepState state;

  const _StepIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _StepState.done:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case _StepState.active:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border:
            Border.all(color: const Color(0xFF2563EB), width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _StepState.pending:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFD1D5DB), width: 2),
          ),
        );
    }
  }
}

// ── Info field ────────────────────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}