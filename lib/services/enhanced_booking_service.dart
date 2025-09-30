// lib/services/enhanced_booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import 'dart:math' as math;

class EnhancedBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique booking ID
  static Future<String> _generateBookingId() async {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String randomSuffix = (math.Random().nextInt(9999) + 1000).toString();
    return 'BK_${timestamp.substring(timestamp.length - 6)}$randomSuffix';
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
      String bookingId = await _generateBookingId();

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
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      // Save booking to Firestore
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .set(booking.toFirestore());

      // Update customer's booking history
      await _firestore.collection('customers').doc(customerId).update({
        'bookingHistory': FieldValue.arrayUnion([bookingId]),
        'totalBookings': FieldValue.increment(1),
        'lastBookingDate': FieldValue.serverTimestamp(),
      });

      // Update worker's booking queue
      await _firestore.collection('workers').doc(workerId).update({
        'pendingBookings': FieldValue.arrayUnion([bookingId]),
        'totalBookingsReceived': FieldValue.increment(1),
        'lastBookingReceived': FieldValue.serverTimestamp(),
      });

      // Create notification for worker
      await _createNotification(
        userId: workerId,
        type: 'new_booking',
        title: 'New Booking Request',
        message:
            'You have received a new booking request for $serviceType service.',
        data: {
          'bookingId': bookingId,
          'serviceType': serviceType,
          'customerName': customerName,
          'urgency': urgency,
        },
      );

      // Create notification for customer
      await _createNotification(
        userId: customerId,
        type: 'booking_created',
        title: 'Booking Created',
        message: 'Your booking request has been sent to $workerName.',
        data: {
          'bookingId': bookingId,
          'workerName': workerName,
          'serviceType': serviceType,
        },
      );

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  // Update booking status
  static Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? notes,
    double? finalPrice,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['workerNotes'] = notes;
      }

      if (finalPrice != null) {
        updates['finalPrice'] = finalPrice;
      }

      switch (status) {
        case BookingStatus.accepted:
          updates['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.completed:
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Get booking details for notifications
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (bookingDoc.exists) {
        Map<String, dynamic> bookingData =
            bookingDoc.data() as Map<String, dynamic>;

        // Send appropriate notifications
        await _sendStatusUpdateNotifications(bookingData, status);
      }
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCustomerRating) {
        updates['customerRating'] = rating;
        updates['customerReview'] = review;
      } else {
        updates['workerRating'] = rating;
        updates['workerReview'] = review;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Update worker's overall rating if customer rated
      if (isCustomerRating) {
        await _updateWorkerRating(bookingId, rating);
      }
    } catch (e) {
      throw Exception('Failed to add rating: ${e.toString()}');
    }
  }

  // Get bookings for customer
  static Future<List<BookingModel>> getCustomerBookings(
      String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customer bookings: ${e.toString()}');
    }
  }

  // Get bookings for worker
  static Future<List<BookingModel>> getWorkerBookings(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch worker bookings: ${e.toString()}');
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
      throw Exception('Failed to fetch booking: ${e.toString()}');
    }
  }

  // Cancel booking
  static Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    required bool isCancelledByCustomer,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'status': BookingStatus.cancelled.toString().split('.').last,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Get booking details
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (bookingDoc.exists) {
        Map<String, dynamic> bookingData =
            bookingDoc.data() as Map<String, dynamic>;

        // Send cancellation notifications
        String notificationTitle = 'Booking Cancelled';
        String customerMessage =
            'Your booking has been cancelled. Reason: $reason';
        String workerMessage =
            'A booking has been cancelled by the customer. Reason: $reason';

        if (isCancelledByCustomer) {
          // Notify worker
          await _createNotification(
            userId: bookingData['workerId'],
            type: 'booking_cancelled',
            title: notificationTitle,
            message: workerMessage,
            data: {
              'bookingId': bookingId,
              'reason': reason,
            },
          );
        } else {
          // Notify customer
          await _createNotification(
            userId: bookingData['customerId'],
            type: 'booking_cancelled',
            title: notificationTitle,
            message: customerMessage,
            data: {
              'bookingId': bookingId,
              'reason': reason,
            },
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  // Private helper methods
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to create notification: $e');
    }
  }

  static Future<void> _sendStatusUpdateNotifications(
    Map<String, dynamic> bookingData,
    BookingStatus status,
  ) async {
    String customerId = bookingData['customerId'];
    String workerId = bookingData['workerId'];
    String serviceType = bookingData['serviceType'];
    String workerName = bookingData['workerName'];
    String customerName = bookingData['customerName'];

    switch (status) {
      case BookingStatus.accepted:
        await _createNotification(
          userId: customerId,
          type: 'booking_accepted',
          title: 'Booking Accepted',
          message:
              '$workerName has accepted your $serviceType service request.',
          data: {'bookingId': bookingData['bookingId']},
        );
        break;
      case BookingStatus.inProgress:
        await _createNotification(
          userId: customerId,
          type: 'booking_started',
          title: 'Service Started',
          message:
              '$workerName has started working on your $serviceType service.',
          data: {'bookingId': bookingData['bookingId']},
        );
        break;
      case BookingStatus.completed:
        await _createNotification(
          userId: customerId,
          type: 'booking_completed',
          title: 'Service Completed',
          message:
              'Your $serviceType service has been completed. Please rate your experience.',
          data: {'bookingId': bookingData['bookingId']},
        );
        await _createNotification(
          userId: workerId,
          type: 'booking_completed',
          title: 'Service Completed',
          message:
              'You have completed the $serviceType service for $customerName.',
          data: {'bookingId': bookingData['bookingId']},
        );
        break;
      default:
        break;
    }
  }

  static Future<void> _updateWorkerRating(
      String bookingId, double newRating) async {
    try {
      // Get booking details
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) return;

      Map<String, dynamic> bookingData =
          bookingDoc.data() as Map<String, dynamic>;
      String workerId = bookingData['workerId'];

      // Get worker's current ratings
      DocumentSnapshot workerDoc =
          await _firestore.collection('workers').doc(workerId).get();

      if (!workerDoc.exists) return;

      Map<String, dynamic> workerData =
          workerDoc.data() as Map<String, dynamic>;
      double currentRating = (workerData['rating'] ?? 0.0).toDouble();
      int totalRatings = workerData['totalRatings'] ?? 0;

      // Calculate new average rating
      double newAverageRating;
      if (totalRatings == 0) {
        newAverageRating = newRating;
      } else {
        newAverageRating =
            ((currentRating * totalRatings) + newRating) / (totalRatings + 1);
      }

      // Update worker's rating
      await _firestore.collection('workers').doc(workerId).update({
        'rating': newAverageRating,
        'totalRatings': totalRatings + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update worker rating: $e');
    }
  }
}
