import 'package:cloud_firestore/cloud_firestore.dart';
import '../Employer/models/job_model.dart';

class JobService {
  final CollectionReference _jobsCollection =
  FirebaseFirestore.instance.collection('jobs');

  // Create a new job
  Future<void> createJob(Job job) async {
    try {
      await _jobsCollection.add(job.toMap());
    } catch (e) {
      print('Error creating job: $e');
      throw Exception('Failed to create job');
    }
  }

  // Get all jobs
  Stream<List<Job>> getJobs() {
    return _jobsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get recent jobs (limit 1 for dashboard)
  Stream<Job?> getRecentJob() {
    return _jobsCollection
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Job.fromMap(snapshot.docs.first.id,
          snapshot.docs.first.data() as Map<String, dynamic>);
    });
  }

  // Update job
  Future<void> updateJob(String jobId, Job job) async {
    try {
      await _jobsCollection.doc(jobId).update(job.toMap());
    } catch (e) {
      print('Error updating job: $e');
      throw Exception('Failed to update job');
    }
  }

  // Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).delete();
    } catch (e) {
      print('Error deleting job: $e');
      throw Exception('Failed to delete job');
    }
  }
}