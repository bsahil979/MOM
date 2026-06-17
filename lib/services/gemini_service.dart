import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/meeting.dart';

class GeminiService {
  /// Transcribes a local audio file using Gemini.
  static Future<String> transcribeAudioFile(String filePath, String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API Key is missing. Please configure it in Settings.');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at path: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      
      final ext = filePath.split('.').last.toLowerCase();
      String mimeType = 'audio/m4a';
      if (ext == 'mp3') mimeType = 'audio/mp3';
      else if (ext == 'wav') mimeType = 'audio/wav';
      else if (ext == 'ogg') mimeType = 'audio/ogg';
      else if (ext == 'mp4') mimeType = 'audio/mp4';
      else if (ext == 'aac') mimeType = 'audio/aac';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = 'You are an expert audio transcriber. Listen to the audio and write a complete, accurate transcript of the speech. Return only the plain transcript text.';
      
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, fileBytes),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      print('Gemini Audio Transcription Error: $e');
      rethrow;
    }
  }

  /// Generates structured Minutes of Meeting (MoM) from a raw transcript.
  /// If [apiKey] is provided, it uses the official Gemini API.
  /// Otherwise, or if it fails, it returns a simulated MoM.
  static Future<MomData> generateMoM(String transcript, String? apiKey) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API Key is missing. Please configure it in Settings.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are an expert executive secretary and project manager. Analyze the following meeting transcript and generate a structured Minutes of Meeting (MoM) in JSON format.

The JSON object must strictly follow this structure:
{
  "summary": "A concise executive summary of the meeting, highlighting the main objectives and overall outcomes (2-4 sentences).",
  "participants": ["Name of Participant 1", "Name of Participant 2"],
  "actionItems": [
    {
      "description": "Specific action item detail",
      "assignee": "Name of assignee, or 'Unassigned'",
      "dueDate": "Specific date, timeline, or 'TBD'"
    }
  ],
  "decisions": [
    "Key decision 1 made during the meeting",
    "Key decision 2 made during the meeting"
  ]
}

Ensure that:
1. Participants are correctly extracted from the speakers and names mentioned.
2. Action items represent clear, concrete deliverables discussed.
3. Decisions capture agreements or conclusions reached.
4. Output ONLY valid JSON matching the schema. No markdown formatting blocks (e.g. do not wrap in ```json), no additional text outside JSON.

Transcript:
$transcript
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Received empty response from Gemini API.');
      }

      // Try parsing the JSON
      final Map<String, dynamic> jsonMap = jsonDecode(_cleanJsonResponse(responseText));
      return MomData.fromJson(jsonMap);
    } catch (e) {
      print('Gemini API Error: $e');
      rethrow;
    }
  }

  /// Clean any wrapping formatting like markdown ```json code blocks from the API output.
  static String _cleanJsonResponse(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
