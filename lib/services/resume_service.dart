import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Ensure this is in pubspec.yaml
import 'smart_analyzer_service.dart';

class ResumeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> uploadResume(
      BuildContext context,
      Function(bool) onLoading
      ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // 1. OPEN PICKER
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return [];

      final pickedFile = result.files.single;

      // 2. CONSTRAINT CHECK (Safety for Firestore 1MB limit)
      // We check raw size first, but we will resize it regardless
      if (pickedFile.size > 2 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File too large (Max 2MB for Base64 storage)"), backgroundColor: Colors.red),
          );
        }
        return [];
      }

      onLoading(true);

      // 3. GET BYTES
      Uint8List? fileBytes;
      if (pickedFile.bytes != null) {
        fileBytes = pickedFile.bytes;
      } else if (pickedFile.path != null) {
        fileBytes = await File(pickedFile.path!).readAsBytes();
      }

      if (fileBytes == null) {
        onLoading(false);
        return [];
      }

      // 4. RESIZE IMAGE (Crucial to avoid Firestore Document limit)
      img.Image? originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) throw "Could not decode image";

      // Resize to 800px width (Good balance for AI and Human readability)
      img.Image resized = img.copyResize(originalImage, width: 800);
      Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 60));

      // 5. SAVE BASE64 TO FIRESTORE
      await _firestore.collection('users').doc(user.uid).update({
        'resumeUrl': base64Encode(compressedBytes),
        'resumeFileName': pickedFile.name,
        'resumeUploadedAt': FieldValue.serverTimestamp(),
        'isBase64': true,
      });

      // 6. FETCH CURRENT DATA FOR AI CONTEXT
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final eduSnap = await _firestore.collection('users').doc(user.uid).collection('education_history').get();
      final expSnap = await _firestore.collection('users').doc(user.uid).collection('experience_history').get();

      final List<String> existingEdu = eduSnap.docs.map((d) => (d.data()['course'] ?? '').toString()).toList();
      final List<String> existingExp = expSnap.docs.map((d) => (d.data()['role'] ?? '').toString()).toList();
      final List<dynamic> existingLangs = userData['languages'] ?? [];

      // 7. ANALYZE WITH AI
      final analyzer = SmartAnalyzerService();
      final suggestions = await analyzer.getMissingSuggestionsFromImage(
        imageBytes: compressedBytes, // Use the resized bytes
        existingSkills: userData['skills'] ?? [],
        existingEducation: existingEdu,
        existingExperience: existingExp,
        existingLanguages: existingLangs,
      );

      return suggestions;
    } catch (e) {
      debugPrint("ResumeService Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis Error: $e"), backgroundColor: Colors.red),
        );
      }
      return [];
    } finally {
      onLoading(false);
    }
  }
}