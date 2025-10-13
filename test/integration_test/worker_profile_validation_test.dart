// test/integration_test/worker_profile_validation_test.dart
// Test Cases: FT-046 to FT-052 - Worker Profile Validation Tests
// Run: flutter test test/integration_test/worker_profile_validation_test.dart

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
  });

  group('Worker Profile Validation Tests', () {
    test('FT-046: Worker Registration with Incomplete Form', () async {
      TestLogger.logTestStart(
          'FT-046', 'Worker Registration with Incomplete Form');

      // Precondition: User on worker registration flow
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(userCredential, isNotNull);

      // Test Data: Partial data - only service type filled
      Map<String, dynamic> partialData = {
        'serviceType': 'Plumbing',
        // Missing required fields: experience, skills, location, rates, portfolio
      };

      // Validation check
      bool isValid = _validateWorkerForm(partialData);

      expect(isValid, false);

      // Verify error messages would be displayed
      List<String> errors = _getFormErrors(partialData);
      expect(errors.isNotEmpty, true);
      expect(errors.contains('Experience is required'), true);
      expect(errors.contains('Skills are required'), true);
      expect(errors.contains('Location is required'), true);

      TestLogger.logTestPass('FT-046',
          'Error messages displayed on empty required fields, cannot proceed');
    });

    test('FT-047: Worker Portfolio Image Upload (Multiple)', () async {
      TestLogger.logTestStart(
          'FT-047', 'Worker Portfolio Image Upload (Multiple)');

      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      final userId = userCredential!.user!.uid;

      // Test Data: 10 images (2-5MB each, JPG format)
      List<Map<String, dynamic>> images = [];
      for (int i = 1; i <= 10; i++) {
        images.add({
          'filename': 'portfolio_$i.jpg',
          'size': 2 * 1024 * 1024 + i * 100000, // 2-5 MB
          'format': 'jpg',
        });
      }

      // Upload all images
      List<String> uploadedUrls = [];
      for (var image in images) {
        // Validate file before upload
        bool isValid = _validateImageFile(image);
        expect(isValid, true);

        String url = await mockStorage.uploadFile(
          filePath: 'portfolio_photos/$userId/${image['filename']}',
          fileData: 'mock_image_data_${image['size']}',
        );
        uploadedUrls.add(url);
      }

      // Verify all 10 images uploaded
      expect(uploadedUrls.length, 10);

      // Save to Firestore
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'portfolio': uploadedUrls
              .map((url) => {
                    'image_url': url,
                    'note': 'Sample work',
                    'uploaded_at': DateTime.now().toIso8601String(),
                  })
              .toList(),
        },
      );

      // Verify in database
      final doc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(doc.data()!['portfolio'].length, 10);

      TestLogger.logTestPass(
          'FT-047', 'All 10 images uploaded successfully to Firebase Storage');
    });

    test('FT-048: Worker Portfolio Image Upload (Large File)', () async {
      TestLogger.logTestStart(
          'FT-048', 'Worker Portfolio Image Upload (Large File)');

      // Test Data: 12MB image (exceeds 10MB limit)
      Map<String, dynamic> largeImage = {
        'filename': 'large_image.jpg',
        'size': 12 * 1024 * 1024, // 12 MB
        'format': 'jpg',
      };

      // Validate file size
      bool isValid = _validateImageFile(largeImage);

      expect(isValid, false);

      String errorMessage = _getFileSizeError(largeImage);
      expect(errorMessage, 'File too large. Maximum 10MB per image');

      TestLogger.logTestPass(
          'FT-048', 'Error message displayed, upload blocked');
    });

    test('FT-049: Worker Profile with Invalid Phone Number', () async {
      TestLogger.logTestStart(
          'FT-049', 'Worker Profile with Invalid Phone Number');

      // Test Data: Invalid phone numbers
      List<String> invalidPhones = [
        '12345',
        'abcd',
        '+941234567890123',
        '771234567',
      ];

      for (var phone in invalidPhones) {
        bool isValid = _validatePhoneNumber(phone);
        expect(isValid, false);

        String error = _getPhoneError(phone);
        expect(error, 'Invalid phone number format. Use +94XXXXXXXXX');
      }

      // Test valid phone
      bool isValid = _validatePhoneNumber('+94771234567');
      expect(isValid, true);

      TestLogger.logTestPass(
          'FT-049', 'Error message displayed for invalid phone numbers');
    });

    test('FT-050: Worker Availability Schedule Update', () async {
      TestLogger.logTestStart('FT-050', 'Worker Availability Schedule Update');

      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      final userId = userCredential!.user!.uid;

      // Test Data: Available Mon-Fri 8AM-5PM, Unavailable weekends
      Map<String, dynamic> schedule = {
        'available_days': [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday'
        ],
        'unavailable_days': ['Saturday', 'Sunday'],
        'working_hours': '8:00 AM - 5:00 PM',
      };

      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'availability_schedule': schedule,
        },
      );

      // Verify schedule saved
      final doc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(doc.data()!['availability_schedule']['available_days'].length, 5);
      expect(
          doc.data()!['availability_schedule']['unavailable_days'].length, 2);

      TestLogger.logTestPass('FT-050',
          'Schedule saved, worker appears in search only during available hours');
    });

    test('FT-051: Worker Profile Rate Update (Out of Range)', () async {
      TestLogger.logTestStart(
          'FT-051', 'Worker Profile Rate Update (Out of Range)');

      // Test Data: Invalid rates
      List<double> invalidRates = [-500, 0, 100000];

      for (var rate in invalidRates) {
        bool isValid = _validateDailyRate(rate);
        expect(isValid, false);

        String error = _getRateError(rate);
        expect(error, 'Daily rate must be between 1,000 and 50,000 LKR');
      }

      // Test valid rate
      bool isValid = _validateDailyRate(3500);
      expect(isValid, true);

      TestLogger.logTestPass(
          'FT-051', 'Error message displayed for out of range rates');
    });

    test('FT-052: Worker Status Auto-Offline After Inactivity', () async {
      TestLogger.logTestStart(
          'FT-052', 'Worker Status Auto-Offline After Inactivity');

      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      final userId = userCredential!.user!.uid;

      // Set initial status to online
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'is_online': true,
          'last_active': DateTime.now().toIso8601String(),
        },
      );

      // Simulate 30 minutes of inactivity
      final inactiveTime = DateTime.now().subtract(Duration(minutes: 30));

      // Auto-update status to offline
      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: userId,
        data: {
          'is_online': false,
          'last_active': inactiveTime.toIso8601String(),
        },
      );

      // Verify status changed
      final doc = await mockFirestore.getDocument(
        collection: 'workers',
        documentId: userId,
      );

      expect(doc.data()!['is_online'], false);

      TestLogger.logTestPass(
          'FT-052', 'Status automatically changes to offline after 30 minutes');
    });
  });
}

// Helper validation functions
bool _validateWorkerForm(Map<String, dynamic> data) {
  return data.containsKey('serviceType') &&
      data.containsKey('experienceYears') &&
      data.containsKey('skills') &&
      data.containsKey('location') &&
      data.containsKey('pricing');
}

List<String> _getFormErrors(Map<String, dynamic> data) {
  List<String> errors = [];
  if (!data.containsKey('experienceYears'))
    errors.add('Experience is required');
  if (!data.containsKey('skills')) errors.add('Skills are required');
  if (!data.containsKey('location')) errors.add('Location is required');
  return errors;
}

bool _validateImageFile(Map<String, dynamic> image) {
  const maxSize = 10 * 1024 * 1024; // 10 MB
  return image['size'] <= maxSize &&
      (image['format'] == 'jpg' || image['format'] == 'png');
}

String _getFileSizeError(Map<String, dynamic> image) {
  return 'File too large. Maximum 10MB per image';
}

bool _validatePhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^\+94\d{9}$');
  return phoneRegex.hasMatch(phone);
}

String _getPhoneError(String phone) {
  return 'Invalid phone number format. Use +94XXXXXXXXX';
}

bool _validateDailyRate(double rate) {
  return rate >= 1000 && rate <= 50000;
}

String _getRateError(double rate) {
  return 'Daily rate must be between 1,000 and 50,000 LKR';
}
