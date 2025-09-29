// lib/services/booking_service_extension.dart
// Add these methods to your existing BookingService class
// Or create this file and import it where needed

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingServiceExtension {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate unique booking ID
  static Future<String> generateBookingId() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Get count of bookings today
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final todayBookings = await _firestore
        .collection('bookings')
        .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final count = todayBookings.docs.length + 1;
    final bookingId = 'BK_${dateStr}_${count.toString().padLeft(4, '0')}';

    return bookingId;
  }

  /// Create booking with all necessary validations
  static Future<String> createBookingWithValidation({
    required String customerId,
    required String workerId,
    required String serviceType,
    required String problemDescription,
    required double estimatedCost,
    String? scheduledDate,
    String? scheduledTime,
    String? location,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      // Validate customer exists
      final customerDoc =
          await _firestore.collection('customers').doc(customerId).get();
      if (!customerDoc.exists) {
        throw Exception('Customer not found');
      }

      // Validate worker exists
      final workerQuery = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (workerQuery.docs.isEmpty) {
        throw Exception('Worker not found');
      }

      final workerDoc = workerQuery.docs.first;
      final workerData = workerDoc.data();

      // Generate booking ID
      final bookingId = await generateBookingId();

      // Create booking document
      final bookingData = {
        'booking_id': bookingId,
        'customer_id': customerId,
        'worker_id': workerId,
        'service_type': serviceType,
        'problem_description': problemDescription,
        'estimated_cost': estimatedCost,
        'status': 'requested',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),

        // Customer details
        'customer_name': customerDoc.data()?['customer_name'] ??
            customerDoc.data()?['first_name'] ??
            'Customer',
        'customer_phone': customerDoc.data()?['phone'] ?? '',
        'customer_email': customerDoc.data()?['email'] ?? '',

        // Worker details
        'worker_name': workerData['worker_name'] ?? '',
        'worker_phone': workerData['contact']?['phone_number'] ?? '',
        'worker_rating': workerData['rating'] ?? 0.0,

        // Optional fields
        if (scheduledDate != null) 'scheduled_date': scheduledDate,
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (location != null) 'location': location,
        if (additionalDetails != null) ...additionalDetails,
      };

      // Save booking
      await _firestore.collection('bookings').doc(bookingId).set(bookingData);

      // Send notifications
      await _sendBookingNotifications(
        bookingId: bookingId,
        customerId: customerId,
        customerName: bookingData['customer_name'],
        workerId: workerId,
        workerName: workerData['worker_name'],
        serviceType: serviceType,
      );

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Send notifications to both worker and customer
  static Future<void> _sendBookingNotifications({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
    required String serviceType,
  }) async {
    try {
      // Notify worker
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

      // Notify customer
      await _firestore.collection('notifications').add({
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'type': 'booking_created',
        'title': 'Booking Created',
        'message': 'Your booking request has been sent to $workerName',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Notifications sent for booking $bookingId');
    } catch (e) {
      print('❌ Failed to send notifications: $e');
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

  /// Update booking status with validation
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

      // Send status update notification
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

  /// Send status update notification
  static Future<void> _sendStatusUpdateNotification({
    required String bookingId,
    required String customerId,
    required String workerId,
    required String workerName,
    required String newStatus,
  }) async {
    String title = '';
    String message = '';

    switch (newStatus) {
      case 'accepted':
        title = 'Booking Accepted';
        message = '$workerName has accepted your booking request';
        break;
      case 'declined':
        title = 'Booking Declined';
        message = '$workerName has declined your booking request';
        break;
      case 'in_progress':
        title = 'Work Started';
        message = '$workerName has started working on your service';
        break;
      case 'completed':
        title = 'Service Completed';
        message =
            '$workerName has completed your service. Please rate the service.';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        message = 'Your booking has been cancelled';
        break;
      default:
        title = 'Booking Update';
        message = 'Your booking status has been updated';
    }

    try {
      await _firestore.collection('notifications').add({
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'type': 'booking_status_update',
        'title': title,
        'message': message,
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Failed to send notification: $e');
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

  /// Add rating to completed booking
  static Future<void> rateBooking({
    required String bookingId,
    required double rating,
    String? review,
  }) async {
    try {
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      if (bookingData['status'] != 'completed') {
        throw Exception('Can only rate completed bookings');
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'rating': rating,
        'review': review ?? '',
        'rated_at': FieldValue.serverTimestamp(),
      });

      // Update worker's average rating
      await _updateWorkerRating(bookingData['worker_id'], rating);

      print('✅ Booking $bookingId rated: $rating stars');
    } catch (e) {
      throw Exception('Failed to rate booking: $e');
    }
  }

  /// Update worker's average rating
  static Future<void> _updateWorkerRating(
      String workerId, double newRating) async {
    try {
      // Get all rated bookings for this worker
      final ratedBookings = await _firestore
          .collection('bookings')
          .where('worker_id', isEqualTo: workerId)
          .where('rating', isGreaterThan: 0)
          .get();

      if (ratedBookings.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      for (var doc in ratedBookings.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      double averageRating = totalRating / ratedBookings.docs.length;

      // Update worker document
      final workerQuery = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (workerQuery.docs.isNotEmpty) {
        await _firestore
            .collection('workers')
            .doc(workerQuery.docs.first.id)
            .update({
          'rating': averageRating,
          'total_ratings': ratedBookings.docs.length,
        });
      }
    } catch (e) {
      print('Failed to update worker rating: $e');
    }
  }
}
