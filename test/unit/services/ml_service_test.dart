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
      });

      test('BRANCH 2: Service unavailable - false path', () async {
        // Arrange
        when(mockClient.get(any)).thenThrow(Exception('Connection refused'));

        // Act
        final result = await MLService.isServiceAvailable();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
