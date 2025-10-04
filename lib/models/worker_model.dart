// lib/models/worker_model.dart
// MODIFIED VERSION - Added profilePictureUrl field
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerModel {
  final String? workerId;
  final String workerName;
  final String firstName;
  final String lastName;
  final String serviceType;
  final String serviceCategory;
  final String businessName;
  final WorkerLocation location;
  final double rating;
  final int experienceYears;
  final int jobsCompleted;
  final double successRate;
  final WorkerPricing pricing;
  final WorkerAvailability availability;
  final WorkerCapabilities capabilities;
  final WorkerContact contact;
  final WorkerProfile profile;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final bool verified;
  final String? profilePictureUrl; // ✅ NEW FIELD

  WorkerModel({
    this.workerId,
    required this.workerName,
    required this.firstName,
    required this.lastName,
    required this.serviceType,
    required this.serviceCategory,
    required this.businessName,
    required this.location,
    this.rating = 0.0,
    this.experienceYears = 0,
    this.jobsCompleted = 0,
    this.successRate = 0.0,
    required this.pricing,
    required this.availability,
    required this.capabilities,
    required this.contact,
    required this.profile,
    this.createdAt,
    this.lastActive,
    this.verified = false,
    this.profilePictureUrl, // ✅ NEW PARAMETER
  });

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkerModel(
      workerId: data['worker_id'],
      workerName: data['worker_name'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      serviceType: data['service_type'] ?? '',
      serviceCategory: data['service_category'] ?? '',
      businessName: data['business_name'] ?? '',
      location: WorkerLocation.fromMap(data['location'] ?? {}),
      rating: (data['rating'] ?? 0.0).toDouble(),
      experienceYears: data['experience_years'] ?? 0,
      jobsCompleted: data['jobs_completed'] ?? 0,
      successRate: (data['success_rate'] ?? 0.0).toDouble(),
      pricing: WorkerPricing.fromMap(data['pricing'] ?? {}),
      availability: WorkerAvailability.fromMap(data['availability'] ?? {}),
      capabilities: WorkerCapabilities.fromMap(data['capabilities'] ?? {}),
      contact: WorkerContact.fromMap(data['contact'] ?? {}),
      profile: WorkerProfile.fromMap(data['profile'] ?? {}),
      createdAt: data['created_at']?.toDate(),
      lastActive: data['last_active']?.toDate(),
      verified: data['verified'] ?? false,
      profilePictureUrl: data['profile_picture_url'], // ✅ NEW FIELD
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'worker_id': workerId,
      'worker_name': workerName,
      'first_name': firstName,
      'last_name': lastName,
      'service_type': serviceType,
      'service_category': serviceCategory,
      'business_name': businessName,
      'location': location.toMap(),
      'rating': rating,
      'experience_years': experienceYears,
      'jobs_completed': jobsCompleted,
      'success_rate': successRate,
      'pricing': pricing.toMap(),
      'availability': availability.toMap(),
      'capabilities': capabilities.toMap(),
      'contact': contact.toMap(),
      'profile': profile.toMap(),
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'last_active': lastActive ?? FieldValue.serverTimestamp(),
      'verified': verified,
      'profile_picture_url': profilePictureUrl, // ✅ NEW FIELD
    };
  }
}

class WorkerLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String postalCode;

  WorkerLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory WorkerLocation.fromMap(Map<String, dynamic> map) {
    return WorkerLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postal_code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'postal_code': postalCode,
    };
  }
}

class WorkerPricing {
  final double dailyWageLkr;
  final double halfDayRateLkr;
  final double minimumChargeLkr;
  final double emergencyRateMultiplier;
  final double overtimeHourlyLkr;

  WorkerPricing({
    required this.dailyWageLkr,
    required this.halfDayRateLkr,
    required this.minimumChargeLkr,
    required this.emergencyRateMultiplier,
    required this.overtimeHourlyLkr,
  });

  factory WorkerPricing.fromMap(Map<String, dynamic> map) {
    return WorkerPricing(
      dailyWageLkr: (map['daily_wage_lkr'] ?? 0.0).toDouble(),
      halfDayRateLkr: (map['half_day_rate_lkr'] ?? 0.0).toDouble(),
      minimumChargeLkr: (map['minimum_charge_lkr'] ?? 0.0).toDouble(),
      emergencyRateMultiplier:
          (map['emergency_rate_multiplier'] ?? 1.0).toDouble(),
      overtimeHourlyLkr: (map['overtime_hourly_lkr'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'daily_wage_lkr': dailyWageLkr,
      'half_day_rate_lkr': halfDayRateLkr,
      'minimum_charge_lkr': minimumChargeLkr,
      'emergency_rate_multiplier': emergencyRateMultiplier,
      'overtime_hourly_lkr': overtimeHourlyLkr,
    };
  }
}

class WorkerAvailability {
  final bool availableToday;
  final bool availableWeekends;
  final bool emergencyService;
  final String workingHours;
  final int responseTimeMinutes;

  WorkerAvailability({
    required this.availableToday,
    required this.availableWeekends,
    required this.emergencyService,
    required this.workingHours,
    required this.responseTimeMinutes,
  });

  factory WorkerAvailability.fromMap(Map<String, dynamic> map) {
    return WorkerAvailability(
      availableToday: map['available_today'] ?? false,
      availableWeekends: map['available_weekends'] ?? false,
      emergencyService: map['emergency_service'] ?? false,
      workingHours: map['working_hours'] ?? '',
      responseTimeMinutes: map['response_time_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'available_today': availableToday,
      'available_weekends': availableWeekends,
      'emergency_service': emergencyService,
      'working_hours': workingHours,
      'response_time_minutes': responseTimeMinutes,
    };
  }
}

class WorkerCapabilities {
  final bool toolsOwned;
  final bool vehicleAvailable;
  final bool certified;
  final bool insurance;
  final List<String> languages;

  WorkerCapabilities({
    required this.toolsOwned,
    required this.vehicleAvailable,
    required this.certified,
    required this.insurance,
    required this.languages,
  });

  factory WorkerCapabilities.fromMap(Map<String, dynamic> map) {
    return WorkerCapabilities(
      toolsOwned: map['tools_owned'] ?? false,
      vehicleAvailable: map['vehicle_available'] ?? false,
      certified: map['certified'] ?? false,
      insurance: map['insurance'] ?? false,
      languages: List<String>.from(map['languages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tools_owned': toolsOwned,
      'vehicle_available': vehicleAvailable,
      'certified': certified,
      'insurance': insurance,
      'languages': languages,
    };
  }
}

class WorkerContact {
  final String phoneNumber;
  final bool whatsappAvailable;
  final String email;
  final String? website;

  WorkerContact({
    required this.phoneNumber,
    required this.whatsappAvailable,
    required this.email,
    this.website,
  });

  factory WorkerContact.fromMap(Map<String, dynamic> map) {
    return WorkerContact(
      phoneNumber: map['phone_number'] ?? '',
      whatsappAvailable: map['whatsapp_available'] ?? false,
      email: map['email'] ?? '',
      website: map['website'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone_number': phoneNumber,
      'whatsapp_available': whatsappAvailable,
      'email': email,
      'website': website,
    };
  }
}

class WorkerProfile {
  final String bio;
  final List<String> specializations;
  final double serviceRadiusKm;

  WorkerProfile({
    required this.bio,
    required this.specializations,
    required this.serviceRadiusKm,
  });

  factory WorkerProfile.fromMap(Map<String, dynamic> map) {
    return WorkerProfile(
      bio: map['bio'] ?? '',
      specializations: List<String>.from(map['specializations'] ?? []),
      serviceRadiusKm: (map['service_radius_km'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bio': bio,
      'specializations': specializations,
      'service_radius_km': serviceRadiusKm,
    };
  }
}
