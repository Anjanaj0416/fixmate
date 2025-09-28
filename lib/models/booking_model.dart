// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String workerId;
  final String workerName;
  final String workerPhone;
  final String serviceType;
  final String subService;
  final String issueType;
  final String problemDescription;
  final List<String> problemImageUrls;
  final String location;
  final String address;
  final String urgency;
  final String budgetRange;
  final DateTime scheduledDate;
  final String scheduledTime;
  final BookingStatus status;
  final double? finalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? customerNotes;
  final String? workerNotes;
  final double? customerRating;
  final double? workerRating;
  final String? customerReview;
  final String? workerReview;

  BookingModel({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.serviceType,
    required this.subService,
    required this.issueType,
    required this.problemDescription,
    this.problemImageUrls = const [],
    required this.location,
    required this.address,
    required this.urgency,
    required this.budgetRange,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.finalPrice,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.customerNotes,
    this.workerNotes,
    this.customerRating,
    this.workerRating,
    this.customerReview,
    this.workerReview,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      bookingId: data['booking_id'] ?? doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      customerPhone: data['customer_phone'] ?? '',
      customerEmail: data['customer_email'] ?? '',
      workerId: data['worker_id'] ?? '',
      workerName: data['worker_name'] ?? '',
      workerPhone: data['worker_phone'] ?? '',
      serviceType: data['service_type'] ?? '',
      subService: data['sub_service'] ?? '',
      issueType: data['issue_type'] ?? '',
      problemDescription: data['problem_description'] ?? '',
      problemImageUrls: List<String>.from(data['problem_image_urls'] ?? []),
      location: data['location'] ?? '',
      address: data['address'] ?? '',
      urgency: data['urgency'] ?? 'normal',
      budgetRange: data['budget_range'] ?? '',
      scheduledDate: (data['scheduled_date'] as Timestamp).toDate(),
      scheduledTime: data['scheduled_time'] ?? '',
      status: BookingStatus.fromString(data['status'] ?? 'requested'),
      finalPrice: data['final_price']?.toDouble(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      acceptedAt: data['accepted_at'] != null
          ? (data['accepted_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelled_at'] != null
          ? (data['cancelled_at'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellation_reason'],
      customerNotes: data['customer_notes'],
      workerNotes: data['worker_notes'],
      customerRating: data['customer_rating']?.toDouble(),
      workerRating: data['worker_rating']?.toDouble(),
      customerReview: data['customer_review'],
      workerReview: data['worker_review'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'worker_id': workerId,
      'worker_name': workerName,
      'worker_phone': workerPhone,
      'service_type': serviceType,
      'sub_service': subService,
      'issue_type': issueType,
      'problem_description': problemDescription,
      'problem_image_urls': problemImageUrls,
      'location': location,
      'address': address,
      'urgency': urgency,
      'budget_range': budgetRange,
      'scheduled_date': Timestamp.fromDate(scheduledDate),
      'scheduled_time': scheduledTime,
      'status': status.toString(),
      'final_price': finalPrice,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'accepted_at':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelled_at':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellation_reason': cancellationReason,
      'customer_notes': customerNotes,
      'worker_notes': workerNotes,
      'customer_rating': customerRating,
      'worker_rating': workerRating,
      'customer_review': customerReview,
      'worker_review': workerReview,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? workerId,
    String? workerName,
    String? workerPhone,
    String? serviceType,
    String? subService,
    String? issueType,
    String? problemDescription,
    List<String>? problemImageUrls,
    String? location,
    String? address,
    String? urgency,
    String? budgetRange,
    DateTime? scheduledDate,
    String? scheduledTime,
    BookingStatus? status,
    double? finalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? customerNotes,
    String? workerNotes,
    double? customerRating,
    double? workerRating,
    String? customerReview,
    String? workerReview,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      serviceType: serviceType ?? this.serviceType,
      subService: subService ?? this.subService,
      issueType: issueType ?? this.issueType,
      problemDescription: problemDescription ?? this.problemDescription,
      problemImageUrls: problemImageUrls ?? this.problemImageUrls,
      location: location ?? this.location,
      address: address ?? this.address,
      urgency: urgency ?? this.urgency,
      budgetRange: budgetRange ?? this.budgetRange,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      finalPrice: finalPrice ?? this.finalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      customerNotes: customerNotes ?? this.customerNotes,
      workerNotes: workerNotes ?? this.workerNotes,
      customerRating: customerRating ?? this.customerRating,
      workerRating: workerRating ?? this.workerRating,
      customerReview: customerReview ?? this.customerReview,
      workerReview: workerReview ?? this.workerReview,
    );
  }
}

enum BookingStatus {
  requested,
  accepted,
  inProgress,
  completed,
  cancelled,
  declined,
  pending;

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return BookingStatus.requested;
      case 'accepted':
        return BookingStatus.accepted;
      case 'in_progress':
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'declined':
        return BookingStatus.declined;
      case 'pending':
        return BookingStatus.pending;
      default:
        return BookingStatus.requested;
    }
  }

  @override
  String toString() {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.declined:
        return 'declined';
      case BookingStatus.pending:
        return 'pending';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.pending:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.declined:
        return Colors.red;
      case BookingStatus.pending:
        return Colors.grey;
    }
  }
}
