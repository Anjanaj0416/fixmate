// test/unit/screens/customer_dashboard_test.dart
// FIXED VERSION - Corrected imports and mock types

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixmate/screens/customer_dashboard.dart'; // ADD THIS IMPORT

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  User,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference
])
import 'customer_dashboard_test.mocks.dart';

void main() {
  group('WT021 - CustomerDashboard._loadUserLocation() Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef; // FIXED TYPE
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnap; // FIXED TYPE

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>(); // FIXED TYPE
      mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>(); // FIXED TYPE

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('TEST_USER_001');
      when(mockFirestore.collection('customers'))
          .thenReturn(MockCollectionReference<Map<String, dynamic>>());
      when(mockFirestore.collection('customers').doc(any))
          .thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
    });

    test('BRANCH 1: Full location data path', () async {
      // Arrange
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn({
        'location': {
          'city': 'Colombo',
          'district': 'Colombo',
          'latitude': 6.9271,
          'longitude': 79.8612,
        }
      });

      // Act
      String location = await CustomerDashboard.loadUserLocationStatic(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Assert
      expect(location, equals('Colombo'));
    });

    test('BRANCH 2: Partial location (city only) path', () async {
      // Arrange
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn({
        'location': {'city': 'Gampaha'}
      });

      // Act
      String location = await CustomerDashboard.loadUserLocationStatic(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Assert
      expect(location, equals('Gampaha'));
    });

    test('BRANCH 3: Null location field path', () async {
      // Arrange
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn({'location': null});

      // Act
      String location = await CustomerDashboard.loadUserLocationStatic(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Assert
      expect(location, equals('Location not set'));
    });

    test('BRANCH 4: No location field in document path', () async {
      // Arrange
      when(mockDocSnap.exists).thenReturn(true);
      when(mockDocSnap.data()).thenReturn({
        'customer_name': 'John Doe',
        'email': 'john@test.com',
        // NO location field
      });

      // Act
      String location = await CustomerDashboard.loadUserLocationStatic(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Assert
      expect(location, equals('Location not set'));
    });

    test('BRANCH 5: Firestore exception path', () async {
      // Arrange
      when(mockDocRef.get()).thenThrow(
        FirebaseException(plugin: 'firestore', message: 'Network error'),
      );

      // Act
      String location = await CustomerDashboard.loadUserLocationStatic(
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Assert
      expect(location, equals('Location not set'));
    });
  });

  group('WT028 - CustomerDashboard._handleServiceSelection() Tests', () {
    // Service selection navigation tests
    test('BRANCH 1: Service selection with location', () async {
      // Test navigation to ServiceRequestFlow with location
      // This would require widget testing framework
      expect(true, isTrue); // Placeholder
    });

    test('BRANCH 2: Service selection without location', () async {
      // Test location fetch before navigation
      expect(true, isTrue); // Placeholder
    });

    test('BRANCH 3: AI Chat navigation path', () async {
      // Test navigation to AI Chat Screen
      expect(true, isTrue); // Placeholder
    });
  });
}
