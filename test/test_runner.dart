// test/test_runner.dart
// COMPLETE FIXED VERSION - Automated test runner with reporting
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
      'test/performance/app_performance_test.dart',
    ],
  };

  // Individual test cases mapping - COMPLETE with all test cases
  static final Map<String, String> testCases = {
    // ========== Authentication Tests (FT-001 to FT-007) ==========
    'FT-001': 'User Account Creation',
    'FT-002': 'Email/Password Login',
    'FT-003': 'Google OAuth Login',
    'FT-004': 'Password Reset',
    'FT-005': 'Account Type Selection',
    'FT-006': 'Switch to Professional Account',
    'FT-007': 'Two-Factor Authentication (SMS)',

    // ========== Worker Profile Tests (FT-008 to FT-010) ==========
    'FT-008': 'Worker Setup Form Completion',
    'FT-009': 'Portfolio Upload (Min 5 Images)',
    'FT-010': 'Service Specialization Selection',

    // ========== AI Matching Tests (FT-011 to FT-017) ==========
    'FT-011': 'Image Upload for AI Analysis',
    'FT-012': 'Text-Based Service Identification',
    'FT-013': 'AI Worker Ranking Algorithm',
    'FT-014': 'Distance-Based Filter',
    'FT-015': 'Rating & Review Integration',
    'FT-016': 'Price Range Filter',
    'FT-017': 'Availability Check',

    // ========== Booking & Quote Management (FT-018 to FT-030) ==========
    'FT-018': 'Quote Request by Customer',
    'FT-019': 'Quote Submission by Worker',
    'FT-020': 'Quote Acceptance by Customer',
    'FT-021': 'Quote Rejection with Reason',
    'FT-022': 'Multiple Quote Comparison',
    'FT-023': 'Booking Confirmation Flow',
    'FT-024': 'Real-Time Chat Messaging',
    'FT-025': 'Voice Call Feature',
    'FT-026': 'Push Notifications',
    'FT-027': 'Payment Integration',
    'FT-028': 'Job Status Updates',
    'FT-029': 'Rating & Review Submission',
    'FT-030': 'Dispute Resolution',

    // ========== Additional Test Cases (FT-031 to FT-076) ==========
    'FT-031': 'Password Reset with Invalid Email',
    'FT-032': 'Login with Unverified Email',
    'FT-033': 'Account Lockout After Failed Attempts',
    'FT-034': 'Session Timeout',
    'FT-035': 'Duplicate Account Prevention',
    'FT-036': 'Invalid Email Format Validation',
    'FT-037': 'Weak Password Rejection',
    'FT-038': 'Password Confirmation Mismatch',
    'FT-039': 'Google Sign-In Failure',
    'FT-040': 'OTP Expiration',
    'FT-041': 'Incorrect OTP Entry',
    'FT-042': 'Multiple OTP Request Limit',
    'FT-043': 'Profile Update',
    'FT-044': 'Profile Picture Upload',
    'FT-045': 'Account Deletion',
    'FT-046': 'Worker Registration with Incomplete Form',
    'FT-047': 'Portfolio Image Size Validation',
    'FT-048': 'Service Rate Validation',
    'FT-049': 'Experience Years Validation',
    'FT-050': 'Multiple Service Selection',
    'FT-051': 'Worker Profile Visibility Toggle',
    'FT-052': 'Emergency Availability Toggle',
    'FT-053': 'AI Image Analysis Failure',
    'FT-054': 'Multiple Service Type Prediction',
    'FT-055': 'AI Confidence Threshold',
    'FT-056': 'Location Auto-Detection',
    'FT-057': 'Fuzzy Search for Misspellings',
    'FT-058': 'AI Response Time Under Heavy Load',
    'FT-059': 'AI Location Extraction from Text',
    'FT-060': 'AI Confidence Score Display',
    'FT-061': 'AI Service Questionnaire Generation',
    'FT-062': 'AI Recommendation with No Matching Workers',
    'FT-063': 'Quote Request with Image Attachment',
    'FT-064': 'Quote Counter-Offer',
    'FT-065': 'Quote Expiration',
    'FT-066': 'Bulk Quote Request',
    'FT-067': 'Quote Notification Settings',
    'FT-068': 'Booking Cancellation by Customer',
    'FT-069': 'Booking Cancellation by Worker',
    'FT-070': 'Booking History Pagination',
    'FT-071': 'Booking with Special Instructions Field',
    'FT-072': 'Direct Booking Emergency Flow',
    'FT-073': 'Chat Message with Special Characters',
    'FT-074': 'Chat Message Retry on Network Failure',
    'FT-075': 'Voice Call with Invalid Phone Number',
    'FT-076': 'Push Notification Opt-Out',

    // ========== Performance Tests (PT-001 to PT-020) ==========
    'PT-001': 'App Home Screen Load Time',
    'PT-002': 'AI Chatbot Response Time',
    'PT-003': 'User Interface Responsiveness',
    'PT-004': 'AI Prediction Performance',
    'PT-005': 'Worker Search Performance',
    'PT-006': 'System Availability',
    'PT-007': 'Chat Performance',
    'PT-008': 'Data Backup Verification',
    'PT-009': 'Concurrent Users Load Test',
    'PT-010': 'Database Query Optimization',
    'PT-011': 'Image Loading Performance',
    'PT-012': 'Firestore Listener Performance',
    'PT-013': 'ML Model Inference Time',
    'PT-014': 'Large File Upload Performance',
    'PT-015': 'Search Performance with Multiple Filters',
    'PT-016': 'App Cold Start Time',
    'PT-017': 'Memory Usage Under Load',
    'PT-018': 'Battery Consumption Test',
    'PT-019': 'Network Resilience Test',
    'PT-020': 'Offline Mode Functionality',

    // ========== Security Tests (ST-001 to ST-025) ==========
    'ST-001': 'Password Encryption Verification',
    'ST-002': 'SQL Injection Prevention',
    'ST-003': 'XSS Attack Prevention',
    'ST-004': 'CSRF Token Validation',
    'ST-005': 'Rate Limiting',
    'ST-006': 'API Authentication',
    'ST-007': 'Data Encryption at Rest',
    'ST-008': 'Data Encryption in Transit',
    'ST-009': 'Session Management',
    'ST-010': 'Access Control',
    'ST-011': 'Input Sanitization',
    'ST-012': 'Secure File Upload',
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
      print('\nAvailable test cases:');

      // Group by prefix for better display
      var ftCases = testCases.entries.where((e) => e.key.startsWith('FT-'));
      var ptCases = testCases.entries.where((e) => e.key.startsWith('PT-'));
      var stCases = testCases.entries.where((e) => e.key.startsWith('ST-'));

      if (ftCases.isNotEmpty) {
        print('\nFunctional Tests:');
        for (var entry in ftCases) {
          print('  ${entry.key}: ${entry.value}');
        }
      }

      if (ptCases.isNotEmpty) {
        print('\nPerformance Tests:');
        for (var entry in ptCases) {
          print('  ${entry.key}: ${entry.value}');
        }
      }

      if (stCases.isNotEmpty) {
        print('\nSecurity Tests:');
        for (var entry in stCases) {
          print('  ${entry.key}: ${entry.value}');
        }
      }

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

  /// Run specific test category
  static Future<void> runCategory(String category) async {
    if (!testCategories.containsKey(category)) {
      print('❌ Unknown category: $category');
      print('\nAvailable categories:');
      for (var cat in testCategories.keys) {
        print('  - $cat');
      }
      exit(1);
    }

    print('\n$separator');
    print('🧪 Running Category: $category');
    print(separator);
    print('Start Time: ${DateTime.now()}\n');

    final startTime = DateTime.now();
    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;

    for (var testFile in testCategories[category]!) {
      print('\n▶️  Running: $testFile');

      final result = await _runTestFile(testFile);
      totalTests += result['total'] as int;
      passedTests += result['passed'] as int;
      failedTests += result['failed'] as int;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n$separator');
    print('📊 CATEGORY SUMMARY: $category');
    print(separator);
    print('Total Tests: $totalTests');
    print('✅ Passed: $passedTests');
    print('❌ Failed: $failedTests');
    print('⏱️  Duration: ${duration.inSeconds}s');
    print('End Time: $endTime');
    print(separator);

    exit(failedTests > 0 ? 1 : 0);
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

    // Try to find test count patterns
    final passedMatch = RegExp(r'\+(\d+)').allMatches(output);
    final failedMatch = RegExp(r'-(\d+)').allMatches(output);

    int passed = 0;
    int failed = 0;

    if (passedMatch.isNotEmpty) {
      passed = int.parse(passedMatch.last.group(1)!);
    }

    if (failedMatch.isNotEmpty) {
      failed = int.parse(failedMatch.last.group(1)!);
    }

    return {
      'total': passed + failed,
      'passed': passed,
      'failed': failed,
    };
  }

  /// List all available tests
  static void listTests() {
    print('\n$separator');
    print('📋 AVAILABLE TEST CASES');
    print(separator);

    // Functional Tests
    print('\n🔹 Functional Tests (FT):');
    testCases.entries
        .where((e) => e.key.startsWith('FT-'))
        .forEach((e) => print('  ${e.key}: ${e.value}'));

    // Performance Tests
    print('\n⚡ Performance Tests (PT):');
    testCases.entries
        .where((e) => e.key.startsWith('PT-'))
        .forEach((e) => print('  ${e.key}: ${e.value}'));

    // Security Tests
    print('\n🔒 Security Tests (ST):');
    testCases.entries
        .where((e) => e.key.startsWith('ST-'))
        .forEach((e) => print('  ${e.key}: ${e.value}'));

    print('\n$separator');
    print('Total Test Cases: ${testCases.length}');
    print(separator);
  }

  /// List all available categories
  static void listCategories() {
    print('\n$separator');
    print('📦 AVAILABLE TEST CATEGORIES');
    print(separator);

    for (var entry in testCategories.entries) {
      print('\n${entry.key}:');
      for (var file in entry.value) {
        print('  - $file');
      }
    }

    print('\n$separator');
    print('Total Categories: ${testCategories.length}');
    print(separator);
  }
}

/// Main entry point
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('\n${'=' * 80}');
    print('🧪 FIXMATE TEST RUNNER');
    print('=' * 80);
    print('\nUsage:');
    print('  dart test/test_runner.dart <command> [options]');
    print('\nCommands:');
    print('  all                     - Run all tests');
    print('  category <name>         - Run specific category');
    print('  case <id>               - Run specific test case');
    print('  list                    - List all test cases');
    print('  categories              - List all categories');
    print('\nExamples:');
    print('  dart test/test_runner.dart all');
    print('  dart test/test_runner.dart category "Performance Tests"');
    print('  dart test/test_runner.dart case PT-001');
    print('  dart test/test_runner.dart case FT-001');
    print('  dart test/test_runner.dart list');
    print('  dart test/test_runner.dart categories');
    print('\n${'=' * 80}\n');
    exit(1);
  }

  final command = arguments[0].toLowerCase();

  try {
    switch (command) {
      case 'all':
        await TestRunner.runAllTests();
        break;

      case 'category':
        if (arguments.length < 2) {
          print('❌ Error: Please specify a category name');
          print(
              '\nExample: dart test/test_runner.dart category "Performance Tests"');
          print(
              '\nRun "dart test/test_runner.dart categories" to see all categories');
          exit(1);
        }
        await TestRunner.runCategory(arguments[1]);
        break;

      case 'case':
        if (arguments.length < 2) {
          print('❌ Error: Please specify a test case ID');
          print('\nExample: dart test/test_runner.dart case PT-001');
          print(
              '\nRun "dart test/test_runner.dart list" to see all test cases');
          exit(1);
        }
        await TestRunner.runTestCase(arguments[1]);
        break;

      case 'list':
        TestRunner.listTests();
        break;

      case 'categories':
        TestRunner.listCategories();
        break;

      case 'help':
      case '--help':
      case '-h':
        main([]); // Show help by calling with no arguments
        break;

      default:
        print('❌ Error: Unknown command: $command');
        print('\nRun "dart test/test_runner.dart" to see usage information');
        exit(1);
    }
  } catch (e, stackTrace) {
    print('\n❌ Error: $e');
    print('\nStack trace:');
    print(stackTrace);
    exit(1);
  }
}
