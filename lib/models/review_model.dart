// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String workerId;
  final String workerName;
  final double rating;
  final String review;
  final String serviceType;
  final DateTime createdAt;
  final bool isVerified; // True if from completed booking
  final String? response; // Worker's response to review
  final DateTime? responseDate;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.workerName,
    required this.rating,
    required this.review,
    required this.serviceType,
    required this.createdAt,
    this.isVerified = true,
    this.response,
    this.responseDate,
  });

  // Create from Firestore document
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReviewModel(
      reviewId: doc.id,
      bookingId: data['booking_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      workerId: data['worker_id'] ?? '',
      workerName: data['worker_name'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: data['review'] ?? '',
      serviceType: data['service_type'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isVerified: data['is_verified'] ?? true,
      response: data['response'],
      responseDate: data['response_date'] != null
          ? (data['response_date'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'worker_id': workerId,
      'worker_name': workerName,
      'rating': rating,
      'review': review,
      'service_type': serviceType,
      'created_at': Timestamp.fromDate(createdAt),
      'is_verified': isVerified,
      'response': response,
      'response_date':
          responseDate != null ? Timestamp.fromDate(responseDate!) : null,
    };
  }

  // Create a copy with updated fields
  ReviewModel copyWith({
    String? reviewId,
    String? bookingId,
    String? customerId,
    String? customerName,
    String? workerId,
    String? workerName,
    double? rating,
    String? review,
    String? serviceType,
    DateTime? createdAt,
    bool? isVerified,
    String? response,
    DateTime? responseDate,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      serviceType: serviceType ?? this.serviceType,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      response: response ?? this.response,
      responseDate: responseDate ?? this.responseDate,
    );
  }

  // Get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Rating statistics model
class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  // Calculate percentage for each star rating
  double getStarPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[stars] ?? 0) / totalReviews * 100;
  }

  // Get rating count for specific stars
  int getStarCount(int stars) {
    return ratingDistribution[stars] ?? 0;
  }
}
