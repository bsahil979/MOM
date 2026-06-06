import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/meeting_provider.dart';
import '../models/meeting.dart';
import '../utils/file_saver.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  late String _markdownContent;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MeetingProvider>(context, listen: false);
    final meeting = provider.currentMeeting;

    if (meeting != null) {
      _markdownContent = _generateMarkdownContent(meeting);
      _emailController.text = '';
      _subjectController.text = 'Minutes of Meeting: ${meeting.title} - ${DateFormat('yyyy-MM-dd').format(meeting.date)}';
    } else {
      _markdownContent = '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String _generateMarkdownContent(Meeting meeting) {
    final buffer = StringBuffer();
    buffer.writeln('# Minutes of Meeting: ${meeting.title}');
    buffer.writeln('**Date:** ${DateFormat('MMMM dd, yyyy • hh:mm a').format(meeting.date)}');
    buffer.writeln('**Duration:** ${meeting.duration.inMinutes} minutes');
    buffer.writeln();
    buffer.writeln('## 1. Executive Summary');
    buffer.writeln(meeting.mom.summary.isNotEmpty ? meeting.mom.summary : 'No summary provided.');
    buffer.writeln();
    buffer.writeln('## 2. Attendees');
    if (meeting.mom.participants.isNotEmpty) {
      for (var attendee in meeting.mom.participants) {
        buffer.writeln('- $attendee');
      }
    } else {
      buffer.writeln('_No attendees listed._');
    }
    buffer.writeln();
    buffer.writeln('## 3. Key Decisions');
    final validDecisions = meeting.mom.decisions.where((d) => d.trim().isNotEmpty).toList();
    if (validDecisions.isNotEmpty) {
      for (var decision in validDecisions) {
        buffer.writeln('- $decision');
      }
    } else {
      buffer.writeln('_No decisions recorded._');
    }
    buffer.writeln();
    buffer.writeln('## 4. Action Items & Deliverables');
    final validActions = meeting.mom.actionItems.where((item) => item.description.trim().isNotEmpty).toList();
    if (validActions.isNotEmpty) {
      buffer.writeln('| Task / Description | Assignee | Due Date |');
      buffer.writeln('| :--- | :--- | :--- |');
      for (var item in validActions) {
        buffer.writeln('| ${item.description} | ${item.assignee.isNotEmpty ? item.assignee : "TBD"} | ${item.dueDate.isNotEmpty ? item.dueDate : "TBD"} |');
      }
    } else {
      buffer.writeln('_No action items created._');
    }
    return buffer.toString();
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _markdownContent;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch mail client. Copied to clipboard!'),
            backgroundColor: Colors.orange,
          ),
        );
        Clipboard.setData(ClipboardData(text: _markdownContent));
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _markdownContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Markdown copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadMarkdown(Meeting meeting) {
    final safeTitle = meeting.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(' ', '_');
    final filename = 'MoM_$safeTitle.md';
    
    FileSaver.saveFile(_markdownContent, filename);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded file: $filename'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeetingProvider>(context);
    final theme = Theme.of(context);
    final meeting = provider.currentMeeting;

    if (meeting == null) {
      return Scaffold(
        body: Center(
          child: Text('No active meeting.', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Share & Export'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Setup Email Form
                  _buildFormCard(theme),
                  const SizedBox(height: 24),

                  // Quick Export Operations
                  _buildExportOptionsCard(meeting, theme),
                  const SizedBox(height: 24),

                  // Report Preview Panel
                  _buildPreviewPanel(theme),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Send via Email',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            TextField(
              controller: _emailController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Recipient Email(s)',
                hintText: 'e.g. team@company.com',
                prefixIcon: Icon(Icons.person_outline, size: 16),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Subject Line',
                prefixIcon: Icon(Icons.subject_outlined, size: 16),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _sendEmail,
                icon: Icon(Icons.send_outlined, size: 16, color: theme.colorScheme.onPrimary),
                label: Text(
                  'Open Mail Client', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.onPrimary,
                    fontSize: 14,
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionsCard(Meeting meeting, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.ios_share_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isMobile = width < 500;

                return Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionBtn(
                      theme: theme,
                      icon: Icons.copy_all_outlined,
                      label: 'Copy Markdown',
                      description: 'Save to clipboard',
                      onPressed: _copyToClipboard,
                    ),
                    if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 12),
                    _buildQuickActionBtn(
                      theme: theme,
                      icon: Icons.download_outlined,
                      label: 'Download MD',
                      description: 'Save as local file',
                      onPressed: () => _downloadMarkdown(meeting),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      flex: MediaQuery.of(context).size.width < 500 ? 0 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 1),
                  ),
                  child: Icon(icon, color: theme.colorScheme.onBackground, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet_outlined, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Raw Markdown Output',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: SelectableText(
                _markdownContent,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
