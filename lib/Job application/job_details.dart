import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Note: Currently this is just the UI representation (still no data yet)
// TODO: Implement state management
class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage>{

  // Data/variables
  int _currentIndex = 0;

  // SVG icons
  final List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/saved.svg',
    'assets/icons/applied.svg',
    'assets/icons/profile.svg',
  ];

  final List<String> _labels = ['Home', 'Saved', 'Applied', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          "Job Details",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,

        // sharing
        actions: const [
          Icon(Icons.share, color: Colors.black),
          SizedBox(width: 16)
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Company Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.work, size: 40),
                ),
              ),

              const SizedBox(height: 16),

              // Job Title
              const Center(
                child: Text(
                  "Senior Product Designer",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Company + Location
              const Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "JobBuddy Inc.",
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: "  •  Penang, George Town",
                        style: TextStyle(
                            color: Color(0xFF64748B)
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoCard("SALARY", "RM 5000 - RM 8500"),
                  _infoCard("JOB TYPE", "Full-time"),
                  _infoCard("EXPERIENCE", "Senior (5+ yr)"),
                ],
              ),

              const SizedBox(height: 24),

              // Section Title
              const Text(
                "Job Description",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),


              // TODO: job description data
              const Text(
                "NeuralStream is building the next "
                    "generation of creative tools powered by "
                    "generative AI. We're looking for a Senior "
                    "Designer to lead our Core Interface team, "
                    "focusing on making complex AI workflows "
                    "feel natural and intuitive for millions of "
                    "creators worldwide.",
                style: TextStyle(color: Color(0xFF475569)),
              ),

              const SizedBox(height: 20),

              // Responsibilities
              const Text(
                "Responsibilities",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // TODO: The job responsibilities need to render with for loop (depending on how many the employer added)
              _bullet("Design end-to-end user journeys for new AI-powered editing features."),
              _bullet("Collaborate with ML engineers to define interaction patterns for LLM outputs."),
              _bullet("Establish and maintain a scalable design system for our desktop and mobile apps."),

              const SizedBox(height: 20),

              // Requirements
              const Text(
                "Requirements",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // TODO: The requirements need to render with for loop (depending on how many the employer added)
              _dot("5+ years of experience in product design, preferably in SaaS or creative tools."),
              _dot("Strong portfolio demonstrating high-fidelity UI work and complex UX problem solving."),
              _dot("Experience working with generative AI interfaces is a huge plus."),

              const SizedBox(height: 20),

              // TODO: need to implement the map logic listed in the figma
              // Map Placeholder
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[300],
                ),
                child: const Center(child: Text("Map Placeholder")),
              ),

              const SizedBox(height: 20),

              //TODO: button logic
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: const Color(0xFFffffff),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: const Color(0xFFffffff),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      ),
                      child: const Text("Apply Now"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // TODO: some adjustment need to be done with the navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final isActive = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      _icons[index],
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Info Card (reusable component)
  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFA790CC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            Text(value, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF2563EB),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Color(0xFF475569)))),
        ],
      ),
    );
  }

  // Dot bullet (reusable component)
  Widget _dot(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFF94A3B8))),
          Expanded(child: Text(text, style: TextStyle(color: Color(0xFF475569)))),
        ],
      ),
    );
  }
}

