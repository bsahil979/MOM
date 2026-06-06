import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/meeting_provider.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulsingController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulsingController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeetingProvider>(context);
    final theme = Theme.of(context);

    // Auto-scroll transcript on new content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.recordingState == RecordingState.recording) {
        _scrollToBottom();
      }
    });

    if (!_isEditingTitle && _titleController.text != provider.currentMeeting?.title) {
      _titleController.text = provider.currentMeeting?.title ?? 'New Meeting';
    }

    return WillPopScope(
      onWillPop: () async {
        if (provider.recordingState != RecordingState.idle) {
          _confirmCancel(context, provider);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmCancel(context, provider),
          ),
          title: _isEditingTitle
              ? TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Enter meeting title...',
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      provider.updateMeetingTitle(val);
                      _isEditingTitle = false;
                    });
                  },
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.currentMeeting?.title ?? 'New Meeting',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.secondary),
                      onPressed: () {
                        setState(() {
                          _isEditingTitle = true;
                        });
                      },
                    )
                  ],
                ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Status Indicator
                _buildStatusIndicator(provider, theme),
                const SizedBox(height: 36),

                // Pulsing Mic Icon
                Center(child: _buildMicButton(provider, theme)),
                const SizedBox(height: 48),

                // Custom Waveform Painter
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WaveformPainter(
                      levels: provider.audioWaveLevels,
                      color: theme.colorScheme.primary,
                      isRecording: provider.recordingState == RecordingState.recording,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Duration text
                Text(
                  provider.formattedDuration,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 36),

                // Action controls
                _buildControls(provider, theme),
                const SizedBox(height: 36),

                // Scrolling Transcription Text Panel
                Expanded(
                  child: _buildTranscriptPanel(provider, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(MeetingProvider provider, ThemeData theme) {
    String text = 'READY';
    Color color = theme.colorScheme.secondary;

    if (provider.recordingState == RecordingState.recording) {
      text = 'RECORDING';
      color = theme.colorScheme.onBackground;
    } else if (provider.recordingState == RecordingState.paused) {
      text = 'PAUSED';
      color = theme.colorScheme.secondary.withOpacity(0.8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(MeetingProvider provider, ThemeData theme) {
    final isRecording = provider.recordingState == RecordingState.recording;

    return AnimatedBuilder(
      animation: _pulsingController,
      builder: (context, child) {
        double scale = 1.0;
        double opacity = 0.1;

        if (isRecording) {
          scale = 1.0 + (_pulsingController.value * 0.15);
          opacity = 0.2 - (_pulsingController.value * 0.15);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost pulsing ring
            Container(
              width: 140 * scale,
              height: 140 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(opacity),
              ),
            ),
            // Inner pulsing ring
            Container(
              width: 115 * (1.0 + (_pulsingController.value * 0.08)),
              height: 115 * (1.0 + (_pulsingController.value * 0.08)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(opacity * 1.5),
              ),
            ),
            // Core button
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                Icons.mic,
                size: 38,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(MeetingProvider provider, ThemeData theme) {
    final state = provider.recordingState;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume Button
        if (state == RecordingState.recording)
          _buildActionButton(
            icon: Icons.pause,
            label: 'Pause',
            color: theme.colorScheme.secondary,
            theme: theme,
            onPressed: () => provider.pauseRecording(),
          )
        else if (state == RecordingState.paused)
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Resume',
            color: theme.colorScheme.onBackground,
            theme: theme,
            onPressed: () => provider.resumeRecording(),
          ),

        if (state != RecordingState.idle) const SizedBox(width: 32),

        // Stop/Save Button
        _buildActionButton(
          icon: Icons.stop,
          label: 'Finish',
          color: theme.colorScheme.primary,
          theme: theme,
          onPressed: () {
            provider.stopRecording();
            Navigator.pushReplacementNamed(context, '/transcript');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    final bool isPrimary = color == theme.colorScheme.primary;

    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface,
            foregroundColor: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            side: BorderSide(color: theme.dividerColor, width: 1.5),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 24, color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptPanel(MeetingProvider provider, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Live Transcription',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: provider.liveTranscriptText.isEmpty
                  ? Center(
                      child: Text(
                        'Voice feeds will stream here...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.liveTranscriptText.split('\n').length,
                      itemBuilder: (context, index) {
                        final lines = provider.liveTranscriptText.split('\n');
                        final line = lines[index];
                        final isLast = index == lines.length - 1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            line,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isLast
                                  ? theme.colorScheme.onBackground
                                  : theme.colorScheme.secondary,
                              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, MeetingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Discard Recording?'),
        content: const Text('Are you sure you want to cancel? This will delete all current progress.'),
        actions: [
          TextButton(
            child: Text('Resume', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
            onPressed: () {
              provider.cancelRecording();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final bool isRecording;

  WaveformPainter({
    required this.levels,
    required this.color,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final int count = levels.length;
    final double spacing = width / count;

    final paint = Paint()
      ..color = isRecording ? color : color.withOpacity(0.2)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final double x = i * spacing + spacing / 2;
      double val = levels[i];
      
      if (!isRecording) {
        val = 0.05;
      }

      final double barHeight = val * height;
      final double top = (height - barHeight) / 2;
      final double bottom = top + barHeight;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
