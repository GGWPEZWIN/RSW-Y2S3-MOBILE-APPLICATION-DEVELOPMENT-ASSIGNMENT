import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import './create_job_screen.dart';

class JobListScreen extends StatefulWidget {
  final List<Job> jobs;

  const JobListScreen({super.key, required this.jobs});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late List<Job> _currentJobs;
  static const Color _blue1 = Color(0xFF3B4FD8);
  static const Color _blue2 = Color(0xFF2F3DBF);

  @override
  void initState() {
    super.initState();
    _currentJobs = List.from(widget.jobs);
  }

  void _showDeleteDialog(BuildContext context, Job job, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, color: Color(0xFFFF2D55), size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete job',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure want to delete this post for <${job.title}>?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD1D5DB),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('No, keep it.', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _currentJobs.removeAt(index));
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2D55),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Yes, Delete!', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to navigate to edit screen
  Future<void> _navigateToEditJob(Job job, int index) async {
    final editedJob = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateJobPage(jobToEdit: job),
      ),
    );

    // If we got an edited job back, update the list
    if (editedJob != null && editedJob is Job) {
      setState(() {
        _currentJobs[index] = editedJob;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Job List",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateJobPage()));
              },
              icon: const Icon(Icons.add, color: Colors.black)
          ),
        ],
      ),
      body: _currentJobs.isEmpty
          ? const Center(child: Text("No jobs found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentJobs.length,
        itemBuilder: (context, index) {
          return _jobCard(_currentJobs[index], index);
        },
      ),
    );
  }

  Widget _jobCard(Job job, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue1, _blue2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TOP TAGS
          Row(
            children: [
              _tag(job.workType),
              const SizedBox(width: 8),
              _tag(job.workplace),
              const Spacer(),
              // Pencil Icon - Now with edit functionality
              GestureDetector(
                onTap: () => _navigateToEditJob(job, index),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              // Delete Icon
              GestureDetector(
                onTap: () => _showDeleteDialog(context, job, index),
                child: const Icon(Icons.delete, color: Colors.white, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // TITLE
          Text(job.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),

          const SizedBox(height: 4),

          Text(job.company,
              style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          // LOCATION
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(job.location,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),

          const SizedBox(height: 6),

          // SALARY
          Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(job.salary,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(color: Colors.white30),

          const SizedBox(height: 10),

          // BOTTOM
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(job.postedTime,
                  style: const TextStyle(color: Colors.white70)),

              const SizedBox(width: 16),

              const Icon(Icons.people, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(job.applicants,
                  style: const TextStyle(color: Colors.white70)),

              const Spacer(),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("View details",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
