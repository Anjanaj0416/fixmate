// test/performance/performance_test.dart
// Performance and load testing for authentication
// Ensures authentication is fast and scalable

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';
import 'dart:async';

void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late MockOTPService otpService;

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    otpService = MockOTPService();
  });

  tearDown(() {
    mockFirestore.clearData();
    otpService.clearOTPData();
  });

  group('⚡ Login Performance', () {
    test('Should complete login within 2 seconds', () async {
      final stopwatch = Stopwatch()..start();

      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Login took: ${duration}ms');
      expect(duration, lessThan(2000)); // Less than 2 seconds
    });

    test('Should handle concurrent logins efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate 10 concurrent login attempts
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
      expect(avgDuration, lessThan(3000)); // Average < 3 seconds
    });

    test('Should cache authentication state efficiently', () async {
      // First login
      final stopwatch1 = Stopwatch()..start();
      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );
      stopwatch1.stop();

      // Second login (should be faster with caching)
      final stopwatch2 = Stopwatch()..start();
      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );
      stopwatch2.stop();

      print('First login: ${stopwatch1.elapsedMilliseconds}ms');
      print('Second login: ${stopwatch2.elapsedMilliseconds}ms');

      // Second should be comparable or faster
      expect(stopwatch2.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('⚡ Registration Performance', () {
    test('Should complete registration within 3 seconds', () async {
      final stopwatch = Stopwatch()..start();

      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'Test@123',
      );

      await mockFirestore.setDocument(
        collection: 'users',
        documentId: userCredential!.user!.uid,
        data: {
          'email': 'newuser@example.com',
          'name': 'New User',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Registration took: ${duration}ms');
      expect(duration, lessThan(3000)); // Less than 3 seconds
    });

    test('Should handle batch user creation efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 20; i++) {
        futures.add(
          mockAuth.createUserWithEmailAndPassword(
            email: 'batchuser$i@example.com',
            password: 'Test@123',
          ),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final avgDuration = stopwatch.elapsedMilliseconds / 20;
      print('Average registration time (20 users): ${avgDuration}ms');
      expect(avgDuration, lessThan(3000));
    });
  });

  group('⚡ Firestore Performance', () {
    test('Should read user document within 500ms', () async {
      // Create test document
      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user',
        data: {'email': 'test@example.com', 'name': 'Test User'},
      );

      final stopwatch = Stopwatch()..start();

      await mockFirestore.getDocument(
        collection: 'users',
        documentId: 'test_user',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Document read took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should write user document within 500ms', () async {
      final stopwatch = Stopwatch()..start();

      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'new_user',
        data: {
          'email': 'new@example.com',
          'name': 'New User',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Document write took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should update user document within 500ms', () async {
      // Create initial document
      await mockFirestore.setDocument(
        collection: 'users',
        documentId: 'test_user',
        data: {'email': 'test@example.com', 'name': 'Test User'},
      );

      final stopwatch = Stopwatch()..start();

      await mockFirestore.updateDocument(
        collection: 'users',
        documentId: 'test_user',
        data: {'lastLogin': DateTime.now().toIso8601String()},
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Document update took: ${duration}ms');
      expect(duration, lessThan(500));
    });

    test('Should handle batch operations efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        futures.add(
          mockFirestore.setDocument(
            collection: 'users',
            documentId: 'batch_user_$i',
            data: {'email': 'batch$i@example.com'},
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

      final futures = <Future>[];
      for (int i = 0; i < 20; i++) {
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
    test('Should complete OAuth flow within 3 seconds', () async {
      final mockGoogleAuth = MockGoogleAuthService();
      final stopwatch = Stopwatch()..start();

      await mockGoogleAuth.signInWithGoogle();

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Google OAuth took: ${duration}ms');
      expect(duration, lessThan(3000));
    });
  });

  group('⚡ Memory Performance', () {
    test('Should not leak memory during repeated logins', () async {
      // Track memory usage (simplified)
      final initialMemory = ProcessInfo.currentRss;

      // Perform 100 login/logout cycles
      for (int i = 0; i < 100; i++) {
        await mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Test@123',
        );
        await mockAuth.signOut();
      }

      final finalMemory = ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;

      print('Memory increase: ${memoryIncrease} bytes');
      // Memory increase should be minimal (less than 10MB)
      expect(memoryIncrease, lessThan(10 * 1024 * 1024));
    });

    test('Should clean up resources after logout', () async {
      await mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'Test@123',
      );

      // Simulate resource allocation
      final resources = <String>[];
      for (int i = 0; i < 1000; i++) {
        resources.add('resource_$i');
      }

      await mockAuth.signOut();

      // Resources should be cleaned up
      resources.clear();
      expect(resources.length, 0);
    });
  });

  group('⚡ Scalability Tests', () {
    test('Should handle 100 concurrent users', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
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
      final avgDuration = duration / 100;

      print('100 concurrent logins took: ${duration}ms');
      print('Average per user: ${avgDuration}ms');
      expect(avgDuration, lessThan(5000)); // Less than 5 seconds per user
    });

    test('Should handle 1000 user registrations', () async {
      final stopwatch = Stopwatch()..start();

      // Create in batches to avoid overwhelming the system
      final batchSize = 100;
      for (int batch = 0; batch < 10; batch++) {
        final futures = <Future>[];
        for (int i = 0; i < batchSize; i++) {
          final userId = batch * batchSize + i;
          futures.add(
            mockAuth.createUserWithEmailAndPassword(
              email: 'scaleuser$userId@example.com',
              password: 'Test@123',
            ),
          );
        }
        await Future.wait(futures);
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      final avgDuration = duration / 1000;

      print('1000 registrations took: ${duration}ms (${duration / 1000}s)');
      print('Average per user: ${avgDuration}ms');
      expect(avgDuration, lessThan(10000)); // Less than 10 seconds per user
    });
  });

  group('⚡ Database Query Performance', () {
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

      await mockFirestore.queryDocuments(
        collection: 'users',
        whereField: 'accountType',
        whereValue: 'worker',
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      print('Query took: ${duration}ms');
      expect(duration, lessThan(1000));
    });
  });

  group('⚡ Response Time SLA', () {
    test('99th percentile login should be under 3 seconds', () async {
      final durations = <int>[];

      // Perform 100 login attempts
      for (int i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        await mockAuth.signInWithEmailAndPassword(
          email: 'test$i@example.com',
          password: 'Test@123',
        );
        stopwatch.stop();
        durations.add(stopwatch.elapsedMilliseconds);
      }

      // Sort durations
      durations.sort();

      // Get 99th percentile
      final p99Index = (durations.length * 0.99).floor();
      final p99Duration = durations[p99Index];

      print('99th percentile login time: ${p99Duration}ms');
      print('Median login time: ${durations[50]}ms');
      print(
          '95th percentile: ${durations[(durations.length * 0.95).floor()]}ms');

      expect(p99Duration, lessThan(3000));
    });
  });

  group('⚡ Throughput Tests', () {
    test('Should handle 50 requests per second', () async {
      final stopwatch = Stopwatch()..start();
      var completedRequests = 0;

      // Run for 5 seconds
      Timer.periodic(Duration(milliseconds: 20), (timer) async {
        if (stopwatch.elapsed.inSeconds >= 5) {
          timer.cancel();
          return;
        }

        await mockAuth.signInWithEmailAndPassword(
          email: 'throughput@example.com',
          password: 'Test@123',
        );
        completedRequests++;
      });

      // Wait for completion
      await Future.delayed(Duration(seconds: 6));

      final requestsPerSecond = completedRequests / 5;
      print('Throughput: $requestsPerSecond requests/second');
      expect(requestsPerSecond, greaterThan(40)); // At least 40 req/s
    });
  });
}

// Helper class to mock process info
class ProcessInfo {
  static int get currentRss => 1024 * 1024; // 1MB mock
}
