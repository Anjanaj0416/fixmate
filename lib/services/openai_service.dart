// lib/services/openai_service.dart
// FIXED VERSION - Handles CORS by using backend proxy on web platform

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OpenAIService {
  static String? _apiKey;

  // IMPORTANT: Change this to your backend URL
  // For development: http://localhost:8000
  // For production: https://your-backend-url.com
  static const String BACKEND_URL = 'http://localhost:8000';

  static void initialize() {
    _apiKey = dotenv.env['OPENAI_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('⚠️ OPENAI_API_KEY not found in .env file');
      if (kIsWeb) {
        print('   Web platform will use backend proxy at $BACKEND_URL');
      } else {
        print('   Mobile/Desktop requires API key for direct access');
      }
    } else {
      print('✅ OpenAI API key loaded successfully');
    }
  }

  // ===========================================================================
  // PRIMARY METHOD: Analyze Image from XFile (works on both web and mobile)
  // ===========================================================================
  static Future<String> analyzeImageFromXFile({
    required XFile imageFile,
    String? userMessage,
  }) async {
    try {
      // Read bytes from XFile (works on both web and mobile)
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

      // PLATFORM DETECTION: Use proxy for web, direct API for mobile
      if (kIsWeb) {
        print('🌐 Web platform detected - using backend proxy');
        return await _analyzeImageViaProxy(
          base64Image: base64Image,
          mimeType: mimeType,
          userMessage: userMessage,
        );
      } else {
        print('📱 Mobile/Desktop platform detected - using direct API');
        return await _analyzeImageDirect(
          base64Image: base64Image,
          mimeType: mimeType,
          userMessage: userMessage,
        );
      }
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  // ===========================================================================
  // PROXY METHOD: Analyze via backend (for web - fixes CORS)
  // ===========================================================================
  static Future<String> _analyzeImageViaProxy({
    required String base64Image,
    required String mimeType,
    String? userMessage,
  }) async {
    try {
      final requestBody = {
        'base64_image': base64Image,
        'mime_type': mimeType,
        'user_message': userMessage ??
            'Please analyze this image and describe what you see. If this appears to be a maintenance or repair issue, provide details about what might be wrong and potential solutions.',
      };

      print('📤 Sending request to backend proxy...');
      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/openai/analyze-image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Image analysis successful via proxy');
          return data['content'];
        } else {
          throw Exception('Backend Error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Backend proxy request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Provide helpful error message
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Cannot connect to backend at $BACKEND_URL. Please ensure:\n'
            '1. Backend server is running (python main.py)\n'
            '2. Backend URL is correct in openai_service.dart\n'
            '3. OPENAI_API_KEY is set in backend environment\n\n'
            'Original error: $e');
      }
      throw Exception('Proxy request failed: $e');
    }
  }

  // ===========================================================================
  // DIRECT METHOD: Analyze via OpenAI API (for mobile - no CORS issues)
  // ===========================================================================
  static Future<String> _analyzeImageDirect({
    required String base64Image,
    required String mimeType,
    String? userMessage,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'OpenAI API key not found. Please add OPENAI_API_KEY to .env file.');
    }

    try {
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

      print('📤 Sending request directly to OpenAI API...');
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
        print('✅ Image analysis successful via direct API');
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'OpenAI API Error: ${error['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Direct API request failed: $e');
    }
  }

  // ===========================================================================
  // BACKWARD COMPATIBILITY: Analyze Image from File (mobile only)
  // ===========================================================================
  static Future<String> analyzeImage({
    required File imageFile,
    String? userMessage,
  }) async {
    // Convert File to XFile for compatibility
    final xFile = XFile(imageFile.path);
    return analyzeImageFromXFile(
      imageFile: xFile,
      userMessage: userMessage,
    );
  }

  // ===========================================================================
  // PRIMARY METHOD: Send Text Message
  // ===========================================================================
  static Future<String> sendMessage(String message) async {
    try {
      // PLATFORM DETECTION: Use proxy for web, direct API for mobile
      if (kIsWeb) {
        print('🌐 Web platform detected - using backend proxy for text');
        return await _sendMessageViaProxy(message);
      } else {
        print(
            '📱 Mobile/Desktop platform detected - using direct API for text');
        return await _sendMessageDirect(message);
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ===========================================================================
  // PROXY METHOD: Send message via backend (for web - fixes CORS)
  // ===========================================================================
  static Future<String> _sendMessageViaProxy(String message) async {
    try {
      final requestBody = {
        'message': message,
      };

      print('📤 Sending text message to backend proxy...');
      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/openai/send-message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Text message sent successfully via proxy');
          return data['content'];
        } else {
          throw Exception('Backend Error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Backend proxy request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Provide helpful error message
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Cannot connect to backend at $BACKEND_URL. Please ensure:\n'
            '1. Backend server is running (python main.py)\n'
            '2. Backend URL is correct in openai_service.dart\n'
            '3. OPENAI_API_KEY is set in backend environment\n\n'
            'Original error: $e');
      }
      throw Exception('Proxy request failed: $e');
    }
  }

  // ===========================================================================
  // DIRECT METHOD: Send message via OpenAI API (for mobile - no CORS issues)
  // ===========================================================================
  static Future<String> _sendMessageDirect(String message) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'OpenAI API key not found. Please add OPENAI_API_KEY to .env file.');
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

      print('📤 Sending text message directly to OpenAI API...');
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
        print('✅ Text message sent successfully via direct API');
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'OpenAI API Error: ${error['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Direct API request failed: $e');
    }
  }
}
