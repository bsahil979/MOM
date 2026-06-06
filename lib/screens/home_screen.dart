import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/meeting_provider.dart';
import '../models/meeting.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MeetingProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Filter meetings based on search query
    final filteredMeetings = provider.meetings.where((meeting) {
      final query = _searchQuery.toLowerCase();
      return meeting.title.toLowerCase().contains(query) ||
          meeting.transcript.toLowerCase().contains(query) ||
          meeting.mom.summary.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined, 
              size: 20, 
              color: theme.colorScheme.onBackground
            ),
            const SizedBox(width: 8),
            Text(
              'MoM Generator',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: theme.colorScheme.onBackground,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => provider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined, 
              color: theme.colorScheme.onBackground,
              size: 20,
            ),
            tooltip: 'Settings',
            onPressed: () => _showSettingsDialog(context, provider),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildHeader(theme, provider),
              const SizedBox(height: 24),

              // Search Bar & Actions
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  
                  final searchField = Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search meetings or summaries...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );

                  final newBtn = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      provider.startRecording();
                      Navigator.pushNamed(context, '/recording');
                    },
                    icon: Icon(Icons.add, size: 18, color: theme.colorScheme.onPrimary),
                    label: Text(
                      'New Meeting',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        newBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 16),
                      newBtn,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Meetings Grid/List Header
              Text(
                'Recent Meetings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Meetings list
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : filteredMeetings.isEmpty
                        ? _buildEmptyState(theme, _searchQuery.isNotEmpty)
                        : _buildMeetingsGrid(filteredMeetings, size, provider, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, MeetingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capture audio transcripts and structure them into official meeting logs.',
          style: theme.textTheme.bodyMedium,
        ),
        if (provider.geminiApiKey.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulation Mode Active. Add a Gemini API Key in Settings for live transcribing.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.folder_open_outlined,
            size: 48,
            color: theme.colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No meetings saved yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching with different keywords.'
                : 'Click "New Meeting" to record your first conversation.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsGrid(
      List<Meeting> meetings, Size size, MeetingProvider provider, ThemeData theme) {
    final double width = size.width;
    final int crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _buildMeetingCard(meeting, provider, theme);
      },
    );
  }

  Widget _buildMeetingCard(Meeting meeting, MeetingProvider provider, ThemeData theme) {
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(meeting.date);
    final durationMinutes = meeting.duration.inMinutes;
    final durationSeconds = meeting.duration.inSeconds % 60;
    final durationStr = durationMinutes > 0
        ? '${durationMinutes}m ${durationSeconds}s'
        : '${durationSeconds}s';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          provider.setEditingMeeting(meeting);
          Navigator.pushNamed(context, '/editor');
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: theme.cardTheme.shape is RoundedRectangleBorder
                ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
                : BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meeting Title & Operations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meeting.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18, 
                        color: theme.colorScheme.error.withOpacity(0.8)
                      ),
                      tooltip: 'Delete Meeting',
                      onPressed: () => _confirmDelete(context, provider, meeting),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      durationStr,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Executive Summary snippet
                Expanded(
                  child: Text(
                    meeting.mom.summary.isNotEmpty
                        ? meeting.mom.summary
                        : 'No summary generated yet. Click to view and generate.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MeetingProvider provider, Meeting meeting) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${meeting.title}"?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () {
              provider.deleteMeeting(meeting.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, MeetingProvider provider) {
    final bool hasKey = provider.geminiApiKey.isNotEmpty;
    // Show dummy characters if key is already saved to keep it hidden
    final apiController = TextEditingController(text: hasKey ? '••••••••••••••••••••' : '');
    bool obscureKey = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onBackground, size: 20),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini API Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'The app uses Google Gemini API to structure transcripts. For security, your key is masked.',
                style: TextStyle(fontSize: 12, height: 1.3, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiController,
                obscureText: obscureKey,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 16),
                  suffixIcon: hasKey && apiController.text == '••••••••••••••••••••'
                      ? null // Don't show eye toggle if it's the dummy mask
                      : IconButton(
                          icon: Icon(obscureKey ? Icons.visibility : Icons.visibility_off, size: 16),
                          onPressed: () {
                            setState(() {
                              obscureKey = !obscureKey;
                            });
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                ),
                child: Text(
                  hasKey
                      ? '💡 A key is saved. To change it, clear the field and paste your new key.'
                      : '💡 Leave empty to use Simulation Mode with realistic pre-configured templates.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
              onPressed: () {
                final enteredText = apiController.text.trim();
                String targetKey = provider.geminiApiKey;

                if (enteredText.isEmpty) {
                  targetKey = ''; // Clear key
                } else if (enteredText != '••••••••••••••••••••') {
                  targetKey = enteredText; // Update with new key
                }

                provider.saveSettings(
                  apiKey: targetKey,
                  isDarkTheme: provider.isDarkTheme,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
