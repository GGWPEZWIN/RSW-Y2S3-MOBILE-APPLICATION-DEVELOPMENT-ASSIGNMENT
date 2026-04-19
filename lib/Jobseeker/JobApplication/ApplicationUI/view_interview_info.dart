import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewInterviewScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic> initialData;

  const ViewInterviewScreen({
    super.key,
    required this.applicationId,
    required this.initialData,
  });

  @override
  State<ViewInterviewScreen> createState() => _ViewInterviewScreenState();
}

class _ViewInterviewScreenState extends State<ViewInterviewScreen> {
  late TextEditingController _reasonController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(
        text: widget.initialData['rescheduleReason'] ?? widget.initialData['rejectReason'] ?? ''
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Helper to pick Date
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Helper to pick Time
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatTsDate(dynamic ts) => (ts is Timestamp) ? DateFormat('dd/MM/yyyy').format(ts.toDate()) : 'N/A';
  String _formatTsTime(dynamic ts) => (ts is Timestamp) ? DateFormat('h:mm a').format(ts.toDate()).toLowerCase() : 'N/A';

  @override
  Widget build(BuildContext context) {
    // 1. Fetch the application document to get the candidate's name
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('applications').doc(widget.applicationId).get(),
      builder: (context, appSnapshot) {
        // Get the name from the application collection fallback
        final String applicationName = appSnapshot.data?.get('candidateName')
            ?? appSnapshot.data?.get('applicantName')
            ?? 'Candidate';

        // 2. Listen to the interview document for date/time/status updates
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('interviews').doc(widget.applicationId).snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic> d = widget.initialData;
            if (snapshot.hasData && snapshot.data!.exists) {
              d = snapshot.data!.data() as Map<String, dynamic>;
            }

            // Combine names: Priority to Interview doc, then Application doc, then 'Candidate'
            final String displayName = d['candidateName'] ?? d['applicantName'] ?? applicationName;

            final interviewTs = d['interviewTimestamp'];
            final currentStatus = d['status'] ?? 'scheduled';
            final bool isEditable = currentStatus == 'scheduled' || currentStatus == 'reschedule_proposed';

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: const BackButton(color: Colors.black),
                title: const Text('Interview Info',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 22)),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Now shows the real name from the application collection!
                    _PrototypeField(label: 'Candidate', value: displayName),
                    const SizedBox(height: 20),
                    _PrototypeField(label: 'Current Date', value: _formatTsDate(interviewTs)),
                    const SizedBox(height: 20),
                    _PrototypeField(label: 'Current Time', value: _formatTsTime(interviewTs)),
                    const SizedBox(height: 20),
                    _PrototypeField(label: 'Location', value: d['locationType'] ?? 'TBC'),

                    // Rest of your UI code...
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Propose New Date & Time section
                    const Text('Propose New Date & Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EditableSelector(
                            label: 'Date',
                            value: _selectedDate == null ? 'Select Date' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            onTap: isEditable ? () => _pickDate(context) : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _EditableSelector(
                            label: 'Time',
                            value: _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                            onTap: isEditable ? () => _pickTime(context) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('Reject Reason', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      enabled: isEditable,
                      decoration: InputDecoration(
                        hintText: "Why are you rescheduling?",
                        filled: true,
                        fillColor: const Color(0xFFE8E1F7),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (currentStatus == 'scheduled' || currentStatus == 'reschedule_proposed')
                      _buildActionButtons(context)
                    else
                      _statusBanner(currentStatus),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => _updateResponse('accepted'),
            child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () {
              if (_selectedDate == null || _selectedTime == null || _reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a new date, time, and provide a reason.")));
                return;
              }
              _updateResponse('reschedule_pending');
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Future<void> _updateResponse(String status) async {
    try {
      DateTime? finalReschedule;
      if (_selectedDate != null && _selectedTime != null) {
        finalReschedule = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      }

      final batch = FirebaseFirestore.instance.batch();
      final appRef = FirebaseFirestore.instance.collection('applications').doc(widget.applicationId);
      final ivRef = FirebaseFirestore.instance.collection('interviews').doc(widget.applicationId);

      batch.update(appRef, {'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      batch.update(ivRef, {
        'status': status,
        if (status == 'reschedule_pending') 'rescheduleReason': _reasonController.text,
        if (finalReschedule != null) 'rescheduleDate': Timestamp.fromDate(finalReschedule),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Widget _statusBanner(String status) {
    bool isRed = status == 'cancelled' || status == 'reschedule_pending';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isRed ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase().replaceAll('_', ' '), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.green)),
    );
  }
}

class _EditableSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _EditableSelector({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE8E1F7), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFB39DDB))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.w500)),
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF673AB7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeField extends StatelessWidget {
  final String label;
  final String value;
  const _PrototypeField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)), child: Text(value, style: const TextStyle(fontSize: 16))),
    ]);
  }
}