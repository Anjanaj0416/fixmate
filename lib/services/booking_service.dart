// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import 'id_generator_service.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new booking with structured ID: BOOK_0001
  static Future<String> createBooking({
    required String customerId,
    required String workerId,
    required String workerName,
    required String workerPhone,
    required String serviceType,
    required String subService,
    required String issueType,
    required String problemDescription,
    List<String> problemImageUrls = const [],
    required String location,
    required String address,
    required String urgency,
    required String budgetRange,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get customer data
      DocumentSnapshot customerDoc =
          await _firestore.collection('customers').doc(user.uid).get();

      if (!customerDoc.exists) {
        throw Exception('Customer profile not found');
      }

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      // Generate structured booking ID: BOOK_0001
      String bookingId = await IDGeneratorService.generateBookingId();

      // Create booking model
      BookingModel booking = BookingModel(
        bookingId: bookingId,
        customerId: customerData['customer_id'] ?? customerId,
        customerName: customerData['customer_name'] ?? '',
        customerPhone: customerData['phone_number'] ?? '',
        customerEmail: customerData['email'] ?? '',
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

      return bookingId;
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  /// Get bookings for a customer
  static Stream<List<BookingModel>> getCustomerBookings(String customerId) {
    return _firestore
        .collection('bookings')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get bookings for a worker
  static Stream<List<BookingModel>> getWorkerBookings(String workerId) {
    return _firestore
        .collection('bookings')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get a single booking by ID
  static Future<BookingModel?> getBooking(String bookingId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  /// Update booking status
  static Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': newStatus.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add notes if provided
      if (notes != null && notes.isNotEmpty) {
        updateData['status_notes'] = notes;
      }

      // Add timestamp fields based on status
      switch (newStatus) {
        case BookingStatus.accepted:
          updateData['accepted_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.inProgress:
          updateData['started_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.completed:
          updateData['completed_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updateData['cancelled_at'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.declined:
          updateData['declined_at'] = FieldValue.serverTimestamp();
          if (notes != null) {
            updateData['cancellation_reason'] = notes;
          }
          break;
        default:
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Cancel booking
  static Future<void> cancelBooking(
    String bookingId,
    String cancellationReason,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString(),
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancellation_reason': cancellationReason,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Add rating and review
  static Future<void> addCustomerReview({
    required String bookingId,
    required double rating,
    String? review,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'customer_rating': rating,
        'customer_review': review,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding customer review: $e');
      rethrow;
    }
  }

  /// Update final price
  static Future<void> updateFinalPrice(
    String bookingId,
    double finalPrice,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'final_price': finalPrice,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating final price: $e');
      rethrow;
    }
  }
}
