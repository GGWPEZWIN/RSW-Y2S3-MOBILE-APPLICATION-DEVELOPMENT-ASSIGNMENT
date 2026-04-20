import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditEducationPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? educationData;
  final String? docId; // Added docId to know if we are editing an existing one

  const EditEducationPage({Key? key, required this.user, this.educationData, this.docId}) : super(key: key);

  @override
  State<EditEducationPage> createState() => _EditEducationPageState();
}

class _EditEducationPageState extends State<EditEducationPage> {
  late TextEditingController _courseController;
  late TextEditingController _institutionController;
  late TextEditingController _yearController;
  late TextEditingController _highlightsController;

  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _courseController = TextEditingController(text: widget.educationData?['course'] ?? '');
    _institutionController = TextEditingController(text: widget.educationData?['institution'] ?? '');
    _yearController = TextEditingController(text: widget.educationData?['year'] ?? '');
    _highlightsController = TextEditingController(text: widget.educationData?['highlights'] ?? '');
    _isCompleted = widget.educationData?['isCompleted'] ?? false;
  }

  @override
  void dispose() {
    _courseController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    _highlightsController.dispose();
    super.dispose();
  }

  Future<void> _saveEducation() async {
    setState(() => _isLoading = true);
    try {
      final data = {
        'course': _courseController.text.trim(),
        'institution': _institutionController.text.trim(),
        'year': _yearController.text.trim(),
        'highlights': _highlightsController.text.trim(),
        'isCompleted': _isCompleted,
        'timestamp': FieldValue.serverTimestamp(), // Useful for sorting
      };

      if (widget.docId != null) {
        // UPDATE existing document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('education_history')
            .doc(widget.docId)
            .update(data);
      } else {
        // CREATE NEW document (Fixes the overwriting issue)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('education_history')
            .add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Education Saved!")));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEducation() async {
    if (widget.docId == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('education_history')
          .doc(widget.docId)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
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
        title: Text(widget.docId == null ? 'Add education' : 'Edit education',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Course or qualification"),
            _buildCustomField(_courseController, "e.g. Diploma in Software Engineering"),

            const SizedBox(height: 20),
            _buildLabel("Institution"),
            _buildCustomField(_institutionController, "e.g. TAR UMT"),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Qualification complete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Switch(
                  value: _isCompleted,
                  activeColor: brandBlue,
                  onChanged: (val) => setState(() => _isCompleted = val),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildLabel("Finished (optional)"),
            _buildCustomField(_yearController, "2025"),

            const SizedBox(height: 20),
            _buildLabel("Course highlights (optional)"),
            _buildCustomField(_highlightsController, "Add activities, projects, etc.", maxLines: 4),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEducation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            if (widget.docId != null) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _deleteEducation,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text("Delete Education", style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFE4E6)),
                    backgroundColor: const Color(0xFFFFF1F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _buildCustomField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}