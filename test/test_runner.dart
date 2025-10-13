// test/test_runner.dart
// Automated test runner with reporting
// Run with: dart test/test_runner.dart

import 'dart:io';

class TestRunner {
  static const String separator = '=' * 80;

  // Test categories and their files
  static final Map<String, List<String>> testCategories = {
    'Authentication Tests': [
      'test/integration_test/auth_test.dart',
    ],
    'Widget Tests': [
      'test/widget_test/auth_widget_test.dart',
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

        if (result['passed'] == result['total']) {
          print('✅ All tests passed in this file\n');
        } else {
          print('❌ Some tests failed in this file\n');
        }
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // Print summary
    print('\n$separator');
    print('📊 TEST SUMMARY');
    print(separator);
    print('Total Tests: $totalTests');
    print('✅ Passed: $passedTests');
    print('❌ Failed: $failedTests');
    print(
        '📈 Success Rate: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');
    print('⏱️  Duration: ${duration.inSeconds} seconds');
    print('End Time: ${DateTime.now()}');
    print(separator);

    // Print test case coverage
    print('\n📋 TEST CASE COVERAGE');
    print(separator);
    for (var testCase in testCases.entries) {
      print('${testCase.key}: ${testCase.value}');
    }
    print(separator);

    // Exit with appropriate code
    exit(failedTests > 0 ? 1 : 0);
  }

  /// Run specific test file
  static Future<Map<String, int>> _runTestFile(String testFile) async {
    try {
      final result = await Process.run(
        'flutter',
        ['test', testFile, '--reporter', 'expanded'],
        runInShell: true,
      );

      // Parse output to count tests
      final output = result.stdout.toString();
      final passed = _countMatches(output, r'\+\d+');
      final failed = _countMatches(output, r'ERROR');

      print(output);

      if (result.exitCode != 0) {
        print('⚠️  Test file had errors');
      }

      return {
        'total': passed + failed,
        'passed': passed,
        'failed': failed,
      };
    } catch (e) {
      print('❌ Error running test file: $e');
      return {'total': 0, 'passed': 0, 'failed': 0};
    }
  }

  /// Count regex matches in string
  static int _countMatches(String text, String pattern) {
    try {
      return RegExp(pattern).allMatches(text).length;
    } catch (e) {
      return 0;
    }
  }

  /// Run specific test case by ID
  static Future<void> runTestCase(String testCaseId) async {
    print('\n$separator');
    print('🧪 Running Test Case: $testCaseId');
    print('📝 ${testCases[testCaseId] ?? "Unknown test case"}');
    print(separator);

    final result = await Process.run(
      'flutter',
      ['test', '--name', testCaseId],
      runInShell: true,
    );

    print(result.stdout);

    if (result.exitCode == 0) {
      print('\n✅ Test case $testCaseId PASSED');
    } else {
      print('\n❌ Test case $testCaseId FAILED');
      print(result.stderr);
    }

    exit(result.exitCode);
  }

  /// Generate coverage report
  static Future<void> generateCoverage() async {
    print('\n$separator');
    print('📊 Generating Coverage Report');
    print(separator);

    print('Running tests with coverage...');
    final testResult = await Process.run(
      'flutter',
      ['test', '--coverage'],
      runInShell: true,
    );

    print(testResult.stdout);

    if (testResult.exitCode != 0) {
      print('❌ Tests failed, coverage not generated');
      exit(1);
    }

    print('\nGenerating HTML coverage report...');
    final genhtmlResult = await Process.run(
      'genhtml',
      ['coverage/lcov.info', '-o', 'coverage/html'],
      runInShell: true,
    );

    if (genhtmlResult.exitCode == 0) {
      print('✅ Coverage report generated at: coverage/html/index.html');

      // Try to open in browser (macOS/Linux)
      if (Platform.isMacOS) {
        await Process.run('open', ['coverage/html/index.html']);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', ['coverage/html/index.html']);
      }
    } else {
      print('⚠️  genhtml not found. Install lcov to generate HTML reports.');
      print('   macOS: brew install lcov');
      print('   Linux: apt-get install lcov');
    }
  }

  /// Print help message
  static void printHelp() {
    print('\n$separator');
    print('🧪 FIXMATE TEST RUNNER');
    print(separator);
    print('\nUsage:');
    print('  dart test/test_runner.dart [command] [options]\n');
    print('Commands:');
    print('  all              Run all tests (default)');
    print('  test <ID>        Run specific test case (e.g., FT-001)');
    print('  coverage         Generate coverage report');
    print('  list             List all test cases');
    print('  help             Show this help message\n');
    print('Examples:');
    print('  dart test/test_runner.dart');
    print('  dart test/test_runner.dart test FT-001');
    print('  dart test/test_runner.dart coverage');
    print(separator);
  }

  /// List all test cases
  static void listTestCases() {
    print('\n$separator');
    print('📋 AVAILABLE TEST CASES');
    print(separator);

    for (var testCase in testCases.entries) {
      print('${testCase.key.padRight(10)} ${testCase.value}');
    }

    print('\nTotal: ${testCases.length} test cases');
    print(separator);
  }
}

/// Main entry point
void main(List<String> args) async {
  if (args.isEmpty || args[0] == 'all') {
    await TestRunner.runAllTests();
  } else if (args[0] == 'test' && args.length > 1) {
    await TestRunner.runTestCase(args[1]);
  } else if (args[0] == 'coverage') {
    await TestRunner.generateCoverage();
  } else if (args[0] == 'list') {
    TestRunner.listTestCases();
  } else if (args[0] == 'help') {
    TestRunner.printHelp();
  } else {
    print('❌ Unknown command: ${args[0]}');
    TestRunner.printHelp();
    exit(1);
  }
}
