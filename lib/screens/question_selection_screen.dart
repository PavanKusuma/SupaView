import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../providers/interview_provider.dart';
import '../services/question_repository.dart';
import '../utils/app_theme.dart';
import 'interview_session_screen.dart';

class QuestionSelectionScreen extends StatefulWidget {
  final bool isImportMode;

  const QuestionSelectionScreen({
    super.key,
    this.isImportMode = false,
  });

  @override
  State<QuestionSelectionScreen> createState() =>
      _QuestionSelectionScreenState();
}

class _QuestionSelectionScreenState extends State<QuestionSelectionScreen> {
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  List<InterviewQuestion> get _filteredQuestions {
    var questions = QuestionRepository.allQuestions;

    if (_selectedCategory != 'All') {
      questions =
          questions.where((q) => q.category == _selectedCategory).toList();
    }

    if (_selectedDifficulty != 'All') {
      questions = questions
          .where((q) => q.difficulty == _selectedDifficulty)
          .toList();
    }

    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isImportMode ? 'Select Question' : 'Choose a Question'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Random question',
            onPressed: _selectRandom,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildQuestionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final categories = ['All', ...QuestionRepository.categories];
    final difficulties = ['All', ...QuestionRepository.difficulties];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == _selectedCategory;
                return FilterChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: difficulties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final diff = difficulties[index];
                final isSelected = diff == _selectedDifficulty;
                return FilterChip(
                  label: Text(
                    diff,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedDifficulty = diff),
                  selectedColor: _difficultyColor(diff),
                  checkmarkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    final questions = _filteredQuestions;

    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'No questions match your filters.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(questions[index]);
      },
    );
  }

  Widget _buildQuestionCard(InterviewQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectQuestion(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor(question.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _categoryColor(question.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _difficultyColor(question.difficulty).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.difficulty,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _difficultyColor(question.difficulty),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question.tip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectQuestion(InterviewQuestion question) {
    context.read<InterviewProvider>().setQuestion(question);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewSessionScreen(
          isImportMode: widget.isImportMode,
        ),
      ),
    );
  }

  void _selectRandom() {
    final questions = _filteredQuestions;
    if (questions.isEmpty) return;
    questions.shuffle();
    _selectQuestion(questions.first);
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Behavioral':
        return AppTheme.primaryColor;
      case 'Technical':
        return AppTheme.accentColor;
      case 'Leadership':
        return AppTheme.warningColor;
      case 'Situational':
        return AppTheme.infoColor;
      case 'Communication':
        return const Color(0xFFE91E63);
      default:
        return Colors.white;
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return AppTheme.successColor;
      case 'Medium':
        return AppTheme.warningColor;
      case 'Hard':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
