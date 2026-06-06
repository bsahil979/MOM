import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/meeting_provider.dart';
import '../models/meeting.dart';

class MomEditorScreen extends StatefulWidget {
  const MomEditorScreen({super.key});

  @override
  State<MomEditorScreen> createState() => _MomEditorScreenState();
}

class _MomEditorScreenState extends State<MomEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers for editing
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _participantInputController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final provider = Provider.of<MeetingProvider>(context, listen: false);
    final meeting = provider.currentMeeting;
    
    _titleController = TextEditingController(text: meeting?.title ?? '');
    _summaryController = TextEditingController(text: meeting?.mom.summary ?? '');
    _participantInputController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _participantInputController.dispose();
    super.dispose();
  }

  void _saveChanges(MeetingProvider provider) {
    if (provider.currentMeeting == null) return;
    
    provider.currentMeeting!.title = _titleController.text;
    provider.currentMeeting!.mom.summary = _summaryController.text;
    
    provider.notifyListeners();
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
        title: const Text('Edit MoM'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: theme.colorScheme.onBackground,
          unselectedLabelColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Edit Details'),
            Tab(icon: Icon(Icons.preview_outlined, size: 20), text: 'Report Preview'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, size: 20),
            tooltip: 'Save MoM',
            onPressed: () {
              _saveChanges(provider);
              provider.saveCurrentMeeting();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share MoM',
            onPressed: () {
              _saveChanges(provider);
              Navigator.pushNamed(context, '/share');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Edit Details
            _buildEditTab(meeting, provider, theme),
            
            // Tab 2: Preview Mode
            _buildPreviewTab(meeting, provider, theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () {
          _saveChanges(provider);
          Navigator.pushNamed(context, '/share');
        },
        icon: const Icon(Icons.send_outlined, size: 18),
        label: const Text('Share & Export', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEditTab(Meeting meeting, MeetingProvider provider, ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Details
          _buildCard(
            theme: theme,
            title: 'Meeting Details',
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Meeting Title',
                    prefixIcon: Icon(Icons.title_outlined, size: 16),
                  ),
                  onChanged: (val) => meeting.title = val,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(meeting.date),
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${meeting.duration.inMinutes}m ${meeting.duration.inSeconds % 60}s',
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Executive Summary
          _buildCard(
            theme: theme,
            title: 'Summary',
            child: TextField(
              controller: _summaryController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter executive summary...',
              ),
              onChanged: (val) => meeting.mom.summary = val,
            ),
          ),
          const SizedBox(height: 20),

          // Participants Chips
          _buildCard(
            theme: theme,
            title: 'Attendees',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _participantInputController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Add attendee...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              meeting.mom.participants.add(val.trim());
                              _participantInputController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final val = _participantInputController.text;
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            meeting.mom.participants.add(val.trim());
                            _participantInputController.clear();
                          });
                        }
                      },
                      child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: meeting.mom.participants.map((name) {
                    return InputChip(
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(color: theme.colorScheme.onBackground),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                      onDeleted: () {
                        setState(() {
                          meeting.mom.participants.remove(name);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Decisions
          _buildCard(
            theme: theme,
            title: 'Decisions Made',
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meeting.mom.decisions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: meeting.mom.decisions[index]),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter decision...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                prefixIcon: Icon(Icons.check, color: theme.colorScheme.primary, size: 16),
                              ),
                              onChanged: (val) {
                                meeting.mom.decisions[index] = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 18),
                            onPressed: () {
                              setState(() {
                                meeting.mom.decisions.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onBackground,
                    side: BorderSide(color: theme.dividerColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      meeting.mom.decisions.add('');
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Decision', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Items
          _buildCard(
            theme: theme,
            title: 'Action Items',
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meeting.mom.actionItems.length,
                  itemBuilder: (context, index) {
                    final item = meeting.mom.actionItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(text: item.description),
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'Action Task',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (val) => item.description = val,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      meeting.mom.actionItems.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(text: item.assignee),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Assignee',
                                      prefixIcon: Icon(Icons.person_outline, size: 14),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (val) => item.assignee = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(text: item.dueDate),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Timeline',
                                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 14),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (val) => item.dueDate = val,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onBackground,
                    side: BorderSide(color: theme.dividerColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      meeting.mom.actionItems.add(ActionItem(
                        description: '',
                        assignee: '',
                        dueDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Action Item', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(Meeting meeting, MeetingProvider provider, ThemeData theme) {
    final formattedDate = DateFormat('MMMM dd, yyyy').format(meeting.date);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimalistic Document Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFFICIAL MINUTES OF MEETING',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      meeting.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Date: $formattedDate', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                        const SizedBox(width: 14),
                        Text('•', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 14),
                        Text(
                          'Duration: ${meeting.duration.inMinutes}m ${meeting.duration.inSeconds % 60}s',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 36, thickness: 1.5),

              // Executive Summary
              _buildSectionTitle(theme, '1. Summary Objectives', Icons.summarize_outlined),
              const SizedBox(height: 8),
              Text(
                meeting.mom.summary.isNotEmpty ? meeting.mom.summary : 'No summary provided.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Participants
              _buildSectionTitle(theme, '2. Attendees', Icons.people_outline),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meeting.mom.participants.isNotEmpty
                    ? meeting.mom.participants.map((name) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.dividerColor, width: 1),
                          ),
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList()
                    : [Text('No participants listed.', style: theme.textTheme.bodyMedium)],
              ),
              const SizedBox(height: 28),

              // Key Decisions
              _buildSectionTitle(theme, '3. Key Decisions', Icons.gavel_outlined),
              const SizedBox(height: 10),
              meeting.mom.decisions.isNotEmpty
                  ? Column(
                      children: meeting.mom.decisions
                          .where((d) => d.trim().isNotEmpty)
                          .map((decision) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  decision,
                                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Text('No decisions recorded.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 28),

              // Action Items Table
              _buildSectionTitle(theme, '4. Deliverables & Owners', Icons.playlist_add_check_outlined),
              const SizedBox(height: 12),
              meeting.mom.actionItems.isNotEmpty
                  ? Column(
                      children: [
                        // Headers
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Task / Action',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Assignee',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Due Date',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rows
                        ...meeting.mom.actionItems
                            .where((item) => item.description.trim().isNotEmpty)
                            .map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      item.assignee.isNotEmpty ? item.assignee : 'TBD',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      item.dueDate.isNotEmpty ? item.dueDate : 'TBD',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      ],
                    )
                  : Text('No action items created.', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
