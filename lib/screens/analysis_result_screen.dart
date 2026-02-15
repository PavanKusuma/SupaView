import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/speech_analysis_result.dart';
import '../providers/interview_provider.dart';
import '../utils/app_theme.dart';
import 'question_selection_screen.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InterviewProvider>(
      builder: (context, provider, _) {
        final result = provider.lastResult;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analysis')),
            body: const Center(
              child: Text(
                'No analysis data available.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Results'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
                onPressed: () async {
                  await provider.saveSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session saved!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOverallScoreCard(context, result),
                const SizedBox(height: 16),
                _buildScoreBreakdown(context, result),
                const SizedBox(height: 16),
                _buildMetricsGrid(context, result),
                const SizedBox(height: 16),
                _buildFillerWordsCard(context, result),
                const SizedBox(height: 16),
                _buildPauseAnalysis(context, result),
                const SizedBox(height: 16),
                _buildPaceChart(context, result),
                const SizedBox(height: 16),
                _buildContentAnalysisCard(context, result),
                const SizedBox(height: 16),
                _buildSTARCard(context, result),
                const SizedBox(height: 16),
                if (result.hasAiEvaluation)
                  _buildAiEvaluationCard(context, result),
                if (result.hasAiEvaluation) const SizedBox(height: 16),
                _buildStrengthsCard(context, result),
                const SizedBox(height: 16),
                _buildImprovementsCard(context, result),
                const SizedBox(height: 16),
                _buildTranscriptCard(context, result),
                const SizedBox(height: 24),
                _buildActionButtons(context, provider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallScoreCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.scoreColor(result.overallScore).withOpacity(0.2),
              AppTheme.cardDark,
            ],
          ),
        ),
        child: Column(
          children: [
            CircularPercentIndicator(
              radius: 70,
              lineWidth: 10,
              percent: (result.overallScore / 100).clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    result.overallGrade,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.scoreColor(result.overallScore),
                        ),
                  ),
                  Text(
                    '${result.overallScore.round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
              progressColor: AppTheme.scoreColor(result.overallScore),
              backgroundColor: Colors.white10,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 16),
            Text(
              'Overall Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _overallMessage(result.overallScore),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            _scoreBar(context, 'Confidence', result.confidenceScore,
                Icons.psychology),
            const SizedBox(height: 12),
            _scoreBar(
                context, 'Clarity', result.clarityScore, Icons.visibility),
            const SizedBox(height: 12),
            _scoreBar(context, 'Pace', result.paceScore, Icons.speed),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(
      BuildContext context, String label, double score, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.scoreColor(score)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          child: LinearPercentIndicator(
            lineHeight: 8,
            percent: (score / 100).clamp(0.0, 1.0),
            progressColor: AppTheme.scoreColor(score),
            backgroundColor: Colors.white10,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${score.round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppTheme.scoreColor(score),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(
      BuildContext context, SpeechAnalysisResult result) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: _formatDuration(result.totalDuration),
            color: AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.text_fields,
            label: 'Total Words',
            value: '${result.totalWords}',
            color: AppTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillerWordsCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Filler Words',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (result.fillerWordCount > 10
                            ? AppTheme.errorColor
                            : result.fillerWordCount > 5
                                ? AppTheme.warningColor
                                : AppTheme.successColor)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result.fillerWordCount} total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: result.fillerWordCount > 10
                          ? AppTheme.errorColor
                          : result.fillerWordCount > 5
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result.fillerWords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No filler words detected! Excellent!',
                  style: TextStyle(color: AppTheme.successColor),
                ),
              )
            else
              ...result.fillerWords.take(8).map((filler) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${filler.word}"',
                            style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filler.count}x',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: LinearPercentIndicator(
                            lineHeight: 4,
                            percent: (filler.percentage / 10).clamp(0.0, 1.0),
                            progressColor: AppTheme.warningColor,
                            backgroundColor: Colors.white10,
                            barRadius: const Radius.circular(2),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseAnalysis(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pause_circle_outline,
                    size: 20, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Text(
                  'Pause Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _pauseStat(
                    context,
                    label: 'Total Pauses',
                    value: '${result.pauseCount}',
                    subtext: result.pauseCount <= 3
                        ? 'Good'
                        : result.pauseCount <= 6
                            ? 'Moderate'
                            : 'Frequent',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _pauseStat(
                    context,
                    label: 'Pause Time',
                    value: _formatDuration(result.totalPauseDuration),
                    subtext: 'of total duration',
                  ),
                ),
              ],
            ),
            if (result.pauses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Text(
                'Pause Timeline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: _buildPauseTimeline(result),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pauseStat(BuildContext context,
      {required String label, required String value, required String subtext}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          subtext,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildPauseTimeline(SpeechAnalysisResult result) {
    if (result.totalDuration.inSeconds == 0) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background bar
            Container(
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Pause markers
            ...result.pauses.map((pause) {
              final position = pause.timestamp.inMilliseconds /
                  result.totalDuration.inMilliseconds;
              final width = (pause.duration.inMilliseconds /
                      result.totalDuration.inMilliseconds) *
                  constraints.maxWidth;

              return Positioned(
                left: position * constraints.maxWidth,
                top: 11,
                child: Container(
                  width: width.clamp(4.0, constraints.maxWidth * 0.2),
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPaceChart(BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, size: 20, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Speaking Pace',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '${result.wordsPerMinute.round()}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'words per minute',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _paceColor(result.wordsPerMinute).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      result.paceLabel,
                      style: TextStyle(
                        color: _paceColor(result.wordsPerMinute),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Pace gauge
            SizedBox(
              height: 100,
              child: _buildPaceGauge(context, result.wordsPerMinute),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceGauge(BuildContext context, double wpm) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Slow', 'Ideal', 'Fast'];
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox();
                return Text(
                  labels[idx],
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _paceBar(0, wpm < 100 ? _normalizeWpm(wpm, 0, 100) : 0,
              AppTheme.infoColor),
          _paceBar(
              1,
              wpm >= 100 && wpm <= 160
                  ? _normalizeWpm(wpm, 100, 160)
                  : 0,
              AppTheme.successColor),
          _paceBar(2, wpm > 160 ? _normalizeWpm(wpm, 160, 220) : 0,
              AppTheme.errorColor),
        ],
      ),
    );
  }

  BarChartGroupData _paceBar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.clamp(0.0, 1.0),
          color: value > 0 ? color : Colors.white10,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  double _normalizeWpm(double wpm, double min, double max) {
    return ((wpm - min) / (max - min)).clamp(0.1, 1.0);
  }

  Widget _buildStrengthsCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined,
                    size: 20, color: AppTheme.successColor),
                const SizedBox(width: 8),
                Text(
                  'Strengths',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: AppTheme.successColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                              color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementsCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 20, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Areas to Improve',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.improvements.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right,
                          size: 20, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                              color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined,
                    size: 20, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  'Transcript',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              result.questionText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const Divider(color: Colors.white12, height: 24),
            Text(
              result.transcript.isEmpty
                  ? 'No transcript available.'
                  : result.transcript,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentAnalysisCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Content Quality',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_android, size: 10, color: Colors.white38),
                      SizedBox(width: 4),
                      Text(
                        'On-Device',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _scoreBar(context, 'Vocabulary', result.vocabularyDiversityScore,
                Icons.text_fields),
            const SizedBox(height: 10),
            _scoreBar(context, 'Readability', result.readabilityScore,
                Icons.menu_book),
            const SizedBox(height: 10),
            _scoreBar(context, 'Structure', result.structureScore,
                Icons.account_tree),
            const SizedBox(height: 10),
            _scoreBar(context, 'Specificity', result.specificityScore,
                Icons.gps_fixed),
            const SizedBox(height: 10),
            _scoreBar(context, 'Relevance', result.relevanceScore,
                Icons.track_changes),
            if (result.powerWordsUsed.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Text(
                'Power words used:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.powerWordsUsed.map((w) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    w,
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
            if (result.weakPhrasesUsed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Weak phrases to avoid:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.weakPhrasesUsed.map((w) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '"$w"',
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSTARCard(BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_outline,
                    size: 20, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'STAR Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                Text(
                  '${result.starOverallScore.round()}%',
                  style: TextStyle(
                    color: AppTheme.scoreColor(result.starOverallScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _starComponent('S', 'Situation', result.starHasSituation),
                const SizedBox(width: 8),
                _starComponent('T', 'Task', result.starHasTask),
                const SizedBox(width: 8),
                _starComponent('A', 'Action', result.starHasAction),
                const SizedBox(width: 8),
                _starComponent('R', 'Result', result.starHasResult),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _starSummary(result),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starComponent(String letter, String label, bool present) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: (present ? AppTheme.successColor : Colors.white)
              .withOpacity(present ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: present
                ? AppTheme.successColor.withOpacity(0.3)
                : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Text(
              letter,
              style: TextStyle(
                color: present ? AppTheme.successColor : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: present ? Colors.white54 : Colors.white24,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              present ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: present ? AppTheme.successColor : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  String _starSummary(SpeechAnalysisResult result) {
    final count = (result.starHasSituation ? 1 : 0) +
        (result.starHasTask ? 1 : 0) +
        (result.starHasAction ? 1 : 0) +
        (result.starHasResult ? 1 : 0);
    if (count == 4) return 'Excellent! All STAR components detected.';
    if (count == 3) return 'Good structure — one component could be stronger.';
    if (count == 2) return 'Partial structure — try to include all four components.';
    if (count == 1) return 'Weak structure — practice using the full STAR method.';
    return 'No STAR structure detected. Frame your answer around a specific situation, your task, actions taken, and results achieved.';
  }

  Widget _buildAiEvaluationCard(
      BuildContext context, SpeechAnalysisResult result) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentColor.withOpacity(0.08),
              AppTheme.cardDark,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 20, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'AI Evaluation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 10, color: AppTheme.accentColor),
                      SizedBox(width: 4),
                      Text(
                        'Gemini',
                        style: TextStyle(
                            color: AppTheme.accentColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.aiOverallImpression != null &&
                result.aiOverallImpression!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.aiOverallImpression!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (result.aiContentScore != null)
              _scoreBar(context, 'Content', result.aiContentScore!,
                  Icons.description),
            if (result.aiStructureScore != null) ...[
              const SizedBox(height: 10),
              _scoreBar(context, 'Structure', result.aiStructureScore!,
                  Icons.account_tree),
            ],
            if (result.aiDepthScore != null) ...[
              const SizedBox(height: 10),
              _scoreBar(context, 'Depth', result.aiDepthScore!,
                  Icons.layers),
            ],
            if (result.aiStrengths != null &&
                result.aiStrengths!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              ...result.aiStrengths!.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13)),
                        ),
                      ],
                    ),
                  )),
            ],
            if (result.aiIdealAnswerTips != null &&
                result.aiIdealAnswerTips!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Tips for the ideal answer:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              ...result.aiIdealAnswerTips!.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 14, color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, InterviewProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              provider.resetSession();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuestionSelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Another Question'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Color _paceColor(double wpm) {
    if (wpm >= 100 && wpm <= 160) return AppTheme.successColor;
    if (wpm >= 80 && wpm <= 180) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _overallMessage(double score) {
    if (score >= 85) return 'Outstanding! You delivered a confident and clear response.';
    if (score >= 70) return 'Great job! A strong response with room for minor improvements.';
    if (score >= 55) return 'Good effort! Focus on the improvement areas below to level up.';
    if (score >= 40) return 'Decent start. Practice the tips below to boost your scores.';
    return 'Keep practicing! Review the feedback below to improve your delivery.';
  }
}
