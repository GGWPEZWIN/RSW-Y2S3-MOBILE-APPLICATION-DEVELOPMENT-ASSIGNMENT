import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ResumeParserPage extends StatefulWidget {
  const ResumeParserPage({super.key});

  @override
  _ResumeParserPageState createState() => _ResumeParserPageState();
}

class _ResumeParserPageState extends State<ResumeParserPage> {
  final ImagePicker _picker = ImagePicker();
  String _extractedText = "No data extracted yet.";
  bool _isLoading = false;
  String AImodel = 'gemini-3-flash-preview';
  final String _apiKey = dotenv.env['APPLICANT_API_KEY'] ?? "";

  // Initialize the Gemini Model
  late final model = GenerativeModel(
    model: AImodel,
    apiKey: _apiKey,
  );

  Future<void> _processResume() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await image.readAsBytes();

      // Define the prompt for text extraction
      final prompt = TextPart(
        //"Read this resume image and extract all text clearly. "
          "list down the skill as skill:"
        //"Format it neatly so it is easy to read."
      );

      final imagePart = DataPart('image/jpeg', bytes);

      // Call the API
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      setState(() {
        _extractedText = response.text ?? "Failed to extract text.";
      });
    } catch (e) {
      setState(() {
        _extractedText = "Error: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("JobBuddy Resume Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _processResume,
              icon: Icon(Icons.document_scanner),
              label: Text("Upload Resume Image"),
            ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_extractedText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



