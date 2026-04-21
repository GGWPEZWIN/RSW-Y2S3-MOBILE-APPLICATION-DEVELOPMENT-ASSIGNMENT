import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Employer/models/job_model.dart';
import '../JobApplication/ApplicationUI/job_details_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D5BE3)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const JobSearchScreen(),
    );
  }
}

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedWorkType = 'All work types';
  String _selectedRemoteOption = 'All remote options';
  String _selectedSalaryRange = 'RM 0 to RM50k+ Monthly';
  String _selectedClassification = 'Any classification';

  @override
  void dispose() {
    _keywordsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // REAL SEARCH FUNCTION – queries Firestore jobs collection
  // ------------------------------------------------------------
  Future<void> _performSearch() async {
    // 1. Capture and normalize user inputs
    final rawWhat = _keywordsController.text.trim();
    final searchWhat = rawWhat.toLowerCase();

    final rawWhere = _locationController.text.trim();
    final searchWhere = rawWhere.toLowerCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Base Query: Only use categorical dropdowns for the DB query
      // This keeps the request broad enough so we don't accidentally filter out everything
      Query query = FirebaseFirestore.instance.collection('jobs');

      if (_selectedWorkType != 'All work types') {
        query = query.where('workType', isEqualTo: _selectedWorkType);
      }
      if (_selectedRemoteOption != 'All remote options') {
        query = query.where('workplace', isEqualTo: _selectedRemoteOption);
      }
      if (_selectedClassification != 'Any classification') {
        query = query.where('classification', isEqualTo: _selectedClassification);
      }

      final snapshot = await query.get();

      // 3. Client-Side Filter: This handles the partial matches and case-insensitivity
      final filteredJobs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // --- LOCATION FILTER (WHERE) ---
        // We check if the stored location contains the user's search text
        final String dbLocation = (data['location'] ?? '').toString().toLowerCase();
        bool locationMatch = searchWhere.isEmpty || dbLocation.contains(searchWhere);

        // --- TITLE & KEYWORDS FILTER (WHAT) ---
        final String dbTitle = (data['title'] ?? '').toString().toLowerCase();
        final List<dynamic> dbKeywords = data['keywords'] ?? [];

        // Check if title contains the search string
        bool titleMatch = dbTitle.contains(searchWhat);

        // Check if any word in the search matches any word in the keywords array
        final searchTerms = searchWhat.split(' ').where((s) => s.isNotEmpty).toList();
        bool keywordMatch = searchTerms.any((term) =>
            dbKeywords.any((k) => k.toString().toLowerCase() == term)
        );

        bool whatMatch = searchWhat.isEmpty || titleMatch || keywordMatch;

        // Only keep the job if BOTH What and Where match
        return whatMatch && locationMatch;
      }).toList();

      if (context.mounted) Navigator.pop(context);

      if (filteredJobs.isEmpty) {
        _showNoResults(rawWhat.isNotEmpty ? rawWhat : rawWhere);
      } else {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobResultsScreen(jobs: filteredJobs),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showError('Search failed: $e');
    }
  }

  // Parse salary range string into min/max numbers
  ({double min, double max})? _parseSalaryRange(String range) {
    if (range == 'RM 0 to RM50k+ Monthly') return null;
    // Example: "RM 2000 - RM4000 Monthly" -> min=2000, max=4000
    final parts = range.replaceAll('RM', '').replaceAll('Monthly', '').split('-');
    if (parts.length != 2) return null;
    final minStr = parts[0].trim();
    final maxStr = parts[1].trim().replaceAll('k+', '000').replaceAll('k', '000');
    final min = double.tryParse(minStr);
    final max = double.tryParse(maxStr);
    if (min == null || max == null) return null;
    return (min: min, max: max);
  }

  void _showNoResults(String keyword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No results'),
        content: Text('No jobs found for “$keyword” with your filters.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI BUILD (same as original, but search now works)
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 12.0),
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.chevron_left, size: 32, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _buildSearchField(controller: _keywordsController, hintText: 'Enter keywords'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _buildSearchField(controller: _locationController, hintText: 'Enter suburb, city, or region'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildFilterRow('All work types',
                          value: _selectedWorkType,
                          options: const ['All work types', 'Full-time', 'Part-time', 'Contract', 'Casual'],
                          onChanged: (v) => setState(() => _selectedWorkType = v)),
                      _buildFilterRow('All remote options',
                          value: _selectedRemoteOption,
                          options: const ['All remote options', 'On-site', 'Remote', 'Hybrid'],
                          onChanged: (v) => setState(() => _selectedRemoteOption = v)),
                      _buildFilterRow('RM 0 to RM50k+ Monthly',
                          value: _selectedSalaryRange,
                          options: const [
                            'RM 0 - RM2000 Monthly',
                            'RM 2000 - RM4000 Monthly',
                            'RM 4000 - RM6000 Monthly',
                            'RM 6000 - RM8000 Monthly',
                            'RM 8000 - RM10000 Monthly',
                            'RM 10000 - RM15000 Monthly',
                            'RM 15000 - RM20000 Monthly',
                            'RM 20000+ Monthly',
                          ],
                          onChanged: (v) => setState(() => _selectedSalaryRange = v)),
                      _buildFilterRow('Any classification',
                          value: _selectedClassification,
                          options: const [
                            'Any classification',
                            'IT & Software',
                            'Sales & Marketing',
                            'Finance & Accounting',
                            'Healthcare',
                            'Education',
                            'Hospitality',
                            'Retail',
                            'Manufacturing',
                            'Construction',
                            'Creative & Design',
                            'Administration',
                            'Customer Service',
                          ],
                          onChanged: (v) => setState(() => _selectedClassification = v),
                          isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2352D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Search', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 220, child: CustomPaint(painter: BlobPainter())),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({required TextEditingController controller, required String hintText}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B72E8), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterRow(String label,
      {required String value,
        required List<String> options,
        required Function(String) onChanged,
        bool isLast = false}) {
    return Column(
      children: [
        if (label == 'All work types') const Divider(height: 1, thickness: 1, color: Color(0xFFD8D0F5)),
        InkWell(
          onTap: () => _showFilterBottomSheet(label, value, options, onChanged),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                const Icon(Icons.chevron_right, color: Colors.black54, size: 22),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D0F5)),
      ],
    );
  }

  void _showFilterBottomSheet(String title, String currentValue, List<String> options, Function(String) onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take more height if needed
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        String tempSelected = currentValue;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              // Use constraints to prevent the sheet from becoming too tall
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 1. Wrap the list in Expanded + ListView to handle long lists
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = tempSelected == option;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero, // Match your UI design
                              leading: isSelected
                                  ? const Icon(Icons.radio_button_checked, color: Color(0xFF2352D8))
                                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF2352D8) : Colors.black87,
                                ),
                              ),
                              onTap: () => setState(() => tempSelected = option),
                            ),
                            if (option != options.last) const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Button stays at the bottom
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        onChanged(tempSelected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2352D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------------------------------------------------
// Results Screen – displays job cards from search
// ------------------------------------------------------------
class JobResultsScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> jobs;

  const JobResultsScreen({super.key, required this.jobs});

  @override
  State<JobResultsScreen> createState() => _JobResultsScreenState();
}

class _JobResultsScreenState extends State<JobResultsScreen> {
  // Sets to track state locally in results
  Set<String> _appliedJobs = {};
  Set<String> _savedJobs = {};

  @override
  void initState() {
    super.initState();
    // You could fetch the latest saved/applied jobs here if needed
  }

  String _getTimeAgo(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: const Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: widget.jobs.isEmpty
          ? const Center(child: Text('No results found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.jobs.length,
        itemBuilder: (context, index) {
          final doc = widget.jobs[index];
          final data = doc.data() as Map<String, dynamic>;

          // Map Firebase data to Job Model
          final job = Job(
            id: doc.id,
            title: data['title'] ?? 'Untitled',
            companyId: data['companyId'] ?? '',
            company: data['company'] ?? 'Company',
            location: data['location'] ?? '',
            workType: data['workType'] ?? 'Full-time',
            workplace: data['workplace'] ?? 'On-site',
            salary: data['salary'] ?? 'N/A',
            postedTime: '',
            applicants: '${data['applicants'] ?? 0} applied',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );

          // Extract benefits
          final benefits = (data['benefits'] ?? '').toString()
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .take(2)
              .toList();

          return _jobCard(
              context,
              job,
              benefits,
              _appliedJobs.contains(job.id),
              _savedJobs.contains(job.id),
              data
          );
        },
      ),
    );
  }

  Widget _jobCard(BuildContext context, Job job, List<String> benefits, bool hasApplied, bool isSaved, Map<String, dynamic> fullData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B4FD8), // The signature Blue
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _tag(job.workType),
                  const SizedBox(width: 8),
                  _tag(job.workplace),
                  const Spacer(),
                  const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 18),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(job.company[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B4FD8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(job.company, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.payments_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(job.salary, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.white60),
              const SizedBox(width: 4),
              Text(_getTimeAgo(job.createdAt), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsPage(job: job))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}

// ------------------------------------------------------------
// Decorative blob painter (unchanged)
// ------------------------------------------------------------
class BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkBluePaint = Paint()..color = const Color(0xFF2352D8)..style = PaintingStyle.fill;
    final darkBlobPath = Path()
      ..moveTo(size.width * 0.55, size.height)
      ..cubicTo(size.width * 0.55, size.height * 0.6, size.width * 0.7, size.height * 0.3, size.width, size.height * 0.2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(darkBlobPath, darkBluePaint);

    final lightBluePaint = Paint()..color = const Color(0xFF92AEED)..style = PaintingStyle.fill;
    final lightBlobPath = Path()
      ..moveTo(0, size.height)
      ..cubicTo(0, size.height * 0.5, size.width * 0.15, size.height * 0.25, size.width * 0.42, size.height * 0.55)
      ..cubicTo(size.width * 0.55, size.height * 0.7, size.width * 0.5, size.height * 0.9, size.width * 0.4, size.height)
      ..close();
    canvas.drawPath(lightBlobPath, lightBluePaint);

    final paleBluePaint = Paint()..color = const Color(0xFFB8CAEE)..style = PaintingStyle.fill;
    final paleBlobPath = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..cubicTo(size.width * 0.05, size.height * 0.75, size.width * 0.25, size.height * 0.55, size.width * 0.52, size.height * 0.72)
      ..cubicTo(size.width * 0.62, size.height * 0.8, size.width * 0.58, size.height, size.width * 0.4, size.height)
      ..close();
    canvas.drawPath(paleBlobPath, paleBluePaint);

    canvas.drawCircle(Offset(size.width * 0.06, size.height * 0.28), 6, darkBluePaint);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.42), 3.5, darkBluePaint);
    canvas.drawCircle(Offset(size.width * 0.04, size.height * 0.48), 5, darkBluePaint);

    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.88), 14, whitePaint);

    final whiteLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final wavePath = Path()
      ..moveTo(size.width * 0.6, size.height * 0.62)
      ..cubicTo(size.width * 0.65, size.height * 0.5, size.width * 0.72, size.height * 0.55, size.width * 0.75, size.height * 0.45);
    canvas.drawPath(wavePath, whiteLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}