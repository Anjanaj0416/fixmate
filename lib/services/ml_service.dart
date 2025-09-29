// lib/services/ml_service.dart
// COMPLETE FIXED VERSION - Replace entire file

import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  static const String baseUrl = 'http://localhost:8000';

  /// Search for workers using ML model
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
  final String email; // Email field from dataset
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

  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'worker_name': workerName,
      'service_type': serviceType,
      'rating': rating,
      'experience_years': experienceYears,
      'daily_wage_lkr': dailyWageLkr,
      'phone_number': phoneNumber,
      'email': email,
      'city': city,
      'distance_km': distanceKm,
      'ai_confidence': aiConfidence,
      'bio': bio,
    };
  }
}

// FIXED AIAnalysis class with ALL required fields
class AIAnalysis {
  final String detectedService;
  final String urgencyLevel;
  final String timePreference;
  final List<String> requiredSkills;
  final double confidence;

  // Additional fields that were missing
  final String userInputLocation;
  final List<ServicePrediction> servicePredictions;
  final String timeRequirement;

  AIAnalysis({
    required this.detectedService,
    required this.urgencyLevel,
    required this.timePreference,
    required this.requiredSkills,
    required this.confidence,
    required this.userInputLocation,
    required this.servicePredictions,
    required this.timeRequirement,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      detectedService: json['detected_service'] ?? '',
      urgencyLevel: json['urgency_level'] ?? '',
      timePreference: json['time_preference'] ?? '',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      userInputLocation: json['user_input_location'] ?? '',
      servicePredictions: (json['service_predictions'] as List?)
              ?.map((p) => ServicePrediction.fromJson(p))
              .toList() ??
          [
            ServicePrediction(
              serviceType: json['detected_service'] ?? '',
              confidence: (json['confidence'] ?? 0.0).toDouble(),
            )
          ],
      timeRequirement:
          json['time_requirement'] ?? json['time_preference'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected_service': detectedService,
      'urgency_level': urgencyLevel,
      'time_preference': timePreference,
      'required_skills': requiredSkills,
      'confidence': confidence,
      'user_input_location': userInputLocation,
      'service_predictions': servicePredictions.map((p) => p.toJson()).toList(),
      'time_requirement': timeRequirement,
    };
  }
}

// ServicePrediction class for service predictions list
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

  Map<String, dynamic> toJson() {
    return {
      'service_type': serviceType,
      'confidence': confidence,
    };
  }
}
