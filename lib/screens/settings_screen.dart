import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isKeyVisible = false;
  bool _isLoading = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final gemini = context.read<InterviewProvider>().geminiService;
    final key = await gemini.getApiKey();
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      if (_hasKey) {
        _apiKeyController.text = key!;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeminiSection(context),
                  const SizedBox(height: 24),
                  _buildAnalysisInfoSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildGeminiSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Analysis',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Google Gemini Flash-Lite (Free Tier)',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_hasKey ? AppTheme.successColor : Colors.white24)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _hasKey ? 'Active' : 'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          _hasKey ? AppTheme.successColor : Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Add a free Gemini API key to unlock AI-powered content evaluation. '
              'Without it, the app still provides full on-device analysis (NLP, '
              'STAR method, vocabulary, pace, filler words).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free tier includes:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _infoBullet('1,000 requests/day (Flash-Lite)'),
                  _infoBullet('No credit card required'),
                  _infoBullet('AI content & structure scoring'),
                  _infoBullet('Personalized answer tips'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: !_isKeyVisible,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                labelStyle: const TextStyle(color: Colors.white38),
                hintText: 'AIza...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isKeyVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isKeyVisible = !_isKeyVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    child: Text(_hasKey ? 'Update Key' : 'Save Key'),
                  ),
                ),
                if (_hasKey) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _removeApiKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _showGetKeyInstructions(context);
              },
              child: const Text(
                'How do I get a free API key?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            _analysisMethod(
              icon: Icons.phone_android,
              title: 'On-Device Analysis (Always Free)',
              items: [
                'Filler word detection (20+ words)',
                'Speaking pace & WPM',
                'Pause tracking',
                'STAR method structure detection',
                'Vocabulary diversity (TTR)',
                'Readability score',
                'Specificity & power words',
                'Response relevance',
              ],
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            _analysisMethod(
              icon: Icons.auto_awesome,
              title: 'AI Analysis (Free Gemini API)',
              items: [
                'Content quality evaluation',
                'Answer structure & depth scoring',
                'Personalized strengths & improvements',
                'Ideal answer tips for each question',
                'Professional tone assessment',
              ],
              color: AppTheme.accentColor,
              isOptional: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisMethod({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isOptional)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Optional',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 14, color: color.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _infoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 12, color: AppTheme.accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    final gemini = context.read<InterviewProvider>().geminiService;
    await gemini.setApiKey(key);

    setState(() => _hasKey = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved! AI evaluation is now active.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _removeApiKey() async {
    final gemini = context.read<InterviewProvider>().geminiService;
    await gemini.clearApiKey();
    _apiKeyController.clear();

    setState(() => _hasKey = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key removed. On-device analysis only.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  void _showGetKeyInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Get a Free Gemini API Key',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              _step('1', 'Go to aistudio.google.com'),
              _step('2', 'Sign in with your Google account'),
              _step('3', 'Click "Get API Key" in the left menu'),
              _step('4', 'Create a new API key (free, no credit card)'),
              _step('5', 'Copy the key and paste it above'),
              const SizedBox(height: 12),
              Text(
                'The free tier gives you 1,000 requests/day with '
                'Gemini Flash-Lite — enough for extensive practice.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
