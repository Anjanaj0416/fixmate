// test/mocks/mock_services.dart
// UPDATED VERSION - Added MockQuoteService, MockBookingService, MockChatService, MockNotificationService
// Contains all required mock methods including new booking/quote/communication services

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
// 3. Mock Storage Service
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

  void clearStorage() {
    _files.clear();
  }

  void clearFiles() {
    _files.clear();
  }
}

// ============================================================================
// 4. Mock ML Service
// ============================================================================

class MockMLService {
  Future<Map<String, dynamic>> predictServiceType({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

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

  Future<List<Map<String, dynamic>>> predictMultipleServices({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    List<Map<String, dynamic>> predictions = [];
    final lowerDescription = description.toLowerCase();

    if (lowerDescription.contains('ac') ||
        lowerDescription.contains('air condition') ||
        lowerDescription.contains('cooling') ||
        lowerDescription.contains('not cooling')) {
      predictions.add({
        'service_type': 'AC Repair',
        'confidence': 0.75,
      });
    }

    if (lowerDescription.contains('leak') ||
        lowerDescription.contains('pipe') ||
        lowerDescription.contains('water') ||
        lowerDescription.contains('plumb')) {
      predictions.add({
        'service_type': 'Plumbing',
        'confidence': 0.80,
      });
    }

    if (lowerDescription.contains('electric') ||
        lowerDescription.contains('wiring') ||
        lowerDescription.contains('wire') ||
        lowerDescription.contains('wirring')) {
      predictions.add({
        'service_type': 'Electrical',
        'confidence': 0.85,
      });
    }

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
// 5. Mock OpenAI Service
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

  Future<String> analyzeTextDescription({
    required String description,
  }) async {
    await Future.delayed(Duration(milliseconds: 250));

    final lowerDescription = description.toLowerCase();

    if (lowerDescription.contains('fix my house') ||
        lowerDescription.contains('help') && lowerDescription.length < 20) {
      return 'What specifically needs fixing? (plumbing, electrical, carpentry, etc.)';
    }

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
// Mock Account Lockout Service
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

  Map<String, dynamic>? getLockoutData(String email) {
    return getLockoutInfo(email);
  }

  void clearAllLockouts() {
    _failedAttempts.clear();
    _lockoutUntil.clear();
  }
}

// ============================================================================
// Mock OTP Service
// ============================================================================

class MockOTPService {
  final Map<String, String> _otpCodes = {};
  final Map<String, DateTime> _otpExpiry = {};
  final Map<String, int> _otpAttempts = {};

  Future<String> generateOTP(String phone) async {
    await Future.delayed(Duration(milliseconds: 100));

    final otp = (Random().nextInt(900000) + 100000).toString();
    _otpCodes[phone] = otp;
    _otpExpiry[phone] = DateTime.now().add(Duration(minutes: 10));
    _otpAttempts[phone] = 0;

    return otp;
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_otpCodes.containsKey(phone)) return false;

    if (DateTime.now().isAfter(_otpExpiry[phone]!)) {
      return false;
    }

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

  bool isExpired(String phone) {
    return isOTPExpired(phone);
  }

  bool isOTPExpired(String phone) {
    if (!_otpExpiry.containsKey(phone)) return true;
    return DateTime.now().isAfter(_otpExpiry[phone]!);
  }

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

// ============================================================================
// NEW: Mock Quote Service
// ============================================================================

class MockQuoteService {
  final Map<String, Map<String, dynamic>> _quotes = {};
  final Map<String, List<String>> _customerQuotes =
      {}; // customer_id -> quote_ids
  int _quoteCounter = 1;

  Future<String> createQuoteRequest({
    required String customerId,
    required String customerName,
    required String workerId,
    required String problemDescription,
    required DateTime scheduledDate,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (problemDescription.isEmpty) {
      throw Exception('Please provide problem description');
    }

    // Check for duplicate pending quotes
    if (_customerQuotes.containsKey(customerId)) {
      final customerQuotesList = _customerQuotes[customerId]!;
      for (var quoteId in customerQuotesList) {
        final quote = _quotes[quoteId]!;
        if (quote['worker_id'] == workerId && quote['status'] == 'pending') {
          throw Exception('You already have a pending quote with this worker');
        }
      }
    }

    final quoteId = 'Q_${_quoteCounter++}';
    _quotes[quoteId] = {
      'quote_id': quoteId,
      'customer_id': customerId,
      'customer_name': customerName,
      'worker_id': workerId,
      'problem_description': problemDescription,
      'scheduled_date': scheduledDate,
      'status': 'pending',
      'created_at': DateTime.now(),
    };

    if (!_customerQuotes.containsKey(customerId)) {
      _customerQuotes[customerId] = [];
    }
    _customerQuotes[customerId]!.add(quoteId);

    return quoteId;
  }

  Future<void> createPendingQuote({
    required String quoteId,
    required String workerId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _quotes[quoteId] = {
      'quote_id': quoteId,
      'worker_id': workerId,
      'status': 'pending',
      'created_at': DateTime.now(),
    };
  }

  Future<void> sendCustomQuote({
    required String quoteId,
    required double price,
    required String timeline,
    required String notes,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (!_quotes.containsKey(quoteId)) {
      throw Exception('Quote not found');
    }

    _quotes[quoteId]!['price'] = price;
    _quotes[quoteId]!['timeline'] = timeline;
    _quotes[quoteId]!['notes'] = notes;
    _quotes[quoteId]!['status'] = 'sent';
    _quotes[quoteId]!['expires_at'] = DateTime.now().add(Duration(hours: 48));
  }

  Future<void> createSentQuote({
    required String quoteId,
    required String customerId,
    required String workerId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _quotes[quoteId] = {
      'quote_id': quoteId,
      'customer_id': customerId,
      'worker_id': workerId,
      'status': 'sent',
      'price': 5000.0,
      'created_at': DateTime.now(),
      'expires_at': DateTime.now().add(Duration(hours: 48)),
    };
  }

  Future<String> acceptQuote({required String quoteId}) async {
    await Future.delayed(Duration(milliseconds: 100));

    if (!_quotes.containsKey(quoteId)) {
      throw Exception('Quote not found');
    }

    final quote = _quotes[quoteId]!;

    // Check if quote expired
    if (quote['expires_at'] != null &&
        DateTime.now().isAfter(quote['expires_at'] as DateTime)) {
      quote['status'] = 'expired';
      throw Exception('This quote expired. Request new quote');
    }

    // Check worker availability (simplified check)
    // In real implementation, would query Firestore
    final workerId = quote['worker_id'];
    // Simulate availability check - you could enhance this

    quote['status'] = 'accepted';
    quote['accepted_at'] = DateTime.now();

    // Create booking
    final bookingId = 'B_${DateTime.now().millisecondsSinceEpoch}';
    quote['booking_id'] = bookingId;

    return bookingId;
  }

  Future<void> declineQuote({required String quoteId}) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_quotes.containsKey(quoteId)) {
      throw Exception('Quote not found');
    }

    _quotes[quoteId]!['status'] = 'declined';
    _quotes[quoteId]!['declined_at'] = DateTime.now();
  }

  Future<void> createExpiredQuote({
    required String quoteId,
    required String customerId,
    required int hoursAgo,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _quotes[quoteId] = {
      'quote_id': quoteId,
      'customer_id': customerId,
      'status': 'expired',
      'created_at': DateTime.now().subtract(Duration(hours: hoursAgo)),
      'expires_at': DateTime.now().subtract(Duration(hours: hoursAgo - 48)),
    };
  }

  void clearAll() {
    _quotes.clear();
    _customerQuotes.clear();
    _quoteCounter = 1;
  }
}

// ============================================================================
// NEW: Mock Booking Service
// ============================================================================

class MockBookingService {
  final Map<String, Map<String, dynamic>> _bookings = {};
  int _bookingCounter = 1;

  Future<String> createDirectBooking({
    required String customerId,
    required String workerId,
    required DateTime scheduledDate,
    required double defaultRate,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    // Validate future date
    if (scheduledDate.isBefore(DateTime.now())) {
      throw Exception('Please select a future date');
    }

    final bookingId = 'B_${_bookingCounter++}';
    _bookings[bookingId] = {
      'booking_id': bookingId,
      'customer_id': customerId,
      'worker_id': workerId,
      'scheduled_date': scheduledDate,
      'price': defaultRate,
      'status': 'requested',
      'created_at': DateTime.now(),
    };

    return bookingId;
  }

  Future<void> createBooking({
    required String bookingId,
    required String customerId,
    String? workerId,
    required String status,
    DateTime? completedAt,
    String? specialInstructions,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _bookings[bookingId] = {
      'booking_id': bookingId,
      'customer_id': customerId,
      'worker_id': workerId ?? 'worker_default',
      'customer_name': 'Test Customer',
      'worker_name': 'Test Worker',
      'problem_description': 'Test problem',
      'scheduled_date': DateTime.now().add(Duration(days: 1)),
      'location': 'Colombo',
      'status': status,
      'created_at': DateTime.now(),
      'service_type': 'Plumbing',
      'final_price': 3500.0,
    };

    if (completedAt != null) {
      _bookings[bookingId]!['completed_at'] = completedAt;
    }

    if (specialInstructions != null) {
      _bookings[bookingId]!['special_instructions'] = specialInstructions;
    }
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    _bookings[bookingId]!['status'] = status;
    _bookings[bookingId]!['${status}_at'] = DateTime.now();
  }

  Future<void> cancelBooking({required String bookingId}) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    final booking = _bookings[bookingId]!;

    if (booking['status'] != 'requested') {
      throw Exception(
          'Contact worker to cancel. Phone: ${booking['worker_phone'] ?? '+94771234567'}');
    }

    booking['status'] = 'cancelled';
    booking['cancelled_at'] = DateTime.now();
  }

  Future<bool> canCancelBooking({required String bookingId}) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_bookings.containsKey(bookingId)) {
      return false;
    }

    final booking = _bookings[bookingId]!;
    return booking['status'] == 'requested';
  }

  Future<List<Map<String, dynamic>>> getWorkerBookingRequests({
    required String workerId,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    return _bookings.values
        .where((b) => b['worker_id'] == workerId && b['status'] == 'requested')
        .toList();
  }

  Future<void> acceptBooking({required String bookingId}) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    _bookings[bookingId]!['status'] = 'accepted';
    _bookings[bookingId]!['accepted_at'] = DateTime.now();
  }

  Future<void> declineBooking({
    required String bookingId,
    required String reason,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    _bookings[bookingId]!['status'] = 'declined';
    _bookings[bookingId]!['decline_reason'] = reason;
    _bookings[bookingId]!['declined_at'] = DateTime.now();
  }

  Future<void> completeBooking({required String bookingId}) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    _bookings[bookingId]!['status'] = 'completed';
    _bookings[bookingId]!['completed_at'] = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> getBookingHistory({
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final history = _bookings.values
        .where((b) => b['customer_id'] == userId && b['status'] == 'completed')
        .toList();

    history.sort((a, b) {
      final aTime = a['completed_at'] as DateTime;
      final bTime = b['completed_at'] as DateTime;
      return bTime.compareTo(aTime);
    });

    return history.map((b) => {...b, 'can_rebook': true}).toList();
  }

  Future<List<Map<String, dynamic>>> getBookingHistoryPaginated({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final allHistory = _bookings.values
        .where((b) => b['customer_id'] == userId && b['status'] == 'completed')
        .toList();

    allHistory.sort((a, b) {
      final aTime = a['completed_at'] as DateTime;
      final bTime = b['completed_at'] as DateTime;
      return bTime.compareTo(aTime);
    });

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= allHistory.length) {
      return [];
    }

    final paginatedResults = allHistory.sublist(
      startIndex,
      endIndex > allHistory.length ? allHistory.length : endIndex,
    );

    return paginatedResults;
  }

  Future<Map<String, dynamic>> getBookingListView({
    required String bookingId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_bookings.containsKey(bookingId)) {
      throw Exception('Booking not found');
    }

    final booking = _bookings[bookingId]!;
    final instructions = booking['special_instructions'] as String?;

    return {
      'booking_id': bookingId,
      'instructions_preview': instructions != null && instructions.length > 100
          ? instructions.substring(0, 100)
          : instructions ?? '',
      'has_read_more': instructions != null && instructions.length > 100,
    };
  }

  Future<String> createEmergencyBooking({
    required String customerId,
    required String workerId,
    required double defaultRate,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final bookingId = 'B_emergency_${_bookingCounter++}';
    _bookings[bookingId] = {
      'booking_id': bookingId,
      'customer_id': customerId,
      'worker_id': workerId,
      'urgency': 'emergency',
      'status': 'requested',
      'price': defaultRate,
      'created_at': DateTime.now(),
    };

    return bookingId;
  }

  Future<Map<String, dynamic>> initiateCall({
    required String workerId,
    required String customerId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    // Simulate fetching worker phone
    // In real implementation, would query Firestore
    final workerPhone = '+94771234567';

    if (workerPhone.isEmpty ||
        workerPhone == 'invalid' ||
        workerPhone.length < 10) {
      throw Exception('Phone number not available. Please use chat');
    }

    return {
      'action': 'dial',
      'phone_number': workerPhone,
    };
  }

  void clearAll() {
    _bookings.clear();
    _bookingCounter = 1;
  }
}

// ============================================================================
// NEW: Mock Chat Service
// ============================================================================

class MockChatService {
  final Map<String, List<Map<String, dynamic>>> _chatMessages = {};
  final Map<String, Map<String, dynamic>> _messageDetails = {};
  bool _isOnline = true;
  int _messageCounter = 1;

  Future<String> sendMessage({
    required String bookingId,
    required String senderId,
    required String message,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final messageId = 'msg_${_messageCounter++}';

    final messageData = {
      'message_id': messageId,
      'booking_id': bookingId,
      'sender_id': senderId,
      'text': message,
      'timestamp': DateTime.now(),
      'status': _isOnline ? 'sent' : 'sending',
    };

    if (!_chatMessages.containsKey(bookingId)) {
      _chatMessages[bookingId] = [];
    }

    _chatMessages[bookingId]!.add(messageData);
    _messageDetails[messageId] = messageData;

    return messageId;
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String bookingId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_chatMessages.containsKey(bookingId)) {
      return [];
    }

    return _chatMessages[bookingId]!
        .map((m) => {...m, 'status': 'read'})
        .toList();
  }

  Future<String> getMessageStatus({required String messageId}) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_messageDetails.containsKey(messageId)) {
      return 'unknown';
    }

    return _messageDetails[messageId]!['status'];
  }

  Future<int> getUnreadCount({
    required String bookingId,
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_chatMessages.containsKey(bookingId)) {
      return 0;
    }

    return _chatMessages[bookingId]!
        .where((m) => m['sender_id'] != userId && m['status'] != 'read')
        .length;
  }

  Future<void> setNetworkStatus({required bool offline}) async {
    await Future.delayed(Duration(milliseconds: 10));
    _isOnline = !offline;

    // Auto-resend queued messages when back online
    if (_isOnline) {
      for (var messageId in _messageDetails.keys) {
        if (_messageDetails[messageId]!['status'] == 'sending') {
          _messageDetails[messageId]!['status'] = 'sent';
        }
      }
    }
  }

  void clearAll() {
    _chatMessages.clear();
    _messageDetails.clear();
    _messageCounter = 1;
    _isOnline = true;
  }
}

// ============================================================================
// NEW: Mock Notification Service
// ============================================================================

class MockNotificationService {
  final Map<String, List<Map<String, dynamic>>> _notifications = {};
  final Map<String, bool> _pushEnabled = {};

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String bookingId,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    if (!_notifications.containsKey(userId)) {
      _notifications[userId] = [];
    }

    final isPushEnabled = _pushEnabled[userId] ?? true;

    final notification = {
      'notification_id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId,
      'type': type,
      'booking_id': bookingId,
      'sent_at': DateTime.now(),
      'is_push': isPushEnabled,
      'is_in_app': true,
      'target_screen': _getTargetScreen(type),
      'action': _getAction(type),
    };

    if (type == 'booking_request' && bookingId.contains('emergency')) {
      notification['urgency'] = 'emergency';
      notification['priority'] = 'high';
    }

    _notifications[userId]!.add(notification);
  }

  String _getTargetScreen(String type) {
    switch (type) {
      case 'new_message':
        return 'chat';
      case 'booking_accepted':
      case 'booking_completed':
        return 'booking_details';
      case 'quote_received':
        return 'quote_details';
      default:
        return 'home';
    }
  }

  String? _getAction(String type) {
    if (type == 'booking_completed') {
      return 'rate_worker';
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_notifications.containsKey(userId)) {
      return [];
    }

    return _notifications[userId]!;
  }

  Future<List<Map<String, dynamic>>> getPushNotifications({
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_notifications.containsKey(userId)) {
      return [];
    }

    return _notifications[userId]!.where((n) => n['is_push'] == true).toList();
  }

  Future<List<Map<String, dynamic>>> getInAppNotifications({
    required String userId,
  }) async {
    await Future.delayed(Duration(milliseconds: 30));

    if (!_notifications.containsKey(userId)) {
      return [];
    }

    return _notifications[userId]!
        .where((n) => n['is_in_app'] == true)
        .toList();
  }

  Future<void> enableNotifications({required String userId}) async {
    await Future.delayed(Duration(milliseconds: 30));
    _pushEnabled[userId] = true;
  }

  Future<void> disablePushNotifications({required String userId}) async {
    await Future.delayed(Duration(milliseconds: 30));
    _pushEnabled[userId] = false;
  }

  void clearAll() {
    _notifications.clear();
    _pushEnabled.clear();
  }
}
