// test/unit/services/notification_service_test.dart
// FIXED VERSION - Corrected mock types

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmate/services/notification_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'notification_service_test.mocks.dart';

void main() {
  group('WT019 - NotificationService.createNotification() Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>>
        mockCollection; // FIXED TYPE
    late MockDocumentReference<Map<String, dynamic>> mockDocument; // FIXED TYPE

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection =
          MockCollectionReference<Map<String, dynamic>>(); // FIXED TYPE
      mockDocument =
          MockDocumentReference<Map<String, dynamic>>(); // FIXED TYPE

      // Setup mock chain
      when(mockFirestore.collection('notifications'))
          .thenReturn(mockCollection);
      when(mockCollection.doc()).thenReturn(mockDocument);
      when(mockDocument.set(any)).thenAnswer((_) async => Future.value());
    });

    group('Notification Type Branching Tests', () {
      test('BRANCH 1: new_booking notification type path', () async {
        // Arrange
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_001',
          type: 'new_booking',
          title: 'New Booking Request',
          message: 'You have a new booking',
          data: {'bookingId': 'BK_123'},
          priority: 'high',
        );

        // Assert
        expect(capturedData['type'], equals('new_booking'));
        expect(capturedData['title'], equals('New Booking Request'));
        expect(capturedData['priority'], equals('high'));
        expect(capturedData['data']['bookingId'], equals('BK_123'));
        expect(capturedData['read'], equals(false));
        expect(capturedData['userId'], equals('USER_001'));
        verify(mockDocument.set(any)).called(1);
      });

      test('BRANCH 2: booking_accepted notification type path', () async {
        // Arrange
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_002',
          type: 'booking_accepted',
          title: 'Booking Accepted',
          message: 'Worker accepted your booking',
          data: {'bookingId': 'BK_456'},
          priority: 'medium',
        );

        // Assert
        expect(capturedData['type'], equals('booking_accepted'));
        expect(capturedData['priority'], equals('medium'));
        verify(mockDocument.set(any)).called(1);
      });

      test('BRANCH 3: message notification type path', () async {
        // Arrange
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_003',
          type: 'message',
          title: 'New Message',
          message: 'You have 1 new message',
          data: {'chatId': 'CH_789'},
          priority: 'low',
        );

        // Assert
        expect(capturedData['type'], equals('message'));
        expect(capturedData['data']['chatId'], equals('CH_789'));
        expect(capturedData['priority'], equals('low'));
      });
    });

    group('Data Payload Handling Tests', () {
      test('BRANCH 4: Null data payload path', () async {
        // Arrange
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_004',
          type: 'booking_completed',
          title: 'Booking Completed',
          message: 'Your booking is complete',
          data: null, // NULL DATA TEST
          priority: 'medium',
        );

        // Assert
        expect(capturedData['data'], equals({})); // Should be empty map
        verify(mockDocument.set(any)).called(1);
      });

      test('BRANCH 5: Complex data payload path', () async {
        // Arrange
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        Map<String, dynamic> complexData = {
          'bookingId': 'BK_999',
          'workerName': 'John Doe',
          'serviceType': 'Plumbing',
          'estimatedPrice': 5000,
          'scheduledDate': '2025-10-15',
        };

        // Act
        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_005',
          type: 'quote_received',
          title: 'Quote Received',
          message: 'Worker sent you a quote',
          data: complexData,
          priority: 'high',
        );

        // Assert
        expect(capturedData['data'], equals(complexData));
        expect(capturedData['data']['bookingId'], equals('BK_999'));
        expect(capturedData['data']['estimatedPrice'], equals(5000));
      });
    });

    group('Priority Logic Tests', () {
      test('BRANCH 6: High priority path', () async {
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_006',
          type: 'emergency',
          title: 'Emergency Request',
          message: 'Urgent booking request',
          data: {},
          priority: 'high',
        );

        expect(capturedData['priority'], equals('high'));
      });

      test('BRANCH 7: Medium priority path', () async {
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_007',
          type: 'reminder',
          title: 'Reminder',
          message: 'Booking reminder',
          data: {},
          priority: 'medium',
        );

        expect(capturedData['priority'], equals('medium'));
      });

      test('BRANCH 8: Low priority path', () async {
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_008',
          type: 'update',
          title: 'System Update',
          message: 'App update available',
          data: {},
          priority: 'low',
        );

        expect(capturedData['priority'], equals('low'));
      });
    });

    group('Error Handling Tests', () {
      test('BRANCH 9: Firestore exception path', () async {
        // Arrange
        when(mockDocument.set(any)).thenThrow(FirebaseException(
          plugin: 'firestore',
          message: 'Network error',
        ));

        // Act & Assert
        expect(
          () async => await NotificationService.createNotification(
            firestore: mockFirestore,
            userId: 'USER_009',
            type: 'test',
            title: 'Test',
            message: 'Test message',
            data: {},
            priority: 'low',
          ),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('Timestamp and Read Status Tests', () {
      test('BRANCH 10: Verify timestamp and read=false initialization',
          () async {
        Map<String, dynamic> capturedData = {};
        when(mockDocument.set(any)).thenAnswer((invocation) {
          capturedData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        await NotificationService.createNotification(
          firestore: mockFirestore,
          userId: 'USER_010',
          type: 'test',
          title: 'Test Notification',
          message: 'Testing timestamp',
          data: {},
          priority: 'medium',
        );

        expect(capturedData['read'], equals(false));
        expect(capturedData['created_at'], isNotNull);
        expect(capturedData['userId'], equals('USER_010'));
      });
    });
  });
}
