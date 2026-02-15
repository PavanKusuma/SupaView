/// On-device NLP analysis — 100% free, no API calls.
///
/// Computes industry-standard speech metrics from a transcript:
/// - Vocabulary diversity (Type-Token Ratio)
/// - Readability (Flesch-Kincaid adapted for spoken language)
/// - STAR method adherence (Situation, Task, Action, Result)
/// - Sentence structure & complexity
/// - Specificity & use of concrete examples
/// - Response relevance to the question asked
class TextAnalysisService {
  /// Full analysis returning all metrics.
  TextAnalysisMetrics analyze({
    required String transcript,
    required String question,
  }) {
    final sentences = _splitSentences(transcript);
    final words = _extractWords(transcript);
    final wordCount = words.length;

    if (wordCount < 5) {
      return TextAnalysisMetrics.empty();
    }

    final vocabularyDiversity = _vocabularyDiversity(words);
    final readabilityScore = _readabilityScore(words, sentences);
    final starAnalysis = _analyzeSTAR(transcript);
    final structureScore = _structureScore(sentences, wordCount);
    final specificityScore = _specificityScore(transcript, words);
    final relevanceScore = _relevanceScore(transcript, question);
    final sentimentIndicators = _sentimentIndicators(transcript);
    final powerWords = _detectPowerWords(transcript);
    final weakPhrases = _detectWeakPhrases(transcript);

    return TextAnalysisMetrics(
      vocabularyDiversityScore: vocabularyDiversity,
      readabilityScore: readabilityScore,
      starAnalysis: starAnalysis,
      structureScore: structureScore,
      specificityScore: specificityScore,
      relevanceScore: relevanceScore,
      sentimentIndicators: sentimentIndicators,
      powerWordsUsed: powerWords,
      weakPhrasesUsed: weakPhrases,
      averageSentenceLength: wordCount / (sentences.isEmpty ? 1 : sentences.length).toDouble(),
      sentenceCount: sentences.length,
    );
  }

  // ── Vocabulary Diversity (Type-Token Ratio) ──

  double _vocabularyDiversity(List<String> words) {
    if (words.isEmpty) return 0;
    final uniqueWords = words.toSet();
    final ttr = uniqueWords.length / words.length;

    // Normalize: TTR of 0.4-0.7 is typical for spoken language
    // Below 0.3 = very repetitive, above 0.7 = excellent variety
    return (ttr * 100).clamp(0.0, 100.0);
  }

  // ── Readability (Flesch-Kincaid adapted) ──

  double _readabilityScore(List<String> words, List<String> sentences) {
    if (words.isEmpty || sentences.isEmpty) return 50;

    final avgWordsPerSentence = words.length / sentences.length;
    final avgSyllablesPerWord = words.map(_countSyllables).reduce((a, b) => a + b) / words.length;

    // Flesch Reading Ease formula (adapted)
    // Higher = easier to understand (which is GOOD for interviews)
    final flesch = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord);

    // For interviews, 60-80 is ideal (conversational but professional)
    // Map to 0-100 score
    if (flesch >= 60 && flesch <= 80) return 100;
    if (flesch >= 50 && flesch < 60) return 85;
    if (flesch > 80 && flesch <= 90) return 85;
    if (flesch >= 40 && flesch < 50) return 70;
    if (flesch > 90) return 70; // too simple
    if (flesch >= 30 && flesch < 40) return 55;
    return 40;
  }

  int _countSyllables(String word) {
    if (word.isEmpty) return 1;
    word = word.toLowerCase();
    if (word.length <= 3) return 1;

    int count = 0;
    bool prevVowel = false;
    const vowels = 'aeiouy';

    for (int i = 0; i < word.length; i++) {
      final isVowel = vowels.contains(word[i]);
      if (isVowel && !prevVowel) count++;
      prevVowel = isVowel;
    }

    // Handle silent 'e'
    if (word.endsWith('e') && count > 1) count--;
    return count < 1 ? 1 : count;
  }

  // ── STAR Method Analysis ──

  STARAnalysis _analyzeSTAR(String transcript) {
    final lower = transcript.toLowerCase();

    final situationKeywords = [
      'situation', 'context', 'background', 'scenario', 'when i was',
      'at my previous', 'in my role', 'there was a time', 'we were facing',
      'the problem was', 'the challenge was', 'i was working',
      'our team was', 'the company was', 'during my time',
    ];

    final taskKeywords = [
      'task', 'responsible', 'my role was', 'i needed to', 'goal was',
      'objective', 'i was asked to', 'had to', 'assigned to',
      'my job was', 'expected to', 'was supposed to', 'charged with',
      'tasked with', 'requirement was',
    ];

    final actionKeywords = [
      'i decided', 'i implemented', 'i created', 'i developed',
      'i organized', 'i led', 'i initiated', 'i built', 'i designed',
      'steps i took', 'my approach', 'i started by', 'first i',
      'then i', 'i collaborated', 'i analyzed', 'i proposed',
      'i negotiated', 'i managed', 'i coordinated', 'i resolved',
    ];

    final resultKeywords = [
      'result', 'outcome', 'achieved', 'improved', 'increased',
      'reduced', 'saved', 'led to', 'as a result', 'consequently',
      'impact was', 'success', 'delivered', 'accomplished',
      'percent', '%', 'grew by', 'decreased by', 'this resulted',
      'the team was able', 'we were able', 'ultimately',
    ];

    final situationScore = _keywordMatchScore(lower, situationKeywords);
    final taskScore = _keywordMatchScore(lower, taskKeywords);
    final actionScore = _keywordMatchScore(lower, actionKeywords);
    final resultScore = _keywordMatchScore(lower, resultKeywords);

    final overallScore = (situationScore + taskScore + actionScore + resultScore) / 4;

    return STARAnalysis(
      situationScore: situationScore,
      taskScore: taskScore,
      actionScore: actionScore,
      resultScore: resultScore,
      overallScore: overallScore,
      hasSituation: situationScore > 30,
      hasTask: taskScore > 30,
      hasAction: actionScore > 30,
      hasResult: resultScore > 30,
    );
  }

  double _keywordMatchScore(String text, List<String> keywords) {
    int matchCount = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) matchCount++;
    }
    // At least 2-3 keyword matches = full score
    final ratio = matchCount / 3.0;
    return (ratio * 100).clamp(0.0, 100.0);
  }

  // ── Structure Score ──

  double _structureScore(List<String> sentences, int wordCount) {
    if (sentences.isEmpty) return 0;

    double score = 50; // baseline

    final avgLen = wordCount / sentences.length;

    // Good sentence length for spoken language: 10-25 words
    if (avgLen >= 10 && avgLen <= 25) {
      score += 25;
    } else if (avgLen >= 7 && avgLen < 10) {
      score += 15;
    } else if (avgLen > 25 && avgLen <= 35) {
      score += 10;
    }

    // Having multiple sentences shows structured thinking
    if (sentences.length >= 3) score += 15;
    if (sentences.length >= 6) score += 10;

    return score.clamp(0.0, 100.0);
  }

  // ── Specificity Score ──

  double _specificityScore(String transcript, List<String> words) {
    final lower = transcript.toLowerCase();
    double score = 40; // baseline

    // Numbers and quantifiable results
    final numberPattern = RegExp(r'\b\d+\b');
    final numberCount = numberPattern.allMatches(lower).length;
    if (numberCount >= 1) score += 10;
    if (numberCount >= 3) score += 10;

    // Specific time references
    final timeWords = ['year', 'month', 'week', 'day', 'quarter', 'sprint'];
    for (final tw in timeWords) {
      if (lower.contains(tw)) {
        score += 5;
        break;
      }
    }

    // Action verbs (specific > vague)
    final actionVerbs = [
      'implemented', 'built', 'designed', 'launched', 'created',
      'optimized', 'reduced', 'increased', 'negotiated', 'delivered',
      'analyzed', 'streamlined', 'automated', 'migrated', 'refactored',
    ];
    int actionCount = 0;
    for (final verb in actionVerbs) {
      if (lower.contains(verb)) actionCount++;
    }
    score += (actionCount * 5).clamp(0, 20).toDouble();

    // Penalize vague language
    final vagueWords = [
      'stuff', 'things', 'whatever', 'somehow', 'something like',
      'i guess', 'kind of', 'sort of', 'maybe', 'i think maybe',
    ];
    int vagueCount = 0;
    for (final vague in vagueWords) {
      if (lower.contains(vague)) vagueCount++;
    }
    score -= (vagueCount * 5).clamp(0, 15).toDouble();

    return score.clamp(0.0, 100.0);
  }

  // ── Relevance Score ──

  double _relevanceScore(String transcript, String question) {
    if (transcript.isEmpty || question.isEmpty) return 50;

    final transcriptWords = _extractWords(transcript).toSet();
    final questionWords = _extractWords(question)
        .where((w) => w.length > 3) // skip small words
        .toSet();

    if (questionWords.isEmpty) return 70;

    // How many question keywords appear in the response
    int overlap = 0;
    for (final qWord in questionWords) {
      if (transcriptWords.contains(qWord)) overlap++;
    }

    final ratio = overlap / questionWords.length;

    // Also check for topic-related synonyms/phrases
    double bonus = 0;
    final lower = transcript.toLowerCase();
    final qLower = question.toLowerCase();

    if (qLower.contains('strength') &&
        (lower.contains('good at') || lower.contains('excel') || lower.contains('strong'))) {
      bonus += 10;
    }
    if (qLower.contains('challenge') &&
        (lower.contains('difficult') || lower.contains('problem') || lower.contains('obstacle'))) {
      bonus += 10;
    }
    if (qLower.contains('team') &&
        (lower.contains('collaborate') || lower.contains('together') || lower.contains('group'))) {
      bonus += 10;
    }

    return ((ratio * 80) + 20 + bonus).clamp(0.0, 100.0);
  }

  // ── Sentiment Indicators ──

  Map<String, double> _sentimentIndicators(String transcript) {
    final lower = transcript.toLowerCase();

    final positiveWords = [
      'achieved', 'accomplished', 'improved', 'successful', 'excited',
      'passionate', 'enjoyed', 'proud', 'excellent', 'great',
      'opportunity', 'growth', 'learned', 'thrived', 'innovative',
    ];

    final negativeWords = [
      'failed', 'struggled', 'unfortunately', 'difficult', 'problem',
      'mistake', 'couldn\'t', 'unable', 'frustrated', 'disappointed',
    ];

    int posCount = 0;
    int negCount = 0;
    for (final w in positiveWords) {
      if (lower.contains(w)) posCount++;
    }
    for (final w in negativeWords) {
      if (lower.contains(w)) negCount++;
    }

    final total = posCount + negCount;
    return {
      'positive': total > 0 ? posCount / total : 0.5,
      'negative': total > 0 ? negCount / total : 0.5,
      'positiveCount': posCount.toDouble(),
      'negativeCount': negCount.toDouble(),
    };
  }

  // ── Power Words ──

  List<String> _detectPowerWords(String transcript) {
    final lower = transcript.toLowerCase();
    const powerWords = [
      'achieved', 'accelerated', 'built', 'created', 'delivered',
      'designed', 'developed', 'drove', 'established', 'generated',
      'implemented', 'improved', 'increased', 'initiated', 'launched',
      'led', 'managed', 'negotiated', 'optimized', 'orchestrated',
      'pioneered', 'produced', 'reduced', 'resolved', 'spearheaded',
      'streamlined', 'strengthened', 'surpassed', 'transformed',
    ];

    return powerWords.where((w) => lower.contains(w)).toList();
  }

  // ── Weak Phrases ──

  List<String> _detectWeakPhrases(String transcript) {
    final lower = transcript.toLowerCase();
    const weakPhrases = [
      'i think', 'i guess', 'kind of', 'sort of', 'maybe',
      'i\'m not sure', 'i don\'t know', 'to be honest',
      'i feel like', 'it was okay', 'not really', 'just a',
      'i was just', 'probably', 'hopefully',
    ];

    return weakPhrases.where((w) => lower.contains(w)).toList();
  }

  // ── Helpers ──

  List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<String> _splitSentences(String text) {
    if (text.trim().isEmpty) return [];

    // Speech-to-text often lacks punctuation, so split on natural breaks
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // If no punctuation was found (common with speech-to-text),
    // estimate sentences by average length
    if (sentences.length <= 1 && text.split(' ').length > 20) {
      final words = text.split(' ');
      final estimated = <String>[];
      for (int i = 0; i < words.length; i += 15) {
        final end = (i + 15).clamp(0, words.length);
        estimated.add(words.sublist(i, end).join(' '));
      }
      return estimated;
    }

    return sentences;
  }
}

// ── Data Classes ──

class TextAnalysisMetrics {
  final double vocabularyDiversityScore;
  final double readabilityScore;
  final STARAnalysis starAnalysis;
  final double structureScore;
  final double specificityScore;
  final double relevanceScore;
  final Map<String, double> sentimentIndicators;
  final List<String> powerWordsUsed;
  final List<String> weakPhrasesUsed;
  final double averageSentenceLength;
  final int sentenceCount;

  const TextAnalysisMetrics({
    required this.vocabularyDiversityScore,
    required this.readabilityScore,
    required this.starAnalysis,
    required this.structureScore,
    required this.specificityScore,
    required this.relevanceScore,
    required this.sentimentIndicators,
    required this.powerWordsUsed,
    required this.weakPhrasesUsed,
    required this.averageSentenceLength,
    required this.sentenceCount,
  });

  factory TextAnalysisMetrics.empty() => TextAnalysisMetrics(
        vocabularyDiversityScore: 0,
        readabilityScore: 0,
        starAnalysis: STARAnalysis.empty(),
        structureScore: 0,
        specificityScore: 0,
        relevanceScore: 0,
        sentimentIndicators: const {'positive': 0.5, 'negative': 0.5},
        powerWordsUsed: const [],
        weakPhrasesUsed: const [],
        averageSentenceLength: 0,
        sentenceCount: 0,
      );

  /// Weighted content quality score (0-100).
  double get contentQualityScore {
    return (vocabularyDiversityScore * 0.15 +
            readabilityScore * 0.15 +
            starAnalysis.overallScore * 0.25 +
            structureScore * 0.15 +
            specificityScore * 0.15 +
            relevanceScore * 0.15)
        .clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'vocabulary_diversity': vocabularyDiversityScore,
      'readability': readabilityScore,
      'star_overall': starAnalysis.overallScore,
      'star_situation': starAnalysis.situationScore,
      'star_task': starAnalysis.taskScore,
      'star_action': starAnalysis.actionScore,
      'star_result': starAnalysis.resultScore,
      'structure': structureScore,
      'specificity': specificityScore,
      'relevance': relevanceScore,
      'power_words': powerWordsUsed,
      'weak_phrases': weakPhrasesUsed,
      'avg_sentence_length': averageSentenceLength,
      'sentence_count': sentenceCount,
    };
  }
}

class STARAnalysis {
  final double situationScore;
  final double taskScore;
  final double actionScore;
  final double resultScore;
  final double overallScore;
  final bool hasSituation;
  final bool hasTask;
  final bool hasAction;
  final bool hasResult;

  const STARAnalysis({
    required this.situationScore,
    required this.taskScore,
    required this.actionScore,
    required this.resultScore,
    required this.overallScore,
    required this.hasSituation,
    required this.hasTask,
    required this.hasAction,
    required this.hasResult,
  });

  factory STARAnalysis.empty() => const STARAnalysis(
        situationScore: 0,
        taskScore: 0,
        actionScore: 0,
        resultScore: 0,
        overallScore: 0,
        hasSituation: false,
        hasTask: false,
        hasAction: false,
        hasResult: false,
      );

  int get componentsPresent =>
      (hasSituation ? 1 : 0) +
      (hasTask ? 1 : 0) +
      (hasAction ? 1 : 0) +
      (hasResult ? 1 : 0);

  String get summary {
    if (componentsPresent == 4) return 'Excellent STAR structure';
    if (componentsPresent == 3) return 'Good structure - missing one component';
    if (componentsPresent == 2) return 'Partial structure - needs more components';
    if (componentsPresent == 1) return 'Weak structure - use the STAR method';
    return 'No STAR structure detected';
  }
}
