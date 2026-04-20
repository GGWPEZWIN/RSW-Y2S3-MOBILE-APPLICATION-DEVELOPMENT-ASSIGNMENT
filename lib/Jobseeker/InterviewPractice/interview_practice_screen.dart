// lib/Jobseeker/InterviewPractice/interview_practice_screen.dart
//
// ✅ AI-GENERATED questions — OpenRouter generates 6 personalised questions
//    based on job title, company, requirements, experience level
// ✅ AI feedback via OpenRouter free model after each answer
// ✅ Real speech-to-text via speech_to_text package

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class InterviewQuestion {
  final int number;
  final String question;
  const InterviewQuestion({required this.number, required this.question});
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
// OPENROUTER HELPER — single reusable call
// ─────────────────────────────────────────────────────────────────────────────

Future<String> _callOpenRouter(String prompt, String apiKey) async {
  final response = await http.post(
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'JobBuddy Interview Practice',
    },
    body: jsonEncode({
      'model': 'openrouter/free',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.8,
      'max_tokens': 1000,
    }),
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) {
    throw Exception('OpenRouter error ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  return data['choices'][0]['message']['content'] as String;
}

// ─────────────────────────────────────────────────────────────────────────────
// AI QUESTION GENERATOR — calls OpenRouter to generate 6 personalised Qs
// ─────────────────────────────────────────────────────────────────────────────

Future<List<InterviewQuestion>> _generateQuestionsFromAI(
    Map<String, dynamic> jobData, String apiKey) async {
  final title        = jobData['jobTitle']        as String? ?? jobData['title'] as String? ?? 'this role';
  final company      = jobData['company']         as String? ?? 'the company';
  final description  = jobData['description']     as String? ?? '';
  final requirements = jobData['requirements']    as String? ?? '';
  final experience   = jobData['experienceLevel'] as String? ?? '';
  final industry     = jobData['industry']        as String? ?? '';

  final prompt = '''
You are a professional interview coach preparing a candidate for a real job interview.

Job Details:
- Position: $title
- Company: $company
- Experience Level: $experience
- Industry: $industry
- Job Description: ${description.isNotEmpty ? description.substring(0, description.length.clamp(0, 400)) : 'Not provided'}
- Key Requirements: ${requirements.isNotEmpty ? requirements.substring(0, requirements.length.clamp(0, 300)) : 'Not provided'}

Generate exactly 6 interview questions that a real hiring manager at $company would ask for this $title role.

Rules:
1. Make each question SPECIFIC to this role and company — mention "$title" or "$company" naturally in at least 2 questions
2. Cover a mix of: technical skills, behavioural (STAR), situational, motivation, and career goals
3. Vary the difficulty — 2 easy, 2 medium, 2 challenging
4. Do NOT use generic questions like "tell me about yourself" or "what is your greatest weakness"
5. Each question must be a single sentence ending with "?"

Respond with ONLY a numbered list — no intro text, no explanations:
1. [question]
2. [question]
3. [question]
4. [question]
5. [question]
6. [question]
''';

  try {
    final text = await _callOpenRouter(prompt, apiKey);
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => RegExp(r'^\d+[\.\)]').hasMatch(l))
        .map((l) => l.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim())
        .where((l) => l.isNotEmpty && l.endsWith('?'))
        .take(6)
        .toList();

    if (lines.length >= 4) {
      return lines.asMap().entries
          .map((e) => InterviewQuestion(number: e.key + 1, question: e.value))
          .toList();
    }
  } catch (_) {
    // Fall through to local fallback
  }

  // ── Fallback: smarter local questions using job data ────────────────────
  return _localFallbackQuestions(title, company, requirements, experience);
}

List<InterviewQuestion> _localFallbackQuestions(
    String title, String company, String requirements, String experience) {
  final reqLines = requirements
      .split('\n')
      .map((l) => l.replaceAll('•', '').trim())
      .where((l) => l.isNotEmpty)
      .take(2)
      .toList();

  final List<String> questions = [
    'What specifically drew you to apply for the $title role at $company, and how does it align with your career goals?',
    reqLines.isNotEmpty
        ? 'The $title role at $company requires ${reqLines.first.toLowerCase()} — can you walk us through a specific project where you demonstrated this?'
        : 'Can you walk us through the most technically challenging aspect of a project you have worked on as a $title?',
    'Describe a time you had to deliver results under a tight deadline in a $title-type role. What was your approach and what was the outcome?',
    experience.toLowerCase().contains('senior')
        ? 'As a senior $title, how have you influenced technical direction or mentored others in your team?'
        : 'How are you currently developing your skills to grow into a stronger $title candidate at a company like $company?',
    'Tell me about a situation where you disagreed with a team member or manager on a technical decision. How did you handle it?',
    'Where do you see yourself in 3 years, and how does joining $company as a $title fit into that vision?',
  ];

  return questions.asMap().entries
      .map((e) => InterviewQuestion(number: e.key + 1, question: e.value))
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — Job Selection (Saved / Applied tabs)
// ─────────────────────────────────────────────────────────────────────────────

class InterviewPracticeJobSelectScreen extends StatefulWidget {
  const InterviewPracticeJobSelectScreen({super.key});

  @override
  State<InterviewPracticeJobSelectScreen> createState() =>
      _InterviewPracticeJobSelectScreenState();
}

class _InterviewPracticeJobSelectScreenState
    extends State<InterviewPracticeJobSelectScreen> {

  int _tabIndex = 0;
  static const Color _blue = Color(0xFF3B4FD8);
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _ago(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    try { dt = (ts as Timestamp).toDate(); } catch (_) { return ''; }
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0)  return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _appBar(context),
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFF0F1F7),
              borderRadius: BorderRadius.circular(20)),
          child: Row(children: [_tab('Saved Jobs', 0), _tab('Applied Jobs', 1)]),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Text('Select a job',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      ),
      Expanded(child: _tabIndex == 0 ? _savedList() : _appliedList()),
    ]),
  );

  Widget _tab(String label, int i) {
    final active = _tabIndex == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36, margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: active ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B7280),
          ))),
        ),
      ),
    );
  }

  Widget _savedList() {
    if (_uid == null) return _empty('Please log in.');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(_uid).collection('savedJobs')
          .orderBy('savedAt', descending: true).snapshots(),
      builder: (_, s) {
        if (s.hasError) return _empty('Failed to load saved jobs.\nPlease try again.');
        if (!s.hasData) return const Center(child: CircularProgressIndicator(color: _blue));
        if (s.data!.docs.isEmpty) return _empty('No saved jobs yet.\nSave a job from the home page first.');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: s.data!.docs.length,
          itemBuilder: (_, i) {
            final d = s.data!.docs[i].data() as Map<String, dynamic>;
            return _card(_PracticeJobItem(
              jobId: s.data!.docs[i].id,
              title: d['jobTitle'] ?? d['title'] ?? 'Untitled',
              company: d['company'] ?? '',
              location: d['location'] ?? '',
              timeLabel: 'Saved ${_ago(d['savedAt'])}',
              fullData: d,
            ));
          },
        );
      },
    );
  }

  Widget _appliedList() {
    if (_uid == null) return _empty('Please log in.');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications').where('userId', isEqualTo: _uid)
          .orderBy('appliedAt', descending: true).snapshots(),
      builder: (_, s) {
        if (s.hasError) return _empty('Failed to load applications.\nPlease try again.');
        if (!s.hasData) return const Center(child: CircularProgressIndicator(color: _blue));
        if (s.data!.docs.isEmpty) return _empty('No applications yet.');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: s.data!.docs.length,
          itemBuilder: (_, i) {
            final d = s.data!.docs[i].data() as Map<String, dynamic>;
            return _card(_PracticeJobItem(
              jobId: d['jobId'] ?? '',
              title: d['jobTitle'] ?? 'Untitled',
              company: d['company'] ?? '',
              location: d['workplace'] ?? d['location'] ?? '',
              timeLabel: 'Applied ${_ago(d['appliedAt'])}',
              fullData: d,
            ));
          },
        );
      },
    );
  }

  Widget _card(_PracticeJobItem item) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF3B4FD8), Color(0xFF2A3BB8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: const Color(0xFF3B4FD8).withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(item.title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -0.3))),
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: const Color(0xFFF5C842),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bookmark_rounded, color: Color(0xFF1A1A2E), size: 18)),
        ]),
        const SizedBox(height: 4),
        Text(item.company,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 8),
        if (item.location.isNotEmpty) Row(children: [
          Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(item.location,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.access_time, size: 13, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(item.timeLabel,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => InterviewPracticeSessionScreen(savedJobData: item.fullData))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFFF5C842),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Practice Interview',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ),
        ),
      ]),
    ),
  );

  Widget _empty(String msg) => Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Text(msg, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)))));
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — Interview Session
// ─────────────────────────────────────────────────────────────────────────────

class InterviewPracticeSessionScreen extends StatefulWidget {
  final Map<String, dynamic> savedJobData;
  const InterviewPracticeSessionScreen({super.key, required this.savedJobData});

  @override
  State<InterviewPracticeSessionScreen> createState() =>
      _InterviewPracticeSessionScreenState();
}

class _InterviewPracticeSessionScreenState
    extends State<InterviewPracticeSessionScreen>
    with SingleTickerProviderStateMixin {

  static const Color _blue  = Color(0xFF3B4FD8);
  static const Color _red   = Color(0xFFE53935);
  static const Color _green = Color(0xFF0BA87E);

  // ── Session state ─────────────────────────────────────────────────────────
  // 'generating' → loading AI questions at start
  // 'idle'       → waiting for mic tap
  // 'listening'  → mic active
  // 'stopped'    → recording stopped, show retry/submit
  // 'typing'     → text input mode
  // 'loading'    → getting AI feedback
  // 'feedback'   → showing AI feedback
  String _mode = 'generating';

  // ── Questions ─────────────────────────────────────────────────────────────
  List<InterviewQuestion> _questions = [];
  String _questionLoadError = '';

  bool _isMicTapLocked    = false;
  bool _isSubmitting      = false;
  bool _isWaitingForFinal = false;
  Timer? _finalResultTimeout;

  int _currentQuestionIndex = 0;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _feedbackExpanded = true;
  bool _sampleExpanded   = false;
  bool _endReviewActive  = false;
  String _aiFeedback       = '';
  String _aiSampleResponse = '';

  // ── Timer ─────────────────────────────────────────────────────────────────
  static const int _totalSeconds = 120;
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;

  // ── Speech ────────────────────────────────────────────────────────────────
  final SpeechToText _speech    = SpeechToText();
  bool _speechAvailable         = false;
  bool _speechInitialising      = false;
  String _currentWords          = '';

  // ── Pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.stop();

    //  Generate personalised questions + init speech in parallel
    Future.wait([_loadQuestions(), _initSpeech()]);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _finalResultTimeout?.cancel();
    _pulseCtrl.dispose();
    _answerCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Load AI-generated questions ───────────────────────────────────────────
  Future<void> _loadQuestions() async {
    if (_apiKey.isEmpty) {
      // No API key — use smart local fallback immediately
      final title = widget.savedJobData['jobTitle'] as String? ??
          widget.savedJobData['title'] as String? ?? 'this role';
      final company = widget.savedJobData['company'] as String? ?? 'the company';
      final reqs = widget.savedJobData['requirements'] as String? ?? '';
      final exp = widget.savedJobData['experienceLevel'] as String? ?? '';
      final questions = _localFallbackQuestions(title, company, reqs, exp);
      if (mounted) setState(() { _questions = questions; _mode = 'idle'; });
      return;
    }

    try {
      final questions = await _generateQuestionsFromAI(widget.savedJobData, _apiKey);
      if (mounted) setState(() { _questions = questions; _mode = 'idle'; });
    } catch (e) {
      // Fallback to local questions if API fails
      final title = widget.savedJobData['jobTitle'] as String? ??
          widget.savedJobData['title'] as String? ?? 'this role';
      final company = widget.savedJobData['company'] as String? ?? 'the company';
      final reqs = widget.savedJobData['requirements'] as String? ?? '';
      final exp = widget.savedJobData['experienceLevel'] as String? ?? '';
      final questions = _localFallbackQuestions(title, company, reqs, exp);
      if (mounted) setState(() { _questions = questions; _mode = 'idle'; });
    }
  }

  // ── Speech init ───────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    if (_speechInitialising) return;
    if (mounted) setState(() => _speechInitialising = true);
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && _mode == 'listening') {
            _stopRecordingAndShowStopped();
          }
        },
        onError: (e) {
          if (mounted && _mode == 'listening') {
            _stopRecordingAndShowStopped();
            _showSnack('Microphone error — please retry or type your answer');
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() => _speechInitialising = false);
  }

  // ── Speech callbacks ──────────────────────────────────────────────────────
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _currentWords = result.recognizedWords);

    if (result.finalResult) {
      final existing = _answerCtrl.text;
      final newWords = result.recognizedWords.trim();
      if (newWords.isNotEmpty) {
        _answerCtrl.text = existing.isNotEmpty && !existing.endsWith(' ')
            ? '$existing $newWords'
            : '$existing$newWords';
        _answerCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _answerCtrl.text.length));
      }
      _currentWords = '';
      if (_isWaitingForFinal) {
        _isWaitingForFinal = false;
        _finalResultTimeout?.cancel();
        if (mounted) setState(() => _mode = 'stopped');
      }
    }
  }

  // ── Mic tap ───────────────────────────────────────────────────────────────
  Future<void> _onMicTap() async {
    if (_isMicTapLocked || _mode == 'loading' || _mode == 'feedback' ||
        _mode == 'stopped' || _mode == 'generating') return;

    if (_speechInitialising) { _showSnack('Setting up microphone...'); return; }
    if (!_speechAvailable && _mode == 'idle') {
      _showSnack('Microphone unavailable — tap "Or type your answer"');
      return;
    }

    setState(() => _isMicTapLocked = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isMicTapLocked = false);
    });

    if (_mode == 'idle') {
      await _startListening();
    } else if (_mode == 'listening') {
      _stopRecordingAndShowStopped();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _mode = 'listening';
      _currentWords = '';
      _remainingSeconds = _totalSeconds;
    });
    _pulseCtrl.repeat(reverse: true);

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
        partialResults: true,
      );
    } catch (_) {
      _pulseCtrl.stop();
      if (mounted) {
        setState(() => _mode = 'typing');
        _showSnack('Could not start microphone — please type your answer');
      }
      return;
    }
    _startCountdown();
  }

  void _stopRecordingAndShowStopped() {
    _countdownTimer?.cancel();
    _pulseCtrl.stop();

    if (_mode == 'listening') {
      if (_currentWords.trim().isNotEmpty) {
        final existing = _answerCtrl.text;
        final newWords = _currentWords.trim();
        _answerCtrl.text = existing.isNotEmpty && !existing.endsWith(' ')
            ? '$existing $newWords'
            : '$existing$newWords';
        _answerCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _answerCtrl.text.length));
        _currentWords = '';
      }

      _isWaitingForFinal = true;
      _speech.stop();

      _finalResultTimeout?.cancel();
      _finalResultTimeout = Timer(const Duration(seconds: 5), () {
        if (mounted && _isWaitingForFinal) {
          _isWaitingForFinal = false;
          setState(() { _mode = 'stopped'; _currentWords = ''; });
          if (_answerCtrl.text.trim().isEmpty) {
            _showSnack('Nothing transcribed — please retry or type');
          }
        }
      });
    } else {
      setState(() { _mode = 'stopped'; _currentWords = ''; });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_remainingSeconds <= 0) { t.cancel(); _stopRecordingAndShowStopped(); return; }
      setState(() => _remainingSeconds--);
    });
  }

  void _retryRecording() {
    _countdownTimer?.cancel();
    _finalResultTimeout?.cancel();
    _isWaitingForFinal = false;
    _answerCtrl.clear();
    _currentWords = '';
    setState(() { _mode = 'idle'; _remainingSeconds = _totalSeconds; });
  }

  void _switchToTyping() {
    if (_mode == 'loading' || _mode == 'feedback') return;
    if (_mode == 'listening') _stopRecordingAndShowStopped();
    setState(() => _mode = 'typing');
  }

  void _switchToVoice() {
    if (_mode == 'loading' || _mode == 'feedback') return;
    setState(() { _mode = 'idle'; _remainingSeconds = _totalSeconds; });
  }

  // ── Submit for AI feedback ────────────────────────────────────────────────
  Future<void> _submitForFeedback() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    if (_isWaitingForFinal) {
      int waited = 0;
      while (_isWaitingForFinal && waited < 40) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
    }
    if (_mode == 'listening') {
      _stopRecordingAndShowStopped();
      await Future.delayed(const Duration(milliseconds: 800));
    }

    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      _isSubmitting = false;
      _showSnack('Please speak or type your answer first');
      if (mounted) setState(() => _mode = _speechAvailable ? 'idle' : 'typing');
      return;
    }

    if (mounted) setState(() {
      _mode = 'loading';
      _aiFeedback = '';
      _aiSampleResponse = '';
      _currentWords = '';
    });

    final jobTitle = widget.savedJobData['jobTitle'] as String? ??
        widget.savedJobData['title'] as String? ?? 'this role';
    final company = widget.savedJobData['company'] as String? ?? 'the company';

    try {
      if (_apiKey.isEmpty) throw Exception('OPENROUTER_API_KEY not set in .env');

      final prompt = '''
You are a professional interview coach. The candidate is applying for "$jobTitle" at "$company".

Interview Question:
"${_questions[_currentQuestionIndex].question}"

Candidate's Answer:
"$answer"

Respond in EXACTLY this format — no extra text:

FEEDBACK: <3-4 sentences of constructive feedback mentioning specific strengths and areas to improve based on the actual answer given.>
SAMPLE_RESPONSE: <A strong 3-4 sentence model answer for this specific question at $company.>
SCORE: <Score like 7/10 with one sentence justification.>
''';

      final text = await _callOpenRouter(prompt, _apiKey);

      final feedbackMatch = RegExp(r'FEEDBACK:\s*(.*?)(?=SAMPLE_RESPONSE:|$)', dotAll: true).firstMatch(text);
      final sampleMatch   = RegExp(r'SAMPLE_RESPONSE:\s*(.*?)(?=SCORE:|$)',    dotAll: true).firstMatch(text);
      final scoreMatch    = RegExp(r'SCORE:\s*(.*)',                           dotAll: true).firstMatch(text);

      if (mounted) {
        final score = scoreMatch?.group(1)?.trim() ?? '';
        setState(() {
          _aiFeedback = (feedbackMatch?.group(1)?.trim() ?? 'No feedback available.') +
              (score.isNotEmpty ? '\n\n⭐ Score: $score' : '');
          _aiSampleResponse = sampleMatch?.group(1)?.trim() ?? 'No sample response available.';
          _mode = 'feedback';
          _endReviewActive = true;
          _feedbackExpanded = true;
          _sampleExpanded = false;
        });
      }
    } on TimeoutException {
      if (mounted) setState(() {
        _aiFeedback = 'Request timed out. Check internet and try again.';
        _aiSampleResponse = '';
        _mode = 'feedback';
        _endReviewActive = true;
      });
    } catch (e) {
      if (mounted) setState(() {
        _aiFeedback = 'Could not get feedback. Error: ${e.toString()}';
        _aiSampleResponse = '';
        _mode = 'feedback';
        _endReviewActive = true;
      });
    } finally {
      _isSubmitting = false;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _nextQuestion() {
    if (_mode == 'loading' || _questions.isEmpty) return;
    _countdownTimer?.cancel();
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _mode = 'idle';
        _remainingSeconds = _totalSeconds;
        _answerCtrl.clear();
        _currentWords = '';
        _aiFeedback = '';
        _aiSampleResponse = '';
        _feedbackExpanded = true;
        _sampleExpanded = false;
        _isSubmitting = false;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _endAndReview() {
    if (_mode == 'loading') { _showSnack('Please wait for feedback before leaving'); return; }
    Navigator.pop(context);
  }

  Future<bool> _onWillPop() async {
    if (_mode == 'loading') { _showSnack('Please wait for feedback before leaving'); return false; }
    if (_mode == 'listening' || _mode == 'stopped') {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Practice?', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Your recorded answer will be lost.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      return confirm ?? false;
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  InterviewQuestion? get _currentQ =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;

  String get _timerDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} / 2:00';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 30) return _red;
    if (_remainingSeconds <= 60) return Colors.orange;
    return Colors.black54;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: _mode == 'generating'
          ? _buildGeneratingScreen()
          : Column(children: [

        // End & Review
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GestureDetector(
            onTap: (_endReviewActive && _mode != 'loading') ? _endAndReview : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, height: 48,
              decoration: BoxDecoration(
                color: (_endReviewActive && _mode != 'loading') ? _red : const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(child: Text('End & Review', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: (_endReviewActive && _mode != 'loading') ? Colors.white : const Color(0xFF9CA3AF),
              ))),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Question pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF0F1F7), borderRadius: BorderRadius.circular(24)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${(_currentQ?.number ?? 1)} of ${_questions.length}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black54),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Main card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(children: [

                // Question text
                if (_currentQ != null)
                  Text(_currentQ!.question, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: Colors.black87, height: 1.5)),
                const SizedBox(height: 24),

                // ── VOICE MODES ─────────────────────────────────────────
                if (_mode == 'idle' || _mode == 'listening' || _mode == 'stopped') ...[
                  if (_mode != 'idle') ...[
                    Text(_timerDisplay, style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w300,
                        color: _timerColor, letterSpacing: 1)),
                    const SizedBox(height: 12),
                  ],
                  if (_mode == 'idle') ...[
                    Text(_speechInitialising ? 'Setting up microphone...'
                        : _speechAvailable ? 'Tap the mic to start speaking'
                        : 'Microphone unavailable — use typing below',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 16),
                  ],

                  // Mic button
                  Opacity(
                    opacity: (_isMicTapLocked || _speechInitialising) ? 0.5 : 1.0,
                    child: GestureDetector(
                      onTap: _onMicTap,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _mode == 'listening' ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: _mode == 'listening' ? _red
                                : _mode == 'stopped' ? Colors.grey
                                : _speechAvailable ? _blue : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: (_mode == 'listening' ? _red : _blue).withOpacity(0.4),
                              blurRadius: _mode == 'listening' ? 24 : 12,
                              offset: const Offset(0, 6),
                            )],
                          ),
                          child: _speechInitialising
                              ? const Padding(padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(_mode == 'listening' ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _speechInitialising   ? 'Initialising...'
                        : _mode == 'idle' ? (_speechAvailable ? 'Tap mic to start' : 'Not available')
                        : _mode == 'listening' ? 'Recording... tap mic to stop'
                        : 'Recording stopped',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: _mode == 'listening' ? _red
                            : _mode == 'stopped' ? Colors.grey[600] : Colors.grey[500]),
                  ),
                  const SizedBox(height: 12),

                  // Live partial transcription
                  if (_mode == 'listening' && _currentWords.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _blue.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.mic_rounded, size: 14, color: _blue.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_currentWords, style: TextStyle(
                            fontSize: 12, color: _blue.withOpacity(0.85),
                            fontStyle: FontStyle.italic))),
                      ]),
                    ),

                  // Captured text preview
                  if (_answerCtrl.text.isNotEmpty && _mode != 'listening') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 100),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(_answerCtrl.text,
                            style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                    ),
                  ],

                  // Retry / Submit buttons (stopped mode)
                  if (_mode == 'stopped') ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _retryRecording,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue, side: BorderSide(color: _blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitForFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Submit for AI Feedback',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _switchToTyping,
                    child: const Text('Or type your answer', style: TextStyle(
                        fontSize: 13, color: Colors.black54,
                        decoration: TextDecoration.underline)),
                  ),
                ],

                // ── TYPING ──────────────────────────────────────────────
                if (_mode == 'typing') ...[
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _answerCtrl,
                      maxLines: null, minLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _switchToVoice,
                    child: const Text('Or record your answer', style: TextStyle(
                        fontSize: 13, color: Colors.black54,
                        decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _answerCtrl,
                    builder: (_, value, __) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: value.text.trim().isNotEmpty ? _submitForFeedback : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue, foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit for Feedback',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],

                // ── LOADING ─────────────────────────────────────────────
                if (_mode == 'loading') ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: _blue),
                  const SizedBox(height: 16),
                  const Text('Analysing your answer...',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('Getting personalised feedback...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  const SizedBox(height: 20),
                ],

                // ── FEEDBACK ────────────────────────────────────────────
                if (_mode == 'feedback') ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _answerCtrl.text.isNotEmpty ? _answerCtrl.text : 'Answer given verbally.',
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue, foregroundColor: Colors.white,
                        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next Question' : 'Finish Practice',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Accordions
                _accordion(label: 'Feedback', icon: Icons.star_outline_rounded,
                    iconColor: const Color(0xFFF5C842),
                    expanded: _feedbackExpanded,
                    onTap: () => setState(() => _feedbackExpanded = !_feedbackExpanded),
                    content: _feedbackExpanded && _mode == 'feedback' ? _aiFeedback : null),

                _accordion(label: 'Sample Response', icon: Icons.lightbulb_outline_rounded,
                    iconColor: _green,
                    expanded: _sampleExpanded,
                    onTap: () => setState(() => _sampleExpanded = !_sampleExpanded),
                    content: _sampleExpanded && _mode == 'feedback' ? _aiSampleResponse : null),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );

  // ── Generating questions loading screen ──────────────────────────────────
  Widget _buildGeneratingScreen() {
    final title = widget.savedJobData['jobTitle'] as String? ??
        widget.savedJobData['title'] as String? ?? 'this role';
    final company = widget.savedJobData['company'] as String? ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 40, color: Color(0xFF3B4FD8)),
          ),
          const SizedBox(height: 24),
          const Text('Preparing your interview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(
            'Generating personalised questions\nfor the $title role${company.isNotEmpty ? ' at $company' : ''}...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Color(0xFF3B4FD8)),
          const SizedBox(height: 16),
          Text('This takes about 5–10 seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ]),
      ),
    );
  }

  Widget _accordion({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool expanded,
    required VoidCallback onTap,
    String? content,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ]),
            Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: Colors.black54, size: 22),
          ]),
        ),
        if (content != null && content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(content,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.6)),
          ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared AppBar
// ─────────────────────────────────────────────────────────────────────────────
PreferredSizeWidget _appBar(BuildContext context) => AppBar(
  backgroundColor: Colors.white, elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Navigator.maybePop(context),
  ),
  title: Row(children: [
    const Text('Interview Practice',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
    const SizedBox(width: 8),
    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[600]),
  ]),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(height: 1, color: const Color(0xFFEEEEEE)),
  ),
);