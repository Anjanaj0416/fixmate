import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String? customerId;
  final String customerName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final CustomerLocation? location;
  final List<String> preferredServices;
  final CustomerPreferences preferences;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final bool verified;

  CustomerModel({
    this.customerId,
    required this.customerName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.location,
    this.preferredServices = const [],
    required this.preferences,
    this.createdAt,
    this.lastActive,
    this.verified = false,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      customerId: data['customer_id'],
      customerName: data['customer_name'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      location: data['location'] != null
          ? CustomerLocation.fromMap(data['location'])
          : null,
      preferredServices: List<String>.from(data['preferred_services'] ?? []),
      preferences: CustomerPreferences.fromMap(data['preferences'] ?? {}),
      createdAt: data['created_at']?.toDate(),
      lastActive: data['last_active']?.toDate(),
      verified: data['verified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'location': location?.toMap(),
      'preferred_services': preferredServices,
      'preferences': preferences.toMap(),
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'last_active': lastActive ?? FieldValue.serverTimestamp(),
      'verified': verified,
    };
  }
}

class CustomerLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String postalCode;
  final String address;

  CustomerLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.address,
  });

  factory CustomerLocation.fromMap(Map<String, dynamic> map) {
    return CustomerLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postal_code'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'address': address,
    };
  }
}

class CustomerPreferences {
  final double maxBudgetPerDay;
  final int maxDistanceKm;
  final bool emergencyServiceOnly;
  final List<String> preferredLanguages;
  final bool verifiedWorkersOnly;
  final bool insuranceRequired;

  CustomerPreferences({
    this.maxBudgetPerDay = 0.0,
    this.maxDistanceKm = 50,
    this.emergencyServiceOnly = false,
    this.preferredLanguages = const [],
    this.verifiedWorkersOnly = false,
    this.insuranceRequired = false,
  });

  factory CustomerPreferences.fromMap(Map<String, dynamic> map) {
    return CustomerPreferences(
      maxBudgetPerDay: (map['max_budget_per_day'] ?? 0.0).toDouble(),
      maxDistanceKm: map['max_distance_km'] ?? 50,
      emergencyServiceOnly: map['emergency_service_only'] ?? false,
      preferredLanguages: List<String>.from(map['preferred_languages'] ?? []),
      verifiedWorkersOnly: map['verified_workers_only'] ?? false,
      insuranceRequired: map['insurance_required'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'max_budget_per_day': maxBudgetPerDay,
      'max_distance_km': maxDistanceKm,
      'emergency_service_only': emergencyServiceOnly,
      'preferred_languages': preferredLanguages,
      'verified_workers_only': verifiedWorkersOnly,
      'insurance_required': insuranceRequired,
    };
  }
}
