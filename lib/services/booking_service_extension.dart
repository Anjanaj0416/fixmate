// lib/services/booking_service_extension.dart
// UPDATED VERSION - Fixed notification messages for customer and worker

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingServiceExtension {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send status update notification
  /// This sends proper notifications to customers when worker accepts/declines
  static Future<void> _sendStatusUpdateNotification({
    required String bookingId,
    required String customerId,
    required String workerId,
    required String workerName,
    required String newStatus,
  }) async {
    String title = '';
    String customerMessage = '';

    switch (newStatus) {
      case 'accepted':
        title = 'Booking Accepted ✓';
        customerMessage = '$workerName has accepted your booking request!';
        break;
      case 'declined':
        title = 'Booking Declined';
        customerMessage = '$workerName has declined your booking request';
        break;
      case 'in_progress':
        title = 'Work Started';
        customerMessage = '$workerName has started working on your service';
        break;
      case 'completed':
        title = 'Service Completed';
        customerMessage =
            '$workerName has completed your service. Please rate the service.';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        customerMessage = 'Your booking has been cancelled';
        break;
      default:
        title = 'Booking Update';
        customerMessage = 'Your booking status has been updated';
    }

    try {
      // Send notification to customer
      await _firestore.collection('notifications').add({
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'type': 'booking_status_update',
        'title': title,
        'message': customerMessage,
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Customer notification sent: $title');
    } catch (e) {
      print('❌ Failed to send notification: $e');
    }
  }

  /// Send notifications to both worker and customer when booking is created
  static Future<void> _sendBookingNotifications({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
    required String serviceType,
  }) async {
    try {
      // Notify worker about NEW booking request
      await _firestore.collection('notifications').add({
        'recipient_id': workerId,
        'recipient_type': 'worker',
        'type': 'new_booking',
        'title': 'New Booking Request',
        'message':
            'You have a new $serviceType booking request from $customerName',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent: New booking request');

      // Notify customer that booking was CREATED (not "requested")
      // Don't show "Your booking with X is now requested" - that's confusing
      // Only show this initial notification if needed, otherwise skip
      // We'll rely on the acceptance notification instead

      print('✅ Notifications sent for booking $bookingId');
    } catch (e) {
      print('❌ Failed to send notifications: $e');
    }
  }

  /// Update booking status with validation and notifications
  static Future<void> updateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? userId,
    String? notes,
  }) async {
    try {
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final updates = {
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
        if (notes != null) 'status_notes': notes,
      };

      // Add status-specific fields
      switch (newStatus) {
        case 'accepted':
          updates['accepted_at'] = FieldValue.serverTimestamp();
          break;
        case 'in_progress':
          updates['started_at'] = FieldValue.serverTimestamp();
          break;
        case 'completed':
          updates['completed_at'] = FieldValue.serverTimestamp();
          break;
        case 'cancelled':
          updates['cancelled_at'] = FieldValue.serverTimestamp();
          if (userId != null) updates['cancelled_by'] = userId;
          break;
        case 'declined':
          updates['declined_at'] = FieldValue.serverTimestamp();
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Send status update notification to customer
      final bookingData = bookingDoc.data()!;
      await _sendStatusUpdateNotification(
        bookingId: bookingId,
        customerId: bookingData['customer_id'],
        workerId: bookingData['worker_id'],
        workerName: bookingData['worker_name'],
        newStatus: newStatus,
      );

      print('✅ Booking $bookingId status updated to $newStatus');
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Get booking status statistics for customer
  static Future<Map<String, int>> getCustomerBookingStats(
      String customerId) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('customer_id', isEqualTo: customerId)
          .get();

      Map<String, int> stats = {
        'total': bookings.docs.length,
        'requested': 0,
        'accepted': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
        'declined': 0,
      };

      for (var doc in bookings.docs) {
        String status = doc.data()['status'] ?? 'requested';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting booking stats: $e');
      return {'total': 0};
    }
  }

  /// Get booking status statistics for worker
  static Future<Map<String, int>> getWorkerBookingStats(String workerId) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('worker_id', isEqualTo: workerId)
          .get();

      Map<String, int> stats = {
        'total': bookings.docs.length,
        'requested': 0,
        'accepted': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
        'declined': 0,
      };

      for (var doc in bookings.docs) {
        String status = doc.data()['status'] ?? 'requested';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting booking stats: $e');
      return {'total': 0};
    }
  }

  /// Cancel booking with reason
  static Future<void> cancelBooking({
    required String bookingId,
    required String userId,
    required String userType, // 'customer' or 'worker'
    String? reason,
  }) async {
    try {
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: 'cancelled',
        userId: userId,
        notes: reason ?? 'Cancelled by $userType',
      );

      await _firestore.collection('bookings').doc(bookingId).update({
        'cancellation_reason': reason ?? 'No reason provided',
        'cancelled_by_type': userType,
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
