import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String? _apiKey;

  static void initialize() {
    _apiKey = dotenv.env['OPENAI_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
  }

  static Future<String> analyzeImage({
    required File imageFile,
    String? userMessage,
  }) async {
    if (_apiKey == null) {
      throw Exception(
          'OpenAI service not initialized. Call initialize() first.');
    }

    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine image mime type
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      // Prepare the request body
      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': userMessage ??
                    'Please analyze this image and describe what you see. If this appears to be a maintenance or repair issue, provide details about what might be wrong and potential solutions.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 1000,
      };

      // Make API request
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'OpenAI API Error: ${error['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  static Future<String> sendMessage(String message) async {
    if (_apiKey == null) {
      throw Exception(
          'OpenAI service not initialized. Call initialize() first.');
    }

    try {
      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant for a home services marketplace app called FixMate. Help users understand their maintenance and repair issues, and provide guidance on what type of service they might need.',
          },
          {
            'role': 'user',
            'content': message,
          },
        ],
        'max_tokens': 500,
      };

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'OpenAI API Error: ${error['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
