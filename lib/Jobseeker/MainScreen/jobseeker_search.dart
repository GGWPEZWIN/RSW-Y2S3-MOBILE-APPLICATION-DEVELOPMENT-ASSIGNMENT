import 'package:flutter/material.dart';

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

  // Filter selection states
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 12.0),
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // What section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSearchField(
                        controller: _keywordsController,
                        hintText: 'Enter keywords',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Where section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSearchField(
                        controller: _locationController,
                        hintText: 'Enter suburb, city, or region',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filter options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildFilterRow(
                        'All work types',
                        value: _selectedWorkType,
                        options: const [
                          'All work types',
                          'Full-time',
                          'Part-time',
                          'Contract',
                          'Casual',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedWorkType = value;
                          });
                        },
                      ),
                      _buildFilterRow(
                        'All remote options',
                        value: _selectedRemoteOption,
                        options: const [
                          'All remote options',
                          'On-site',
                          'Remote',
                          'Hybrid',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRemoteOption = value;
                          });
                        },
                      ),
                      _buildFilterRow(
                        'RM 0 to RM50k+ Monthly',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedSalaryRange = value;
                          });
                        },
                      ),
                      _buildFilterRow(
                        'Any classification',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedClassification = value;
                          });
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Search button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2352D8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom decorative blobs
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 220,
              child: CustomPaint(
                painter: BlobPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B72E8),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFilterRow(
      String label, {
        required String value,
        required List<String> options,
        required Function(String) onChanged,
        bool isLast = false,
      }) {
    return Column(
      children: [
        // Top divider (skip for first item — handled by spacing above)
        if (label == 'All work types')
          const Divider(height: 1, thickness: 1, color: Color(0xFFD8D0F5)),

        InkWell(
          onTap: () {
            _showFilterBottomSheet(label, value, options, onChanged);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black54,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D0F5)),
      ],
    );
  }

  void _showFilterBottomSheet(
      String title,
      String currentValue,
      List<String> options,
      Function(String) onChanged,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempSelected = currentValue;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Select $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options list
                  ...options.map((option) {
                    final isSelected = tempSelected == option;
                    return Column(
                      children: [
                        ListTile(
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
                          onTap: () {
                            setState(() {
                              tempSelected = option;
                            });
                          },
                        ),
                        if (option != options.last)
                          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Apply button
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  void _performSearch() {
    final keywords = _keywordsController.text.trim();
    final location = _locationController.text.trim();

    // Build search query
    final searchParams = {
      'keywords': keywords,
      'location': location,
      'workType': _selectedWorkType == 'All work types' ? '' : _selectedWorkType,
      'workplace': _selectedRemoteOption == 'All remote options' ? '' : _selectedRemoteOption,
      'salary': _selectedSalaryRange,
      'classification': _selectedClassification == 'Any classification' ? '' : _selectedClassification,
    };

    // Show search results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search Parameters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchResultRow('Keywords', keywords.isEmpty ? 'All' : keywords),
            _buildSearchResultRow('Location', location.isEmpty ? 'All' : location),
            _buildSearchResultRow('Work Type', _selectedWorkType),
            _buildSearchResultRow('Remote Option', _selectedRemoteOption),
            _buildSearchResultRow('Salary Range', _selectedSalaryRange),
            _buildSearchResultRow('Classification', _selectedClassification),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the decorative blue blob shapes at the bottom of the screen
class BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Large dark blue blob (right side)
    final darkBluePaint = Paint()
      ..color = const Color(0xFF2352D8)
      ..style = PaintingStyle.fill;

    final darkBlobPath = Path();
    darkBlobPath.moveTo(size.width * 0.55, size.height);
    darkBlobPath.cubicTo(
      size.width * 0.55, size.height * 0.6,
      size.width * 0.7, size.height * 0.3,
      size.width, size.height * 0.2,
    );
    darkBlobPath.lineTo(size.width, size.height);
    darkBlobPath.close();
    canvas.drawPath(darkBlobPath, darkBluePaint);

    // Medium light blue blob (bottom center-left)
    final lightBluePaint = Paint()
      ..color = const Color(0xFF92AEED)
      ..style = PaintingStyle.fill;

    final lightBlobPath = Path();
    lightBlobPath.moveTo(0, size.height);
    lightBlobPath.cubicTo(
      0, size.height * 0.5,
      size.width * 0.15, size.height * 0.25,
      size.width * 0.42, size.height * 0.55,
    );
    lightBlobPath.cubicTo(
      size.width * 0.55, size.height * 0.7,
      size.width * 0.5, size.height * 0.9,
      size.width * 0.4, size.height,
    );
    lightBlobPath.close();
    canvas.drawPath(lightBlobPath, lightBluePaint);

    // Lighter/paler blue overlapping blob
    final paleBluePaint = Paint()
      ..color = const Color(0xFFB8CAEE)
      ..style = PaintingStyle.fill;

    final paleBlobPath = Path();
    paleBlobPath.moveTo(size.width * 0.12, size.height);
    paleBlobPath.cubicTo(
      size.width * 0.05, size.height * 0.75,
      size.width * 0.25, size.height * 0.55,
      size.width * 0.52, size.height * 0.72,
    );
    paleBlobPath.cubicTo(
      size.width * 0.62, size.height * 0.8,
      size.width * 0.58, size.height,
      size.width * 0.4, size.height,
    );
    paleBlobPath.close();
    canvas.drawPath(paleBlobPath, paleBluePaint);

    // Small dark blue dot (left, mid-height)
    canvas.drawCircle(
      Offset(size.width * 0.06, size.height * 0.28),
      6,
      darkBluePaint,
    );

    // Tiny dots cluster
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.42),
      3.5,
      darkBluePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 0.48),
      5,
      darkBluePaint,
    );

    // White circle on dark blob (bottom right)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.88),
      14,
      whitePaint,
    );

    // Wavy white line on dark blob
    final whiteLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wavePath = Path();
    wavePath.moveTo(size.width * 0.6, size.height * 0.62);
    wavePath.cubicTo(
      size.width * 0.65, size.height * 0.5,
      size.width * 0.72, size.height * 0.55,
      size.width * 0.75, size.height * 0.45,
    );
    canvas.drawPath(wavePath, whiteLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}