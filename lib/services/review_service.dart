// lib/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../models/booking_model.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a review for a completed booking
  static Future<String> submitReview({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
    required double rating,
    required String review,
    required String serviceType,
  }) async {
    try {
      // Validate booking is completed
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      BookingModel booking = BookingModel.fromFirestore(bookingDoc);

      if (booking.status != BookingStatus.completed) {
        throw Exception('Can only review completed bookings');
      }

      // Check if review already exists
      QuerySnapshot existingReviews = await _firestore
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existingReviews.docs.isNotEmpty) {
        throw Exception('You have already reviewed this booking');
      }

      // Create review document
      String reviewId = _firestore.collection('reviews').doc().id;

      ReviewModel reviewModel = ReviewModel(
        reviewId: reviewId,
        bookingId: bookingId,
        customerId: customerId,
        customerName: customerName,
        workerId: workerId,
        workerName: workerName,
        rating: rating,
        review: review,
        serviceType: serviceType,
        createdAt: DateTime.now(),
        isVerified: true,
      );

      // Save review
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .set(reviewModel.toFirestore());

      // Update booking with rating
      await _firestore.collection('bookings').doc(bookingId).update({
        'customer_rating': rating,
        'customer_review': review,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update worker's overall rating
      await _updateWorkerRating(workerId);

      print('✅ Review submitted successfully: $reviewId');
      return reviewId;
    } catch (e) {
      print('❌ Error submitting review: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Update worker's average rating based on all reviews
  static Future<void> _updateWorkerRating(String workerId) async {
    try {
      // Get all reviews for this worker
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .get();

      if (reviews.docs.isEmpty) {
        return;
      }

      // Calculate average rating and distribution
      double totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in reviews.docs) {
        double rating = (doc.data() as Map<String, dynamic>)['rating'];
        totalRating += rating;
        distribution[rating.round()] = (distribution[rating.round()] ?? 0) + 1;
      }

      double averageRating = totalRating / reviews.docs.length;
      int totalReviews = reviews.docs.length;

      // Update worker document
      QuerySnapshot workerQuery = await _firestore
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
          'total_reviews': totalReviews,
          'rating_distribution': distribution,
          'updated_at': FieldValue.serverTimestamp(),
        });

        print(
            '✅ Worker rating updated: $averageRating ($totalReviews reviews)');
      }
    } catch (e) {
      print('❌ Error updating worker rating: $e');
    }
  }

  /// Get all reviews for a worker
  static Stream<List<ReviewModel>> getWorkerReviewsStream(String workerId) {
    return _firestore
        .collection('reviews')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  /// Get reviews for a worker with pagination
  static Future<List<ReviewModel>> getWorkerReviews(
    String workerId, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting worker reviews: $e');
      throw Exception('Failed to get reviews: $e');
    }
  }

  /// Get rating statistics for a worker
  static Future<RatingStats> getWorkerRatingStats(String workerId) async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .get();

      if (reviews.docs.isEmpty) {
        return RatingStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          fiveStarCount: 0,
          fourStarCount: 0,
          threeStarCount: 0,
          twoStarCount: 0,
          oneStarCount: 0,
        );
      }

      double totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in reviews.docs) {
        double rating = (doc.data() as Map<String, dynamic>)['rating'];
        totalRating += rating;
        int starRating = rating.round();
        distribution[starRating] = (distribution[starRating] ?? 0) + 1;
      }

      double averageRating = totalRating / reviews.docs.length;

      return RatingStats(
        averageRating: averageRating,
        totalReviews: reviews.docs.length,
        ratingDistribution: distribution,
        fiveStarCount: distribution[5] ?? 0,
        fourStarCount: distribution[4] ?? 0,
        threeStarCount: distribution[3] ?? 0,
        twoStarCount: distribution[2] ?? 0,
        oneStarCount: distribution[1] ?? 0,
      );
    } catch (e) {
      print('❌ Error getting rating stats: $e');
      throw Exception('Failed to get rating statistics: $e');
    }
  }

  /// Check if customer has reviewed a booking
  static Future<bool> hasReviewedBooking(String bookingId) async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      return reviews.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking review status: $e');
      return false;
    }
  }

  /// Get customer's review for a booking
  static Future<ReviewModel?> getBookingReview(String bookingId) async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (reviews.docs.isEmpty) {
        return null;
      }

      return ReviewModel.fromFirestore(reviews.docs.first);
    } catch (e) {
      print('❌ Error getting booking review: $e');
      return null;
    }
  }

  /// Worker responds to a review
  static Future<void> respondToReview({
    required String reviewId,
    required String response,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'response': response,
        'response_date': FieldValue.serverTimestamp(),
      });

      print('✅ Response added to review: $reviewId');
    } catch (e) {
      print('❌ Error responding to review: $e');
      throw Exception('Failed to respond to review: $e');
    }
  }

  /// Get reviews by customer
  static Stream<List<ReviewModel>> getCustomerReviewsStream(String customerId) {
    return _firestore
        .collection('reviews')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }
}
