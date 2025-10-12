// lib/models/worker_model.dart
// UPDATED VERSION - Added Portfolio support
import 'package:cloud_firestore/cloud_firestore.dart';

// Add this new class for portfolio items
class PortfolioItem {
  final String imageUrl;
  final String note;
  final DateTime uploadedAt;

  PortfolioItem({
    required this.imageUrl,
    required this.note,
    required this.uploadedAt,
  });

  factory PortfolioItem.fromMap(Map<String, dynamic> data) {
    return PortfolioItem(
      imageUrl: data['image_url'] ?? '',
      note: data['note'] ?? '',
      uploadedAt: data['uploaded_at'] is Timestamp
          ? (data['uploaded_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'note': note,
      'uploaded_at': Timestamp.fromDate(uploadedAt),
    };
  }
}

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
  final String? profilePictureUrl;
  final List<PortfolioItem> portfolio; // NEW: Portfolio items

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
    this.profilePictureUrl,
    this.portfolio = const [], // NEW: Initialize portfolio
  });

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle contact data
    Map<String, dynamic> contactData;
    if (data.containsKey('contact') && data['contact'] is Map) {
      contactData = data['contact'] as Map<String, dynamic>;
    } else {
      contactData = {
        'phone_number': data['phone_number'] ?? '',
        'email': data['email'] ?? '',
        'whatsapp_available': data['whatsapp_available'] ?? false,
        'website': data['website'],
      };
    }

    // NEW: Parse portfolio items
    List<PortfolioItem> portfolioItems = [];
    if (data.containsKey('portfolio') && data['portfolio'] is List) {
      portfolioItems = (data['portfolio'] as List)
          .map((item) => PortfolioItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

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
      contact: WorkerContact.fromMap(contactData),
      profile: WorkerProfile.fromMap(data['profile'] ?? {}),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      lastActive: data['last_active'] != null
          ? (data['last_active'] as Timestamp).toDate()
          : null,
      verified: data['verified'] ?? false,
      profilePictureUrl: data['profile_picture_url'],
      portfolio: portfolioItems, // NEW: Add portfolio
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
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'last_active': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : FieldValue.serverTimestamp(),
      'verified': verified,
      'profile_picture_url': profilePictureUrl,
      'portfolio':
          portfolio.map((item) => item.toMap()).toList(), // NEW: Add portfolio
    };
  }

  WorkerModel copyWith({
    String? workerId,
    String? workerName,
    String? firstName,
    String? lastName,
    String? serviceType,
    String? serviceCategory,
    String? businessName,
    WorkerLocation? location,
    double? rating,
    int? experienceYears,
    int? jobsCompleted,
    double? successRate,
    WorkerPricing? pricing,
    WorkerAvailability? availability,
    WorkerCapabilities? capabilities,
    WorkerContact? contact,
    WorkerProfile? profile,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? verified,
    String? profilePictureUrl,
    List<PortfolioItem>? portfolio, // NEW
  }) {
    return WorkerModel(
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      serviceType: serviceType ?? this.serviceType,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      businessName: businessName ?? this.businessName,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      successRate: successRate ?? this.successRate,
      pricing: pricing ?? this.pricing,
      availability: availability ?? this.availability,
      capabilities: capabilities ?? this.capabilities,
      contact: contact ?? this.contact,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      verified: verified ?? this.verified,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      portfolio: portfolio ?? this.portfolio, // NEW
    );
  }

  String get city => location.city;
  double get dailyWageLkr => pricing.dailyWageLkr;
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
      city: map['city'] ?? map['district'] ?? '',
      state: map['state'] ?? map['district'] ?? '',
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
      overtimeHourlyLkr:
          (map['overtime_hourly_lkr'] ?? map['hourly_rate_lkr'] ?? 0.0)
              .toDouble(),
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
    // Handle working_hours as either String or Map
    String workingHoursStr = '';
    if (map['working_hours'] != null) {
      if (map['working_hours'] is String) {
        workingHoursStr = map['working_hours'];
      } else if (map['working_hours'] is Map) {
        Map hrs = map['working_hours'] as Map;
        String start = hrs['start'] ?? '08:00';
        String end = hrs['end'] ?? '18:00';
        workingHoursStr = '$start - $end';
      }
    }

    return WorkerAvailability(
      availableToday: map['available_today'] ?? false,
      availableWeekends: map['available_weekends'] ?? false,
      emergencyService: map['emergency_service'] ?? false,
      workingHours: workingHoursStr,
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

  factory WorkerCapabilities.fromMap(dynamic mapOrList) {
    // Handle capabilities as either Map or empty List
    if (mapOrList is List) {
      return WorkerCapabilities(
        toolsOwned: false,
        vehicleAvailable: false,
        certified: false,
        insurance: false,
        languages: [],
      );
    }

    Map<String, dynamic> map = mapOrList as Map<String, dynamic>;
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
    // Handle certifications if present, but map to specializations
    List<String> specs = [];
    if (map['specializations'] != null) {
      specs = List<String>.from(map['specializations']);
    } else if (map['certifications'] != null) {
      specs = List<String>.from(map['certifications']);
    }

    return WorkerProfile(
      bio: map['bio'] ?? '',
      specializations: specs,
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
