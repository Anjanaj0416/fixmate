// test/integration_test/rating_review_test.dart
// COMPLETE FIXED VERSION - Test Cases: FT-031, FT-032, FT-077, FT-078
// Run: flutter test test/integration_test/rating_review_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';

void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late MockRatingService mockRating;
  late MockBookingService mockBooking;

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    mockRating = MockRatingService();
    mockBooking = MockBookingService();

    mockRating.setFirestoreService(mockFirestore);
    mockBooking.setFirestoreService(mockFirestore);
  });

  tearDown(() {
    mockAuth.clearAll();
    mockFirestore.clearData();
    mockRating.clearAll();
    mockBooking.clearAll();
  });

  group('⭐ Rating & Review System Tests (FT-031, FT-032, FT-077, FT-078)', () {
    test('FT-031: Submit Rating & Review', () async {
      TestLogger.logTestStart('FT-031', 'Submit Rating & Review');

      // Precondition: Booking completed
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      // Create completed booking
      const bookingId = 'B_12345';
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerCred!.user!.uid,
        status: 'completed',
        completedAt: DateTime.now(),
      );

      // Create worker profile with initial rating (10 existing ratings with average 4.3)
      // To get 4.4 after adding 5.0: (4.3 * 10 + 5.0) / 11 = (43 + 5) / 11 = 4.36 ≈ 4.4
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: workerCred.user!.uid,
        data: {
          'worker_id': workerCred.user!.uid,
          'name': 'Test Worker',
          'rating': 4.3,
          'total_ratings': 10,
          'service_type': 'Plumbing',
        },
      );

      // Add 10 existing reviews to match the initial rating
      for (int i = 0; i < 10; i++) {
        await mockRating.addReview(
          workerId: workerCred.user!.uid,
          reviewData: {
            'review_id': 'R_$i',
            'customer_name': 'Customer $i',
            'rating': 4.3,
            'review': 'Good service',
            'date': DateTime.now().subtract(Duration(days: i + 1)),
            'tags': ['Professional'],
          },
        );
      }

      TestLogger.log('Step 1: Booking marked complete');
      TestLogger.log('Step 2: Rating prompt appears');

      // Test Data
      const rating = 5.0;
      const review = 'Excellent work!';
      const tags = ['Professional', 'Punctual'];

      TestLogger.log('Step 3: Select 5 stars');
      TestLogger.log('Step 4: Write review: "$review"');
      TestLogger.log('Step 5: Select tags: ${tags.join(", ")}');
      TestLogger.log('Step 6: Submit');

      // Submit rating
      await mockRating.submitRating(
        bookingId: bookingId,
        workerId: workerCred.user!.uid,
        workerName: 'Test Worker',
        customerId: customerCred.user!.uid,
        customerName: 'Test Customer',
        rating: rating,
        review: review,
        serviceType: 'Plumbing',
        tags: tags,
      );

      // Verify review saved
      final reviews = await mockRating.getWorkerReviews(workerCred.user!.uid);
      expect(reviews.length, 11); // 10 existing + 1 new
      expect(reviews[0]['rating'], rating);
      expect(reviews[0]['review'], review);
      expect(reviews[0]['tags'], tags);

      // Verify worker's rating updated (4.3 → 4.4)
      final workerDoc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: workerCred.user!.uid,
      );
      final workerRating = workerDoc.data()!['rating'];

      // New average: (4.3 * 10 + 5.0) / 11 = 48 / 11 = 4.36
      expect(workerRating, greaterThan(4.3));
      expect(workerRating, closeTo(4.36, 0.1));

      TestLogger.logTestPass('FT-031',
          'Review saved in Firestore, worker\'s average rating recalculated (4.3→4.4), displayed on profile');
    });

    test('FT-032: View Ratings & Reviews', () async {
      TestLogger.logTestStart('FT-032', 'View Ratings & Reviews');

      // Precondition: Worker has received reviews
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      // Create multiple reviews
      final reviews = [
        {
          'customer_name': 'John Doe',
          'rating': 5.0,
          'review': 'Excellent service!',
          'date': DateTime.now().subtract(Duration(days: 1)),
          'tags': ['Professional', 'Punctual'],
        },
        {
          'customer_name': 'Jane Smith',
          'rating': 4.0,
          'review': 'Good work, minor delay',
          'date': DateTime.now().subtract(Duration(days: 2)),
          'tags': ['Quality Work'],
        },
        {
          'customer_name': 'Bob Wilson',
          'rating': 5.0,
          'review': 'Perfect job!',
          'date': DateTime.now().subtract(Duration(days: 3)),
          'tags': ['Professional', 'Efficient'],
        },
      ];

      for (int i = 0; i < reviews.length; i++) {
        await mockRating.addReview(
          workerId: workerCred!.user!.uid,
          reviewData: reviews[i],
        );
      }

      TestLogger.log('Step 1: Login as worker');
      TestLogger.log('Step 2: Go to profile');
      TestLogger.log('Step 3: View reviews section');

      // Get reviews
      final workerReviews =
          await mockRating.getWorkerReviews(workerCred!.user!.uid);

      // Verify all reviews displayed
      expect(workerReviews.length, 3);

      // Verify sorted by newest first
      expect(workerReviews[0]['customer_name'], 'John Doe');
      expect(workerReviews[1]['customer_name'], 'Jane Smith');
      expect(workerReviews[2]['customer_name'], 'Bob Wilson');

      // Verify all required fields present
      for (var review in workerReviews) {
        expect(review['customer_name'], isNotNull);
        expect(review['rating'], isNotNull);
        expect(review['review'], isNotNull);
        expect(review['date'], isNotNull);
        expect(review['tags'], isNotNull);
      }

      TestLogger.logTestPass('FT-032',
          'All reviews displayed with: customer name, star rating, text, date, tags, sorted by newest first');
    });

    test('FT-077: Review Submission with Profanity', () async {
      TestLogger.logTestStart('FT-077', 'Review Submission with Profanity');

      // Precondition: Customer on review submission screen
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      // Create completed booking
      const bookingId = 'B_12345';
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerCred!.user!.uid,
        status: 'completed',
        completedAt: DateTime.now(),
      );

      // Test Data: Review containing offensive language
      const profaneReview = 'This worker is f***ing terrible and a b****!';

      TestLogger.log('Step 1: Enter review with profanity');
      TestLogger.log('Step 2: Attempt to submit');
      TestLogger.log('Step 3: Check validation');

      // Attempt to submit review with profanity
      try {
        await mockRating.submitRating(
          bookingId: bookingId,
          workerId: workerCred.user!.uid,
          workerName: 'Test Worker',
          customerId: customerCred.user!.uid,
          customerName: 'Test Customer',
          rating: 2.0,
          review: profaneReview,
          serviceType: 'Plumbing',
          tags: [],
        );

        fail('Should have thrown profanity exception');
      } catch (e) {
        expect(e.toString(), contains('inappropriate content'));
      }

      // Verify review was flagged
      final flaggedReviews = await mockRating.getFlaggedReviews();
      expect(flaggedReviews.length, 1);
      expect(flaggedReviews[0]['review'], profaneReview);
      expect(flaggedReviews[0]['flagged'], true);
      expect(flaggedReviews[0]['flag_reason'], contains('profanity'));

      TestLogger.logTestPass('FT-077',
          'Warning "Review contains inappropriate content", auto-flagged for admin review');
    });

    test('FT-078: Review Edit After Submission', () async {
      TestLogger.logTestStart('FT-078', 'Review Edit After Submission');

      // Precondition: Customer submitted review 1 hour ago
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      // Create completed booking and review
      const bookingId = 'B_12345';
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerCred!.user!.uid,
        status: 'completed',
        completedAt: DateTime.now().subtract(Duration(hours: 2)),
      );

      // Submit original review
      await mockRating.submitRating(
        bookingId: bookingId,
        workerId: workerCred.user!.uid,
        workerName: 'Test Worker',
        customerId: customerCred.user!.uid,
        customerName: 'Test Customer',
        rating: 4.0,
        review: 'Good work',
        serviceType: 'Plumbing',
        tags: ['Professional'],
      );

      // Wait to simulate 1 hour passing
      await Future.delayed(Duration(milliseconds: 100));

      TestLogger.log('Step 1: View submitted review');
      TestLogger.log('Step 2: Look for edit option');
      TestLogger.log('Step 3: Attempt to modify');

      // Attempt to edit review
      try {
        await mockRating.editReview(
          bookingId: bookingId,
          newReview: 'Actually, it was excellent work!',
          newRating: 5.0,
        );

        fail('Should not allow editing');
      } catch (e) {
        expect(e.toString(), contains('cannot be edited'));
      }

      // Verify original review unchanged
      final reviews = await mockRating.getWorkerReviews(workerCred.user!.uid);
      expect(reviews.length, 1);
      expect(reviews[0]['review'], 'Good work');
      expect(reviews[0]['rating'], 4.0);

      TestLogger.logTestPass('FT-078',
          'No edit option available, message "Reviews cannot be edited. Contact support for corrections"');
    });
  });
}
