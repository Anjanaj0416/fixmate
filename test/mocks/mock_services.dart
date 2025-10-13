// test/mocks/mock_services.dart
// Complete Mock Services for All Test Cases
// This file contains all mock implementations for testing

import 'dart:async';
import 'dart:math';

// ============================================================================
// Mock User Credential & User Classes
// ============================================================================

class MockUser {
  final String uid;
  final String? email;
  final bool emailVerified;

  MockUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
  });
}

class MockUserCredential {
  final MockUser? user;

  MockUserCredential({this.user});
}

// ============================================================================
// Mock Document Classes
// ============================================================================

class MockDocumentSnapshot {
  final String id;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot({required this.id, Map<String, dynamic>? data})
      : _data = data;

  bool get exists => _data != null;

  Map<String, dynamic>? data() => _data;
}

// ============================================================================
// 1. Mock Authentication Service
// ============================================================================

class MockAuthService {
  final Map<String, MockUser> _users = {};
  final Map<String, String> _passwords = {};
  final Map<String, bool> _verifiedEmails = {};
  MockUser? _currentUser;

  Future<MockUserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_users.containsKey(email)) {
      throw Exception('Email already exists');
    }

    final uid =
        'user_${_users.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
    final user = MockUser(uid: uid, email: email, emailVerified: false);

    _users[email] = user;
    _passwords[email] = password;
    _verifiedEmails[email] = false;
    _currentUser = user;

    return MockUserCredential(user: user);
  }

  Future<MockUserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (!_users.containsKey(email)) {
      throw Exception('User not found');
    }

    if (_passwords[email] != password) {
      throw Exception('Invalid password');
    }

    _currentUser = _users[email];
    return MockUserCredential(user: _users[email]);
  }

  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 50));
    _currentUser = null;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (!_users.containsKey(email)) {
      throw Exception('User not found');
    }
  }

  Future<void> sendEmailVerification() async {
    await Future.delayed(Duration(milliseconds: 100));

    if (_currentUser != null && _currentUser!.email != null) {
      _verifiedEmails[_currentUser!.email!] = true;
    }
  }

  MockUser? get currentUser => _currentUser;

  void clearAll() {
    _users.clear();
    _passwords.clear();
    _verifiedEmails.clear();
    _currentUser = null;
  }
}

// ============================================================================
// 2. Mock Firestore Service
// ============================================================================

class MockFirestoreService {
  final Map<String, Map<String, MockDocumentSnapshot>> _collections = {};

  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_collections.containsKey(collection)) {
      _collections[collection] = {};
    }

    _collections[collection]![documentId] = MockDocumentSnapshot(
      id: documentId,
      data: Map<String, dynamic>.from(data),
    );
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_collections.containsKey(collection) ||
        !_collections[collection]!.containsKey(documentId)) {
      throw Exception('Document not found');
    }

    final existingData = _collections[collection]![documentId]!.data()!;
    final updatedData = Map<String, dynamic>.from(existingData);

    // Handle nested field updates (e.g., 'profile.bio')
    data.forEach((key, value) {
      if (key.contains('.')) {
        final parts = key.split('.');
        Map<String, dynamic> current = updatedData;

        for (int i = 0; i < parts.length - 1; i++) {
          if (!current.containsKey(parts[i])) {
            current[parts[i]] = {};
          }
          current = current[parts[i]] as Map<String, dynamic>;
        }

        current[parts.last] = value;
      } else {
        updatedData[key] = value;
      }
    });

    _collections[collection]![documentId] = MockDocumentSnapshot(
      id: documentId,
      data: updatedData,
    );
  }

  Future<MockDocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_collections.containsKey(collection) ||
        !_collections[collection]!.containsKey(documentId)) {
      return MockDocumentSnapshot(id: documentId, data: null);
    }

    return _collections[collection]![documentId]!;
  }

  Future<Map<String, dynamic>> getDocumentData({
    required String collection,
    required String documentId,
  }) async {
    final doc = await getDocument(
      collection: collection,
      documentId: documentId,
    );

    if (!doc.exists) {
      throw Exception('Document not found');
    }

    return doc.data()!;
  }

  Future<List<MockDocumentSnapshot>> getCollection({
    required String collection,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_collections.containsKey(collection)) {
      return [];
    }

    return _collections[collection]!.values.toList();
  }

  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (_collections.containsKey(collection)) {
      _collections[collection]!.remove(documentId);
    }
  }

  void clearData() {
    _collections.clear();
  }
}

// ============================================================================
// 3. Mock Storage Service
// ============================================================================

class MockStorageService {
  final Map<String, String> _storage = {};
  int _uploadCounter = 0;

  Future<String> uploadFile({
    required String filePath,
    required dynamic fileData,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    _uploadCounter++;
    String url = 'https://storage.mock.fixmate.com/$filePath?v=$_uploadCounter';
    _storage[filePath] = url;

    return url;
  }

  Future<void> deleteFile(String filePath) async {
    await Future.delayed(Duration(milliseconds: 50));
    _storage.remove(filePath);
  }

  String? getFileUrl(String filePath) {
    return _storage[filePath];
  }

  bool fileExists(String filePath) {
    return _storage.containsKey(filePath);
  }

  void clearStorage() {
    _storage.clear();
    _uploadCounter = 0;
  }

  int get uploadCount => _uploadCounter;
}

// ============================================================================
// 4. Mock ML Service
// ============================================================================

class MockMLService {
  final Random _random = Random();

  Future<Map<String, dynamic>> predictServiceType({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    String lowerDesc = description.toLowerCase();

    // Plumbing detection
    if (lowerDesc.contains('leak') ||
        lowerDesc.contains('pipe') ||
        lowerDesc.contains('sink') ||
        lowerDesc.contains('plumb') ||
        lowerDesc.contains('water') ||
        lowerDesc.contains('drain')) {
      return {
        'service_type': 'Plumbing',
        'confidence': 0.88 + _random.nextDouble() * 0.12,
        'status': 'success',
      };
    }

    // Electrical detection
    if (lowerDesc.contains('electric') ||
        lowerDesc.contains('elektrical') ||
        lowerDesc.contains('wire') ||
        lowerDesc.contains('wirring') ||
        lowerDesc.contains('outlet') ||
        lowerDesc.contains('circuit') ||
        lowerDesc.contains('power') ||
        lowerDesc.contains('switch')) {
      return {
        'service_type': 'Electrical',
        'confidence': 0.85 + _random.nextDouble() * 0.15,
        'status': 'success',
      };
    }

    // AC Repair detection
    if (lowerDesc.contains('ac') ||
        lowerDesc.contains('cooling') ||
        lowerDesc.contains('air condition') ||
        lowerDesc.contains('hvac')) {
      return {
        'service_type': 'AC Repair',
        'confidence': 0.90 + _random.nextDouble() * 0.10,
        'status': 'success',
      };
    }

    // Carpentry detection
    if (lowerDesc.contains('wood') ||
        lowerDesc.contains('door') ||
        lowerDesc.contains('window') ||
        lowerDesc.contains('furniture') ||
        lowerDesc.contains('carpenter')) {
      return {
        'service_type': 'Carpentry',
        'confidence': 0.82 + _random.nextDouble() * 0.18,
        'status': 'success',
      };
    }

    // Default
    return {
      'service_type': 'General Maintenance',
      'confidence': 0.60 + _random.nextDouble() * 0.15,
      'status': 'success',
    };
  }

  Future<List<Map<String, dynamic>>> predictMultipleServices({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    List<Map<String, dynamic>> predictions = [];
    String lowerDesc = description.toLowerCase();

    if (lowerDesc.contains('ac') || lowerDesc.contains('cooling')) {
      predictions.add({
        'service_type': 'AC Repair',
        'confidence': 0.75 + _random.nextDouble() * 0.10,
      });
    }

    if (lowerDesc.contains('leak') || lowerDesc.contains('pipe')) {
      predictions.add({
        'service_type': 'Plumbing',
        'confidence': 0.80 + _random.nextDouble() * 0.10,
      });
    }

    if (lowerDesc.contains('electric') || lowerDesc.contains('wire')) {
      predictions.add({
        'service_type': 'Electrical',
        'confidence': 0.78 + _random.nextDouble() * 0.12,
      });
    }

    return predictions;
  }

  Future<List<Map<String, dynamic>>> findWorkers({
    required String serviceType,
    required String location,
  }) async {
    await Future.delayed(Duration(milliseconds: 150));

    return [
      {
        'worker_id': 'HM_1234',
        'worker_name': 'John ${serviceType.split(' ')[0]}',
        'service_type': serviceType,
        'rating': 4.5,
        'location': location,
        'daily_rate': 3500,
        'is_online': true,
      },
      {
        'worker_id': 'HM_5678',
        'worker_name': 'Jane Expert',
        'service_type': serviceType,
        'rating': 4.8,
        'location': location,
        'daily_rate': 4200,
        'is_online': true,
      },
      {
        'worker_id': 'HM_9012',
        'worker_name': 'Mike Professional',
        'service_type': serviceType,
        'rating': 4.3,
        'location': location,
        'daily_rate': 3000,
        'is_online': false,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> findWorkersWithAnswers({
    required String serviceType,
    required Map<String, dynamic> answers,
    required String location,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    return [
      {
        'worker_id': 'HM_1234',
        'worker_name': 'Expert ${serviceType.split(' ')[0]}',
        'service_type': serviceType,
        'rating': 4.7,
        'location': location,
        'specialization': answers['indoor_outdoor'] ?? 'General',
        'daily_rate': 4000,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> searchWorkersWithFilters({
    required String serviceType,
    required Map<String, dynamic> filters,
  }) async {
    await Future.delayed(Duration(milliseconds: 250));

    List<Map<String, dynamic>> workers = [
      {
        'worker_id': 'HM_2345',
        'worker_name': 'Filtered Worker 1',
        'service_type': serviceType,
        'location': filters['location'],
        'rating': 4.5,
        'daily_rate': 3500,
        'is_online': true,
      },
      {
        'worker_id': 'HM_3456',
        'worker_name': 'Filtered Worker 2',
        'service_type': serviceType,
        'location': filters['location'],
        'rating': 4.8,
        'daily_rate': 4500,
        'is_online': true,
      },
    ];

    // Apply filters
    return workers.where((worker) {
      if (filters.containsKey('minRating') &&
          worker['rating'] < filters['minRating']) {
        return false;
      }
      if (filters.containsKey('minPrice') &&
          worker['daily_rate'] < filters['minPrice']) {
        return false;
      }
      if (filters.containsKey('maxPrice') &&
          worker['daily_rate'] > filters['maxPrice']) {
        return false;
      }
      if (filters.containsKey('availability') &&
          filters['availability'] == 'online' &&
          !worker['is_online']) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> analyzeWithLocation({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    // Extract location
    String? location;
    if (description.toLowerCase().contains('negombo')) {
      location = 'Negombo';
    } else if (description.toLowerCase().contains('colombo')) {
      location = 'Colombo';
    } else if (description.toLowerCase().contains('kandy')) {
      location = 'Kandy';
    }

    var prediction = await predictServiceType(description: description);
    var workers = await findWorkers(
      serviceType: prediction['service_type'],
      location: location ?? 'Colombo',
    );

    // Add distance to workers
    for (var worker in workers) {
      worker['distance_km'] = 15.5 + (workers.indexOf(worker) * 5);
    }

    return {
      'location': location ?? 'Unknown',
      'service_type': prediction['service_type'],
      'confidence': prediction['confidence'],
      'workers': workers,
    };
  }

  Future<List<Map<String, dynamic>>> generateQuestionnaire({
    required String serviceType,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (serviceType == 'Electrical') {
      return [
        {'question': 'Indoor or outdoor wiring?', 'type': 'choice'},
        {'question': 'Number of outlets needed?', 'type': 'number'},
        {'question': 'Circuit breaker issues?', 'type': 'boolean'},
        {'question': 'Voltage requirements?', 'type': 'choice'},
      ];
    } else if (serviceType == 'Plumbing') {
      return [
        {'question': 'Type of plumbing issue?', 'type': 'choice'},
        {'question': 'Is it an emergency?', 'type': 'boolean'},
        {'question': 'Location of the issue?', 'type': 'text'},
        {'question': 'How long has the issue persisted?', 'type': 'choice'},
      ];
    } else if (serviceType == 'AC Repair') {
      return [
        {'question': 'Type of AC unit?', 'type': 'choice'},
        {'question': 'Age of the unit?', 'type': 'number'},
        {'question': 'Is it cooling at all?', 'type': 'boolean'},
      ];
    }

    return [];
  }

  Future<Map<String, dynamic>> searchWorkersWithFallback({
    required String description,
    required String location,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    // Check if rare service
    if (description.toLowerCase().contains('violin') ||
        description.toLowerCase().contains('rare') ||
        description.toLowerCase().contains('unusual')) {
      return {
        'workers': [],
        'message':
            'No workers found. Try nearby areas or different service type',
        'suggestions': [
          'Expand search radius to 50km',
          'Try "Musical Instrument Repair"',
          'Browse all service categories',
          'Contact customer support for assistance',
        ],
      };
    }

    // Otherwise return normal results
    var workers = await findWorkers(
      serviceType: 'General Maintenance',
      location: location,
    );

    return {
      'workers': workers,
      'message': '',
      'suggestions': [],
    };
  }
}

// ============================================================================
// 5. Mock OpenAI Service
// ============================================================================

class MockOpenAIService {
  Future<String> analyzeImage({
    required String imageUrl,
    String? prompt,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    // Simulate AI analysis based on image URL
    if (imageUrl.contains('pipe') || imageUrl.contains('broken')) {
      return 'Plumbing issue detected - Broken water pipe. The pipe appears to have a crack causing water leakage. This is a common issue that can lead to water damage if not addressed quickly. Recommended action: Contact a licensed plumber for pipe repair or replacement. Estimated time: 2-3 hours.';
    }

    if (imageUrl.contains('electric') || imageUrl.contains('wire')) {
      return 'Electrical issue detected - Exposed wiring or faulty outlet. This could be a safety hazard. Recommended action: Contact a licensed electrician immediately.';
    }

    if (imageUrl.contains('ac') || imageUrl.contains('cooling')) {
      return 'AC unit issue detected - The air conditioning system appears to have a malfunction. Recommended action: Contact an HVAC technician for diagnosis and repair.';
    }

    return 'General maintenance issue detected. The image shows some wear and tear that may require professional attention. Please provide more details for accurate diagnosis.';
  }

  Future<String> analyzeImageQuality({
    required String imageUrl,
    required double qualityScore,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));

    if (qualityScore < 0.3) {
      return 'Image quality too low. Please upload a clearer photo for accurate analysis. Try taking a photo in better lighting and hold the camera steady.';
    } else if (qualityScore < 0.6) {
      return 'Image quality is acceptable but could be better. Based on what I can see, this appears to be a maintenance issue. For more accurate diagnosis, please upload a clearer image with better focus and lighting.';
    }

    return 'Clear image detected. Analyzing the issue in detail...';
  }

  Future<String> analyzeTextDescription({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    if (description.length < 10 ||
        description.toLowerCase() == 'fix my house' ||
        description.toLowerCase() == 'help' ||
        description.toLowerCase() == 'repair') {
      return 'What specifically needs fixing? Please provide more details such as:\n'
          '- Plumbing (leaks, clogs, pipe issues)\n'
          '- Electrical (wiring, outlets, switches)\n'
          '- Carpentry (doors, windows, furniture)\n'
          '- AC/Cooling issues\n'
          '- Or describe your issue in more detail';
    }

    return 'Thank you for the details. Let me analyze your issue and find the best workers to help you...';
  }
}

// ============================================================================
// 6. Mock Account Lockout Service
// ============================================================================

class MockAccountLockoutService {
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  void recordFailedAttempt(String email) {
    _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;

    if (_failedAttempts[email]! >= 5) {
      _lockoutUntil[email] = DateTime.now().add(Duration(minutes: 30));
    }
  }

  bool isLocked(String email) {
    if (!_lockoutUntil.containsKey(email)) return false;

    if (DateTime.now().isAfter(_lockoutUntil[email]!)) {
      _lockoutUntil.remove(email);
      _failedAttempts.remove(email);
      return false;
    }

    return true;
  }

  void resetAttempts(String email) {
    _failedAttempts.remove(email);
    _lockoutUntil.remove(email);
  }

  void clearAllLockouts() {
    _failedAttempts.clear();
    _lockoutUntil.clear();
  }
}

// ============================================================================
// 7. Mock OTP Service
// ============================================================================

class MockOTPService {
  final Map<String, String> _otpCodes = {};
  final Map<String, DateTime> _otpExpiry = {};
  final Map<String, int> _otpAttempts = {};

  Future<void> sendOTP(String phoneNumber) async {
    await Future.delayed(Duration(milliseconds: 100));

    String otp = (100000 + Random().nextInt(900000)).toString();
    _otpCodes[phoneNumber] = otp;
    _otpExpiry[phoneNumber] = DateTime.now().add(Duration(minutes: 5));
    _otpAttempts[phoneNumber] = 0;
  }

  bool verifyOTP(String phoneNumber, String otp) {
    if (!_otpCodes.containsKey(phoneNumber)) return false;

    _otpAttempts[phoneNumber] = (_otpAttempts[phoneNumber] ?? 0) + 1;

    if (_otpAttempts[phoneNumber]! > 3) {
      _otpCodes.remove(phoneNumber);
      return false;
    }

    if (DateTime.now().isAfter(_otpExpiry[phoneNumber]!)) {
      _otpCodes.remove(phoneNumber);
      return false;
    }

    return _otpCodes[phoneNumber] == otp;
  }

  bool isExpired(String phoneNumber) {
    if (!_otpExpiry.containsKey(phoneNumber)) return true;
    return DateTime.now().isAfter(_otpExpiry[phoneNumber]!);
  }

  void clearOTPData() {
    _otpCodes.clear();
    _otpExpiry.clear();
    _otpAttempts.clear();
  }
}
