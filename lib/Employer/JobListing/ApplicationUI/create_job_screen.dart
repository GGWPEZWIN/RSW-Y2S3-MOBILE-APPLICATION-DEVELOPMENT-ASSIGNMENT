import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';
import 'job_list_screen.dart';

class CreateJobPage extends StatefulWidget {
  final Job? jobToEdit;

  const CreateJobPage({super.key, this.jobToEdit});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool get isEditing => widget.jobToEdit != null;

  late TextEditingController _jobTitleController;
  late TextEditingController _locationController;
  late TextEditingController _minPayController;
  late TextEditingController _maxPayController;

  String _selectedWorkplace = 'On-site';
  String _selectedWorkType = 'Full-time';
  String _selectedPayType = 'Monthly';
  String _selectedCurrency = 'MYR';
  String _showPayOnAd = 'Yes';

  final int _currentStep = 0;
  final List<String> _stepLabels = ['Classify', 'Ad Types', 'Write', 'Manage'];
  final List<String> _workTypeOptions = ['Full-time', 'Part-time', 'Contract', 'Casual'];
  final List<String> _payTypeOptions = ['Hourly', 'Monthly', 'Annually'];
  final List<String> _currencyOptions = ['MYR', 'USD', 'SGD', 'EUR'];

  static const Color _primaryBlue = Color(0xFF3B4FD8);
  static const Color _inactiveGrey = Color(0xFFBDBDBD);
  static const Color _borderColor = Color(0xFFDDDDDD);
  static const Color _fillColor = Color(0xFFFAFAFA);
  static const Color _labelColor = Color(0xFF1A1A2E);
  static const Color _hintColor = Color(0xFFAAAAAA);
  static const Color _helperColor = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _jobTitleController = TextEditingController();
    _locationController = TextEditingController();
    _minPayController = TextEditingController();
    _maxPayController = TextEditingController();

    if (isEditing) {
      final job = widget.jobToEdit!;
      _jobTitleController.text = job.title;
      _locationController.text = job.location;
      _selectedWorkplace = job.workplace;
      _selectedWorkType = job.workType;

      final salaryClean = job.salary.replaceAll(RegExp(r'[^0-9\s-]'), '');
      final parts = salaryClean.split('-');
      if (parts.length == 2) {
        _minPayController.text = parts[0].trim();
        _maxPayController.text = parts[1].trim();
      }
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _locationController.dispose();
    _minPayController.dispose();
    _maxPayController.dispose();
    super.dispose();
  }

  // ── FIXED _saveJob: single Navigator.pop, no finally-pop ─────────────────
  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final salary =
          'RM${_minPayController.text.trim()} - RM${_maxPayController.text.trim()}';
      final now = DateTime.now();

      final jobData = {
        'title': _jobTitleController.text.trim(),
        'company': isEditing ? widget.jobToEdit!.company : 'Your Company',
        'location': _locationController.text.trim(),
        'workType': _selectedWorkType,
        'workplace': _selectedWorkplace,
        'salary': salary,
        'postedTime': _getTimeAgo(now),
        'applicants': isEditing ? widget.jobToEdit!.applicants : '0 applied',
        'createdAt': isEditing ? widget.jobToEdit!.createdAt : now,
      };

      if (isEditing && widget.jobToEdit!.id != null) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobToEdit!.id)
            .update(jobData);
      } else {
        await FirebaseFirestore.instance.collection('jobs').add(jobData);
      }

      // ✅ Stop loading spinner first
      if (mounted) setState(() => _isSaving = false);

      // ✅ Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Job updated successfully!' : 'Job created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // ✅ Single pop — returns to the screen that pushed this page
      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      // ✅ Stop spinner on error too
      if (mounted) setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // ✅ NO finally block with Navigator.pop — that was the root cause
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  // ── Stepper ───────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    if (isEditing) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          final isLast = i == _stepLabels.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive || isDone ? _primaryBlue : Colors.white,
                          border: Border.all(
                            color: isActive || isDone ? _primaryBlue : _inactiveGrey,
                            width: isActive ? 5 : 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? _primaryBlue : _inactiveGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < _currentStep ? _primaryBlue : _inactiveGrey,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _labelColor),
          ),
          if (showInfo) ...[
            const SizedBox(width: 4),
            const Icon(Icons.help_outline_rounded, size: 16, color: _inactiveGrey),
          ],
        ],
      ),
    );
  }

  Widget _helperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _helperColor)),
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
      prefixIcon: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: _fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _chipSelector({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final active = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: active ? _primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: active ? _primaryBlue : _borderColor,
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : const Color(0xFF444444),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _currencyDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _fillColor,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          style: const TextStyle(fontSize: 14, color: _labelColor),
          items: _currencyOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCurrency = v!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit job ad' : 'Create a job ad',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
      body: _isSaving
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Saving...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepper(),
              if (!isEditing) const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),

              // Job Title
              _sectionLabel('Job Title', showInfo: true),
              TextFormField(
                controller: _jobTitleController,
                decoration: _fieldDecoration(
                  hint: 'Enter a simple job title (e.g. Sales Assistant)',
                  prefix: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.work_outline_rounded,
                        size: 20, color: Colors.grey[400]),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please add job title'
                    : null,
              ),
              const SizedBox(height: 20),

              // Location
              _sectionLabel('Location', showInfo: true),
              TextFormField(
                controller: _locationController,
                decoration: _fieldDecoration(
                  hint: 'Enter a suburb, city or region (e.g. Kuala Lumpur)',
                  prefix: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.location_on_outlined,
                        size: 20, color: _inactiveGrey),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter location'
                    : null,
              ),
              _helperText('Suggestions will appear below the field as you type'),
              const SizedBox(height: 16),

              // Workplace Option
              _sectionLabel('Workplace Option'),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _fillColor,
                  border: Border.all(color: _borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWorkplace,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: Colors.grey),
                    style: const TextStyle(fontSize: 14, color: _labelColor),
                    items: ['On-site', 'Remote', 'Hybrid']
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedWorkplace = v!),
                  ),
                ),
              ),
              _helperText('Suggestions will appear below the field as you type'),
              const SizedBox(height: 16),

              // Work Type
              _sectionLabel('Work type'),
              _chipSelector(
                options: _workTypeOptions,
                selected: _selectedWorkType,
                onSelect: (v) => setState(() => _selectedWorkType = v),
              ),
              const SizedBox(height: 20),

              // Pay Type
              _sectionLabel('Pay type'),
              _chipSelector(
                options: _payTypeOptions,
                selected: _selectedPayType,
                onSelect: (v) => setState(() => _selectedPayType = v),
              ),
              const SizedBox(height: 20),

              // Pay Range
              _sectionLabel('Pay Range', showInfo: true),
              const Text(
                'Enter a range to offer candidates. If pay is an exact amount, enter the same in both fields.',
                style: TextStyle(fontSize: 12, color: _helperColor, height: 1.4),
              ),
              const SizedBox(height: 14),

              _sectionLabel('Currency'),
              _currencyDropdown(),
              const SizedBox(height: 14),

              _sectionLabel('From'),
              TextFormField(
                controller: _minPayController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(hint: 'Enter minimum pay'),
              ),
              const SizedBox(height: 12),

              _sectionLabel('To'),
              TextFormField(
                controller: _maxPayController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(hint: 'Enter maximum pay'),
              ),
              const SizedBox(height: 20),

              // Pay Shown on Ad
              _sectionLabel('Pay shown on ad'),
              Row(
                children: ['Yes', 'No'].map((opt) {
                  final active = _showPayOnAd == opt;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPayOnAd = opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: opt == 'Yes' ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: active ? _primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? _primaryBlue : _borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active ? Colors.white : const Color(0xFF444444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Save / Update Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Job' : 'Save',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}