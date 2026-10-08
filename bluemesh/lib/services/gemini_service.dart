import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/student.dart';

class GeminiMessage {
  final String sender; // 'user' | 'gemini' | 'system'
  final String text;
  final DateTime timestamp;

  GeminiMessage({
    required this.sender,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class GeminiService {
  static final GeminiService instance = GeminiService._();
  GeminiService._();

  Future<String> askGemini({
    required String prompt,
    List<Student>? students,
    List<Map<String, dynamic>>? attendanceRecords,
    List<GeminiMessage>? conversationHistory,
  }) async {
    final apiKey = EnvConfig.instance.geminiApiKey.trim();

    if (apiKey.isEmpty) {
      return '⚠️ **Gemini API Key Missing**\n\n'
          'Please set your free Google Gemini API Key in the `.env` file:\n'
          '```env\n'
          'GEMINI_API_KEY=your_gemini_api_key_here\n'
          '```\n'
          'You can get a free API key at: [Google AI Studio](https://aistudio.google.com/app/apikey). You can also tap the ⚙️ icon at the top right to enter it directly!';
    }

    // Build context summary
    final StringBuffer contextBuffer = StringBuffer();
    contextBuffer.writeln('SYSTEM CONTEXT: You are an intelligent AI Class & Attendance Assistant for the BlueMesh Smart BLE System.');

    if (students != null && students.isNotEmpty) {
      contextBuffer.writeln('\nACTIVE STUDENT ROSTER (${students.length} students):');
      for (final s in students) {
        contextBuffer.writeln('- Roll: ${s.rollNumber} | Name: ${s.name} | Section: ${s.classSection} | Email: ${s.email} | Biometric: ${s.isFingerprintRegistered ? "Registered" : "Pending"}');
      }
    }

    if (attendanceRecords != null && attendanceRecords.isNotEmpty) {
      contextBuffer.writeln('\nRECENT ATTENDANCE DATA (${attendanceRecords.length} records):');
      for (final r in attendanceRecords) {
        final roll = r['roll_number'] ?? r['rollNumber'] ?? 'Unknown';
        final status = r['status'] ?? 'N/A';
        final verified = r['fingerprint_verified'] == 1 || r['verified'] == true ? 'Yes' : 'No';
        final pct = r['attendance_percentage'] ?? '100';
        contextBuffer.writeln('- Student: $roll | Status: $status | Fingerprint Verified: $verified | Score: $pct%');
      }
    }

    // Try models in order: gemini-1.5-flash -> gemini-2.0-flash -> gemini-1.5-pro
    final models = ['gemini-1.5-flash', 'gemini-2.0-flash', 'gemini-1.5-pro'];

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final contents = <Map<String, dynamic>>[];

        // System instruction / initial context
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$contextBuffer\n\nPlease answer the user\'s inquiry concisely and helpfully based on the context.'}
          ]
        });
        contents.add({
          'role': 'model',
          'parts': [
            {'text': 'Understood. I have reviewed the BlueMesh student roster and attendance telemetry. How can I assist you with the class today?'}
          ]
        });

        // Add previous conversation
        if (conversationHistory != null) {
          for (final msg in conversationHistory.take(6)) {
            contents.add({
              'role': msg.sender == 'user' ? 'user' : 'model',
              'parts': [{'text': msg.text}],
            });
          }
        }

        // Add current prompt
        contents.add({
          'role': 'user',
          'parts': [{'text': prompt}],
        });

        final requestBody = jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        });

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? 'No text generated.';
            }
          }
        } else {
          debugPrint('Gemini model $model returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini API call failed with model $model: $e');
      }
    }

    return '⚠️ Unable to connect to Gemini API. Please check your internet connection or verify that your GEMINI_API_KEY in `.env` is valid.';
  }
}
