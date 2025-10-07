import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:fixmate/services/booking_service.dart';
import 'package:fixmate/models/booking_model.dart';
import 'package:flutter/services.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  QuerySnapshot
], customMocks: [
  MockSpec<CollectionReference<Map<String, dynamic>>>(
      as: #MockCollectionReference),
  MockSpec<DocumentReference<Map<String, dynamic>>>(as: #MockDocumentReference),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(as: #MockDocumentSnapshot),
])
import 'booking_service_test.mocks.dart';

// ADDED: Firebase Mock Setup
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase Core mock platform
  MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    return null;
  });
}

void main() {
  // ADDED: Setup Firebase mocks before any tests
  setUpAll(() async {
    setupFirebaseMocks();
    await Firebase.initializeApp();
  });

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

        // Act & Assert - Should not throw exception for valid worker ID
        try {
          final bookingId = await BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: 'HM_1234', // VALID FORMAT
            workerName: 'Test Worker',
            workerPhone: '+94771234568',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Leak',
            problemDescription: 'Water leak in kitchen',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test Street',
            urgency: 'normal',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00 AM',
          );

          // Test passes if no exception thrown
          expect(bookingId, isNotEmpty);
          print('✅ BRANCH 1 PASSED: Valid worker ID accepted');
        } catch (e) {
          fail('Should not throw exception for valid worker ID: $e');
        }
      });

      test('BRANCH 2: Invalid worker ID format - Error path', () async {
        // Act & Assert - Should throw exception for invalid format
        try {
          await BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: 'INVALID_123', // INVALID FORMAT
            workerName: 'Test Worker',
            workerPhone: '+94771234568',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Leak',
            problemDescription: 'Water leak in kitchen',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test Street',
            urgency: 'normal',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00 AM',
          );

          fail('Should throw exception for invalid worker ID format');
        } catch (e) {
          // Expected error
          expect(e.toString(), contains('Invalid worker_id format'));
          expect(e.toString(), contains('INVALID_123'));
          print('✅ BRANCH 2 PASSED: Invalid worker ID rejected');
        }
      });

      test('BRANCH 3: Empty worker ID - Validation path', () async {
        // Act & Assert - Should throw exception for empty worker ID
        try {
          await BookingService.createBooking(
            customerId: 'test_customer',
            customerName: 'Test Customer',
            customerPhone: '+94771234567',
            customerEmail: 'test@example.com',
            workerId: '', // EMPTY
            workerName: 'Test Worker',
            workerPhone: '+94771234568',
            serviceType: 'Plumbing',
            subService: 'Pipe Repair',
            issueType: 'Leak',
            problemDescription: 'Water leak in kitchen',
            problemImageUrls: [],
            location: 'Colombo',
            address: '123 Test Street',
            urgency: 'normal',
            budgetRange: '5000-10000',
            scheduledDate: DateTime.now(),
            scheduledTime: '10:00 AM',
          );

          fail('Should throw exception for empty worker ID');
        } catch (e) {
          // Expected error
          expect(e.toString(), contains('Invalid worker_id format'));
          print('✅ BRANCH 3 PASSED: Empty worker ID rejected');
        }
      });
    });
  });
}
