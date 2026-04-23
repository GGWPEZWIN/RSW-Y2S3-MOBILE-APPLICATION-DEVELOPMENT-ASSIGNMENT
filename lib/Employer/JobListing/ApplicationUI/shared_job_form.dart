// lib/Employer/CreateJob/shared_job_form.dart
//
// ALL the shared form fields and logic used by BOTH create and edit pages

import 'dart:async';
import 'package:flutter/material.dart';

mixin SharedJobForm<T extends StatefulWidget> on State<T> {

  // ─────────────────────────────────────────────────────────────────────────
  // COLORS
  // ─────────────────────────────────────────────────────────────────────────

  static const Color kBlue         = Color(0xFF3B4FD8);
  static const Color kInactiveGrey = Color(0xFFBDBDBD);
  static const Color kBorder       = Color(0xFFDDDDDD);
  static const Color kFill         = Color(0xFFFAFAFA);
  static const Color kLabel        = Color(0xFF1A1A2E);
  static const Color kHint         = Color(0xFFAAAAAA);
  static const Color kHelper       = Color(0xFF888888);

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT BOX CONTROLLERS
  // ─────────────────────────────────────────────────────────────────────────

  late TextEditingController jobTitleCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController minPayCtrl;
  late TextEditingController maxPayCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController requirementsCtrl;
  late TextEditingController benefitsCtrl;
  late TextEditingController vacanciesCtrl;
  late TextEditingController applicationUrlCtrl;
  late TextEditingController applicationEmailCtrl;
  late TextEditingController streetCtrl;       // Street address field
  late FocusNode locationFocus;

  // ─────────────────────────────────────────────────────────────────────────
  // STEPPER
  // ─────────────────────────────────────────────────────────────────────────

  final List<String> stepLabels = ['Classify', 'Write', 'Manage'];
  int  currentStep       = 0;
  bool isSaving          = false;
  bool isSavingAttempted = false;

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 - CLASSIFY
  // ─────────────────────────────────────────────────────────────────────────

  String selectedIndustry  = '';
  String selectedWorkplace = 'On-site';
  String selectedWorkType  = 'Full-time';
  String selectedPayType   = 'Monthly';
  String selectedCurrency  = 'MYR';
  String showPayOnAd       = 'Yes';

  // ─────────────────────────────────────────────────────────────────────────
  // MALAYSIA LOCATION DROPDOWNS
  // ─────────────────────────────────────────────────────────────────────────

  String? selectedState;
  String? selectedCity;
  String? selectedPostcode;
  String? _suggestedPostcode;  // For showing suggestion popup

  // Malaysia states and their cities with postcodes
  static const Map<String, Map<String, List<String>>> kMalaysiaPostcodeMap = {
    'Kuala Lumpur': {
      'Chow Kit': ['50300', '50350'],
      'Bukit Bintang': ['55100', '55150'],
      'Mont Kiara': ['50480'],
      'Bangsar': ['59000', '59100'],
      'Cheras': ['56000', '56100'],
      'Kepong': ['52100', '52200'],
      'Setapak': ['53000', '53100'],
      'Wangsa Maju': ['53300'],
      'Titiwangsa': ['53200'],
      'Segambut': ['51200', '51250'],
    },
    'Selangor': {
      'Petaling Jaya': ['47300', '47301', '47310', '47320', '47330', '47340', '47350', '47370', '47380'],
      'Shah Alam': ['40000', '40100', '40150', '40200', '40300', '40400', '40450', '40500', '40503', '40505'],
      'Subang Jaya': ['47500', '47501', '47502', '47507', '47509', '47600', '47610', '47620', '47630', '47650'],
      'Klang': ['41000', '41100', '41200', '41300', '41400', '41401', '41402', '41403', '41405', '41409'],
      'Ampang': ['68000', '68001', '68010', '68020', '68030', '68040', '68050', '68060', '68070', '68080'],
      'Puchong': ['47100', '47110', '47120', '47130', '47140', '47150', '47160', '47170', '47180', '47190'],
      'Kajang': ['43000', '43001', '43002', '43003', '43004', '43005', '43006', '43007', '43008', '43009'],
      'Sepang': ['43900', '43909'],
      'Rawang': ['48000', '48050', '48060', '48070', '48080'],
      'Batu Caves': ['68100', '68120', '68130', '68131', '68140', '68150'],
    },
    'Johor': {
      'Johor Bahru': ['80000', '80100', '80200', '80300', '80400', '80500', '80600', '80700', '80800', '80900'],
      'Skudai': ['81300', '81310', '81320', '81330', '81340'],
      'Batu Pahat': ['83000', '83010', '83020', '83030', '83040', '83100', '83200', '83300', '83400'],
      'Muar': ['84000', '84010', '84020', '84030', '84100', '84200', '84300', '84400'],
      'Kluang': ['86000', '86010', '86020', '86030', '86100', '86200', '86300'],
      'Segamat': ['85000', '85100', '85200', '85300'],
      'Kulai': ['81000', '81010', '81020', '81030'],
    },
    'Penang': {
      'George Town': ['10000', '10050', '10100', '10150', '10200', '10300', '10400', '10500', '10600', '10700', '10800', '10900'],
      'Butterworth': ['12000', '12100', '12200', '12300', '12400', '13000', '13100', '13400', '13800'],
      'Bukit Mertajam': ['14000', '14100', '14200'],
      'Bayan Lepas': ['11900', '11909', '11910', '11920', '11950', '11960'],
      'Nibong Tebal': ['14300'],
      'Balik Pulau': ['11000'],
      'Seberang Jaya': ['13700'],
    },
    'Perak': {
      'Ipoh': ['30000', '30100', '30200', '30300', '30400', '30450', '30500', '30600', '30700', '30720', '30740', '30750', '30760', '30800', '30900'],
      'Taiping': ['34000', '34010', '34020', '34030', '34040', '34050', '34060', '34070', '34080', '34090', '34100', '34200', '34300', '34400', '34500', '34600', '34700', '34800'],
      'Teluk Intan': ['36000', '36100', '36200', '36300', '36400', '36500', '36600'],
      'Sitiawan': ['32000'],
      'Lumut': ['32100'],
    },
    'Sabah': {
      'Kota Kinabalu': ['88000', '88100', '88200', '88300', '88400', '88450', '88500'],
      'Sandakan': ['90000', '90100', '90200', '90300', '90400', '90500', '90600', '90700', '90800', '90900'],
      'Tawau': ['91000', '91100', '91200', '91300', '91400', '91500'],
    },
    'Sarawak': {
      'Kuching': ['93000', '93100', '93200', '93300', '93350', '93400', '93450', '93500'],
      'Miri': ['98000', '98100'],
      'Sibu': ['96000', '96100', '96200'],
    },
  };

  List<String> get _citiesForSelectedState {
    if (selectedState == null) return [];
    return kMalaysiaPostcodeMap[selectedState!]?.keys.toList() ?? [];
  }

  // Get postcode suggestions for selected city
  List<String> _getPostcodeSuggestions() {
    if (selectedState == null || selectedCity == null) return [];
    return kMalaysiaPostcodeMap[selectedState!]?[selectedCity!] ?? [];
  }

  // Auto-select first postcode when city is chosen
  void _autoFillPostcodeFromCity() {
    final suggestions = _getPostcodeSuggestions();
    if (suggestions.isNotEmpty) {
      setState(() {
        selectedPostcode = suggestions.first;
        _suggestedPostcode = null;
      });
      _updateLocationFromDropdowns();
    }
  }

  // Build the full location string from dropdowns + street
  void _updateLocationFromDropdowns() {
    final parts = <String>[];
    if (streetCtrl.text.trim().isNotEmpty) parts.add(streetCtrl.text.trim());
    if (selectedPostcode != null && selectedPostcode!.isNotEmpty) parts.add(selectedPostcode!);
    if (selectedCity != null) parts.add(selectedCity!);
    if (selectedState != null) parts.add(selectedState!);
    locationCtrl.text = parts.join(', ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARSE LOCATION STRING (for editing existing jobs)
  // ─────────────────────────────────────────────────────────────────────────

  void parseLocationString(String location) {
    if (location.isEmpty) return;

    final parts = location.split(',');

    if (parts.isNotEmpty) {
      streetCtrl.text = parts[0].trim();
    }

    for (var part in parts) {
      final trimmed = part.trim();
      final postcodeMatch = RegExp(r'\b\d{5}\b').firstMatch(trimmed);
      if (postcodeMatch != null) {
        selectedPostcode = postcodeMatch.group(0);
      } else if (trimmed.isNotEmpty && trimmed != streetCtrl.text) {
        for (var stateKey in kMalaysiaPostcodeMap.keys) {
          if (trimmed.contains(stateKey)) {
            selectedState = stateKey;
            break;
          }
        }
        if (selectedState != null && selectedCity == null) {
          final cities = kMalaysiaPostcodeMap[selectedState!]?.keys.toList() ?? [];
          for (var cityName in cities) {
            if (trimmed.contains(cityName)) {
              selectedCity = cityName;
              break;
            }
          }
        }
      }
    }

    // Update the location controller after parsing
    _updateLocationFromDropdowns();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 - WRITE
  // ─────────────────────────────────────────────────────────────────────────

  final Set<String> selectedExperiences = {'Fresh Graduate'};
  final Set<String> selectedEducations  = {'Diploma'};
  String reqCategory = 'General';

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 - MANAGE
  // ─────────────────────────────────────────────────────────────────────────

  DateTime? publishDate;
  DateTime? expiryDate;
  String applicationMethod = 'In-app';

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION SEARCH (kept for fallback/edit prefill)
  // ─────────────────────────────────────────────────────────────────────────

  List<Map<String, String>> placeSuggestions = [];
  Timer? locationDebounce;
  bool showPlaceSuggestions = false;
  bool isLoadingPlaces      = false;

  // ─────────────────────────────────────────────────────────────────────────
  // DROPDOWN OPTIONS
  // ─────────────────────────────────────────────────────────────────────────

  final List<String> workTypeOptions   = ['Full-time', 'Part-time', 'Contract', 'Casual'];
  final List<String> payTypeOptions    = ['Hourly', 'Monthly', 'Annually'];
  final List<String> currencyOptions   = ['MYR', 'USD', 'SGD', 'EUR'];
  final List<String> experienceOptions = ['Fresh Graduate', '1–3 years', '3–5 years', '5+ years', 'Senior'];
  final List<String> educationOptions  = ['SPM', 'Diploma', "Bachelor's Degree", "Master's Degree", 'PhD'];
  final List<String> appMethodOptions  = ['In-app', 'Email', 'External URL'];
  final List<String> reqCategories     = ['General', 'IT / Tech', 'Design', 'Sales'];

  // ─────────────────────────────────────────────────────────────────────────
  // SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────

  final Map<String, List<String>> descSuggestions = {
    'Full-time': [
      'Responsible for day-to-day operations',
      'Collaborate with cross-functional teams',
      'Prepare and submit weekly reports',
      'Handle customer enquiries and complaints',
      'Achieve monthly sales targets',
    ],
    'Part-time': [
      'Assist with daily tasks and operations',
      'Support the team during peak hours',
      'Handle customer service duties',
      'Perform data entry and filing',
    ],
    'Contract': [
      'Deliver project milestones on schedule',
      'Provide technical expertise for project scope',
      'Coordinate with stakeholders and vendors',
    ],
    'Casual': [
      'Available on an as-needed basis',
      'Assist during events or busy periods',
      'Flexible scheduling required',
    ],
  };

  final Map<String, List<String>> reqSuggestions = {
    'General': [
      'Minimum 1 year relevant experience',
      'Strong communication skills',
      'Proficient in Microsoft Office',
      'Able to work independently',
      'Good time management skills',
    ],
    'IT / Tech': [
      'Proficient in Flutter / Dart',
      'Experience with Firebase',
      'Knowledge of REST APIs',
      'Familiar with Git version control',
    ],
    'Design': [
      'Proficient in Figma / Adobe XD',
      'Strong portfolio required',
      'Experience in branding and visual design',
    ],
    'Sales': [
      'Proven sales track record',
      'Strong negotiation skills',
      'Experience with CRM tools',
      'Self-motivated and target-driven',
    ],
  };

  final List<String> benefitsSuggestions = [
    'EPF & SOCSO contributions',
    'Annual leave (14 days)',
    'Medical & hospitalisation coverage',
    'Performance bonus',
    'Staff discount',
    'Flexible working hours',
    'Remote work option',
    'Training & development programs',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATORS
  // ─────────────────────────────────────────────────────────────────────────

  String? validateStreetAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street address is required';
    }

    final address = value.trim();

    if (address.length < 5) {
      return 'Please enter a complete address';
    }

    if (!RegExp(r'\d').hasMatch(address)) {
      return 'Include building/unit number (e.g., No. 123, Tower A)';
    }

    // Check for fake addresses
    final fakePatterns = [
      RegExp(r'^(test|asdf|qwerty|abc|xxx|fake|null|undefined)$', caseSensitive: false),
      RegExp(r'^[a-z]+$', caseSensitive: false),
      RegExp(r'^\d+$'),
    ];

    for (var pattern in fakePatterns) {
      if (pattern.hasMatch(address)) {
        return 'Please enter a valid street address';
      }
    }

    return null;
  }

  String? validatePostcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postcode is required';
    }

    final postcode = value.trim();

    if (!RegExp(r'^\d{5}$').hasMatch(postcode)) {
      return 'Postcode must be 5 digits (e.g., 47300)';
    }

    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }

    if (value.trim().length < 2) {
      return 'Enter valid city name';
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SETUP & CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  void initFormFields() {
    jobTitleCtrl         = TextEditingController();
    locationCtrl         = TextEditingController();
    streetCtrl           = TextEditingController();
    minPayCtrl           = TextEditingController();
    maxPayCtrl           = TextEditingController();
    descriptionCtrl      = TextEditingController();
    requirementsCtrl     = TextEditingController();
    benefitsCtrl         = TextEditingController();
    vacanciesCtrl        = TextEditingController(text: '1');
    applicationUrlCtrl   = TextEditingController();
    applicationEmailCtrl = TextEditingController();
    locationFocus        = FocusNode();

    streetCtrl.addListener(() {
      _updateLocationFromDropdowns();
      if (mounted) setState(() {});
    });
  }

  void cleanupFormFields() {
    locationDebounce?.cancel();
    locationFocus.dispose();
    jobTitleCtrl.dispose();
    locationCtrl.dispose();
    streetCtrl.dispose();
    minPayCtrl.dispose();
    maxPayCtrl.dispose();
    descriptionCtrl.dispose();
    requirementsCtrl.dispose();
    benefitsCtrl.dispose();
    vacanciesCtrl.dispose();
    applicationUrlCtrl.dispose();
    applicationEmailCtrl.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────

  void goToNextStep(GlobalKey<FormState> formKey) {
    if (!isCurrentStepValid(currentStep)) return;
    FocusScope.of(context).unfocus();
    if (currentStep < 2) setState(() => currentStep++);
  }

  void goToPrevStep() {
    FocusScope.of(context).unfocus();
    if (currentStep > 0) setState(() => currentStep--);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────────────

  bool isCurrentStepValid(int step) {
    if (step == 0) {
      if (_isEmpty(jobTitleCtrl.text))   { _showError('Please enter a job title');   return false; }
      if (selectedState == null)         { _showError('Please select a state');       return false; }
      if (selectedCity == null)          { _showError('Please select a city');        return false; }
      if (_isEmpty(streetCtrl.text))     { _showError('Please enter street address'); return false; }
      if (_isEmpty(minPayCtrl.text))     { _showError('Please enter minimum pay');   return false; }
      if (_isEmpty(maxPayCtrl.text))     { _showError('Please enter maximum pay');   return false; }

      final min = double.tryParse(minPayCtrl.text.trim()) ?? -1;
      final max = double.tryParse(maxPayCtrl.text.trim()) ?? -1;
      if (min < 0) { _showError('Minimum pay must be a valid number'); return false; }
      if (max < 0) { _showError('Maximum pay must be a valid number'); return false; }
      if (max < min) { _showError('Maximum pay cannot be less than minimum pay'); return false; }

      // Validate street address format
      final streetValidation = validateStreetAddress(streetCtrl.text);
      if (streetValidation != null) {
        _showError(streetValidation);
        return false;
      }

      // Validate postcode if entered
      if (selectedPostcode != null && selectedPostcode!.isNotEmpty) {
        final postcodeValidation = validatePostcode(selectedPostcode);
        if (postcodeValidation != null) {
          _showError(postcodeValidation);
          return false;
        }
      }
    }
    if (step == 1) {
      if (_isEmpty(descriptionCtrl.text))  { _showError('Please enter a job description'); return false; }
      if (_isEmpty(requirementsCtrl.text)) { _showError('Please enter job requirements');  return false; }
      if (selectedExperiences.isEmpty)   { _showError('Please select at least one experience level'); return false; }
      if (selectedEducations.isEmpty)    { _showError('Please select at least one education level');  return false; }
    }
    if (step == 2) {
      // No extra validation needed
    }
    return true;
  }

  bool _isEmpty(String s) => s.trim().isEmpty;
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

  // ─────────────────────────────────────────────────────────────────────────
  // SUGGESTION CHIPS
  // ─────────────────────────────────────────────────────────────────────────

  void addSuggestionToField(TextEditingController ctrl, String chip) {
    final current = ctrl.text;
    final alreadyAdded = current.contains(chip);

    if (alreadyAdded) {
      final lines = current.split('\n');
      final filtered = lines.where((line) {
        final clean = line.replaceAll('• ', '').trim();
        return clean != chip;
      }).toList();
      ctrl.text = filtered.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight();
      if (ctrl.text.isNotEmpty && !ctrl.text.endsWith('\n')) {
        ctrl.text = '${ctrl.text}\n';
      }
    } else {
      final trimmed = current.trim();
      ctrl.text = trimmed.isEmpty ? '• $chip\n' : '$trimmed\n• $chip\n';
    }

    ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD JOB DATA MAP
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> buildJobDataMap({
    required String companyName,
    required String companyId,
    required String employerId,
    required bool isEditing,
    required dynamic createdAt,
    required dynamic applicants,
  }) {
    final salary = '${selectedCurrency}${minPayCtrl.text.trim()} - ${selectedCurrency}${maxPayCtrl.text.trim()}';
    final now = DateTime.now();

    return {
      'title':             jobTitleCtrl.text.trim(),
      'company':           companyName,
      'companyId':         companyId,
      'location':          locationCtrl.text.trim(),
      'street_address':    streetCtrl.text.trim(),
      'state':             selectedState ?? '',
      'city':              selectedCity ?? '',
      'postcode':          selectedPostcode ?? '',
      'workType':          selectedWorkType,
      'workplace':         selectedWorkplace,
      'salary':            salary,
      'payType':           selectedPayType,
      'showPayOnAd':       showPayOnAd,
      'description':       descriptionCtrl.text.trim(),
      'requirements':      requirementsCtrl.text.trim(),
      'benefits':          benefitsCtrl.text.trim(),
      'vacancies':         int.tryParse(vacanciesCtrl.text.trim()) ?? 1,
      'experienceLevel':   selectedExperiences.join(', '),
      'educationLevel':    selectedEducations.join(', '),
      'publishDate':       publishDate ?? now,
      'expiryDate':        expiryDate,
      'applicationMethod': applicationMethod,
      'applicationUrl':    applicationUrlCtrl.text.trim(),
      'applicationEmail':  applicationEmailCtrl.text.trim(),
      'postedTime':        isEditing ? null : 'Just now',
      'applicants':        applicants,
      'createdAt':         createdAt,
      'employerId':        employerId,
      'industry':          selectedIndustry,
    }..removeWhere((_, v) => v == null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: kLabel)),
      if (required)
        const Text(' *',
            style: TextStyle(
                color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget buildHint(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, color: kHelper)),
  );

  InputDecoration buildDecoration(
      {required String hint, Widget? prefix, String? errorText}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kHint, fontSize: 13),
        prefixIcon: prefix,
        errorText: errorText,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        filled: true,
        fillColor: kFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        alignLabelWithHint: true,
      );

  Widget buildChipSelector({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) =>
      Wrap(
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
                  color: active ? kBlue : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: active ? kBlue : kBorder, width: 1.5),
                ),
                child: Text(opt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : const Color(0xFF444444),
                    )),
              ),
            );
          }).toList());

  Widget buildMultiChipSelector({
    required List<String> options,
    required Set<String> selected,
    required Function(String) onToggle,
    bool required = false,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) {
              final active = selected.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    active ? selected.remove(opt) : selected.add(opt);
                  });
                  onToggle(opt);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? kBlue : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: active ? kBlue : kBorder, width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (active) ...[
                      const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(opt,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? Colors.white : const Color(0xFF444444),
                        )),
                  ]),
                ),
              );
            }).toList()),
        if (required && selected.isEmpty && isSavingAttempted)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Please select at least one option',
                style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
      ]);

  Widget buildDropdown(String value, List<String> options, ValueChanged<String> onChanged) =>
      Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: kFill,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey),
            style: const TextStyle(fontSize: 14, color: kLabel),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ),
      );

  // ── Malaysia location picker widget with auto-postcode ────────────────────
  Widget _buildMalaysiaLocationPicker() {
    final states = kMalaysiaPostcodeMap.keys.toList()..sort();
    final cities = List<String>.from(_citiesForSelectedState)..sort();
    final postcodeSuggestions = _getPostcodeSuggestions();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Street address (free text with validation)
      buildLabel('Street / Building Name', required: true),
      TextFormField(
        controller: streetCtrl,
        maxLines: 2,
        decoration: buildDecoration(
          hint: 'e.g. No. 12, Jalan Bukit Bintang',
          prefix: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.home_outlined, size: 20, color: kInactiveGrey)),
        ),
        validator: (value) => validateStreetAddress(value),
      ),
      const SizedBox(height: 14),

      // State dropdown
      buildLabel('State', required: true),
      Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: kFill,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedState,
            isExpanded: true,
            hint: const Text('Select state',
                style: TextStyle(color: kHint, fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey),
            style: const TextStyle(fontSize: 14, color: kLabel),
            items: states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedState    = v;
                selectedCity     = null;
                selectedPostcode = null;
              });
              _updateLocationFromDropdowns();
            },
          ),
        ),
      ),
      const SizedBox(height: 14),

      // City dropdown (depends on state)
      buildLabel('City / Area', required: true),
      Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: selectedState == null
                ? const Color(0xFFEEEEEE)
                : kFill,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCity,
            isExpanded: true,
            hint: Text(
              selectedState == null
                  ? 'Select state first'
                  : 'Select city / area',
              style: const TextStyle(color: kHint, fontSize: 13),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey),
            style: const TextStyle(fontSize: 14, color: kLabel),
            items: cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: selectedState == null
                ? null
                : (v) {
              setState(() {
                selectedCity = v;
                _autoFillPostcodeFromCity();
              });
              _updateLocationFromDropdowns();
            },
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Postcode field with auto-fill and dropdown for multiple options
      buildLabel('Postcode', required: true),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: TextEditingController(
              text: selectedPostcode ?? '',
            )..addListener(() {
              setState(() {
                selectedPostcode = (selectedPostcode != null && selectedPostcode!.isNotEmpty)
                    ? selectedPostcode
                    : null;
              });
              _updateLocationFromDropdowns();
            }),
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: buildDecoration(
              hint: selectedCity != null
                  ? 'e.g. ${postcodeSuggestions.isNotEmpty ? postcodeSuggestions.first : '50000'}'
                  : 'Select city first',
              prefix: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.markunread_mailbox_outlined,
                      size: 20, color: kInactiveGrey)),
            ),
            onChanged: (v) {
              setState(() {
                selectedPostcode = v.trim().isEmpty ? null : v.trim();
              });
              _updateLocationFromDropdowns();
            },
            validator: (value) => validatePostcode(value),
          ),

          // Show multiple postcode options if available
          if (postcodeSuggestions.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: postcodeSuggestions.map((code) {
                  final isSelected = selectedPostcode == code;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPostcode = code;
                      });
                      _updateLocationFromDropdowns();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? kBlue : kFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? kBlue : kBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : kLabel,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),

      // Preview of full location string
      if (locationCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBlue.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: kBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(locationCtrl.text,
                  style: const TextStyle(
                      fontSize: 12, color: kBlue, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget buildDateField(String label, DateTime? date, VoidCallback onTap,
      VoidCallback onClear) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: kFill,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: kInactiveGrey),
            const SizedBox(width: 10),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : label,
              style: TextStyle(
                  fontSize: 14,
                  color: date != null ? kLabel : kHint),
            ),
            if (date != null) ...[
              const Spacer(),
              GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.clear,
                      size: 16, color: kInactiveGrey)),
            ],
          ]),
        ),
      );

  // ── Suggestion chips ──────────────────────────────────────────────────────
  Widget buildSuggestionRow(List<String> suggestions,
      TextEditingController ctrl) =>
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Icon(Icons.lightbulb_outline_rounded,
                size: 14, color: Color(0xFFE07B39)),
            SizedBox(width: 4),
            Text('Suggestions — tap to add / remove',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE07B39),
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                final isAdded = ctrl.text.contains(s);
                return GestureDetector(
                  onTap: () => addSuggestionToField(ctrl, s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAdded
                          ? const Color(0xFFE8FBF0)
                          : const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAdded
                            ? const Color(0xFF2CB06A)
                            : kBlue,
                        width: 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isAdded
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        size: 13,
                        color: isAdded
                            ? const Color(0xFF2CB06A)
                            : kBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: isAdded
                                  ? const Color(0xFF2CB06A)
                                  : kBlue,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                );
              }).toList()),
        ]),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // STEPPER WIDGET
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildStepper() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
    child: Row(
      children: List.generate(stepLabels.length, (i) {
        final isActive = i == currentStep;
        final isDone   = i < currentStep;
        final isLast   = i == stepLabels.length - 1;
        return Expanded(
          child: Row(children: [
            Expanded(
                child: Column(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive || isDone ? kBlue : Colors.white,
                      border: Border.all(
                        color: isActive || isDone ? kBlue : kInactiveGrey,
                        width: isActive ? 5 : 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(stepLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? kBlue : kInactiveGrey,
                      )),
                ])),
            if (!isLast)
              Expanded(
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: isDone ? kBlue : kInactiveGrey,
                  )),
          ]),
        );
      }),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 - CLASSIFY
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildClassifyStep({Widget? extraTop}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      if (extraTop != null) ...[extraTop, const SizedBox(height: 20)],

      buildLabel('Job Title', required: true),
      TextFormField(
        controller: jobTitleCtrl,
        decoration: buildDecoration(
          hint: 'Enter a professional job title',
          prefix: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.work_outline_rounded,
                  size: 20, color: Colors.grey)),
        ),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Job title is required' : null,
      ),
      const SizedBox(height: 20),

      // MALAYSIA LOCATION PICKER
      buildLabel('Job Location', required: true),
      const SizedBox(height: 4),
      _buildMalaysiaLocationPicker(),
      const SizedBox(height: 16),

      buildLabel('Workplace Option'),
      buildDropdown(selectedWorkplace, ['On-site', 'Remote', 'Hybrid'],
              (v) => setState(() => selectedWorkplace = v)),
      const SizedBox(height: 16),

      buildLabel('Work Type', required: true),
      buildChipSelector(
          options: workTypeOptions,
          selected: selectedWorkType,
          onSelect: (v) => setState(() => selectedWorkType = v)),
      const SizedBox(height: 20),

      buildLabel('Pay Type', required: true),
      buildChipSelector(
          options: payTypeOptions,
          selected: selectedPayType,
          onSelect: (v) => setState(() => selectedPayType = v)),
      const SizedBox(height: 20),

      buildLabel('Pay Range', required: true),
      const Text(
          'Enter a range. If exact, enter the same value in both fields.',
          style: TextStyle(fontSize: 12, color: kHelper)),
      const SizedBox(height: 14),

      buildLabel('Currency'),
      buildDropdown(selectedCurrency, currencyOptions,
              (v) => setState(() => selectedCurrency = v)),
      const SizedBox(height: 14),

      buildLabel('From', required: true),
      TextFormField(
        controller: minPayCtrl,
        keyboardType: TextInputType.number,
        decoration: buildDecoration(hint: 'Enter minimum pay'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (double.tryParse(v.trim()) == null) return 'Must be a valid number';
          if (double.parse(v.trim()) < 0) return 'Pay cannot be negative';
          return null;
        },
      ),
      const SizedBox(height: 12),

      buildLabel('To', required: true),
      TextFormField(
        controller: maxPayCtrl,
        keyboardType: TextInputType.number,
        decoration: buildDecoration(hint: 'Enter maximum pay'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final min = double.tryParse(minPayCtrl.text.trim());
          final max = double.tryParse(v.trim());
          if (max == null) return 'Must be a valid number';
          if (min != null && max < min) return 'Cannot be less than minimum pay';
          if (max < 0) return 'Pay cannot be negative';
          return null;
        },
      ),
      const SizedBox(height: 20),

      buildLabel('Pay shown on ad'),
      Row(children: ['Yes', 'No'].map((opt) {
        final active = showPayOnAd == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => showPayOnAd = opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: opt == 'Yes' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: active ? kBlue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? kBlue : kBorder, width: 1.5),
              ),
              child: Center(
                  child: Text(opt,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? Colors.white
                            : const Color(0xFF444444),
                      ))),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 - WRITE
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildWriteStep() {
    final descSugs =
        descSuggestions[selectedWorkType] ?? descSuggestions['Full-time']!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      buildLabel('Job Description', required: true),
      TextFormField(
        controller: descriptionCtrl,
        maxLines: 6,
        decoration: buildDecoration(
            hint:
            'Describe the role, day-to-day tasks and responsibilities...'),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Job description is required' : null,
      ),
      buildSuggestionRow(descSugs, descriptionCtrl),
      const SizedBox(height: 24),

      buildLabel('Requirements & Skills', required: true),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: reqCategories.map((cat) {
              final active = reqCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => reqCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8, bottom: 10),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? kBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? kBlue : kBorder),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? kBlue : kHelper,
                      )),
                ),
              );
            }).toList()),
      ),
      TextFormField(
        controller: requirementsCtrl,
        maxLines: 5,
        decoration: buildDecoration(
            hint:
            'e.g. Minimum 2 years experience, proficient in Microsoft Office...'),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Requirements are required' : null,
      ),
      buildSuggestionRow(reqSuggestions[reqCategory]!, requirementsCtrl),
      const SizedBox(height: 24),

      buildLabel('Benefits'),
      TextFormField(
        controller: benefitsCtrl,
        maxLines: 4,
        decoration: buildDecoration(
            hint: 'e.g. EPF & SOCSO, medical coverage, annual leave...'),
      ),
      buildSuggestionRow(benefitsSuggestions, benefitsCtrl),
      const SizedBox(height: 24),

      buildLabel('Number of Vacancies'),
      Row(children: [
        _buildVacancyButton(
          icon: Icons.remove,
          color: kFill,
          iconColor: kLabel,
          onTap: () {
            final v = int.tryParse(vacanciesCtrl.text) ?? 1;
            if (v > 1) {
              vacanciesCtrl.text = '${v - 1}';
              setState(() {});
            }
          },
        ),
        const SizedBox(width: 12),
        SizedBox(
            width: 80,
            child: TextFormField(
              controller: vacanciesCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: buildDecoration(hint: '1'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'Min 1';
                return null;
              },
              onChanged: (_) => setState(() {}),
            )),
        const SizedBox(width: 12),
        _buildVacancyButton(
          icon: Icons.add,
          color: kBlue,
          iconColor: Colors.white,
          onTap: () {
            final v = int.tryParse(vacanciesCtrl.text) ?? 1;
            vacanciesCtrl.text = '${v + 1}';
            setState(() {});
          },
        ),
      ]),
      const SizedBox(height: 20),

      buildLabel('Experience Level', required: true),
      buildHint('Select all that apply — tap again to deselect'),
      buildMultiChipSelector(
          options: experienceOptions,
          selected: selectedExperiences,
          onToggle: (_) {},
          required: true),
      const SizedBox(height: 20),

      buildLabel('Minimum Education', required: true),
      buildHint('Select all that apply — tap again to deselect'),
      buildMultiChipSelector(
          options: educationOptions,
          selected: selectedEducations,
          onToggle: (_) {},
          required: true),
    ]);
  }

  Widget _buildVacancyButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            border: color == kFill ? Border.all(color: kBorder) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 - MANAGE
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildManageStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),

      buildLabel('Publish Date'),
      buildDateField(
        'Publish now (immediately)',
        publishDate,
            () async {
          final p = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
          );
          if (p != null) setState(() => publishDate = p);
        },
            () => setState(() => publishDate = null),
      ),
      buildHint('Leave empty to publish immediately'),
      const SizedBox(height: 16),

      buildLabel('Ad Expiry Date'),
      buildDateField(
        'Select expiry date',
        expiryDate,
            () async {
          final p = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 180)),
          );
          if (p != null) setState(() => expiryDate = p);
        },
            () => setState(() => expiryDate = null),
      ),
      buildHint('Ad will auto-close after this date'),
      const SizedBox(height: 20),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: const [
          Icon(Icons.info_outline_rounded, size: 18, color: kBlue),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Candidates will apply directly through the JobBuddy app.',
                  style: TextStyle(fontSize: 13, color: kBlue))),
        ]),
      ),
      const SizedBox(height: 16),

      // Ad Summary Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FF),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ad Summary',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kLabel)),
          const SizedBox(height: 12),
          _buildSummaryRow('Category',  selectedIndustry.isEmpty ? '—' : selectedIndustry),
          _buildSummaryRow('Job Title', jobTitleCtrl.text.isEmpty ? '—' : jobTitleCtrl.text),
          _buildSummaryRow('Street Address', streetCtrl.text.isEmpty ? '—' : streetCtrl.text),
          _buildSummaryRow('City', selectedCity ?? '—'),
          _buildSummaryRow('State', selectedState ?? '—'),
          _buildSummaryRow('Postcode', selectedPostcode ?? '—'),
          _buildSummaryRow('Work Type', selectedWorkType),
          _buildSummaryRow('Workplace', selectedWorkplace),
          _buildSummaryRow('Pay',
              '${selectedCurrency}${minPayCtrl.text.isEmpty ? "0" : minPayCtrl.text} – '
                  '${selectedCurrency}${maxPayCtrl.text.isEmpty ? "0" : maxPayCtrl.text} / $selectedPayType'),
          _buildSummaryRow('Vacancies',  vacanciesCtrl.text.isEmpty ? '1' : vacanciesCtrl.text),
          _buildSummaryRow('Experience', selectedExperiences.isEmpty ? '—' : selectedExperiences.join(', ')),
          _buildSummaryRow('Education',  selectedEducations.isEmpty  ? '—' : selectedEducations.join(', ')),
        ]),
      ),
    ]);
  }

  Widget _buildSummaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: kHelper))),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kLabel))),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // NAV BUTTONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget buildNavButtons({
    required String saveLabel,
    required VoidCallback onSave,
    required GlobalKey<FormState> formKey,
  }) {
    final isLast = currentStep == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 40),
      child: Row(children: [
        if (currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: goToPrevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: kBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(
                      color: kBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLast ? onSave : () => goToNextStep(formKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isLast ? saveLabel : 'Next',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}