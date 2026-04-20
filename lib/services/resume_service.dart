import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

      // 1. OPEN IMAGE PICKER
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return [];

      final pickedFile = result.files.single;

      // 2. CONSTRAINTS CHECK
      if (pickedFile.size > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File too large (Max 5MB)"), backgroundColor: Colors.red),
          );
        }
        return [];
      }

      // 3. START LOADER
      onLoading(true);

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

      // 4. SAVE TO FIRESTORE
      await _firestore.collection('users').doc(user.uid).update({
        'resumeUrl': base64Encode(fileBytes),
        'resumeFileName': pickedFile.name,
        'resumeUploadedAt': FieldValue.serverTimestamp(),
        'isBase64': true,
        'fileType': 'image',
      });

      // 5. FETCH CURRENT DATA FOR COMPARISON
      // Added 'languages' to the profile fetch
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final eduSnap = await _firestore.collection('users').doc(user.uid).collection('education_history').get();
      final expSnap = await _firestore.collection('users').doc(user.uid).collection('experience_history').get();

      final List<String> existingEdu = eduSnap.docs.map((d) => (d.data()['course'] ?? '').toString()).toList();
      final List<String> existingExp = expSnap.docs.map((d) => (d.data()['role'] ?? '').toString()).toList();

      // Get languages from the main user document
      final List<dynamic> existingLangs = userData['languages'] ?? [];

      // 6. ANALYZE
      final analyzer = SmartAnalyzerService();
      final suggestions = await analyzer.getMissingSuggestionsFromImage(
        imageBytes: fileBytes,
        existingSkills: userData['skills'] ?? [],
        existingEducation: existingEdu,
        existingExperience: existingExp,
        existingLanguages: existingLangs, // Pass languages to the AI
      );

      return suggestions;
    } catch (e) {
      debugPrint("ResumeService Error: $e");
      return [];
    } finally {
      onLoading(false);
    }
  }
}