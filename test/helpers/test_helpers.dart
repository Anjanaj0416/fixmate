// test/helpers/test_helpers.dart
// FIXED VERSION - Helper utilities for test cases

import 'package:flutter/foundation.dart';

/// Test Logger for consistent test output
class TestLogger {
  static void logTestStart(String testId, String testName) {
    print('\n${'=' * 80}');
    print('🧪 TEST CASE: $testId - $testName');
    print('${'=' * 80}');
    print('⏰ Started at: ${DateTime.now().toString()}');
    print('${'─' * 80}');
  }

  static void log(String message) {
    print('📝 $message');
  }

  // FIXED: Updated signature to match usage
  static void logTestPass(String testId, String message) {
    print('${'─' * 80}');
    print('✅ TEST PASSED: $testId');
    print('📋 Result: $message');
    print('⏰ Completed at: ${DateTime.now().toString()}');
    print('${'=' * 80}\n');
  }

  static void logTestFail(String testId, String message, [dynamic error]) {
    print('${'─' * 80}');
    print('❌ TEST FAILED: $testId');
    print('📋 Reason: $message');
    if (error != null) {
      print('🔍 Error: $error');
    }
    print('⏰ Failed at: ${DateTime.now().toString()}');
    print('${'=' * 80}\n');
  }

  static void logSection(String sectionName) {
    print('\n${'─' * 80}');
    print('📂 $sectionName');
    print('${'─' * 80}');
  }

  static void logWarning(String message) {
    print('⚠️  WARNING: $message');
  }

  static void logError(String message) {
    print('❌ ERROR: $message');
  }

  static void logSuccess(String message) {
    print('✅ SUCCESS: $message');
  }

  static void logInfo(String message) {
    print('ℹ️  INFO: $message');
  }
}

/// FIXED: Added ValidationHelper class with all required methods
class ValidationHelper {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 6 characters, contains letter, number, and special char
    if (password.length < 6) return false;

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasDigit && hasSpecial;
  }

  /// Validate phone number (Sri Lankan format)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+94\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Check for XSS patterns
  static bool containsXSS(String input) {
    final xssPatterns = [
      RegExp(r'<script.*?>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
      RegExp(r'<img.*?onerror', caseSensitive: false),
      RegExp(r'<svg.*?onload', caseSensitive: false),
    ];

    for (var pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Sanitize input for XSS
  static String sanitizeForXSS(String input) {
    String sanitized = input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    return sanitized;
  }

  /// Validate worker ID format (HM_XXXX)
  static bool isValidWorkerId(String workerId) {
    final workerIdRegex = RegExp(r'^HM_\d{4}$');
    return workerIdRegex.hasMatch(workerId);
  }

  /// Validate daily rate range
  static bool isValidDailyRate(double rate) {
    return rate >= 1000 && rate <= 50000;
  }

  /// Validate image file format
  static bool isValidImageFormat(String format) {
    final validFormats = ['jpg', 'jpeg', 'png'];
    return validFormats.contains(format.toLowerCase());
  }

  /// Validate image file size (max 10MB)
  static bool isValidImageSize(int sizeInBytes) {
    const maxSize = 10 * 1024 * 1024; // 10 MB
    return sizeInBytes <= maxSize;
  }
}

/// Test Validation Helpers (legacy - keeping for compatibility)
class TestValidators {
  /// Validate email format
  static bool isValidEmail(String email) {
    return ValidationHelper.isValidEmail(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 6 characters, contains letter and number
    if (password.length < 6) return false;

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);

    return hasLetter && hasDigit;
  }

  /// Validate phone number (Sri Lankan format)
  static bool isValidPhoneNumber(String phone) {
    return ValidationHelper.isValidPhone(phone);
  }

  /// Validate worker ID format (HM_XXXX)
  static bool isValidWorkerId(String workerId) {
    return ValidationHelper.isValidWorkerId(workerId);
  }

  /// Validate daily rate range
  static bool isValidDailyRate(double rate) {
    return ValidationHelper.isValidDailyRate(rate);
  }

  /// Validate image file format
  static bool isValidImageFormat(String format) {
    return ValidationHelper.isValidImageFormat(format);
  }

  /// Validate image file size (max 10MB)
  static bool isValidImageSize(int sizeInBytes) {
    return ValidationHelper.isValidImageSize(sizeInBytes);
  }
}

/// Test Data Generators
class TestDataGenerator {
  /// Generate random email
  static String generateEmail({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final basePrefix = prefix ?? 'test';
    return '$basePrefix$timestamp@test.com';
  }

  /// Generate random phone number (Sri Lankan)
  static String generatePhoneNumber() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000000;
    return '+947${random.toString().padLeft(8, '0')}';
  }

  /// Generate worker ID
  static String generateWorkerId() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'HM_${random.toString().padLeft(4, '0')}';
  }

  /// Generate random name
  static String generateName() {
    final firstNames = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Emma'];
    final lastNames = [
      'Smith',
      'Johnson',
      'Williams',
      'Brown',
      'Jones',
      'Davis'
    ];
    final randomIndex1 =
        DateTime.now().millisecondsSinceEpoch % firstNames.length;
    final randomIndex2 =
        (DateTime.now().millisecondsSinceEpoch + 1) % lastNames.length;
    return '${firstNames[randomIndex1]} ${lastNames[randomIndex2]}';
  }

  /// Generate test password
  static String generatePassword() {
    return 'Test@${DateTime.now().millisecondsSinceEpoch % 10000}';
  }
}

/// Test Assertions Extensions
class TestAssertions {
  /// Assert map contains all keys
  static void assertMapContainsKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (var key in keys) {
      if (!map.containsKey(key)) {
        throw AssertionError('Map does not contain key: $key');
      }
    }
  }

  /// Assert value is in range
  static void assertInRange(
    num value,
    num min,
    num max, {
    String? message,
  }) {
    if (value < min || value > max) {
      throw AssertionError(
        message ?? 'Value $value is not in range [$min, $max]',
      );
    }
  }

  /// Assert list is not empty
  static void assertNotEmpty(List list, {String? message}) {
    if (list.isEmpty) {
      throw AssertionError(message ?? 'List should not be empty');
    }
  }

  /// Assert string matches pattern
  static void assertMatchesPattern(
    String value,
    RegExp pattern, {
    String? message,
  }) {
    if (!pattern.hasMatch(value)) {
      throw AssertionError(
        message ?? 'String "$value" does not match pattern',
      );
    }
  }
}

/// Test Timing Helpers
class TestTimer {
  static DateTime? _startTime;

  static void start() {
    _startTime = DateTime.now();
  }

  static Duration? elapsed() {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!);
  }

  static void logElapsed(String operation) {
    final duration = elapsed();
    if (duration != null) {
      TestLogger.log('⏱️  $operation took ${duration.inMilliseconds}ms');
    }
  }

  static void reset() {
    _startTime = null;
  }
}

/// Test Wait/Delay Helpers
class TestWaiter {
  /// Wait for a condition to be true (with timeout)
  static Future<bool> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return true;
      }
      await Future.delayed(checkInterval);
    }

    return false;
  }

  /// Wait for a specific duration
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }
}

/// Test Cleanup Helpers
class TestCleanup {
  static final List<Function> _cleanupFunctions = [];

  /// Register a cleanup function to run after test
  static void register(Function cleanupFn) {
    _cleanupFunctions.add(cleanupFn);
  }

  /// Run all registered cleanup functions
  static Future<void> runAll() async {
    for (var fn in _cleanupFunctions) {
      try {
        await fn();
      } catch (e) {
        TestLogger.logWarning('Cleanup function failed: $e');
      }
    }
    _cleanupFunctions.clear();
  }

  /// Clear all registered cleanup functions
  static void clear() {
    _cleanupFunctions.clear();
  }
}

/// Test Environment Helpers
class TestEnvironment {
  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;

  /// Check if running in profile mode
  static bool get isProfileMode => kProfileMode;

  /// Get platform name
  static String get platformName {
    if (kIsWeb) return 'Web';
    return defaultTargetPlatform.name;
  }

  /// Print environment info
  static void logEnvironmentInfo() {
    TestLogger.logSection('Test Environment');
    TestLogger.log('Platform: $platformName');
    TestLogger.log('Debug Mode: $isDebugMode');
    TestLogger.log('Release Mode: $isReleaseMode');
    TestLogger.log('Profile Mode: $isProfileMode');
  }
}
