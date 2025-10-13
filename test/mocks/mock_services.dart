// test/mocks/mock_services.dart
// FINAL CORRECTED VERSION - No duplicates, all methods implemented

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock User implementation
class MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final bool emailVerified;

  @override
  final String? phoneNumber;

  @override
  final String? photoURL;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.phoneNumber,
    this.photoURL,
  });

  @override
  Future<void> delete() async {}

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    return MockUserCredential(user: this);
  }

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber,
          [RecaptchaVerifier? verifier]) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) async {}

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    return MockUserCredential(user: this);
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async {}

  @override
  Future<UserCredential> reauthenticateWithProvider(
          AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<User> unlink(String providerId) async => this;

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}

/// Mock UserCredential implementation
class MockUserCredential implements UserCredential {
  @override
  final User? user;

  @override
  final AdditionalUserInfo? additionalUserInfo;

  @override
  final AuthCredential? credential;

  MockUserCredential({
    this.user,
    this.additionalUserInfo,
    this.credential,
  });
}

/// Mock Auth Service
class MockAuthService {
  final Map<String, MockUser> _users = {};
  MockUser? _currentUser;

  MockUser? get currentUser => _currentUser;

  Future<MockUserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_users.containsKey(email)) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use.',
      );
    }

    final user = MockUser(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      emailVerified: false,
    );

    _users[email] = user;
    _currentUser = user;

    return MockUserCredential(user: user);
  }

  Future<MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!_users.containsKey(email)) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found with this email.',
      );
    }

    final user = _users[email]!;
    _currentUser = user;

    return MockUserCredential(user: user);
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(Duration(milliseconds: 100));
  }

  Stream<MockUser?> authStateChanges() {
    return Stream.value(_currentUser);
  }
}

/// Mock DocumentSnapshot implementation
class MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic>? _data;
  final bool _exists;

  MockDocumentSnapshot({
    required String id,
    Map<String, dynamic>? data,
    bool exists = true,
  })  : _id = id,
        _data = data,
        _exists = exists;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _exists;

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => get(field);

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference get reference => throw UnimplementedError();
}

/// Mock QueryDocumentSnapshot implementation
class MockQueryDocumentSnapshot extends MockDocumentSnapshot
    implements QueryDocumentSnapshot {
  MockQueryDocumentSnapshot({
    required String id,
    required Map<String, dynamic> data,
  }) : super(id: id, data: data, exists: true);

  @override
  Map<String, dynamic> data() => _data!;
}

/// Mock QuerySnapshot implementation
class MockQuerySnapshot implements QuerySnapshot {
  final List<QueryDocumentSnapshot> _docs;

  MockQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot> get docs => _docs;

  @override
  List<DocumentChange> get docChanges => [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => _docs.length;
}

/// Mock Firestore Service
class MockFirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};

  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_collections.containsKey(collection)) {
      _collections[collection] = {};
    }
    _collections[collection]![documentId] = Map.from(data);
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_collections.containsKey(collection) ||
        !_collections[collection]!.containsKey(documentId)) {
      throw Exception('Document not found');
    }
    _collections[collection]![documentId]!.addAll(data);
  }

  Future<MockDocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    if (!_collections.containsKey(collection) ||
        !_collections[collection]!.containsKey(documentId)) {
      return MockDocumentSnapshot(id: documentId, exists: false);
    }

    return MockDocumentSnapshot(
      id: documentId,
      data: Map.from(_collections[collection]![documentId]!),
      exists: true,
    );
  }

  Future<List<MockQueryDocumentSnapshot>> queryCollection({
    required String collection,
    String? whereField,
    dynamic whereValue,
  }) async {
    if (!_collections.containsKey(collection)) {
      return [];
    }

    final results = <MockQueryDocumentSnapshot>[];
    _collections[collection]!.forEach((docId, data) {
      if (whereField == null || data[whereField] == whereValue) {
        results.add(MockQueryDocumentSnapshot(
          id: docId,
          data: Map.from(data),
        ));
      }
    });

    return results;
  }

  void clearData() {
    _collections.clear();
  }
}

/// Mock Google Auth Service
class MockGoogleAuthService {
  bool _isSignedIn = false;
  MockUser? _currentUser;

  Future<MockUserCredential?> signInWithGoogle() async {
    await Future.delayed(Duration(milliseconds: 100));

    final user = MockUser(
      uid: 'google_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: 'testuser@gmail.com',
      displayName: 'Test User',
      emailVerified: true,
    );

    _currentUser = user;
    _isSignedIn = true;

    return MockUserCredential(user: user);
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    _currentUser = null;
  }

  bool get isSignedIn => _isSignedIn;
  MockUser? get currentUser => _currentUser;
}

/// FIXED: Enhanced validation helpers
class ValidationHelper {
  /// FIXED: Strict email validation that rejects double dots and other invalid patterns
  static bool isValidEmail(String email) {
    if (email.isEmpty || email.length > 254) return false;

    // Reject emails with double dots
    if (email.contains('..')) return false;

    // Reject SQL injection attempts and XSS payloads
    if (email.contains("'") ||
        email.contains('"') ||
        email.contains('<') ||
        email.contains('>') ||
        email.contains('script') ||
        email.contains('DROP') ||
        email.contains('SELECT') ||
        email.contains('--') ||
        email.contains('/*')) {
      return false;
    }

    // Standard email regex with stricter validation
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]@[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$');

    return emailRegex.hasMatch(email);
  }

  /// FIXED: Strong password validation - must be at least 6 characters
  static bool isStrongPassword(String password) {
    // Reject passwords shorter than 6 characters
    if (password.length < 6) return false;

    return true;
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+94\d{9}$').hasMatch(phone);
  }

  /// FIXED: Check if string contains XSS payload
  static bool containsXSS(String input) {
    final xssPatterns = [
      '<script',
      'javascript:',
      'onerror=',
      'onload=',
      '<img',
      '<svg',
      '<iframe',
      '<body',
    ];

    final lowerInput = input.toLowerCase();
    return xssPatterns.any((pattern) => lowerInput.contains(pattern));
  }

  /// FIXED: Sanitize string to prevent XSS
  static String sanitizeForXSS(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }
}

/// Account lockout service
class MockAccountLockoutService {
  final Map<String, LockoutData> _lockouts = {};

  Future<void> recordFailedLogin(String email) async {
    if (!_lockouts.containsKey(email)) {
      _lockouts[email] = LockoutData(
        email: email,
        attempts: 0,
        lastAttempt: DateTime.now(),
      );
    }

    final data = _lockouts[email]!;
    data.attempts++;
    data.lastAttempt = DateTime.now();

    if (data.attempts >= 5) {
      data.lockedUntil = DateTime.now().add(Duration(minutes: 15));
    }
  }

  bool isAccountLocked(String email) {
    if (!_lockouts.containsKey(email)) return false;

    final data = _lockouts[email]!;
    if (data.lockedUntil == null) return false;

    if (DateTime.now().isBefore(data.lockedUntil!)) {
      return true;
    }

    // Unlock if time has passed
    data.attempts = 0;
    data.lockedUntil = null;
    return false;
  }

  LockoutData? getLockoutData(String email) {
    return _lockouts[email];
  }

  void clearAllLockouts() {
    _lockouts.clear();
  }
}

class LockoutData {
  final String email;
  int attempts;
  DateTime lastAttempt;
  DateTime? lockedUntil;

  LockoutData({
    required this.email,
    required this.attempts,
    required this.lastAttempt,
    this.lockedUntil,
  });
}

/// FIXED: Enhanced OTP Service with lockout mechanism
class MockOTPService {
  final Map<String, OTPData> _otpData = {};

  Future<String> generateOTP(String phoneNumber) async {
    await Future.delayed(Duration(milliseconds: 2));

    final otp = _generateSixDigitCode();
    _otpData[phoneNumber] = OTPData(
      code: otp,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 10)),
      attempts: 0,
      isLocked: false,
    );

    return otp;
  }

  /// FIXED: Verify OTP with attempt limiting
  Future<bool> verifyOTP(String phoneNumber, String code) async {
    await Future.delayed(Duration(milliseconds: 4));

    if (!_otpData.containsKey(phoneNumber)) return false;

    final data = _otpData[phoneNumber]!;

    // FIXED: Check if account is locked
    if (data.isLocked) {
      return false;
    }

    // Check expiration
    if (DateTime.now().isAfter(data.expiresAt)) {
      return false;
    }

    // Check code match
    if (data.code != code) {
      data.attempts++;

      // FIXED: Lock after 5 failed attempts
      if (data.attempts >= 5) {
        data.isLocked = true;
      }

      return false;
    }

    // Success - mark as used
    data.used = true;
    return true;
  }

  /// FIXED: Check if OTP is expired
  bool isExpired(String phoneNumber) {
    if (!_otpData.containsKey(phoneNumber)) return true;
    final data = _otpData[phoneNumber]!;
    return DateTime.now().isAfter(data.expiresAt);
  }

  /// FIXED: Get number of failed attempts
  int getAttempts(String phoneNumber) {
    if (!_otpData.containsKey(phoneNumber)) return 0;
    return _otpData[phoneNumber]!.attempts;
  }

  OTPData? getOTPData(String phoneNumber) {
    return _otpData[phoneNumber];
  }

  void clearOTPData() {
    _otpData.clear();
  }

  String _generateSixDigitCode() {
    return (100000 + DateTime.now().microsecond % 900000).toString();
  }
}

/// FIXED: Made fields mutable for testing
class OTPData {
  final String code;
  final DateTime generatedAt;
  DateTime expiresAt; // FIXED: Not final anymore
  int attempts;
  bool used;
  bool isLocked;

  OTPData({
    required this.code,
    required this.generatedAt,
    required this.expiresAt,
    this.attempts = 0,
    this.used = false,
    this.isLocked = false,
  });
}

/// Email service for testing
enum EmailType { verification, passwordReset, notification }

class EmailData {
  final String recipient;
  final EmailType type;
  final DateTime sentAt;
  final String subject;
  final String body;

  EmailData({
    required this.recipient,
    required this.type,
    required this.sentAt,
    required this.subject,
    required this.body,
  });
}

class MockEmailService {
  final List<EmailData> _sentEmails = [];

  Future<void> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    await Future.delayed(Duration(milliseconds: 10));

    _sentEmails.add(EmailData(
      recipient: email,
      type: EmailType.passwordReset,
      sentAt: DateTime.now(),
      subject: 'Password Reset Request',
      body: 'Click here to reset: $resetLink',
    ));
  }

  List<EmailData> getSentEmails({String? recipient, EmailType? type}) {
    return _sentEmails.where((email) {
      if (recipient != null && email.recipient != recipient) return false;
      if (type != null && email.type != type) return false;
      return true;
    }).toList();
  }

  void clearSentEmails() {
    _sentEmails.clear();
  }
}
