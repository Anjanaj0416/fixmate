// test/test_runner.dart
// Automated test runner with reporting
// Run with: dart test/test_runner.dart

import 'dart:io';

class TestRunner {
  // FIXED: Proper string repetition in Dart
  static final String separator = '=' * 80;

  // Test categories and their files
  static final Map<String, List<String>> testCategories = {
    'Authentication Tests': [
      'test/integration_test/auth_test.dart',
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

  // Individual test cases mapping
  static final Map<String, String> testCases = {
    'FT-001': 'User Account Creation',
    'FT-002': 'Email/Password Login',
    'FT-003': 'Google OAuth Login',
    'FT-004': 'Password Reset',
    'FT-005': 'Account Type Selection',
    'FT-006': 'Switch to Professional Account',
    'FT-007': 'Two-Factor Authentication (SMS)',
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
  };

  /// Run all tests
  static Future<void> runAllTests() async {
    print('\n$separator');
    print('🧪 FIXMATE AUTHENTICATION TEST SUITE');
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
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage:');
    print('  dart test/test_runner.dart all           # Run all tests');
    print('  dart test/test_runner.dart case FT-001   # Run specific test');
    exit(1);
  }

  if (arguments[0] == 'all') {
    await TestRunner.runAllTests();
  } else if (arguments[0] == 'case' && arguments.length > 1) {
    await TestRunner.runTestCase(arguments[1]);
  } else {
    print('❌ Unknown command: ${arguments[0]}');
    exit(1);
  }
}
