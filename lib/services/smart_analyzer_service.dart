import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class SmartAnalyzerService {
  // We will keep your model name if it worked before,
  // but changed to 1.5-flash if you continue to see timeouts.
  static const String _AImodel = 'gemini-3-flash-preview';

  // FIX: Using a 'get' ensures the app fetches the key from memory
  // at the moment you click scan, not when the app first starts.
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";

  Future<List<Map<String, dynamic>>> getMissingSuggestionsFromImage({
    required Uint8List imageBytes,
    required List<dynamic> existingSkills,
    required List<dynamic> existingEducation,
    required List<dynamic> existingExperience,
    required List<dynamic> existingLanguages,
  }) async {
    try {
      // 1. Deep Debug: Let's see if the key actually exists in memory
      debugPrint("--- AI Service Debug ---");
      debugPrint("Detected API Key length: ${_apiKey.length}");

      if (_apiKey.isEmpty) {
        debugPrint("❌ ERROR: API Key is EMPTY. Check your .env file and pubspec.yaml assets.");
        return [];
      }

      // 2. OCR Step
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/profile_ocr.png').create();
      await file.writeAsBytes(imageBytes);
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFile(file));
      await textRecognizer.close();

      String extractedText = recognizedText.text;
      if (extractedText.isEmpty) {
        debugPrint("⚠️ OCR result was empty.");
        return [];
      }

      // 3. AI Analysis Step
      final model = GenerativeModel(model: _AImodel, apiKey: _apiKey);

      final prompt = '''
      You are a Resume Analyzer. Extract information from the text provided.
      
      RESUME TEXT: 
      $extractedText
      
      CURRENT PROFILE (DO NOT SUGGEST THESE):
      - Skills: $existingSkills
      - Languages: $existingLanguages
      - Education: $existingEducation
      - Experience: $existingExperience

      STRICT INSTRUCTIONS:
      1. Extract ONLY items NOT already in the current profile.
      2. Distinguish between technical "Skill" and spoken "Language".
      3. For "Education" and "Experience", if a Start/End date is missing, strictly use "-" for the "details" field.
      4. For "Experience", the "details" field MUST contain a short summary of job responsibilities found in the resume.
      5. Return ONLY a JSON list of objects.

      CATEGORIES: "Skill", "Language", "Education", "Experience".
      
      FORMAT EXAMPLE:
      [
        {"category": "Skill", "title": "Java", "subtitle": "", "details": ""},
        {"category": "Experience", "title": "Manager", "subtitle": "Fajar Export", "details": "Managed 10 employees and reduced friction."}
      ]
      ''';

      debugPrint("🚀 Sending request to Gemini...");

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        debugPrint("❌ AI Response was NULL.");
        return [];
      }

      // Debug: See exactly what the AI sent back
      debugPrint("📦 RAW AI RESPONSE: ${response.text}");

      String cleanedText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Debug: See what we are passing to the JSON decoder
      debugPrint("🧹 CLEANED JSON: $cleanedText");

      List<dynamic> aiResults = jsonDecode(cleanedText);

      // 4. Filtering Logic
      List<Map<String, dynamic>> finalSuggestions = [];

      for (var item in aiResults) {
        String title = (item['title'] ?? '').toString().toLowerCase().trim();
        String category = (item['category'] ?? '').toString();
        bool isDuplicate = false;

        if (category == 'Skill') {
          isDuplicate = existingSkills.any((s) => s.toString().toLowerCase().trim() == title);
        } else if (category == 'Language') {
          isDuplicate = existingLanguages.any((l) => l.toString().toLowerCase().trim() == title);
        } else if (category == 'Education') {
          isDuplicate = existingEducation.any((e) => e.toString().toLowerCase().trim() == title);
        } else if (category == 'Experience') {
          isDuplicate = existingExperience.any((ex) => ex.toString().toLowerCase().trim() == title);
        }

        if (!isDuplicate && title.isNotEmpty) {
          finalSuggestions.add(Map<String, dynamic>.from(item));
        }
      }

      debugPrint("✅ Found ${finalSuggestions.length} new suggestions.");
      return finalSuggestions;
    } catch (e) {
      debugPrint("❌ SmartAnalyzerService Error: $e");
      return [];
    }
  }
}