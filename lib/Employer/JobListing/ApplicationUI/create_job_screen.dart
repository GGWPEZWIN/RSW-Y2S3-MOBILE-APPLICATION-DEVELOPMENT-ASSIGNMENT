// lib/Employer/CreateJob/create_job.dart
//
// CREATE a new job posting
// Step 1: Pick category → Step 2: Pick job title → Step 3: Fill form → Save

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

  // Category selection screen state
  List<Map<String, dynamic>> _categories = [];
  String _categorySearchQuery = '';
  bool _isLoadingCategories = false;
  bool _showDropdown = false;
  bool _hasSelectedCategory = false;

  final TextEditingController _categorySearchCtrl = TextEditingController();
  final FocusNode _categoryFocus = FocusNode();

  List<Map<String, dynamic>> get _filteredCategories {
    if (_categorySearchQuery.isEmpty) return _categories;
    final q = _categorySearchQuery.toLowerCase();
    return _categories.where((cat) {
      final name = cat['name'].toString().toLowerCase();
      final keywords = List<String>.from(cat['keywords'] ?? []);
      return name.contains(q) || keywords.any((k) => k.contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    initFormFields();
    _loadCategories();

    _categoryFocus.addListener(() {
      if (!_categoryFocus.hasFocus) {
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
    _categorySearchCtrl.dispose();
    _categoryFocus.dispose();
    cleanupFormFields();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_data')
          .doc('industries')
          .get();
      if (doc.exists) {
        final map =
            (doc.data() as Map<String, dynamic>?)?['industries']
            as Map<String, dynamic>? ??
                {};
        setState(() {
          _categories = map.entries
              .map((e) => {
            'name': e.key,
            'keywords':
            List<String>.from(e.value['searchKeywords'] ?? []),
            'jobTitles':
            List<String>.from(e.value['jobTitles'] ?? []),
          })
              .toList();
          _isLoadingCategories = false;
        });
      } else {
        _useFallbackCategories();
      }
    } catch (e) {
      _useFallbackCategories();
    }
  }

  void _useFallbackCategories() {
    setState(() {
      _categories = [
        {'name': 'Technology & IT',      'keywords': ['tech', 'software'],  'jobTitles': ['Software Engineer', 'Developer']},
        {'name': 'Sales & Marketing',    'keywords': ['sales', 'marketing'],'jobTitles': ['Sales Executive', 'Marketing Manager']},
        {'name': 'Finance & Accounting', 'keywords': ['finance', 'account'],'jobTitles': ['Accountant', 'Financial Analyst']},
        {'name': 'Healthcare',           'keywords': ['health', 'medical'], 'jobTitles': ['Nurse', 'Doctor']},
        {'name': 'Education',            'keywords': ['education', 'teach'],'jobTitles': ['Teacher', 'Lecturer']},
      ];
      _isLoadingCategories = false;
    });
  }

  Future<void> _pickJobTitle(Map<String, dynamic> category) async {
    setState(() {
      selectedIndustry       = category['name'] as String;
      _categorySearchCtrl.text = category['name'] as String;
      _categorySearchQuery   = '';
      _showDropdown          = false;
    });

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectJobTitlePage(
          industryName: category['name'] as String,
          suggestedTitles:
          List<String>.from(category['jobTitles'] ?? []),
          initialTitle:
          jobTitleCtrl.text.isNotEmpty ? jobTitleCtrl.text : null,
        ),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        jobTitleCtrl.text    = result;
        _hasSelectedCategory = true;
      });
    } else {
      // User went back — reset category
      setState(() {
        _hasSelectedCategory = false;
        selectedIndustry     = '';
        _categorySearchCtrl.clear();
        _categorySearchQuery = '';
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
      String companyId   = user?.uid ?? 'unknown';

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
          companyId =
              data['companyId']?.toString().trim() ?? companyId;
        }
      }

      final jobData = buildJobDataMap(
        companyName: companyName,
        companyId:   companyId,
        employerId:  user?.uid ?? '',
        isEditing:   false,
        createdAt:   DateTime.now(),
        applicants:  '0 applied',
      );

      await FirebaseFirestore.instance.collection('jobs').add(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

  // ── Category selection screen ──────────────────────────────────────────────

  Widget _buildCategoryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        _buildHeaderCard(),
        const SizedBox(height: 24),
        buildLabel('Category', required: true),
        const SizedBox(height: 8),
        _buildSearchTextField(),
        if (_showDropdown &&
            _filteredCategories.isNotEmpty &&
            !_isLoadingCategories)
          _buildDropdownList(),
        if (_isLoadingCategories) _buildLoadingIndicator(),
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
        border:
        Border.all(color: SharedJobForm.kBlue.withValues(alpha: 0.2)),
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
      controller: _categorySearchCtrl,
      focusNode: _categoryFocus,
      onChanged: (v) => setState(() {
        _categorySearchQuery = v;
        _showDropdown = true;
      }),
      decoration: InputDecoration(
        hintText: 'Type to search category...',
        hintStyle:
        const TextStyle(color: SharedJobForm.kHint, fontSize: 13),
        prefixIcon:
        const Icon(Icons.search_rounded, color: SharedJobForm.kBlue),
        suffixIcon: _categorySearchQuery.isNotEmpty
            ? IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              _categorySearchCtrl.clear();
              setState(() {
                _categorySearchQuery = '';
                selectedIndustry     = '';
                _hasSelectedCategory = false;
              });
            })
            : null,
        filled: true,
        fillColor: SharedJobForm.kFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: SharedJobForm.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: SharedJobForm.kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: SharedJobForm.kBlue, width: 1.5)),
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
        itemCount: _filteredCategories.length,
        itemBuilder: (_, i) {
          final cat = _filteredCategories[i];
          return InkWell(
            onTap: () => _pickJobTitle(cat),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(_getCategoryIcon(cat['name'] as String),
                    size: 18, color: SharedJobForm.kBlue),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(cat['name'] as String,
                        style: const TextStyle(
                            fontSize: 14,
                            color: SharedJobForm.kLabel))),
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

  IconData _getCategoryIcon(String category) {
    if (category.contains('Technology')) return Icons.computer_rounded;
    if (category.contains('Sales'))      return Icons.trending_up_rounded;
    if (category.contains('Finance'))    return Icons.attach_money_rounded;
    if (category.contains('Healthcare')) return Icons.local_hospital_rounded;
    if (category.contains('Education'))  return Icons.school_rounded;
    return Icons.business_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Screen 1: Pick category first
    if (!_hasSelectedCategory) {
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
        body: _buildCategoryScreen(),
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
              // Go back to category selection
              setState(() {
                _hasSelectedCategory = false;
                selectedIndustry     = '';
                _categorySearchCtrl.clear();
                _categorySearchQuery = '';
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
                    style:
                    TextStyle(color: Colors.grey, fontSize: 14)),
              ]))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildStepper(),
                const Divider(
                    height: 1, color: Color(0xFFEEEEEE)),
                if (currentStep == 0) buildClassifyStep(),
                if (currentStep == 1) buildWriteStep(),
                if (currentStep == 2) buildManageStep(),
                buildNavButtons(
                  saveLabel: 'Post Job',
                  onSave:    _saveJobToFirebase,
                  formKey:   _formKey,
                ),
              ]),
        ),
      ),
    );
  }
}