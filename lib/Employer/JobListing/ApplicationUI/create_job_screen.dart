import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';

class CreateJobPage extends StatefulWidget {
  final Job? jobToEdit;
  const CreateJobPage({super.key, this.jobToEdit});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Step control (0=Classify, 1=Write, 2=Manage) ──────────────────────────
  int _currentStep = 0;
  final List<String> _stepLabels = ['Classify', 'Write', 'Manage'];

  bool get isEditing => widget.jobToEdit != null;

  // ── Step 1 ────────────────────────────────────────────────────────────────
  late TextEditingController _jobTitleController;
  late TextEditingController _locationController;
  late TextEditingController _minPayController;
  late TextEditingController _maxPayController;
  String _selectedWorkplace = 'On-site';
  String _selectedWorkType  = 'Full-time';
  String _selectedPayType   = 'Monthly';
  String _selectedCurrency  = 'MYR';
  String _showPayOnAd       = 'Yes';

  // ── Step 2 ────────────────────────────────────────────────────────────────
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _benefitsController;
  late TextEditingController _vacanciesController;
  String _selectedExperience = 'Fresh Graduate';
  String _selectedEducation  = 'Diploma';

  // ── Step 3 ────────────────────────────────────────────────────────────────
  DateTime? _publishDate;
  DateTime? _expiryDate;
  String _applicationMethod = 'In-app';
  late TextEditingController _applicationUrlController;
  late TextEditingController _applicationEmailController;

  // ── Options ───────────────────────────────────────────────────────────────
  final List<String> _workTypeOptions   = ['Full-time', 'Part-time', 'Contract', 'Casual'];
  final List<String> _payTypeOptions    = ['Hourly', 'Monthly', 'Annually'];
  final List<String> _currencyOptions   = ['MYR', 'USD', 'SGD', 'EUR'];
  final List<String> _experienceOptions = ['Fresh Graduate', '1–3 years', '3–5 years', '5+ years', 'Senior'];
  final List<String> _educationOptions  = ['SPM', 'Diploma', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD'];
  final List<String> _appMethodOptions  = ['In-app', 'Email', 'External URL'];

  // ── Suggestion chips data ─────────────────────────────────────────────────
  // Description suggestions per work type
  final Map<String, List<String>> _descSuggestions = {
    'Full-time': [
      'Responsible for day-to-day operations',
      'Collaborate with cross-functional teams',
      'Prepare and submit weekly reports',
      'Handle customer enquiries and complaints',
      'Achieve monthly sales targets',
      'Maintain accurate records and documentation',
      'Support management in planning and execution',
      'Conduct regular performance reviews',
    ],
    'Part-time': [
      'Assist with daily tasks and operations',
      'Support the team during peak hours',
      'Handle customer service duties',
      'Perform data entry and filing',
      'Flexible hours including weekends',
    ],
    'Contract': [
      'Deliver project milestones on schedule',
      'Provide technical expertise for project scope',
      'Coordinate with stakeholders and vendors',
      'Document project progress and outcomes',
      'Adhere to contract terms and KPIs',
    ],
    'Casual': [
      'Available on an as-needed basis',
      'Assist during events or busy periods',
      'Flexible scheduling required',
      'Support frontline operations',
    ],
  };

  // Requirements suggestions
  final Map<String, List<String>> _reqSuggestions = {
    'General': [
      'Minimum 1 year relevant experience',
      'Strong communication skills',
      'Proficient in Microsoft Office',
      'Able to work independently',
      'Good time management skills',
      'Attention to detail',
      'Team player with positive attitude',
      'Willing to travel when required',
      'Basic computer literacy',
      'Fluent in Bahasa Malaysia and English',
    ],
    'IT / Tech': [
      'Proficient in Flutter / Dart',
      'Experience with Firebase',
      'Knowledge of REST APIs',
      'Familiar with Git version control',
      'Experience with SQL / NoSQL databases',
      'Understanding of OOP principles',
      'Knowledge of UI/UX best practices',
    ],
    'Design': [
      'Proficient in Figma / Adobe XD',
      'Strong portfolio required',
      'Experience in branding and visual design',
      'Knowledge of design systems',
      'Able to produce print-ready artwork',
    ],
    'Sales': [
      'Proven sales track record',
      'Strong negotiation skills',
      'Experience with CRM tools',
      'Self-motivated and target-driven',
      'Existing client network preferred',
    ],
  };

  // Benefits suggestions
  final List<String> _benefitsSuggestions = [
    'EPF & SOCSO contributions',
    'Annual leave (14 days)',
    'Medical & hospitalisation coverage',
    'Performance bonus',
    'Staff discount',
    'Flexible working hours',
    'Remote work option',
    'Training & development programs',
    'Team building activities',
    'Career advancement opportunities',
    'Dental & optical coverage',
    'Free parking',
    'Meal allowance',
    'Transport allowance',
    'Phone & data allowance',
  ];

  // Which category is active for requirements
  String _reqCategory = 'General';
  final List<String> _reqCategories = ['General', 'IT / Tech', 'Design', 'Sales'];

  // Colors
  static const Color _primaryBlue  = Color(0xFF3B4FD8);
  static const Color _inactiveGrey = Color(0xFFBDBDBD);
  static const Color _borderColor  = Color(0xFFDDDDDD);
  static const Color _fillColor    = Color(0xFFFAFAFA);
  static const Color _labelColor   = Color(0xFF1A1A2E);
  static const Color _hintColor    = Color(0xFFAAAAAA);
  static const Color _helperColor  = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _jobTitleController         = TextEditingController();
    _locationController         = TextEditingController();
    _minPayController           = TextEditingController();
    _maxPayController           = TextEditingController();
    _descriptionController      = TextEditingController();
    _requirementsController     = TextEditingController();
    _benefitsController         = TextEditingController();
    _vacanciesController        = TextEditingController(text: '1');
    _applicationUrlController   = TextEditingController();
    _applicationEmailController = TextEditingController();

    if (isEditing) {
      final job = widget.jobToEdit!;
      _jobTitleController.text = job.title;
      _locationController.text = job.location;
      _selectedWorkplace       = job.workplace;
      _selectedWorkType        = job.workType;
      final clean = job.salary.replaceAll(RegExp(r'[^0-9\s-]'), '');
      final parts = clean.split('-');
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
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _vacanciesController.dispose();
    _applicationUrlController.dispose();
    _applicationEmailController.dispose();
    super.dispose();
  }

  // ── Append suggestion to a controller ────────────────────────────────────
  void _appendSuggestion(TextEditingController ctrl, String chip) {
    final current = ctrl.text.trim();
    if (current.isEmpty) {
      ctrl.text = '• $chip\n';
    } else {
      // avoid duplicates
      if (current.contains(chip)) return;
      ctrl.text = '$current\n• $chip\n';
    }
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
    setState(() {});
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _saveJob() async {
    setState(() => _isSaving = true);
    try {
      final salary = 'RM${_minPayController.text.trim()} - RM${_maxPayController.text.trim()}';
      final now    = DateTime.now();
      final jobData = {
        'title':             _jobTitleController.text.trim(),
        'company':           isEditing ? widget.jobToEdit!.company : 'Your Company',
        'location':          _locationController.text.trim(),
        'workType':          _selectedWorkType,
        'workplace':         _selectedWorkplace,
        'salary':            salary,
        'payType':           _selectedPayType,
        'showPayOnAd':       _showPayOnAd,
        'description':       _descriptionController.text.trim(),
        'requirements':      _requirementsController.text.trim(),
        'benefits':          _benefitsController.text.trim(),
        'vacancies':         int.tryParse(_vacanciesController.text.trim()) ?? 1,
        'experienceLevel':   _selectedExperience,
        'educationLevel':    _selectedEducation,
        'publishDate':       _publishDate ?? now,
        'expiryDate':        _expiryDate,
        'applicationMethod': _applicationMethod,
        'applicationUrl':    _applicationUrlController.text.trim(),
        'applicationEmail':  _applicationEmailController.text.trim(),
        'postedTime':        'Just now',
        'applicants':        isEditing ? widget.jobToEdit!.applicants : '0 applied',
        'createdAt':         isEditing ? widget.jobToEdit!.createdAt : now,
      };

      if (isEditing && widget.jobToEdit!.id != null) {
        await FirebaseFirestore.instance.collection('jobs').doc(widget.jobToEdit!.id).update(jobData);
      } else {
        await FirebaseFirestore.instance.collection('jobs').add(jobData);
      }

      if (mounted) setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditing ? 'Job updated!' : 'Job posted!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Step validation ───────────────────────────────────────────────────────
  bool _validateStep(int step) {
    if (step == 0) {
      if (_jobTitleController.text.trim().isEmpty) { _showError('Please enter a job title'); return false; }
      if (_locationController.text.trim().isEmpty) { _showError('Please enter a location');  return false; }
    }
    if (step == 1) {
      if (_descriptionController.text.trim().isEmpty) { _showError('Please enter a job description'); return false; }
    }
    return true;
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

  // ✅ FIX 1: Dismiss keyboard AND unfocus before switching step
  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    FocusScope.of(context).unfocus(); // ← dismisses keyboard, clears focus
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    FocusScope.of(context).unfocus(); // ← also dismiss on back
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final isActive = i == _currentStep;
          final isDone   = i < _currentStep;
          final isLast   = i == _stepLabels.length - 1;
          return Expanded(
            child: Row(children: [
              Expanded(child: Column(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive || isDone ? _primaryBlue : Colors.white,
                    border: Border.all(
                      color: isActive || isDone ? _primaryBlue : _inactiveGrey,
                      width: isActive ? 5 : 1.5,
                    ),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                ),
                const SizedBox(height: 6),
                Text(_stepLabels[i], style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _primaryBlue : _inactiveGrey,
                )),
              ])),
              if (!isLast)
                Expanded(child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: isDone ? _primaryBlue : _inactiveGrey,
                )),
            ]),
          );
        }),
      ),
    );
  }

  Widget _label(String text, {bool showInfo = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _labelColor)),
      if (showInfo) ...[const SizedBox(width: 4), const Icon(Icons.help_outline_rounded, size: 16, color: _inactiveGrey)],
    ]),
  );

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, color: _helperColor)),
  );

  InputDecoration _dec({required String hint, Widget? prefix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
    prefixIcon: prefix,
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    filled: true, fillColor: _fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    alignLabelWithHint: true,
  );

  Widget _chips({required List<String> options, required String selected, required ValueChanged<String> onSelect}) {
    return Wrap(spacing: 10, runSpacing: 10, children: options.map((opt) {
      final active = opt == selected;
      return GestureDetector(
        onTap: () => onSelect(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: active ? _primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active ? _primaryBlue : _borderColor, width: 1.5),
          ),
          child: Text(opt, style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : const Color(0xFF444444),
          )),
        ),
      );
    }).toList());
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String> onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: _fillColor, border: Border.all(color: _borderColor), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
          style: const TextStyle(fontSize: 14, color: _labelColor),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: _fillColor, border: Border.all(color: _borderColor), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: _inactiveGrey),
          const SizedBox(width: 10),
          Text(
            date != null ? '${date.day}/${date.month}/${date.year}' : label,
            style: TextStyle(fontSize: 14, color: date != null ? _labelColor : _hintColor),
          ),
          if (date != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                if (label.contains('Publish')) _publishDate = null;
                else _expiryDate = null;
              }),
              child: const Icon(Icons.clear, size: 16, color: _inactiveGrey),
            ),
          ],
        ]),
      ),
    );
  }

  // ── ✅ FIX 2: Suggestion chip row — tapping appends to the field ──────────
  Widget _suggestionRow(List<String> suggestions, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFE07B39)),
            const SizedBox(width: 4),
            const Text('Suggestions — tap to add', style: TextStyle(fontSize: 11, color: Color(0xFFE07B39), fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: suggestions.map((s) {
              final alreadyAdded = ctrl.text.contains(s);
              return GestureDetector(
                onTap: alreadyAdded ? null : () => _appendSuggestion(ctrl, s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: alreadyAdded ? const Color(0xFFE8FBF0) : const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: alreadyAdded ? const Color(0xFF2CB06A) : const Color(0xFF3B4FD8),
                      width: 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      alreadyAdded ? Icons.check_rounded : Icons.add_rounded,
                      size: 13,
                      color: alreadyAdded ? const Color(0xFF2CB06A) : _primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(s, style: TextStyle(
                      fontSize: 12,
                      color: alreadyAdded ? const Color(0xFF2CB06A) : _primaryBlue,
                      fontWeight: FontWeight.w500,
                    )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Nav buttons ───────────────────────────────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 40),
      child: Row(children: [
        if (_currentStep > 0) ...[
          Expanded(child: OutlinedButton(
            onPressed: _prevStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back', style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w700, fontSize: 15)),
          )),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLast ? _saveJob : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isLast ? (isEditing ? 'Update Job' : 'Post Job') : 'Next',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP SCREENS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildClassify() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _label('Job Title', showInfo: true),
      TextFormField(
        controller: _jobTitleController,
        decoration: _dec(
          hint: 'Enter a simple job title (e.g. Sales Assistant)',
          prefix: Padding(padding: const EdgeInsets.all(12),
              child: Icon(Icons.work_outline_rounded, size: 20, color: Colors.grey[400])),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add job title' : null,
      ),
      const SizedBox(height: 20),

      _label('Location', showInfo: true),
      TextFormField(
        controller: _locationController,
        decoration: _dec(
          hint: 'Enter a suburb, city or region (e.g. Kuala Lumpur)',
          prefix: const Padding(padding: EdgeInsets.all(12),
              child: Icon(Icons.location_on_outlined, size: 20, color: _inactiveGrey)),
        ),
      ),
      _hint('Suggestions will appear below the field as you type'),
      const SizedBox(height: 16),

      _label('Workplace Option'),
      _dropdown(_selectedWorkplace, ['On-site', 'Remote', 'Hybrid'], (v) => setState(() => _selectedWorkplace = v)),
      _hint('Suggestions will appear below the field as you type'),
      const SizedBox(height: 16),

      _label('Work type'),
      _chips(options: _workTypeOptions, selected: _selectedWorkType, onSelect: (v) => setState(() => _selectedWorkType = v)),
      const SizedBox(height: 20),

      _label('Pay type'),
      _chips(options: _payTypeOptions, selected: _selectedPayType, onSelect: (v) => setState(() => _selectedPayType = v)),
      const SizedBox(height: 20),

      _label('Pay Range', showInfo: true),
      const Text('Enter a range to offer candidates. If pay is an exact amount, enter the same in both fields.',
          style: TextStyle(fontSize: 12, color: _helperColor, height: 1.4)),
      const SizedBox(height: 14),

      _label('Currency'),
      _dropdown(_selectedCurrency, _currencyOptions, (v) => setState(() => _selectedCurrency = v)),
      const SizedBox(height: 14),

      _label('From'),
      TextFormField(controller: _minPayController, keyboardType: TextInputType.number, decoration: _dec(hint: 'Enter minimum pay')),
      const SizedBox(height: 12),

      _label('To'),
      TextFormField(controller: _maxPayController, keyboardType: TextInputType.number, decoration: _dec(hint: 'Enter maximum pay')),
      const SizedBox(height: 20),

      _label('Pay shown on ad'),
      Row(children: ['Yes', 'No'].map((opt) {
        final active = _showPayOnAd == opt;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _showPayOnAd = opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: opt == 'Yes' ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: active ? _primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? _primaryBlue : _borderColor, width: 1.5),
            ),
            child: Center(child: Text(opt, style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : const Color(0xFF444444),
            ))),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWrite() {
    final descSuggestions = _descSuggestions[_selectedWorkType] ?? _descSuggestions['Full-time']!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      // ── Job Description ────────────────────────────────────────────────
      _label('Job Description', showInfo: true),
      TextFormField(
        controller: _descriptionController,
        maxLines: 6,
        decoration: _dec(hint: 'Describe the role, day-to-day tasks and responsibilities...'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a job description' : null,
      ),
      // Suggestions for description
      _suggestionRow(descSuggestions, _descriptionController),
      const SizedBox(height: 24),

      // ── Requirements ──────────────────────────────────────────────────
      _label('Requirements & Skills'),
      // Category tabs for requirements
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _reqCategories.map((cat) {
          final active = _reqCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _reqCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _primaryBlue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _primaryBlue : _borderColor),
              ),
              child: Text(cat, style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? _primaryBlue : _helperColor,
              )),
            ),
          );
        }).toList()),
      ),
      TextFormField(
        controller: _requirementsController,
        maxLines: 5,
        decoration: _dec(hint: 'e.g. Minimum 2 years experience, proficient in Microsoft Office...'),
      ),
      // Suggestions for requirements
      _suggestionRow(_reqSuggestions[_reqCategory]!, _requirementsController),
      const SizedBox(height: 24),

      // ── Benefits ──────────────────────────────────────────────────────
      _label('Benefits'),
      TextFormField(
        controller: _benefitsController,
        maxLines: 4,
        decoration: _dec(hint: 'e.g. EPF & SOCSO, medical coverage, annual leave...'),
      ),
      // Suggestions for benefits
      _suggestionRow(_benefitsSuggestions, _benefitsController),
      const SizedBox(height: 24),

      // ── Vacancies ─────────────────────────────────────────────────────
      _label('Number of Vacancies'),
      Row(children: [
        // minus
        GestureDetector(
          onTap: () {
            final v = int.tryParse(_vacanciesController.text) ?? 1;
            if (v > 1) { _vacanciesController.text = '${v - 1}'; setState(() {}); }
          },
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _fillColor, border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.remove, size: 18, color: _labelColor),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: TextFormField(
          controller: _vacanciesController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: _dec(hint: '1'),
          onChanged: (_) => setState(() {}),
        )),
        const SizedBox(width: 12),
        // plus
        GestureDetector(
          onTap: () {
            final v = int.tryParse(_vacanciesController.text) ?? 1;
            _vacanciesController.text = '${v + 1}'; setState(() {});
          },
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.white),
          ),
        ),
      ]),
      const SizedBox(height: 20),

      // ── Experience Level ──────────────────────────────────────────────
      _label('Experience Level'),
      _chips(options: _experienceOptions, selected: _selectedExperience, onSelect: (v) => setState(() => _selectedExperience = v)),
      const SizedBox(height: 20),

      // ── Education Level ───────────────────────────────────────────────
      _label('Minimum Education'),
      _chips(options: _educationOptions, selected: _selectedEducation, onSelect: (v) => setState(() => _selectedEducation = v)),
    ]);
  }

  Widget _buildManage() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      _label('Publish Date'),
      _dateField('Publish now (immediately)', _publishDate, () async {
        final p = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (p != null) setState(() => _publishDate = p);
      }),
      _hint('Leave empty to publish immediately'),
      const SizedBox(height: 16),

      _label('Ad Expiry Date'),
      _dateField('Select expiry date', _expiryDate, () async {
        final p = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 180)),
        );
        if (p != null) setState(() => _expiryDate = p);
      }),
      _hint('Ad will auto-close after this date'),
      const SizedBox(height: 20),

      _label('Application Method'),
      _chips(options: _appMethodOptions, selected: _applicationMethod, onSelect: (v) => setState(() => _applicationMethod = v)),
      const SizedBox(height: 16),

      if (_applicationMethod == 'Email') ...[
        _label('Application Email'),
        TextFormField(
          controller: _applicationEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec(
            hint: 'e.g. hr@yourcompany.com',
            prefix: const Padding(padding: EdgeInsets.all(12),
                child: Icon(Icons.email_outlined, size: 20, color: _inactiveGrey)),
          ),
        ),
        const SizedBox(height: 16),
      ],

      if (_applicationMethod == 'External URL') ...[
        _label('Application URL'),
        TextFormField(
          controller: _applicationUrlController,
          keyboardType: TextInputType.url,
          decoration: _dec(
            hint: 'https://yourcompany.com/careers/apply',
            prefix: const Padding(padding: EdgeInsets.all(12),
                child: Icon(Icons.link_rounded, size: 20, color: _inactiveGrey)),
          ),
        ),
        const SizedBox(height: 16),
      ],

      if (_applicationMethod == 'In-app') ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: const [
            Icon(Icons.info_outline_rounded, size: 18, color: _primaryBlue),
            SizedBox(width: 10),
            Expanded(child: Text('Candidates will apply directly through the JobBuddy app.',
                style: TextStyle(fontSize: 13, color: _primaryBlue))),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // Summary card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FF),
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ad Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _labelColor)),
          const SizedBox(height: 12),
          _summaryRow('Job Title',  _jobTitleController.text.isEmpty  ? '—' : _jobTitleController.text),
          _summaryRow('Location',   _locationController.text.isEmpty   ? '—' : _locationController.text),
          _summaryRow('Work Type',  _selectedWorkType),
          _summaryRow('Workplace',  _selectedWorkplace),
          _summaryRow('Pay',        'RM${_minPayController.text.isEmpty ? "0" : _minPayController.text} – RM${_maxPayController.text.isEmpty ? "0" : _maxPayController.text} / $_selectedPayType'),
          _summaryRow('Vacancies',  _vacanciesController.text.isEmpty ? '1' : _vacanciesController.text),
          _summaryRow('Experience', _selectedExperience),
          _summaryRow('Education',  _selectedEducation),
          _summaryRow('Apply via',  _applicationMethod),
        ]),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: _helperColor))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _labelColor))),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
          onPressed: () {
            if (_currentStep > 0) _prevStep();
            else Navigator.pop(context);
          },
        ),
        title: Text(
          isEditing ? 'Edit job ad' : 'Create a job ad',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
      body: _isSaving
          ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Posting job...', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditing) ...[
                _buildStepper(),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ],
              if (_currentStep == 0) _buildClassify(),
              if (_currentStep == 1) _buildWrite(),
              if (_currentStep == 2) _buildManage(),
              _buildNavButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
