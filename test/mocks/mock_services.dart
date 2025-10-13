// test/mocks/mock_services.dart
// Mock services for authentication testing
// Simulates your actual services without Firebase connection

import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

// ==================== MOCK AUTH SERVICE ====================

class MockAuthService extends Mock {
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate authentication delay
    await Future.delayed(Duration(milliseconds: 500));

    // Mock successful authentication
    return MockUserCredential(
      user: MockUser(
        uid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        emailVerified: true,
      ),
    );
  }

  // Create account
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    return MockUserCredential(
      user: MockUser(
        uid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        emailVerified: false,
      ),
    );
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(Duration(milliseconds: 300));
    // Mock email sent
  }

  // Sign out
  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 200));
  }

  // Get current user
  MockUser? get currentUser => null;
}

// ==================== MOCK USER ====================

class MockUser extends Mock implements User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final String? phoneNumber;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.phoneNumber,
  });

  @override
  Future<void> reload() async {
    await Future.delayed(Duration(milliseconds: 100));
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future.delayed(Duration(milliseconds: 200));
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(Duration(milliseconds: 300));
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await Future.delayed(Duration(milliseconds: 300));
  }

  @override
  Future<void> delete() async {
    await Future.delayed(Duration(milliseconds: 300));
  }
}

// ==================== MOCK USER CREDENTIAL ====================

class MockUserCredential extends Mock implements UserCredential {
  @override
  final User? user;

  MockUserCredential({this.user});
}

// ==================== MOCK GOOGLE AUTH SERVICE ====================

class MockGoogleAuthService extends Mock {
  Future<UserCredential?> signInWithGoogle() async {
    await Future.delayed(Duration(milliseconds: 800));

    return MockUserCredential(
      user: MockUser(
        uid: 'google_mock_uid_${DateTime.now().millisecondsSinceEpoch}',
        email: 'testuser@gmail.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        emailVerified: true,
      ),
    );
  }

  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 200));
  }
}

// ==================== MOCK FIRESTORE SERVICE ====================

class MockFirestoreService extends Mock {
  final Map<String, Map<String, dynamic>> _mockData = {};

  // Get document
  Future<MockDocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final key = '$collection/$documentId';
    return MockDocumentSnapshot(
      exists: _mockData.containsKey(key),
      data: _mockData[key],
      id: documentId,
    );
  }

  // Set document
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(milliseconds: 150));

    final key = '$collection/$documentId';
    _mockData[key] = data;
  }

  // Update document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(Duration(milliseconds: 150));

    final key = '$collection/$documentId';
    if (_mockData.containsKey(key)) {
      _mockData[key]!.addAll(data);
    }
  }

  // Delete document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(Duration(milliseconds: 150));

    final key = '$collection/$documentId';
    _mockData.remove(key);
  }

  // Query documents
  Future<List<MockDocumentSnapshot>> queryDocuments({
    required String collection,
    String? whereField,
    dynamic whereValue,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    final results = <MockDocumentSnapshot>[];

    _mockData.forEach((key, value) {
      if (key.startsWith('$collection/')) {
        if (whereField == null || value[whereField] == whereValue) {
          final docId = key.split('/').last;
          results.add(MockDocumentSnapshot(
            exists: true,
            data: value,
            id: docId,
          ));
        }
      }
    });

    return results;
  }

  // Clear all data (for testing cleanup)
  void clearData() {
    _mockData.clear();
  }
}

// ==================== MOCK DOCUMENT SNAPSHOT ====================

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {
  @override
  final bool exists;
  final Map<String, dynamic>? _data;
  @override
  final String id;

  MockDocumentSnapshot({
    required this.exists,
    Map<String, dynamic>? data,
    required this.id,
  }) : _data = data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(String field) => _data?[field];
}

// ==================== MOCK SMS SERVICE ====================

class MockSMSService extends Mock {
  final Map<String, String> _otpStorage = {};

  // Send OTP
  Future<String> sendOTP({required String phoneNumber}) async {
    await Future.delayed(Duration(milliseconds: 500));

    // Generate 6-digit OTP
    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');

    _otpStorage[phoneNumber] = otp;

    print('📱 Mock OTP sent to $phoneNumber: $otp');
    return otp;
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));

    final storedOtp = _otpStorage[phoneNumber];
    return storedOtp == otp;
  }

  // Get stored OTP (for testing only)
  String? getStoredOTP(String phoneNumber) => _otpStorage[phoneNumber];

  // Clear OTP storage
  void clearOTPs() => _otpStorage.clear();
}

// ==================== MOCK EMAIL SERVICE ====================

class MockEmailService extends Mock {
  final List<MockEmail> _sentEmails = [];

  // Send verification email
  Future<void> sendVerificationEmail({
    required String email,
    required String verificationLink,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));

    _sentEmails.add(MockEmail(
      to: email,
      subject: 'Verify Your Email',
      body: 'Click here to verify: $verificationLink',
      type: EmailType.verification,
      sentAt: DateTime.now(),
    ));

    print('📧 Mock verification email sent to $email');
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));

    _sentEmails.add(MockEmail(
      to: email,
      subject: 'Reset Your Password',
      body: 'Click here to reset: $resetLink',
      type: EmailType.passwordReset,
      sentAt: DateTime.now(),
    ));

    print('📧 Mock password reset email sent to $email');
  }

  // Get sent emails (for testing verification)
  List<MockEmail> getSentEmails({String? recipient, EmailType? type}) {
    return _sentEmails.where((email) {
      if (recipient != null && email.to != recipient) return false;
      if (type != null && email.type != type) return false;
      return true;
    }).toList();
  }

  // Clear sent emails
  void clearSentEmails() => _sentEmails.clear();
}

// ==================== MOCK EMAIL ====================

class MockEmail {
  final String to;
  final String subject;
  final String body;
  final EmailType type;
  final DateTime sentAt;

  MockEmail({
    required this.to,
    required this.subject,
    required this.body,
    required this.type,
    required this.sentAt,
  });
}

enum EmailType {
  verification,
  passwordReset,
  accountLockout,
  twoFactorAuth,
}

// ==================== MOCK ACCOUNT LOCKOUT SERVICE ====================

class MockAccountLockoutService {
  final Map<String, LockoutData> _lockoutData = {};

  // Record failed login attempt
  Future<void> recordFailedLogin(String email) async {
    final data = _lockoutData[email] ?? LockoutData();
    data.attempts++;
    data.lastAttempt = DateTime.now();

    if (data.attempts >= 5) {
      data.isLocked = true;
      data.lockedUntil = DateTime.now().add(Duration(minutes: 15));
    }

    _lockoutData[email] = data;
  }

  // Check if account is locked
  bool isAccountLocked(String email) {
    final data = _lockoutData[email];
    if (data == null) return false;

    if (data.isLocked && data.lockedUntil != null) {
      if (DateTime.now().isBefore(data.lockedUntil!)) {
        return true;
      } else {
        // Lockout expired, reset
        data.isLocked = false;
        data.attempts = 0;
      }
    }

    return false;
  }

  // Reset failed attempts
  void resetFailedAttempts(String email) {
    _lockoutData[email] = LockoutData();
  }

  // Get lockout data
  LockoutData? getLockoutData(String email) => _lockoutData[email];

  // Clear all lockout data
  void clearAllLockouts() => _lockoutData.clear();
}

class LockoutData {
  int attempts = 0;
  DateTime? lastAttempt;
  bool isLocked = false;
  DateTime? lockedUntil;
}

// ==================== MOCK OTP SERVICE ====================

class MockOTPService {
  final Map<String, OTPData> _otpData = {};

  // Generate and send OTP
  Future<String> generateOTP(String phoneNumber) async {
    await Future.delayed(Duration(milliseconds: 500));

    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');

    _otpData[phoneNumber] = OTPData(
      otp: otp,
      generatedAt: DateTime.now(),
      attempts: 0,
      isLocked: false,
    );

    print('🔐 Mock OTP generated for $phoneNumber: $otp');
    return otp;
  }

  // Verify OTP
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    await Future.delayed(Duration(milliseconds: 300));

    final data = _otpData[phoneNumber];
    if (data == null) return false;

    // Check if locked
    if (data.isLocked) {
      print('🚫 Account locked due to too many OTP attempts');
      return false;
    }

    // Check if expired (10 minutes)
    if (DateTime.now().difference(data.generatedAt).inMinutes > 10) {
      print('⏰ OTP expired');
      return false;
    }

    // Check OTP
    if (data.otp == otp) {
      print('✅ OTP verified successfully');
      _otpData.remove(phoneNumber);
      return true;
    } else {
      data.attempts++;
      if (data.attempts >= 5) {
        data.isLocked = true;
        print('🚫 Account locked after 5 failed OTP attempts');
      }
      return false;
    }
  }

  // Check if OTP is expired
  bool isOTPExpired(String phoneNumber) {
    final data = _otpData[phoneNumber];
    if (data == null) return true;

    return DateTime.now().difference(data.generatedAt).inMinutes > 10;
  }

  // Get OTP data (for testing)
  OTPData? getOTPData(String phoneNumber) => _otpData[phoneNumber];

  // Clear OTP data
  void clearOTPData() => _otpData.clear();
}

class OTPData {
  final String otp;
  final DateTime generatedAt;
  int attempts;
  bool isLocked;

  OTPData({
    required this.otp,
    required this.generatedAt,
    this.attempts = 0,
    this.isLocked = false,
  });
}
