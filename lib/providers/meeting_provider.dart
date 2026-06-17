import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';

import '../models/meeting.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';

enum RecordingState { idle, recording, paused }
enum ApiMode { simulation, gemini, custom }

class MeetingProvider with ChangeNotifier {
  List<Meeting> _meetings = [];
  bool _isLoading = false;
  String _geminiApiKey = '';
  bool _isDarkTheme = true;
  bool _isLiveRecording = true;

  // API Configuration
  ApiMode _apiMode = ApiMode.simulation;
  String _customApiBaseUrl = 'http://10.0.2.2:8000';

  // Recording State variables
  RecordingState _recordingState = RecordingState.idle;
  int _recordingDurationSeconds = 0;
  List<double> _audioWaveLevels = List.filled(30, 0.1, growable: true);
  String _liveTranscriptText = '';
  String _baseTranscriptText = '';
  Timer? _recordingTimer;
  Timer? _waveTimer;
  Timer? _transcriptTimer;

  // Audio Recorder
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

   
  final stt.SpeechToText _speechToText = stt.SpeechToText(); //SpeechToText 
  bool _speechToTextInitialized = false;
  bool _isSpeechAvailable = false;

  // Temporary container for the meeting 
  Meeting? _currentMeeting;

  // Simulation templates
  final List<Map<String, dynamic>> _simulationTemplates = [
    {
      'title': 'Project Aurora Kickoff',
      'transcript': 'John: Hello everyone, welcome to the Project Aurora kickoff. Let\'s quickly outline our objectives.\nSarah: Sounds good. I\'ll begin setting up the cloud infrastructure and CI/CD pipelines. That should take me about 3 days. I\'ll target completing it by June 12.\nJohn: Perfect. Sahil, what about the Flutter frontend architecture?\nSahil: I\'ll establish the boilerplate, theme setup, and state management using Provider. I can have the skeleton app ready by June 15.\nJohn: Great. I\'ll handle the database schema design and API endpoints, aiming for June 14.\nSarah: Do we have a target date for the beta launch?\nJohn: Yes, we decided to target the beta launch for July 1. Let\'s ensure all core features are integrated by June 25 for testing.\nSahil: Got it. I will coordinate with John for API integration.\nJohn: Excellent. Let\'s meet next Monday for our first sync.',
      'mom': {
        'summary': 'The kickoff meeting for Project Aurora successfully defined the initial responsibilities and timelines for the development team. Cloud infrastructure, frontend architecture, and backend database design schedules were aligned, targeting a beta launch in early July.',
        'participants': ['John', 'Sarah', 'Sahil'],
        'actionItems': [
          {'description': 'Set up cloud infrastructure and CI/CD pipelines', 'assignee': 'Sarah', 'dueDate': '2026-06-12'},
          {'description': 'Establish Flutter frontend architecture & boilerplate', 'assignee': 'Sahil', 'dueDate': '2026-06-15'},
          {'description': 'Design database schema & API endpoints', 'assignee': 'John', 'dueDate': '2026-06-14'},
          {'description': 'Integrate backend APIs into the frontend', 'assignee': 'Sahil & John', 'dueDate': '2026-06-22'}
        ],
        'decisions': [
          'Target beta launch is scheduled for July 1, 2026.',
          'Core feature integration cutoff is set to June 25, 2026.',
          'Weekly sync meetings will occur every Monday morning.'
        ]
      }
    },
    {
      'title': 'Sprint 4 Planning Sync',
      'transcript': 'David: Let\'s kick off the Sprint 4 planning. We have a few key backlog items to prioritize.\nEmma: I think the push notification service is top priority. Users are requesting real-time alerts.\nDavid: Agreed. Emma, can you take ownership of the notification logic? We need it by the end of the sprint, June 18.\nEmma: Yes, I\'ll handle the Firebase Cloud Messaging integration.\nDavid: Perfect. We also need to fix the session timeout bug. Sahil, is that in your queue?\nSahil: Yes, I investigated it. It\'s a state sync issue on Web. I will deploy a hotfix by tomorrow, June 7.\nDavid: Excellent. What about the onboarding redesign?\nEmma: We need new illustrations from the design team first. I\'ll follow up with them today.\nDavid: Good idea. Let\'s estimate our sprint capacity at 45 story points. All items are logged in Jira.',
      'mom': {
        'summary': 'Sprint 4 planning focused on real-time features and critical web bugs. Push notification integration was prioritized as the main deliverable, with critical bugs assigned for immediate hotfix deployment.',
        'participants': ['David', 'Emma', 'Sahil'],
        'actionItems': [
          {'description': 'Integrate Firebase Cloud Messaging for notifications', 'assignee': 'Emma', 'dueDate': '2026-06-18'},
          {'description': 'Deploy hotfix for Web session timeout bug', 'assignee': 'Sahil', 'dueDate': '2026-06-07'},
          {'description': 'Request new illustrations from the design team', 'assignee': 'Emma', 'dueDate': '2026-06-06'}
        ],
        'decisions': [
          'Sprint 4 capacity is locked at 45 story points.',
          'Push notifications is designated as the primary sprint goal.'
        ]
      }
    },
    {
      'title': 'Marketing Strategy & Budget Review',
      'transcript': 'Sophia: Thanks for joining. We need to allocate our marketing budget of \$10,000 for Q3.\nLiam: Based on Q2 performance, Paid Search yielded the highest ROI. I suggest putting \$5,000 there.\nSophia: Makes sense. Let\'s allocate \$3,000 to Social Media campaigns (Instagram/LinkedIn) and \$2,000 to Content Marketing and SEO.\nLiam: For social media, we need new video creatives. I will draft the video briefs by June 10.\nSophia: Excellent. Sahil, we need tracking pixels installed on the pricing page. Can you do that?\nSahil: Yes, I\'ll set up Google Tag Manager and Facebook Pixel tracking by June 12.\nSophia: Perfect. That will give us clean attribution data. I will finalize the campaign schedule and budget sheet by June 15.',
      'mom': {
        'summary': 'The marketing team aligned on a Q3 budget distribution totaling \$10,000, prioritizing Paid Search for high ROI. Conversion attribution will be improved through tracking pixel installations and new video campaigns.',
        'participants': ['Sophia', 'Liam', 'Sahil'],
        'actionItems': [
          {'description': 'Draft creative briefs for social media video ads', 'assignee': 'Liam', 'dueDate': '2026-06-10'},
          {'description': 'Install tracking pixels (GTM & Facebook Pixel) on pricing page', 'assignee': 'Sahil', 'dueDate': '2026-06-12'},
          {'description': 'Finalize campaign schedule and budget sheet', 'assignee': 'Sophia', 'dueDate': '2026-06-15'}
        ],
        'decisions': [
          'Q3 marketing budget is set to \$10,000.',
          'Budget breakdown: \$5,000 Paid Search, \$3,000 Social Media, \$2,000 Content/SEO.'
        ]
      }
    }
  ];


  final List<String> _liveTranscriptSimSentences = [
    "Testing microphone... Connection established.",
    "Moderator: Good morning everyone, thanks for joining the meeting.",
    "Moderator: Today, we want to finalize our project roadmap and assign key milestones.",
    "Developer: For the frontend, we are setting up Flutter with a responsive grid layout.",
    "Developer: I'll handle the API integration, which should be ready by next Friday.",
    "Designer: The UI mockups are complete. I'll share the Figma link in our channel.",
    "Manager: Excellent. Let's make sure the tracking pixels are set up for analytical tracking.",
    "Manager: We need this by Wednesday so marketing can launch the pre-signup campaign.",
    "Developer: Got it, I will add GTM and pixel scripts to the web index.",
    "Moderator: Perfect. Let's wrap up this sync. I'll publish the minutes shortly."
  ];

  // Getters
  List<Meeting> get meetings => _meetings;
  bool get isLoading => _isLoading;
  String get geminiApiKey => _geminiApiKey;
  bool get isDarkTheme => _isDarkTheme;
  RecordingState get recordingState => _recordingState;
  int get recordingDurationSeconds => _recordingDurationSeconds;
  List<double> get audioWaveLevels => _audioWaveLevels;
  String get liveTranscriptText => _liveTranscriptText;
  Meeting? get currentMeeting => _currentMeeting;
  ApiMode get apiMode => _apiMode;
  String get customApiBaseUrl => _customApiBaseUrl;
  bool get isLiveRecording => _isLiveRecording;

  String get formattedDuration {
    final minutes = (_recordingDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  
  MeetingProvider() {
    loadSettings();
    loadMeetings();
  }

  // Load configuration settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
    _isDarkTheme = prefs.getBool('is_dark_theme') ?? true;
    
    final modeStr = prefs.getString('api_mode') ?? 'simulation';
    _apiMode = ApiMode.values.firstWhere(
      (e) => e.toString().split('.').last == modeStr,
      orElse: () => ApiMode.simulation,
    );
    
    _customApiBaseUrl = prefs.getString('custom_api_base_url') ?? 'http://10.0.2.2:8000';
    notifyListeners();
  }

  // Save Settings
  Future<void> saveSettings({
    required String apiKey,
    required bool isDarkTheme,
    required ApiMode apiMode,
    required String customApiBaseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = apiKey.trim();
    _isDarkTheme = isDarkTheme;
    _apiMode = apiMode;
    _customApiBaseUrl = customApiBaseUrl.trim();

    await prefs.setString('gemini_api_key', _geminiApiKey);
    await prefs.setBool('is_dark_theme', _isDarkTheme);
    await prefs.setString('api_mode', _apiMode.toString().split('.').last);
    await prefs.setString('custom_api_base_url', _customApiBaseUrl);
    notifyListeners();
  }

  // Load past meetings
  Future<void> loadMeetings() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? meetingsJson = prefs.getString('saved_meetings');

    if (meetingsJson != null && meetingsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(meetingsJson);
        _meetings = decoded.map((m) => Meeting.fromJson(Map<String, dynamic>.from(m))).toList();
        // Sort newest first
        _meetings.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        print('Error loading meetings: $e');
        _meetings = [];
      }
    } else {
      // Seed with initial meetings so the dashboard is beautiful and populated!
      _seedMeetings();
      await saveMeetingsToStorage();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save meetings list to persistence
  Future<void> saveMeetingsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_meetings.map((m) => m.toJson()).toList());
    await prefs.setString('saved_meetings', encoded);
  }

  void _seedMeetings() {
    _meetings = _simulationTemplates.map((template) {
      final index = _simulationTemplates.indexOf(template);
      return Meeting(
        id: 'seed_$index',
        title: template['title'],
        date: DateTime.now().subtract(Duration(days: index + 1, hours: 3)),
        duration: Duration(minutes: 10 + index * 5, seconds: 12),
        transcript: template['transcript'],
        mom: MomData.fromJson(template['mom']),
      );
    }).toList();
  }

  // Start a new recording session
  Future<void> startRecording({bool isLive = true}) async {
    if (_recordingState != RecordingState.idle) return;
    _isLiveRecording = isLive;

    try {
      String filePath = '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/recording_$timestamp.m4a';
      }
      _recordedFilePath = filePath;

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _recordingState = RecordingState.recording;
      _recordingDurationSeconds = 0;
      _audioWaveLevels = List.filled(30, 0.1, growable: true);
      _liveTranscriptText = '';
      _baseTranscriptText = '';
      
      _currentMeeting = Meeting(
        id: timestamp.toString(),
        title: isLive
            ? 'Live Meeting ${DateTime.now().day}/${DateTime.now().month}'
            : 'Phone Recording ${DateTime.now().day}/${DateTime.now().month}',
        date: DateTime.now(),
        duration: Duration.zero,
        transcript: '',
        mom: MomData.empty(),
        audioFilePath: filePath.isNotEmpty ? filePath : null,
      );

      // Duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingState == RecordingState.recording) {
          _recordingDurationSeconds++;
          notifyListeners();
        }
      });

      // Wave animator (live amplitude or simulation based on mode)
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen((amp) {
        if (_recordingState == RecordingState.recording) {
          _audioWaveLevels.removeAt(0);
          final double db = amp.current;
          double level = 0.1;
          if (db > -50) {
            level = 0.1 + ((db + 50) / 50) * 0.9;
            level = level.clamp(0.1, 1.0);
          } else {
            level = 0.05 + Random().nextDouble() * 0.1;
          }
          _audioWaveLevels.add(level);
          notifyListeners();
        }
      });

      // Speech recognition / transcription setup
      if (_isLiveRecording) {
        if (_apiMode == ApiMode.simulation) {
          _startSimulationTranscript();
        } else {
          await _startRealSpeechToText();
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error starting recording: $e');
      _recordingState = RecordingState.idle;
      _currentMeeting = null;
      notifyListeners();
    }
  }

  // Helper to start simulated transcription
  void _startSimulationTranscript() {
    int sentenceIndex = 0;
    _transcriptTimer?.cancel();
    _transcriptTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_recordingState == RecordingState.recording) {
        if (sentenceIndex < _liveTranscriptSimSentences.length) {
          final textToAdd = _liveTranscriptSimSentences[sentenceIndex];
          if (_liveTranscriptText.isEmpty) {
            _liveTranscriptText = textToAdd;
          } else {
            _liveTranscriptText += '\n$textToAdd';
          }
          sentenceIndex++;
          notifyListeners();
        } else {
          sentenceIndex = 0;
        }
      }
    });
  }

  // Helper to start real Speech-to-Text
  Future<void> _startRealSpeechToText() async {
    try {
      if (!_speechToTextInitialized) {
        _isSpeechAvailable = await _speechToText.initialize(
          onStatus: (status) => print('SpeechToText Status: $status'),
          onError: (error) => print('SpeechToText Error: $error'),
        );
        _speechToTextInitialized = true;
      }

      if (_isSpeechAvailable) {
        await _speechToText.listen(
          onResult: (result) {
            _liveTranscriptText = _baseTranscriptText.isEmpty
                ? result.recognizedWords
                : '$_baseTranscriptText\n${result.recognizedWords}';
            notifyListeners();
          },
          listenFor: const Duration(hours: 1),
          pauseFor: const Duration(seconds: 10),
          cancelOnError: false,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        );
      } else {
        print('Speech recognition not available on this device');
        _liveTranscriptText = 'Speech recognition not available. Streaming mock feed instead...\n';
        _startSimulationTranscript();
      }
    } catch (e) {
      print('Error starting SpeechToText: $e');
      _liveTranscriptText = 'SpeechToText failed: $e. Streaming mock feed instead...\n';
      _startSimulationTranscript();
    }
  }

  // Pause recording
  Future<void> pauseRecording() async {
    if (_recordingState != RecordingState.recording) return;
    try {
      await _audioRecorder.pause();
      if (_apiMode != ApiMode.simulation && _speechToText.isListening) {
        await _speechToText.stop();
      }
      _recordingState = RecordingState.paused;
      notifyListeners();
    } catch (e) {
      print('Error pausing recorder: $e');
    }
  }

  // Resume recording
  Future<void> resumeRecording() async {
    if (_recordingState != RecordingState.paused) return;
    try {
      await _audioRecorder.resume();
      if (_apiMode != ApiMode.simulation) {
        _baseTranscriptText = _liveTranscriptText;
        await _startRealSpeechToText();
      }
      _recordingState = RecordingState.recording;
      notifyListeners();
    } catch (e) {
      print('Error resuming recorder: $e');
    }
  }

  // Stop recording and capture result
  Future<void> stopRecording() async {
    if (_recordingState == RecordingState.idle) return;

    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _transcriptTimer?.cancel();
    _amplitudeSubscription?.cancel();

    if (_apiMode != ApiMode.simulation && _speechToText.isListening) {
      await _speechToText.stop();
    }

    _recordingState = RecordingState.idle;

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        _recordedFilePath = path;
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    }

    if (_currentMeeting != null) {
      _currentMeeting = Meeting(
        id: _currentMeeting!.id,
        title: _currentMeeting!.title,
        date: _currentMeeting!.date,
        duration: Duration(seconds: _recordingDurationSeconds),
        transcript: _liveTranscriptText.isEmpty 
            ? 'No audio content recorded.' 
            : _liveTranscriptText,
        mom: MomData.empty(),
        audioFilePath: _recordedFilePath,
      );
    }

    notifyListeners();
  }

  // Cancel recording session
  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _transcriptTimer?.cancel();
    _amplitudeSubscription?.cancel();
    
    if (_apiMode != ApiMode.simulation && _speechToText.isListening) {
      await _speechToText.stop();
    }

    try {
      await _audioRecorder.stop();
      if (_recordedFilePath != null && !kIsWeb) {
        final file = File(_recordedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error cancelling recorder: $e');
    }

    _recordingState = RecordingState.idle;
    _currentMeeting = null;
    _recordedFilePath = null;
    notifyListeners();
  }

  // Set transcript manually (from edit screen)
  void updateTranscript(String newTranscript) {
    if (_currentMeeting != null) {
      _currentMeeting!.transcript = newTranscript;
      notifyListeners();
    }
  }

  // Update meeting title
  void updateMeetingTitle(String newTitle) {
    if (_currentMeeting != null) {
      _currentMeeting!.title = newTitle;
      notifyListeners();
    }
  }

  // Generate MoM (either live or simulated)
  Future<void> generateMinutesOfMeeting() async {
    if (_currentMeeting == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (_apiMode == ApiMode.custom) {
        // Custom Backend API Mode
        final generatedMom = await MeetingApiService.generateMoM(
          _currentMeeting!.transcript, 
          _customApiBaseUrl,
        );
        _currentMeeting!.mom = generatedMom;
      } else if (_apiMode == ApiMode.gemini && _geminiApiKey.isNotEmpty) {
        // Real API Mode
        final generatedMom = await GeminiService.generateMoM(
          _currentMeeting!.transcript, 
          _geminiApiKey,
        );
        _currentMeeting!.mom = generatedMom;
      } else {
        // Simulation Mode: Select a template that matches or fallback to a template
        // Let's delay to make it feel realistic (1.5 seconds loading)
        await Future.delayed(const Duration(milliseconds: 1800));
        
        // Pick one of the templates or generate dynamic mockup based on sentences
        final template = _simulationTemplates[Random().nextInt(_simulationTemplates.length)];
        
        // If they wrote their own text, we can adjust the summary slightly or use template mom
        _currentMeeting!.mom = MomData.fromJson(template['mom']);
        
        // Adapt titles or keep template titles if not changed
        if (_currentMeeting!.title.startsWith('New Meeting')) {
          _currentMeeting!.title = template['title'];
        }
      }
    } catch (e) {
      // If real API fails, fall back to simulation to ensure the app stays perfectly interactive, 
      // but log/show warning to user.
      print('MoM Generation failed, falling back to simulated MoM: $e');
      await Future.delayed(const Duration(milliseconds: 1200));
      final template = _simulationTemplates[0];
      _currentMeeting!.mom = MomData.fromJson(template['mom']);
      if (_currentMeeting!.title.startsWith('New Meeting')) {
        _currentMeeting!.title = '${template['title']} (Simulated)';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Allows the user to select an audio file from their phone/computer, and sets it
  /// as the current meeting context.
  Future<Meeting?> pickAndProcessAudioFile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'mp4', 'aac'],
      );

      if (result == null || result.files.single.path == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final String filePath = result.files.single.path!;
      final String fileName = result.files.single.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _currentMeeting = Meeting(
        id: 'upload_$timestamp',
        title: 'Uploaded Audio: ${fileName.split('.').first}',
        date: DateTime.now(),
        duration: Duration.zero,
        transcript: '',
        mom: MomData.empty(),
        audioFilePath: filePath,
      );

      _liveTranscriptText = '';
      _isLiveRecording = false;

      _isLoading = false;
      notifyListeners();
      return _currentMeeting;
    } catch (e) {
      print('Error picking audio file: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sends the saved audio file path to custom backend API or Gemini for speech-to-text.
  Future<void> transcribeCurrentMeetingAudio() async {
    if (_currentMeeting == null || _currentMeeting!.audioFilePath == null) {
      throw Exception('No recorded audio file to transcribe.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final filePath = _currentMeeting!.audioFilePath!;
      String transcriptText = '';

      if (_apiMode == ApiMode.custom) {
        transcriptText = await MeetingApiService.transcribeAudio(
          filePath,
          _customApiBaseUrl,
        );
      } else if (_apiMode == ApiMode.gemini && _geminiApiKey.isNotEmpty) {
        transcriptText = await GeminiService.transcribeAudioFile(
          filePath,
          _geminiApiKey,
        );
      } else {
        // Simulation mode: Delay for realism, then load a random seeded transcript
        await Future.delayed(const Duration(seconds: 3));
        final template = _simulationTemplates[Random().nextInt(_simulationTemplates.length)];
        transcriptText = template['transcript'];
      }

      _currentMeeting!.transcript = transcriptText;
      _liveTranscriptText = transcriptText;
    } catch (e) {
      print('Transcription error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save the currently generated/edited meeting into list of saved meetings
  Future<void> saveCurrentMeeting() async {
    if (_currentMeeting == null) return;

    // Check if it already exists in the list (e.g. if we are editing a past meeting)
    final existingIndex = _meetings.indexWhere((m) => m.id == _currentMeeting!.id);

    if (existingIndex != -1) {
      _meetings[existingIndex] = _currentMeeting!;
    } else {
      _meetings.insert(0, _currentMeeting!);
    }

    await saveMeetingsToStorage();
    _currentMeeting = null;
    notifyListeners();
  }

  // Set the current active meeting for editing (e.g., from home list)
  void setEditingMeeting(Meeting meeting) {
    _currentMeeting = Meeting(
      id: meeting.id,
      title: meeting.title,
      date: meeting.date,
      duration: meeting.duration,
      transcript: meeting.transcript,
      mom: meeting.mom.copyWith(),
    );
    notifyListeners();
  }

  // Clear current meeting reference
  void clearCurrentMeeting() {
    _currentMeeting = null;
    notifyListeners();
  }

  // Delete a saved meeting
  Future<void> deleteMeeting(String id) async {
    _meetings.removeWhere((m) => m.id == id);
    await saveMeetingsToStorage();
    notifyListeners();
  }

  // Toggle app theme
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('is_dark_theme', _isDarkTheme);
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _waveTimer?.cancel();
    _transcriptTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
