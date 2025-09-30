// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String workerId;
  final String workerName;
  final String customerId;
  final String customerName;
  final double rating;
  final String review;
  final DateTime createdAt;
  final String serviceType;
  final List<String> tags; // e.g., ['professional', 'punctual', 'quality_work']

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.workerId,
    required this.workerName,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.review,
    required this.createdAt,
    required this.serviceType,
    this.tags = const [],
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      reviewId: doc.id,
      bookingId: data['booking_id'] ?? '',
      workerId: data['worker_id'] ?? '',
      workerName: data['worker_name'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: data['review'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      serviceType: data['service_type'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'worker_id': workerId,
      'worker_name': workerName,
      'customer_id': customerId,
      'customer_name': customerName,
      'rating': rating,
      'review': review,
      'created_at': Timestamp.fromDate(createdAt),
      'service_type': serviceType,
      'tags': tags,
    };
  }
}
