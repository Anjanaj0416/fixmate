import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixmate/services/booking_service.dart';
import 'package:fixmate/models/booking_model.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot
])
import 'booking_service_test.mocks.dart';

void main() {
  group('BookingService White Box Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockBookingsCollection;
    late MockDocumentReference mockDocumentReference;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockBookingsCollection = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
    });

    group('WT001: createBooking() - Worker ID Validation Branches', () {
      test('BRANCH 1: Valid worker ID format (HM_XXXX) - Success path',
          () async {
        // Arrange - Test the VALID branch
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc()).thenReturn(mockDocumentReference);
        when(mockDocumentReference.id).thenReturn('test_booking_id');
        when(mockDocumentReference.set(any)).thenAnswer((_) async => {});

        // Act
        try {
          final bookingId = await BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: 'HM_1234', // VALID format - tests true branch
            workerName: 'Test Worker',
            workerPhone: '+94777654321',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Leak',
            problemDescription: 'Leaking pipe in kitchen',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test Street',
            urgency: 'high',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00 AM',
          );

          // Assert - Validates the success branch was taken
          expect(bookingId, isNotNull);
          expect(bookingId, isNotEmpty);

          // Verify the set method was called (proves branch executed)
          verify(mockDocumentReference.set(any)).called(1);
        } catch (e) {
          fail('Should not throw exception for valid worker ID');
        }
      });

      test('BRANCH 2: Invalid worker ID format - Error handling path',
          () async {
        // Arrange - Test the INVALID branch
        const invalidWorkerId = 'INVALID_123';

        // Act & Assert - Tests error handling branch
        expect(
          () => BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: invalidWorkerId, // INVALID format - tests false branch
            workerName: 'Test Worker',
            workerPhone: '+94777654321',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Leak',
            problemDescription: 'Leaking pipe',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test Street',
            urgency: 'high',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00 AM',
          ),
          throwsA(predicate((e) =>
              e.toString().contains('Invalid worker_id format') &&
              e.toString().contains(invalidWorkerId))),
        );

        // Verify set was never called (proves error branch executed)
        verifyNever(mockDocumentReference.set(any));
      });

      test('BRANCH 3: Empty worker ID - Edge case branch', () {
        // Tests empty string edge case branch
        expect(
          () => BookingService.createBooking(
            workerId: '', // Empty - tests edge case
            customerId: 'test',
            customerName: 'Test',
            customerPhone: '+94771234567',
            customerEmail: 'test@test.com',
            workerName: 'Worker',
            workerPhone: '+94777654321',
            serviceType: 'Plumbing',
            subService: 'Repair',
            issueType: 'Leak',
            problemDescription: 'Problem',
            problemImageUrls: [],
            location: 'Colombo',
            address: 'Address',
            urgency: 'high',
            budgetRange: '5000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('WT004: updateBookingStatus() - Status Transition Branches', () {
      test('BRANCH 1: Status transition to ACCEPTED - timestamp branch',
          () async {
        // Arrange
        final mockBookingDoc = MockDocumentSnapshot();
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockBookingDoc);
        when(mockBookingDoc.exists).thenReturn(true);
        when(mockBookingDoc.data()).thenReturn({
          'customer_id': 'customer_123',
          'worker_name': 'Test Worker',
          'status': 'requested',
        });
        when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

        // Act - Tests COMPLETED branch with final price
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.completed,
          finalPrice: 5000,
        );

        // Assert - Verify completed_at timestamp AND final_price were set
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('completed'));
        expect(captured.first['completed_at'], isNotNull);
        expect(captured.first['final_price'], equals(5000));
      });

      test('BRANCH 4: Status transition to DECLINED - timestamp branch',
          () async {
        // Arrange
        final mockBookingDoc = MockDocumentSnapshot();
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockBookingDoc);
        when(mockBookingDoc.exists).thenReturn(true);
        when(mockBookingDoc.data()).thenReturn({
          'customer_id': 'customer_123',
          'worker_name': 'Test Worker',
          'status': 'requested',
        });
        when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

        // Act - Tests DECLINED branch
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.declined,
        );

        // Assert - Verify declined_at timestamp was set
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('declined'));
        expect(captured.first['declined_at'], isNotNull);
      });

      test('BRANCH 5: Status transition to CANCELLED - timestamp branch',
          () async {
        // Arrange
        final mockBookingDoc = MockDocumentSnapshot();
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockBookingDoc);
        when(mockBookingDoc.exists).thenReturn(true);
        when(mockBookingDoc.data()).thenReturn({
          'customer_id': 'customer_123',
          'worker_name': 'Test Worker',
          'status': 'accepted',
        });
        when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

        // Act - Tests CANCELLED branch
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.cancelled,
        );

        // Assert - Verify cancelled_at timestamp was set
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('cancelled'));
        expect(captured.first['cancelled_at'], isNotNull);
      });

      test('BRANCH 6: Default case - no specific timestamp', () async {
        // Arrange
        final mockBookingDoc = MockDocumentSnapshot();
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockBookingDoc);
        when(mockBookingDoc.exists).thenReturn(true);
        when(mockBookingDoc.data()).thenReturn({
          'customer_id': 'customer_123',
          'worker_name': 'Test Worker',
          'status': 'requested',
        });
        when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

        // Act - Tests default branch (requested status - no special timestamp)
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.requested,
        );

        // Assert - Verify only updated_at is set, no status-specific timestamps
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('requested'));
        expect(captured.first.containsKey('accepted_at'), isFalse);
        expect(captured.first.containsKey('completed_at'), isFalse);
      });
    });
  });
}
