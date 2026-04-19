import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // ── Step control ──────────────────────────────────────────────────────────
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

  // ── Google Places autocomplete ────────────────────────────────────────────
  List<Map<String, String>> _placeSuggestions = [];
  Timer? _debounce;
  bool _showPlaceSuggestions = false;
  bool _isLoadingPlaces = false;
  final FocusNode _locationFocus = FocusNode();

  // ── Step 2 ────────────────────────────────────────────────────────────────
  late TextEditingController _descriptionController;
  late TextEditingController _requirementsController;
  late TextEditingController _benefitsController;
  late TextEditingController _vacanciesController;

  // ✅ FIX: multi-select for experience and education
  final Set<String> _selectedExperiences = {'Fresh Graduate'};
  final Set<String> _selectedEducations  = {'Diploma'};

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

    // Listen for location changes to trigger autocomplete
    _locationController.addListener(_onLocationChanged);

    // Hide suggestions when location field loses focus
    _locationFocus.addListener(() {
      if (!_locationFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showPlaceSuggestions = false);
        });
      }
    });

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
    _debounce?.cancel();
    _locationFocus.dispose();
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

  // ── Google Places Autocomplete ────────────────────────────────────────────

  void _onLocationChanged() {
    final query = _locationController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _showPlaceSuggestions = false;
      });
      return;
    }

    // Debounce 400ms so we don't call on every keystroke
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 2) _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isLoadingPlaces = true);

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        // Fallback: show Malaysian city suggestions manually
        _showFallbackSuggestions(query);
        return;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&types=(cities)'
            '&components=country:my'  // restrict to Malaysia; remove to allow worldwide
            '&key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List? ?? [];
        if (mounted) {
          setState(() {
            _placeSuggestions = predictions.map<Map<String, String>>((p) => {
              'description': p['description']?.toString() ?? '',
              'placeId':     p['place_id']?.toString()    ?? '',
            }).toList();
            _showPlaceSuggestions = _placeSuggestions.isNotEmpty;
            _isLoadingPlaces = false;
          });
        }
      }
    } catch (_) {
      // On error, show fallback
      _showFallbackSuggestions(query);
    } finally {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  // Fallback suggestions if no API key or network error
  void _showFallbackSuggestions(String query) {
    final allCities = [
      'Kuala Lumpur', 'Petaling Jaya', 'Shah Alam', 'Subang Jaya',
      'Johor Bahru', 'Georgetown, Penang', 'Ipoh', 'Kota Kinabalu',
      'Kuching', 'Malacca City', 'Seremban', 'Alor Setar',
      'Kuantan', 'Kota Bharu', 'Kuala Terengganu', 'Sandakan',
      'Miri', 'Sibu', 'Bintulu', 'Klang', 'Putrajaya', 'Cyberjaya',
      'Puchong', 'Cheras', 'Ampang', 'Kepong', 'Bangsar',
    ];
    final q = query.toLowerCase();
    final matched = allCities
        .where((c) => c.toLowerCase().contains(q))
        .map((c) => {'description': c, 'placeId': ''})
        .toList();

    if (mounted) {
      setState(() {
        _placeSuggestions = matched;
        _showPlaceSuggestions = matched.isNotEmpty;
        _isLoadingPlaces = false;
      });
    }
  }

  void _selectPlace(String description) {
    _locationController.text = description;
    _locationController.selection = TextSelection.fromPosition(
      TextPosition(offset: description.length),
    );
    setState(() {
      _placeSuggestions = [];
      _showPlaceSuggestions = false;
    });
    _locationFocus.unfocus();
  }

  // ── Append suggestion ─────────────────────────────────────────────────────
  void _appendSuggestion(TextEditingController ctrl, String chip) {
    final current = ctrl.text.trim();
    if (current.isEmpty) {
      ctrl.text = '• $chip\n';
    } else {
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
    if (!_formKey.currentState!.validate()) return;

    // ✅ Extra validation for fields not covered by TextFormField validators
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter a location');
      return;
    }
    if (_selectedExperiences.isEmpty) {
      _showError('Please select at least one experience level');
      return;
    }
    if (_selectedEducations.isEmpty) {
      _showError('Please select at least one education level');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String companyName = 'Your Company';
      String companyId   = user?.uid ?? 'unknown';

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>? ?? {};
            final cn = data['companyName']?.toString().trim() ?? '';
            final n  = data['name']?.toString().trim() ?? '';
            if (cn.isNotEmpty) companyName = cn;
            else if (n.isNotEmpty) companyName = n;
            final cid = data['companyId']?.toString().trim() ?? '';
            if (cid.isNotEmpty) companyId = cid;
          }
        } catch (e) {
          debugPrint('Error getting user data: $e');
        }
      }

      final salary = '${_selectedCurrency}${_minPayController.text.trim()} - ${_selectedCurrency}${_maxPayController.text.trim()}';
      final now    = DateTime.now();

      final jobData = {
        'title':             _jobTitleController.text.trim(),
        'company':           companyName,
        'companyId':         companyId,
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
        'experienceLevel':   _selectedExperiences.join(', '),
        'educationLevel':    _selectedEducations.join(', '),
        'publishDate':       _publishDate ?? now,
        'expiryDate':        _expiryDate,
        'applicationMethod': _applicationMethod,
        'applicationUrl':    _applicationUrlController.text.trim(),
        'applicationEmail':  _applicationEmailController.text.trim(),
        'postedTime':        'Just now',
        'applicants':        isEditing ? widget.jobToEdit!.applicants : '0 applied',
        'createdAt':         isEditing ? widget.jobToEdit!.createdAt : now,
        'employerId':        user?.uid ?? '',
      };

      if (isEditing && widget.jobToEdit!.id != null) {
        await FirebaseFirestore.instance
            .collection('jobs').doc(widget.jobToEdit!.id).update(jobData);
      } else {
        await FirebaseFirestore.instance.collection('jobs').add(jobData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditing ? 'Job updated!' : 'Job posted!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Step validation ───────────────────────────────────────────────────────
  bool _validateStep(int step) {
    if (step == 0) {
      if (_jobTitleController.text.trim().isEmpty) {
        _showError('Please enter a job title'); return false;
      }
      if (_locationController.text.trim().isEmpty) {
        _showError('Please enter a location'); return false;
      }
      if (_minPayController.text.trim().isEmpty) {
        _showError('Please enter minimum pay'); return false;
      }
      if (_maxPayController.text.trim().isEmpty) {
        _showError('Please enter maximum pay'); return false;
      }
      final min = double.tryParse(_minPayController.text.trim()) ?? -1;
      final max = double.tryParse(_maxPayController.text.trim()) ?? -1;
      if (min < 0) { _showError('Minimum pay must be a valid number'); return false; }
      if (max < 0) { _showError('Maximum pay must be a valid number'); return false; }
      if (max < min) { _showError('Maximum pay cannot be less than minimum pay'); return false; }
    }
    if (step == 1) {
      if (_descriptionController.text.trim().isEmpty) {
        _showError('Please enter a job description'); return false;
      }
      if (_requirementsController.text.trim().isEmpty) {
        _showError('Please enter job requirements'); return false;
      }
      if (_selectedExperiences.isEmpty) {
        _showError('Please select at least one experience level'); return false;
      }
      if (_selectedEducations.isEmpty) {
        _showError('Please select at least one education level'); return false;
      }
    }
    if (step == 2) {
      if (_applicationMethod == 'Email' && _applicationEmailController.text.trim().isEmpty) {
        _showError('Please enter an application email'); return false;
      }
      if (_applicationMethod == 'Email') {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(_applicationEmailController.text.trim())) {
          _showError('Please enter a valid email address'); return false;
        }
      }
      if (_applicationMethod == 'External URL' && _applicationUrlController.text.trim().isEmpty) {
        _showError('Please enter an application URL'); return false;
      }
      if (_applicationMethod == 'External URL') {
        final url = _applicationUrlController.text.trim();
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          _showError('URL must start with http:// or https://'); return false;
        }
      }
    }
    return true;
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    FocusScope.of(context).unfocus();
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
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

  Widget _label(String text, {bool showInfo = false, bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _labelColor)),
      if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
      if (showInfo) ...[const SizedBox(width: 4), const Icon(Icons.help_outline_rounded, size: 16, color: _inactiveGrey)],
    ]),
  );

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, color: _helperColor)),
  );

  InputDecoration _dec({required String hint, Widget? prefix, String? errorText}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
    prefixIcon: prefix,
    errorText: errorText,
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    filled: true, fillColor: _fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    alignLabelWithHint: true,
  );

  // ✅ FIX: Single-select chips (original behaviour kept for workplace/worktype/pay)
  Widget _chips({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
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

  // ✅ FIX: Multi-select chips with deselect support for experience & education
  Widget _multiChips({
    required List<String> options,
    required Set<String> selected,
    required Function(String) onToggle,
    bool required = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 10, runSpacing: 10, children: options.map((opt) {
        final active = selected.contains(opt);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (active) {
                // ✅ Allow deselect only if more than 1 selected (keep at least 1 if required)
                if (!required || selected.length > 1) {
                  selected.remove(opt);
                }
              } else {
                selected.add(opt);
              }
            });
            onToggle(opt);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? _primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: active ? _primaryBlue : _borderColor, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (active) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(opt, style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : const Color(0xFF444444),
              )),
            ]),
          ),
        );
      }).toList()),
      if (required && selected.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Please select at least one option',
              style: TextStyle(fontSize: 12, color: Colors.red)),
        ),
    ]);
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

  Widget _suggestionRow(List<String> suggestions, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFE07B39)),
          const SizedBox(width: 4),
          const Text('Suggestions — tap to add', style: TextStyle(fontSize: 11, color: Color(0xFFE07B39), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: suggestions.map((s) {
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
        }).toList()),
      ]),
    );
  }

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
  // STEP 1 — CLASSIFY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildClassify() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      // ── Job Title ──────────────────────────────────────────────────────
      _label('Job Title', showInfo: true, required: true),
      TextFormField(
        controller: _jobTitleController,
        decoration: _dec(
          hint: 'Enter a simple job title (e.g. Sales Assistant)',
          prefix: Padding(padding: const EdgeInsets.all(12),
              child: Icon(Icons.work_outline_rounded, size: 20, color: Colors.grey[400])),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Job title is required' : null,
      ),
      const SizedBox(height: 20),

      // ── Location with Google Places ────────────────────────────────────
      _label('Location', showInfo: true, required: true),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(
          controller: _locationController,
          focusNode: _locationFocus,
          decoration: _dec(
            hint: 'Search for a city or area...',
            prefix: Padding(
              padding: const EdgeInsets.all(12),
              child: _isLoadingPlaces
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue))
                  : const Icon(Icons.location_on_outlined, size: 20, color: _inactiveGrey),
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
        ),

        // ✅ Place suggestions dropdown
        if (_showPlaceSuggestions && _placeSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 4),
              )],
            ),
            child: Column(
              children: _placeSuggestions.take(5).map((place) {
                return InkWell(
                  onTap: () => _selectPlace(place['description']!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: _primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        place['description']!,
                        style: const TextStyle(fontSize: 13, color: _labelColor),
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
      _hint('Start typing to search for a location'),
      const SizedBox(height: 16),

      // ── Workplace ──────────────────────────────────────────────────────
      _label('Workplace Option'),
      _dropdown(_selectedWorkplace, ['On-site', 'Remote', 'Hybrid'],
              (v) => setState(() => _selectedWorkplace = v)),
      const SizedBox(height: 16),

      // ── Work type ──────────────────────────────────────────────────────
      _label('Work type', required: true),
      _chips(
        options: _workTypeOptions,
        selected: _selectedWorkType,
        onSelect: (v) => setState(() => _selectedWorkType = v),
      ),
      const SizedBox(height: 20),

      // ── Pay type ───────────────────────────────────────────────────────
      _label('Pay type', required: true),
      _chips(
        options: _payTypeOptions,
        selected: _selectedPayType,
        onSelect: (v) => setState(() => _selectedPayType = v),
      ),
      const SizedBox(height: 20),

      // ── Pay Range ──────────────────────────────────────────────────────
      _label('Pay Range', showInfo: true, required: true),
      const Text('Enter a range. If exact, enter the same value in both fields.',
          style: TextStyle(fontSize: 12, color: _helperColor, height: 1.4)),
      const SizedBox(height: 14),

      _label('Currency'),
      _dropdown(_selectedCurrency, _currencyOptions,
              (v) => setState(() => _selectedCurrency = v)),
      const SizedBox(height: 14),

      _label('From', required: true),
      TextFormField(
        controller: _minPayController,
        keyboardType: TextInputType.number,
        decoration: _dec(hint: 'Enter minimum pay'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Minimum pay is required';
          if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
          if (double.parse(v.trim()) < 0) return 'Pay cannot be negative';
          return null;
        },
      ),
      const SizedBox(height: 12),

      _label('To', required: true),
      TextFormField(
        controller: _maxPayController,
        keyboardType: TextInputType.number,
        decoration: _dec(hint: 'Enter maximum pay'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Maximum pay is required';
          if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
          final max = double.parse(v.trim());
          final min = double.tryParse(_minPayController.text.trim()) ?? 0;
          if (max < 0) return 'Pay cannot be negative';
          if (max < min) return 'Maximum pay cannot be less than minimum pay';
          return null;
        },
      ),
      const SizedBox(height: 20),

      // ── Show pay on ad ─────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — WRITE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWrite() {
    final descSuggestions = _descSuggestions[_selectedWorkType] ?? _descSuggestions['Full-time']!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      // ── Job Description ────────────────────────────────────────────────
      _label('Job Description', showInfo: true, required: true),
      TextFormField(
        controller: _descriptionController,
        maxLines: 6,
        decoration: _dec(hint: 'Describe the role, day-to-day tasks and responsibilities...'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Job description is required' : null,
      ),
      _suggestionRow(descSuggestions, _descriptionController),
      const SizedBox(height: 24),

      // ── Requirements ──────────────────────────────────────────────────
      _label('Requirements & Skills', required: true),
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
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requirements are required' : null,
      ),
      _suggestionRow(_reqSuggestions[_reqCategory]!, _requirementsController),
      const SizedBox(height: 24),

      // ── Benefits ──────────────────────────────────────────────────────
      _label('Benefits'),
      TextFormField(
        controller: _benefitsController,
        maxLines: 4,
        decoration: _dec(hint: 'e.g. EPF & SOCSO, medical coverage, annual leave...'),
      ),
      _suggestionRow(_benefitsSuggestions, _benefitsController),
      const SizedBox(height: 24),

      // ── Vacancies ─────────────────────────────────────────────────────
      _label('Number of Vacancies'),
      Row(children: [
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
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = int.tryParse(v.trim());
            if (n == null || n < 1) return 'Min 1';
            return null;
          },
          onChanged: (_) => setState(() {}),
        )),
        const SizedBox(width: 12),
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

      // ── Experience Level (multi-select, deselectable) ──────────────────
      _label('Experience Level', required: true),
      _hint('Select all that apply — tap again to deselect'),
      _multiChips(
        options: _experienceOptions,
        selected: _selectedExperiences,
        onToggle: (_) {},
        required: true,
      ),
      const SizedBox(height: 20),

      // ── Education Level (multi-select, deselectable) ───────────────────
      _label('Minimum Education', required: true),
      _hint('Select all that apply — tap again to deselect'),
      _multiChips(
        options: _educationOptions,
        selected: _selectedEducations,
        onToggle: (_) {},
        required: true,
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — MANAGE
  // ─────────────────────────────────────────────────────────────────────────

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

      _label('Application Method', required: true),
      _chips(
        options: _appMethodOptions,
        selected: _applicationMethod,
        onSelect: (v) => setState(() => _applicationMethod = v),
      ),
      const SizedBox(height: 16),

      if (_applicationMethod == 'Email') ...[
        _label('Application Email', required: true),
        TextFormField(
          controller: _applicationEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec(
            hint: 'e.g. hr@yourcompany.com',
            prefix: const Padding(padding: EdgeInsets.all(12),
                child: Icon(Icons.email_outlined, size: 20, color: _inactiveGrey)),
          ),
          validator: (v) {
            if (_applicationMethod != 'Email') return null;
            if (v == null || v.trim().isEmpty) return 'Email is required';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(v.trim())) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],

      if (_applicationMethod == 'External URL') ...[
        _label('Application URL', required: true),
        TextFormField(
          controller: _applicationUrlController,
          keyboardType: TextInputType.url,
          decoration: _dec(
            hint: 'https://yourcompany.com/careers/apply',
            prefix: const Padding(padding: EdgeInsets.all(12),
                child: Icon(Icons.link_rounded, size: 20, color: _inactiveGrey)),
          ),
          validator: (v) {
            if (_applicationMethod != 'External URL') return null;
            if (v == null || v.trim().isEmpty) return 'URL is required';
            if (!v.trim().startsWith('http://') && !v.trim().startsWith('https://')) {
              return 'URL must start with http:// or https://';
            }
            return null;
          },
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
          _summaryRow('Job Title',   _jobTitleController.text.isEmpty  ? '—' : _jobTitleController.text),
          _summaryRow('Location',    _locationController.text.isEmpty   ? '—' : _locationController.text),
          _summaryRow('Work Type',   _selectedWorkType),
          _summaryRow('Workplace',   _selectedWorkplace),
          _summaryRow('Pay',         '${_selectedCurrency}${_minPayController.text.isEmpty ? "0" : _minPayController.text} – ${_selectedCurrency}${_maxPayController.text.isEmpty ? "0" : _maxPayController.text} / $_selectedPayType'),
          _summaryRow('Vacancies',   _vacanciesController.text.isEmpty ? '1' : _vacanciesController.text),
          _summaryRow('Experience',  _selectedExperiences.isEmpty ? '—' : _selectedExperiences.join(', ')),
          _summaryRow('Education',   _selectedEducations.isEmpty  ? '—' : _selectedEducations.join(', ')),
          _summaryRow('Apply via',   _applicationMethod),
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