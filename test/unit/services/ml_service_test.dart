import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:fixmate/services/ml_service.dart';
import 'dart:convert';

@GenerateMocks([http.Client])
import 'ml_service_test.mocks.dart';

void main() {
  group('MLService White Box Tests - WT003', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      // Inject mock client into MLService
      MLService.setTestClient(mockClient);
    });

    tearDown(() {
      // Reset to real client after tests
      MLService.setTestClient(null);
    });

    group('searchWorkers() - HTTP Communication & Parsing Branches', () {
      test('BRANCH 1: Successful API call - Complete success path', () async {
        // Arrange - Mock successful HTTP response
        final mockResponseBody = jsonEncode({
          'workers': [
            {
              'worker_id': 'HM_0001',
              'worker_name': 'John Doe',
              'service_type': 'Plumbing',
              'rating': 4.5,
              'experience_years': 5,
              'daily_wage_lkr': 5000,
              'phone_number': '+94771234567',
              'email': 'john@example.com',
              'city': 'Colombo',
              'distance_km': 2.5,
              'ai_confidence': 0.95,
              'bio': 'Expert plumber',
            }
          ],
          'ai_analysis': {
            'service_predictions': [
              {
                'service_type': 'Plumbing',
                'confidence': 0.95,
              }
            ],
            'detected_service': 'Plumbing',
            'urgency_level': 'normal',
            'time_preference': 'flexible',
            'required_skills': ['pipe_repair', 'leak_fixing'],
            'confidence': 0.95,
            'user_input_location': 'Colombo',
          }
        });

        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(mockResponseBody, 200));

        // Act
        final result = await MLService.searchWorkers(
          description: 'Fix water leak',
          location: 'Colombo',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.workers, isNotEmpty);
        expect(result.workers.first.workerId, equals('HM_0001'));
        expect(result.workers.first.workerName, equals('John Doe'));
        expect(result.aiAnalysis, isNotNull);
        print('✅ BRANCH 1 PASSED: Successful API call and parsing');
      });

      test('BRANCH 2: HTTP Status 500 - Server error path', () async {
        // Arrange - Mock server error response
        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

        // Act & Assert
        try {
          await MLService.searchWorkers(
            description: 'Fix water leak',
            location: 'Colombo',
          );
          fail('Should throw exception for status 500');
        } catch (e) {
          expect(e.toString(), contains('Failed to get recommendations'));
          print('✅ BRANCH 2 PASSED: HTTP 500 error handling');
        }
      });

      test('BRANCH 3: Network exception - Connection error path', () async {
        // Arrange - Mock network exception
        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: anyNamed('body'),
        )).thenThrow(Exception('Network connection failed'));

        // Act & Assert
        try {
          await MLService.searchWorkers(
            description: 'Fix water leak',
            location: 'Colombo',
          );
          fail('Should throw exception for network error');
        } catch (e) {
          expect(e.toString(), contains('Error connecting to ML service'));
          print('✅ BRANCH 3 PASSED: Network exception handling');
        }
      });

      test('BRANCH 4: Malformed JSON response - Parsing error path', () async {
        // Arrange - Mock invalid JSON response
        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{ invalid json }', 200));

        // Act & Assert
        try {
          await MLService.searchWorkers(
            description: 'Fix water leak',
            location: 'Colombo',
          );
          fail('Should throw exception for invalid JSON');
        } catch (e) {
          expect(e.toString(), contains('Error connecting to ML service'));
          print('✅ BRANCH 4 PASSED: Malformed JSON error handling');
        }
      });

      test('BRANCH 5: Empty workers list - Edge case path', () async {
        // Arrange - Mock response with empty workers array
        final mockResponseBody = jsonEncode({
          'workers': [], // Empty array
          'ai_analysis': {
            'service_predictions': [],
            'detected_service': 'Unknown',
            'urgency_level': 'normal',
            'time_preference': 'flexible',
            'required_skills': [],
            'confidence': 0.0,
            'user_input_location': 'Colombo',
          }
        });

        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(mockResponseBody, 200));

        // Act
        final result = await MLService.searchWorkers(
          description: 'Unknown service',
          location: 'Colombo',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.workers, isEmpty);
        print('✅ BRANCH 5 PASSED: Empty workers list handling');
      });
    });

    group('isServiceAvailable() - Health Check Branches', () {
      test('BRANCH 6: Service available - Returns true', () async {
        // Arrange
        when(mockClient.get(Uri.parse('http://localhost:8000/')))
            .thenAnswer((_) async => http.Response('OK', 200));

        // Act
        final isAvailable = await MLService.isServiceAvailable();

        // Assert
        expect(isAvailable, isTrue);
        print('✅ BRANCH 6 PASSED: Service availability check');
      });

      test('BRANCH 7: Service unavailable - Returns false', () async {
        // Arrange
        when(mockClient.get(Uri.parse('http://localhost:8000/')))
            .thenThrow(Exception('Connection refused'));

        // Act
        final isAvailable = await MLService.isServiceAvailable();

        // Assert
        expect(isAvailable, isFalse);
        print('✅ BRANCH 7 PASSED: Service unavailable handling');
      });
    });

    group('Request Body Validation', () {
      test('BRANCH 8: Location converted to lowercase', () async {
        // Arrange
        final mockResponseBody = jsonEncode({
          'workers': [],
          'ai_analysis': {
            'service_predictions': [],
            'detected_service': 'Unknown',
            'urgency_level': 'normal',
            'time_preference': 'flexible',
            'required_skills': [],
            'confidence': 0.0,
            'user_input_location': 'colombo', // lowercase
          }
        });

        when(mockClient.post(
          Uri.parse('http://localhost:8000/search'),
          headers: {'Content-Type': 'application/json'},
          body: argThat(
            predicate<String>((body) {
              final decoded = jsonDecode(body);
              return decoded['location'] == 'colombo'; // Verify lowercase
            }),
            named: 'body',
          ),
        )).thenAnswer((_) async => http.Response(mockResponseBody, 200));

        // Act
        await MLService.searchWorkers(
          description: 'Fix leak',
          location: 'COLOMBO', // UPPERCASE input
        );

        // Assert - Verification happens in the when() mock setup
        print('✅ BRANCH 8 PASSED: Location lowercase conversion');
      });
    });

    group('MLRecommendationResponse Model Tests', () {
      test('BRANCH 9: Proper JSON parsing of complete response', () {
        // Arrange
        final json = {
          'workers': [
            {
              'worker_id': 'HM_0002',
              'worker_name': 'Jane Smith',
              'service_type': 'Electrical',
              'rating': 4.8,
              'experience_years': 8,
              'daily_wage_lkr': 6000,
              'phone_number': '+94771234568',
              'email': 'jane@example.com',
              'city': 'Kandy',
              'distance_km': 5.0,
              'ai_confidence': 0.88,
              'bio': 'Licensed electrician',
            }
          ],
          'ai_analysis': {
            'service_predictions': [
              {
                'service_type': 'Electrical',
                'confidence': 0.88,
              }
            ],
            'detected_service': 'Electrical',
            'urgency_level': 'high',
            'time_preference': 'asap',
            'required_skills': ['wiring', 'circuit_repair'],
            'confidence': 0.88,
            'user_input_location': 'Kandy',
          }
        };

        // Act
        final response = MLRecommendationResponse.fromJson(json);

        // Assert
        expect(response.workers.length, equals(1));
        expect(response.workers.first.workerId, equals('HM_0002'));
        expect(response.aiAnalysis.servicePredictions.length, equals(1));
        print('✅ BRANCH 9 PASSED: Complete response parsing');
      });

      test('BRANCH 10: Handling missing optional fields', () {
        // Arrange - JSON with missing optional fields
        final json = {
          'workers': [
            {
              'worker_id': 'HM_0003',
              'worker_name': 'Bob Wilson',
              'service_type': 'Carpentry',
              // Missing rating - should default to 0.0
              // Missing experience_years - should default to 0
              'daily_wage_lkr': 4500,
              'phone_number': '+94771234569',
              // Missing email - should default to empty string
              'city': 'Galle',
              'distance_km': 10.0,
              'ai_confidence': 0.75,
              'bio': 'Skilled carpenter',
            }
          ],
          'ai_analysis': {
            'service_predictions': [],
            'detected_service': 'Carpentry',
            'urgency_level': 'normal',
            'time_preference': 'flexible',
            'required_skills': [],
            'confidence': 0.75,
            'user_input_location': 'Galle',
          }
        };

        // Act
        final response = MLRecommendationResponse.fromJson(json);

        // Assert
        expect(response.workers.first.rating, equals(0.0));
        expect(response.workers.first.experienceYears, equals(0));
        expect(response.workers.first.email, equals(''));
        print('✅ BRANCH 10 PASSED: Missing optional fields handling');
      });
    });
  });
}
