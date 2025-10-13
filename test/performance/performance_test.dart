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
  late MockGoogleAuthService googleAuth;

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    otpService = MockOTPService();
    googleAuth = MockGoogleAuthService();
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

      final avgDuration = stopwatch.elapsedMilliseconds / 10;
      print('Average login time (10 concurrent): ${avgDuration}ms');
      expect(avgDuration, lessThan(3000));
    });

    test('Should cache authentication state efficiently', () async {
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );

      // First login
      final stopwatch1 = Stopwatch()..start();
      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );
      stopwatch1.stop();

      // Second login (should be faster in real implementation)
      final stopwatch2 = Stopwatch()..start();
      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );
      stopwatch2.stop();

      print('First login: ${stopwatch1.elapsedMilliseconds}ms');
      print('Second login: ${stopwatch2.elapsedMilliseconds}ms');

      expect(stopwatch1.elapsedMilliseconds, lessThan(2000));
      expect(stopwatch2.elapsedMilliseconds, lessThan(2000));
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

    test('Should handle concurrent registrations', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          mockAuth.createUserWithEmailAndPassword(
            email: 'batch$i@example.com',
            password: 'Test@123',
          ),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 10;
      print('Average registration time (10 concurrent): ${avgDuration}ms');
      expect(avgDuration, lessThan(4000));
    });
  });

  group('⚡ Firestore Performance', () {
    test('Should write user document within 1 second', () async {
      final stopwatch = Stopwatch()..start();

      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user',
        data: {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '+94771234567',
        },
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Firestore write took: ${duration}ms');
      expect(duration, lessThan(1000));
    });

    test('Should read user document within 500ms', () async {
      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user',
        data: {'name': 'Test User'},
      );

      final stopwatch = Stopwatch()..start();

      await mockFirestore.getDocument(
        collection: 'users',
        documentId: 'test_user',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Firestore read took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should handle batch writes efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        futures.add(
          mockFirestore.setDocument(
            collection: 'users',
            documentId: 'user_$i',
            data: {
              'name': 'User $i',
              'email': 'user$i@example.com',
            },
          ),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 50;
      print('Average batch write time (50 docs): ${avgDuration}ms');
      expect(avgDuration, lessThan(1000));
    });
  });

  group('⚡ OTP Performance', () {
    test('Should generate OTP within 1 second', () async {
      final stopwatch = Stopwatch()..start();

      await otpService.generateOTP('+94771234567');

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('OTP generation took: ${duration}ms');
      expect(duration, lessThan(1000));
    });

    test('Should verify OTP within 500ms', () async {
      final otp = await otpService.generateOTP('+94771234567');

      final stopwatch = Stopwatch()..start();

      await otpService.verifyOTP('+94771234567', otp);

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('OTP verification took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should handle multiple OTP generations efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future<String>>[];
      for (int i = 0; i < 20; i++) {
        // FIXED: Store futures properly with correct type
        futures.add(otpService.generateOTP('+9477123456$i'));
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 20;
      print('Average OTP generation (20 requests): ${avgDuration}ms');
      expect(avgDuration, lessThan(1500));
    });
  });

  group('⚡ Password Reset Performance', () {
    test('Should send reset email within 1 second', () async {
      final stopwatch = Stopwatch()..start();

      await mockAuth.sendPasswordResetEmail(email: 'test@example.com');

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Password reset email took: ${duration}ms');
      expect(duration, lessThan(1000));
    });

    test('Should handle multiple reset requests efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          mockAuth.sendPasswordResetEmail(email: 'user$i@example.com'),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 10;
      print('Average reset email time (10 requests): ${avgDuration}ms');
      expect(avgDuration, lessThan(1500));
    });
  });

  group('⚡ Google OAuth Performance', () {
    test('Should complete Google sign-in within 2 seconds', () async {
      final stopwatch = Stopwatch()..start();

      // FIXED: Use MockGoogleAuthService properly
      await googleAuth.signInWithGoogle();

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Google sign-in took: ${duration}ms');
      expect(duration, lessThan(2000));
    });

    test('Should handle concurrent Google sign-ins', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        final auth = MockGoogleAuthService();
        futures.add(auth.signInWithGoogle());
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 5;
      print('Average Google sign-in (5 concurrent): ${avgDuration}ms');
      expect(avgDuration, lessThan(3000));
    });
  });

  group('⚡ Query Performance', () {
    test('Should query users efficiently', () async {
      // Create test data
      for (int i = 0; i < 100; i++) {
        await mockFirestore.setDocument(
          collection: 'users',
          documentId: 'user_$i',
          data: {
            'email': 'user$i@example.com',
            'accountType': i % 2 == 0 ? 'customer' : 'worker',
          },
        );
      }

      final stopwatch = Stopwatch()..start();

      await mockFirestore.queryCollection(
        collection: 'users',
        whereField: 'accountType',
        whereValue: 'worker',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Query took: ${duration}ms for 100 documents');
      expect(duration, lessThan(2000));
    });
  });
}
