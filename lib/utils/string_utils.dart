// lib/utils/string_utils.dart
/// Utility class for safe string operations
class StringUtils {
  /// Safely truncate a string to a maximum length
  /// Returns the original string if it's shorter than maxLength
  /// Adds ellipsis (...) by default if truncated
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
    bool addEllipsis = true,
  }) {
    if (text.isEmpty) return text;
    if (text.length <= maxLength) return text;

    if (addEllipsis && maxLength > ellipsis.length) {
      return text.substring(0, maxLength - ellipsis.length) + ellipsis;
    }

    return text.substring(0, maxLength);
  }

  /// Safely get a substring with bounds checking
  /// Returns the substring if valid, otherwise returns the original string or empty
  static String safeSubstring(
    String text,
    int start, [
    int? end,
  ]) {
    if (text.isEmpty) return text;

    // Ensure start is within bounds
    if (start < 0 || start >= text.length) {
      return text; // Return original if start is invalid
    }

    // If no end specified, return from start to end of string
    if (end == null) {
      return text.substring(start);
    }

    // Ensure end is within bounds
    if (end > text.length) {
      end = text.length;
    }

    // Ensure start is before end
    if (start >= end) {
      return text.substring(start);
    }

    return text.substring(start, end);
  }

  /// Format a booking ID for display (safely truncated)
  static String formatBookingId(String bookingId, {int maxLength = 12}) {
    return truncate(bookingId, maxLength, addEllipsis: true);
  }

  /// Format a customer ID for display
  static String formatCustomerId(String customerId, {int maxLength = 12}) {
    return truncate(customerId, maxLength, addEllipsis: true);
  }

  /// Format a worker ID for display
  static String formatWorkerId(String workerId, {int maxLength = 12}) {
    return truncate(workerId, maxLength, addEllipsis: true);
  }

  /// Check if a string is a valid ID format (not null, not empty, reasonable length)
  static bool isValidId(String? id, {int minLength = 5, int maxLength = 100}) {
    if (id == null || id.isEmpty) return false;
    return id.length >= minLength && id.length <= maxLength;
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Replace underscores with spaces and capitalize
  static String formatEnumValue(String value) {
    return capitalizeWords(value.replaceAll('_', ' '));
  }
}
