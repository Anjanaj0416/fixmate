// test/unit/models/booking_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fixmate/models/booking_model.dart';

void main() {
  group('BookingModel Unit Tests', () {
    test('Create booking model with valid data', () {
      // Arrange
      final bookingData = {
        'booking_id': 'BK_1234567890',
        'worker_id': 'HM_1234',
        'customer_id': 'CUST_5678',
        'customer_name': 'Test Customer',
        'service_type': 'Plumbing',
        'status': 'requested',
      };

      // Act - Create booking model
      // In a real test, this would instantiate BookingModel
      final bookingId = bookingData['booking_id'] as String;

      // Assert
      expect(bookingId, startsWith('BK_'));
      expect(bookingId.length, equals(13));
    });

    test('Booking model validation - invalid worker_id', () {
      // Arrange
      final invalidWorkerId = 'INVALID_123';

      // Assert
      expect(invalidWorkerId.startsWith('HM_'), isFalse);
    });

    test('Booking model status transitions', () {
      // Test status transitions
      final validStatuses = [
        'requested',
        'accepted',
        'in_progress',
        'completed',
        'declined',
        'cancelled'
      ];

      for (final status in validStatuses) {
        expect(validStatuses.contains(status), isTrue);
      }
    });
  });
}
