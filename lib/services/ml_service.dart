// lib/services/ml_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  // Change this to your FastAPI server URL
  // For local testing: 'http://localhost:8000'
  // For production: 'https://your-server.com'
  static const String baseUrl = 'http://localhost:8000';

  /// Search for workers using ML model
  /// [description]: AI-generated problem description
  /// [location]: Customer location (city name like "colombo", "kandy", etc.)
  static Future<MLRecommendationResponse> searchWorkers({
    required String description,
    required String location,
  }) async {
    try {
      final response = await http.post(
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
      final response = await http.get(Uri.parse('$baseUrl/'));
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
  final String workerId;
  final String workerName;
  final String serviceType;
  final double rating;
  final int experienceYears;
  final int dailyWageLkr;
  final String phoneNumber;
  final String city;
  final double distanceKm;
  final double aiConfidence;
  final String bio;

  MLWorker({
    required this.workerId,
    required this.workerName,
    required this.serviceType,
    required this.rating,
    required this.experienceYears,
    required this.dailyWageLkr,
    required this.phoneNumber,
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
      rating: json['rating'].toDouble(),
      experienceYears: json['experience_years'],
      dailyWageLkr: json['daily_wage_lkr'],
      phoneNumber: json['phone_number'],
      city: json['city'],
      distanceKm: json['distance_km'].toDouble(),
      aiConfidence: json['ai_confidence'].toDouble(),
      bio: json['bio'],
    );
  }
}

class AIAnalysis {
  final List<ServicePrediction> servicePredictions;
  final String detectedLocation;
  final String timeRequirement;
  final String userInputLocation;

  AIAnalysis({
    required this.servicePredictions,
    required this.detectedLocation,
    required this.timeRequirement,
    required this.userInputLocation,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      servicePredictions: (json['service_predictions'] as List)
          .map((p) => ServicePrediction.fromList(p))
          .toList(),
      detectedLocation: json['detected_location'],
      timeRequirement: json['time_requirement'],
      userInputLocation: json['user_input_location'] ?? '',
    );
  }
}

class ServicePrediction {
  final String serviceType;
  final String confidence;

  ServicePrediction({
    required this.serviceType,
    required this.confidence,
  });

  factory ServicePrediction.fromList(List<dynamic> list) {
    return ServicePrediction(
      serviceType: list[0],
      confidence: list[1],
    );
  }
}
