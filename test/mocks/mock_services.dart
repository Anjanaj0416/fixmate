// test/mocks/mock_services.dart
// FIXED VERSION - Compatible with firebase_auth 5.7.0 and cloud_firestore 5.6.12

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

  // FIXED: Updated signature to match firebase_auth 5.7.0
  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    emailVerified = true;
  }

  @override
  Future<void> delete() async {}

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

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

  @override
  Future<void> reload() async {}

  @override
  Future<void> updateDisplayName(String? displayName) async {
    // this.displayName = displayName; // Can't assign to final
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    // this.email = newEmail; // Can't assign to final
  }

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {
    // this.photoURL = photoURL; // Can't assign to final
  }

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
    // Simulate sending reset email
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

  // FIXED: Changed from property to method to match cloud_firestore 5.6.12
  @override
  Map<String, dynamic>? data() => _data;

  // FIXED: Changed parameter type from String to Object
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

/// Mock Account Lockout Service
class MockAccountLockoutService {
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockouts = {};

  bool isLocked(String email) {
    if (!_lockouts.containsKey(email)) return false;

    final lockoutTime = _lockouts[email]!;
    if (DateTime.now().isAfter(lockoutTime)) {
      _lockouts.remove(email);
      _failedAttempts.remove(email);
      return false;
    }
    return true;
  }

  void recordFailedAttempt(String email) {
    _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;

    if (_failedAttempts[email]! >= 5) {
      _lockouts[email] = DateTime.now().add(Duration(minutes: 15));
    }
  }

  void clearLockout(String email) {
    _failedAttempts.remove(email);
    _lockouts.remove(email);
  }

  void clearAllLockouts() {
    _failedAttempts.clear();
    _lockouts.clear();
  }

  int getFailedAttempts(String email) {
    return _failedAttempts[email] ?? 0;
  }
}

/// Mock OTP Service
class MockOTPService {
  final Map<String, String> _otpCodes = {};
  final Map<String, DateTime> _otpExpiry = {};
  final Map<String, int> _otpAttempts = {};

  String generateOTP(String phone) {
    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    _otpCodes[phone] = otp;
    _otpExpiry[phone] = DateTime.now().add(Duration(minutes: 10));
    _otpAttempts[phone] = 0;
    return otp;
  }

  bool verifyOTP(String phone, String otp) {
    if (!_otpCodes.containsKey(phone)) return false;

    // Check expiry
    if (DateTime.now().isAfter(_otpExpiry[phone]!)) {
      return false;
    }

    // Check attempts
    _otpAttempts[phone] = (_otpAttempts[phone] ?? 0) + 1;
    if (_otpAttempts[phone]! > 5) {
      return false;
    }

    return _otpCodes[phone] == otp;
  }

  bool isExpired(String phone) {
    if (!_otpExpiry.containsKey(phone)) return true;
    return DateTime.now().isAfter(_otpExpiry[phone]!);
  }

  void clearOTP(String phone) {
    _otpCodes.remove(phone);
    _otpExpiry.remove(phone);
    _otpAttempts.remove(phone);
  }

  void clearOTPData() {
    _otpCodes.clear();
    _otpExpiry.clear();
    _otpAttempts.clear();
  }

  int getAttempts(String phone) {
    return _otpAttempts[phone] ?? 0;
  }
}
