// test/helpers/test_helpers.dart
// Helper utilities for authentication testing - FIXED VERSION

import 'dart:async'; // FIXED: Added import for Completer
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

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
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  void setUp() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
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
  Future<UserCredential> createTestUser({
    String? email,
    String? password,
    String? displayName,
  }) async {
    final mockUser = MockUser(
      uid: 'test_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? TestConstants.testEmail,
      displayName: displayName ?? TestConstants.testName,
    );

    // Use signInWithCustomToken to create the user in MockFirebaseAuth
    await mockAuth.signInWithCustomToken('mock_token');

    // Create Firestore document
    await mockFirestore.collection('users').doc(mockUser.uid).set({
      'name': displayName ?? TestConstants.testName,
      'email': email ?? TestConstants.testEmail,
      'phone': TestConstants.testPhone,
      'address': TestConstants.testAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'emailVerified': false,
    });

    return Future.value(UserCredential(
      user: mockUser,
      additionalUserInfo: AdditionalUserInfo(isNewUser: true, profile: {}),
    ) as UserCredential);
  }

  /// Create a verified user
  Future<UserCredential> createVerifiedUser({
    String? email,
    String? password,
  }) async {
    final userCredential = await createTestUser(
      email: email,
      password: password,
    );

    await mockFirestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .update({
      'emailVerified': true,
      'emailVerifiedAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  /// Create a worker account
  Future<UserCredential> createWorkerAccount({
    String? email,
    String? password,
  }) async {
    final userCredential = await createTestUser(
      email: email ?? TestConstants.workerEmail,
      password: password,
    );

    await mockFirestore
        .collection('workers')
        .doc(userCredential.user!.uid)
        .set({
      'userId': userCredential.user!.uid,
      'serviceType': 'Plumber',
      'experienceYears': 5,
      'rating': 4.5,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await mockFirestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .update({
      'accountType': 'worker',
    });

    return userCredential;
  }

  /// Simulate account lockout
  Future<void> simulateAccountLockout({
    required String email,
    required int attempts,
  }) async {
    final querySnapshot = await mockFirestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      await mockFirestore.collection('users').doc(doc.id).update({
        'failedLoginAttempts': attempts,
        'lockedUntil': attempts >= 5
            ? DateTime.now().add(Duration(minutes: 15)).toIso8601String()
            : null,
      });
    }
  }

  /// Simulate 2FA verification
  Future<bool> simulate2FA({
    required String uid,
    required String otpCode,
  }) async {
    final doc = await mockFirestore.collection('users').doc(uid).get();

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
      // Increment failed attempts
      final attempts = (data['otpAttempts'] ?? 0) + 1;

      await mockFirestore.collection('users').doc(uid).update({
        'otpAttempts': attempts,
      });

      // Lock after 5 attempts
      if (attempts >= 5) {
        await mockFirestore.collection('users').doc(uid).update({
          'otpLocked': true,
          'otpLockedUntil':
              DateTime.now().add(Duration(hours: 1)).toIso8601String(),
        });
      }

      return false;
    }

    // OTP verified successfully
    await mockFirestore.collection('users').doc(uid).update({
      'phoneVerified': true,
      'phoneVerifiedAt': FieldValue.serverTimestamp(),
      'otpAttempts': 0,
    });

    return true;
  }
}

/// Validation helpers
class ValidationHelper {
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    return password.length >= 6;
  }

  /// Validate phone number (Sri Lankan format)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+94\d{9}$').hasMatch(phone);
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

  /// Match Firestore document existence
  static Future<bool> firestoreDocumentExists({
    required FakeFirebaseFirestore firestore,
    required String collection,
    required String documentId,
  }) async {
    final doc = await firestore.collection(collection).doc(documentId).get();
    return doc.exists;
  }
}

/// Wait helpers for async operations
class WaitHelper {
  /// Wait for authentication state change
  static Future<User?> waitForAuthStateChange({
    required MockFirebaseAuth auth,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<User?>();

    final subscription = auth.authStateChanges().listen((user) {
      if (!completer.isCompleted) {
        completer.complete(user);
      }
    });

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }

  /// Wait for Firestore update
  static Future<void> waitForFirestoreUpdate({
    required Duration duration,
  }) async {
    await Future.delayed(duration);
  }
}

/// Test data generators
class TestDataGenerator {
  /// Generate random email
  static String generateRandomEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test_$timestamp@test.com';
  }

  /// Generate random phone number
  static String generateRandomPhone() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000000;
    return '+94${random.toString().padLeft(9, '0')}';
  }

  /// Generate OTP code
  static String generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }
}
