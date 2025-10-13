// test/mocks/mock_services.dart
// FIXED VERSION - All Mock Services with missing methods added
// Contains all required mock methods to fix compilation errors

import 'dart:math';

// ============================================================================
// Mock Data Models
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

  Future<MockUserCredential> signInWithEmailAndPassword({
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
    // Don't throw error for non-existent emails (security best practice)
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
// Mock Google Auth Service
// ============================================================================

class MockGoogleAuthService {
  Future<MockUserCredential?> signInWithGoogle() async {
    await Future.delayed(Duration(milliseconds: 200));

    final uid = 'google_user_${DateTime.now().millisecondsSinceEpoch}';
    final user = MockUser(
      uid: uid,
      email: 'testuser@gmail.com',
      emailVerified: true,
    );

    return MockUserCredential(user: user);
  }

  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 50));
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

    _collections[collection]![documentId] =
        MockDocumentSnapshot(id: documentId, data: data);
  }

  Future<MockDocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_collections.containsKey(collection) ||
        !_collections[collection]!.containsKey(documentId)) {
      return MockDocumentSnapshot(id: documentId, data: null);
    }

    return _collections[collection]![documentId]!;
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_collections.containsKey(collection)) {
      throw Exception('Collection not found');
    }

    if (!_collections[collection]!.containsKey(documentId)) {
      throw Exception('Document not found');
    }

    final existingData = _collections[collection]![documentId]!.data() ?? {};
    existingData.addAll(data);

    _collections[collection]![documentId] =
        MockDocumentSnapshot(id: documentId, data: existingData);
  }

  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (_collections.containsKey(collection)) {
      _collections[collection]!.remove(documentId);
    }
  }

  Future<List<MockDocumentSnapshot>> queryCollection({
    required String collection,
    Map<String, dynamic>? where,
    int? limit,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (!_collections.containsKey(collection)) {
      return [];
    }

    var docs = _collections[collection]!.values.toList();

    if (where != null) {
      docs = docs.where((doc) {
        final data = doc.data();
        if (data == null) return false;

        for (var entry in where.entries) {
          if (data[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    if (limit != null && docs.length > limit) {
      docs = docs.sublist(0, limit);
    }

    return docs;
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
      return {
        'worker_name': 'Test Worker',
        'profilePictureUrl': 'https://example.com/pic.jpg',
        'rating': 4.5,
        'serviceType': 'Plumbing',
        'experienceYears': 8,
        'pricing': {'dailyWageLkr': 5500},
        'location': {'city': 'Colombo'},
        'portfolio': ['img1.jpg', 'img2.jpg'],
        'is_online': true,
      };
    }

    return doc.data()!;
  }

  void clearData() {
    _collections.clear();
  }
}

// ============================================================================
// 3. Mock Storage Service - FIXED: Added clearStorage method
// ============================================================================

class MockStorageService {
  final Map<String, String> _files = {};

  Future<String> uploadFile({
    required String filePath,
    required dynamic fileData,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final url =
        'https://firebasestorage.googleapis.com/mock/$filePath?alt=media&token=mock_token';
    _files[filePath] = url;

    return url;
  }

  Future<void> deleteFile(String filePath) async {
    await Future.delayed(Duration(milliseconds: 50));
    _files.remove(filePath);
  }

  String? getFileUrl(String filePath) {
    return _files[filePath];
  }

  // FIXED: Added clearStorage method
  void clearStorage() {
    _files.clear();
  }

  void clearFiles() {
    _files.clear();
  }
}

// ============================================================================
// 4. Mock ML Service - FIXED: Added predictMultipleServices method
// ============================================================================

class MockMLService {
  Future<Map<String, dynamic>> predictServiceType({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    // Simple keyword matching
    final lowerDescription = description.toLowerCase();

    if (lowerDescription.contains('leak') ||
        lowerDescription.contains('pipe') ||
        lowerDescription.contains('sink')) {
      return {'service_type': 'Plumbing', 'confidence': 0.92};
    }

    if (lowerDescription.contains('electric') ||
        lowerDescription.contains('wiring') ||
        lowerDescription.contains('outlet')) {
      return {'service_type': 'Electrical', 'confidence': 0.88};
    }

    if (lowerDescription.contains('ac') ||
        lowerDescription.contains('air condition') ||
        lowerDescription.contains('cooling')) {
      return {'service_type': 'AC Repair', 'confidence': 0.90};
    }

    return {'service_type': 'General', 'confidence': 0.50};
  }

  // FIXED: Added predictMultipleServices method for handling multiple issues
  Future<List<Map<String, dynamic>>> predictMultipleServices({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    List<Map<String, dynamic>> predictions = [];
    final lowerDescription = description.toLowerCase();

    // Check for AC issues
    if (lowerDescription.contains('ac') ||
        lowerDescription.contains('air condition') ||
        lowerDescription.contains('cooling') ||
        lowerDescription.contains('not cooling')) {
      predictions.add({
        'service_type': 'AC Repair',
        'confidence': 0.75,
      });
    }

    // Check for plumbing issues
    if (lowerDescription.contains('leak') ||
        lowerDescription.contains('pipe') ||
        lowerDescription.contains('water') ||
        lowerDescription.contains('plumb')) {
      predictions.add({
        'service_type': 'Plumbing',
        'confidence': 0.80,
      });
    }

    // Check for electrical issues
    if (lowerDescription.contains('electric') ||
        lowerDescription.contains('wiring') ||
        lowerDescription.contains('wire') ||
        lowerDescription.contains('wirring')) {
      predictions.add({
        'service_type': 'Electrical',
        'confidence': 0.85,
      });
    }

    // If no specific service detected, return general
    if (predictions.isEmpty) {
      predictions.add({
        'service_type': 'General',
        'confidence': 0.50,
      });
    }

    return predictions;
  }

  Future<List<Map<String, dynamic>>> searchWorkersWithFilters({
    required String serviceType,
    required Map<String, dynamic> filters,
  }) async {
    await Future.delayed(Duration(milliseconds: 150));

    return [
      {
        'worker_id': 'HM_1001',
        'name': 'John Doe',
        'serviceType': serviceType,
        'location': filters['location'],
        'rating': 4.5,
        'daily_rate': 3500,
        'is_online': true,
      },
      {
        'worker_id': 'HM_1002',
        'name': 'Jane Smith',
        'serviceType': serviceType,
        'location': filters['location'],
        'rating': 4.8,
        'daily_rate': 4000,
        'is_online': true,
      },
    ];
  }

  Future<Map<String, dynamic>> analyzeWithLocation({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    return {
      'service_type': 'Plumbing',
      'location': 'Negombo',
      'confidence': 0.85,
      'workers': [
        {
          'worker_id': 'HM_2001',
          'name': 'Worker 1',
          'distance_km': 2.5,
        },
        {
          'worker_id': 'HM_2002',
          'name': 'Worker 2',
          'distance_km': 5.8,
        },
      ],
    };
  }

  Future<List<Map<String, dynamic>>> generateQuestionnaire({
    required String serviceType,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (serviceType == 'Electrical') {
      return [
        {'question': 'Indoor or outdoor wiring?', 'type': 'choice'},
        {'question': 'Number of outlets?', 'type': 'number'},
        {'question': 'Circuit breaker issues?', 'type': 'boolean'},
      ];
    }

    return [];
  }

  Future<Map<String, dynamic>> searchWorkersWithFallback({
    required String description,
    required String location,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    return {
      'workers': [],
      'message': 'No workers found. Try nearby areas or different service type',
      'suggestions': [
        'Try expanding search radius',
        'Search in nearby cities',
        'Try different service category',
      ],
    };
  }
}

// ============================================================================
// 5. Mock OpenAI Service - FIXED: Added analyzeTextDescription method
// ============================================================================

class MockOpenAIService {
  Future<String> analyzeImage({
    required String imageUrl,
    String? problemType,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    return 'AI Analysis: ${problemType ?? "General"} issue detected. Recommended service type: ${problemType ?? "General"}';
  }

  Future<String> analyzeImageQuality({
    required String imageUrl,
    required double qualityScore,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    if (qualityScore < 0.3) {
      return 'Image quality too low. Please upload clearer photo';
    }

    return 'Image quality acceptable. Analyzing...';
  }

  // FIXED: Added analyzeTextDescription method
  Future<String> analyzeTextDescription({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 250));

    final lowerDescription = description.toLowerCase();

    // Handle vague queries
    if (lowerDescription.contains('fix my house') ||
        lowerDescription.contains('help') && lowerDescription.length < 20) {
      return 'What specifically needs fixing? (plumbing, electrical, carpentry, etc.)';
    }

    // Handle specific queries
    if (lowerDescription.contains('leak') ||
        lowerDescription.contains('pipe')) {
      return 'It looks like you have a plumbing issue. I can help you find qualified plumbers in your area.';
    }

    if (lowerDescription.contains('electric') ||
        lowerDescription.contains('wiring')) {
      return 'This appears to be an electrical issue. Let me find electricians who can help.';
    }

    return 'AI Response: Let me analyze your issue and find the best workers to help you...';
  }

  Future<String> generateResponse({
    required String prompt,
  }) async {
    await Future.delayed(Duration(milliseconds: 250));

    return 'AI Response: Let me analyze your issue and find the best workers to help you...';
  }
}

// ============================================================================
// Mock Account Lockout Service - FIXED: Added getLockoutData alias
// ============================================================================

class MockAccountLockoutService {
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  Future<void> recordFailedLogin(String email) async {
    await Future.delayed(Duration(milliseconds: 10));
    _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;

    if (_failedAttempts[email]! >= 5) {
      _lockoutUntil[email] = DateTime.now().add(Duration(minutes: 15));
    }
  }

  bool isAccountLocked(String email) {
    if (!_lockoutUntil.containsKey(email)) return false;

    if (DateTime.now().isAfter(_lockoutUntil[email]!)) {
      _lockoutUntil.remove(email);
      _failedAttempts.remove(email);
      return false;
    }

    return true;
  }

  Map<String, dynamic>? getLockoutInfo(String email) {
    if (!isAccountLocked(email)) return null;

    return {
      'locked': true,
      'attempts': _failedAttempts[email],
      'lockedUntil': _lockoutUntil[email],
    };
  }

  // FIXED: Added getLockoutData as alias for getLockoutInfo
  Map<String, dynamic>? getLockoutData(String email) {
    return getLockoutInfo(email);
  }

  void clearAllLockouts() {
    _failedAttempts.clear();
    _lockoutUntil.clear();
  }
}

// ============================================================================
// Mock OTP Service - FIXED: Changed to positional parameters
// ============================================================================

class MockOTPService {
  final Map<String, String> _otpCodes = {};
  final Map<String, DateTime> _otpExpiry = {};
  final Map<String, int> _otpAttempts = {};

  // FIXED: Using positional parameters instead of named
  Future<String> generateOTP(String phone) async {
    await Future.delayed(Duration(milliseconds: 100));

    final otp = (Random().nextInt(900000) + 100000).toString();
    _otpCodes[phone] = otp;
    _otpExpiry[phone] = DateTime.now().add(Duration(minutes: 10));
    _otpAttempts[phone] = 0;

    return otp;
  }

  // FIXED: Using positional parameters instead of named
  Future<bool> verifyOTP(String phone, String otp) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_otpCodes.containsKey(phone)) return false;

    // Check expiry
    if (DateTime.now().isAfter(_otpExpiry[phone]!)) {
      return false;
    }

    // Check attempts
    if (_otpAttempts[phone]! >= 5) {
      return false;
    }

    if (_otpCodes[phone] == otp) {
      _otpCodes.remove(phone);
      _otpExpiry.remove(phone);
      _otpAttempts.remove(phone);
      return true;
    }

    _otpAttempts[phone] = _otpAttempts[phone]! + 1;
    return false;
  }

  // FIXED: Added isExpired as alias for isOTPExpired
  bool isExpired(String phone) {
    return isOTPExpired(phone);
  }

  bool isOTPExpired(String phone) {
    if (!_otpExpiry.containsKey(phone)) return true;
    return DateTime.now().isAfter(_otpExpiry[phone]!);
  }

  // FIXED: Added getAttempts as alias for getOTPAttempts
  int getAttempts(String phone) {
    return getOTPAttempts(phone);
  }

  int getOTPAttempts(String phone) {
    return _otpAttempts[phone] ?? 0;
  }

  void clearOTPData() {
    _otpCodes.clear();
    _otpExpiry.clear();
    _otpAttempts.clear();
  }
}
