import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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
      drawer: _buildDrawer(context, provider, theme),
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

              // Search Bar
              Container(
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
              ),
              const SizedBox(height: 20),

              // Action Options (Record Live, Upload, Local Recorder)
              _buildActionCards(context, provider, theme),
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
        // Mode specific banners
        if (provider.apiMode == ApiMode.simulation || (provider.apiMode == ApiMode.gemini && provider.geminiApiKey.isEmpty))
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
                    provider.apiMode == ApiMode.simulation
                        ? 'Simulation Mode Active. Configure custom API or add a Gemini Key in Settings.'
                        : 'Gemini Key Missing! Please configure it in Settings to transcribe.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (provider.apiMode == ApiMode.custom)
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
                const Icon(Icons.dns_outlined, size: 16, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Custom Backend API Active: ${provider.customApiBaseUrl}',
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
    final urlController = TextEditingController(text: provider.customApiBaseUrl);
    bool obscureKey = true;
    ApiMode selectedMode = provider.apiMode;

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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Integration Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<ApiMode>(
                  value: selectedMode,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: const [
                    DropdownMenuItem(
                      value: ApiMode.simulation,
                      child: Text('Simulation / Demo Mode', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: ApiMode.gemini,
                      child: Text('Direct Gemini SDK Key', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: ApiMode.custom,
                      child: Text('Custom Backend API', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      setState(() {
                        selectedMode = mode;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (selectedMode == ApiMode.gemini) ...[
                  const Text(
                    'Gemini API Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The app uses Google Gemini API to structure transcripts. For security, your key is masked.',
                    style: TextStyle(fontSize: 12, height: 1.3, color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(height: 12),
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
                          : '💡 Input your own Gemini API Key. It is stored securely on your local device.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else if (selectedMode == ApiMode.custom) ...[
                  const Text(
                    'Custom Backend API Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Direct communication with the team\'s custom endpoints (`/transcribe` and `/generate-mom`).',
                    style: TextStyle(fontSize: 12, height: 1.3, color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Backend API Base URL',
                      hintText: 'e.g. http://10.0.2.2:8000',
                      prefixIcon: Icon(Icons.dns_outlined, size: 16),
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
                      '💡 Note: For Android Emulators, `http://10.0.2.2:port` is used to reach local servers on your host machine.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                    ),
                    child: Text(
                      '💡 Simulation mode is active. Preloaded meeting templates will be used for testing and UI showcase.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
                  apiMode: selectedMode,
                  customApiBaseUrl: urlController.text,
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

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs access to your microphone to record meeting conversations for MoM generation. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, MeetingProvider provider, ThemeData theme) {
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Drawer Header - Profile Section
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    'SB',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sahil Belchada',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'sahil.belchada@gmail.com',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Statistics Panel
          Builder(
            builder: (context) {
              Duration totalDuration = Duration.zero;
              for (var m in provider.meetings) {
                totalDuration += m.duration;
              }
              final totalHours = totalDuration.inHours;
              final totalMinutes = totalDuration.inMinutes % 60;
              final totalSeconds = totalDuration.inSeconds % 60;
              String totalStr = '';
              if (totalHours > 0) {
                totalStr = '${totalHours}h ${totalMinutes}m';
              } else if (totalMinutes > 0) {
                totalStr = '${totalMinutes}m ${totalSeconds}s';
              } else {
                totalStr = '${totalSeconds}s';
              }

              String avgStr = '0s';
              if (provider.meetings.isNotEmpty) {
                final avgMs = totalDuration.inMilliseconds ~/ provider.meetings.length;
                final avgDuration = Duration(milliseconds: avgMs);
                final avgMinutes = avgDuration.inMinutes;
                final avgSeconds = avgDuration.inSeconds % 60;
                avgStr = avgMinutes > 0 ? '${avgMinutes}m ${avgSeconds}s' : '${avgSeconds}s';
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Meeting Stats',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Total', '${provider.meetings.length}', theme),
                        _buildStatItem('Time', totalStr, theme),
                        _buildStatItem('Avg', avgStr, theme),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
          
          const SizedBox(height: 6),
          
          // Navigation Items
          ListTile(
            leading: Icon(Icons.dashboard_outlined, color: theme.colorScheme.onSurface, size: 20),
            title: Text(
              'Dashboard',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.mic_none_outlined, color: theme.colorScheme.onSurface, size: 20),
            title: Text(
              'Record Live Meeting',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              final status = await Permission.microphone.request();
              if (status.isGranted) {
                provider.startRecording(isLive: true);
                if (context.mounted) {
                  Navigator.pushNamed(context, '/recording', arguments: {'mode': 'live'});
                }
              } else {
                if (context.mounted) {
                  _showPermissionDeniedDialog(context);
                }
              }
            },
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 20),
          ),
          
          // Action / Settings Items
          ListTile(
            leading: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface, size: 20),
            title: Text(
              'Settings',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showSettingsDialog(context, provider);
            },
          ),
          
          ListTile(
            leading: Icon(
              provider.isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            title: Text(
              provider.isDarkTheme ? 'Light Theme' : 'Dark Theme',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              provider.toggleTheme();
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: theme.colorScheme.onSurface, size: 20),
            title: Text(
              'Help & Guide',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showHelpDialog(context);
            },
          ),
          
          const Spacer(),
          
          // Footer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'MoM Generator v1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: theme.colorScheme.onBackground, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'User & Integration Guide',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                '1. Direct Gemini Mode',
                'Navigate to Settings and select Direct Gemini Key. Enter your Google Gemini API key. When finishing a recording, the app makes secure calls directly to the Gemini 1.5 Flash endpoint on your device to create a structured MoM summary, participants list, decisions, and action items.',
                theme,
              ),
              const SizedBox(height: 14),
              _buildHelpSection(
                '2. Custom Backend Mode',
                'Ideal for team deployments. Select Custom Backend API in Settings and enter your team\'s base URL (e.g. http://10.0.2.2:8000 for local emulator testing). The app uploads audio records to /transcribe for voice-to-text conversion, then uses /generate-mom to format the text into structured MoM outputs.',
                theme,
              ),
              const SizedBox(height: 14),
              _buildHelpSection(
                '3. Simulation Mode',
                'Demonstrates the full application capabilities without an API connection. Pre-loaded meeting logs (Project Aurora, Sprint Planning, etc.) populate your dashboard and run simulations to demonstrate high-fidelity layouts immediately.',
                theme,
              ),
              const SizedBox(height: 14),
              _buildHelpSection(
                '4. Sharing & Exporting',
                'Export generated minutes as formatted Markdown files locally or trigger standard email clients to instantly send executive briefings directly from your platform.',
                theme,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Got it'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            height: 1.45,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, MeetingProvider provider, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final double spacing = 12.0;

        final cards = [
          _buildActionCard(
            context: context,
            title: 'Record Live',
            subtitle: 'Real-time text dictation & audio recording',
            icon: Icons.mic_none_outlined,
            theme: theme,
            onTap: () async {
              final status = await Permission.microphone.request();
              if (status.isGranted) {
                provider.startRecording(isLive: true);
                if (context.mounted) {
                  Navigator.pushNamed(context, '/recording', arguments: {'mode': 'live'});
                }
              } else {
                if (context.mounted) {
                  _showPermissionDeniedDialog(context);
                }
              }
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Upload Audio',
            subtitle: 'Transcribe pre-recorded MP3/WAV/M4A files',
            icon: Icons.file_upload_outlined,
            theme: theme,
            onTap: () async {
              final meeting = await provider.pickAndProcessAudioFile();
              if (meeting != null && context.mounted) {
                Navigator.pushNamed(context, '/transcript');
              }
            },
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards.map((card) => Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: card,
            )).toList(),
          );
        }

        return Row(
          children: cards.map((card) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: card,
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
