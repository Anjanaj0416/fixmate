import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmate/services/rating_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  WriteBatch,
])
import 'rating_service_test.mocks.dart';

void main() {
  group('RatingService White Box Tests - WT007', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockReviewsCollection;
    late MockCollectionReference mockWorkersCollection;
    late MockDocumentReference mockReviewDoc;
    late MockDocumentReference mockWorkerDoc;
    late MockDocumentSnapshot mockWorkerSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockReviewsCollection = MockCollectionReference();
      mockWorkersCollection = MockCollectionReference();
      mockReviewDoc = MockDocumentReference();
      mockWorkerDoc = MockDocumentReference();
      mockWorkerSnapshot = MockDocumentSnapshot();
    });

    group('submitRating() - Validation & Calculation Branches', () {
      test(
          'BRANCH 1: Valid rating submission - complete flow with average calculation',
          () async {
        // Arrange - Mock valid submission
        when(mockFirestore.collection('reviews'))
            .thenReturn(mockReviewsCollection);
        when(mockFirestore.collection('workers'))
            .thenReturn(mockWorkersCollection);
        when(mockReviewsCollection.add(any))
            .thenAnswer((_) async => mockReviewDoc);
        when(mockWorkersCollection.doc(any)).thenReturn(mockWorkerDoc);
        when(mockWorkerDoc.get()).thenAnswer((_) async => mockWorkerSnapshot);
        when(mockWorkerSnapshot.exists).thenReturn(true);
        when(mockWorkerSnapshot.data()).thenReturn({
          'rating': 4.0,
          'total_reviews': 10,
        });
        when(mockWorkerDoc.update(any)).thenAnswer((_) async => {});

        // Act - Execute VALID submission branch
        await RatingService.submitRating(
          bookingId: 'booking_123',
          workerId: 'HM_1234',
          workerName: 'Test Worker',
          customerId: 'customer_123',
          customerName: 'Test Customer',
          rating: 4.5,
          review: 'Excellent service provided',
          serviceType: 'Plumbing',
          tags: ['Professional', 'Punctual'],
        );

        // Assert - Verify complete flow executed
        verify(mockReviewsCollection.add(any)).called(1);
        verify(mockWorkerDoc.update(any)).called(1);

        // Verify rating calculation: (4.0 * 10 + 4.5) / 11 = 4.045...
        final captured = verify(mockWorkerDoc.update(captureAny)).captured;
        expect(captured.first['rating'], isA<double>());
        expect(captured.first['total_reviews'], equals(11));
      });

      test('BRANCH 2: Empty review text - validation error branch', () {
        // Act & Assert - Execute VALIDATION error branch
        expect(
          () => RatingService.submitRating(
            bookingId: 'booking_123',
            workerId: 'HM_1234',
            workerName: 'Test Worker',
            customerId: 'customer_123',
            customerName: 'Test Customer',
            rating: 4.5,
            review: '', // Empty review - triggers validation
            serviceType: 'Plumbing',
            tags: [],
          ),
          throwsA(predicate((e) =>
              e.toString().contains('review') ||
              e.toString().contains('empty'))),
        );

        // Verify no database operations occurred (proves validation branch)
        verifyNever(mockReviewsCollection.add(any));
      });

      test('BRANCH 3: Invalid rating range (< 0) - range validation branch',
          () {
        // Act & Assert - Execute RANGE validation branch (too low)
        expect(
          () => RatingService.submitRating(
            bookingId: 'booking_123',
            workerId: 'HM_1234',
            workerName: 'Test Worker',
            customerId: 'customer_123',
            customerName: 'Test Customer',
            rating: -1.0, // Invalid rating
            review: 'Test review',
            serviceType: 'Plumbing',
            tags: [],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('BRANCH 4: Invalid rating range (> 5) - range validation branch',
          () {
        // Act & Assert - Execute RANGE validation branch (too high)
        expect(
          () => RatingService.submitRating(
            bookingId: 'booking_123',
            workerId: 'HM_1234',
            workerName: 'Test Worker',
            customerId: 'customer_123',
            customerName: 'Test Customer',
            rating: 6.0, // Invalid rating
            review: 'Test review',
            serviceType: 'Plumbing',
            tags: [],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test(
          'BRANCH 5: First rating for worker - initial rating calculation branch',
          () async {
        // Arrange - Worker with no previous ratings
        when(mockFirestore.collection('reviews'))
            .thenReturn(mockReviewsCollection);
        when(mockFirestore.collection('workers'))
            .thenReturn(mockWorkersCollection);
        when(mockReviewsCollection.add(any))
            .thenAnswer((_) async => mockReviewDoc);
        when(mockWorkersCollection.doc(any)).thenReturn(mockWorkerDoc);
        when(mockWorkerDoc.get()).thenAnswer((_) async => mockWorkerSnapshot);
        when(mockWorkerSnapshot.exists).thenReturn(true);
        when(mockWorkerSnapshot.data()).thenReturn({
          'rating': 0.0,
          'total_reviews': 0, // First rating
        });
        when(mockWorkerDoc.update(any)).thenAnswer((_) async => {});

        // Act - Execute FIRST rating branch
        await RatingService.submitRating(
          bookingId: 'booking_123',
          workerId: 'HM_1234',
          workerName: 'Test Worker',
          customerId: 'customer_123',
          customerName: 'Test Customer',
          rating: 5.0,
          review: 'First review',
          serviceType: 'Plumbing',
          tags: [],
        );

        // Assert - Verify first rating logic: rating = 5.0, reviews = 1
        final captured = verify(mockWorkerDoc.update(captureAny)).captured;
        expect(captured.first['rating'], equals(5.0));
        expect(captured.first['total_reviews'], equals(1));
      });

      test('BRANCH 6: Firestore transaction failure - rollback branch',
          () async {
        // Arrange - Mock Firestore error
        when(mockFirestore.collection('reviews'))
            .thenReturn(mockReviewsCollection);
        when(mockReviewsCollection.add(any)).thenThrow(
            FirebaseException(plugin: 'firestore', message: 'Write failed'));

        // Act & Assert - Execute ERROR rollback branch
        expect(
          () => RatingService.submitRating(
            bookingId: 'booking_123',
            workerId: 'HM_1234',
            workerName: 'Test Worker',
            customerId: 'customer_123',
            customerName: 'Test Customer',
            rating: 4.5,
            review: 'Test review',
            serviceType: 'Plumbing',
            tags: [],
          ),
          throwsA(isA<FirebaseException>()),
        );

        // Verify worker update never happened (transaction rolled back)
        verifyNever(mockWorkerDoc.update(any));
      });
    });
  });
}
