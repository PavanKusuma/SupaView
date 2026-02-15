import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Uses Google Gemini 2.5 Flash-Lite (free tier: 1,000 requests/day)
/// for AI-powered interview response evaluation.
///
/// Falls back to rule-based evaluation when:
/// - No API key is configured
/// - API quota is exceeded
/// - Network errors occur
class GeminiEvaluationService {
  static const _apiKeyPrefKey = 'gemini_api_key';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.0-flash-lite';

  String? _cachedApiKey;

  Future<String?> getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_apiKeyPrefKey);
    return _cachedApiKey;
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, key);
    _cachedApiKey = key;
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefKey);
    _cachedApiKey = null;
  }

  bool get hasApiKey => _cachedApiKey != null && _cachedApiKey!.isNotEmpty;

  /// Evaluates an interview response using Gemini.
  /// Returns null if API is unavailable (caller should use rule-based fallback).
  Future<GeminiEvaluation?> evaluate({
    required String transcript,
    required String question,
    required String category,
    required double wordsPerMinute,
    required int fillerWordCount,
    required int pauseCount,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final prompt = _buildPrompt(
        transcript: transcript,
        question: question,
        category: category,
        wordsPerMinute: wordsPerMinute,
        fillerWordCount: fillerWordCount,
        pauseCount: pauseCount,
      );

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else if (response.statusCode == 429) {
        print('Gemini rate limit reached — using rule-based fallback');
        return null;
      } else {
        print('Gemini API error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Gemini evaluation failed: $e');
      return null;
    }
  }

  String _buildPrompt({
    required String transcript,
    required String question,
    required String category,
    required double wordsPerMinute,
    required int fillerWordCount,
    required int pauseCount,
  }) {
    return '''You are an expert interview coach evaluating a candidate's response.

INTERVIEW QUESTION ($category): "$question"

CANDIDATE'S RESPONSE TRANSCRIPT:
"$transcript"

SPEECH METRICS:
- Speaking pace: ${wordsPerMinute.round()} words per minute
- Filler words detected: $fillerWordCount
- Pauses detected: $pauseCount

Evaluate the response and return a JSON object with exactly this structure:
{
  "content_score": <number 0-100, how well the content answers the question>,
  "structure_score": <number 0-100, logical flow and organization>,
  "relevance_score": <number 0-100, how directly it addresses the question>,
  "depth_score": <number 0-100, specificity, examples, and detail>,
  "professionalism_score": <number 0-100, appropriate tone and language>,
  "star_used": <boolean, whether STAR method was used>,
  "key_strengths": [<3 short strength strings>],
  "improvements": [<3 short improvement strings>],
  "ideal_answer_tips": [<2 tips for the ideal answer to this specific question>],
  "overall_impression": "<1 sentence overall assessment>"
}

Be constructive but honest. Score realistically — most answers should be 50-80 range.''';
  }

  GeminiEvaluation? _parseResponse(String responseBody) {
    try {
      final responseJson = json.decode(responseBody);
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'] as String;
      final evaluation = json.decode(text);

      return GeminiEvaluation(
        contentScore: (evaluation['content_score'] as num?)?.toDouble() ?? 50,
        structureScore: (evaluation['structure_score'] as num?)?.toDouble() ?? 50,
        relevanceScore: (evaluation['relevance_score'] as num?)?.toDouble() ?? 50,
        depthScore: (evaluation['depth_score'] as num?)?.toDouble() ?? 50,
        professionalismScore: (evaluation['professionalism_score'] as num?)?.toDouble() ?? 50,
        starUsed: evaluation['star_used'] as bool? ?? false,
        keyStrengths: List<String>.from(evaluation['key_strengths'] ?? []),
        improvements: List<String>.from(evaluation['improvements'] ?? []),
        idealAnswerTips: List<String>.from(evaluation['ideal_answer_tips'] ?? []),
        overallImpression: evaluation['overall_impression'] as String? ?? '',
      );
    } catch (e) {
      print('Failed to parse Gemini response: $e');
      return null;
    }
  }
}

class GeminiEvaluation {
  final double contentScore;
  final double structureScore;
  final double relevanceScore;
  final double depthScore;
  final double professionalismScore;
  final bool starUsed;
  final List<String> keyStrengths;
  final List<String> improvements;
  final List<String> idealAnswerTips;
  final String overallImpression;

  const GeminiEvaluation({
    required this.contentScore,
    required this.structureScore,
    required this.relevanceScore,
    required this.depthScore,
    required this.professionalismScore,
    required this.starUsed,
    required this.keyStrengths,
    required this.improvements,
    required this.idealAnswerTips,
    required this.overallImpression,
  });

  double get overallScore =>
      (contentScore * 0.3 +
          structureScore * 0.2 +
          relevanceScore * 0.2 +
          depthScore * 0.2 +
          professionalismScore * 0.1)
          .clamp(0.0, 100.0);

  Map<String, dynamic> toMap() {
    return {
      'content_score': contentScore,
      'structure_score': structureScore,
      'relevance_score': relevanceScore,
      'depth_score': depthScore,
      'professionalism_score': professionalismScore,
      'star_used': starUsed,
      'key_strengths': keyStrengths,
      'improvements': improvements,
      'ideal_answer_tips': idealAnswerTips,
      'overall_impression': overallImpression,
    };
  }
}
