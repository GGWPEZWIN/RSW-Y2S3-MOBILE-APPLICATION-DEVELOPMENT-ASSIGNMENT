  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import '../../MainScreen/jobseeker_profile.dart';
  import '../../Widgets/nav_bar_widget.dart';
  import '../../InterviewPractice/interview_practice_screen.dart';
  import 'saved_job_list.dart';

  // ══════════════════════════════════════════════════════════════════════════════
  // APPLIED JOBS LIST SCREEN
  // ══════════════════════════════════════════════════════════════════════════════
  class AppliedJobsScreen extends StatefulWidget {
    const AppliedJobsScreen({Key? key}) : super(key: key);

    @override
    State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
  }

  class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
    bool _showWithdrawn = false;

    static const Color _cardColor     = Color(0xFF2D3A8C);
    static const Color _cardColorDeep = Color(0xFF1E2A6E);
    static const Color _bg            = Color(0xFFF4F5FA);

    Color _statusColor(String status) {
      switch (status.toLowerCase()) {
        case 'shortlisted':  return const Color(0xFF22C55E);
        case 'interview':    return const Color(0xFF8B5CF6);
        case 'unprocessed':  return const Color(0xFFF59E0B);
        case 'under review': return const Color(0xFF60A5FA);
        case 'reschedule_pending': return Colors.orange;
        case 'reschedule_proposed': return Colors.purple;
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
        case 'reschedule_pending': return 'RESCHEDULE PENDING';
        case 'reschedule_proposed': return 'RESCHEDULE PROPOSED';
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
                      color: const Color(0xFF3B52E8), borderRadius: BorderRadius.circular(20)),
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
          // ── Tab toggle ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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

          // ── List ──────────────────────────────────────────────────────────
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
                final docs = snap.data!.docs.where((d) {
                  final s = ((d.data() as Map)['status'] ?? '').toString();
                  return _showWithdrawn ? _isWithdrawn(s) : !_isWithdrawn(s);
                }).toList();

                if (docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.work_off_outlined, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      _showWithdrawn
                          ? 'No withdrawn applications.'
                          : 'No applications yet.\nStart applying!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            else if (i == 1) Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const SavedJobsScreen()));
            else if (i == 3) Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser)));
          },
        ),
      );
    }

    Widget _tabBtn(String label, bool active) => Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showWithdrawn = label == 'Withdrawn'),
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

    Widget _card(BuildContext context, String docId, Map<String, dynamic> d,
        String status, Color sCol) {
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

          // Status strip
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
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => JobseekerApplicationDetailScreen(
                      applicationId: docId, applicationData: d),
                )),
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

  // ══════════════════════════════════════════════════════════════════════════════
  // APPLICATION DETAIL SCREEN
  // ══════════════════════════════════════════════════════════════════════════════
  class JobseekerApplicationDetailScreen extends StatefulWidget {
    final String applicationId;
    final Map<String, dynamic> applicationData;

    const JobseekerApplicationDetailScreen({
      super.key,
      required this.applicationId,
      required this.applicationData,
    });

    @override
    State<JobseekerApplicationDetailScreen> createState() =>
        _JobseekerApplicationDetailScreenState();
  }

  class _JobseekerApplicationDetailScreenState
      extends State<JobseekerApplicationDetailScreen> {

    static const Color _blue      = Color(0xFF3B4FD8);
    static const Color _cardDark  = Color(0xFF2D3A8C);
    static const Color _cardDeep  = Color(0xFF1E2A6E);
    static const Color _bg        = Color(0xFFF3F4F8);

    bool _isBusy = false;

    // Application fields (read-only display)
    late final String _title, _company, _salary, _workType, _workplace,
        _education, _experienceLevel, _coverLetter, _portfolioUrl, _resume;
    late final List<String> _skills;
    late final DateTime _appliedAt;
    late String _status;

    @override
    void initState() {
      super.initState();
      final d = widget.applicationData;
      _title           = d['jobTitle']        ?? 'Unknown Job';
      _company         = d['company']         ?? '';
      _salary          = d['salary']          ?? '—';
      _workType        = d['workType']        ?? '';
      _workplace       = d['workplace']       ?? '';
      _education       = d['education']       ?? '—';
      _experienceLevel = d['experienceLevel'] ?? '—';
      _coverLetter     = d['coverLetter']     ?? '';
      _portfolioUrl    = d['portfolioUrl']    ?? '';
      _resume          = d['resume']          ?? '';
      _skills          = List<String>.from(d['skills'] ?? []);
      _status          = (d['status'] ?? 'unprocessed').toString();
      _appliedAt       = (d['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    }

    // ── Colour helpers ───────────────────────────────────────────────────────

    Color _sColor(String s) {
      switch (s.toLowerCase()) {
        case 'shortlisted':  return const Color(0xFF22C55E);
        case 'interview':    return const Color(0xFF8B5CF6);
        case 'unprocessed':  return const Color(0xFFF59E0B);
        case 'reschedule_pending': return Colors.orange;
        case 'reschedule_proposed': return Colors.purple;
        case 'declined':     return const Color(0xFFEF4444);
        case 'rejected':     return const Color(0xFFEF4444);
        case 'cancelled':     return const Color(0xFFEF4444);
        case 'withdrawn':    return const Color(0xFF94A3B8);
        default:             return const Color(0xFF94A3B8);
      }
    }

    String _sLabel(String s) {
      switch (s.toLowerCase()) {
        case 'unprocessed': return 'Pending Review';
        case 'shortlisted': return 'Shortlisted';
        case 'interview':   return 'Interview Scheduled';
        case 'reschedule_pending': return 'Reschedule Pending';
        case 'reschedule_proposed': return 'Reschedule Proposed';
        case 'declined':    return 'Declined';
        case 'rejected':    return 'Rejected';
        case 'cancelled':    return 'Cancelled';
        case 'withdrawn':    return 'Withdrawn';
        default:            return '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';
      }
    }

    // ── Firestore helpers ────────────────────────────────────────────────────

    Future<String> _getEmployerId() async {
      final doc = await FirebaseFirestore.instance
          .collection('interviews').doc(widget.applicationId).get();
      return (doc.data()?['employerId'] as String?) ?? '';
    }

    Future<void> _notifyEmployer({
      required String employerId,
      required String type,
      required String title,
      required String body,
      String? rescheduleReason,
    }) async {
      if (employerId.isEmpty) return;
      final uid  = FirebaseAuth.instance.currentUser?.uid ?? '';
      final d    = widget.applicationData;
      final data = <String, dynamic>{
        'employerId':      employerId,
        'applicationId':   widget.applicationId,
        'jobId':           d['jobId']         ?? '',
        'candidateUserId': uid,
        'candidateName':   d['candidateName'] ?? '',
        'jobTitle':        _title,
        'title':           title,
        'body':            body,
        'type':            type,
        'status':          'unread',
        'isRead':          false,
        'createdAt':       FieldValue.serverTimestamp(),
      };
      if (rescheduleReason != null) data['rescheduleReason'] = rescheduleReason;
      await FirebaseFirestore.instance.collection('employer_notifications').add(data);
    }

// ── Action: request reschedule (jobseeker initiates) ────────────────────
    Future<void> _requestReschedule() async {
      final reasonCtrl = TextEditingController();

      // 1. Get the reason from the dialog
      final ok = await _reasonDialog(
        title:       'Request Reschedule',
        subtitle:    'Please tell the employer why you need to reschedule.',
        hint:        'e.g. I have a prior commitment on that day...',
        confirmText: 'Send Request',
        confirmColor: _blue,
        ctrl:        reasonCtrl,
      );

      // 2. If user cancelled or dialog closed, stop here.
      if (!ok || !mounted) return;

      final reason = reasonCtrl.text.trim();
      if (reason.isEmpty) {
        _snack('Please enter a reason', Colors.red);
        return;
      }

      setState(() => _isBusy = true);

      try {
        final db = FirebaseFirestore.instance;

        // 3. Update the Application status
        await db.collection('applications').doc(widget.applicationId).update({
          'status': 'reschedule_pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update the Interview status
        await db.collection('interviews').doc(widget.applicationId).update({
          'status': 'reschedule_pending',
          'rescheduleReason': reason,
          'rescheduleBy': FirebaseAuth.instance.currentUser?.uid,
          'pendingAcceptance': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 4. Notify the employer
        final employerId = await _getEmployerId();
        await _notifyEmployer(
          employerId: employerId,
          type: 'reschedule_request',
          title: 'Interview Reschedule Request',
          body: 'A candidate has requested to reschedule the interview for $_title.',
          rescheduleReason: reason,
        );

        if (mounted) {
          _snack('Request sent successfully', Colors.green);
          // 5. Update local state to reflect change if not popping
          setState(() => _status = 'reschedule_pending');
        }
      } catch (e) {
        if (mounted) _snack('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isBusy = false);
        reasonCtrl.dispose();
      }
    }

    // ── Helper: Reason Dialog ────────────────────────────────────────────────
    Future<bool> _reasonDialog({
      required String title,
      required String subtitle,
      required String hint,
      required String confirmText,
      required Color confirmColor,
      required TextEditingController ctrl,
    }) async {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    void _snack(String msg, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }

    // ── Action: accept employer's proposed new time ──────────────────────────
    Future<void> _acceptReschedule() async {
      setState(() => _isBusy = true);
      try {
        final db         = FirebaseFirestore.instance;
        final employerId = await _getEmployerId();

        final batch = db.batch();
        batch.update(db.collection('interviews').doc(widget.applicationId), {
          'status':           'scheduled',
          'rescheduleReason': FieldValue.delete(),
          'rescheduleBy':     FieldValue.delete(),
          'pendingAcceptance': false,
          'updatedAt':        FieldValue.serverTimestamp(),
        });
        batch.update(db.collection('applications').doc(widget.applicationId), {
          'status': 'interview',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        await _notifyEmployer(
          employerId: employerId,
          type:       'reschedule_accepted',
          title:      'Reschedule Accepted',
          body:       '${widget.applicationData['candidateName'] ?? 'Candidate'} has accepted the new interview time.',
        );

        if (mounted) setState(() => _status = 'interview');
        _snack('New interview time accepted ✓', const Color(0xFF22C55E));
      } catch (e) {
        _snack('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    }

    // ── Action: decline employer's proposed new time (with reason) ──────────
    Future<void> _declineReschedule() async {
      final reasonCtrl = TextEditingController();
      final ok = await _reasonDialog(
        title:       'Decline New Time',
        subtitle:    'Please tell the employer why this time does not work.',
        hint:        'e.g. I am also unavailable on that date...',
        confirmText: 'Decline & Notify',
        confirmColor: Colors.red,
        ctrl:        reasonCtrl,
      );
      if (!ok || !mounted) return;

      final reason = reasonCtrl.text.trim();
      reasonCtrl.dispose();
      if (reason.isEmpty) { _snack('Please enter a reason', Colors.red); return; }

      setState(() => _isBusy = true);
      try {
        final db         = FirebaseFirestore.instance;
        final employerId = await _getEmployerId();

        final batch = db.batch();
        batch.update(db.collection('interviews').doc(widget.applicationId), {
          'status':           'reschedule_pending',
          'rescheduleReason': reason,
          'rescheduleBy':     FirebaseAuth.instance.currentUser?.uid,
          'pendingAcceptance': false,
          'updatedAt':        FieldValue.serverTimestamp(),
        });
        batch.update(db.collection('applications').doc(widget.applicationId), {
          'status': 'reschedule_pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        await _notifyEmployer(
          employerId:      employerId,
          type:            'reschedule_request',
          title:           'New Time Declined',
          body:            '${widget.applicationData['candidateName'] ?? 'Candidate'} declined the proposed time and submitted a new reschedule request.',
          rescheduleReason: reason,
        );

        if (mounted) setState(() => _status = 'reschedule_pending');
        _snack('Request sent — employer will propose another time', Colors.orange);
      } catch (e) {
        _snack('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    }

    // ── Action: cancel interview ─────────────────────────────────────────────
    Future<void> _cancelInterview() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Withdraw Application',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
          content: const Text(
            'Are you sure you want to withdraw this application? The employer will be notified.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, Keep It', style: TextStyle(color: Color(0xFF6B7280)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Withdraw', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _isBusy = true);
      try {
        final db         = FirebaseFirestore.instance;
        final employerId = await _getEmployerId();

        final batch = db.batch();
        batch.update(db.collection('interviews').doc(widget.applicationId), {
          'status':    'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.update(db.collection('applications').doc(widget.applicationId), {
          'status':    'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        await _notifyEmployer(
          employerId: employerId,
          type:       'interview_cancelled',
          title:      'Application Withdrawn',
          body:       '${widget.applicationData['candidateName'] ?? 'Candidate'} has withdrawn their application for $_title.',
        );

        if (mounted) setState(() => _status = 'cancelled');
        _snack('Application withdrawn successfully', Colors.orange);
      } catch (e) {
        _snack('Error: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    }

    // ── Build ────────────────────────────────────────────────────────────────

    @override
    Widget build(BuildContext context) {
      final isWithdrawn = _status.toLowerCase() == 'withdrawn' || _status.toLowerCase() == 'cancelled';

      return Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(slivers: [

          // ── Sliver app bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _cardDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_cardDark, _cardDeep],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: SafeArea(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(_title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.3)),
                        if (_company.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_company, style: TextStyle(
                              fontSize: 14, color: Colors.white.withOpacity(0.75))),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _sColor(_status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _sColor(_status).withOpacity(0.6)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 7, height: 7,
                                decoration: BoxDecoration(
                                    color: _sColor(_status), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(_sLabel(_status), style: TextStyle(
                                color: _sColor(_status), fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                )),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Interview panel ───────────────────────────────────────────
              if (!isWithdrawn && (_status.toLowerCase() == 'interview' || 
                  _status.toLowerCase() == 'reschedule_pending' || 
                  _status.toLowerCase() == 'reschedule_proposed')) ...[
                _sectionTitle('🗓  Interview Details'),
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('interviews')
                      .doc(widget.applicationId)
                      .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData || !snap.data!.exists) {
                      return _card([_row(Icons.info_outline, 'Info', 'Loading...')]);
                    }
                    final iv = snap.data!.data() as Map<String, dynamic>;
                    return _interviewPanel(iv);
                  },
                ),
                const SizedBox(height: 24),
              ],

              // ── Application info ──────────────────────────────────────────
              _sectionTitle('Application Info'),
              const SizedBox(height: 12),
              _card([
                _row(Icons.work_outline,              'Job Title',   _title),
                _row(Icons.business_center_outlined,  'Work Type',   _workType),
                _row(Icons.location_on_outlined,       'Workplace',   _workplace),
                _row(Icons.attach_money_rounded,       'Salary',      _salary),
                _row(Icons.school_outlined,            'Education',   _education),
                _row(Icons.timeline_outlined,          'Experience',  _experienceLevel),
                _row(Icons.calendar_today_outlined,    'Applied',
                    '${_appliedAt.day}/${_appliedAt.month}/${_appliedAt.year}'),
              ]),

              // ── Skills ────────────────────────────────────────────────────
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Skills'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                    children: _skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: _blue, borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    )).toList()),
              ],

              // ── Cover letter ──────────────────────────────────────────────
              if (_coverLetter.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Cover Letter'),
                const SizedBox(height: 12),
                _whiteBox(child: Text(_coverLetter,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.6))),
              ],

              // ── Portfolio ─────────────────────────────────────────────────
              if (_portfolioUrl.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Portfolio'),
                const SizedBox(height: 12),
                _whiteBox(child: Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF0FF),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.link_rounded, color: _blue, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_portfolioUrl,
                      style: const TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                ])),
              ],

              // ── CV ────────────────────────────────────────────────────────
              if (_resume.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('My CV / Resume'),
                const SizedBox(height: 12),
                _CvViewer(base64Image: _resume),
              ],

              if (!isWithdrawn) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _cancelInterview,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Withdraw Application', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40), // Bottom padding
            ]),
          )),
        ]),
      );
    }

    // ── Interview panel widget ───────────────────────────────────────────────

    Widget _interviewPanel(Map<String, dynamic> iv) {
      final ts              = iv['interviewTimestamp'] as Timestamp?;
      final dt              = ts?.toDate();
      final ivStatus        = (iv['status'] as String?) ?? 'scheduled';
      final locationType    = (iv['locationType']  as String?) ?? '—';
      final locationDetail  = (iv['locationDetail'] as String?) ?? '';
      final notes           = (iv['notes']          as String?) ?? '';
      final rescheduleReason = (iv['rescheduleReason'] as String?) ?? '';
      final pendingAcceptance = (iv['pendingAcceptance'] as bool?) ?? false;

      final dtStr = dt == null
          ? '—'
          : '${_wday(dt.weekday)}, ${dt.day} ${_mon(dt.month)} ${dt.year}  •  ${_fmtTime(dt)}';

      final isAwaitingEmployer = ivStatus == 'reschedule_pending';
      final isNewTimeProposed  = ivStatus == 'reschedule_proposed';
      final isCancelled        = ivStatus == 'cancelled';
      final isScheduled        = ivStatus == 'scheduled';

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Banner: awaiting employer ──────────────────────────────────────
        if (isAwaitingEmployer) ...[
          _banner(
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
            icon: Icons.schedule_rounded,
            text: 'Your reschedule request has been sent. Waiting for the employer to propose a new time.',
          ),
          const SizedBox(height: 12),
        ],

        // ── Banner: new time proposed by employer ──────────────────────────
        if (isNewTimeProposed) ...[
          _banner(
            color: _blue,
            bgColor: const Color(0xFFEEF2FF),
            icon: Icons.event_available_rounded,
            text: 'The employer has proposed a new interview time. Please review and respond.',
          ),
          const SizedBox(height: 12),
        ],

        // ── Interview info card ────────────────────────────────────────────
        _card([
          _row(Icons.calendar_today_outlined, 'Date & Time', dtStr),
          _row(Icons.videocam_outlined,        'Format',     locationType),
          if (locationDetail.isNotEmpty && locationDetail != '—')
            _row(Icons.link_rounded,           'Link / Venue', locationDetail),
          if (notes.isNotEmpty)
            _row(Icons.notes_rounded,          'Notes', notes),
        ]),

        // ── Reason submitted by jobseeker (visible while awaiting) ─────────
        if (isAwaitingEmployer && rescheduleReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          _whiteBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Reason', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(rescheduleReason, style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
          ])),
        ],

        // ── Action buttons ─────────────────────────────────────────────────
        const SizedBox(height: 14),

        // NEW TIME PROPOSED → Accept / Decline
        if (isNewTimeProposed) Row(children: [
          Expanded(child: _actionBtn(
            label: 'Accept New Time',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF22C55E),
            onTap: _isBusy ? null : _acceptReschedule,
          )),
          const SizedBox(width: 10),
          Expanded(child: _actionBtn(
            label: 'Decline & Reason',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onTap: _isBusy ? null : _declineReschedule,
          )),
        ]),

        // SCHEDULED (normal) → Request reschedule / Cancel
        if (isScheduled) Row(children: [
          Expanded(child: _actionBtn(
            label: 'Request Reschedule',
            icon: Icons.schedule_rounded,
            color: _blue,
            onTap: _isBusy ? null : _requestReschedule,
          )),
          const SizedBox(width: 10),
          Expanded(child: _actionBtn(
            label: 'Cancel Interview',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onTap: _isBusy ? null : _cancelInterview,
          )),
        ]),

        // CANCELLED
        if (isCancelled)
          _banner(
            color: Colors.red,
            bgColor: const Color(0xFFFEF2F2),
            icon: Icons.cancel_outlined,
            text: 'This interview has been cancelled.',
          ),
      ]);
    }

    // ── Reusable widget helpers ──────────────────────────────────────────────

    Widget _sectionTitle(String t) => Text(t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E)));

    Widget _card(List<Widget> rows) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: rows),
    );

    Widget _row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Icon(icon, size: 18, color: _blue),
        const SizedBox(width: 12),
        SizedBox(width: 95, child: Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
      ]),
    );

    Widget _whiteBox({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );

    Widget _banner({
      required Color color,
      required Color bgColor,
      required IconData icon,
      required String text,
    }) =>
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500, height: 1.4))),
          ]),
        );

    Widget _actionBtn({
      required String label,
      required IconData icon,
      required Color color,
      VoidCallback? onTap,
    }) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ),
        );

    // Date helpers
    String _wday(int w) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w - 1];
    String _mon(int m)  => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
    String _fmtTime(DateTime dt) {
      final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$h:$mm ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // CV VIEWER
  // ══════════════════════════════════════════════════════════════════════════════
  class _CvViewer extends StatefulWidget {
    final String base64Image;
    const _CvViewer({required this.base64Image});

    @override
    State<_CvViewer> createState() => _CvViewerState();
  }

  class _CvViewerState extends State<_CvViewer> {
    static const Color _blue = Color(0xFF3B4FD8);
    bool _expanded = false;

    @override
    Widget build(BuildContext context) {
      late final bytes = base64Decode(widget.base64Image);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: _expanded
                ? Image.memory(bytes, fit: BoxFit.contain, width: double.infinity,
                errorBuilder: (_, __, ___) => _err())
                : SizedBox(height: 280,
                child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => _err())),
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
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: _blue, size: 20),
                const SizedBox(width: 6),
                Text(_expanded ? 'Collapse' : 'View full CV',
                    style: const TextStyle(
                        color: _blue, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      );
    }

    Widget _err() => Container(
      height: 100, color: const Color(0xFFF3F4F8),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF9CA3AF)),
        SizedBox(height: 6),
        Text('Unable to display CV',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
      ])),
    );
  }