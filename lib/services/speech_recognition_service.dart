import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/speech_analysis_result.dart';

/// Wraps the speech_to_text plugin and tracks pauses + confidence.
class SpeechRecognitionService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  String _currentTranscript = '';
  final List<String> _transcriptSegments = [];
  final List<double> _confidences = [];
  final List<PauseInfo> _pauses = [];

  DateTime? _lastSpeechTime;
  DateTime? _sessionStartTime;
  Timer? _pauseDetectionTimer;

  // Callbacks
  void Function(String transcript)? onTranscriptUpdate;
  void Function(bool isListening)? onListeningStateChange;
  void Function(PauseInfo pause)? onPauseDetected;

  static const _pauseThreshold = Duration(seconds: 2);
  static const _pauseCheckInterval = Duration(milliseconds: 500);

  bool get isListening => _isListening;
  String get currentTranscript => _currentTranscript;
  List<double> get confidences => List.unmodifiable(_confidences);
  List<PauseInfo> get pauses => List.unmodifiable(_pauses);

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: ${error.errorMsg}');
        if (error.permanent) {
          _isListening = false;
          onListeningStateChange?.call(false);
        }
      },
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          // Auto-restart listening if session is still active
          _restartListening();
        }
      },
    );

    return _isInitialized;
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      final ready = await initialize();
      if (!ready) return;
    }

    _currentTranscript = '';
    _transcriptSegments.clear();
    _confidences.clear();
    _pauses.clear();
    _lastSpeechTime = DateTime.now();
    _sessionStartTime = DateTime.now();
    _isListening = true;

    onListeningStateChange?.call(true);
    _startPauseDetection();
    await _beginListening();
  }

  Future<void> _beginListening() async {
    await _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(minutes: 6),
      pauseFor: const Duration(seconds: 30),
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    _lastSpeechTime = DateTime.now();

    if (result.finalResult) {
      _transcriptSegments.add(result.recognizedWords);
      _currentTranscript = _transcriptSegments.join(' ');

      if (result.hasConfidenceRating) {
        _confidences.add(result.confidence);
      }
    } else {
      // Show partial results in real-time
      final partial = _transcriptSegments.join(' ');
      _currentTranscript = partial.isEmpty
          ? result.recognizedWords
          : '$partial ${result.recognizedWords}';
    }

    onTranscriptUpdate?.call(_currentTranscript);
  }

  void _startPauseDetection() {
    _pauseDetectionTimer?.cancel();
    _pauseDetectionTimer = Timer.periodic(_pauseCheckInterval, (_) {
      if (!_isListening || _lastSpeechTime == null || _sessionStartTime == null) {
        return;
      }

      final silenceDuration = DateTime.now().difference(_lastSpeechTime!);
      if (silenceDuration >= _pauseThreshold) {
        final elapsed = _lastSpeechTime!.difference(_sessionStartTime!);
        final pause = PauseInfo(
          timestamp: elapsed,
          duration: silenceDuration,
        );

        // Only add if this is a new pause (not the same ongoing one)
        if (_pauses.isEmpty ||
            _pauses.last.timestamp != pause.timestamp) {
          _pauses.add(pause);
          onPauseDetected?.call(pause);
        }
      }
    });
  }

  Future<void> _restartListening() async {
    if (!_isListening) return;

    // Small delay before restarting
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isListening) {
      await _beginListening();
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _pauseDetectionTimer?.cancel();
    await _speech.stop();
    onListeningStateChange?.call(false);
  }

  Duration get sessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  void dispose() {
    _pauseDetectionTimer?.cancel();
    _speech.stop();
    _speech.cancel();
  }
}
