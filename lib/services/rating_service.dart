// lib/services/rating_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a rating and review for a completed booking
  static Future<void> submitRating({
    required String bookingId,
    required String workerId,
    required String workerName,
    required String customerId,
    required String customerName,
    required double rating,
    required String review,
    required String serviceType,
    List<String> tags = const [],
  }) async {
    try {
      // Validate booking is completed
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      Map<String, dynamic> bookingData =
          bookingDoc.data() as Map<String, dynamic>;

      if (bookingData['status'] != 'completed') {
        throw Exception('Can only rate completed bookings');
      }

      // Check if already rated
      if (bookingData['customer_rating'] != null) {
        throw Exception('This booking has already been rated');
      }

      // Create review document
      ReviewModel reviewModel = ReviewModel(
        reviewId: '', // Will be auto-generated
        bookingId: bookingId,
        workerId: workerId,
        workerName: workerName,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        review: review,
        createdAt: DateTime.now(),
        serviceType: serviceType,
        tags: tags,
      );

      // Add review to reviews collection
      await _firestore.collection('reviews').add(reviewModel.toFirestore());

      // Update booking with rating
      await _firestore.collection('bookings').doc(bookingId).update({
        'customer_rating': rating,
        'customer_review': review,
        'rated_at': FieldValue.serverTimestamp(),
      });

      // Update worker's average rating
      await _updateWorkerRating(workerId);

      print('✅ Rating submitted successfully for booking: $bookingId');
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Update worker's average rating and total ratings count
  static Future<void> _updateWorkerRating(String workerId) async {
    try {
      // Get all reviews for this worker
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      int count = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0.0).toDouble();
      }

      double averageRating = totalRating / count;

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
          'total_ratings': count,
        });

        print('✅ Worker rating updated: $averageRating ($count ratings)');
      }
    } catch (e) {
      print('Failed to update worker rating: $e');
    }
  }

  /// Get all reviews for a worker
  static Future<List<ReviewModel>> getWorkerReviews(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Get worker's rating statistics
  static Future<Map<String, dynamic>> getWorkerRatingStats(
      String workerId) async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
          'rating_breakdown': {
            5: 0,
            4: 0,
            3: 0,
            2: 0,
            1: 0,
          },
        };
      }

      // Calculate statistics
      double totalRating = 0;
      Map<int, int> ratingBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var doc in reviewsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double rating = (data['rating'] ?? 0.0).toDouble();
        totalRating += rating;

        int ratingInt = rating.round();
        ratingBreakdown[ratingInt] = (ratingBreakdown[ratingInt] ?? 0) + 1;
      }

      double averageRating = totalRating / reviewsSnapshot.docs.length;

      return {
        'average_rating': averageRating,
        'total_reviews': reviewsSnapshot.docs.length,
        'rating_breakdown': ratingBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to fetch rating stats: $e');
    }
  }

  /// Check if a booking has been rated by the customer
  static Future<bool> isBookingRated(String bookingId) async {
    try {
      DocumentSnapshot bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) return false;

      Map<String, dynamic> data = bookingDoc.data() as Map<String, dynamic>;
      return data['customer_rating'] != null;
    } catch (e) {
      return false;
    }
  }
}
