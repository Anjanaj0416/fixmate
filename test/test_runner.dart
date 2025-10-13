// test/test_runner.dart
// Automated test runner with reporting
// Run with: dart test/test_runner.dart all

import 'dart:io';

class TestRunner {
  static final String separator = '=' * 80;

  // Test categories and their files
  static final Map<String, List<String>> testCategories = {
    'Authentication Tests': [
      'test/integration_test/auth_test.dart',
    ],
    'Worker Profile Tests': [
      'test/integration_test/worker_profile_test.dart',
      'test/integration_test/worker_profile_validation_test.dart',
    ],
    'AI Matching Tests': [
      'test/integration_test/ai_matching_test.dart',
      'test/integration_test/ai_advanced_test.dart',
    ],
    'Booking & Quote Management Tests': [
      'test/integration_test/booking_quote_communication_test.dart',
    ],
    'Widget Tests': [
      'test/widget_test/auth_widget_test.dart',
    ],
    'Security Tests': [
      'test/security/security_test.dart',
    ],
    'Performance Tests': [
      'test/performance/performance_test.dart',
    ],
  };

  // Individual test cases mapping - UPDATED with all new test cases
  static final Map<String, String> testCases = {
    // Authentication Tests (FT-001 to FT-007)
    'FT-001': 'User Account Creation',
    'FT-002': 'Email/Password Login',
    'FT-003': 'Google OAuth Login',
    'FT-004': 'Password Reset',
    'FT-005': 'Account Type Selection',
    'FT-006': 'Switch to Professional Account',
    'FT-007': 'Two-Factor Authentication (SMS)',

    // Worker Profile Tests (FT-008 to FT-010)
    'FT-008': 'Worker Setup Form Completion',
    'FT-009': 'Portfolio Image Upload',
    'FT-010': 'Automatic Online/Offline Status',

    // AI Matching Tests (FT-011 to FT-017)
    'FT-011': 'Image Upload for AI Analysis',
    'FT-012': 'Text-Based Service Identification',
    'FT-013': 'Service-Specific Questionnaires',
    'FT-014': 'Browse Service Categories',
    'FT-015': 'Worker Search with Filters',
    'FT-016': 'Worker Profile View',
    'FT-017': 'Google Maps Integration',

    // Booking & Quote Management Tests (FT-018 to FT-027)
    'FT-018': 'Quote Request by Customer',
    'FT-019': 'Create Custom Quote by Worker',
    'FT-020': 'Quote Accept/Decline by Customer',
    'FT-021': 'Direct Booking Without Quote',
    'FT-022': 'Booking Status Tracking',
    'FT-023': 'Booking Cancellation by Customer',
    'FT-024': 'View Booking Requests (Worker)',
    'FT-025': 'Accept/Decline Booking (Worker)',
    'FT-026': 'Mark Booking as Completed',
    'FT-027': 'Booking History View',

    // Communication Features Tests (FT-028 to FT-030)
    'FT-028': 'Real-Time In-App Chat',
    'FT-029': 'Voice Call Integration',
    'FT-030': 'Push Notifications',

    // Validation Tests (FT-036 to FT-045)
    'FT-036': 'Invalid Email Format',
    'FT-037': 'Weak Password Validation',
    'FT-038': 'Duplicate Email Prevention',
    'FT-039': 'Account Lockout After Failed Attempts',
    'FT-040': 'Unverified Email Login',
    'FT-041': 'Password Reset with Invalid Email',
    'FT-042': 'Google OAuth Cancelled Authorization',
    'FT-043': 'Expired OTP Code',
    'FT-044': 'Multiple Incorrect OTP Attempts',
    'FT-045': 'Account Type Switch Back to Customer',

    // Worker Profile Validation Tests (FT-046 to FT-052)
    'FT-046': 'Worker Registration with Incomplete Form',
    'FT-047': 'Portfolio Image Upload Over Size Limit',
    'FT-048': 'Portfolio with Unsupported File Format',
    'FT-049': 'Worker Profile with Empty Bio',
    'FT-050': 'Worker Availability Schedule Conflict',
    'FT-051': 'Worker Profile Rate Update (Out of Range)',
    'FT-052': 'Worker Status Auto-Offline After Inactivity',

    // AI Advanced Tests (FT-053 to FT-062)
    'FT-053': 'AI Image Analysis with Unsupported Format',
    'FT-054': 'AI Image Analysis with Blurry Photo',
    'FT-055': 'AI Text Description with Ambiguous Query',
    'FT-056': 'AI Text Description with Multiple Issues',
    'FT-057': 'AI Service Classification with Misspelled Words',
    'FT-058': 'AI Performance Under Heavy Load',
    'FT-059': 'AI Location Extraction from Text',
    'FT-060': 'AI Confidence Score Display',
    'FT-061': 'AI Service Questionnaire Generation',
    'FT-062': 'AI Recommendation with No Matching Workers',

    // Booking & Quote Validation Tests (FT-063 to FT-072)
    'FT-063': 'Quote Request with Empty Description',
    'FT-064': 'Multiple Quote Requests to Same Worker',
    'FT-065': 'Quote Acceptance After Worker Unavailable',
    'FT-066': 'Booking Cancellation After Worker Acceptance',
    'FT-067': 'Booking with Past Date Selection',
    'FT-068': 'Quote Expiration After 48 Hours',
    'FT-069': 'Booking Status Update Notifications',
    'FT-070': 'Booking History Pagination',
    'FT-071': 'Booking with Special Instructions Field',
    'FT-072': 'Direct Booking Emergency Flow',

    // Communication Validation Tests (FT-073 to FT-076)
    'FT-073': 'Chat Message with Special Characters',
    'FT-074': 'Chat Message Retry on Network Failure',
    'FT-075': 'Voice Call with Invalid Phone Number',
    'FT-076': 'Push Notification Opt-Out',
  };

  /// Run all tests
  static Future<void> runAllTests() async {
    print('\n$separator');
    print('🧪 FIXMATE COMPLETE TEST SUITE');
    print(separator);
    print('Start Time: ${DateTime.now()}\n');

    final startTime = DateTime.now();
    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;

    for (var category in testCategories.entries) {
      print('\n📦 ${category.key}');
      print('-' * 80);

      for (var testFile in category.value) {
        print('\n▶️  Running: $testFile');

        final result = await _runTestFile(testFile);
        totalTests += result['total'] as int;
        passedTests += result['passed'] as int;
        failedTests += result['failed'] as int;
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n$separator');
    print('📊 TEST SUMMARY');
    print(separator);
    print('Total Tests: $totalTests');
    print('✅ Passed: $passedTests');
    print('❌ Failed: $failedTests');
    print('⏱️  Duration: ${duration.inSeconds}s');
    print('End Time: $endTime');
    print(separator);

    exit(failedTests > 0 ? 1 : 0);
  }

  /// Run specific test case by ID
  static Future<void> runTestCase(String testId) async {
    if (!testCases.containsKey(testId)) {
      print('❌ Unknown test case: $testId');
      print('Available test cases:');
      testCases.forEach((id, name) => print('  $id: $name'));
      exit(1);
    }

    print('\n$separator');
    print('🧪 Running Test Case: $testId - ${testCases[testId]}');
    print(separator);

    final result = await Process.run(
      'flutter',
      ['test', '--name', testId],
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    exit(result.exitCode);
  }

  /// Run specific test file
  static Future<Map<String, int>> _runTestFile(String filePath) async {
    final result = await Process.run(
      'flutter',
      ['test', filePath, '--reporter', 'compact'],
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    // Parse output to count tests
    final output = result.stdout.toString();
    final passedMatch = RegExp(r'\+(\d+)').allMatches(output).lastOrNull;
    final failedMatch = RegExp(r'-(\d+)').allMatches(output).lastOrNull;

    final passed = passedMatch != null ? int.parse(passedMatch.group(1)!) : 0;
    final failed = failedMatch != null ? int.parse(failedMatch.group(1)!) : 0;

    return {
      'total': passed + failed,
      'passed': passed,
      'failed': failed,
    };
  }

  /// Run tests by category
  static Future<void> runCategory(String categoryName) async {
    if (!testCategories.containsKey(categoryName)) {
      print('❌ Unknown category: $categoryName');
      print('Available categories:');
      testCategories.keys.forEach((cat) => print('  - $cat'));
      exit(1);
    }

    print('\n$separator');
    print('🧪 Running Category: $categoryName');
    print(separator);

    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;

    for (var testFile in testCategories[categoryName]!) {
      print('\n▶️  Running: $testFile');

      final result = await _runTestFile(testFile);
      totalTests += result['total'] as int;
      passedTests += result['passed'] as int;
      failedTests += result['failed'] as int;
    }

    print('\n$separator');
    print('📊 CATEGORY SUMMARY: $categoryName');
    print(separator);
    print('Total Tests: $totalTests');
    print('✅ Passed: $passedTests');
    print('❌ Failed: $failedTests');
    print(separator);

    exit(failedTests > 0 ? 1 : 0);
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage:');
    print(
        '  dart test/test_runner.dart all                    # Run all tests');
    print(
        '  dart test/test_runner.dart case FT-001            # Run specific test');
    print(
        '  dart test/test_runner.dart category "Auth Tests"  # Run test category');
    print('\nAvailable Categories:');
    TestRunner.testCategories.keys.forEach((cat) => print('  - $cat'));
    print('\nTotal Test Cases: ${TestRunner.testCases.length}');
    exit(1);
  }

  if (arguments[0] == 'all') {
    await TestRunner.runAllTests();
  } else if (arguments[0] == 'case' && arguments.length > 1) {
    await TestRunner.runTestCase(arguments[1]);
  } else if (arguments[0] == 'category' && arguments.length > 1) {
    await TestRunner.runCategory(arguments[1]);
  } else {
    print('❌ Unknown command: ${arguments[0]}');
    exit(1);
  }
}
