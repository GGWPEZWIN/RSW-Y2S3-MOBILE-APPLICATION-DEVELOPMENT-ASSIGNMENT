import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Local notifier ────────────────────────────────────────────────────────────
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
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'interview_channel', 'Interview Notifications',
      description: 'Interview schedule updates',
      importance: Importance.max,
    ));
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
          color: Color(0xFF3B4FD8), icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ScheduleInterviewPage extends StatefulWidget {
  final String applicationId;
  final String candidateUserId; // FK → users/{uid}
  final String jobId;           // FK → jobs/{jobId}
  final String jobTitle;        // display only
  final String candidateName;   // display only
  final String candidateEmail;  // display only
  final Map<String, dynamic>? existingInterview;
  final String? rescheduleReason; // set when opened from employer notifications

  const ScheduleInterviewPage({
    super.key,
    required this.applicationId,
    required this.candidateUserId,
    required this.jobId,
    required this.jobTitle,
    required this.candidateName,
    required this.candidateEmail,
    this.existingInterview,
    this.rescheduleReason,
  });

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final _formKey      = GlobalKey<FormState>();
  final _notesCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  String     _locationType = 'On-site';
  bool       _isSaving     = false;
  bool       _isCancelling = false;

  bool get _isEditing => widget.existingInterview != null;
  // True when employer is reviewing a reschedule request
  bool get _isRescheduling => widget.rescheduleReason != null;

  static const Color kBlue    = Color(0xFF3B4FD8);
  static const Color kBg      = Color(0xFFF5F6FA);
  static const Color kCard    = Colors.white;
  static const Color kText    = Color(0xFF0F172A);
  static const Color kSubtext = Color(0xFF64748B);
  static const Color kBorder  = Color(0xFFE2E8F0);
  static const Color kOrange  = Color(0xFFF59E0B);
  static const Color kRed     = Color(0xFFEF4444);

  final List<String> _locationTypes = [
    'On-site', 'Zoom', 'Google Meet', 'Phone Call',
  ];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final e = widget.existingInterview;
    if (e == null) return;
    final ts = e['interviewTimestamp'] as Timestamp?;
    if (ts != null) {
      final dt = ts.toDate();
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    _locationType      = e['locationType']   ?? 'On-site';
    _locationCtrl.text = e['locationDetail'] ?? '';
    _notesCtrl.text    = e['notes']          ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now, lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kBlue)),
        child: child!,
      ),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  Future<void> _pickTime() async {
    final p = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kBlue)),
        child: child!,
      ),
    );
    if (p != null) setState(() => _selectedTime = p);
  }

  // ── Save / Update ──────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      _snack('Please select both date and time.', Colors.orange);
      return;
    }
    if (_locationType == 'On-site' && _locationCtrl.text.trim().isEmpty) {
      _snack('Please enter the interview address.', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final employer = FirebaseAuth.instance.currentUser;
      final interviewTimestamp = Timestamp.fromDate(DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      ));

      final dateStr       = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      final timeFormatted = _selectedTime!.format(context);
      final locationText  = _locationType == 'On-site' &&
          _locationCtrl.text.trim().isNotEmpty
          ? _locationCtrl.text.trim()
          : _locationType;

      final db = FirebaseFirestore.instance;

      // Logic: If the employer is responding to a reschedule request,
      // the status becomes 'reschedule_proposed' (waiting for candidate approval).
      // If it's a fresh schedule or a standard edit, it stays 'scheduled'.
      final targetStatus = _isRescheduling ? 'reschedule_proposed' : 'scheduled';

      // Status name for the 'applications' collection
      final appCollectionStatus = _isRescheduling ? 'reschedule_proposed' : 'interview';

      final interviewData = <String, dynamic>{
        'applicationId':      widget.applicationId,
        'jobId':              widget.jobId,
        'candidateUserId':    widget.candidateUserId,
        'employerId':         employer?.uid ?? '',
        'interviewTimestamp': interviewTimestamp,
        'locationType':       _locationType,
        'locationDetail':     _locationCtrl.text.trim(),
        'notes':              _notesCtrl.text.trim(),
        'status':             targetStatus,
        'updatedAt':          FieldValue.serverTimestamp(),
        if (_isRescheduling) 'pendingAcceptance': true,
        // Remove these fields so the request is considered "resolved"
        'rescheduleReason':   FieldValue.delete(),
        'rescheduleBy':       FieldValue.delete(),
      };

      final batch        = db.batch();
      final interviewRef = db.collection('interviews').doc(widget.applicationId);

      if (_isEditing) {
        batch.update(interviewRef, interviewData);
      } else {
        // If creating new, remove the delete instructions and add createdAt
        interviewData.remove('rescheduleReason');
        interviewData.remove('rescheduleBy');
        interviewData['createdAt'] = FieldValue.serverTimestamp();
        batch.set(interviewRef, interviewData);
      }

      // Update the main applications collection status
      batch.update(
        db.collection('applications').doc(widget.applicationId),
        {
          'status': appCollectionStatus,
          'updatedAt': FieldValue.serverTimestamp()
        },
      );

      await batch.commit();

      // ── Notifications ──
      final notifTitle = _isRescheduling
          ? '📅 New Interview Time Proposed'
          : '📅 Interview ${_isEditing ? 'Updated' : 'Scheduled'}';

      final notifBody = 'For ${widget.jobTitle}: $dateStr at $timeFormatted ($locationText). '
          'Please check the app to confirm.';

      if (widget.candidateUserId.isNotEmpty) {
        await db
            .collection('users')
            .doc(widget.candidateUserId)
            .collection('notifications')
            .add({
          'applicationId':      widget.applicationId,
          'jobId':              widget.jobId,
          'title':              notifTitle,
          'body':               notifBody,
          'type':               _isRescheduling ? 'reschedule_proposal' : 'interview',
          'isRead':             false,
          'createdAt':          FieldValue.serverTimestamp(),
        });
      }

      await _LocalNotifier.show(notifTitle, notifBody);

      if (!mounted) return;
      _snack(_isRescheduling ? 'Proposed new time to candidate!' : 'Interview saved!', const Color(0xFF22C55E));
      Navigator.pop(context, true);

    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Cancel interview ───────────────────────────────────────────────────────

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.cancel_rounded, color: kRed, size: 22),
          SizedBox(width: 8),
          Text('Cancel Interview?'),
        ]),
        content: Text(
            'Cancel the interview for ${widget.candidateName}? '
                'The candidate will be notified.'),
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
    setState(() => _isCancelling = true);

    try {
      final db    = FirebaseFirestore.instance;
      final batch = db.batch();

      // Update interview status
      batch.update(
        db.collection('interviews').doc(widget.applicationId),
        {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()},
      );
      // Revert application status
      batch.update(
        db.collection('applications').doc(widget.applicationId),
        {'status': 'shortlisted', 'updatedAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();

      const notifTitle = '❌ Interview Cancelled';
      final notifBody  =
          'Hi ${widget.candidateName}! Your interview for ${widget.jobTitle} '
          'has been cancelled by the employer. Please contact them for more info.';

      // Notify candidate inbox
      if (widget.candidateUserId.isNotEmpty) {
        await db
            .collection('users')
            .doc(widget.candidateUserId)
            .collection('notifications')
            .add({
          'applicationId': widget.applicationId,
          'jobId':         widget.jobId,
          'title':         notifTitle,
          'body':          notifBody,
          'type':          'interview_cancelled',
          'isRead':        false,
          'createdAt':     FieldValue.serverTimestamp(),
        });
      }

      await _LocalNotifier.show(notifTitle, notifBody);

      if (!mounted) return;
      _snack('Interview cancelled. ${widget.candidateName} has been notified.',
          kRed, floating: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _snack(String msg, Color bg, {bool floating = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      shape: floating
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          : null,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          _isRescheduling
              ? 'Review Reschedule Request'
              : _isEditing
              ? 'Edit Interview'
              : 'Schedule Interview',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: _isRescheduling ? kOrange : kBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // Cancel interview button in app bar (only when editing an active interview)
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isCancelling
                  ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.event_busy_rounded),
              tooltip: 'Cancel Interview',
              onPressed: _isCancelling ? null : _handleCancel,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _candidateBanner(),
              const SizedBox(height: 16),

              // ── Reschedule reason banner ─────────────────────────────────
              if (_isRescheduling) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kOrange.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.schedule_rounded,
                            size: 16, color: kOrange),
                        const SizedBox(width: 6),
                        const Text('Candidate\'s Reason',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kOrange)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        '"${widget.rescheduleReason}"',
                        style: const TextStyle(
                            fontSize: 13,
                            color: kOrange,
                            fontStyle: FontStyle.italic,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Update the date, time or location below and tap '
                            '"Confirm Reschedule" to renotify the candidate.',
                        style: TextStyle(fontSize: 12, color: kSubtext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _label('Interview Date & Time'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _datePicker()),
                const SizedBox(width: 12),
                Expanded(child: _timePicker()),
              ]),
              const SizedBox(height: 20),

              _label('Interview Location'),
              const SizedBox(height: 10),
              _locationDropdown(),
              const SizedBox(height: 12),

              if (_locationType == 'On-site')
                _field(
                  controller: _locationCtrl,
                  hint: 'e.g. Level 3, Menara JobBuddy, Penang',
                  icon: Icons.location_on_outlined, label: 'Address',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter address' : null,
                )
              else if (_locationType == 'Zoom' || _locationType == 'Google Meet')
                _field(
                  controller: _locationCtrl,
                  hint: _locationType == 'Zoom'
                      ? 'https://zoom.us/j/...' : 'https://meet.google.com/...',
                  icon: Icons.videocam_outlined, label: 'Meeting Link (optional)',
                )
              else
                _field(
                  controller: _locationCtrl,
                  hint: 'e.g. +60 12-345 6789',
                  icon: Icons.phone_outlined, label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
              const SizedBox(height: 20),

              _label('Notes for Candidate'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl, maxLines: 4,
                style: const TextStyle(fontSize: 14, color: kText),
                decoration: InputDecoration(
                  hintText: 'e.g. Please bring your portfolio.',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFFADBAC7)),
                  filled: true, fillColor: kCard,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _notificationPreview(),
              const SizedBox(height: 32),

              // ── Primary action button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.notifications_active_rounded,
                      color: Colors.white, size: 20),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isRescheduling
                        ? 'Confirm Reschedule & Renotify'
                        : _isEditing
                        ? 'Update & Notify Candidate'
                        : 'Schedule & Notify Candidate',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isRescheduling ? kOrange : kBlue,
                    disabledBackgroundColor: kBlue.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              // ── Cancel interview button (below, only when editing) ─────
              if (_isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: (_isCancelling || _isSaving)
                        ? null
                        : _handleCancel,
                    icon: _isCancelling
                        ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: kRed, strokeWidth: 2))
                        : const Icon(Icons.event_busy_rounded,
                        color: kRed, size: 18),
                    label: const Text('Cancel Interview',
                        style: TextStyle(
                            color: kRed,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _candidateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isRescheduling
              ? [Colors.orange.shade700, Colors.orange.shade400] // Orange for Rescheduling
              : [kBlue, const Color(0xFF5B6EF0)],               // Blue for standard
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26, backgroundColor: Colors.white24,
          child: Text(
            widget.candidateName.isNotEmpty
                ? widget.candidateName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.candidateName,
                style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.candidateEmail,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Applying for: ${widget.jobTitle}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(20)),
          child: Text(
            _isRescheduling ? 'Reschedule' : _isEditing ? 'Editing' : 'New',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ]),
    );
  }

  Widget _datePicker() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 18, color: kBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(
          _selectedDate == null ? 'Select Date'
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: TextStyle(fontSize: 13,
              color: _selectedDate == null ? kSubtext : kText,
              fontWeight: FontWeight.w500),
        )),
      ]),
    ),
  );

  Widget _timePicker() => GestureDetector(
    onTap: _pickTime,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        const Icon(Icons.access_time_rounded, size: 18, color: kBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(
          _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
          style: TextStyle(fontSize: 13,
              color: _selectedTime == null ? kSubtext : kText,
              fontWeight: FontWeight.w500),
        )),
      ]),
    ),
  );

  Widget _locationDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: kCard, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _locationType, isExpanded: true,
        icon: const Icon(Icons.expand_more_rounded, color: kSubtext),
        style: const TextStyle(fontSize: 14, color: kText),
        items: _locationTypes.map((type) {
          IconData icon;
          switch (type) {
            case 'Zoom':        icon = Icons.videocam_rounded; break;
            case 'Google Meet': icon = Icons.meeting_room_rounded; break;
            case 'Phone Call':  icon = Icons.phone_rounded; break;
            default:            icon = Icons.location_on_rounded;
          }
          return DropdownMenuItem(value: type,
              child: Row(children: [
                Icon(icon, size: 18, color: kBlue),
                const SizedBox(width: 10), Text(type),
              ]));
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() { _locationType = v; _locationCtrl.clear(); });
        },
      ),
    ),
  );

  Widget _notificationPreview() {
    final dateText = _selectedDate != null
        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
        : '[date]';
    final timeText =
    _selectedTime != null ? _selectedTime!.format(context) : '[time]';
    final locationText =
    _locationType == 'On-site' && _locationCtrl.text.isNotEmpty
        ? _locationCtrl.text : _locationType;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_outlined, size: 15, color: kBlue),
          const SizedBox(width: 6),
          const Text('Notification Preview',
              style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold, color: kBlue)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _isRescheduling
                  ? '📅 Interview Rescheduled — ${widget.jobTitle}'
                  : '📅 Interview Scheduled — ${widget.jobTitle}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: kText),
            ),
            const SizedBox(height: 6),
            Text(
              'Hi ${widget.candidateName}! Your interview for ${widget.jobTitle} '
                  'is on $dateText at $timeText. Location: $locationText.',
              style: const TextStyle(fontSize: 12, color: kSubtext, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.check_circle_outline_rounded, size: 13, color: kBlue),
          const SizedBox(width: 5),
          const Text('Phone notification + in-app inbox',
              style: TextStyle(fontSize: 11, color: kSubtext)),
        ]),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText));

  Widget _field({
    required TextEditingController controller,
    required String hint, required IconData icon, required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, validator: validator,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADBAC7)),
        labelStyle: const TextStyle(fontSize: 13, color: kSubtext),
        prefixIcon: Icon(icon, size: 20, color: kBlue),
        filled: true, fillColor: kCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}