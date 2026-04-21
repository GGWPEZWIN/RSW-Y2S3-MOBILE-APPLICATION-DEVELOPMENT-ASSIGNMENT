// lib/Employer/CreateJob/edit_job.dart
//
// EDIT an existing job posting
// Loads existing job data, shows form, saves with .update()

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

  @override
  void initState() {
    super.initState();
    initFormFields();
    _prefillFormWithExistingData();
  }

  @override
  void dispose() {
    cleanupFormFields();
    super.dispose();
  }

  void _prefillFormWithExistingData() {
    final job = widget.jobData;

    // Parse salary (format: "MYR1000 - MYR5000")
    final salary = job['salary']?.toString() ?? '';
    final salaryParts =
    salary.replaceAll(RegExp(r'[A-Za-z]'), '').split('-');
    final minPay = salaryParts.isNotEmpty ? salaryParts[0].trim() : '';
    final maxPay = salaryParts.length > 1 ? salaryParts[1].trim() : '';

    // Parse comma-separated values
    final experiences = (job['experienceLevel']?.toString() ?? '')
        .split(',')
        .map((e) => e.trim())
        .toSet();
    final educations = (job['educationLevel']?.toString() ?? '')
        .split(',')
        .map((e) => e.trim())
        .toSet();

    setState(() {
      // Basic info
      jobTitleCtrl.text = job['title']?.toString() ?? '';
      locationCtrl.text = job['location']?.toString() ?? '';
      selectedWorkplace = job['workplace']?.toString() ?? 'On-site';
      selectedWorkType = job['workType']?.toString() ?? 'Full-time';
      selectedPayType = job['payType']?.toString() ?? 'Monthly';
      selectedCurrency =
          _extractCurrency(job['salary']?.toString() ?? '') ?? 'MYR';
      minPayCtrl.text = minPay;
      maxPayCtrl.text = maxPay;
      showPayOnAd = job['showPayOnAd']?.toString() ?? 'Yes';
      selectedIndustry = job['industry']?.toString() ?? '';

      // Description & requirements
      descriptionCtrl.text = job['description']?.toString() ?? '';
      requirementsCtrl.text = job['requirements']?.toString() ?? '';
      benefitsCtrl.text = job['benefits']?.toString() ?? '';
      vacanciesCtrl.text = (job['vacancies'] ?? 1).toString();

      // Multi-select fields
      if (experiences.isNotEmpty) {
        selectedExperiences.clear();
        selectedExperiences.addAll(experiences);
      }
      if (educations.isNotEmpty) {
        selectedEducations.clear();
        selectedEducations.addAll(educations);
      }

      // Dates
      publishDate = (job['publishDate'] as Timestamp?)?.toDate();
      expiryDate = (job['expiryDate'] as Timestamp?)?.toDate();

      // Application method
      applicationMethod = job['applicationMethod']?.toString() ?? 'In-app';
      applicationEmailCtrl.text = job['applicationEmail']?.toString() ?? '';
      applicationUrlCtrl.text = job['applicationUrl']?.toString() ?? '';

      _isLoading = false;
    });
  }

  String? _extractCurrency(String salary) {
    final match = RegExp(r'[A-Za-z]+').firstMatch(salary);
    return match?.group(0);
  }

  Future<void> _changeIndustryAndTitle() async {
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _IndustryPickerSheet(
        currentIndustry: selectedIndustry,
        onIndustrySelected: (industryName, jobTitle) {
          setState(() {
            selectedIndustry = industryName;
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
        companyName:
        widget.jobData['company']?.toString() ?? 'Your Company',
        companyId:
        widget.jobData['companyId']?.toString() ?? user?.uid ?? '',
        employerId: user?.uid ?? '',
        isEditing: true,
        createdAt: widget.jobData['createdAt'],
        applicants: widget.jobData['applicants'] ?? '0 applied',
      );

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Job updated!'),
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

  Widget _buildChangeIndustryBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SharedJobForm.kBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: SharedJobForm.kBlue.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.business_center_rounded,
            size: 20, color: SharedJobForm.kBlue),
        const SizedBox(width: 12),
        Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Industry & Job Title',
                style: TextStyle(
                    fontSize: 12, color: SharedJobForm.kHelper)),
            Text(
                selectedIndustry.isEmpty ? 'Not set' : selectedIndustry,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        TextButton.icon(
          onPressed: _changeIndustryAndTitle,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change'),
          style: TextButton.styleFrom(
              foregroundColor: SharedJobForm.kBlue),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                Text('Updating job...',
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
                if (currentStep == 0)
                  buildClassifyStep(
                      extraTop: _buildChangeIndustryBanner()),
                if (currentStep == 1) buildWriteStep(),
                if (currentStep == 2) buildManageStep(),
                buildNavButtons(
                  saveLabel: 'Save Changes',
                  onSave: _updateJob,
                  formKey: _formKey,
                ),
              ]),
        ),
      ),
    );
  }
}

// Bottom sheet for picking industry & title (used only in edit mode)
class _IndustryPickerSheet extends StatefulWidget {
  final String currentIndustry;
  final Function(String industryName, String jobTitle) onIndustrySelected;

  const _IndustryPickerSheet({
    required this.currentIndustry,
    required this.onIndustrySelected,
  });

  @override
  State<_IndustryPickerSheet> createState() =>
      _IndustryPickerSheetState();
}

class _IndustryPickerSheetState extends State<_IndustryPickerSheet> {
  List<Map<String, dynamic>> _industries = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIndustries();
  }

  Future<void> _loadIndustries() async {
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
          _industries = map.entries
              .map((e) => {
            'name': e.key,
            'jobTitles':
            List<String>.from(e.value['jobTitles'] ?? []),
          })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _industries;
    return _industries
        .where((i) => i['name']
        .toString()
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Change Category',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search industry...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final ind = _filtered[i];
                  return ListTile(
                    leading:
                    const Icon(Icons.business_center),
                    title: Text(ind['name']),
                    onTap: () async {
                      // Push to job title picker
                      final title =
                      await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectJobTitlePage(
                            industryName: ind['name'],
                            suggestedTitles:
                            List<String>.from(
                                ind['jobTitles'] ?? []),
                          ),
                        ),
                      );
                      if (title != null &&
                          title.isNotEmpty) {
                        widget.onIndustrySelected(
                            ind['name'], title);
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