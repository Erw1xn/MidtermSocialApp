import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GeminiService {
  // 🔑 API KEY AND ENDPOINT: These are your credentials and the "address" of the Gemini server
  static const String apiKey = '';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // 🔄 MESSAGE FORMATTER: This function converts your app's ChatMessage list into the
  // specific JSON format (role and parts) that the Google API requires.
  static List<Map<String, dynamic>> _formatMessages(List<ChatMessage> messages) {
    return messages.map((msg) {
      return {
        'role': msg.role, // Must be 'user' or 'model'
        'parts': [{'text': msg.text}],
      };
    }).toList();
  }

  // 🚀 API CALLER: This is the main function that sends the chat history and
  // the System Prompt (Expertise) to the internet and waits for the AI response.
  static Future<String> sendMultiTurnMessage({
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) async {
    try {
      // Sending the HTTP POST request to the Google API endpoint
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': _formatMessages(conversationHistory), // The chat history
          'system_instruction': {
            'parts': [{'text': systemPrompt}] // The "Expert Rules" for the AI
          },
          'generationConfig': {
            'temperature': 0.7, // Controls creativity (0.0 is focused, 1.0 is creative)
            'maxOutputTokens': 1000, // Limits the length of the AI's answer
          }
        }),
      );

      // ✅ SUCCESS: If the server responds with 200, we extract the text reply.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      // ❌ ERROR: Handles issues like invalid keys or reaching your quota limit.
      else {
        return 'Error: ${response.statusCode}. Please check your API Key.';
      }
    } catch (e) {
      // 🌐 NETWORK ERROR: Handles internet connection issues.
      return 'Network Error: $e';
    }
  }
}