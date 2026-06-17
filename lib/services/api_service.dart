import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';

class MeetingApiService {
  /// Uploads the recorded audio file to the backend API for transcription.
  /// Expects a JSON response containing 'transcript' or 'text'.
  static Future<String> transcribeAudio(String filePath, String baseUrl) async {
    final cleanBaseUrl = _sanitizeUrl(baseUrl);
    final url = Uri.parse('$cleanBaseUrl/transcribe');
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found at path: $filePath');
    }

    try {
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('audio', filePath));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Transcription can take time
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to transcribe audio. Server returned status code: ${response.statusCode}\nBody: ${response.body}',
        );
      }

      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final transcript = jsonMap['transcript'] ?? jsonMap['text'] ?? '';
      
      if (transcript.toString().isEmpty) {
        throw Exception('Transcription returned an empty text response.');
      }
      
      return transcript.toString();
    } catch (e) {
      print('MeetingApiService.transcribeAudio error: $e');
      rethrow;
    }
  }

  /// Sends raw transcript text to the backend API to generate Minutes of Meeting.
  /// Expects a JSON response matching the MomData schema.
  static Future<MomData> generateMoM(String transcript, String baseUrl) async {
    final cleanBaseUrl = _sanitizeUrl(baseUrl);
    final url = Uri.parse('$cleanBaseUrl/generate-mom');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': transcript}),
      ).timeout(const Duration(minutes: 2));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to generate MoM. Server returned status code: ${response.statusCode}\nBody: ${response.body}',
        );
      }

      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      return MomData.fromJson(jsonMap);
    } catch (e) {
      print('MeetingApiService.generateMoM error: $e');
      rethrow;
    }
  }

  /// Helper to clean user URL input and ensure no trailing slashes
  static String _sanitizeUrl(String url) {
    var sanitized = url.trim();
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    // Automatically prepend http:// if no scheme is specified
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = 'http://$sanitized';
    }
    return sanitized;
  }
}
