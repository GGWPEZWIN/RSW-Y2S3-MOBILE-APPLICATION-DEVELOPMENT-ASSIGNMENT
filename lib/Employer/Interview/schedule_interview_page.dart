import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class ScheduleInterviewPage extends StatefulWidget {
  final String candidateName;
  final String jobTitle;

  const ScheduleInterviewPage({
    super.key,
    required this.candidateName,
    required this.jobTitle,
  });

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'In-Person';
  bool _isSending = false;

  final List<String> _interviewTypes = ['In-Person', 'Online', 'Phone Call'];

  // ─── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF425AE2)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF425AE2)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _scheduleInterview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final interviewDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final dateStr =
        '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    final timeStr = _selectedTime!.format(context);

    try {
      // 1️⃣  Immediate notification — candidate sees this right away
      await NotificationService().sendInterviewScheduledNotification(
        candidateName: widget.candidateName,
        jobTitle: widget.jobTitle,
        interviewDate: dateStr,
        interviewTime: timeStr,
        location: _locationController.text.trim(),
        meetingLink: _interviewType == 'Online'
            ? _meetingLinkController.text.trim()
            : null,
      );

      // 2️⃣  Reminder notification 1 hour before the interview
      await NotificationService().scheduleInterviewReminder(
        candidateName: widget.candidateName,
        jobTitle: widget.jobTitle,
        interviewDateTime: interviewDateTime,
        minutesBefore: 60,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Interview scheduled! ${widget.candidateName} has been notified.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // return true = success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Interview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF425AE2),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Candidate Info Banner
              _buildCandidateBanner(),
              const SizedBox(height: 24),

              // Interview Type
              _sectionLabel('Interview Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _interviewTypes.map((type) {
                  final selected = _interviewType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _interviewType = type),
                    selectedColor: const Color(0xFF425AE2),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date & Time Row
              _sectionLabel('Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildDateButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeButton()),
                ],
              ),
              const SizedBox(height: 20),

              // Location / Link
              if (_interviewType == 'Online') ...[
                _sectionLabel('Meeting Link'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _meetingLinkController,
                  decoration: _inputDecoration(
                    'https://meet.google.com/...',
                    Icons.videocam_outlined,
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter meeting link' : null,
                ),
              ] else if (_interviewType == 'In-Person') ...[
                _sectionLabel('Location'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                    'Office address or room number',
                    Icons.location_on_outlined,
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter location' : null,
                ),
              ] else ...[
                _sectionLabel('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    'Interviewer phone number',
                    Icons.phone_outlined,
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter phone number' : null,
                ),
              ],
              const SizedBox(height: 20),

              // Notes
              _sectionLabel('Notes for Candidate (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Bring your portfolio, dress code...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),

              // Notification Preview Card
              _buildNotificationPreview(),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _scheduleInterview,
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.notifications_active, color: Colors.white),
                  label: Text(
                    _isSending ? 'Sending...' : 'Schedule & Notify Candidate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF425AE2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildCandidateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF425AE2), Color(0xFF6B4EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.candidateName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Applying for: ${widget.jobTitle}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Shortlisted',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF425AE2)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF425AE2)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
                style: TextStyle(
                  color: _selectedTime == null ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 16, color: Color(0xFF425AE2)),
              const SizedBox(width: 6),
              const Text(
                'Notification Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF425AE2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF425AE2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.work_outline,
                      color: Color(0xFF425AE2), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 Interview Scheduled — ${widget.jobTitle}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hi ${widget.candidateName}! Your interview for ${widget.jobTitle} is on '
                            '${_selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : '[date]'} '
                            'at ${_selectedTime != null ? _selectedTime!.format(context) : '[time]'}.',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ A reminder will also be sent 1 hour before the interview.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _meetingLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}