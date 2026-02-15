import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/interview_question.dart';
import '../models/speech_analysis_result.dart';
import '../services/speech_analysis_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/gemini_evaluation_service.dart';
import '../services/session_storage_service.dart';

enum InterviewState {
  idle,
  countdown,
  recording,
  analyzing,
  completed,
}

class InterviewProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final SpeechAnalysisService _analysisService = SpeechAnalysisService();
  final SessionStorageService _storageService = SessionStorageService();

  InterviewState _state = InterviewState.idle;
  InterviewQuestion? _currentQuestion;
  String _transcript = '';
  bool _isListening = false;
  int _countdownValue = 3;
  Duration _elapsed = Duration.zero;
  SpeechAnalysisResult? _lastResult;
  List<SpeechAnalysisResult> _sessionResults = [];
  List<InterviewSession> _history = [];
  bool _historyLoaded = false;

  // Getters
  InterviewState get state => _state;
  InterviewQuestion? get currentQuestion => _currentQuestion;
  String get transcript => _transcript;
  bool get isListening => _isListening;
  int get countdownValue => _countdownValue;
  Duration get elapsed => _elapsed;
  SpeechAnalysisResult? get lastResult => _lastResult;
  List<SpeechAnalysisResult> get sessionResults =>
      List.unmodifiable(_sessionResults);
  List<InterviewSession> get history => List.unmodifiable(_history);
  bool get historyLoaded => _historyLoaded;

  String get elapsedFormatted {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get remainingSeconds =>
      300 - _elapsed.inSeconds; // 5 minutes max

  InterviewProvider() {
    _speechService.onTranscriptUpdate = (transcript) {
      _transcript = transcript;
      notifyListeners();
    };

    _speechService.onListeningStateChange = (listening) {
      _isListening = listening;
      notifyListeners();
    };
  }

  void setQuestion(InterviewQuestion question) {
    _currentQuestion = question;
    _state = InterviewState.idle;
    _transcript = '';
    _lastResult = null;
    notifyListeners();
  }

  Future<void> startCountdown() async {
    _state = InterviewState.countdown;
    _countdownValue = 3;
    notifyListeners();

    for (int i = 3; i > 0; i--) {
      _countdownValue = i;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
    }

    await startRecording();
  }

  Future<void> startRecording() async {
    _state = InterviewState.recording;
    _transcript = '';
    _elapsed = Duration.zero;
    notifyListeners();

    await _speechService.startListening();

    // Timer for elapsed tracking
    _runTimer();
  }

  void _runTimer() async {
    while (_state == InterviewState.recording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_state == InterviewState.recording) {
        _elapsed += const Duration(seconds: 1);
        notifyListeners();

        // Auto-stop at 5 minutes
        if (_elapsed.inSeconds >= 300) {
          await stopRecording();
        }
      }
    }
  }

  Future<void> stopRecording() async {
    if (_state != InterviewState.recording) return;

    _state = InterviewState.analyzing;
    notifyListeners();

    await _speechService.stopListening();

    // Run analysis (now async — includes on-device NLP + optional Gemini AI)
    if (_currentQuestion != null && _transcript.trim().isNotEmpty) {
      _lastResult = await _analysisService.analyze(
        transcript: _transcript,
        questionId: _currentQuestion!.id,
        questionText: _currentQuestion!.question,
        questionCategory: _currentQuestion!.category,
        totalDuration: _elapsed,
        detectedPauses: _speechService.pauses,
        recognitionConfidences: _speechService.confidences,
      );

      _sessionResults.add(_lastResult!);
    }

    _state = InterviewState.completed;
    notifyListeners();
  }

  /// Analyze a transcript from an imported video.
  Future<void> analyzeImportedTranscript({
    required String transcript,
    required InterviewQuestion question,
    required Duration duration,
  }) async {
    _currentQuestion = question;
    _transcript = transcript;
    _elapsed = duration;
    _state = InterviewState.analyzing;
    notifyListeners();

    _lastResult = await _analysisService.analyze(
      transcript: transcript,
      questionId: question.id,
      questionText: question.question,
      questionCategory: question.category,
      totalDuration: duration,
      detectedPauses: [],
      recognitionConfidences: [],
    );

    _sessionResults.add(_lastResult!);
    _state = InterviewState.completed;
    notifyListeners();
  }

  /// Access Gemini service for API key management.
  GeminiEvaluationService get geminiService => _analysisService.geminiService;

  Future<void> saveSession() async {
    if (_sessionResults.isEmpty) return;

    final session = InterviewSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      results: List.from(_sessionResults),
      mode: 'live',
    );

    await _storageService.saveSession(session);
    _history.insert(0, session);
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _history = await _storageService.loadSessions();
    _history.sort((a, b) => b.date.compareTo(a.date));
    _historyLoaded = true;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    await _storageService.deleteSession(sessionId);
    _history.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

  void resetSession() {
    _state = InterviewState.idle;
    _currentQuestion = null;
    _transcript = '';
    _lastResult = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  void startNewSession() {
    _sessionResults.clear();
    resetSession();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
