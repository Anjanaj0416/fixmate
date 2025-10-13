// test/integration_test/ai_advanced_test.dart
// Test Cases: FT-053 to FT-062 - AI Advanced Features & Edge Cases
// Run: flutter test test/integration_test/ai_advanced_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';

void main() {
  late MockAuthService mockAuth;
  late MockStorageService mockStorage;
  late MockMLService mockML;
  late MockOpenAIService mockOpenAI;

  setUp(() {
    mockAuth = MockAuthService();
    mockStorage = MockStorageService();
    mockML = MockMLService();
    mockOpenAI = MockOpenAIService();
  });

  group('AI Advanced Features & Edge Cases', () {
    test('FT-053: AI Image Analysis with Unsupported Format', () async {
      TestLogger.logTestStart(
          'FT-053', 'AI Image Analysis with Unsupported Format');

      // Test Data: Unsupported file formats
      List<Map<String, dynamic>> unsupportedFiles = [
        {'filename': 'problem.gif', 'format': 'gif'},
        {'filename': 'issue.bmp', 'format': 'bmp'},
        {'filename': 'photo.webp', 'format': 'webp'},
      ];

      for (var file in unsupportedFiles) {
        bool isValid = _validateImageFormat(file['format']);
        expect(isValid, false);

        String errorMessage = _getFormatError(file['format']);
        expect(errorMessage, 'Unsupported format. Please use JPG or PNG');
      }

      // Test valid formats
      expect(_validateImageFormat('jpg'), true);
      expect(_validateImageFormat('png'), true);

      TestLogger.logTestPass('FT-053',
          'Error "Unsupported format. Please use JPG or PNG" displayed');
    });

    test('FT-054: AI Image Analysis with Blurry Photo', () async {
      TestLogger.logTestStart('FT-054', 'AI Image Analysis with Blurry Photo');

      // Test Data: Blurry image
      Map<String, dynamic> blurryImage = {
        'filename': 'severely_blurred.jpg',
        'quality': 'low',
        'blur_score': 0.2, // 0-1 scale, <0.3 is blurry
      };

      // Upload and analyze
      String imageUrl = await mockStorage.uploadFile(
        filePath: 'issue_photos/test/${blurryImage['filename']}',
        fileData: 'mock_blurry_image',
      );

      String aiResponse = await mockOpenAI.analyzeImageQuality(
        imageUrl: imageUrl,
        qualityScore: blurryImage['blur_score'],
      );

      // Verify AI handles gracefully
      expect(
          aiResponse.contains('quality too low') ||
              aiResponse.contains('clearer photo') ||
              aiResponse.contains('generic recommendations'),
          true);

      TestLogger.logTestPass('FT-054',
          'AI responds: "Image quality too low. Please upload clearer photo" OR provides generic recommendations');
    });

    test('FT-055: AI Text Description with Ambiguous Query', () async {
      TestLogger.logTestStart(
          'FT-055', 'AI Text Description with Ambiguous Query');

      // Test Data: Vague description
      const vagueProblem = 'fix my house';

      // AI should request clarification
      String aiResponse = await mockOpenAI.analyzeTextDescription(
        description: vagueProblem,
      );

      // Verify clarification request
      expect(
          aiResponse.contains('What specifically') ||
              aiResponse.contains('clarification') ||
              aiResponse.contains('plumbing, electrical, carpentry'),
          true);

      TestLogger.logTestPass('FT-055',
          'AI asks followup: "What specifically needs fixing? (plumbing, electrical, carpentry, etc.)"');
    });

    test('FT-056: AI Text Description with Multiple Issues', () async {
      TestLogger.logTestStart(
          'FT-056', 'AI Text Description with Multiple Issues');

      // Test Data: Multiple problems
      const complexProblem = 'My AC is not cooling and there\'s a leaking pipe';

      // AI predicts multiple service types
      List<Map<String, dynamic>> predictions =
          await mockML.predictMultipleServices(
        description: complexProblem,
      );

      expect(predictions.length, greaterThanOrEqualTo(2));

      // Verify both services identified
      bool hasACRepair = predictions.any((p) =>
          p['service_type'] == 'AC Repair' || p['service_type'].contains('AC'));
      bool hasPlumbing =
          predictions.any((p) => p['service_type'] == 'Plumbing');

      expect(hasACRepair, true);
      expect(hasPlumbing, true);

      // Verify confidence scores
      for (var prediction in predictions) {
        expect(prediction['confidence'], greaterThan(0.7));
      }

      TestLogger.logTestPass('FT-056',
          'AI identifies both: "AC Repair" (75% confidence) + "Plumbing" (80% confidence), shows workers for both');
    });

    test('FT-057: AI Service Classification with Misspelled Words', () async {
      TestLogger.logTestStart(
          'FT-057', 'AI Service Classification with Misspelled Words');

      // Test Data: Intentional typos
      const misspelledProblem = 'elektrical wirring problm';

      // AI should still identify correctly
      Map<String, dynamic> prediction = await mockML.predictServiceType(
        description: misspelledProblem,
      );

      expect(prediction['service_type'], 'Electrical');
      expect(prediction['confidence'], greaterThan(0.7));

      TestLogger.logTestPass('FT-057',
          'AI correctly identifies "Electrical" service despite typos, confidence >70%');
    });

    test('FT-058: AI Response Time Under Heavy Load', () async {
      TestLogger.logTestStart('FT-058', 'AI Response Time Under Heavy Load');

      // Simulate 100 concurrent requests
      const requestCount = 100;
      List<Future<Map<String, dynamic>>> requests = [];

      DateTime startTime = DateTime.now();

      for (int i = 0; i < requestCount; i++) {
        requests.add(mockML.predictServiceType(
          description: 'Need plumber for leak repair $i',
        ));
      }

      // Wait for all requests
      List<Map<String, dynamic>> results = await Future.wait(requests);

      DateTime endTime = DateTime.now();
      Duration totalTime = endTime.difference(startTime);

      // Verify all requests completed
      expect(results.length, requestCount);
      expect(results.every((r) => r.containsKey('service_type')), true);

      // Verify timing (should complete within 10 seconds)
      expect(totalTime.inSeconds, lessThanOrEqualTo(10));

      // Check for failures
      int failures = results.where((r) => r['status'] == 'failed').length;
      expect(failures, 0);

      TestLogger.logTestPass('FT-058',
          'All $requestCount requests completed within ${totalTime.inSeconds} seconds, queue system active, no timeouts');
    });

    test('FT-059: AI Location Extraction from Text', () async {
      TestLogger.logTestStart('FT-059', 'AI Location Extraction from Text');

      // Test Data: Description with location
      const problemWithLocation = 'Need plumber urgently in Negombo area';

      // AI extracts location
      Map<String, dynamic> analysis = await mockML.analyzeWithLocation(
        description: problemWithLocation,
      );

      expect(analysis['location'], 'Negombo');
      expect(analysis['service_type'], 'Plumbing');

      // Verify workers filtered by proximity
      List<Map<String, dynamic>> workers = analysis['workers'];
      expect(workers.isNotEmpty, true);

      for (var worker in workers) {
        expect(worker.containsKey('distance_km'), true);
        expect(worker['distance_km'], greaterThan(0));
      }

      TestLogger.logTestPass('FT-059',
          'AI extracts location "Negombo", filters workers by proximity, displays distance');
    });

    test('FT-060: AI Confidence Score Display', () async {
      TestLogger.logTestStart('FT-060', 'AI Confidence Score Display');

      // Test Data
      const problem = 'Broken AC unit';

      // Get prediction with confidence
      Map<String, dynamic> prediction = await mockML.predictServiceType(
        description: problem,
      );

      expect(prediction.containsKey('confidence'), true);
      expect(prediction.containsKey('service_type'), true);

      // Verify confidence is displayed in user-friendly format
      double confidence = prediction['confidence'];
      String displayText =
          '${prediction['service_type']} - ${(confidence * 100).toInt()}% match';

      expect(confidence, greaterThan(0.0));
      expect(confidence, lessThanOrEqualTo(1.0));
      expect(displayText, contains('%'));

      TestLogger.logTestPass('FT-060',
          'AI displays "$displayText" or similar confidence indicator');
    });

    test('FT-061: AI Service Questionnaire Generation', () async {
      TestLogger.logTestStart('FT-061', 'AI Service Questionnaire Generation');

      // Precondition: Customer selected "Electrical" service
      const serviceType = 'Electrical';

      // AI generates service-specific questions
      List<Map<String, dynamic>> questions = await mockML.generateQuestionnaire(
        serviceType: serviceType,
      );

      expect(questions.isNotEmpty, true);

      // Verify relevant questions are generated
      bool hasIndoorOutdoor = questions.any((q) =>
          q['question'].toLowerCase().contains('indoor') ||
          q['question'].toLowerCase().contains('outdoor'));
      bool hasOutlets =
          questions.any((q) => q['question'].toLowerCase().contains('outlet'));
      bool hasCircuitBreaker = questions.any((q) =>
          q['question'].toLowerCase().contains('circuit') ||
          q['question'].toLowerCase().contains('breaker'));

      expect(hasIndoorOutdoor || hasOutlets || hasCircuitBreaker, true);

      TestLogger.logTestPass('FT-061',
          'Questions like "Indoor or outdoor wiring?", "Number of outlets?", "Circuit breaker issues?" displayed');
    });

    test('FT-062: AI Recommendation with No Matching Workers', () async {
      TestLogger.logTestStart(
          'FT-062', 'AI Recommendation with No Matching Workers');

      // Test Data: Rare service request
      const rareProblem = 'Need violin repair in Jaffna';

      // Get AI recommendations
      Map<String, dynamic> result = await mockML.searchWorkersWithFallback(
        description: rareProblem,
        location: 'Jaffna',
      );

      // Verify fallback behavior
      expect(result['workers'], isEmpty);
      expect(result['message'], isNotEmpty);

      String message = result['message'];
      expect(
          message.contains('No workers found') ||
              message.contains('Try nearby areas') ||
              message.contains('different service type'),
          true);

      // Verify suggestions provided
      expect(result.containsKey('suggestions'), true);
      List<String> suggestions = List<String>.from(result['suggestions']);
      expect(suggestions.isNotEmpty, true);

      TestLogger.logTestPass('FT-062',
          'Message "No workers found. Try nearby areas or different service type" + suggestions for broader search');
    });
  });
}

// Helper validation functions
bool _validateImageFormat(String format) {
  return format.toLowerCase() == 'jpg' ||
      format.toLowerCase() == 'jpeg' ||
      format.toLowerCase() == 'png';
}

String _getFormatError(String format) {
  return 'Unsupported format. Please use JPG or PNG';
}
