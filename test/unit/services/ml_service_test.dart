import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fixmate/services/ml_service.dart';
import 'dart:convert';

@GenerateMocks([http.Client])
import 'ml_service_test.mocks.dart';

void main() {
  group('MLService White Box Tests - WT003', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      // Inject mock client into MLService for testing
      MLService.setTestClient(mockClient);
    });

    tearDown(() {
      // Clean up - remove test client after each test
      MLService.setTestClient(null);
    });

    group('searchWorkers() - HTTP & JSON Parsing Branches', () {
      test('BRANCH 1: Successful API call with valid JSON - success path',
          () async {
        // Arrange - Mock SUCCESS response
        final validResponse = {
          'workers': [
            {
              'worker_id': 'HM_1234',
              'worker_name': 'Test Worker',
              'service_type': 'Plumbing',
              'rating': 4.5,
              'experience_years': 5,
              'daily_wage_lkr': 3000,
              'phone_number': '+94771234567',
              'email': 'worker@test.com',
              'city': 'Colombo',
              'distance_km': 2.5,
              'ai_confidence': 0.95,
              'bio': 'Experienced plumber',
            }
          ],
          'ai_analysis': {
            'service_predictions': [
              {
                'service_type': 'Plumbing',
                'confidence': 0.95,
              }
            ]
          }
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(validResponse),
              200,
            ));

        // Act - Execute SUCCESS path
        final result = await MLService.searchWorkers(
          description: 'Leaking pipe',
          location: 'Colombo',
        );

        // Assert - Verify successful parsing
        expect(result, isA<MLRecommendationResponse>());
        expect(result.workers.length, equals(1));
        expect(result.workers.first.workerId, equals('HM_1234'));
        expect(result.aiAnalysis, isNotNull);

        // Verify the HTTP call was made
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('BRANCH 2: HTTP 500 error - error response handling path', () async {
        // Arrange - Mock ERROR response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              'Internal Server Error',
              500,
            ));

        // Act & Assert - Execute ERROR handling branch
        expect(
          () => MLService.searchWorkers(
            description: 'Test',
            location: 'Colombo',
          ),
          throwsA(predicate(
              (e) => e.toString().contains('Failed to get recommendations'))),
        );

        // Verify error path was executed
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('BRANCH 3: Network exception - connection error path', () async {
        // Arrange - Mock NETWORK ERROR
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(http.ClientException('Network unreachable'));

        // Act & Assert - Execute network error catch block
        expect(
          () => MLService.searchWorkers(
            description: 'Test',
            location: 'Colombo',
          ),
          throwsA(predicate(
              (e) => e.toString().contains('Error connecting to ML service'))),
        );

        // Verify exception path was taken
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('BRANCH 4: Malformed JSON - parsing error path', () async {
        // Arrange - Mock INVALID JSON response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              '{invalid json}',
              200,
            ));

        // Act & Assert - Execute JSON parsing error branch
        expect(
          () => MLService.searchWorkers(
            description: 'Test',
            location: 'Colombo',
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('BRANCH 5: Empty response body - edge case path', () async {
        // Arrange - Mock EMPTY response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 200));

        // Act & Assert - Execute empty response handling
        expect(
          () => MLService.searchWorkers(
            description: 'Test',
            location: 'Colombo',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('BRANCH 6: Response with missing fields - null handling', () async {
        // Arrange - Mock response with minimal/missing fields
        final minimalResponse = {
          'workers': [
            {
              'worker_id': 'HM_9999',
              'worker_name': 'Minimal Worker',
              'service_type': 'Testing',
              // Missing optional fields
            }
          ],
          'ai_analysis': {
            'service_predictions': [
              {
                'service_type': 'Testing',
                'confidence': 0.5,
              }
            ]
          }
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(minimalResponse),
              200,
            ));

        // Act
        final result = await MLService.searchWorkers(
          description: 'Test',
          location: 'Colombo',
        );

        // Assert - Verify defaults are applied for missing fields
        expect(result.workers.length, equals(1));
        expect(result.workers.first.rating, equals(0.0));
        expect(result.workers.first.experienceYears, equals(0));
        expect(result.workers.first.email, equals(''));
      });
    });

    group('isServiceAvailable() - Connection Check Branches', () {
      test('BRANCH 1: Service available - true path', () async {
        // Arrange
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('OK', 200));

        // Act
        final result = await MLService.isServiceAvailable();

        // Assert
        expect(result, isTrue);
        verify(mockClient.get(any)).called(1);
      });

      test('BRANCH 2: Service unavailable - false path', () async {
        // Arrange
        when(mockClient.get(any)).thenThrow(Exception('Connection refused'));

        // Act
        final result = await MLService.isServiceAvailable();

        // Assert
        expect(result, isFalse);
        verify(mockClient.get(any)).called(1);
      });

      test('BRANCH 3: Service returns non-200 status', () async {
        // Arrange - Service is running but returns error
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('Service Error', 503));

        // Act
        final result = await MLService.isServiceAvailable();

        // Assert - Should return false for non-200 status
        expect(result, isFalse);
      });
    });

    group('Edge Cases and Additional Coverage', () {
      test('BRANCH 7: Multiple workers in response', () async {
        // Arrange - Response with multiple workers
        final multiWorkerResponse = {
          'workers': [
            {
              'worker_id': 'HM_0001',
              'worker_name': 'Worker One',
              'service_type': 'Plumbing',
              'rating': 4.5,
              'experience_years': 5,
              'daily_wage_lkr': 3000,
              'phone_number': '+94771111111',
              'email': 'worker1@test.com',
              'city': 'Colombo',
              'distance_km': 2.5,
              'ai_confidence': 0.95,
              'bio': 'Worker 1',
            },
            {
              'worker_id': 'HM_0002',
              'worker_name': 'Worker Two',
              'service_type': 'Electrical',
              'rating': 4.8,
              'experience_years': 7,
              'daily_wage_lkr': 3500,
              'phone_number': '+94772222222',
              'email': 'worker2@test.com',
              'city': 'Kandy',
              'distance_km': 15.0,
              'ai_confidence': 0.88,
              'bio': 'Worker 2',
            },
          ],
          'ai_analysis': {
            'service_predictions': [
              {
                'service_type': 'Plumbing',
                'confidence': 0.95,
              }
            ]
          }
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(multiWorkerResponse),
              200,
            ));

        // Act
        final result = await MLService.searchWorkers(
          description: 'Need help',
          location: 'Colombo',
        );

        // Assert - Verify all workers are parsed
        expect(result.workers.length, equals(2));
        expect(result.workers[0].workerId, equals('HM_0001'));
        expect(result.workers[1].workerId, equals('HM_0002'));
      });

      test('BRANCH 8: HTTP timeout simulation', () async {
        // Arrange - Simulate timeout
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          await Future.delayed(Duration(seconds: 2));
          throw Exception('Timeout');
        });

        // Act & Assert
        expect(
          () => MLService.searchWorkers(
            description: 'Test',
            location: 'Colombo',
          ),
          throwsA(predicate(
              (e) => e.toString().contains('Error connecting to ML service'))),
        );
      });
    });
  });
}
