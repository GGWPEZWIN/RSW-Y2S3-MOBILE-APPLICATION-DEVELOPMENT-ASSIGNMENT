import 'dart:async';
import 'package:flutter/material.dart';

class PracticeJob {
  final String id;
  final String title;
  final String company;
  final String location;
  final String appliedAgo;
  final bool isSaved;

  const PracticeJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.appliedAgo,
    this.isSaved = false,
  });
}

class InterviewQuestion {
  final int number;
  final String question;
  final int timeLimitSeconds; // 2:00 = 120s

  const InterviewQuestion({
    required this.number,
    required this.question,
    this.timeLimitSeconds = 120,
  });
}

class InterviewPracticeJobSelectScreen extends StatefulWidget {
  const InterviewPracticeJobSelectScreen({super.key});

  @override
  State<InterviewPracticeJobSelectScreen> createState() =>
      _InterviewPracticeJobSelectScreenState();
}

class _InterviewPracticeJobSelectScreenState
    extends State<InterviewPracticeJobSelectScreen> {
  int _tabIndex = 0; // 0 = Saved Jobs, 1 = Applied Jobs

  static const Color _blue       = Color(0xFF3B4FD8);
  static const Color _cardBlue1  = Color(0xFF3B4FD8);
  static const Color _cardBlue2  = Color(0xFF2A3BB8);
  static const Color _cardBlue3  = Color(0xFF1E2F9E); // darker variant

  // Sample data
  final List<PracticeJob> _savedJobs = const [
    PracticeJob(
      id: '1',
      title: 'Software Tester',
      company: 'Jabil',
      location: 'Penang, Malaysia',
      appliedAgo: 'Applied 2 days ago',
      isSaved: true,
    ),
    PracticeJob(
      id: '2',
      title: 'Software Engineer',
      company: 'Plexus',
      location: 'Penang, Malaysia',
      appliedAgo: 'Applied 5 days ago',
      isSaved: true,
    ),
  ];

  final List<PracticeJob> _appliedJobs = const [
    PracticeJob(
      id: '3',
      title: 'UI/UX Designer',
      company: 'Grab',
      location: 'Kuala Lumpur, Malaysia',
      appliedAgo: 'Applied 1 day ago',
    ),
    PracticeJob(
      id: '4',
      title: 'Flutter Developer',
      company: 'Sea Group',
      location: 'Penang, Malaysia',
      appliedAgo: 'Applied 3 days ago',
    ),
  ];

  List<PracticeJob> get _currentJobs =>
      _tabIndex == 0 ? _savedJobs : _appliedJobs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // ── Tab Toggle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                _tabBtn('Saved Jobs', 0),
                _tabBtn('Applied Jobs', 1),
              ]),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Select a job',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _currentJobs.length,
              itemBuilder: (_, i) => _buildJobCard(_currentJobs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF3B4FD8) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(PracticeJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B4FD8), Color(0xFF2A3BB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B4FD8).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C842),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_rounded,
                      color: Color(0xFF1A1A2E), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Company
            Text(
              job.company,
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 10),

            // Location
            Row(children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(job.location,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
            const SizedBox(height: 4),

            // Applied time
            Row(children: [
              Icon(Icons.access_time,
                  size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(job.appliedAgo,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
            const SizedBox(height: 14),

            // Practice Interview button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterviewPracticeSessionScreen(job: job),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C842),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Practice Interview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InterviewPracticeSessionScreen extends StatefulWidget {
  final PracticeJob job;

  const InterviewPracticeSessionScreen({super.key, required this.job});

  @override
  State<InterviewPracticeSessionScreen> createState() =>
      _InterviewPracticeSessionScreenState();
}

class _InterviewPracticeSessionScreenState
    extends State<InterviewPracticeSessionScreen>
    with TickerProviderStateMixin {

  static const Color _blue   = Color(0xFF3B4FD8);
  static const Color _yellow = Color(0xFFF5C842);
  static const Color _red    = Color(0xFFE53935);

  // ── Session state ─────────────────────────────────────────────────────────
  // 'voice' | 'typing' | 'feedback'
  String _mode = 'voice';

  int _currentQuestionIndex = 0;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _feedbackExpanded  = true;
  bool _sampleExpanded    = false;
  bool _endReviewActive   = false; // turns red after first answer

  // ── Timer ──────────────────────────────────────────────────────────────────
  static const int _totalSeconds = 120; // 2:00
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _timerRunning = false;

  // ── Sample questions ───────────────────────────────────────────────────────
  final List<InterviewQuestion> _questions = const [
    InterviewQuestion(
      number: 1,
      question:
      'Can you describe a challenging project you worked on and how you managed to complete it successfully?',
    ),
    InterviewQuestion(
      number: 2,
      question:
      'Tell me about a time you had to work with a difficult team member. How did you handle it?',
    ),
    InterviewQuestion(
      number: 3,
      question:
      'Where do you see yourself in 5 years, and how does this role fit into your career plan?',
    ),
  ];

  InterviewQuestion get _currentQ => _questions[_currentQuestionIndex];

  // ── Sample AI feedback ─────────────────────────────────────────────────────
  static const String _sampleFeedback =
      'Your answer provides a clear example of overcoming a technical challenge, '
      'highlighting your research and problem-solving skills, which is a strong point. '
      'However, it would be more impactful if you included specific metrics or feedback '
      'to quantify success, and if you briefly discussed how the project influenced the '
      'overall team or client. Additionally, try to reduce the use of filler words and '
      'maintain a confident, steady tone throughout.';

  static const String _sampleResponse =
      'A challenging project I worked on involved developing a mobile app for an '
      'e-commerce platform as part of a university team. Our goal was to enable users '
      'to browse products, place orders, and manage profiles, but we faced a steep '
      'learning curve with Flutter and backend integration. My specific task was to '
      'develop the product listing feature and ensure smooth API communication. I '
      'researched REST API integration with Flutter, then created a structured plan '
      'with the team to divide responsibilities.';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _timerRunning = false;
        return;
      }
      if (mounted) setState(() => _remainingSeconds--);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  String get _timerDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} / 2:00';
  }

  void _switchToTyping() {
    _stopTimer();
    setState(() => _mode = 'typing');
  }

  void _submitForFeedback() {
    setState(() {
      _mode = 'feedback';
      _endReviewActive = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _mode = 'voice';
        _remainingSeconds = _totalSeconds;
        _answerCtrl.clear();
        _feedbackExpanded = true;
        _sampleExpanded   = false;
      });
      _startTimer();
    }
  }

  void _endAndReview() {
    // Could navigate to a review summary page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Top bar: End & Review button ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: GestureDetector(
              onTap: _endReviewActive ? _endAndReview : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _endReviewActive
                      ? const Color(0xFFE53935)
                      : const Color(0xFFF0F1F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'End & Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _endReviewActive
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Question pill ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQ.number}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Colors.black54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Main card ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Question card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Question text
                        Text(
                          _currentQ.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── VOICE MODE ────────────────────────────────
                        if (_mode == 'voice') ...[
                          Text(
                            _timerDisplay,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mic button
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Or type link
                          GestureDetector(
                            onTap: _switchToTyping,
                            child: const Text(
                              'Or type your answer',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],

                        // ── TYPING MODE ───────────────────────────────
                        if (_mode == 'typing') ...[
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _answerCtrl,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: 'Type your answer',
                                hintStyle: TextStyle(
                                    color: Color(0xFFAAAAAA), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => _mode = 'voice');
                              _startTimer();
                            },
                            child: const Text(
                              'Or record your answer',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],

                        // ── FEEDBACK MODE — answer text ───────────────
                        if (_mode == 'feedback') ...[
                          Container(
                            width: double.infinity,
                            height: 120,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _answerCtrl.text.isNotEmpty
                                    ? _answerCtrl.text
                                    : 'One challenging project I worked on was developing a mobile application for an e-commerce platform as part of a university team project. Situation: Our goal was to build a complete mobile app that allowed users to browse products, place orders, and...',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Next Question button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Next Question',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Submit for AI feedback button ─────────────
                        // Shown in voice + typing mode
                        if (_mode != 'feedback')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Submit for AI feedback',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ── Feedback accordion ────────────────────────
                        _buildAccordion(
                          label: 'Feedback',
                          expanded: _feedbackExpanded,
                          onTap: () => setState(
                                  () => _feedbackExpanded = !_feedbackExpanded),
                          content: _feedbackExpanded && _mode == 'feedback'
                              ? _sampleFeedback
                              : null,
                        ),
                        const SizedBox(height: 1),

                        // ── Sample Response accordion ─────────────────
                        _buildAccordion(
                          label: 'Sample Response',
                          expanded: _sampleExpanded,
                          onTap: () => setState(
                                  () => _sampleExpanded = !_sampleExpanded),
                          content: _sampleExpanded && _mode == 'feedback'
                              ? _sampleResponse
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordion({
    required String label,
    required bool expanded,
    required VoidCallback onTap,
    String? content,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.black54,
                    size: 22,
                  ),
                ],
              ),
            ),
            if (content != null && content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    ),
    title: Row(
      children: [
        const Text(
          'Interview Practice',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chat_bubble_outline_rounded,
            size: 18, color: Colors.grey[600]),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: const Color(0xFFEEEEEE),
      ),
    ),
  );
}