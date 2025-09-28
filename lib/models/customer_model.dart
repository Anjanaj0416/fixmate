// lib/models/customer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String customerId;
  final String customerName;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final CustomerLocation? location;
  final List<String> preferredServices;
  final CustomerPreferences preferences;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? lastActive;

  CustomerModel({
    required this.customerId,
    required this.customerName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.location,
    this.preferredServices = const [],
    required this.preferences,
    this.verified = false,
    this.createdAt,
    this.lastActive,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CustomerModel(
      customerId: data['customer_id'] ?? '',
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
      verified: data['verified'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      lastActive: (data['last_active'] as Timestamp?)?.toDate(),
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
      'verified': verified,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'last_active': FieldValue.serverTimestamp(),
    };
  }

  CustomerModel copyWith({
    String? customerId,
    String? customerName,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    CustomerLocation? location,
    List<String>? preferredServices,
    CustomerPreferences? preferences,
    bool? verified,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      preferredServices: preferredServices ?? this.preferredServices,
      preferences: preferences ?? this.preferences,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class CustomerLocation {
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  CustomerLocation({
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory CustomerLocation.fromMap(Map<String, dynamic> map) {
    return CustomerLocation(
      address: map['address'],
      city: map['city'],
      state: map['state'],
      postalCode: map['postal_code'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  CustomerLocation copyWith({
    String? address,
    String? city,
    String? state,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) {
    return CustomerLocation(
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class CustomerPreferences {
  final List<String> preferredTimeSlots;
  final String communicationMethod;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final String language;
  final String currency;

  CustomerPreferences({
    this.preferredTimeSlots = const ['9:00 AM - 12:00 PM', '1:00 PM - 5:00 PM'],
    this.communicationMethod = 'app',
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.pushNotifications = true,
    this.language = 'English',
    this.currency = 'LKR',
  });

  factory CustomerPreferences.fromMap(Map<String, dynamic> map) {
    return CustomerPreferences(
      preferredTimeSlots: List<String>.from(map['preferred_time_slots'] ??
          ['9:00 AM - 12:00 PM', '1:00 PM - 5:00 PM']),
      communicationMethod: map['communication_method'] ?? 'app',
      emailNotifications: map['email_notifications'] ?? true,
      smsNotifications: map['sms_notifications'] ?? true,
      pushNotifications: map['push_notifications'] ?? true,
      language: map['language'] ?? 'English',
      currency: map['currency'] ?? 'LKR',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferred_time_slots': preferredTimeSlots,
      'communication_method': communicationMethod,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'push_notifications': pushNotifications,
      'language': language,
      'currency': currency,
    };
  }

  CustomerPreferences copyWith({
    List<String>? preferredTimeSlots,
    String? communicationMethod,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    String? language,
    String? currency,
  }) {
    return CustomerPreferences(
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      communicationMethod: communicationMethod ?? this.communicationMethod,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      language: language ?? this.language,
      currency: currency ?? this.currency,
    );
  }
}

// Enhanced Customer Service with additional methods
class CustomerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get customer by user ID
  static Future<CustomerModel?> getCustomerByUserId(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('customers').doc(userId).get();

      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch customer: ${e.toString()}');
    }
  }

  // Update customer profile
  static Future<void> updateCustomer(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['last_active'] = FieldValue.serverTimestamp();
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('customers').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update customer: ${e.toString()}');
    }
  }

  // Add preferred service
  static Future<void> addPreferredService(String userId, String service) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'preferred_services': FieldValue.arrayUnion([service]),
        'last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add preferred service: ${e.toString()}');
    }
  }

  // Remove preferred service
  static Future<void> removePreferredService(
      String userId, String service) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'preferred_services': FieldValue.arrayRemove([service]),
        'last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove preferred service: ${e.toString()}');
    }
  }

  // Update customer location
  static Future<void> updateLocation(
      String userId, CustomerLocation location) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'location': location.toMap(),
        'last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update location: ${e.toString()}');
    }
  }

  // Update customer preferences
  static Future<void> updatePreferences(
      String userId, CustomerPreferences preferences) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'preferences': preferences.toMap(),
        'last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update preferences: ${e.toString()}');
    }
  }

  // Verify customer
  static Future<void> verifyCustomer(String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'verified': true,
        'verified_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to verify customer: ${e.toString()}');
    }
  }

  // Get customer service requests
  static Future<List<Map<String, dynamic>>> getCustomerServiceRequests(
      String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('service_requests')
          .where('customer_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get service requests: ${e.toString()}');
    }
  }

  // Delete customer account
  static Future<void> deleteCustomer(String userId) async {
    try {
      // Note: In production, you might want to soft delete or archive instead
      await _firestore.collection('customers').doc(userId).delete();

      // Also update the user document
      await _firestore.collection('users').doc(userId).update({
        'accountType': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete customer: ${e.toString()}');
    }
  }

  // Generate unique customer ID
  static Future<String> generateCustomerId() async {
    QuerySnapshot customerCount =
        await _firestore.collection('customers').get();
    int count = customerCount.docs.length + 1;
    String customerId = 'CUST_${count.toString().padLeft(4, '0')}';

    while (await _customerIdExists(customerId)) {
      count++;
      customerId = 'CUST_${count.toString().padLeft(4, '0')}';
    }

    return customerId;
  }

  static Future<bool> _customerIdExists(String customerId) async {
    QuerySnapshot existing = await _firestore
        .collection('customers')
        .where('customer_id', isEqualTo: customerId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Save new customer
  static Future<void> saveCustomer(
      CustomerModel customer, String userId) async {
    try {
      await _firestore
          .collection('customers')
          .doc(userId)
          .set(customer.toFirestore());

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'accountType': 'customer',
        'customerId': customer.customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save customer profile: ${e.toString()}');
    }
  }
}
