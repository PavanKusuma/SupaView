import '../models/interview_question.dart';

class QuestionRepository {
  static const List<InterviewQuestion> allQuestions = [
    // Behavioral Questions
    InterviewQuestion(
      id: 'beh_01',
      question: 'Tell me about yourself and your background.',
      category: 'Behavioral',
      difficulty: 'Easy',
      tip: 'Keep it concise (1-2 minutes). Focus on relevant experience, skills, and what brought you here. Use the Present-Past-Future formula.',
    ),
    InterviewQuestion(
      id: 'beh_02',
      question: 'What is your greatest strength?',
      category: 'Behavioral',
      difficulty: 'Easy',
      tip: 'Choose a strength relevant to the role. Back it up with a specific example that demonstrates this strength in action.',
    ),
    InterviewQuestion(
      id: 'beh_03',
      question: 'Tell me about a time you faced a challenging situation at work. How did you handle it?',
      category: 'Behavioral',
      difficulty: 'Medium',
      tip: 'Use the STAR method: Situation, Task, Action, Result. Focus on your specific contribution and the positive outcome.',
    ),
    InterviewQuestion(
      id: 'beh_04',
      question: 'Describe a situation where you had to work with a difficult team member.',
      category: 'Behavioral',
      difficulty: 'Medium',
      tip: 'Show emotional intelligence and conflict resolution skills. Focus on the solution, not the drama. Never badmouth others.',
    ),
    InterviewQuestion(
      id: 'beh_05',
      question: 'Where do you see yourself in five years?',
      category: 'Behavioral',
      difficulty: 'Easy',
      tip: 'Show ambition but be realistic. Align your goals with the company\'s trajectory. Demonstrate that this role fits your career path.',
    ),
    InterviewQuestion(
      id: 'beh_06',
      question: 'Tell me about a time you failed. What did you learn from it?',
      category: 'Behavioral',
      difficulty: 'Hard',
      tip: 'Be honest and choose a genuine failure. Focus primarily on the lessons learned and how you improved afterward.',
    ),
    InterviewQuestion(
      id: 'beh_07',
      question: 'Why are you interested in this position?',
      category: 'Behavioral',
      difficulty: 'Easy',
      tip: 'Show genuine enthusiasm. Connect your skills and interests to the specific role. Mention what excites you about the company.',
    ),

    // Technical Questions
    InterviewQuestion(
      id: 'tech_01',
      question: 'Explain a complex technical concept to someone non-technical.',
      category: 'Technical',
      difficulty: 'Medium',
      tip: 'Use analogies and simple language. Avoid jargon. Structure your explanation step by step, checking for understanding.',
    ),
    InterviewQuestion(
      id: 'tech_02',
      question: 'Describe a project you are most proud of. What was your role and what technologies did you use?',
      category: 'Technical',
      difficulty: 'Medium',
      tip: 'Highlight your specific contributions. Explain why you made certain technical decisions. Discuss challenges and how you overcame them.',
    ),
    InterviewQuestion(
      id: 'tech_03',
      question: 'How do you stay updated with the latest technology trends?',
      category: 'Technical',
      difficulty: 'Easy',
      tip: 'Mention specific resources: blogs, podcasts, conferences, open-source contributions. Show genuine passion for learning.',
    ),
    InterviewQuestion(
      id: 'tech_04',
      question: 'Walk me through how you would debug a production issue.',
      category: 'Technical',
      difficulty: 'Hard',
      tip: 'Show a systematic approach: gather information, reproduce the issue, check logs, isolate the cause, fix, and verify. Mention communication with stakeholders.',
    ),

    // Leadership Questions
    InterviewQuestion(
      id: 'lead_01',
      question: 'Describe a time when you had to lead a team through a difficult project.',
      category: 'Leadership',
      difficulty: 'Hard',
      tip: 'Highlight your leadership style, communication, and decision-making. Show how you motivated the team and delivered results despite challenges.',
    ),
    InterviewQuestion(
      id: 'lead_02',
      question: 'How do you prioritize tasks when everything seems urgent?',
      category: 'Leadership',
      difficulty: 'Medium',
      tip: 'Mention frameworks like Eisenhower Matrix or MoSCoW. Show that you can assess impact, communicate with stakeholders, and make tough calls.',
    ),
    InterviewQuestion(
      id: 'lead_03',
      question: 'Tell me about a time you mentored someone. What was the outcome?',
      category: 'Leadership',
      difficulty: 'Medium',
      tip: 'Show that you invest in others\' growth. Highlight specific actions you took and the measurable impact on the person\'s development.',
    ),

    // Situational Questions
    InterviewQuestion(
      id: 'sit_01',
      question: 'If you were given a project with an impossible deadline, what would you do?',
      category: 'Situational',
      difficulty: 'Medium',
      tip: 'Show your ability to negotiate scope, communicate risks, and find creative solutions. Don\'t just say you\'d work overtime.',
    ),
    InterviewQuestion(
      id: 'sit_02',
      question: 'How would you handle a situation where you disagree with your manager\'s decision?',
      category: 'Situational',
      difficulty: 'Hard',
      tip: 'Show respect while being assertive. Explain how you\'d present your perspective with data, and ultimately support the final decision.',
    ),
    InterviewQuestion(
      id: 'sit_03',
      question: 'Imagine you just started a new job and realize the codebase has significant technical debt. What do you do?',
      category: 'Situational',
      difficulty: 'Hard',
      tip: 'Show patience and a strategic approach. Understand the context first, prioritize issues by impact, and propose incremental improvements.',
    ),

    // Communication Questions
    InterviewQuestion(
      id: 'comm_01',
      question: 'How do you handle receiving critical feedback?',
      category: 'Communication',
      difficulty: 'Medium',
      tip: 'Show openness and maturity. Give a specific example of feedback you received and how it helped you grow professionally.',
    ),
    InterviewQuestion(
      id: 'comm_02',
      question: 'Describe a time you had to present a complex idea to stakeholders. How did you ensure they understood?',
      category: 'Communication',
      difficulty: 'Medium',
      tip: 'Highlight your ability to tailor your message to the audience. Mention visual aids, analogies, or structured presentations you used.',
    ),
  ];

  static List<InterviewQuestion> getByCategory(String category) {
    return allQuestions.where((q) => q.category == category).toList();
  }

  static List<InterviewQuestion> getByDifficulty(String difficulty) {
    return allQuestions.where((q) => q.difficulty == difficulty).toList();
  }

  static List<String> get categories =>
      allQuestions.map((q) => q.category).toSet().toList();

  static List<String> get difficulties =>
      allQuestions.map((q) => q.difficulty).toSet().toList();

  static InterviewQuestion? getById(String id) {
    try {
      return allQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<InterviewQuestion> getRandom(int count) {
    final shuffled = List<InterviewQuestion>.from(allQuestions)..shuffle();
    return shuffled.take(count).toList();
  }
}
