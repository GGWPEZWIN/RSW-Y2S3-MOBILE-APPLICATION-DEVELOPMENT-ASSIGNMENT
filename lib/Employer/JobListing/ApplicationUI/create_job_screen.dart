// lib/Employer/CreateJob/create_job.dart
//
// CREATE a new job posting
// Step 1: Pick industry → Step 2: Pick job title → Step 3: Fill form → Save

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared_job_form.dart';
import 'select_jobtitle.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> with SharedJobForm {
  final _formKey = GlobalKey<FormState>();

  // Industry selection screen state
  List<Map<String, dynamic>> _industries = [];
  String _industrySearchQuery = '';
  bool _isLoadingIndustries = false;
  bool _showDropdown = false;
  bool _hasSelectedIndustry = false;

  final TextEditingController _industrySearchCtrl = TextEditingController();
  final FocusNode _industryFocus = FocusNode();

  List<Map<String, dynamic>> get _filteredIndustries {
    if (_industrySearchQuery.isEmpty) return _industries;
    final q = _industrySearchQuery.toLowerCase();
    return _industries.where((ind) {
      final name = ind['name'].toString().toLowerCase();
      final keywords = List<String>.from(ind['keywords'] ?? []);
      return name.contains(q) || keywords.any((k) => k.contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    initFormFields(); // from SharedJobForm
    _loadIndustries();

    _industryFocus.addListener(() {
      if (!_industryFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      } else {
        setState(() => _showDropdown = true);
      }
    });
  }

  @override
  void dispose() {
    _industrySearchCtrl.dispose();
    _industryFocus.dispose();
    cleanupFormFields(); // from SharedJobForm
    super.dispose();
  }

  Future<void> _loadIndustries() async {
    setState(() => _isLoadingIndustries = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_data')
          .doc('industries')
          .get();
      if (doc.exists) {
        final map = (doc.data() as Map<String, dynamic>?)?['industries']
        as Map<String, dynamic>? ??
            {};
        setState(() {
          _industries = map.entries
              .map((e) => {
            'name': e.key,
            'keywords': List<String>.from(e.value['searchKeywords'] ?? []),
            'jobTitles': List<String>.from(e.value['jobTitles'] ?? []),
          })
              .toList();
          _isLoadingIndustries = false;
        });
      } else {
        _useFallbackIndustries();
      }
    } catch (e) {
      _useFallbackIndustries();
    }
  }

  void _useFallbackIndustries() {
    setState(() {
      _industries = [
        {'name': 'Technology & IT', 'keywords': ['tech', 'software'], 'jobTitles': ['Software Engineer', 'Developer']},
        {'name': 'Sales & Marketing', 'keywords': ['sales', 'marketing'], 'jobTitles': ['Sales Executive', 'Marketing Manager']},
        {'name': 'Finance & Accounting', 'keywords': ['finance', 'account'], 'jobTitles': ['Accountant', 'Financial Analyst']},
        {'name': 'Healthcare', 'keywords': ['health', 'medical'], 'jobTitles': ['Nurse', 'Doctor']},
        {'name': 'Education', 'keywords': ['education', 'teach'], 'jobTitles': ['Teacher', 'Lecturer']},
      ];
      _isLoadingIndustries = false;
    });
  }

  Future<void> _pickJobTitle(Map<String, dynamic> industry) async {
    setState(() {
      selectedIndustry = industry['name'] as String;
      _industrySearchCtrl.text = industry['name'] as String;
      _industrySearchQuery = '';
      _showDropdown = false;
    });

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectJobTitlePage(
          industryName: industry['name'] as String,
          suggestedTitles: List<String>.from(industry['jobTitles'] ?? []),
          initialTitle: jobTitleCtrl.text.isNotEmpty ? jobTitleCtrl.text : null,
        ),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        jobTitleCtrl.text = result;
        _hasSelectedIndustry = true;
      });
    } else {
      // User went back - reset industry
      setState(() {
        _hasSelectedIndustry = false;
        selectedIndustry = '';
        _industrySearchCtrl.clear();
        _industrySearchQuery = '';
      });
    }
  }

  Future<void> _saveJobToFirebase() async {
    setState(() => isSavingAttempted = true);
    if (!_formKey.currentState!.validate()) return;
    if (selectedExperiences.isEmpty) {
      _showError('Please select at least one experience level');
      return;
    }
    if (selectedEducations.isEmpty) {
      _showError('Please select at least one education level');
      return;
    }

    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String companyName = 'Your Company';
      String companyId = user?.uid ?? 'unknown';

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          companyName = data['companyName']?.toString().trim() ??
              data['name']?.toString().trim() ??
              companyName;
          companyId = data['companyId']?.toString().trim() ?? companyId;
        }
      }

      final jobData = buildJobDataMap(
        companyName: companyName,
        companyId: companyId,
        employerId: user?.uid ?? '',
        isEditing: false,
        createdAt: DateTime.now(),
        applicants: '0 applied',
      );

      await FirebaseFirestore.instance.collection('jobs').add(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Job posted!'),
                backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // UI for industry selection screen
  Widget _buildIndustryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        _buildHeaderCard(),
        const SizedBox(height: 24),
        buildLabel('Category', required: true),
        const SizedBox(height: 8),
        _buildSearchTextField(),
        if (_showDropdown && _filteredIndustries.isNotEmpty && !_isLoadingIndustries)
          _buildDropdownList(),
        if (_isLoadingIndustries) _buildLoadingIndicator(),
        buildHint('Start typing to search for your category'),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SharedJobForm.kBlue.withValues(alpha: 0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SharedJobForm.kBlue.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.business_center_rounded,
            size: 48, color: SharedJobForm.kBlue),
        const SizedBox(height: 12),
        const Text('Select Your Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Search and select to get tailored job title suggestions',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ]),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _industrySearchCtrl,
      focusNode: _industryFocus,
      onChanged: (v) => setState(() {
        _industrySearchQuery = v;
        _showDropdown = true;
      }),
      decoration: InputDecoration(
        hintText: 'Type to search category...',
        hintStyle: const TextStyle(color: SharedJobForm.kHint, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: SharedJobForm.kBlue),
        suffixIcon: _industrySearchQuery.isNotEmpty
            ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _industrySearchCtrl.clear();
              setState(() {
                _industrySearchQuery = '';
                selectedIndustry = '';
                _hasSelectedIndustry = false;
              });
            })
            : null,
        filled: true,
        fillColor: SharedJobForm.kFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SharedJobForm.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SharedJobForm.kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: SharedJobForm.kBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdownList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SharedJobForm.kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredIndustries.length,
        itemBuilder: (_, i) {
          final ind = _filteredIndustries[i];
          return InkWell(
            onTap: () => _pickJobTitle(ind),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(_getIndustryIcon(ind['name'] as String),
                    size: 18, color: SharedJobForm.kBlue),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(ind['name'] as String,
                        style: const TextStyle(
                            fontSize: 14, color: SharedJobForm.kLabel))),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: SharedJobForm.kInactiveGrey),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  IconData _getIndustryIcon(String industry) {
    if (industry.contains('Technology')) return Icons.computer_rounded;
    if (industry.contains('Sales')) return Icons.trending_up_rounded;
    if (industry.contains('Finance')) return Icons.attach_money_rounded;
    if (industry.contains('Healthcare')) return Icons.local_hospital_rounded;
    if (industry.contains('Education')) return Icons.school_rounded;
    return Icons.business_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Screen 1: Pick industry first
    if (!_hasSelectedIndustry) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Create a job ad',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
        ),
        body: _buildIndustryScreen(),
      );
    }

    // Screen 2: The 3-step form
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (currentStep > 0) {
              goToPrevStep();
            } else {
              // Go back to industry selection
              setState(() {
                _hasSelectedIndustry = false;
                selectedIndustry = '';
                _industrySearchCtrl.clear();
                _industrySearchQuery = '';
              });
            }
          },
        ),
        title: const Text('Create a job ad',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
      ),
      body: isSaving
          ? const Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Posting job...',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            buildStepper(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            if (currentStep == 0) buildClassifyStep(),
            if (currentStep == 1) buildWriteStep(),
            if (currentStep == 2) buildManageStep(),
            buildNavButtons(
              saveLabel: 'Post Job',
              onSave: _saveJobToFirebase,
              formKey: _formKey,
            ),
          ]),
        ),
      ),
    );
  }
}