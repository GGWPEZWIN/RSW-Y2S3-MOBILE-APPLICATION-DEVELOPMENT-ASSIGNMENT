// lib/Jobseeker/InterviewPractice/interview_practice_screen.dart
//
// 4 screens in 1 file:
//   Screen 1: InterviewPracticeJobSelectScreen  — job selection (Saved/Applied tabs)
//   Screen 2/3/4: InterviewPracticeSessionScreen — voice → typing → feedback
//
// ✅ NEW: InterviewPracticeSessionScreen accepts savedJobData
//         and generates tailored questions from the job description

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class InterviewQuestion {
  final int number;
  final String question;
  final int timeLimitSeconds;

  const InterviewQuestion({
    required this.number,
    required this.question,
    this.timeLimitSeconds = 120,
  });
}

class _PracticeJobItem {
  final String jobId;
  final String title;
  final String company;
  final String location;
  final String timeLabel;
  final Map<String, dynamic> fullData;

  const _PracticeJobItem({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.timeLabel,
    required this.fullData,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// QUESTION GENERATOR
// Builds tailored questions from the job's description, requirements, title
// ─────────────────────────────────────────────────────────────────────────────

List<InterviewQuestion> _generateQuestionsFromJob(
    Map<String, dynamic> jobData) {
  final title       = jobData['jobTitle']      as String? ?? jobData['title'] as String? ?? 'this role';
  final company     = jobData['company']       as String? ?? 'the company';
  final description = jobData['description']   as String? ?? '';
  final requirements= jobData['requirements']  as String? ?? '';
  final experience  = jobData['experienceLevel'] as String? ?? '';

  // Extract requirement keywords
  final reqLines = requirements
      .split('\n')
      .map((l) => l.replaceAll('•', '').trim())
      .where((l) => l.isNotEmpty)
      .take(3)
      .toList();

  final List<InterviewQuestion> questions = [];
  int n = 1;

  // Q1 — always: challenging project / describe yourself
  questions.add(InterviewQuestion(
    number: n++,
    question:
    'Can you describe a challenging project you worked on and how you managed to complete it successfully?',
  ));

  // Q2 — role specific
  questions.add(InterviewQuestion(
    number: n++,
    question:
    'Why are you interested in the $title position at $company, and what makes you a strong fit for this role?',
  ));

  // Q3 — from requirements if available
  if (reqLines.isNotEmpty) {
    questions.add(InterviewQuestion(
      number: n++,
      question:
      'This role requires ${reqLines.first.toLowerCase()}. Can you walk us through your experience in that area?',
    ));
  } else {
    questions.add(InterviewQuestion(
      number: n++,
      question:
      'Tell me about a time you had to quickly learn a new skill or technology. How did you approach it?',
    ));
  }

  // Q4 — experience level based
  if (experience.toLowerCase().contains('senior') ||
      experience.toLowerCase().contains('5+')) {
    questions.add(InterviewQuestion(
      number: n++,
      question:
      'As a senior-level candidate, describe how you have mentored junior team members or led a technical initiative.',
    ));
  } else if (experience.toLowerCase().contains('fresh') ||
      experience.toLowerCase().contains('1')) {
    questions.add(InterviewQuestion(
      number: n++,
      question:
      'As someone earlier in your career, what specific steps are you taking to grow your skills in ${title.toLowerCase()}?',
    ));
  } else {
    questions.add(InterviewQuestion(
      number: n++,
      question:
      'Describe a situation where you had to work under pressure to meet a deadline. How did you handle it?',
    ));
  }

  // Q5 — teamwork / soft skills
  questions.add(InterviewQuestion(
    number: n++,
    question:
    'Tell me about a time you had to work with a difficult team member. How did you handle the situation?',
  ));

  // Q6 — career goals
  questions.add(InterviewQuestion(
    number: n++,
    question:
    'Where do you see yourself in 5 years, and how does this $title role fit into your career plan?',
  ));

  return questions;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — Job Selection
// ─────────────────────────────────────────────────────────────────────────────

class InterviewPracticeJobSelectScreen extends StatefulWidget {
  const InterviewPracticeJobSelectScreen({super.key});

  @override
  State<InterviewPracticeJobSelectScreen> createState() =>
      _InterviewPracticeJobSelectScreenState();
}

class _InterviewPracticeJobSelectScreenState
    extends State<InterviewPracticeJobSelectScreen> {
  int _tabIndex = 0; // 0 = Saved Jobs  |  1 = Applied Jobs

  static const Color _blue = Color(0xFF3B4FD8);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    try { dt = (ts as Timestamp).toDate(); } catch (_) { return ''; }
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0)  return 'Applied ${diff.inDays}d ago';
    if (diff.inHours > 0) return 'Applied ${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Tab toggle
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
                  color: Colors.black),
            ),
          ),

          Expanded(
            child: _tabIndex == 0
                ? _buildSavedList()
                : _buildAppliedList(),
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
            color: active ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : const Color(0xFF6B7280),
                )),
          ),
        ),
      ),
    );
  }

  // ── Saved Jobs tab — from subcollection ──────────────────────────────────
  Widget _buildSavedList() {
    if (_uid == null) return _emptyState('Please log in.');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('savedJobs')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(
              'No saved jobs yet.\nSave a job from the home page first.');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data  = docs[i].data() as Map<String, dynamic>;
            final jobId = docs[i].id;
            final item = _PracticeJobItem(
              jobId:     jobId,
              title:     data['jobTitle'] ?? data['title'] ?? 'Untitled',
              company:   data['company']  ?? '',
              location:  data['location'] ?? '',
              timeLabel: _timeAgo(data['savedAt']),
              fullData:  data,
            );
            return _jobCard(item, isSaved: true);
          },
        );
      },
    );
  }

  // ── Applied Jobs tab — from applications collection ──────────────────────
  Widget _buildAppliedList() {
    if (_uid == null) return _emptyState('Please log in.');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: _uid)
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('No applications yet.');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final item = _PracticeJobItem(
              jobId:    data['jobId']    ?? '',
              title:    data['jobTitle'] ?? 'Untitled',
              company:  data['company']  ?? '',
              location: data['workplace'] ?? data['location'] ?? '',
              timeLabel: _timeAgo(data['appliedAt']),
              fullData: data,
            );
            return _jobCard(item, isSaved: false);
          },
        );
      },
    );
  }

  Widget _jobCard(_PracticeJobItem item, {required bool isSaved}) {
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
                  child: Text(item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      )),
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
            Text(item.company,
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(item.location,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time,
                  size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(item.timeLabel,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
            const SizedBox(height: 14),

            // ✅ Practice Interview → passes fullData for question generation
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterviewPracticeSessionScreen(
                    savedJobData: item.fullData,
                  ),
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

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B7280))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2/3/4 — Interview Session
// ─────────────────────────────────────────────────────────────────────────────

class InterviewPracticeSessionScreen extends StatefulWidget {
  // ✅ Accepts full saved job data to generate tailored questions
  final Map<String, dynamic> savedJobData;

  const InterviewPracticeSessionScreen({
    super.key,
    required this.savedJobData,
  });

  @override
  State<InterviewPracticeSessionScreen> createState() =>
      _InterviewPracticeSessionScreenState();
}

class _InterviewPracticeSessionScreenState
    extends State<InterviewPracticeSessionScreen> {

  static const Color _blue  = Color(0xFF3B4FD8);
  static const Color _green = Color(0xFF0BA87E);
  static const Color _red   = Color(0xFFE53935);

  // ── Session state ─────────────────────────────────────────────────────────
  String _mode = 'voice'; // 'voice' | 'typing' | 'feedback'

  int _currentQuestionIndex = 0;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _feedbackExpanded  = true;
  bool _sampleExpanded    = false;
  bool _endReviewActive   = false;

  // ── Timer ──────────────────────────────────────────────────────────────────
  static const int _totalSeconds = 120;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;

  // ── Questions generated from job data ────────────────────────────────────
  late final List<InterviewQuestion> _questions;

  // Sample feedback / response (in real app: call AI API)
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
      'develop the product listing feature and ensure smooth API communication.';

  @override
  void initState() {
    super.initState();
    // ✅ Generate questions from the saved job data
    _questions = _generateQuestionsFromJob(widget.savedJobData);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  InterviewQuestion get _currentQ => _questions[_currentQuestionIndex];

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) { t.cancel(); return; }
      if (mounted) setState(() => _remainingSeconds--);
    });
  }

  void _stopTimer() { _timer?.cancel(); }

  String get _timerDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} / 2:00';
  }

  void _switchToTyping() { _stopTimer(); setState(() => _mode = 'typing'); }

  void _submitForFeedback() {
    setState(() { _mode = 'feedback'; _endReviewActive = true; });
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
    } else {
      // All questions done
      Navigator.pop(context);
    }
  }

  String get _jobTitle =>
      widget.savedJobData['jobTitle'] as String? ??
          widget.savedJobData['title']    as String? ??
          'this role';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // End & Review button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: GestureDetector(
              onTap: _endReviewActive ? () => Navigator.pop(context) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _endReviewActive
                      ? _red
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

          // Question pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQ.number} of ${_questions.length}',
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

          // Main card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
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

                        // Voice mode
                        if (_mode == 'voice') ...[
                          Text(_timerDisplay,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w300,
                                color: Colors.black54,
                                letterSpacing: 1,
                              )),
                          const SizedBox(height: 16),
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
                            child: const Icon(Icons.mic_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 16),
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

                        // Typing mode
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
                                    color: Color(0xFFAAAAAA),
                                    fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _mode = 'voice';
                                _remainingSeconds = _totalSeconds;
                              });
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

                        // Feedback mode — answer + next button
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
                                    : 'One challenging project I worked on was developing a mobile application for an e-commerce platform as part of a university team project...',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                    borderRadius:
                                    BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _currentQuestionIndex <
                                    _questions.length - 1
                                    ? 'Next Question'
                                    : 'Finish Practice',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Submit for AI feedback button (voice + typing only)
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
                                    borderRadius:
                                    BorderRadius.circular(12)),
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

                        // Feedback accordion
                        _buildAccordion(
                          label: 'Feedback',
                          expanded: _feedbackExpanded,
                          onTap: () => setState(() =>
                          _feedbackExpanded = !_feedbackExpanded),
                          content: _feedbackExpanded &&
                              _mode == 'feedback'
                              ? _sampleFeedback
                              : null,
                        ),
                        const SizedBox(height: 1),

                        // Sample Response accordion
                        _buildAccordion(
                          label: 'Sample Response',
                          expanded: _sampleExpanded,
                          onTap: () => setState(
                                  () => _sampleExpanded = !_sampleExpanded),
                          content:
                          _sampleExpanded && _mode == 'feedback'
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
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      )),
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
                child: Text(content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared AppBar
// ─────────────────────────────────────────────────────────────────────────────
PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    ),
    title: Row(children: [
      const Text('Interview Practice',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black)),
      const SizedBox(width: 8),
      Icon(Icons.chat_bubble_outline_rounded,
          size: 18, color: Colors.grey[600]),
    ]),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: const Color(0xFFEEEEEE)),
    ),
  );
}