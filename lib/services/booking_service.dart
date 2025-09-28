// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique booking ID
  static Future<String> generateBookingId() async {
    // Get the count of existing bookings to generate sequential ID
    QuerySnapshot bookingCount = await _firestore.collection('bookings').get();
    int count = bookingCount.docs.length + 1;

    // Format: B_XXXX (4 digits)
    String bookingId = 'B_${count.toString().padLeft(4, '0')}';

    // Check if ID already exists, if so increment
    while (await _bookingIdExists(bookingId)) {
      count++;
      bookingId = 'B_${count.toString().padLeft(4, '0')}';
    }

    return bookingId;
  }

  // Check if booking ID exists
  static Future<bool> _bookingIdExists(String bookingId) async {
    QuerySnapshot existing = await _firestore
        .collection('bookings')
        .where('booking_id', isEqualTo: bookingId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Create a new booking
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
      // Generate unique booking ID
      String bookingId = await generateBookingId();

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

      // Send notification to worker (optional)
      await _notifyWorker(workerId, bookingId, customerName, serviceType);

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  // Get bookings for a customer
  static Future<List<BookingModel>> getCustomerBookings(
      String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('customer_id', isEqualTo: customerId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get customer bookings: ${e.toString()}');
    }
  }

  // Get bookings for a worker
  static Future<List<BookingModel>> getWorkerBookings(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('worker_id', isEqualTo: workerId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get worker bookings: ${e.toString()}');
    }
  }

  // Update booking status
  static Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? cancellationReason,
    double? finalPrice,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      switch (status) {
        case BookingStatus.accepted:
          updateData['accepted_at'] = FieldValue.serverTimestamp();
          if (finalPrice != null) {
            updateData['final_price'] = finalPrice;
          }
          break;
        case BookingStatus.completed:
          updateData['completed_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updateData['cancelled_at'] = FieldValue.serverTimestamp();
          if (cancellationReason != null) {
            updateData['cancellation_reason'] = cancellationReason;
          }
          break;
        case BookingStatus.declined:
          updateData['cancelled_at'] = FieldValue.serverTimestamp();
          if (cancellationReason != null) {
            updateData['cancellation_reason'] = cancellationReason;
          }
          break;
        default:
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Send notification to customer about status change
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (bookingDoc.exists) {
        Map<String, dynamic> bookingData =
            bookingDoc.data() as Map<String, dynamic>;
        await _notifyCustomer(
          bookingData['customer_id'],
          bookingId,
          bookingData['worker_name'],
          status,
        );
      }
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }

  // Add rating and review
  static Future<void> addRating({
    required String bookingId,
    required double rating,
    required String review,
    required bool isCustomerRating,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isCustomerRating) {
        updateData['customer_rating'] = rating;
        updateData['customer_review'] = review;
      } else {
        updateData['worker_rating'] = rating;
        updateData['worker_review'] = review;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Update worker's overall rating if it's a customer rating
      if (isCustomerRating) {
        await _updateWorkerRating(bookingId, rating);
      }
    } catch (e) {
      throw Exception('Failed to add rating: ${e.toString()}');
    }
  }

  // Update worker's overall rating
  static Future<void> _updateWorkerRating(
      String bookingId, double newRating) async {
    try {
      // Get the booking to find the worker
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) return;

      Map<String, dynamic> bookingData =
          bookingDoc.data() as Map<String, dynamic>;
      String workerId = bookingData['worker_id'];

      // Get all completed bookings for this worker with ratings
      QuerySnapshot workerBookings = await _firestore
          .collection('bookings')
          .where('worker_id', isEqualTo: workerId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate new average rating
      List<double> ratings = [];
      for (var doc in workerBookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['customer_rating'] != null) {
          ratings.add(data['customer_rating'].toDouble());
        }
      }

      if (ratings.isNotEmpty) {
        double averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

        // Update worker's rating
        await _firestore
            .collection('workers')
            .where('worker_id', isEqualTo: workerId)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            snapshot.docs.first.reference.update({
              'rating': averageRating,
              'jobs_completed': ratings.length,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (e) {
      print('Failed to update worker rating: ${e.toString()}');
    }
  }

  // Get booking by ID
  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: ${e.toString()}');
    }
  }

  // Cancel booking
  static Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await updateBookingStatus(
        bookingId,
        BookingStatus.cancelled,
        cancellationReason: reason,
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  // Send notification to worker (placeholder)
  static Future<void> _notifyWorker(
    String workerId,
    String bookingId,
    String customerName,
    String serviceType,
  ) async {
    // In a real app, this would send a push notification or SMS
    // For now, we'll just log or create a notification record
    try {
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
    } catch (e) {
      print('Failed to send worker notification: ${e.toString()}');
    }
  }

  // Send notification to customer (placeholder)
  static Future<void> _notifyCustomer(
    String customerId,
    String bookingId,
    String workerName,
    BookingStatus status,
  ) async {
    try {
      String message = '';
      switch (status) {
        case BookingStatus.accepted:
          message = '$workerName has accepted your booking request';
          break;
        case BookingStatus.declined:
          message = '$workerName has declined your booking request';
          break;
        case BookingStatus.completed:
          message = '$workerName has completed your service';
          break;
        case BookingStatus.cancelled:
          message = 'Your booking with $workerName has been cancelled';
          break;
        default:
          message = 'Your booking status has been updated';
      }

      await _firestore.collection('notifications').add({
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'type': 'booking_update',
        'title': 'Booking Update',
        'message': message,
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Failed to send customer notification: ${e.toString()}');
    }
  }

  // Get booking history with filters
  static Future<List<BookingModel>> getBookingHistory({
    required String userId,
    required bool isWorker,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('bookings');

      // Filter by user
      if (isWorker) {
        query = query.where('worker_id', isEqualTo: userId);
      } else {
        query = query.where('customer_id', isEqualTo: userId);
      }

      // Filter by status
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      // Filter by date range
      if (startDate != null) {
        query = query.where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Order by creation date
      query = query.orderBy('created_at', descending: true);

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get booking history: ${e.toString()}');
    }
  }
}
