import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import 'employer_dashboard.dart';

class CompanyRegistrationPage extends StatefulWidget {
  const CompanyRegistrationPage({super.key});

  @override
  State<CompanyRegistrationPage> createState() => _CompanyRegistrationPageState();
}

class _CompanyRegistrationPageState extends State<CompanyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _companyDescriptionController = TextEditingController();

  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF3B4FD8);

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyWebsiteController.dispose();
    _companyDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final companyData = {
        'name': _companyNameController.text.trim(),
        'email': _companyEmailController.text.trim(),
        'phone': _companyPhoneController.text.trim(),
        'address': _companyAddressController.text.trim(),
        'website': _companyWebsiteController.text.trim(),
        'description': _companyDescriptionController.text.trim(),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save company to Firestore
      final docRef = await FirebaseFirestore.instance.collection('companies').add(companyData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created!'), backgroundColor: Colors.green),
        );
        // Navigate to EmployerDashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployerDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initialize l10n
    final l10n = AppLocalizations.of(context);

    // 2. Safety check
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Translated 'Create Company'
        title: Text(l10n.createCompanyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.setupCompanyHeader,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupCompanySubtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Company Name
              _buildFieldLabel(l10n.companyNameLabel),
              TextFormField(
                controller: _companyNameController,
                decoration: _inputDecoration(l10n.companyNameHint),
                validator: (v) => v == null || v.trim().isEmpty ? l10n.companyNameRequired : null,
              ),
              const SizedBox(height: 20),

              // Company Email
              _buildFieldLabel(l10n.companyEmailLabel),
              TextFormField(
                controller: _companyEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('hr@company.com'),
                validator: (v) => v == null || v.trim().isEmpty ? l10n.emailRequired : null,
              ),
              const SizedBox(height: 20),

              // Phone
              _buildFieldLabel(l10n.phoneNumberLabel),
              TextFormField(
                controller: _companyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('+60 12-345 6789'),
              ),
              const SizedBox(height: 20),

              // Address
              _buildFieldLabel(l10n.addressLabel),
              TextFormField(
                controller: _companyAddressController,
                maxLines: 2,
                decoration: _inputDecoration(l10n.addressHint),
              ),
              const SizedBox(height: 20),

              // Website (optional)
              _buildFieldLabel(l10n.websiteLabel),
              TextFormField(
                controller: _companyWebsiteController,
                keyboardType: TextInputType.url,
                decoration: _inputDecoration('https://www.yourcompany.com'),
              ),
              const SizedBox(height: 20),

              // Description
              _buildFieldLabel(l10n.descriptionLabel),
              TextFormField(
                controller: _companyDescriptionController,
                maxLines: 3,
                decoration: _inputDecoration(l10n.descriptionHint),
              ),
              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.createCompanyBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}