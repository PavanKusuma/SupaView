class InterviewQuestion {
  final String id;
  final String question;
  final String category;
  final String difficulty;
  final String tip;

  const InterviewQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.difficulty,
    required this.tip,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'category': category,
      'difficulty': difficulty,
      'tip': tip,
    };
  }

  factory InterviewQuestion.fromMap(Map<String, dynamic> map) {
    return InterviewQuestion(
      id: map['id'] as String,
      question: map['question'] as String,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      tip: map['tip'] as String,
    );
  }
}
