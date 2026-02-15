import 'package:uuid/uuid.dart';
import '../models/speech_analysis_result.dart';
import 'text_analysis_service.dart';
import 'gemini_evaluation_service.dart';

class SpeechAnalysisService {
  static const _uuid = Uuid();
  final TextAnalysisService _textAnalysis = TextAnalysisService();
  final GeminiEvaluationService _geminiService = GeminiEvaluationService();

  GeminiEvaluationService get geminiService => _geminiService;

  static const List<String> fillerWordsList = [
    'um', 'uh', 'er', 'ah', 'like', 'you know', 'sort of', 'kind of',
    'basically', 'actually', 'literally', 'honestly', 'right', 'okay',
    'so', 'well', 'I mean', 'you see', 'let me think', 'hmm',
  ];

  /// Analyzes the full transcript and timing data to produce a result.
  /// Runs on-device NLP analysis (free) and optionally Gemini AI evaluation.
  Future<SpeechAnalysisResult> analyze({
    required String transcript,
    required String questionId,
    required String questionText,
    required String questionCategory,
    required Duration totalDuration,
    required List<PauseInfo> detectedPauses,
    required List<double> recognitionConfidences,
  }) async {
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

    // ── On-device NLP analysis (100% free) ──
    final textMetrics = _textAnalysis.analyze(
      transcript: transcript,
      question: questionText,
    );

    // ── Delivery scores ──
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

    // ── Gemini AI evaluation (free tier, optional) ──
    GeminiEvaluation? aiEval;
    if (transcript.trim().length > 20) {
      aiEval = await _geminiService.evaluate(
        transcript: transcript,
        question: questionText,
        category: questionCategory,
        wordsPerMinute: wordsPerMinute,
        fillerWordCount: fillerWordCount,
        pauseCount: detectedPauses.length,
      );
    }

    // ── Combined overall score ──
    final overallScore = _calculateOverallScore(
      confidenceScore: confidenceScore,
      clarityScore: clarityScore,
      paceScore: paceScore,
      contentQualityScore: textMetrics.contentQualityScore,
      aiOverallScore: aiEval?.overallScore,
    );

    // ── Merge strengths & improvements from all sources ──
    final strengths = _identifyStrengths(
      wordsPerMinute: wordsPerMinute,
      fillerWordCount: fillerWordCount,
      totalWords: totalWords,
      pauseCount: detectedPauses.length,
      confidenceScore: confidenceScore,
      totalDuration: totalDuration,
      textMetrics: textMetrics,
    );

    final improvements = _identifyImprovements(
      wordsPerMinute: wordsPerMinute,
      fillerWordCount: fillerWordCount,
      totalWords: totalWords,
      pauseCount: detectedPauses.length,
      confidenceScore: confidenceScore,
      totalDuration: totalDuration,
      textMetrics: textMetrics,
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
      // Enhanced NLP metrics
      contentQualityScore: textMetrics.contentQualityScore,
      vocabularyDiversityScore: textMetrics.vocabularyDiversityScore,
      readabilityScore: textMetrics.readabilityScore,
      structureScore: textMetrics.structureScore,
      specificityScore: textMetrics.specificityScore,
      relevanceScore: textMetrics.relevanceScore,
      starOverallScore: textMetrics.starAnalysis.overallScore,
      starHasSituation: textMetrics.starAnalysis.hasSituation,
      starHasTask: textMetrics.starAnalysis.hasTask,
      starHasAction: textMetrics.starAnalysis.hasAction,
      starHasResult: textMetrics.starAnalysis.hasResult,
      powerWordsUsed: textMetrics.powerWordsUsed,
      weakPhrasesUsed: textMetrics.weakPhrasesUsed,
      // AI evaluation
      hasAiEvaluation: aiEval != null,
      aiContentScore: aiEval?.contentScore,
      aiStructureScore: aiEval?.structureScore,
      aiDepthScore: aiEval?.depthScore,
      aiStrengths: aiEval?.keyStrengths,
      aiImprovements: aiEval?.improvements,
      aiIdealAnswerTips: aiEval?.idealAnswerTips,
      aiOverallImpression: aiEval?.overallImpression,
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
    required double contentQualityScore,
    double? aiOverallScore,
  }) {
    if (aiOverallScore != null) {
      // When AI evaluation is available, blend all sources
      // Delivery: 40%, On-device content: 25%, AI content: 35%
      final deliveryScore =
          confidenceScore * 0.4 + clarityScore * 0.35 + paceScore * 0.25;
      return (deliveryScore * 0.40 +
              contentQualityScore * 0.25 +
              aiOverallScore * 0.35)
          .clamp(0.0, 100.0);
    }

    // Without AI: Delivery 55%, On-device content 45%
    final deliveryScore =
        confidenceScore * 0.4 + clarityScore * 0.35 + paceScore * 0.25;
    return (deliveryScore * 0.55 + contentQualityScore * 0.45)
        .clamp(0.0, 100.0);
  }

  List<String> _identifyStrengths({
    required double wordsPerMinute,
    required int fillerWordCount,
    required int totalWords,
    required int pauseCount,
    required double confidenceScore,
    required Duration totalDuration,
    required TextAnalysisMetrics textMetrics,
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

    // Content-based strengths
    if (textMetrics.starAnalysis.componentsPresent >= 3) {
      strengths.add('Good use of STAR method structure');
    }

    if (textMetrics.specificityScore >= 70) {
      strengths.add('Strong use of specific examples and details');
    }

    if (textMetrics.vocabularyDiversityScore >= 60) {
      strengths.add('Rich and varied vocabulary');
    }

    if (textMetrics.powerWordsUsed.length >= 3) {
      strengths.add('Effective use of power words: ${textMetrics.powerWordsUsed.take(3).join(", ")}');
    }

    if (textMetrics.relevanceScore >= 80) {
      strengths.add('Response is highly relevant to the question');
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
    required TextAnalysisMetrics textMetrics,
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

    // Content-based improvements
    if (textMetrics.starAnalysis.componentsPresent < 3 &&
        textMetrics.starAnalysis.componentsPresent > 0) {
      final missing = <String>[];
      if (!textMetrics.starAnalysis.hasSituation) missing.add('Situation');
      if (!textMetrics.starAnalysis.hasTask) missing.add('Task');
      if (!textMetrics.starAnalysis.hasAction) missing.add('Action');
      if (!textMetrics.starAnalysis.hasResult) missing.add('Result');
      improvements.add(
        'Use the STAR method — missing: ${missing.join(", ")}. '
        'This gives your answer clear structure.',
      );
    } else if (textMetrics.starAnalysis.componentsPresent == 0 && totalWords > 30) {
      improvements.add(
        'Structure your response using the STAR method: '
        'Situation, Task, Action, Result.',
      );
    }

    if (textMetrics.specificityScore < 50 && totalWords > 30) {
      improvements.add(
        'Add more specific examples, numbers, and concrete details '
        'to make your answer more compelling.',
      );
    }

    if (textMetrics.weakPhrasesUsed.isNotEmpty) {
      improvements.add(
        'Avoid weak phrases like "${textMetrics.weakPhrasesUsed.take(2).join('", "')}" — '
        'they reduce perceived confidence.',
      );
    }

    if (improvements.isEmpty) {
      improvements.add('Great job! Keep practicing to maintain consistency.');
    }

    return improvements;
  }
}
