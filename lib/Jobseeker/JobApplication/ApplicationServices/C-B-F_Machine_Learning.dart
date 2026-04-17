import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// MATH LOGIC: COSINE SIMILARITY
/// This calculates how "close" two vectors are in high-dimensional space.
double calculateSimilarity(List<double> vectorA, List<double> vectorB) {
  if (vectorA.length != vectorB.length) {
    throw ArgumentError("Vectors must have the same length");
  }

  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
    normA += vectorA[i] * vectorA[i];
    normB += vectorB[i] * vectorB[i];
  }

  double denominator = math.sqrt(normA) * math.sqrt(normB);
  if (denominator == 0) return 0.0;

  return dotProduct / denominator;
}

/// 2. DATA MODEL: RECOMMENDATION RESULT
class JobRecommendation {
  final Map<String, dynamic> jobData;
  final double similarityScore;

  JobRecommendation(this.jobData, this.similarityScore);
}

/// 3. ALGORITHM: K-NEAREST NEIGHBORS (KNN)
/// This ranks all jobs by similarity and returns the top 'k' results.
List<JobRecommendation> getKNearestNeighbors({
  required List<double> userVector,
  required List<Map<String, dynamic>> allJobsWithVectors,
  int k = 3,
}) {
  List<JobRecommendation> recommendations = [];

  for (var job in allJobsWithVectors) {
    if (job['vector'] == null) continue;

    // Ensure the vector is treated as a List of doubles
    List<double> jobVector = List<double>.from(job['vector']);

    double score = calculateSimilarity(userVector, jobVector);
    recommendations.add(JobRecommendation(job, score));
  }

  // Sort descending (highest similarity first)
  recommendations.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

  return recommendations.take(k).toList();
}

/// 4. THE SERVICE: CONNECTING DATA TO THE AI MODEL
class RecommendationService {
  final GenerativeModel _embeddingModel;

  RecommendationService(String apiKey)
      : _embeddingModel = GenerativeModel(
    model: 'gemini-embedding-2-preview', // this turns resume/job text into math (vectors).
    apiKey: apiKey,
  );

  /// 1. Profile Preparation
  String _prepareProfile(Map<String, dynamic> userData, String resumeText) {
    final skills = (userData['skills'] as List? ?? []).join(', ');
    return "User Profile: Target Role: ${userData['jobTitle']}. "
        "Skills: $skills. Experience: ${userData['experienceLevel']}. "
        "Resume Text: $resumeText";
  }

  /// 2. OCR Helper
  Future<String> extractTextFromBase64(String base64String) async {
    if (base64String.isEmpty) return "";
    try {
      // Handle potential Base64 headers
      String cleanBase64 = base64String.contains(',') ? base64String.split(',').last : base64String;
      Uint8List bytes = base64Decode(cleanBase64);

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/resume.png').create();
      await file.writeAsBytes(bytes);

      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      await textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      print("OCR Error: $e");
      return "";
    }
  }

  /// 3. MAIN ML PIPELINE
  Future<List<JobRecommendation>> recommendJobs({
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> allJobs,
    int k = 5,
  }) async {
    // A. Step 1: Extract text from resume
    String resumeText = "";
    if (userData['resume'] != null) {
      resumeText = await extractTextFromBase64(userData['resume']);
    }

    // B. Step 2: Generate User Vector
    final profileText = _prepareProfile(userData, resumeText);
    final userEmbedding = await _embeddingModel.embedContent(Content.text(profileText));
    final userVector = userEmbedding.embedding.values;

    print("DEBUG: User Profile Text: $profileText");
    print("DEBUG: Number of jobs found: ${allJobs.length}");

    // C. Step 3: Generate Job Vectors using your new Firebase fields
    List<Map<String, dynamic>> processedJobs = [];
    for (var job in allJobs) {
      // We combine Title, Description, and Requirements for the AI to "read"
      String jobText = "Job Title: ${job['title']}. "
          "Description: ${job['description']}. "
          "Requirements: ${job['requirements']}. "
          "Education: ${job['educationLevel']}. "
          "Experience: ${job['experienceLevel']}.";

      final jobEmbedding = await _embeddingModel.embedContent(Content.text(jobText));

      Map<String, dynamic> jobDataWithVector = Map.from(job);
      jobDataWithVector['vector'] = jobEmbedding.embedding.values;
      processedJobs.add(jobDataWithVector);
    }

    // D. Step 4: Run KNN to rank them
    return getKNearestNeighbors(
      userVector: userVector,
      allJobsWithVectors: processedJobs,
      k: k,
    );
  }
}