// lib/services/ml_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  static const String baseUrl = 'http://localhost:8000';

  // ADDED: Static test client for dependency injection during testing
  static http.Client? _testClient;

  // ADDED: Method to inject mock client for testing
  static void setTestClient(http.Client? client) {
    _testClient = client;
  }

  // ADDED: Get the HTTP client (test or real)
  static http.Client get _client => _testClient ?? http.Client();

  /// Search for workers using ML model
  static Future<MLRecommendationResponse> searchWorkers({
    required String description,
    required String location,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': description,
          'location': location.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MLRecommendationResponse.fromJson(data);
      } else {
        throw Exception('Failed to get recommendations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to ML service: $e');
    }
  }

  /// Check if ML service is running
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class MLRecommendationResponse {
  final List<MLWorker> workers;
  final AIAnalysis aiAnalysis;

  MLRecommendationResponse({
    required this.workers,
    required this.aiAnalysis,
  });

  factory MLRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return MLRecommendationResponse(
      workers:
          (json['workers'] as List).map((w) => MLWorker.fromJson(w)).toList(),
      aiAnalysis: AIAnalysis.fromJson(json['ai_analysis']),
    );
  }
}

class MLWorker {
  final String? workerId;
  final String workerName;
  final String serviceType;
  final double rating;
  final int experienceYears;
  final int dailyWageLkr;
  final String phoneNumber;
  final String email;
  final String city;
  final double distanceKm;
  final double aiConfidence;
  final String bio;

  // ContactInfo getter for backward compatibility
  ContactInfo get contact => ContactInfo(
        phoneNumber: phoneNumber,
        email: email,
      );

  MLWorker({
    this.workerId,
    required this.workerName,
    required this.serviceType,
    required this.rating,
    required this.experienceYears,
    required this.dailyWageLkr,
    required this.phoneNumber,
    required this.email,
    required this.city,
    required this.distanceKm,
    required this.aiConfidence,
    required this.bio,
  });

  factory MLWorker.fromJson(Map<String, dynamic> json) {
    return MLWorker(
      workerId: json['worker_id'],
      workerName: json['worker_name'],
      serviceType: json['service_type'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      experienceYears: json['experience_years'] ?? 0,
      dailyWageLkr: json['daily_wage_lkr'] ?? 0,
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      aiConfidence: (json['ai_confidence'] ?? 0.0).toDouble(),
      bio: json['bio'] ?? '',
    );
  }
}

class ContactInfo {
  final String phoneNumber;
  final String email;

  ContactInfo({
    required this.phoneNumber,
    required this.email,
  });
}

class AIAnalysis {
  final List<ServicePrediction> servicePredictions;
  final String detectedService;
  final String urgencyLevel;
  final String timePreference;
  final List<String> requiredSkills;
  final double confidence;
  final String userInputLocation;

  AIAnalysis({
    required this.servicePredictions,
    required this.detectedService,
    required this.urgencyLevel,
    required this.timePreference,
    required this.requiredSkills,
    required this.confidence,
    required this.userInputLocation,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      servicePredictions: (json['service_predictions'] as List)
          .map((p) => ServicePrediction.fromJson(p))
          .toList(),
      detectedService: json['detected_service'] ?? '',
      urgencyLevel: json['urgency_level'] ?? 'normal',
      timePreference: json['time_preference'] ?? 'flexible',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      userInputLocation: json['user_input_location'] ?? '',
    );
  }
}

class ServicePrediction {
  final String serviceType;
  final double confidence;

  ServicePrediction({
    required this.serviceType,
    required this.confidence,
  });

  factory ServicePrediction.fromJson(Map<String, dynamic> json) {
    return ServicePrediction(
      serviceType: json['service_type'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}
