// test/fixtures/test_data.dart
// Centralized test data and fixtures for all authentication tests
// Use this file to manage consistent test data across all test suites

import 'package:cloud_firestore/cloud_firestore.dart';

/// Test user accounts with various scenarios
class TestUsers {
  // Valid test users
  static const Map<String, dynamic> validUser1 = {
    'uid': 'test_uid_001',
    'name': 'John Doe',
    'email': 'john@test.com',
    'password': 'Test@123',
    'phone': '+94771234567',
    'address': 'Colombo 03',
    'nearestTown': 'Colombo',
    'accountType': 'customer',
    'emailVerified': true,
  };

  static const Map<String, dynamic> validUser2 = {
    'uid': 'test_uid_002',
    'name': 'Jane Smith',
    'email': 'jane@test.com',
    'password': 'Test@456',
    'phone': '+94772345678',
    'address': 'Kandy',
    'nearestTown': 'Kandy',
    'accountType': 'customer',
    'emailVerified': true,
  };

  // Worker account
  static const Map<String, dynamic> workerUser = {
    'uid': 'worker_uid_001',
    'name': 'Mike Wilson',
    'email': 'mike.worker@test.com',
    'password': 'Worker@123',
    'phone': '+94773456789',
    'address': 'Galle',
    'nearestTown': 'Galle',
    'accountType': 'both',
    'emailVerified': true,
  };

  // Unverified user
  static const Map<String, dynamic> unverifiedUser = {
    'uid': 'unverified_uid_001',
    'name': 'Bob Unverified',
    'email': 'unverified@test.com',
    'password': 'Test@789',
    'phone': '+94774567890',
    'address': 'Negombo',
    'nearestTown': 'Negombo',
    'accountType': 'customer',
    'emailVerified': false,
  };

  // Google OAuth user
  static const Map<String, dynamic> googleUser = {
    'uid': 'google_uid_001',
    'name': 'Alice Google',
    'email': 'alice@gmail.com',
    'displayName': 'Alice Google',
    'photoURL': 'https://example.com/alice.jpg',
    'accountType': 'customer',
    'emailVerified': true,
    'authProvider': 'google.com',
  };

  // Admin user
  static const Map<String, dynamic> adminUser = {
    'uid': 'admin_uid_001',
    'name': 'Admin User',
    'email': 'admin@fixmate.com',
    'password': 'Admin@123',
    'phone': '+94775678901',
    'accountType': 'admin',
    'emailVerified': true,
    'role': 'admin',
  };
}

/// Invalid test data for validation testing
class InvalidTestData {
  // Invalid emails (FT-036)
  static const List<String> invalidEmails = [
    'user@',
    'user',
    '@domain.com',
    'user@domain',
    'user@.com',
    '@.com',
    'user @domain.com',
    'user@domain .com',
    'user..name@domain.com',
    '.user@domain.com',
    'user.@domain.com',
  ];

  // Weak passwords (FT-037)
  static const List<String> weakPasswords = [
    '',
    '1',
    '12',
    '123',
    '1234',
    '12345',
    'abc',
    'abcde',
    'password',
  ];

  // Invalid phone numbers
  static const List<String> invalidPhones = [
    '0771234567',
    '+9477123456', // Too short
    '+947712345678', // Too long
    '771234567',
    '+1234567890',
    'invalid',
    '',
  ];

  // SQL injection attempts
  static const List<String> sqlInjectionPayloads = [
    "admin'--",
    "admin' OR '1'='1",
    "admin'; DROP TABLE users--",
    "' OR 1=1--",
    "admin'/*",
    "1' UNION SELECT * FROM users--",
  ];

  // XSS attack payloads
  static const List<String> xssPayloads = [
    '<script>alert("XSS")</script>',
    '"><script>alert(String.fromCharCode(88,83,83))</script>',
    '<img src=x onerror=alert("XSS")>',
    '<svg onload=alert("XSS")>',
    'javascript:alert("XSS")',
    '<iframe src="javascript:alert(\'XSS\')">',
    '<body onload=alert("XSS")>',
  ];

  // Path traversal attempts
  static const List<String> pathTraversalPayloads = [
    '../../etc/passwd',
    '../../../windows/system32',
    '....//....//....//etc/passwd',
    '..\\..\\..\\windows\\system32',
  ];
}

/// Valid test data for different scenarios
class ValidTestData {
  // Valid email addresses
  static const List<String> validEmails = [
    'test@example.com',
    'user.name@example.com',
    'user+tag@example.co.uk',
    'user123@test-domain.com',
    'test_user@example.org',
  ];

  // Strong passwords
  static const List<String> strongPasswords = [
    'Test@123',
    'SecurePass123!',
    'MyP@ssw0rd',
    'Strong#Pass456',
    'Complex!Pass789',
  ];

  // Valid phone numbers (Sri Lankan format)
  static const List<String> validPhones = [
    '+94771234567',
    '+94712345678',
    '+94777654321',
    '+94767890123',
    '+94754321098',
  ];

  // Valid Sri Lankan cities/towns
  static const List<String> sriLankanCities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Negombo',
    'Jaffna',
    'Matara',
    'Batticaloa',
    'Trincomalee',
    'Anuradhapura',
    'Nuwara Eliya',
  ];
}

/// Test OTP codes and verification data
class TestOTPData {
  static const String validOTP = '123456';
  static const String invalidOTP = '000000';
  static const String expiredOTP = '999999';

  // OTP scenarios
  static const Map<String, dynamic> validOTPScenario = {
    'otp': '123456',
    'phoneNumber': '+94771234567',
    'generatedAt': '2025-01-01T10:00:00Z',
    'expiresAt': '2025-01-01T10:10:00Z',
    'attempts': 0,
    'isLocked': false,
  };

  static const Map<String, dynamic> expiredOTPScenario = {
    'otp': '999999',
    'phoneNumber': '+94771234567',
    'generatedAt': '2025-01-01T09:00:00Z',
    'expiresAt': '2025-01-01T09:10:00Z',
    'attempts': 0,
    'isLocked': false,
  };

  static const Map<String, dynamic> lockedOTPScenario = {
    'otp': '111111',
    'phoneNumber': '+94771234567',
    'generatedAt': '2025-01-01T10:00:00Z',
    'expiresAt': '2025-01-01T10:10:00Z',
    'attempts': 5,
    'isLocked': true,
    'lockedUntil': '2025-01-01T11:00:00Z',
  };
}

/// Account lockout test scenarios
class TestLockoutScenarios {
  // Account locked after 5 failed attempts
  static const Map<String, dynamic> lockedAccount = {
    'email': 'locked@test.com',
    'failedLoginAttempts': 5,
    'accountLocked': true,
    'lockedAt': '2025-01-01T10:00:00Z',
    'lockedUntil': '2025-01-01T10:15:00Z',
  };

  // Account with 3 failed attempts
  static const Map<String, dynamic> partiallyLockedAccount = {
    'email': 'partial@test.com',
    'failedLoginAttempts': 3,
    'accountLocked': false,
    'lastFailedAttempt': '2025-01-01T10:00:00Z',
  };

  // Account with successful login (reset counter)
  static const Map<String, dynamic> resetAccount = {
    'email': 'reset@test.com',
    'failedLoginAttempts': 0,
    'accountLocked': false,
    'lastSuccessfulLogin': '2025-01-01T10:00:00Z',
  };
}

/// Worker profile test data
class TestWorkerProfiles {
  static const Map<String, dynamic> electrician = {
    'worker_id': 'HM_0001',
    'workerName': 'John Electrician',
    'firstName': 'John',
    'lastName': 'Electrician',
    'email': 'john.electrician@test.com',
    'phoneNumber': '+94771234567',
    'serviceType': 'electrical_services',
    'serviceCategory': 'electrical_installation',
    'experienceYears': 5,
    'rating': 4.5,
    'dailyWageLkr': 3000.0,
    'city': 'Colombo',
    'verified': true,
    'active': true,
  };

  static const Map<String, dynamic> plumber = {
    'worker_id': 'HM_0002',
    'workerName': 'Mike Plumber',
    'firstName': 'Mike',
    'lastName': 'Plumber',
    'email': 'mike.plumber@test.com',
    'phoneNumber': '+94772345678',
    'serviceType': 'plumbing_services',
    'serviceCategory': 'pipe_repair',
    'experienceYears': 8,
    'rating': 4.8,
    'dailyWageLkr': 3500.0,
    'city': 'Kandy',
    'verified': true,
    'active': true,
  };

  static const Map<String, dynamic> unverifiedWorker = {
    'worker_id': 'HM_0003',
    'workerName': 'Bob Unverified',
    'firstName': 'Bob',
    'lastName': 'Unverified',
    'email': 'bob.unverified@test.com',
    'phoneNumber': '+94773456789',
    'serviceType': 'electrical_services',
    'experienceYears': 2,
    'rating': 0.0,
    'dailyWageLkr': 2000.0,
    'city': 'Galle',
    'verified': false,
    'active': false,
  };
}

/// Email verification test data
class TestEmailVerification {
  static const Map<String, dynamic> pendingVerification = {
    'email': 'pending@test.com',
    'emailVerified': false,
    'verificationEmailSent': true,
    'verificationEmailSentAt': '2025-01-01T10:00:00Z',
    'verificationLink': 'https://app.com/verify?token=abc123',
    'verificationLinkExpiresAt': '2025-01-02T10:00:00Z',
  };

  static const Map<String, dynamic> verifiedEmail = {
    'email': 'verified@test.com',
    'emailVerified': true,
    'verifiedAt': '2025-01-01T10:05:00Z',
  };

  static const Map<String, dynamic> expiredVerification = {
    'email': 'expired@test.com',
    'emailVerified': false,
    'verificationEmailSent': true,
    'verificationEmailSentAt': '2024-12-30T10:00:00Z',
    'verificationLink': 'https://app.com/verify?token=expired123',
    'verificationLinkExpiresAt': '2024-12-31T10:00:00Z',
  };
}

/// Password reset test data
class TestPasswordReset {
  static const Map<String, dynamic> validResetRequest = {
    'email': 'reset@test.com',
    'resetToken': 'reset_token_123',
    'resetTokenExpiresAt': '2025-01-01T11:00:00Z',
    'resetRequestedAt': '2025-01-01T10:00:00Z',
  };

  static const Map<String, dynamic> expiredResetRequest = {
    'email': 'expired.reset@test.com',
    'resetToken': 'expired_token_456',
    'resetTokenExpiresAt': '2024-12-31T10:00:00Z',
    'resetRequestedAt': '2024-12-31T09:00:00Z',
  };

  static const Map<String, dynamic> usedResetToken = {
    'email': 'used.reset@test.com',
    'resetToken': 'used_token_789',
    'resetTokenUsed': true,
    'resetTokenUsedAt': '2025-01-01T09:30:00Z',
  };
}

/// Account type scenarios
class TestAccountTypes {
  static const Map<String, dynamic> customerOnly = {
    'accountType': 'customer',
    'hasWorkerProfile': false,
    'canBookServices': true,
    'canOfferServices': false,
  };

  static const Map<String, dynamic> workerOnly = {
    'accountType': 'worker',
    'hasWorkerProfile': true,
    'canBookServices': false,
    'canOfferServices': true,
  };

  static const Map<String, dynamic> bothCustomerAndWorker = {
    'accountType': 'both',
    'hasWorkerProfile': true,
    'canBookServices': true,
    'canOfferServices': true,
    'primaryAccount': 'customer',
  };

  static const Map<String, dynamic> switchingToProfessional = {
    'previousAccountType': 'customer',
    'newAccountType': 'both',
    'switchedAt': '2025-01-01T10:00:00Z',
    'workerProfileCreatedAt': '2025-01-01T10:05:00Z',
  };

  static const Map<String, dynamic> switchingBackToCustomer = {
    'previousAccountType': 'both',
    'newAccountType': 'customer',
    'switchedAt': '2025-01-01T11:00:00Z',
    'workerProfileDeactivatedAt': '2025-01-01T11:00:00Z',
    'workerProfilePreserved': true,
  };
}

/// Firestore document templates
class FirestoreTemplates {
  static Map<String, dynamic> userDocument({
    required String uid,
    required String email,
    required String name,
    String? phone,
    String? address,
    String? nearestTown,
    bool emailVerified = false,
    String accountType = 'customer',
  }) {
    return {
      'email': email,
      'name': name,
      'phone': phone ?? '',
      'address': address ?? '',
      'nearestTown': nearestTown ?? '',
      'emailVerified': emailVerified,
      'accountType': accountType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> workerDocument({
    required String workerId,
    required String email,
    required String serviceType,
    int experienceYears = 0,
    double rating = 0.0,
    bool verified = false,
    bool active = true,
  }) {
    return {
      'worker_id': workerId,
      'email': email,
      'serviceType': serviceType,
      'experienceYears': experienceYears,
      'rating': rating,
      'verified': verified,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Test scenarios for specific test cases
class TestScenarios {
  // FT-001: User Account Creation
  static const Map<String, dynamic> ft001Success = {
    'testId': 'FT-001',
    'scenario': 'successful_registration',
    'userData': TestUsers.validUser1,
    'expectedOutcome': 'account_created',
  };

  // FT-002: Email/Password Login
  static const Map<String, dynamic> ft002Success = {
    'testId': 'FT-002',
    'scenario': 'successful_login',
    'email': 'john@test.com',
    'password': 'Test@123',
    'expectedOutcome': 'login_success',
  };

  // FT-039: Account Lockout
  static const Map<String, dynamic> ft039Lockout = {
    'testId': 'FT-039',
    'scenario': 'account_lockout',
    'email': 'test@example.com',
    'attempts': 5,
    'expectedOutcome': 'account_locked',
    'lockoutDuration': 15, // minutes
  };

  // FT-043: Expired OTP
  static const Map<String, dynamic> ft043ExpiredOTP = {
    'testId': 'FT-043',
    'scenario': 'expired_otp',
    'phoneNumber': '+94771234567',
    'otp': '123456',
    'ageMinutes': 11,
    'expectedOutcome': 'otp_expired',
  };
}

/// Helper class to generate test data
class TestDataGenerator {
  /// Generate random valid email
  static String randomEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test_$timestamp@example.com';
  }

  /// Generate random valid password
  static String randomPassword() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Pass@${timestamp % 10000}';
  }

  /// Generate random phone number
  static String randomPhone() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000000;
    return '+94${random.toString().padLeft(9, '7')}';
  }

  /// Generate random OTP
  static String randomOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Generate random user data
  static Map<String, dynamic> randomUser() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return {
      'uid': 'test_uid_$timestamp',
      'name': 'Test User $timestamp',
      'email': randomEmail(),
      'password': randomPassword(),
      'phone': randomPhone(),
      'address': 'Test Address',
      'nearestTown': ValidTestData.sriLankanCities[timestamp % 10],
      'accountType': 'customer',
      'emailVerified': false,
    };
  }
}
