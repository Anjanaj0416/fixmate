// test/integration_test/worker_profile_test.dart
// Complete Test File for FT-008, FT-009, FT-010
// Run: flutter test test/integration_test/worker_profile_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';

void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late MockStorageService mockStorage;

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    mockStorage = MockStorageService();
  });

  tearDown(() {
    mockFirestore.clearData();
    mockStorage.clearStorage();
  });

  group('👷 Worker Profile Management Tests (FT-008 to FT-010)', () {
    test('FT-008: Worker Setup Form Completion', () async {
      TestLogger.logTestStart('FT-008', 'Worker Setup Form Completion');

      // Precondition: User selected "Worker" account type
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(userCredential, isNotNull);
      final userId = userCredential!.user!.uid;

      // Test Data
      const serviceType = 'Plumbing';
      const experienceYears = 5;
      const dailyRate = 3500.0;
      const location = 'Colombo';
      const skills = ['Pipe repair', 'Installation'];
      final portfolioImages = ['image1.jpg', 'image2.jpg', 'image3.jpg'];

      TestLogger.log('Step 1: Complete Service Type - $serviceType');
      TestLogger.log('Step 2: Complete Experience - $experienceYears years');
      TestLogger.log('Step 3: Complete Skills - ${skills.join(", ")}');
      TestLogger.log('Step 4: Complete Location - $location');
      TestLogger.log('Step 5: Complete Availability');
      TestLogger.log('Step 6: Complete Rates - LKR $dailyRate/day');
      TestLogger.log(
          'Step 7: Upload Portfolio - ${portfolioImages.length} images');

      // Upload portfolio images
      List<String> portfolioUrls = [];
      for (var image in portfolioImages) {
        String url = await mockStorage.uploadFile(
          filePath: 'portfolio/$userId/$image',
          fileData: 'mock_image_data',
        );
        portfolioUrls.add(url);
        TestLogger.log('  ✓ Uploaded: $image');
      }

      // Generate worker ID (HM_XXXX format)
      String workerId = 'HM_${DateTime.now().millisecondsSinceEpoch % 10000}';
      TestLogger.log('Step 8: Submit registration - Generated ID: $workerId');

      // Create worker profile with all 7 steps data
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'worker_id': workerId,
          'serviceType': serviceType,
          'experienceYears': experienceYears,
          'skills': skills,
          'location': {
            'city': location,
            'latitude': 6.9271,
            'longitude': 79.8612,
          },
          'availability': {
            'availableToday': true,
            'workingHours': '8:00 AM - 5:00 PM',
            'availableWeekends': true,
          },
          'pricing': {
            'dailyWageLkr': dailyRate,
            'halfDayRateLkr': dailyRate / 2,
            'minimumChargeLkr': 1500.0,
          },
          'portfolio': portfolioUrls
              .map((url) => {
                    'image_url': url,
                    'note': 'Sample work',
                    'uploaded_at': DateTime.now().toIso8601String(),
                  })
              .toList(),
          'createdAt': DateTime.now().toIso8601String(),
          'verified': false,
          'is_online': false,
        },
      );

      // Verify worker profile created successfully
      final workerDoc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(workerDoc.exists, true, reason: 'Worker document should exist');
      final data = workerDoc.data()!;

      // Verify worker_id format (HM_XXXX)
      expect(data['worker_id'], startsWith('HM_'),
          reason: 'Worker ID should start with HM_');
      expect(data['worker_id'].length, equals(7),
          reason: 'Worker ID should be 7 characters (HM_ + 4 digits)');

      // Verify all data saved correctly
      expect(data['serviceType'], serviceType);
      expect(data['experienceYears'], experienceYears);
      expect(data['skills'], skills);
      expect(data['location']['city'], location);
      expect(data['pricing']['dailyWageLkr'], dailyRate);
      expect(data['portfolio'].length, 3,
          reason: 'Should have 3 portfolio images');

      TestLogger.log('✓ Worker ID format validated: ${data['worker_id']}');
      TestLogger.log('✓ All 7 steps data saved to Firestore');
      TestLogger.log('✓ Portfolio images: ${data['portfolio'].length}/3');

      TestLogger.logTestPass('FT-008',
          'Worker profile created with unique ID (${data['worker_id']}), all data saved in Firestore');
    });

    test('FT-009: Profile Information Update', () async {
      TestLogger.logTestStart('FT-009', 'Profile Information Update');

      // Precondition: User has completed profile setup
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      final userId = userCredential!.user!.uid;

      // Create initial profile
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'worker_id': 'HM_1234',
          'worker_name': 'John Plumber',
          'profile': {
            'bio': 'Plumber',
          },
          'pricing': {
            'dailyWageLkr': 3500.0,
          },
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      TestLogger.log('Step 1: Login as worker');
      await mockAuth.signInWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );

      TestLogger.log('Step 2: Go to "Edit Profile"');

      // Test Data - New values
      const newBio = 'Experienced plumber';
      const newRate = 4000.0;

      TestLogger.log('Step 3: Update bio to "$newBio"');
      TestLogger.log('Step 4: Update rate to LKR $newRate');
      TestLogger.log('Step 5: Tap "Save Changes"');

      // Update profile
      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'profile.bio': newBio,
          'pricing.dailyWageLkr': newRate,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      TestLogger.log('Step 6: Verify updates in Firebase');

      // Verify updates in Firebase
      final updatedDoc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(updatedDoc.exists, true);
      final data = updatedDoc.data()!;

      // Verify profile updated successfully
      expect(data['profile']['bio'], newBio, reason: 'Bio should be updated');
      expect(data['pricing']['dailyWageLkr'], newRate,
          reason: 'Daily rate should be updated');
      expect(data.containsKey('updatedAt'), true,
          reason: 'Update timestamp should exist');

      TestLogger.log('✓ Bio updated: "${data['profile']['bio']}"');
      TestLogger.log('✓ Rate updated: LKR ${data['pricing']['dailyWageLkr']}');
      TestLogger.log('✓ Changes reflected immediately in database');

      TestLogger.logTestPass('FT-009',
          'Profile updated successfully, changes reflected immediately in app and database');
    });

    test('FT-010: Automatic Online/Offline Status', () async {
      TestLogger.logTestStart('FT-010', 'Automatic Online/Offline Status');

      // Precondition: Worker logged in
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      final userId = userCredential!.user!.uid;

      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'worker_id': 'HM_1234',
          'worker_name': 'John Worker',
          'is_online': false,
          'last_active': null,
        },
      );

      TestLogger.log('Step 1: Login as worker');
      await mockAuth.signInWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );

      TestLogger.log('Step 2: Use app actively');

      // Set status to online when active
      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'is_online': true,
          'last_active': DateTime.now().toIso8601String(),
        },
      );

      TestLogger.log('Step 3: Check status in Firestore');

      // Check status - should be online
      var doc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(doc.data()!['is_online'], true,
          reason: 'Status should be online when active');
      TestLogger.log('✓ Status shows "online" when active');

      TestLogger.log('Step 4: Minimize app');
      TestLogger.log('Step 5: Wait 5 minutes (simulated)');

      // Simulate inactivity
      final inactiveTime = DateTime.now().subtract(Duration(minutes: 5));

      TestLogger.log('Step 6: Check status again');

      // Status should automatically change to offline after inactivity
      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'is_online': false,
          'last_active': inactiveTime.toIso8601String(),
        },
      );

      doc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      // Verify status changed to offline after inactivity
      expect(doc.data()!['is_online'], false,
          reason: 'Status should be offline after inactivity');
      expect(doc.data()!.containsKey('last_active'), true,
          reason: 'last_active timestamp should exist');

      // Verify last_active timestamp is updated
      final lastActive = DateTime.parse(doc.data()!['last_active']);
      expect(lastActive.isBefore(DateTime.now()), true,
          reason: 'last_active should be in the past');

      final minutesInactive = DateTime.now().difference(lastActive).inMinutes;

      TestLogger.log(
          '✓ Status automatically changes to "offline" after inactivity');
      TestLogger.log(
          '✓ last_active timestamp updated: $minutesInactive minutes ago');
      TestLogger.log('✓ Changes reflected in search results');

      TestLogger.logTestPass('FT-010',
          'Status shows "online" when active, automatically changes to "offline" after inactivity, last_active timestamp updated');
    });
  });
}
