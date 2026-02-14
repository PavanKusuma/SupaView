import 'package:flutter_test/flutter_test.dart';
import 'package:supaview/services/speech_analysis_service.dart';
import 'package:supaview/models/speech_analysis_result.dart';

void main() {
  late SpeechAnalysisService service;

  setUp(() {
    service = SpeechAnalysisService();
  });

  group('SpeechAnalysisService', () {
    test('analyzes transcript with filler words', () {
      final result = service.analyze(
        transcript:
            'Um, I think that like basically I am a um good candidate. '
            'You know, I have like experience in um software development.',
        questionId: 'test_01',
        questionText: 'Tell me about yourself.',
        totalDuration: const Duration(minutes: 2),
        detectedPauses: [],
        recognitionConfidences: [0.9, 0.85, 0.92],
      );

      expect(result.totalWords, greaterThan(0));
      expect(result.fillerWordCount, greaterThan(0));
      expect(result.fillerWords, isNotEmpty);
      expect(result.overallScore, greaterThan(0));
      expect(result.overallScore, lessThanOrEqualTo(100));

      // Check that 'um' and 'like' are detected
      final fillerWordTexts = result.fillerWords.map((f) => f.word).toList();
      expect(fillerWordTexts, contains('um'));
      expect(fillerWordTexts, contains('like'));
    });

    test('analyzes clean transcript with high score', () {
      final result = service.analyze(
        transcript:
            'I have five years of experience in software development, '
            'specializing in mobile applications. I led a team of three '
            'developers to deliver a healthcare app that served over ten '
            'thousand users. My strengths include problem solving, clear '
            'communication, and the ability to break down complex requirements '
            'into manageable tasks.',
        questionId: 'test_02',
        questionText: 'Tell me about yourself.',
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
    });

    test('handles empty transcript', () {
      final result = service.analyze(
        transcript: '',
        questionId: 'test_03',
        questionText: 'Test question.',
        totalDuration: const Duration(seconds: 5),
        detectedPauses: [],
        recognitionConfidences: [],
      );

      expect(result.totalWords, equals(0));
      expect(result.fillerWordCount, equals(0));
    });

    test('calculates WPM correctly', () {
      // 120 words in 1 minute = 120 WPM
      final words = List.generate(120, (i) => 'word').join(' ');
      final result = service.analyze(
        transcript: words,
        questionId: 'test_04',
        questionText: 'Test question.',
        totalDuration: const Duration(minutes: 1),
        detectedPauses: [],
        recognitionConfidences: [0.9],
      );

      expect(result.wordsPerMinute, closeTo(120, 5));
      expect(result.paceLabel, equals('Ideal'));
    });

    test('identifies fast speaking pace', () {
      final words = List.generate(200, (i) => 'word').join(' ');
      final result = service.analyze(
        transcript: words,
        questionId: 'test_05',
        questionText: 'Test question.',
        totalDuration: const Duration(minutes: 1),
        detectedPauses: [],
        recognitionConfidences: [0.9],
      );

      expect(result.wordsPerMinute, greaterThan(180));
      expect(result.paceLabel, equals('Too Fast'));
    });

    test('result grade mapping works', () {
      final result = service.analyze(
        transcript: 'Good clear response with specific examples and evidence.',
        questionId: 'test_06',
        questionText: 'Test question.',
        totalDuration: const Duration(minutes: 1),
        detectedPauses: [],
        recognitionConfidences: [0.95],
      );

      expect(
        ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'],
        contains(result.overallGrade),
      );
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
