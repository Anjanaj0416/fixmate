import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixmate/services/booking_service.dart';
import 'package:fixmate/models/booking_model.dart';

// FIXED: Added DocumentSnapshot with proper type parameter
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  QuerySnapshot
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(
      as: #MockCollectionReference),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(
      // FIXED: Added type parameter
      as: #MockDocumentSnapshot),
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
            issueType: 'Emergency',
            problemDescription: 'Leaking pipe',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test St',
            urgency: 'high',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now().add(Duration(days: 1)),
            scheduledTime: '10:00 AM',
          );

          // Assert
          expect(bookingId, isNotNull);
          verify(mockBookingsCollection.doc()).called(1);
          verify(mockDocumentReference.set(any)).called(1);
        } catch (e) {
          fail('Should not throw exception for valid worker ID: $e');
        }
      });

      test('BRANCH 2: Invalid worker ID format - Error path', () async {
        // Arrange - Test the INVALID branch
        when(mockFirestore.collection('bookings'))
            .thenReturn(mockBookingsCollection);
        when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentReference);

        // Act & Assert
        expect(
          () => BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: 'INVALID_123', // INVALID format - tests false branch
            workerName: 'Test Worker',
            workerPhone: '+94777654321',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Emergency',
            problemDescription: 'Leaking pipe',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test St',
            urgency: 'high',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now().add(Duration(days: 1)),
            scheduledTime: '10:00 AM',
          ),
          throwsA(predicate((e) =>
              e.toString().contains('Invalid worker_id format') ||
              e.toString().contains('INVALID_123'))),
        );
      });

      test('BRANCH 3: Empty worker ID - Validation path', () async {
        // Test empty string validation
        expect(
          () => BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: '', // Empty worker ID
            workerName: 'Test Worker',
            workerPhone: '+94777654321',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Emergency',
            problemDescription: 'Leaking pipe',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test St',
            urgency: 'high',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now().add(Duration(days: 1)),
            scheduledTime: '10:00 AM',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Additional White Box Coverage', () {
      test('BRANCH 4: Status transition to ACCEPTED', () async {
        // Arrange - FIXED: Use properly typed mock
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

        // Act
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.accepted,
        );

        // Assert
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('accepted'));
        expect(captured.first['accepted_at'], isNotNull);
      });

      test('BRANCH 5: Status transition to IN_PROGRESS', () async {
        // Arrange - FIXED: Use properly typed mock
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

        // Act
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.inProgress,
        );

        // Assert
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('in_progress'));
        expect(captured.first['started_at'], isNotNull);
      });

      test('BRANCH 6: Status transition to DECLINED', () async {
        // Arrange - FIXED: Use properly typed mock
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

        // Act
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.declined,
        );

        // Assert
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('declined'));
        expect(captured.first['declined_at'], isNotNull);
      });

      test('BRANCH 7: Status transition to CANCELLED', () async {
        // Arrange - FIXED: Use properly typed mock
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

        // Act
        await BookingService.updateBookingStatus(
          bookingId: 'test_booking',
          newStatus: BookingStatus.cancelled,
        );

        // Assert
        final captured =
            verify(mockDocumentReference.update(captureAny)).captured;
        expect(captured.first['status'], equals('cancelled'));
        expect(captured.first['cancelled_at'], isNotNull);
      });
    });
  });
}
