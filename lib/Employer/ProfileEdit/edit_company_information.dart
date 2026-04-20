import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditCompanyInfo extends StatefulWidget {
  final String currentIndustry;
  final String currentWebsite;

  const EditCompanyInfo({
    Key? key,
    required this.currentIndustry,
    required this.currentWebsite
  }) : super(key: key);

  @override
  State<EditCompanyInfo> createState() => _EditCompanyInfoState();
}

class _EditCompanyInfoState extends State<EditCompanyInfo> {
  late TextEditingController _websiteController;
  String? _selectedIndustry;
  bool _isLoading = false;

  // Matching your Job Seeker color
  static const Color brandBlue = Color(0xFF2563EB);

  final List<String> _industries = [
    'Technology & IT',
    'Finance & Banking',
    'Healthcare & Medical',
    'Manufacturing',
    'Retail & E-commerce',
    'Education',
    'Hospitality & Tourism',
    'Construction & Real Estate',
    'Media & Communications',
    'Logistics & Transportation',
    'Oil & Gas',
    'Government & Public Sector',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _websiteController = TextEditingController(text: widget.currentWebsite);
    _selectedIndustry = _industries.contains(widget.currentIndustry)
        ? widget.currentIndustry
        : _industries[0];
  }

  @override
  void dispose() {
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'industry': _selectedIndustry,
        'website': _websiteController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company details saved!"), backgroundColor: brandBlue),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit company info',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Industry"),
            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              items: _industries.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedIndustry = newValue),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
            ),

            const SizedBox(height: 20),
            _buildLabel("Website URL"),
            _buildCustomField(_websiteController, "e.g. www.jabil.com", keyboardType: TextInputType.url),

            const SizedBox(height: 40),

            // Reusable Save Button (Same as Job Seeker style)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildCustomField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
    );
  }
}