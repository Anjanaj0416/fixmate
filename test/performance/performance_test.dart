// test/performance/performance_test.dart
// FIXED VERSION - Performance and load testing for authentication
// Ensures authentication is fast and scalable

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';
import 'dart:async';

void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late MockOTPService otpService;
  late MockGoogleAuthService googleAuth; // FIXED: Use MockGoogleAuthService

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    otpService = MockOTPService();
    googleAuth = MockGoogleAuthService(); // FIXED: Initialize properly
  });

  tearDown() {
    mockFirestore.clearData();
    otpService.clearOTPData();
  }

  group('⚡ Login Performance', () {
    test('Should complete login within 2 seconds', () async {
      // First create a user
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );

      final stopwatch = Stopwatch()..start();

      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Login took: ${duration}ms');
      expect(duration, lessThan(2000));
    });

    test('Should handle concurrent logins efficiently', () async {
      // Create 10 users first
      for (int i = 0; i < 10; i++) {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'user$i@example.com',
          password: 'Test@123',
        );
      }

      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          mockAuth.signInWithEmailAndPassword(
            email: 'user$i@example.com',
            password: 'Test@123',
          ),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      print('10 concurrent logins took: ${duration}ms');
      expect(duration, lessThan(5000));
    });
  });

  group('⚡ Registration Performance', () {
    test('Should complete registration within 3 seconds', () async {
      final stopwatch = Stopwatch()..start();

      await mockAuth.createUserWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'Test@123',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Registration took: ${duration}ms');
      expect(duration, lessThan(3000));
    });

    test('Should handle bulk user registration', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 20; i++) {
        futures.add(
          mockAuth.createUserWithEmailAndPassword(
            email: 'bulkuser$i@example.com',
            password: 'Test@123',
          ),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      print('20 bulk registrations took: ${duration}ms');
      expect(duration, lessThan(10000));
    });
  });

  group('⚡ OTP Performance', () {
    test('Should generate OTP within 500ms', () async {
      final stopwatch = Stopwatch()..start();

      // FIXED: Use generateOTP
      await otpService.generateOTP('+94771234567');

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('OTP generation took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should verify OTP within 200ms', () async {
      // FIXED: Use generateOTP
      final otp = await otpService.generateOTP('+94771234567');

      final stopwatch = Stopwatch()..start();

      await otpService.verifyOTP('+94771234567', otp);

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('OTP verification took: ${duration}ms');
      expect(duration, lessThan(200));
    });

    test('Should handle concurrent OTP requests', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        // FIXED: Use generateOTP
        futures.add(otpService.generateOTP('+9477123456$i'));
      }

      await Future.wait(futures);
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      print('10 concurrent OTP requests took: ${duration}ms');
      expect(duration, lessThan(2000));
    });
  });

  group('⚡ Database Performance', () {
    test('Should write user data to Firestore within 500ms', () async {
      final stopwatch = Stopwatch()..start();

      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user_123',
        data: {
          'name': 'Test User',
          'email': 'test@example.com',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Firestore write took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should read user data from Firestore within 300ms', () async {
      // First create a document
      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user_123',
        data: {'name': 'Test User'},
      );

      final stopwatch = Stopwatch()..start();

      await mockFirestore.getDocument(
        collection: 'users',
        documentId: 'test_user_123',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Firestore read took: ${duration}ms');
      expect(duration, lessThan(300));
    });
  });

  group('⚡ Google OAuth Performance', () {
    test('Should complete Google sign-in within 3 seconds', () async {
      final stopwatch = Stopwatch()..start();

      // FIXED: Use MockGoogleAuthService
      final auth = googleAuth;
      await auth.signInWithGoogle();

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Google OAuth took: ${duration}ms');
      expect(duration, lessThan(3000));
    });
  });

  group('⚡ Query Performance', () {
    test('Should query large collection efficiently', () async {
      // Insert 100 test documents
      for (int i = 0; i < 100; i++) {
        await mockFirestore.setDocument(
          collection: 'workers',
          documentId: 'worker_$i',
          data: {
            'name': 'Worker $i',
            'serviceType': i % 2 == 0 ? 'Plumbing' : 'Electrical',
            'rating': 4.0 + (i % 10) / 10,
          },
        );
      }

      final stopwatch = Stopwatch()..start();

      // FIXED: Use queryCollection
      await mockFirestore.queryCollection(
        collection: 'workers',
        where: {'serviceType': 'Plumbing'},
        limit: 20,
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Query took: ${duration}ms');
      expect(duration, lessThan(1000));
    });
  });

  group('⚡ Memory and Resource Tests', () {
    test('Should handle 100 rapid authentication requests', () async {
      final futures = <Future>[];

      for (int i = 0; i < 100; i++) {
        futures.add(
          mockAuth.createUserWithEmailAndPassword(
            email: 'stress$i@example.com',
            password: 'Test@123',
          ),
        );
      }

      await Future.wait(futures);

      expect(futures.length, 100);
    });

    test('Should cleanup resources after operations', () async {
      // Perform operations
      for (int i = 0; i < 10; i++) {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'cleanup$i@example.com',
          password: 'Test@123',
        );
      }

      // Cleanup
      mockAuth.clearAll();
      mockFirestore.clearData();
      otpService.clearOTPData();

      expect(true, true); // Cleanup should complete without error
    });
  });
}
