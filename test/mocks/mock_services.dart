// test/mocks/mock_services.dart
// FIXED VERSION - Compatible with firebase_auth 5.7.0 and cloud_firestore 5.6.12
// Includes all missing methods and services

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock User implementation with ALL required methods
class MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final String? phoneNumber;

  @override
  final String? photoURL;

  @override
  bool emailVerified;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.emailVerified = false,
  });

  // Email verification
  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    emailVerified = true;
  }

  // Basic operations
  @override
  Future<void> delete() async {}

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

  @override
  Future<void> reload() async {}

  // Linking methods
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber,
      [RecaptchaVerifier? verifier]) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async {
    throw UnimplementedError();
  }

  // NEW: Web-specific linking methods (firebase_auth 5.7.0)
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<void> linkWithRedirect(AuthProvider provider) async {
    throw UnimplementedError();
  }

  // Reauthentication methods
  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithProvider(
      AuthProvider provider) async {
    throw UnimplementedError();
  }

  // NEW: Web-specific reauthentication methods (firebase_auth 5.7.0)
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async {
    throw UnimplementedError();
  }

  // Update methods
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

  // NEW: Update profile method (firebase_auth 5.7.0)
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
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

/// Mock Firestore Service
class MockFirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_data.containsKey(collection)) {
      _data[collection] = {};
    }
    _data[collection]![documentId] = Map<String, dynamic>.from(data);
  }

  Future<MockDocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    final collectionData = _data[collection];
    if (collectionData == null || !collectionData.containsKey(documentId)) {
      return MockDocumentSnapshot(id: documentId, exists: false);
    }

    return MockDocumentSnapshot(
      id: documentId,
      data: collectionData[documentId],
      exists: true,
    );
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (_data.containsKey(collection) &&
        _data[collection]!.containsKey(documentId)) {
      _data[collection]![documentId]!.addAll(data);
    }
  }

  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    _data[collection]?.remove(documentId);
  }

  void clearData() {
    _data.clear();
  }

  Future<List<MockDocumentSnapshot>> queryCollection({
    required String collection,
    String? whereField,
    dynamic whereValue,
  }) async {
    final collectionData = _data[collection] ?? {};

    if (whereField == null) {
      return collectionData.entries
          .map((e) => MockDocumentSnapshot(id: e.key, data: e.value))
          .toList();
    }

    return collectionData.entries
        .where((e) => e.value[whereField] == whereValue)
        .map((e) => MockDocumentSnapshot(id: e.key, data: e.value))
        .toList();
  }
}

/// Account Lockout Data
class LockoutData {
  int attempts;
  DateTime? lockedUntil;

  LockoutData({required this.attempts, this.lockedUntil});
}

/// Mock Account Lockout Service
class MockAccountLockoutService {
  final Map<String, LockoutData> _lockouts = {};

  bool isAccountLocked(String email) {
    if (!_lockouts.containsKey(email)) return false;

    final lockoutData = _lockouts[email]!;
    if (lockoutData.lockedUntil == null) return false;

    if (DateTime.now().isAfter(lockoutData.lockedUntil!)) {
      _lockouts.remove(email);
      return false;
    }
    return true;
  }

  Future<void> recordFailedLogin(String email) async {
    if (!_lockouts.containsKey(email)) {
      _lockouts[email] = LockoutData(attempts: 0);
    }

    _lockouts[email]!.attempts++;

    if (_lockouts[email]!.attempts >= 5) {
      _lockouts[email]!.lockedUntil = DateTime.now().add(Duration(minutes: 15));
    }
  }

  LockoutData? getLockoutData(String email) {
    return _lockouts[email];
  }

  void clearLockout(String email) {
    _lockouts.remove(email);
  }

  void clearAllLockouts() {
    _lockouts.clear();
  }

  int getFailedAttempts(String email) {
    return _lockouts[email]?.attempts ?? 0;
  }
}

/// OTP Data
class OTPData {
  String code;
  DateTime generatedAt;
  int attempts;
  bool isLocked;

  OTPData({
    required this.code,
    required this.generatedAt,
    this.attempts = 0,
    this.isLocked = false,
  });
}

/// Mock OTP Service with ASYNC methods
class MockOTPService {
  final Map<String, OTPData> _otpData = {};

  // FIXED: Made async to match usage in tests
  Future<String> generateOTP(String phone) async {
    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');

    _otpData[phone] = OTPData(
      code: otp,
      generatedAt: DateTime.now(),
      attempts: 0,
      isLocked: false,
    );

    return otp;
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    if (!_otpData.containsKey(phone)) return false;

    final data = _otpData[phone]!;

    if (data.isLocked) return false;

    if (isOTPExpired(phone)) return false;

    data.attempts++;

    if (data.attempts > 5) {
      data.isLocked = true;
      return false;
    }

    return data.code == otp;
  }

  bool isOTPExpired(String phone) {
    if (!_otpData.containsKey(phone)) return true;

    final data = _otpData[phone]!;
    final expiryTime = data.generatedAt.add(Duration(minutes: 10));

    return DateTime.now().isAfter(expiryTime);
  }

  bool isExpired(String phone) => isOTPExpired(phone);

  OTPData? getOTPData(String phone) {
    return _otpData[phone];
  }

  void clearOTP(String phone) {
    _otpData.remove(phone);
  }

  void clearOTPData() {
    _otpData.clear();
  }

  int getAttempts(String phone) {
    return _otpData[phone]?.attempts ?? 0;
  }
}

/// Email Type Enum
enum EmailType {
  verification,
  passwordReset,
  lockout,
  twoFactor,
  general,
}

/// Email Record
class EmailRecord {
  final String recipient;
  final EmailType type;
  final String subject;
  final DateTime sentAt;

  EmailRecord({
    required this.recipient,
    required this.type,
    required this.subject,
    required this.sentAt,
  });
}

/// Mock Email Service
class MockEmailService {
  final List<EmailRecord> _sentEmails = [];

  Future<void> sendVerificationEmail({
    required String email,
    required String verificationLink,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _sentEmails.add(EmailRecord(
      recipient: email,
      type: EmailType.verification,
      subject: 'Verify your email',
      sentAt: DateTime.now(),
    ));
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _sentEmails.add(EmailRecord(
      recipient: email,
      type: EmailType.passwordReset,
      subject: 'Reset your password',
      sentAt: DateTime.now(),
    ));
  }

  Future<void> sendLockoutNotification({
    required String email,
    required DateTime lockedUntil,
  }) async {
    await Future.delayed(Duration(milliseconds: 50));

    _sentEmails.add(EmailRecord(
      recipient: email,
      type: EmailType.lockout,
      subject: 'Account temporarily locked',
      sentAt: DateTime.now(),
    ));
  }

  List<EmailRecord> getSentEmails({String? recipient, EmailType? type}) {
    var emails = _sentEmails;

    if (recipient != null) {
      emails = emails.where((e) => e.recipient == recipient).toList();
    }

    if (type != null) {
      emails = emails.where((e) => e.type == type).toList();
    }

    return emails;
  }

  void clearSentEmails() {
    _sentEmails.clear();
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

/// Validation helpers
class ValidationHelper {
  static bool isValidEmail(String email) {
    if (email.length > 254) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+94\d{9}$').hasMatch(phone);
  }
}
