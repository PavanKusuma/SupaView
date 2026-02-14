class FillerWordOccurrence {
  final String word;
  final int count;
  final double percentage;

  const FillerWordOccurrence({
    required this.word,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {'word': word, 'count': count, 'percentage': percentage};
  }

  factory FillerWordOccurrence.fromMap(Map<String, dynamic> map) {
    return FillerWordOccurrence(
      word: map['word'] as String,
      count: map['count'] as int,
      percentage: (map['percentage'] as num).toDouble(),
    );
  }
}

class PauseInfo {
  final Duration timestamp;
  final Duration duration;

  const PauseInfo({required this.timestamp, required this.duration});

  Map<String, dynamic> toMap() {
    return {
      'timestamp_ms': timestamp.inMilliseconds,
      'duration_ms': duration.inMilliseconds,
    };
  }

  factory PauseInfo.fromMap(Map<String, dynamic> map) {
    return PauseInfo(
      timestamp: Duration(milliseconds: map['timestamp_ms'] as int),
      duration: Duration(milliseconds: map['duration_ms'] as int),
    );
  }
}

class SpeechAnalysisResult {
  final String id;
  final String questionId;
  final String questionText;
  final String transcript;
  final Duration totalDuration;
  final int totalWords;
  final double wordsPerMinute;
  final int fillerWordCount;
  final List<FillerWordOccurrence> fillerWords;
  final int pauseCount;
  final List<PauseInfo> pauses;
  final Duration totalPauseDuration;
  final double confidenceScore;
  final double clarityScore;
  final double paceScore;
  final double overallScore;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime createdAt;

  const SpeechAnalysisResult({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.transcript,
    required this.totalDuration,
    required this.totalWords,
    required this.wordsPerMinute,
    required this.fillerWordCount,
    required this.fillerWords,
    required this.pauseCount,
    required this.pauses,
    required this.totalPauseDuration,
    required this.confidenceScore,
    required this.clarityScore,
    required this.paceScore,
    required this.overallScore,
    required this.strengths,
    required this.improvements,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'question_text': questionText,
      'transcript': transcript,
      'total_duration_ms': totalDuration.inMilliseconds,
      'total_words': totalWords,
      'words_per_minute': wordsPerMinute,
      'filler_word_count': fillerWordCount,
      'pause_count': pauseCount,
      'total_pause_duration_ms': totalPauseDuration.inMilliseconds,
      'confidence_score': confidenceScore,
      'clarity_score': clarityScore,
      'pace_score': paceScore,
      'overall_score': overallScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get overallGrade {
    if (overallScore >= 90) return 'A+';
    if (overallScore >= 85) return 'A';
    if (overallScore >= 80) return 'A-';
    if (overallScore >= 75) return 'B+';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 65) return 'B-';
    if (overallScore >= 60) return 'C+';
    if (overallScore >= 55) return 'C';
    if (overallScore >= 50) return 'C-';
    if (overallScore >= 40) return 'D';
    return 'F';
  }

  String get confidenceLabel {
    if (confidenceScore >= 80) return 'High';
    if (confidenceScore >= 60) return 'Moderate';
    if (confidenceScore >= 40) return 'Low';
    return 'Very Low';
  }

  String get paceLabel {
    if (wordsPerMinute > 180) return 'Too Fast';
    if (wordsPerMinute >= 140) return 'Slightly Fast';
    if (wordsPerMinute >= 100) return 'Ideal';
    if (wordsPerMinute >= 80) return 'Slightly Slow';
    return 'Too Slow';
  }
}

class InterviewSession {
  final String id;
  final DateTime date;
  final List<SpeechAnalysisResult> results;
  final String mode; // 'live' or 'recorded'

  const InterviewSession({
    required this.id,
    required this.date,
    required this.results,
    required this.mode,
  });

  double get averageScore {
    if (results.isEmpty) return 0;
    return results.map((r) => r.overallScore).reduce((a, b) => a + b) /
        results.length;
  }

  int get totalQuestions => results.length;

  Duration get totalDuration {
    return results.fold(
      Duration.zero,
      (sum, r) => sum + r.totalDuration,
    );
  }
}
