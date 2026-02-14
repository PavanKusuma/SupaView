import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/interview_provider.dart';
import '../utils/app_theme.dart';
import 'analysis_result_screen.dart';

class InterviewSessionScreen extends StatefulWidget {
  final bool isImportMode;

  const InterviewSessionScreen({
    super.key,
    this.isImportMode = false,
  });

  @override
  State<InterviewSessionScreen> createState() =>
      _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    if (!widget.isImportMode) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InterviewProvider>(
      builder: (context, provider, _) {
        // Navigate to results when analysis is complete
        if (provider.state == InterviewState.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AnalysisResultScreen(),
              ),
            );
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.surfaceDark,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, provider),
                Expanded(
                  child: _buildMainContent(context, provider),
                ),
                _buildBottomControls(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, InterviewProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () {
              if (provider.state == InterviewState.recording) {
                _showExitConfirmation(context, provider);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Spacer(),
          if (provider.state == InterviewState.recording) ...[
            _buildRecordingIndicator(),
            const SizedBox(width: 12),
            _buildTimer(provider),
          ],
          const Spacer(),
          if (_isCameraReady &&
              provider.state != InterviewState.countdown)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white70),
              onPressed: _toggleCamera,
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        AppTheme.errorColor.withOpacity(0.5 * _pulseAnimation.value),
                    blurRadius: 8 * _pulseAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'REC',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimer(InterviewProvider provider) {
    final remaining = provider.remainingSeconds;
    final isLow = remaining <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isLow ? AppTheme.errorColor : Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isLow ? AppTheme.errorColor : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            provider.elapsedFormatted,
            style: TextStyle(
              color: isLow ? AppTheme.errorColor : Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, InterviewProvider provider) {
    return Column(
      children: [
        // Question display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline,
                      size: 16, color: AppTheme.primaryLight),
                  const SizedBox(width: 8),
                  Text(
                    'Interview Question',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                provider.currentQuestion?.question ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Camera preview or countdown
        Expanded(
          flex: 3,
          child: _buildCenterContent(context, provider),
        ),

        // Live transcript
        Expanded(
          flex: 2,
          child: _buildTranscriptArea(context, provider),
        ),
      ],
    );
  }

  Widget _buildCenterContent(
      BuildContext context, InterviewProvider provider) {
    if (provider.state == InterviewState.countdown) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${provider.countdownValue}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 80,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get Ready...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      );
    }

    if (provider.state == InterviewState.analyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing your response...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      );
    }

    // Camera preview
    if (_isCameraReady && _cameraController != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider.state == InterviewState.recording
                ? AppTheme.primaryColor.withOpacity(0.5)
                : Colors.white12,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CameraPreview(_cameraController!),
        ),
      );
    }

    // Fallback - no camera
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.state == InterviewState.recording
                  ? Icons.mic
                  : Icons.videocam_off_outlined,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              provider.state == InterviewState.recording
                  ? 'Listening...'
                  : 'Camera not available\nAudio-only mode',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptArea(
      BuildContext context, InterviewProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subtitles_outlined,
                size: 16,
                color: provider.isListening
                    ? AppTheme.accentColor
                    : Colors.white38,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Transcript',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              if (provider.isListening) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                provider.transcript.isEmpty
                    ? (provider.state == InterviewState.recording
                        ? 'Start speaking... your words will appear here.'
                        : 'Press the button below to begin.')
                    : provider.transcript,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: provider.transcript.isEmpty
                          ? Colors.white24
                          : Colors.white70,
                      height: 1.6,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, InterviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (provider.state == InterviewState.idle) ...[
            _buildActionButton(
              icon: Icons.mic,
              label: 'Start Recording',
              color: AppTheme.primaryColor,
              onTap: () => provider.startCountdown(),
            ),
          ] else if (provider.state == InterviewState.recording) ...[
            _buildActionButton(
              icon: Icons.stop_rounded,
              label: 'Stop & Analyze',
              color: AppTheme.errorColor,
              onTap: () => provider.stopRecording(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCamera() async {
    if (_cameraController == null) return;

    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    _isFrontCamera = !_isFrontCamera;
    final newCamera = cameras.firstWhere(
      (c) => c.lensDirection == (_isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    await _cameraController!.dispose();
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  void _showExitConfirmation(
      BuildContext context, InterviewProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Stop Recording?'),
        content: const Text(
          'Your current recording will be analyzed. '
          'Do you want to stop and see your results?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Recording'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              provider.stopRecording();
            },
            child: const Text('Stop & Analyze'),
          ),
        ],
      ),
    );
  }
}
