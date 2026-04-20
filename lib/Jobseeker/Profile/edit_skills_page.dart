import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSkillsPage extends StatefulWidget {
  final User user;
  final List<dynamic>? currentSkills;
  final List<dynamic>? currentLanguages;

  const EditSkillsPage({
    Key? key,
    required this.user,
    this.currentSkills,
    this.currentLanguages
  }) : super(key: key);

  @override
  State<EditSkillsPage> createState() => _EditSkillsPageState();
}

class _EditSkillsPageState extends State<EditSkillsPage> {
  // We use a list of controllers so each box has its own "memory"
  List<TextEditingController> _skillControllers = [];
  List<TextEditingController> _languageControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize skill boxes from existing data
    if (widget.currentSkills != null && widget.currentSkills!.isNotEmpty) {
      for (var skill in widget.currentSkills!) {
        _skillControllers.add(TextEditingController(text: skill.toString()));
      }
    } else {
      _skillControllers.add(TextEditingController()); // Start with 1 empty box
    }

    // Initialize language boxes from existing data
    if (widget.currentLanguages != null && widget.currentLanguages!.isNotEmpty) {
      for (var lang in widget.currentLanguages!) {
        _languageControllers.add(TextEditingController(text: lang.toString()));
      }
    } else {
      _languageControllers.add(TextEditingController()); // Start with 1 empty box
    }
  }

  @override
  void dispose() {
    for (var c in _skillControllers) {
      c.dispose();
    }
    for (var c in _languageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // --- ADD / REMOVE LOGIC ---
  void _addNewField(List<TextEditingController> list) {
    setState(() {
      list.add(TextEditingController());
    });
  }

  void _removeField(List<TextEditingController> list, int index) {
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      // Map the text from every controller into a clean list
      List<String> skillsList = _skillControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      List<String> languagesList = _languageControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'skills': skillsList,
        'languages': languagesList,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
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
        title: const Text('Edit Skills & Languages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SKILLS SECTION ---
            _buildHeaderSection("Technical Skills", () => _addNewField(_skillControllers)),
            const SizedBox(height: 12),
            ..._skillControllers.asMap().entries.map((entry) {
              return _buildDynamicBox(entry.key, entry.value, _skillControllers, "e.g. Flutter");
            }).toList(),

            const SizedBox(height: 32),

            // --- LANGUAGES SECTION ---
            _buildHeaderSection("Languages", () => _addNewField(_languageControllers)),
            const SizedBox(height: 12),
            ..._languageControllers.asMap().entries.map((entry) {
              return _buildDynamicBox(entry.key, entry.value, _languageControllers, "e.g. English");
            }).toList(),

            const SizedBox(height: 50),

            // --- SAVE BUTTON ---
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
                    : const Text("Update Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the Label + Add Button
  Widget _buildHeaderSection(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18, color: Color(0xFF2563EB)),
          label: const Text("Add New", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Helper to build the individual input box with a delete button
  Widget _buildDynamicBox(int index, TextEditingController controller, List<TextEditingController> list, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
          ),
          if (list.length > 1) // Only show delete if there is more than 1 box
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: () => _removeField(list, index),
            ),
        ],
      ),
    );
  }
}