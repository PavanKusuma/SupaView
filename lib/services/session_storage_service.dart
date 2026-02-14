import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/speech_analysis_result.dart';

/// Persists interview sessions to local JSON files.
class SessionStorageService {
  static const _fileName = 'supaview_sessions.json';

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<List<InterviewSession>> loadSessions() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) return [];

      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonStr);

      return jsonList.map((sessionJson) {
        final results = (sessionJson['results'] as List<dynamic>)
            .map((r) => _resultFromJson(r))
            .toList();

        return InterviewSession(
          id: sessionJson['id'],
          date: DateTime.parse(sessionJson['date']),
          results: results,
          mode: sessionJson['mode'] ?? 'live',
        );
      }).toList();
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }

  Future<void> saveSession(InterviewSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await _saveSessions(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions(sessions);
  }

  Future<void> _saveSessions(List<InterviewSession> sessions) async {
    final jsonList = sessions.map((session) {
      return {
        'id': session.id,
        'date': session.date.toIso8601String(),
        'mode': session.mode,
        'results': session.results.map((r) => _resultToJson(r)).toList(),
      };
    }).toList();

    final file = File(await _filePath);
    await file.writeAsString(json.encode(jsonList));
  }

  Map<String, dynamic> _resultToJson(SpeechAnalysisResult result) {
    return {
      ...result.toMap(),
      'filler_words': result.fillerWords.map((f) => f.toMap()).toList(),
      'pauses': result.pauses.map((p) => p.toMap()).toList(),
      'strengths': result.strengths,
      'improvements': result.improvements,
    };
  }

  SpeechAnalysisResult _resultFromJson(Map<String, dynamic> json) {
    return SpeechAnalysisResult(
      id: json['id'],
      questionId: json['question_id'],
      questionText: json['question_text'],
      transcript: json['transcript'],
      totalDuration: Duration(milliseconds: json['total_duration_ms']),
      totalWords: json['total_words'],
      wordsPerMinute: (json['words_per_minute'] as num).toDouble(),
      fillerWordCount: json['filler_word_count'],
      fillerWords: (json['filler_words'] as List<dynamic>)
          .map((f) => FillerWordOccurrence.fromMap(f))
          .toList(),
      pauseCount: json['pause_count'],
      pauses: (json['pauses'] as List<dynamic>)
          .map((p) => PauseInfo.fromMap(p))
          .toList(),
      totalPauseDuration:
          Duration(milliseconds: json['total_pause_duration_ms']),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      clarityScore: (json['clarity_score'] as num).toDouble(),
      paceScore: (json['pace_score'] as num).toDouble(),
      overallScore: (json['overall_score'] as num).toDouble(),
      strengths: List<String>.from(json['strengths']),
      improvements: List<String>.from(json['improvements']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
