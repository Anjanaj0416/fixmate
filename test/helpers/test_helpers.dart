// test/helpers/test_helpers.dart
// Test helper utilities for logging and common test operations

class TestLogger {
  static void logTestStart(String testId, String testName) {
    print('\n========================================');
    print('TEST: $testId - $testName');
    print('========================================');
  }

  static void logTestPass(String testId) {
    print('✅ PASS: $testId');
  }

  static void logTestFail(String testId, String reason) {
    print('❌ FAIL: $testId - $reason');
  }

  static void logInfo(String message) {
    print('ℹ️  $message');
  }

  static void logWarning(String message) {
    print('⚠️  $message');
  }

  static void logError(String message) {
    print('❌ $message');
  }
}

class TestDataHelper {
  static const String validEmail = 'test@example.com';
  static const String validPassword = 'Test@123';
  static const String validPhone = '+94771234567';
  static const String validName = 'John Doe';

  static const List<String> weakPasswords = [
    '',
    '1',
    '12',
    '123',
    '1234',
    '12345',
    'abc',
    'password',
  ];

  static const List<String> invalidEmails = [
    '',
    'invalid',
    '@example.com',
    'user@',
    'user@domain',
    'user..name@example.com',
  ];

  static const List<String> strongPasswords = [
    'Test@123',
    'SecurePass123',
    'MyP@ssw0rd',
    'StrongPassword1',
  ];
}
