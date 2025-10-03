// lib/services/booking_service.dart
// UPDATED VERSION - Fixed notification messages

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== NOTIFICATION METHODS ====================

  /// Send notification to worker when NEW booking request is created
  /// This notifies the worker that they have a new booking request to review
  static Future<void> _notifyWorker(
    String workerId,
    String bookingId,
    String customerName,
    String serviceType,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'worker_id': workerId,
        'recipient_id': workerId,
        'type': 'new_booking',
        'title': 'New Booking Request 📩',
        'message':
            'You have a new $serviceType booking request from $customerName',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent to: $workerId');
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  /// Send notification to customer
  /// NOTE: This is called when status changes (accepted, declined, etc.)
  /// NOT when booking is first created (to avoid "Your booking with X is now requested")
  static Future<void> _notifyCustomer(
    String customerId,
    String bookingId,
    String workerName,
    BookingStatus status,
  ) async {
    try {
      String title = '';
      String message = '';

      // Set appropriate message based on status
      switch (status) {
        case BookingStatus.accepted:
          title = 'Booking Accepted ✓';
          message = '$workerName has accepted your booking request!';
          break;
        case BookingStatus.declined:
          title = 'Booking Declined';
          message = '$workerName has declined your booking request';
          break;
        case BookingStatus.inProgress:
          title = 'Work Started';
          message = '$workerName has started working on your service';
          break;
        case BookingStatus.completed:
          title = 'Service Completed ✓';
          message =
              '$workerName has completed your service. Please rate the service.';
          break;
        case BookingStatus.cancelled:
          title = 'Booking Cancelled';
          message = 'Your booking has been cancelled';
          break;
        default:
          title = 'Booking Update';
          message = 'Your booking status has been updated';
      }

      await _firestore.collection('notifications').add({
        'recipient_type': 'customer',
        'customer_id': customerId,
        'recipient_id': customerId,
        'type': 'booking_status_update',
        'title': title,
        'message': message,
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Customer notification sent: $title');
    } catch (e) {
      print('⚠️  Failed to send customer notification: $e');
    }
  }

  // ==================== BOOKING CRUD OPERATIONS ====================

  /// Update booking status
  /// This is called by workers when they accept/decline bookings
  static Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
    String? notes,
    double? finalPrice, // ADD THIS PARAMETER
  }) async {
    try {
      print('\n========== UPDATE BOOKING STATUS ==========');
      print('Booking ID: $bookingId');
      print('New Status: $newStatus');

      // Get booking data first
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      Map<String, dynamic> bookingData =
          bookingDoc.data() as Map<String, dynamic>;

      // Prepare update data
      Map<String, dynamic> updates = {
        'status': newStatus.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
        if (notes != null) 'status_notes': notes,
        if (finalPrice != null) 'final_price': finalPrice, // ADD THIS
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case BookingStatus.accepted:
          updates['accepted_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.inProgress:
          updates['started_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.completed:
          updates['completed_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updates['cancelled_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.declined:
          updates['declined_at'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      // Update booking
      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Send notification to customer about the status change
      String customerId = bookingData['customer_id'];
      String workerName = bookingData['worker_name'];

      await _notifyCustomer(
        customerId,
        bookingId,
        workerName,
        newStatus,
      );

      print('✅ Booking status updated successfully');
      print('========== UPDATE END ==========\n');
    } catch (e) {
      print('❌ Error updating booking status: $e');
      print('========== UPDATE END ==========\n');
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }

  /// Create booking
  static Future<String> createBooking({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String workerId,
    required String workerName,
    required String workerPhone,
    required String serviceType,
    required String subService,
    required String issueType,
    required String problemDescription,
    required List<String> problemImageUrls,
    required String location,
    required String address,
    required String urgency,
    required String budgetRange,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) async {
    try {
      print('\n========== CREATE BOOKING ==========');
      print('Customer: $customerName ($customerId)');
      print('Worker: $workerName ($workerId)');
      print('Service: $serviceType');

      // Validate worker_id format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX)');
      }

      // Generate booking ID
      String bookingId = _firestore.collection('bookings').doc().id;
      print('Generated booking ID: $bookingId');

      // Create booking model
      BookingModel booking = BookingModel(
        bookingId: bookingId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
        workerName: workerName,
        workerPhone: workerPhone,
        serviceType: serviceType,
        subService: subService,
        issueType: issueType,
        problemDescription: problemDescription,
        problemImageUrls: problemImageUrls,
        location: location,
        address: address,
        urgency: urgency,
        budgetRange: budgetRange,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        status: BookingStatus.requested,
        createdAt: DateTime.now(),
      );

      // Save booking to Firestore
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .set(booking.toFirestore());

      print('✅ Booking created successfully!');
      print('   Booking ID: $bookingId');
      print('   Worker ID: $workerId');
      print('   Status: requested');

      // Send notification to worker about NEW booking request
      await _notifyWorker(workerId, bookingId, customerName, serviceType);

      // DO NOT send notification to customer here
      // Customer will only get notified when worker accepts/declines
      // This avoids the confusing "Your booking with X is now requested" message

      print('========== CREATE BOOKING END ==========\n');

      return bookingId;
    } catch (e) {
      print('❌ Error creating booking: $e');
      print('========== CREATE BOOKING END ==========\n');
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Create booking with worker validation
  static Future<String> createBookingWithValidation({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String workerId,
    required String serviceType,
    required String subService,
    required String issueType,
    required String problemDescription,
    required List<String> problemImageUrls,
    required String location,
    required String address,
    required String urgency,
    required String budgetRange,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) async {
    try {
      // Validate and get worker details
      Map<String, dynamic> workerData =
          await getWorkerDetailsByWorkerId(workerId);

      String workerName = workerData['worker_name'] ?? '';
      String workerPhone = workerData['contact']?['phone_number'] ?? '';

      // Create booking with validated data
      return await createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
        workerName: workerName,
        workerPhone: workerPhone,
        serviceType: serviceType,
        subService: subService,
        issueType: issueType,
        problemDescription: problemDescription,
        problemImageUrls: problemImageUrls,
        location: location,
        address: address,
        urgency: urgency,
        budgetRange: budgetRange,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      throw Exception('Failed to create booking with validation: $e');
    }
  }

  /// Get worker details by worker_id
  static Future<Map<String, dynamic>> getWorkerDetailsByWorkerId(
      String workerId) async {
    try {
      QuerySnapshot workerQuery = await _firestore
          .collection('workers')
          .where('worker_id', isEqualTo: workerId)
          .limit(1)
          .get();

      if (workerQuery.docs.isEmpty) {
        throw Exception('Worker not found with ID: $workerId');
      }

      return workerQuery.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get worker details: $e');
    }
  }

  /// Get bookings for worker
  static Stream<List<BookingModel>> getWorkerBookingsStream(
    String workerId, {
    String? statusFilter,
  }) {
    Query query = _firestore
        .collection('bookings')
        .where('worker_id', isEqualTo: workerId);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('created_at', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get bookings for customer
  static Stream<List<BookingModel>> getCustomerBookingsStream(
    String customerId, {
    String? statusFilter,
  }) {
    Query query = _firestore
        .collection('bookings')
        .where('customer_id', isEqualTo: customerId);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('created_at', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList(),
        );
  }
}
