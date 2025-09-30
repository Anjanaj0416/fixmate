// lib/services/booking_service.dart
// FIXED VERSION - Ensures worker_id is used correctly in bookings

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// CRITICAL FIX: Get worker details by worker_id (HM_XXXX format)
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

  /// Create a new booking
  /// CRITICAL: workerId parameter must be worker_id (HM_XXXX), NOT Firebase UID
  static Future<String> createBooking({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String workerId, // This is worker_id (HM_XXXX format)
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
      print('\n========== CREATE BOOKING START ==========');
      print('Customer ID: $customerId');
      print('Worker ID: $workerId'); // Should be HM_XXXX format
      print('Service Type: $serviceType');

      // Validate worker_id format
      if (!workerId.startsWith('HM_')) {
        print('⚠️  WARNING: worker_id should start with HM_');
        print('   Received: $workerId');
        print('   This might cause booking display issues!');
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
        workerId: workerId, // CRITICAL: Must be HM_XXXX format
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
      print('========== CREATE BOOKING END ==========\n');

      // Send notifications
      await _notifyWorker(workerId, bookingId, customerName, serviceType);
      await _notifyCustomer(
        customerId,
        bookingId,
        workerName,
        BookingStatus.requested,
      );

      return bookingId;
    } catch (e) {
      print('❌ Error creating booking: $e');
      print('========== CREATE BOOKING END ==========\n');
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  /// Create booking with worker validation
  /// This version validates the worker exists before creating the booking
  static Future<String> createBookingWithValidation({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String workerId, // worker_id in HM_XXXX format
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
        workerId: workerId, // worker_id (HM_XXXX)
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

  // Send notification to worker
  static Future<void> _notifyWorker(
    String workerId, // worker_id (HM_XXXX)
    String bookingId,
    String customerName,
    String serviceType,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'worker_id': workerId, // Use worker_id, not UID
        'type': 'new_booking',
        'title': 'New Booking Request',
        'message': 'New $serviceType booking request from $customerName',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Notification sent to worker: $workerId');
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  // Send notification to customer
  static Future<void> _notifyCustomer(
    String customerId,
    String bookingId,
    String workerName,
    BookingStatus status,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'customer',
        'customer_id': customerId,
        'type': 'booking_status_update',
        'title': 'Booking ${status.displayName}',
        'message':
            'Your booking with $workerName is now ${status.displayName.toLowerCase()}',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Notification sent to customer: $customerId');
    } catch (e) {
      print('⚠️  Failed to send customer notification: $e');
    }
  }

  // Get bookings for worker
  static Stream<List<BookingModel>> getWorkerBookingsStream(
      String workerId, // worker_id (HM_XXXX)
      {String? statusFilter}) {
    Query query = _firestore
        .collection('bookings')
        .where('worker_id', isEqualTo: workerId);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.orderBy('created_at', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get bookings for customer
  static Stream<List<BookingModel>> getCustomerBookingsStream(String customerId,
      {String? statusFilter}) {
    Query query = _firestore
        .collection('bookings')
        .where('customer_id', isEqualTo: customerId);

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.orderBy('created_at', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  // Update booking status
  static Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
    String? notes,
    double? finalPrice,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': newStatus.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (notes != null) updates['worker_notes'] = notes;
      if (finalPrice != null) updates['final_price'] = finalPrice;

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
        default:
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      print('✅ Booking status updated to: ${newStatus.toString()}');
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Get single booking
  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  // Cancel booking
  static Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString(),
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancellation_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Booking cancelled: $bookingId');
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Add rating to booking
  static Future<void> addRating({
    required String bookingId,
    required double rating,
    required String review,
    required bool isCustomerRating,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isCustomerRating) {
        updates['customer_rating'] = rating;
        updates['customer_review'] = review;
      } else {
        updates['worker_rating'] = rating;
        updates['worker_review'] = review;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      print('✅ Rating added to booking: $bookingId');
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }
}
