import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class SmartAnalyzerService {
  // Use the modern model name found in your teammate's working code
  static const String _AImodel = 'gemini-3-flash-preview';

  // CHANGE THIS: Paste your NEW personal API key here
  static const String _apiKey = 'AIzaSyBNZKfTArIZBG8rmGXyg5XwuA5n83eh35g';

  Future<List<Map<String, dynamic>>> getMissingSuggestionsFromImage({
    required Uint8List imageBytes,
    required List<dynamic> existingSkills,
    required List<dynamic> existingEducation,
    required List<dynamic> existingExperience,
  }) async {
    try {
      // 1. Local OCR: This part works on your device (confirmed by your logs)
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/profile_ocr.png').create();
      await file.writeAsBytes(imageBytes);

      final inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      String extractedText = recognizedText.text;
      if (extractedText.isEmpty) return [];

      // 2. Gemini 3: Uses your personal key and the stable text-only path
      final model = GenerativeModel(
        model: _AImodel,
        apiKey: _apiKey,
      );

      final prompt = '''
      Compare this resume text with the User's Profile and suggest missing items.
      
      RESUME TEXT: 
      $extractedText

      USER'S PROFILE:
      - Skills: $existingSkills
      - Education: $existingEducation
      - Experience: $existingExperience

      Return ONLY a JSON list of missing Skills, Education, or Experience objects.
      Format: [{"category": "Skill", "title": "Name", "subtitle": "", "details": ""}]
      ''';

      // Send pure text to avoid Vision API version conflicts
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) return [];

      String cleanedText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      debugPrint("AI Analyzer Result: $cleanedText");
      return List<Map<String, dynamic>>.from(jsonDecode(cleanedText));

    } catch (e) {
      debugPrint("Profile Analyzer Error: $e");
      return [];
    }
  }
}