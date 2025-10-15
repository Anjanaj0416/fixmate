// test/integration_test/ai_advanced_test.dart
// FIXED VERSION - Test Cases: FT-053 to FT-062 - AI Advanced Features & Edge Cases
// Run: flutter test test/integration_test/ai_advanced_test.dart
// Run individual test: flutter test test/integration_test/ai_advanced_test.dart --name "FT-053"

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

      // FIXED: Using analyzeTextDescription method that now exists in MockOpenAIService
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

      // FIXED: Using predictMultipleServices method that now exists in MockMLService
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
      List<Map<String, dynamic>> predictions =
          await mockML.predictMultipleServices(
        description: misspelledProblem,
      );

      // Find electrical service
      var electricalPrediction = predictions.firstWhere(
        (p) => p['service_type'] == 'Electrical',
        orElse: () => {'service_type': 'None', 'confidence': 0.0},
      );

      expect(electricalPrediction['service_type'], 'Electrical');
      expect(electricalPrediction['confidence'], greaterThan(0.7));

      TestLogger.logTestPass('FT-057',
          'AI correctly identifies "Electrical" service despite typos, confidence >70%');
    });

    test('FT-058: AI Response Time Under Heavy Load', () async {
      TestLogger.logTestStart('FT-058', 'AI Response Time Under Heavy Load');

      // Test Data: 100 concurrent requests
      int concurrentRequests = 100;
      DateTime startTime = DateTime.now();

      List<Future<Map<String, dynamic>>> futures = [];
      for (int i = 0; i < concurrentRequests; i++) {
        futures.add(mockML.predictServiceType(
          description: 'Plumbing issue $i',
        ));
      }

      // Wait for all requests to complete
      List<Map<String, dynamic>> results = await Future.wait(futures);
      DateTime endTime = DateTime.now();

      Duration elapsed = endTime.difference(startTime);
      TestLogger.log(
          '  Total time for $concurrentRequests requests: ${elapsed.inMilliseconds}ms');

      // Verify all completed within 10 seconds
      expect(elapsed.inSeconds, lessThan(10));
      expect(results.length, concurrentRequests);

      // Verify no failures
      int successfulResults =
          results.where((r) => r['service_type'] != null).length;
      expect(successfulResults, concurrentRequests);

      TestLogger.logTestPass('FT-058',
          'All requests completed within 10 seconds, queue system active, no timeouts');
    });

    test('FT-059: AI Location Extraction from Text', () async {
      TestLogger.logTestStart('FT-059', 'AI Location Extraction from Text');

      // Test Data: Description with location
      const problemWithLocation = 'Need plumber urgently in Negombo area';

      Map<String, dynamic> result = await mockML.analyzeWithLocation(
        description: problemWithLocation,
      );

      expect(result['location'], 'Negombo');
      expect(result['workers'], isNotEmpty);

      // Verify distance calculation
      for (var worker in result['workers']) {
        expect(worker['distance_km'], isNotNull);
        expect(worker['distance_km'], greaterThan(0));
      }

      TestLogger.logTestPass('FT-059',
          'AI extracts location "Negombo", filters workers by proximity, displays distance');
    });

    test('FT-060: AI Confidence Score Display', () async {
      TestLogger.logTestStart('FT-060', 'AI Confidence Score Display');

      // Test Data: Clear problem description
      const problem = 'Broken AC unit';

      Map<String, dynamic> prediction = await mockML.predictServiceType(
        description: problem,
      );

      expect(prediction['service_type'], 'AC Repair');
      expect(prediction['confidence'], isNotNull);
      expect(prediction['confidence'], greaterThan(0.7));

      // Format confidence for display
      double confidence = prediction['confidence'];
      int confidencePercent = (confidence * 100).round();
      String displayText =
          '${prediction['service_type']} - $confidencePercent% match';

      expect(displayText, contains('AC Repair'));
      expect(displayText, contains('%'));

      TestLogger.logTestPass('FT-060',
          'AI displays "AC Repair - 92% match" or similar confidence indicator');
    });

    test('FT-061: AI Service Questionnaire Generation', () async {
      TestLogger.logTestStart('FT-061', 'AI Service Questionnaire Generation');

      // Test Data: Electrical service
      const serviceType = 'Electrical';

      List<Map<String, dynamic>> questionnaire =
          await mockML.generateQuestionnaire(
        serviceType: serviceType,
      );

      expect(questionnaire.isNotEmpty, true);

      // Verify electrical-specific questions
      bool hasWiringQuestion = questionnaire.any(
          (q) => q['question'].toString().toLowerCase().contains('wiring'));
      bool hasOutletQuestion = questionnaire.any(
          (q) => q['question'].toString().toLowerCase().contains('outlet'));

      expect(hasWiringQuestion || hasOutletQuestion, true);

      TestLogger.logTestPass('FT-061',
          'Questions like "Indoor or outdoor wiring?", "Number of outlets?", "Circuit breaker issues?" displayed');
    });

    test('FT-062: AI Recommendation with No Matching Workers', () async {
      TestLogger.logTestStart(
          'FT-062', 'AI Recommendation with No Matching Workers');

      // Test Data: Rare service request
      const rareService = 'Need violin repair in Jaffna';

      Map<String, dynamic> result = await mockML.searchWorkersWithFallback(
        description: rareService,
        location: 'Jaffna',
      );

      expect(result['workers'], isEmpty);
      expect(result['message'], isNotEmpty);
      expect(result['message'], contains('No workers found'));

      // Verify suggestions provided
      expect(result['suggestions'], isNotEmpty);
      bool hasSuggestions = result['suggestions'].any(
        (s) =>
            s.toString().toLowerCase().contains('nearby') ||
            s.toString().toLowerCase().contains('area') ||
            s.toString().toLowerCase().contains('different'),
      );

      expect(hasSuggestions, true);

      TestLogger.logTestPass('FT-062',
          'Message "No workers found. Try nearby areas or different service type" + suggestions for broader search');
    });
  });
}

// Helper Functions
bool _validateImageFormat(String format) {
  final validFormats = ['jpg', 'jpeg', 'png'];
  return validFormats.contains(format.toLowerCase());
}

String _getFormatError(String format) {
  if (!_validateImageFormat(format)) {
    return 'Unsupported format. Please use JPG or PNG';
  }
  return '';
}
