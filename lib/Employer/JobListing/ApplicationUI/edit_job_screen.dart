// lib/Employer/CreateJob/edit_job.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared_job_form.dart';
import 'select_jobtitle.dart';

class EditJobPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const EditJobPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> with SharedJobForm {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  List<Map<String, dynamic>> _cachedCategories = [];
  bool _isFetchingCategories = false;

  @override
  void initState() {
    super.initState();
    initFormFields();
    _prefillFormWithExistingData();
    _preloadCategories();
  }

  @override
  void dispose() {
    cleanupFormFields();
    super.dispose();
  }

  Future<void> _preloadCategories() async {
    if (_cachedCategories.isNotEmpty) return;
    if (mounted) setState(() => _isFetchingCategories = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_data')
          .doc('industries')
          .get();
      if (doc.exists) {
        final map = (doc.data() as Map<String, dynamic>?)?['industries']
        as Map<String, dynamic>? ?? {};
        _cachedCategories = map.entries.map((e) => {
          'name': e.key,
          'jobTitles': List<String>.from(e.value['jobTitles'] ?? []),
        }).toList();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isFetchingCategories = false);
    }
  }

  void _prefillFormWithExistingData() {
    final job = widget.jobData;

    final salary = job['salary']?.toString() ?? '';
    final salaryParts = salary.replaceAll(RegExp(r'[A-Za-z]'), '').split('-');
    final minPay = salaryParts.isNotEmpty ? salaryParts[0].trim() : '';
    final maxPay = salaryParts.length > 1 ? salaryParts[1].trim() : '';

    final experiences = (job['experienceLevel']?.toString() ?? '')
        .split(',').map((e) => e.trim()).toSet();
    final educations = (job['educationLevel']?.toString() ?? '')
        .split(',').map((e) => e.trim()).toSet();

    setState(() {
      jobTitleCtrl.text     = job['title']?.toString() ?? '';
      locationCtrl.text     = job['location']?.toString() ?? '';
      selectedWorkplace     = job['workplace']?.toString() ?? 'On-site';
      selectedWorkType      = job['workType']?.toString() ?? 'Full-time';
      selectedPayType       = job['payType']?.toString() ?? 'Monthly';
      selectedCurrency      = _extractCurrency(job['salary']?.toString() ?? '') ?? 'MYR';
      minPayCtrl.text       = minPay;
      maxPayCtrl.text       = maxPay;
      showPayOnAd           = job['showPayOnAd']?.toString() ?? 'Yes';

      // FIX 3: Firestore stores it as 'industry' — read that field correctly
      selectedIndustry      = job['industry']?.toString() ?? '';

      descriptionCtrl.text  = job['description']?.toString() ?? '';
      requirementsCtrl.text = job['requirements']?.toString() ?? '';
      benefitsCtrl.text     = job['benefits']?.toString() ?? '';
      vacanciesCtrl.text    = (job['vacancies'] ?? 1).toString();

      if (experiences.isNotEmpty) {
        selectedExperiences.clear();
        selectedExperiences.addAll(experiences);
      }
      if (educations.isNotEmpty) {
        selectedEducations.clear();
        selectedEducations.addAll(educations);
      }

      publishDate               = (job['publishDate'] as Timestamp?)?.toDate();
      expiryDate                = (job['expiryDate'] as Timestamp?)?.toDate();
      applicationMethod         = job['applicationMethod']?.toString() ?? 'In-app';
      applicationEmailCtrl.text = job['applicationEmail']?.toString() ?? '';
      applicationUrlCtrl.text   = job['applicationUrl']?.toString() ?? '';

      _isLoading = false;
    });
  }

  String? _extractCurrency(String salary) {
    final match = RegExp(r'[A-Za-z]+').firstMatch(salary);
    return match?.group(0);
  }

  Future<void> _changeCategory() async {
    // FIX 2: If categories haven't loaded yet, wait for them before opening sheet
    if (_isFetchingCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading categories, please wait...')),
      );
      return;
    }

    // If cache is empty (fetch failed silently), try once more
    if (_cachedCategories.isEmpty) {
      await _preloadCategories();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryPickerSheet(
        currentCategory:     selectedIndustry,
        preloadedCategories: _cachedCategories,
        isLoading:           false, // already waited above
        onCategorySelected:  (categoryName, jobTitle) {
          setState(() {
            selectedIndustry  = categoryName;
            jobTitleCtrl.text = jobTitle;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _updateJob() async {
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
      final jobData = buildJobDataMap(
        companyName: widget.jobData['company']?.toString() ?? 'Your Company',
        companyId:   widget.jobData['companyId']?.toString() ?? user?.uid ?? '',
        employerId:  user?.uid ?? '',
        isEditing:   true,
        createdAt:   widget.jobData['createdAt'],
        applicants:  widget.jobData['applicants'] ?? '0 applied',
      );

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job updated!'), backgroundColor: Colors.green));
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

  Widget _buildChangeCategoryBanner() {
    // FIX 3: Shows the actual saved category name, never "Not set" if it exists
    final displayName = selectedIndustry.isNotEmpty ? selectedIndustry : 'Not set';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedJobForm.kBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SharedJobForm.kBlue.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.business_center_rounded, size: 20, color: SharedJobForm.kBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Category & Job Title',
                style: TextStyle(fontSize: 12, color: SharedJobForm.kHelper)),
            Text(displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        TextButton.icon(
          onPressed: _changeCategory,
          icon: _isFetchingCategories
              ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.edit, size: 16),
          label: Text(_isFetchingCategories ? 'Loading...' : 'Change'),
          style: TextButton.styleFrom(foregroundColor: SharedJobForm.kBlue),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Job',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
      ),
      body: isSaving
          ? const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Updating job...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ]))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            buildStepper(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            if (currentStep == 0)
              buildClassifyStep(extraTop: _buildChangeCategoryBanner()),
            if (currentStep == 1) buildWriteStep(),
            if (currentStep == 2) buildManageStep(),
            buildNavButtons(
              saveLabel: 'Save Changes',
              onSave:    _updateJob,
              formKey:   _formKey,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category picker bottom sheet — receives pre-loaded list, no Firestore calls
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  final String currentCategory;
  final List<Map<String, dynamic>> preloadedCategories;
  final bool isLoading;
  final Function(String categoryName, String jobTitle) onCategorySelected;

  const _CategoryPickerSheet({
    required this.currentCategory,
    required this.preloadedCategories,
    required this.isLoading,
    required this.onCategorySelected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.preloadedCategories;
    final q = _searchQuery.toLowerCase();
    return widget.preloadedCategories
        .where((i) => i['name'].toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Change Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.isLoading
                  ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading categories...', style: TextStyle(color: Colors.grey)),
                  ]))
                  : _filtered.isEmpty
                  ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No categories available'
                        : 'No results for "$_searchQuery"',
                    style: const TextStyle(color: Colors.grey),
                  ))
                  : ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final cat = _filtered[i];
                  final isSelected = cat['name'] == widget.currentCategory;
                  return ListTile(
                    leading: const Icon(Icons.business_center_rounded),
                    title: Text(cat['name'] as String),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF3B4FD8))
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      final title = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectJobTitlePage(
                            industryName: cat['name'] as String,
                            suggestedTitles:
                            List<String>.from(cat['jobTitles'] ?? []),
                          ),
                        ),
                      );
                      if (title != null && title.isNotEmpty) {
                        widget.onCategorySelected(cat['name'] as String, title);
                      }
                    },
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}