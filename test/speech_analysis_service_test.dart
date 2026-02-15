import 'package:flutter_test/flutter_test.dart';
import 'package:supaview/services/speech_analysis_service.dart';
import 'package:supaview/services/text_analysis_service.dart';
import 'package:supaview/models/speech_analysis_result.dart';

void main() {
  late SpeechAnalysisService service;
  late TextAnalysisService textService;

  setUp(() {
    service = SpeechAnalysisService();
    textService = TextAnalysisService();
  });

  group('SpeechAnalysisService', () {
    test('analyzes transcript with filler words', () async {
      final result = await service.analyze(
        transcript:
            'Um, I think that like basically I am a um good candidate. '
            'You know, I have like experience in um software development.',
        questionId: 'test_01',
        questionText: 'Tell me about yourself.',
        questionCategory: 'Behavioral',
        totalDuration: const Duration(minutes: 2),
        detectedPauses: [],
        recognitionConfidences: [0.9, 0.85, 0.92],
      );

      expect(result.totalWords, greaterThan(0));
      expect(result.fillerWordCount, greaterThan(0));
      expect(result.fillerWords, isNotEmpty);
      expect(result.overallScore, greaterThan(0));
      expect(result.overallScore, lessThanOrEqualTo(100));

      final fillerWordTexts = result.fillerWords.map((f) => f.word).toList();
      expect(fillerWordTexts, contains('um'));
      expect(fillerWordTexts, contains('like'));
    });

    test('analyzes clean transcript with high score', () async {
      final result = await service.analyze(
        transcript:
            'I have five years of experience in software development, '
            'specializing in mobile applications. I led a team of three '
            'developers to deliver a healthcare app that served over ten '
            'thousand users. My strengths include problem solving, clear '
            'communication, and the ability to break down complex requirements '
            'into manageable tasks.',
        questionId: 'test_02',
        questionText: 'Tell me about yourself.',
        questionCategory: 'Behavioral',
        totalDuration: const Duration(minutes: 1, seconds: 30),
        detectedPauses: [
          const PauseInfo(
            timestamp: Duration(seconds: 30),
            duration: Duration(seconds: 2),
          ),
        ],
        recognitionConfidences: [0.95, 0.92, 0.97],
      );

      expect(result.fillerWordCount, lessThan(3));
      expect(result.confidenceScore, greaterThan(60));
      expect(result.strengths, isNotEmpty);
      // Enhanced metrics should be populated
      expect(result.contentQualityScore, greaterThan(0));
    });

    test('handles empty transcript', () async {
      final result = await service.analyze(
        transcript: '',
        questionId: 'test_03',
        questionText: 'Test question.',
        questionCategory: 'Behavioral',
        totalDuration: const Duration(seconds: 5),
        detectedPauses: [],
        recognitionConfidences: [],
      );

      expect(result.totalWords, equals(0));
      expect(result.fillerWordCount, equals(0));
    });

    test('calculates WPM correctly', () async {
      final words = List.generate(120, (i) => 'word').join(' ');
      final result = await service.analyze(
        transcript: words,
        questionId: 'test_04',
        questionText: 'Test question.',
        questionCategory: 'Behavioral',
        totalDuration: const Duration(minutes: 1),
        detectedPauses: [],
        recognitionConfidences: [0.9],
      );

      expect(result.wordsPerMinute, closeTo(120, 5));
      expect(result.paceLabel, equals('Ideal'));
    });
  });

  group('TextAnalysisService', () {
    test('detects STAR method components', () {
      final metrics = textService.analyze(
        transcript:
            'In my previous role at Acme Corp, we were facing a major '
            'database performance issue. I was responsible for leading the '
            'optimization effort. I analyzed the slow queries, implemented '
            'indexing strategies, and redesigned the caching layer. As a '
            'result, we reduced response times by 60 percent and the team '
            'was able to handle twice the traffic.',
        question: 'Tell me about a challenging project.',
      );

      expect(metrics.starAnalysis.hasSituation, isTrue);
      expect(metrics.starAnalysis.hasAction, isTrue);
      expect(metrics.starAnalysis.hasResult, isTrue);
      expect(metrics.starAnalysis.componentsPresent, greaterThanOrEqualTo(3));
    });

    test('calculates vocabulary diversity', () {
      // Repetitive text
      final repetitive = textService.analyze(
        transcript: 'I did the thing and the thing was good and the thing worked',
        question: 'Question',
      );

      // Diverse text
      final diverse = textService.analyze(
        transcript:
            'I implemented a microservices architecture, designed REST APIs, '
            'collaborated with stakeholders, analyzed performance metrics, '
            'and delivered comprehensive documentation for the engineering team.',
        question: 'Question',
      );

      expect(
        diverse.vocabularyDiversityScore,
        greaterThan(repetitive.vocabularyDiversityScore),
      );
    });

    test('detects power words and weak phrases', () {
      final metrics = textService.analyze(
        transcript:
            'I implemented and launched a new system that improved efficiency. '
            'I guess I sort of managed the project, I think maybe it was okay.',
        question: 'Question',
      );

      expect(metrics.powerWordsUsed, isNotEmpty);
      expect(metrics.weakPhrasesUsed, isNotEmpty);
      expect(metrics.powerWordsUsed, contains('implemented'));
      expect(metrics.weakPhrasesUsed, contains('i guess'));
    });

    test('calculates content quality score', () {
      final metrics = textService.analyze(
        transcript:
            'In my previous role as a senior engineer, I was tasked with '
            'redesigning our payment processing system. I led a team of 4 '
            'developers, implemented a new microservices architecture, and '
            'delivered the project 2 weeks ahead of schedule. As a result, '
            'we reduced transaction failures by 45 percent.',
        question: 'Describe a project you led.',
      );

      expect(metrics.contentQualityScore, greaterThan(40));
      expect(metrics.specificityScore, greaterThan(50));
    });

    test('handles empty transcript', () {
      final metrics = textService.analyze(
        transcript: '',
        question: 'Question',
      );

      expect(metrics.contentQualityScore, equals(0));
    });
  });

  group('SpeechAnalysisResult', () {
    test('confidenceLabel returns correct label', () {
      final makeResult = (double confidenceScore) => SpeechAnalysisResult(
            id: 'test',
            questionId: 'q1',
            questionText: 'Question',
            transcript: 'test',
            totalDuration: const Duration(minutes: 1),
            totalWords: 100,
            wordsPerMinute: 120,
            fillerWordCount: 0,
            fillerWords: const [],
            pauseCount: 0,
            pauses: const [],
            totalPauseDuration: Duration.zero,
            confidenceScore: confidenceScore,
            clarityScore: 80,
            paceScore: 90,
            overallScore: 80,
            strengths: const [],
            improvements: const [],
            createdAt: DateTime.now(),
          );

      expect(makeResult(90).confidenceLabel, equals('High'));
      expect(makeResult(70).confidenceLabel, equals('Moderate'));
      expect(makeResult(50).confidenceLabel, equals('Low'));
      expect(makeResult(30).confidenceLabel, equals('Very Low'));
    });
  });
}
