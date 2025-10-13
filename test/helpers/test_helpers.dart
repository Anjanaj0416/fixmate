// test/helpers/test_helpers.dart
// FIXED VERSION - Helper utilities for authentication testing

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mocks/mock_services.dart';

/// Test data constants
class TestConstants {
  static const String testEmail = 'john@test.com';
  static const String testPassword = 'Test@123';
  static const String testPhone = '+94771234567';
  static const String testName = 'John Doe';
  static const String testAddress = 'Colombo 03';
  static const String googleTestEmail = 'testuser@gmail.com';
  static const String unverifiedEmail = 'unverified@test.com';
  static const String workerEmail = 'worker@test.com';

  static const List<String> invalidEmails = [
    'user@',
    'user',
    '@domain.com',
    'user@domain',
    'user@.com',
    '@.com',
  ];

  static const List<String> weakPasswords = [
    '123',
    'abc',
    '12345',
    'password',
  ];
}

/// Firebase mock setup helper
class FirebaseMockHelper {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;

  void setUp() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
  }

  Future<void> tearDown() async {
    try {
      final user = mockAuth.currentUser;
      if (user != null) {
        await mockAuth.signOut();
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  /// Create a test user with default data
  Future<MockUserCredential> createTestUser({
    String? email,
    String? password,
    String? displayName,
  }) async {
    final mockUser = MockUser(
      uid: 'test_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? TestConstants.testEmail,
      displayName: displayName ?? TestConstants.testName,
    );

    // Create Firestore document
    await mockFirestore.setDocument(
      collection: 'users',
      documentId: mockUser.uid,
      data: {
        'name': displayName ?? TestConstants.testName,
        'email': email ?? TestConstants.testEmail,
        'phone': TestConstants.testPhone,
        'address': TestConstants.testAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      },
    );

    // FIXED: Return MockUserCredential instead of trying to construct UserCredential
    return MockUserCredential(
      user: mockUser,
      additionalUserInfo: AdditionalUserInfo(isNewUser: true, profile: {}),
    );
  }

  /// Create a verified user
  Future<MockUserCredential> createVerifiedUser({
    String? email,
    String? password,
  }) async {
    final userCredential = await createTestUser(
      email: email,
      password: password,
    );

    await mockFirestore.updateDocument(
      collection: 'users',
      documentId: userCredential.user!.uid,
      data: {
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      },
    );

    return userCredential;
  }

  /// Create a worker account
  Future<MockUserCredential> createWorkerAccount({
    String? email,
    String? password,
  }) async {
    final userCredential = await createTestUser(
      email: email ?? TestConstants.workerEmail,
      password: password,
    );

    await mockFirestore.setDocument(
      collection: 'workers',
      documentId: userCredential.user!.uid,
      data: {
        'userId': userCredential.user!.uid,
        'serviceType': 'Plumber',
        'experienceYears': 5,
        'rating': 4.5,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await mockFirestore.updateDocument(
      collection: 'users',
      documentId: userCredential.user!.uid,
      data: {
        'accountType': 'worker',
      },
    );

    return userCredential;
  }

  /// Simulate account lockout
  Future<void> simulateAccountLockout({
    required String email,
    required int attempts,
  }) async {
    final querySnapshot = await mockFirestore.queryCollection(
      collection: 'users',
      whereField: 'email',
      whereValue: email,
    );

    if (querySnapshot.isNotEmpty) {
      final doc = querySnapshot.first;
      await mockFirestore.updateDocument(
        collection: 'users',
        documentId: doc.id,
        data: {
          'failedLoginAttempts': attempts,
          'lockedUntil': attempts >= 5
              ? DateTime.now().add(Duration(minutes: 15)).toIso8601String()
              : null,
        },
      );
    }
  }

  /// Simulate 2FA verification
  Future<bool> simulate2FA({
    required String uid,
    required String otpCode,
  }) async {
    final doc = await mockFirestore.getDocument(
      collection: 'users',
      documentId: uid,
    );

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOTP = data['otpCode'] as String?;
    final otpExpiry = data['otpExpiry'] as String?;

    if (storedOTP == null || otpExpiry == null) return false;

    // Check if OTP expired
    if (DateTime.now().isAfter(DateTime.parse(otpExpiry))) {
      return false;
    }

    // Check if OTP matches
    if (storedOTP != otpCode) {
      final attempts = (data['otpAttempts'] ?? 0) + 1;

      await mockFirestore.updateDocument(
        collection: 'users',
        documentId: uid,
        data: {
          'otpAttempts': attempts,
        },
      );

      // Lock after 5 attempts
      if (attempts >= 5) {
        await mockFirestore.updateDocument(
          collection: 'users',
          documentId: uid,
          data: {
            'otpLocked': true,
            'otpLockedUntil':
                DateTime.now().add(Duration(hours: 1)).toIso8601String(),
          },
        );
      }

      return false;
    }

    // OTP verified successfully
    await mockFirestore.updateDocument(
      collection: 'users',
      documentId: uid,
      data: {
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'otpAttempts': 0,
      },
    );

    return true;
  }
}

/// Test result logger
class TestLogger {
  static void logTestStart(String testCaseId, String testName) {
    print('\n========================================');
    print('TEST: $testCaseId - $testName');
    print('========================================');
  }

  static void logTestPass(String testCaseId) {
    print('✅ PASS: $testCaseId');
  }

  static void logTestFail(String testCaseId, String reason) {
    print('❌ FAIL: $testCaseId - $reason');
  }

  static void logTestBlocked(String testCaseId, String reason) {
    print('🚫 BLOCKED: $testCaseId - $reason');
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Match Firebase Auth exception codes
  static Matcher throwsFirebaseAuthException({String? code}) {
    return throwsA(
      allOf(
        isA<FirebaseAuthException>(),
        predicate<FirebaseAuthException>(
          (e) => code == null || e.code == code,
          'has code $code',
        ),
      ),
    );
  }

  /// Match specific error messages
  static Matcher hasErrorMessage(String message) {
    return predicate<Exception>(
      (e) => e.toString().contains(message),
      'contains error message: $message',
    );
  }
}

/// Test data generators
class TestDataGenerator {
  /// Generate random email
  static String randomEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test_$timestamp@example.com';
  }

  /// Generate random phone number (Sri Lankan format)
  static String randomPhone() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000000;
    return '+94$random';
  }

  /// Generate random password
  static String randomPassword({int length = 8}) {
    final chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();
  }

  /// Generate test user data
  static Map<String, dynamic> userDocument({
    required String email,
    required String name,
    String? phone,
    String? address,
    bool emailVerified = false,
    String accountType = 'customer',
  }) {
    return {
      'email': email,
      'name': name,
      'phone': phone ?? TestConstants.testPhone,
      'address': address ?? TestConstants.testAddress,
      'emailVerified': emailVerified,
      'accountType': accountType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Generate worker document
  static Map<String, dynamic> workerDocument({
    required String workerId,
    required String serviceType,
    int experienceYears = 0,
    double rating = 0.0,
    bool verified = false,
    bool active = true,
  }) {
    return {
      'worker_id': workerId,
      'serviceType': serviceType,
      'experienceYears': experienceYears,
      'rating': rating,
      'verified': verified,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
