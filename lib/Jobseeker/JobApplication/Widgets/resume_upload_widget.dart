import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ResumeUploadWidget extends StatefulWidget {
  final void Function(String filePath, String fileName) onFileSelected;
  final String? initialFileName;
  final String? initialFilePath;

  const ResumeUploadWidget({
    super.key,
    required this.onFileSelected,
    this.initialFileName,
    this.initialFilePath,
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
  String? _filePath;
  String? _uploadedAgo;
  bool    _isLoading    = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialFileName != null) {
      _fileName    = widget.initialFileName;
      _filePath    = widget.initialFilePath;
      _uploadedAgo = 'N/A';

      // Notify parent on first frame so _resumePath is set from the start
      if (widget.initialFilePath != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFileSelected(
              widget.initialFilePath!, widget.initialFileName!);
        });
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final picked = result.files.single;

      if (picked.size > 5 * 1024 * 1024) {
        setState(() {
          _isLoading    = false;
          _errorMessage = 'File too large. Maximum size is 5 MB.';
        });
        return;
      }

      final path = picked.path;
      if (path == null) {
        setState(() {
          _isLoading    = false;
          _errorMessage = 'Could not read file path. Please try again.';
        });
        return;
      }

      // Store the local path — no upload needed just to print to console
      setState(() {
        _fileName    = picked.name;
        _filePath    = path;
        _uploadedAgo = 'Selected just now';
        _isLoading   = false;
        _errorMessage = null;
      });

      // Notify parent with local path + filename
      widget.onFileSelected(path, picked.name);

    } catch (e) {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
      debugPrint('File pick error: $e');
    }
  }

  String get _displayName => _fileName ?? 'No file selected';
  bool   get _hasFile     => _fileName != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resume / CV',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasFile ? kBlue.withOpacity(0.4) : kBorder,
              width: _hasFile ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _hasFile ? kTextPrimary : kTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_hasFile) ...[
                      const SizedBox(height: 3),
                      Text(
                        _uploadedAgo ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _isLoading
                        ? const SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBlue,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 13,
                              color: kBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text(
                          _hasFile ? 'Replace File' : 'Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _hasFile
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: _hasFile ? kBlue : kTextSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                _errorMessage!,
                style: const TextStyle(
                    fontSize: 12, color: Colors.redAccent),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        const Text(
          'Accepted formats: PDF, DOC, DOCX — max 5 MB',
          style: TextStyle(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }
}
