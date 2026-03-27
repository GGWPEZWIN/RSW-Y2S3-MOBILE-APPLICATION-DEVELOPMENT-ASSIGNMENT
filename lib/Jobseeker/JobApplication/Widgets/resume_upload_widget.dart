import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class ResumeUploadWidget extends StatefulWidget {
  final void Function(String base64Data, String fileName) onFileSelected;
  final String? initialFileName;
  final String? initialFileBase64;

  const ResumeUploadWidget({
    super.key,
    required this.onFileSelected,
    this.initialFileName,
    this.initialFileBase64,
  });

  @override
  State<ResumeUploadWidget> createState() => _ResumeUploadWidgetState();
}

class _ResumeUploadWidgetState extends State<ResumeUploadWidget> {
  static const Color kBlue          = Color(0xFF2F6FED);
  static const Color kBorder        = Color(0xFFE4E9F0);
  static const Color kTextPrimary   = Color(0xFF0F1624);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kIconBg        = Color(0xFFF0F3F8);

  String? _fileName;
  String? _fileBase64;
  String? _uploadedAgo;
  bool    _isLoading    = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // CRITICAL: This ensures the UI updates when you return to this screen from a draft
  @override
  void didUpdateWidget(covariant ResumeUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFileName != oldWidget.initialFileName) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    setState(() {
      _fileName = widget.initialFileName;
      _fileBase64 = widget.initialFileBase64;
      _uploadedAgo = _fileName != null ? 'Loaded from draft' : null;
    });
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // UPDATED: Added image extensions to allowed formats
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final picked = result.files.single;

      // 5 MB limit check
      if (picked.size > 5 * 1024 * 1024) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'File too large. Maximum size is 5 MB.';
        });
        return;
      }

      final path = picked.path;
      if (path == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not read file path.';
        });
        return;
      }

      // 1. Read the raw bytes of the image/file
      final bytes = await File(path).readAsBytes();

      // 2. Convert the entire file to a Base64 string
      final base64String = base64Encode(bytes);

      setState(() {
        _fileName = picked.name;
        _fileBase64 = base64String;
        _uploadedAgo = 'Selected just now';
        _isLoading = false;
      });

      // 3. Notify parent with the full Base64 string
      widget.onFileSelected(base64String, picked.name);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  bool get _hasFile => _fileName != null;

  // Helper to determine icon based on file extension
  IconData _getIcon() {
    if (!_hasFile) return Icons.description_outlined;
    final ext = _fileName!.toLowerCase();
    if (ext.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg')) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resume / CV',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: kTextPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hasFile ? kBlue : kBorder, width: _hasFile ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'No file selected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _hasFile ? kTextPrimary : kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_hasFile) ...[
                      const SizedBox(height: 4),
                      Text(_uploadedAgo ?? '', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                    ],
                    const SizedBox(height: 12),
                    _isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : ElevatedButton(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_hasFile ? 'Replace File' : 'Upload File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: kIconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(_getIcon(), color: _hasFile ? kBlue : kTextSecondary, size: 28),
              ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }
}