import 'package:uuid/uuid.dart';
import '../models/speech_analysis_result.dart';

class SpeechAnalysisService {
  static const _uuid = Uuid();

  static const List<String> fillerWordsList = [
    'um', 'uh', 'er', 'ah', 'like', 'you know', 'sort of', 'kind of',
    'basically', 'actually', 'literally', 'honestly', 'right', 'okay',
    'so', 'well', 'I mean', 'you see', 'let me think', 'hmm',
  ];

  /// Analyzes the full transcript and timing data to produce a result.
  SpeechAnalysisResult analyze({
    required String transcript,
    required String questionId,
    required String questionText,
    required Duration totalDuration,
    required List<PauseInfo> detectedPauses,
    required List<double> recognitionConfidences,
  }) {
    final words = _extractWords(transcript);
    final totalWords = words.length;

    final durationMinutes = totalDuration.inMilliseconds / 60000.0;
    final wordsPerMinute =
        durationMinutes > 0 ? totalWords / durationMinutes : 0.0;

    final fillerAnalysis = _analyzeFillerWords(transcript, totalWords);
    final fillerWordCount =
        fillerAnalysis.fold<int>(0, (sum, f) => sum + f.count);

    final totalPauseDuration = detectedPauses.fold<Duration>(
      Duration.zero,
      (sum, p) => sum + p.duration,
    );

    final confidenceScore = _calculateConfidenceScore(
      fillerWordCount: fillerWordCount,
      totalWords: totalWords,
      pauseCount: detectedPauses.length,
      totalDuration: totalDuration,
      recognitionConfidences: recognitionConfidences,
    );

    final clarityScore = _calculateClarityScore(
      totalWords: totalWords,
      totalDuration: totalDuration,
      recognitionConfidences: recognitionConfidences,
    );

    final paceScore = _calculatePaceScore(wordsPerMinute);

    final overallScore = _calculateOverallScore(
      confidenceScore: confidenceScore,
      clarityScore: clarityScore,
      paceScore: paceScore,
    );

    final strengths = _identifyStrengths(
      wordsPerMinute: wordsPerMinute,
      fillerWordCount: fillerWordCount,
      totalWords: totalWords,
      pauseCount: detectedPauses.length,
      confidenceScore: confidenceScore,
      totalDuration: totalDuration,
    );

    final improvements = _identifyImprovements(
      wordsPerMinute: wordsPerMinute,
      fillerWordCount: fillerWordCount,
      totalWords: totalWords,
      pauseCount: detectedPauses.length,
      confidenceScore: confidenceScore,
      totalDuration: totalDuration,
    );

    return SpeechAnalysisResult(
      id: _uuid.v4(),
      questionId: questionId,
      questionText: questionText,
      transcript: transcript,
      totalDuration: totalDuration,
      totalWords: totalWords,
      wordsPerMinute: wordsPerMinute,
      fillerWordCount: fillerWordCount,
      fillerWords: fillerAnalysis,
      pauseCount: detectedPauses.length,
      pauses: detectedPauses,
      totalPauseDuration: totalPauseDuration,
      confidenceScore: confidenceScore,
      clarityScore: clarityScore,
      paceScore: paceScore,
      overallScore: overallScore,
      strengths: strengths,
      improvements: improvements,
      createdAt: DateTime.now(),
    );
  }

  List<String> _extractWords(String transcript) {
    return transcript
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<FillerWordOccurrence> _analyzeFillerWords(
    String transcript,
    int totalWords,
  ) {
    final lower = transcript.toLowerCase();
    final results = <FillerWordOccurrence>[];

    for (final filler in fillerWordsList) {
      final pattern = RegExp(r'\b' + RegExp.escape(filler) + r'\b');
      final matches = pattern.allMatches(lower).length;
      if (matches > 0) {
        results.add(FillerWordOccurrence(
          word: filler,
          count: matches,
          percentage: totalWords > 0 ? (matches / totalWords) * 100 : 0,
        ));
      }
    }

    results.sort((a, b) => b.count.compareTo(a.count));
    return results;
  }

  double _calculateConfidenceScore({
    required int fillerWordCount,
    required int totalWords,
    required int pauseCount,
    required Duration totalDuration,
    required List<double> recognitionConfidences,
  }) {
    double score = 100;

    // Penalize for filler words (each filler word = -1.5 points, capped at -30)
    final fillerPenalty = (fillerWordCount * 1.5).clamp(0.0, 30.0);
    score -= fillerPenalty;

    // Penalize for excessive pauses (>5 long pauses = penalty)
    if (pauseCount > 5) {
      score -= ((pauseCount - 5) * 2.0).clamp(0.0, 20.0);
    }

    // Penalize for very short responses (under 30 seconds indicates low confidence)
    if (totalDuration.inSeconds < 30 && totalWords < 50) {
      score -= 15;
    }

    // Bonus for strong recognition confidence
    if (recognitionConfidences.isNotEmpty) {
      final avgConfidence =
          recognitionConfidences.reduce((a, b) => a + b) /
          recognitionConfidences.length;
      if (avgConfidence > 0.8) {
        score += 5;
      } else if (avgConfidence < 0.5) {
        score -= 10;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  double _calculateClarityScore({
    required int totalWords,
    required Duration totalDuration,
    required List<double> recognitionConfidences,
  }) {
    double score = 80;

    // Recognition confidence is a proxy for clarity
    if (recognitionConfidences.isNotEmpty) {
      final avgConfidence =
          recognitionConfidences.reduce((a, b) => a + b) /
          recognitionConfidences.length;
      score = avgConfidence * 100;
    }

    // Good word count for the duration adds points
    final durationMinutes = totalDuration.inMilliseconds / 60000.0;
    if (durationMinutes > 0) {
      final wpm = totalWords / durationMinutes;
      if (wpm >= 100 && wpm <= 160) {
        score += 10;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  double _calculatePaceScore(double wordsPerMinute) {
    // Ideal pace: 120-150 WPM for interviews
    if (wordsPerMinute >= 120 && wordsPerMinute <= 150) return 100;
    if (wordsPerMinute >= 100 && wordsPerMinute < 120) return 85;
    if (wordsPerMinute > 150 && wordsPerMinute <= 170) return 85;
    if (wordsPerMinute >= 80 && wordsPerMinute < 100) return 70;
    if (wordsPerMinute > 170 && wordsPerMinute <= 190) return 70;
    if (wordsPerMinute >= 60 && wordsPerMinute < 80) return 50;
    if (wordsPerMinute > 190) return 50;
    return 30;
  }

  double _calculateOverallScore({
    required double confidenceScore,
    required double clarityScore,
    required double paceScore,
  }) {
    // Weighted average
    return (confidenceScore * 0.4 + clarityScore * 0.35 + paceScore * 0.25);
  }

  List<String> _identifyStrengths({
    required double wordsPerMinute,
    required int fillerWordCount,
    required int totalWords,
    required int pauseCount,
    required double confidenceScore,
    required Duration totalDuration,
  }) {
    final strengths = <String>[];

    if (wordsPerMinute >= 100 && wordsPerMinute <= 160) {
      strengths.add('Good speaking pace - easy to follow');
    }

    if (totalWords > 0 && fillerWordCount / totalWords < 0.02) {
      strengths.add('Minimal use of filler words');
    }

    if (pauseCount <= 3 && totalDuration.inSeconds > 60) {
      strengths.add('Smooth delivery with few interruptions');
    }

    if (confidenceScore >= 80) {
      strengths.add('Strong confident delivery');
    }

    if (totalDuration.inSeconds >= 60 && totalDuration.inSeconds <= 180) {
      strengths.add('Good response length - concise yet thorough');
    }

    if (totalWords >= 100) {
      strengths.add('Detailed response with good content depth');
    }

    if (strengths.isEmpty) {
      strengths.add('Completed the response - keep practicing!');
    }

    return strengths;
  }

  List<String> _identifyImprovements({
    required double wordsPerMinute,
    required int fillerWordCount,
    required int totalWords,
    required int pauseCount,
    required double confidenceScore,
    required Duration totalDuration,
  }) {
    final improvements = <String>[];

    if (wordsPerMinute > 170) {
      improvements.add(
        'Slow down your pace - you\'re speaking at ${wordsPerMinute.round()} WPM. '
        'Aim for 120-150 WPM.',
      );
    } else if (wordsPerMinute < 90 && totalWords > 10) {
      improvements.add(
        'Try to speak a bit faster - ${wordsPerMinute.round()} WPM is below '
        'the ideal range of 120-150 WPM.',
      );
    }

    if (totalWords > 0 && fillerWordCount / totalWords > 0.05) {
      improvements.add(
        'Reduce filler words ($fillerWordCount found). Try pausing briefly '
        'instead of using "um" or "uh".',
      );
    } else if (fillerWordCount > 5) {
      improvements.add(
        'Work on reducing filler words ($fillerWordCount used). '
        'Practice replacing them with brief pauses.',
      );
    }

    if (pauseCount > 8) {
      improvements.add(
        'You had $pauseCount noticeable pauses. Try to organize your thoughts '
        'before speaking to reduce hesitations.',
      );
    }

    if (totalDuration.inSeconds < 30) {
      improvements.add(
        'Your response was quite short. Try to elaborate more with examples '
        'and specific details.',
      );
    } else if (totalDuration.inSeconds > 300) {
      improvements.add(
        'Your response was over 5 minutes. Practice being more concise '
        'while keeping key points.',
      );
    }

    if (totalWords < 50 && totalDuration.inSeconds > 30) {
      improvements.add(
        'Low word count relative to time spent. Try to fill the time with '
        'more substantive content.',
      );
    }

    if (improvements.isEmpty) {
      improvements.add('Great job! Keep practicing to maintain consistency.');
    }

    return improvements;
  }
}
