import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditExperiencePage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? experienceData;
  final String? docId;

  const EditExperiencePage({Key? key, required this.user, this.experienceData, this.docId}) : super(key: key);

  @override
  State<EditExperiencePage> createState() => _EditExperiencePageState();
}

class _EditExperiencePageState extends State<EditExperiencePage> {
  late TextEditingController _roleController;
  late TextEditingController _companyController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  // Date Selections
  String? _startMonth;
  String? _startYear;
  String? _endMonth;
  String? _endYear;
  bool _isCurrentlyWorking = false;
  bool _hasLegacyDate = false;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> _years = List.generate(37, (index) => (2026 - index).toString());

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.experienceData?['role'] ?? '');
    _companyController = TextEditingController(text: widget.experienceData?['company'] ?? '');
    _descriptionController = TextEditingController(text: widget.experienceData?['description'] ?? '');

    if (widget.experienceData != null) {
      String duration = widget.experienceData!['duration'] ?? '';
      if (duration == "-") {
        _hasLegacyDate = true;
      } else {
        _startMonth = widget.experienceData!['startMonth'];
        _startYear = widget.experienceData!['startYear'];
        _isCurrentlyWorking = widget.experienceData!['isCurrentlyWorking'] ?? false;

        if (!_isCurrentlyWorking) {
          _endMonth = widget.experienceData!['endMonth'];
          _endYear = widget.experienceData!['endYear'];
        }
      }
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- NEW VALIDATION HELPER ---
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _saveExperience() async {
    if (!_hasLegacyDate) {
      if (_startMonth == null || _startYear == null) {
        _showError("Please select a start date");
        return;
      }

      if (!_isCurrentlyWorking) {
        if (_endMonth == null || _endYear == null) {
          _showError("End data cannot earlier than start data. Please re-select an end date");
          return;
        }

        // --- DATE ORDER VALIDATION ---
        int startMonthIdx = _months.indexOf(_startMonth!) + 1;
        int endMonthIdx = _months.indexOf(_endMonth!) + 1;
        int startYearNum = int.parse(_startYear!);
        int endYearNum = int.parse(_endYear!);

        if (endYearNum < startYearNum) {
          _showError("End year cannot be earlier than start year");
          return;
        } else if (endYearNum == startYearNum && endMonthIdx < startMonthIdx) {
          _showError("End month cannot be earlier than start month");
          return;
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      String durationText;
      if (_hasLegacyDate) {
        durationText = "-";
      } else {
        durationText = "$_startMonth $_startYear - ${_isCurrentlyWorking ? 'Present' : '$_endMonth $_endYear'}";
      }

      final data = {
        'role': _roleController.text.trim(),
        'company': _companyController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': durationText,
        'startMonth': _startMonth,
        'startYear': _startYear,
        'endMonth': _isCurrentlyWorking ? null : _endMonth,
        'endYear': _isCurrentlyWorking ? null : _endYear,
        'isCurrentlyWorking': _isCurrentlyWorking,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('users').doc(widget.user.uid)
            .collection('experience_history').doc(widget.docId).update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('users').doc(widget.user.uid)
            .collection('experience_history').add(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.docId == null ? 'Add experience' : 'Edit experience',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Job Title / Role"),
            _buildCustomField(_roleController, "e.g. Software Engineer Intern"),

            const SizedBox(height: 20),
            _buildLabel("Company Name"),
            _buildCustomField(_companyController, "e.g. Zus Coffee"),

            const SizedBox(height: 20),
            _buildLabel("Dates"),
            if (_hasLegacyDate)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text("Date not found in resume (-)", style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _hasLegacyDate = false),
                      child: const Text("Set Date Manually"),
                    )
                  ],
                ),
              )
            else ...[
              _buildLabel("Start Date"),
              Row(
                children: [
                  Expanded(child: _buildDropdown(_months, _startMonth, "Month", (val) => setState(() => _startMonth = val))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown(_years, _startYear, "Year", (val) => setState(() => _startYear = val))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _isCurrentlyWorking,
                    activeColor: brandBlue,
                    onChanged: (val) => setState(() => _isCurrentlyWorking = val ?? false),
                  ),
                  const Text("I am currently working in this role", style: TextStyle(fontSize: 13)),
                ],
              ),
              if (!_isCurrentlyWorking) ...[
                const SizedBox(height: 10),
                _buildLabel("End Date"),
                Row(
                  children: [
                    Expanded(child: _buildDropdown(_months, _endMonth, "Month", (val) => setState(() => _endMonth = val))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown(_years, _endYear, "Year", (val) => setState(() => _endYear = val))),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 20),
            _buildLabel("Job Description"),
            _buildCustomField(_descriptionController, "Describe your responsibilities...", maxLines: 6),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveExperience,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _buildDropdown(List<String> items, String? value, String hint, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCustomField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF2563EB)), borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}