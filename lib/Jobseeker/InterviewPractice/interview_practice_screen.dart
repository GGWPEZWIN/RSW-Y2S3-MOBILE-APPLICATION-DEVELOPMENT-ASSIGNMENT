// lib/Jobseeker/InterviewPractice/interview_practice_screen.dart

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class InterviewQuestion {
  final int number;
  final String question;
  const InterviewQuestion({required this.number, required this.question});
}

/// Holds the result of one completed question.
class CompletedAnswer {
  final int questionNumber;
  final String question;
  final String answer;
  final String feedback;        // includes ⭐ Score line
  final String sampleResponse;

  const CompletedAnswer({
    required this.questionNumber,
    required this.question,
    required this.answer,
    required this.feedback,
    required this.sampleResponse,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// OPENROUTER HELPER — tries multiple free models, handles rate limits
// ─────────────────────────────────────────────────────────────────────────────

Future<String> _callOpenRouter(String prompt, String apiKey) async {
  const models = [
    'google/gemma-3-12b-it:free',
    'qwen/qwen3-8b:free',
    'mistralai/mistral-7b-instruct:free',
    'deepseek/deepseek-r1-0528:free',
  ];

  for (final model in models) {
    try {
      debugPrint('🟡 Trying model: $model');
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'X-Title': 'JobBuddy Interview Practice',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🟢 Response status: ${response.statusCode} for model: $model');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success with model: $model');
        return data['choices'][0]['message']['content'] as String;
      }

      // Rate limited (429) — wait longer then try next model
      if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limited on model: $model, waiting 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      // 404 / 503 = model offline or unavailable — try next immediately
      if (response.statusCode == 404 || response.statusCode == 503) {
        debugPrint('⚠️ Model $model unavailable (${response.statusCode}), trying next...');
        continue;
      }

      // Other errors
      debugPrint('⚠️ Model $model returned ${response.statusCode}, trying next...');
      continue;

    } on TimeoutException {
      debugPrint('⏰ Timeout on model $model');
      continue;
    } catch (e) {
      debugPrint('❌ Error with model $model: $e');
      continue;
    }
  }

  // All models failed or were rate-limited
  debugPrint('🔥 All models failed!');
  throw Exception('rate_limited');
}

// ─────────────────────────────────────────────────────────────────────────────
// AI QUESTION GENERATOR
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
  } catch (e) {
    debugPrint('❌ Question generation failed: $e');
  }

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
// INTERVIEW SESSION SCREEN
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

  String _mode = 'generating';

  List<InterviewQuestion> _questions = [];

  /// Tracks every question the user has completed (received feedback for).
  final List<CompletedAnswer> _completedAnswers = [];

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
  bool _isEditingTranscript = false;

  static const int _totalSeconds = 120;
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;

  final SpeechToText _speech    = SpeechToText();
  bool _speechAvailable         = false;
  bool _speechInitialising      = false;
  String _currentWords          = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  // ── helpers ────────────────────────────────────────────────────────────────

  /// How many questions have been fully answered (feedback received).
  int get _answeredCount => _completedAnswers.length;

  /// Whether there is a completed-answer entry for the current question index.
  bool get _currentQuestionAnswered =>
      _completedAnswers.any((a) => a.questionNumber == _currentQuestionIndex + 1);

  @override
  void initState() {
    super.initState();
    debugPrint('📱 InterviewPracticeSessionScreen initialized');
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.stop();
    Future.wait([_loadQuestions(), _initSpeech()]);
  }

  @override
  void dispose() {
    debugPrint('🗑️ InterviewPracticeSessionScreen disposed');
    _countdownTimer?.cancel();
    _finalResultTimeout?.cancel();
    _pulseCtrl.dispose();
    _answerCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    debugPrint('📖 Loading questions...');
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ No API key found, using fallback questions');
      final title   = widget.savedJobData['jobTitle'] as String? ?? widget.savedJobData['title'] as String? ?? 'this role';
      final company = widget.savedJobData['company']  as String? ?? 'the company';
      final reqs    = widget.savedJobData['requirements']    as String? ?? '';
      final exp     = widget.savedJobData['experienceLevel'] as String? ?? '';
      final qs = _localFallbackQuestions(title, company, reqs, exp);
      if (mounted) setState(() { _questions = qs; _mode = 'idle'; });
      return;
    }
    try {
      final qs = await _generateQuestionsFromAI(widget.savedJobData, _apiKey);
      debugPrint('✅ Loaded ${qs.length} questions');
      if (mounted) setState(() { _questions = qs; _mode = 'idle'; });
    } catch (e) {
      debugPrint('❌ Failed to load questions: $e');
      final title   = widget.savedJobData['jobTitle'] as String? ?? widget.savedJobData['title'] as String? ?? 'this role';
      final company = widget.savedJobData['company']  as String? ?? 'the company';
      final reqs    = widget.savedJobData['requirements']    as String? ?? '';
      final exp     = widget.savedJobData['experienceLevel'] as String? ?? '';
      final qs = _localFallbackQuestions(title, company, reqs, exp);
      if (mounted) setState(() { _questions = qs; _mode = 'idle'; });
    }
  }

  Future<void> _initSpeech() async {
    if (_speechInitialising) return;
    if (mounted) setState(() => _speechInitialising = true);
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (s) {
          debugPrint('🎤 Speech status: $s');
          if (s == 'notListening' && _mode == 'listening') {
            _stopRecordingAndShowStopped();
          }
        },
        onError: (e) {
          debugPrint('❌ Speech error: $e');
          if (mounted && _mode == 'listening') {
            _stopRecordingAndShowStopped();
            _showSnack('Microphone error — please retry or type your answer');
          }
        },
      );
      debugPrint('🎤 Speech available: $_speechAvailable');
    } catch (e) {
      debugPrint('❌ Speech init error: $e');
      _speechAvailable = false;
    }
    if (mounted) setState(() => _speechInitialising = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    debugPrint('🎤 Speech result: "${result.recognizedWords}" (final: ${result.finalResult})');

    setState(() => _currentWords = result.recognizedWords);

    if (result.finalResult) {
      final existing = _answerCtrl.text;
      final newWords = result.recognizedWords.trim();

      if (newWords.isNotEmpty) {
        final separator = existing.isNotEmpty && !existing.endsWith(' ') ? ' ' : '';
        _answerCtrl.text = '$existing$separator$newWords';
        _answerCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _answerCtrl.text.length));
        debugPrint('📝 Updated answer text: "${_answerCtrl.text}"');
      }

      setState(() {
        _currentWords = '';
        if (_isWaitingForFinal) {
          debugPrint('✅ Final speech result received, stopping waiting');
          _isWaitingForFinal = false;
          _finalResultTimeout?.cancel();
          if (_mode != 'feedback') {
            _mode = 'stopped';
          }
        }
      });
    }
  }

  Future<void> _onMicTap() async {
    debugPrint('🎤 Mic tapped, current mode: $_mode');
    if (_isMicTapLocked || _mode == 'loading' || _mode == 'feedback' ||
        _mode == 'stopped' || _mode == 'generating' || _mode == 'processing_stop' || _mode == 'editing_transcript') {
      debugPrint('🚫 Mic tap blocked - mode: $_mode, locked: $_isMicTapLocked');
      return;
    }
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
      debugPrint('🎤 Starting listening...');
      await _startListening();
    } else if (_mode == 'listening') {
      debugPrint('🎤 Stopping listening...');
      setState(() {
        _mode = 'processing_stop';
      });
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
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 120),
        partialResults: true,
      );
      debugPrint('🎤 Listening started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
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
    debugPrint('🛑 Stopping recording, current mode: $_mode');
    _countdownTimer?.cancel();
    _pulseCtrl.stop();

    if (_mode == 'listening') {
      _isWaitingForFinal = true;
      _speech.stop();
      debugPrint('⏳ Waiting for final speech result...');

      _finalResultTimeout?.cancel();
      _finalResultTimeout = Timer(const Duration(seconds: 5), () {
        if (mounted && _isWaitingForFinal) {
          debugPrint('⏰ Timeout waiting for final speech result');
          _isWaitingForFinal = false;
          setState(() {
            _mode = 'stopped';
            _currentWords = '';
          });
          if (_answerCtrl.text.trim().isEmpty) {
            _showSnack('Nothing transcribed — please retry or type');
          }
        }
      });

      if (_mode != 'processing_stop') {
        setState(() {
          _mode = 'processing_stop';
        });
      }
    } else if (_mode == 'processing_stop') {
      debugPrint('🔄 Already in processing_stop, forcing to stopped');
      setState(() {
        _mode = 'stopped';
        _currentWords = '';
      });
    } else {
      setState(() {
        _mode = 'stopped';
        _currentWords = '';
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_remainingSeconds <= 0) {
        debugPrint('⏰ Countdown finished');
        t.cancel();
        _stopRecordingAndShowStopped();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _retryRecording() {
    debugPrint('🔄 Retry recording');
    _countdownTimer?.cancel();
    _finalResultTimeout?.cancel();
    _isWaitingForFinal = false;
    _answerCtrl.clear();
    _currentWords = '';
    setState(() { _mode = 'idle'; _remainingSeconds = _totalSeconds; });
  }

  void _switchToTyping() {
    debugPrint('⌨️ Switching to typing mode');
    if (_mode == 'loading' || _mode == 'feedback') return;
    if (_mode == 'listening') _stopRecordingAndShowStopped();
    setState(() => _mode = 'typing');
  }

  void _switchToVoice() {
    debugPrint('🎤 Switching to voice mode');
    if (_mode == 'loading' || _mode == 'feedback') return;
    setState(() { _mode = 'idle'; _remainingSeconds = _totalSeconds; });
  }

  void _editTranscript() {
    debugPrint('✏️ Editing transcript');
    setState(() {
      _isEditingTranscript = true;
      _mode = 'editing_transcript';
    });
  }

  void _saveTranscriptEdit() {
    debugPrint('💾 Saving transcript edit');
    setState(() {
      _isEditingTranscript = false;
      _mode = 'stopped';
    });
  }

  void _cancelTranscriptEdit() {
    debugPrint('❌ Cancelling transcript edit');
    setState(() {
      _isEditingTranscript = false;
      _mode = 'stopped';
    });
  }

  Future<void> _showRateLimitDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InterviewDialog(
        icon: Icons.timer_outlined,
        iconColor: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFFFBEB),
        title: 'AI is Busy Right Now',
        body: 'The AI service is currently rate-limited due to high demand. Please wait 30-60 seconds and try again.\n\nTip: You can type your answers instead of using voice to reduce API calls.',
        primaryLabel: 'Try Again',
        primaryColor: const Color(0xFF3B4FD8),
        secondaryLabel: 'Go Back',
        onPrimary: () {
          Navigator.pop(ctx);
          // Retry the submission
          _submitForFeedback();
        },
        onSecondary: () {
          Navigator.pop(ctx);
          setState(() {
            _mode = 'stopped';
            _isSubmitting = false;
          });
        },
      ),
    );
  }

  // FIXED: Improved submit with proper waiting and rate limit handling
  Future<void> _submitForFeedback() async {
    debugPrint('🚀 SUBMIT BUTTON CLICKED - Current mode: $_mode, isSubmitting: $_isSubmitting');

    if (_isSubmitting) {
      debugPrint('⚠️ Already submitting, ignoring click');
      _showSnack('Already submitting, please wait...');
      return;
    }

    // Log current state for debugging
    debugPrint('📊 State before submission - mode: $_mode, waitingForFinal: $_isWaitingForFinal, answer length: ${_answerCtrl.text.length}');

    // If we're in processing_stop, wait for it to complete
    if (_mode == 'processing_stop') {
      debugPrint('⏳ In processing_stop mode, waiting for completion...');
      _showSnack('Processing speech, please wait...');
      int waited = 0;
      while (_mode == 'processing_stop' && waited < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      if (_mode == 'processing_stop') {
        debugPrint('⚠️ processing_stop timeout, forcing to stopped');
        setState(() {
          _mode = 'stopped';
        });
      } else {
        debugPrint('✅ processing_stop completed');
      }
    }

    if (_isWaitingForFinal) {
      debugPrint('⏳ Waiting for final speech result...');
      _showSnack('Waiting for speech recognition...');
      int waited = 0;
      while (_isWaitingForFinal && waited < 40) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      debugPrint('✅ Finished waiting for final result');
    }

    if (_mode == 'listening') {
      debugPrint('🎤 Still in listening mode, stopping recording');
      _stopRecordingAndShowStopped();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Final check - force to stopped if needed
    if (_mode != 'stopped' && _mode != 'typing') {
      debugPrint('⚠️ Mode is $_mode, forcing to stopped');
      setState(() {
        _mode = 'stopped';
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('✅ Ready to submit, mode is now: $_mode');
    _isSubmitting = true;

    final answer = _answerCtrl.text.trim();
    debugPrint('📝 Answer length: ${answer.length} characters');

    if (answer.isEmpty) {
      debugPrint('❌ Answer is empty, cannot submit');
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
    final company  = widget.savedJobData['company']  as String? ?? 'the company';

    debugPrint('🤖 Sending to AI for job: $jobTitle at $company');

    try {
      if (_apiKey.isEmpty) {
        debugPrint('❌ OPENROUTER_API_KEY not set in .env');
        throw Exception('OPENROUTER_API_KEY not set in .env');
      }

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

      debugPrint('📤 Calling OpenRouter API...');
      final text = await _callOpenRouter(prompt, _apiKey);
      debugPrint('📥 Received response from OpenRouter, length: ${text.length}');

      final feedbackMatch = RegExp(r'FEEDBACK:\s*(.*?)(?=SAMPLE_RESPONSE:|$)',  dotAll: true).firstMatch(text);
      final sampleMatch   = RegExp(r'SAMPLE_RESPONSE:\s*(.*?)(?=SCORE:|$)',     dotAll: true).firstMatch(text);
      final scoreMatch    = RegExp(r'SCORE:\s*(.*)',                            dotAll: true).firstMatch(text);

      if (mounted) {
        final score        = scoreMatch?.group(1)?.trim() ?? '';
        final feedbackText = (feedbackMatch?.group(1)?.trim() ?? 'No feedback available.') +
            (score.isNotEmpty ? '\n\n⭐ Score: $score' : '');
        final sampleText   = sampleMatch?.group(1)?.trim() ?? 'No sample response available.';

        debugPrint('✅ Successfully parsed feedback, score: ${score.isNotEmpty ? score : "N/A"}');

        _completedAnswers.removeWhere(
                (a) => a.questionNumber == _currentQuestionIndex + 1);
        _completedAnswers.add(CompletedAnswer(
          questionNumber: _currentQuestionIndex + 1,
          question:       _questions[_currentQuestionIndex].question,
          answer:         answer,
          feedback:       feedbackText,
          sampleResponse: sampleText,
        ));

        setState(() {
          _aiFeedback       = feedbackText;
          _aiSampleResponse = sampleText;
          _mode             = 'feedback';
          _endReviewActive  = true;
          _feedbackExpanded = true;
          _sampleExpanded   = false;
        });
        debugPrint('🎉 Feedback received and displayed');
      }
    } on TimeoutException {
      debugPrint('⏰ TimeoutException - API took too long');
      if (mounted) setState(() {
        _aiFeedback = 'Request timed out. Check internet and try again.';
        _aiSampleResponse = '';
        _mode = 'feedback';
        _endReviewActive = true;
      });
    } catch (e) {
      debugPrint('❌ Exception in submit: $e');
      if (mounted) {
        if (e.toString().contains('rate_limited')) {
          // Show rate limit dialog
          await _showRateLimitDialog();
        } else {
          setState(() {
            _aiFeedback = 'Could not get feedback. Please check your connection and retry.';
            _aiSampleResponse = '';
            _mode = 'stopped';
            _endReviewActive = false;
          });
          _showSnack('Connection error. Please try again.');
        }
      }
    } finally {
      _isSubmitting = false;
      debugPrint('🏁 Submit finished, isSubmitting reset to false');
    }
  }

  void _nextQuestion() {
    debugPrint('➡️ Moving to next question');
    if (_mode == 'loading' || _questions.isEmpty) return;
    _countdownTimer?.cancel();

    final isLast = _currentQuestionIndex >= _questions.length - 1;

    if (isLast) {
      _navigateToReview();
    } else {
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
        _isEditingTranscript = false;
      });
      debugPrint('📋 Now on question ${_currentQuestionIndex + 1} of ${_questions.length}');
    }
  }

  // ── End & Review logic ─────────────────────────────────────────────────────

  Future<void> _endAndReview() async {
    debugPrint('🏁 End & Review clicked');
    if (_mode == 'loading') {
      _showSnack('Please wait for feedback before leaving');
      return;
    }

    final total    = _questions.length;
    final answered = _answeredCount;

    if (answered == 0) {
      await _showNoAnswersDialog();
    } else if (answered < total) {
      await _showPartialProgressDialog(answered, total);
    } else {
      _navigateToReview();
    }
  }

  Future<void> _showNoAnswersDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InterviewDialog(
        icon: Icons.help_outline_rounded,
        iconColor: const Color(0xFF3B4FD8),
        iconBg: const Color(0xFFEEF0FF),
        title: 'End Practice?',
        body: "You haven't answered any questions yet. Are you sure you want to end the practice session?",
        primaryLabel: 'Yes, End Session',
        primaryColor: const Color(0xFFE53935),
        secondaryLabel: 'Continue Practising',
        onPrimary: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _showPartialProgressDialog(int answered, int total) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InterviewDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFFFBEB),
        title: 'Leave Early?',
        body:
        "You've completed $answered of $total questions. Your progress so far will be saved in the review, but unanswered questions will be skipped.",
        primaryLabel: 'View My Progress',
        primaryColor: const Color(0xFF3B4FD8),
        secondaryLabel: 'Keep Going',
        onPrimary: () {
          Navigator.pop(ctx);
          _navigateToReview();
        },
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }

  void _navigateToReview() {
    debugPrint('📊 Navigating to review screen with ${_completedAnswers.length} answers');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewReviewScreen(
          completedAnswers: List.unmodifiable(_completedAnswers),
          totalQuestions:   _questions.length,
          jobData:          widget.savedJobData,
        ),
      ),
    );
  }

  // ── Will-pop ───────────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    debugPrint('🔙 Back button pressed, current mode: $_mode');
    if (_mode == 'loading') { _showSnack('Please wait for feedback before leaving'); return false; }
    if (_mode == 'listening' || _mode == 'stopped' || _mode == 'processing_stop' || _mode == 'editing_transcript') {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Leave Practice?', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Your recorded answer will be lost.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      return confirm ?? false;
    }
    return true;
  }

  void _showSnack(String msg) {
    debugPrint('📢 Snackbar: $msg');
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: _mode == 'generating'
          ? _buildGeneratingScreen()
          : Column(children: [

        // ── End & Review button ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GestureDetector(
            onTap: _mode != 'loading' ? _endAndReview : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, height: 48,
              decoration: BoxDecoration(
                color: _mode == 'loading'
                    ? const Color(0xFFF0F1F7)
                    : _answeredCount > 0
                    ? _red
                    : const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _answeredCount > 0
                          ? 'End & Review (${_answeredCount}/${_questions.length})'
                          : 'End & Review',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _mode == 'loading'
                            ? const Color(0xFF9CA3AF)
                            : _answeredCount > 0
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Question pill ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F1F7),
                borderRadius: BorderRadius.circular(24)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${(_currentQ?.number ?? 1)} of ${_questions.length}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black54),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Main card ────────────────────────────────────────────────
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
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(children: [

                if (_currentQ != null)
                  Text(_currentQ!.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: Colors.black87, height: 1.5)),
                const SizedBox(height: 24),

                // ── VOICE MODES ──────────────────────────────────────
                if (_mode == 'idle' || _mode == 'listening' || _mode == 'stopped' || _mode == 'processing_stop' || _mode == 'editing_transcript') ...[
                  if (_mode != 'idle' && _mode != 'processing_stop' && _mode != 'editing_transcript') ...[
                    Text(_timerDisplay, style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w300,
                        color: _timerColor, letterSpacing: 1)),
                    const SizedBox(height: 12),
                  ],
                  if (_mode == 'idle') ...[
                    Text(
                      _speechInitialising
                          ? 'Setting up microphone...'
                          : _speechAvailable
                          ? 'Tap the mic to start speaking'
                          : 'Microphone unavailable — use typing below',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
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
                            color: _mode == 'listening'
                                ? _red
                                : _mode == 'stopped' || _mode == 'processing_stop' || _mode == 'editing_transcript'
                                ? Colors.grey
                                : _speechAvailable ? _blue : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: (_mode == 'listening' ? _red : _blue).withOpacity(0.4),
                              blurRadius: _mode == 'listening' ? 24 : 12,
                              offset: const Offset(0, 6),
                            )],
                          ),
                          child: _speechInitialising
                              ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Icon(
                            _mode == 'listening'
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white, size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _speechInitialising
                        ? 'Initialising...'
                        : _mode == 'idle'
                        ? (_speechAvailable ? 'Tap mic to start' : 'Not available')
                        : _mode == 'listening'
                        ? 'Recording... tap mic to stop'
                        : _mode == 'processing_stop'
                        ? 'Processing speech...'
                        : _mode == 'editing_transcript'
                        ? 'Editing mode — tap save when done'
                        : 'Recording stopped',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: _mode == 'listening'
                            ? _red
                            : _mode == 'processing_stop'
                            ? _blue
                            : _mode == 'editing_transcript'
                            ? Colors.orange
                            : _mode == 'stopped'
                            ? Colors.grey[600]
                            : Colors.grey[500]),
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
                        Expanded(child: Text(_currentWords,
                            style: TextStyle(
                                fontSize: 12, color: _blue.withOpacity(0.85),
                                fontStyle: FontStyle.italic))),
                      ]),
                    ),

                  // Show processing indicator while waiting for final result
                  if (_mode == 'processing_stop') ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Processing your speech...',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ],

                  // Captured text preview with EDIT capability
                  if (_answerCtrl.text.isNotEmpty && _mode != 'listening' && _mode != 'processing_stop') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _mode == 'editing_transcript'
                            ? Colors.white
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mode == 'editing_transcript'
                              ? _blue
                              : const Color(0xFFE5E7EB),
                          width: _mode == 'editing_transcript' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_mode == 'editing_transcript')
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                '✏️ Edit your answer:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B4FD8),
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _mode == 'editing_transcript'
                                    ? TextField(
                                  controller: _answerCtrl,
                                  maxLines: null,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Edit your answer here...',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAAAAAA),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                )
                                    : SingleChildScrollView(
                                  child: Text(
                                    _answerCtrl.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              if (_mode == 'stopped' && !_isEditingTranscript)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: _editTranscript,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: _blue,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_mode == 'editing_transcript') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _cancelTranscriptEdit,
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _saveTranscriptEdit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (_mode == 'stopped') ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _retryRecording,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            side: BorderSide(color: _blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Retry',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitForFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Get Feedback',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _switchToTyping,
                    child: const Text('Or type your answer',
                        style: TextStyle(
                            fontSize: 13, color: Colors.black54,
                            decoration: TextDecoration.underline)),
                  ),
                ],

                // ── TYPING ───────────────────────────────────────────
                if (_mode == 'typing') ...[
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    child: const Text('Or record your answer',
                        style: TextStyle(
                            fontSize: 13, color: Colors.black54,
                            decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _answerCtrl,
                    builder: (_, value, __) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: value.text.trim().isNotEmpty
                            ? _submitForFeedback : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit for Feedback',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],

                // ── LOADING ──────────────────────────────────────────
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

                // ── FEEDBACK ─────────────────────────────────────────
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
                        _answerCtrl.text.isNotEmpty
                            ? _answerCtrl.text : 'Answer given verbally.',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87, height: 1.5),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next Question' : 'View Full Review',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                _accordion(
                  label: 'Feedback',
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFF5C842),
                  expanded: _feedbackExpanded,
                  onTap: () => setState(() => _feedbackExpanded = !_feedbackExpanded),
                  content: _feedbackExpanded && _mode == 'feedback' ? _aiFeedback : null,
                ),
                _accordion(
                  label: 'Sample Response',
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: _green,
                  expanded: _sampleExpanded,
                  onTap: () => setState(() => _sampleExpanded = !_sampleExpanded),
                  content: _sampleExpanded && _mode == 'feedback' ? _aiSampleResponse : null,
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );

  Widget _buildGeneratingScreen() {
    final title   = widget.savedJobData['jobTitle'] as String? ??
        widget.savedJobData['title']   as String? ?? 'this role';
    final company = widget.savedJobData['company']  as String? ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 40, color: Color(0xFF3B4FD8)),
          ),
          const SizedBox(height: 24),
          const Text('Preparing your interview',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(
            'Generating personalised questions\nfor the $title role'
                '${company.isNotEmpty ? ' at $company' : ''}...',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
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
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                    ]),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.black54, size: 22,
                    ),
                  ]),
            ),
            if (content != null && content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(content,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.6)),
              ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE DIALOG WIDGET (Figma-style)
// ─────────────────────────────────────────────────────────────────────────────

class _InterviewDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String primaryLabel;
  final Color primaryColor;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _InterviewDialog({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryColor,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  primaryLabel,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  secondaryLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW SCREEN (kept as is)
// ─────────────────────────────────────────────────────────────────────────────

class InterviewReviewScreen extends StatefulWidget {
  final List<CompletedAnswer> completedAnswers;
  final int totalQuestions;
  final Map<String, dynamic> jobData;

  const InterviewReviewScreen({
    super.key,
    required this.completedAnswers,
    required this.totalQuestions,
    required this.jobData,
  });

  @override
  State<InterviewReviewScreen> createState() => _InterviewReviewScreenState();
}

class _InterviewReviewScreenState extends State<InterviewReviewScreen> {
  static const Color _blue  = Color(0xFF3B4FD8);
  static const Color _green = Color(0xFF0BA87E);
  static const Color _amber = Color(0xFFF59E0B);

  late final List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(widget.completedAnswers.length, false);
  }

  String get _jobTitle =>
      widget.jobData['jobTitle'] as String? ??
          widget.jobData['title'] as String? ?? 'Interview';

  String get _company => widget.jobData['company'] as String? ?? '';

  String _extractScore(String feedback) {
    final match = RegExp(r'(\d+/10)').firstMatch(feedback);
    return match?.group(1) ?? '—';
  }

  int _scoreInt(String score) {
    final match = RegExp(r'^(\d+)').firstMatch(score);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  Color _scoreColor(int s) {
    if (s >= 8) return _green;
    if (s >= 5) return _amber;
    return const Color(0xFFE53935);
  }

  double get _averageScore {
    if (widget.completedAnswers.isEmpty) return 0;
    final scores = widget.completedAnswers
        .map((a) => _scoreInt(_extractScore(a.feedback)))
        .where((s) => s > 0);
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String get _overallBadge {
    final avg = _averageScore;
    if (avg >= 8) return 'Excellent';
    if (avg >= 6) return 'Good';
    if (avg >= 4) return 'Fair';
    return 'Needs Work';
  }

  Color get _overallBadgeColor {
    final avg = _averageScore;
    if (avg >= 8) return _green;
    if (avg >= 6) return _blue;
    if (avg >= 4) return _amber;
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final answered  = widget.completedAnswers.length;
    final total     = widget.totalQuestions;
    final skipped   = total - answered;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: const Text('Practice Review',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _overallBadgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_overallBadge,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: _overallBadgeColor)),
              ),
              const SizedBox(height: 14),
              Text(_jobTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              if (_company.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_company,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
              const SizedBox(height: 20),
              Row(children: [
                _statBox(
                  label: 'Answered',
                  value: '$answered/$total',
                  color: _blue,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: 12),
                _statBox(
                  label: 'Avg Score',
                  value: _averageScore > 0
                      ? '${_averageScore.toStringAsFixed(1)}/10' : '—',
                  color: _scoreColor(_averageScore.round()),
                  icon: Icons.star_outline_rounded,
                ),
                const SizedBox(width: 12),
                _statBox(
                  label: 'Skipped',
                  value: '$skipped',
                  color: skipped == 0 ? _green : _amber,
                  icon: Icons.skip_next_rounded,
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          if (answered > 0) ...[
            const Text('Question Breakdown',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 12),

            ...widget.completedAnswers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ca  = entry.value;
              final score    = _extractScore(ca.feedback);
              final scoreInt = _scoreInt(score);
              final expanded = _expanded[idx];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8, offset: const Offset(0, 2),
                    )],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => setState(
                                () => _expanded[idx] = !_expanded[idx]),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('Q${ca.questionNumber}',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: Color(0xFF3B4FD8))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(ca.question,
                                  maxLines: expanded ? 10 : 2,
                                  overflow: expanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: Colors.black87, height: 1.4)),
                            ),
                            const SizedBox(width: 8),
                            if (scoreInt > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _scoreColor(scoreInt).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(score,
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: _scoreColor(scoreInt))),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.black38, size: 20,
                            ),
                          ]),
                        ),
                      ),
                      if (expanded) ...[
                        _divider(),
                        _reviewSection(
                          label: 'Your Answer',
                          icon: Icons.person_outline_rounded,
                          iconColor: _blue,
                          text: ca.answer,
                        ),
                        _divider(),
                        _reviewSection(
                          label: 'Feedback',
                          icon: Icons.star_outline_rounded,
                          iconColor: const Color(0xFFF5C842),
                          text: ca.feedback,
                        ),
                        _divider(),
                        _reviewSection(
                          label: 'Sample Response',
                          icon: Icons.lightbulb_outline_rounded,
                          iconColor: _green,
                          text: ca.sampleResponse,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],

          if (skipped > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$skipped question${skipped > 1 ? 's were' : ' was'} skipped. '
                        'Try another session to practise them.',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF92400E), height: 1.4),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    color: Colors.grey.shade100,
    indent: 16,
    endIndent: 16,
  );

  Widget _reviewSection({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor)),
          ]),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563), height: 1.6)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED APPBAR
// ─────────────────────────────────────────────────────────────────────────────

PreferredSizeWidget _appBar(BuildContext context) => AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Navigator.maybePop(context),
  ),
  title: Row(children: [
    const Text('Interview Practice',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
    const SizedBox(width: 8),
    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[600]),
  ]),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(height: 1, color: const Color(0xFFEEEEEE)),
  ),
);