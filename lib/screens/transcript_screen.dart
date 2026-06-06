import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/meeting_provider.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  late TextEditingController _transcriptController;
  Timer? _loadingTextTimer;
  int _loadingTextIndex = 0;

  final List<String> _loadingMessages = [
    'Connecting Gemini API...',
    'Reviewing audio transcript...',
    'Parsing meeting details...',
    'Identifying attendees...',
    'Summarizing discussion items...',
    'Formulating action items...',
    'Extracting decisions...',
    'Building final MoM report...',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MeetingProvider>(context, listen: false);
    _transcriptController = TextEditingController(
      text: provider.currentMeeting?.transcript ?? '',
    );
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  void _startLoadingTextCycle() {
    _loadingTextIndex = 0;
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      setState(() {
        _loadingTextIndex = (_loadingTextIndex + 1) % _loadingMessages.length;
      });
    });
  }

  void _stopLoadingTextCycle() {
    _loadingTextTimer?.cancel();
  }

  Future<void> _handleGenerateMoM(MeetingProvider provider) async {
    provider.updateTranscript(_transcriptController.text);
    _startLoadingTextCycle();

    try {
      await provider.generateMinutesOfMeeting();
      _stopLoadingTextCycle();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/editor');
      }
    } catch (e) {
      _stopLoadingTextCycle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeetingProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Review Transcript'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Discard Meeting',
            onPressed: () => _confirmDiscard(context, provider),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Audio Transcript',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review and edit the raw text below before submitting to Gemini for structured MoM creation.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Large Transcript Editing box
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _transcriptController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Enter transcript text here...',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          foregroundColor: theme.colorScheme.secondary,
                          side: BorderSide(color: theme.dividerColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _confirmDiscard(context, provider),
                        child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _handleGenerateMoM(provider),
                        icon: Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.onPrimary),
                        label: Text(
                          'Generate MoM',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (provider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.85),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Card(
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.onBackground),
                        const SizedBox(height: 24),
                        Text(
                          'Processing Transcript',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 24,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _loadingMessages[_loadingTextIndex],
                              key: ValueKey<int>(_loadingTextIndex),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDiscard(BuildContext context, MeetingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Discard Meeting?'),
        content: const Text('Are you sure you want to discard this meeting? All raw data will be lost.'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Discard'),
            onPressed: () {
              provider.clearCurrentMeeting();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
