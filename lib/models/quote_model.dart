// lib/models/quote_model.dart
// NEW FILE - Quote Model for Quote & Invoice System

import 'package:cloud_firestore/cloud_firestore.dart';

enum QuoteStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

class QuoteModel {
  final String quoteId;
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
  final QuoteStatus status;
  final double? finalPrice;
  final String? workerNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? cancelledAt;
  final String? bookingId;

  QuoteModel({
    required this.quoteId,
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
    this.workerNote,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.declinedAt,
    this.cancelledAt,
    this.bookingId,
  });

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return QuoteModel(
      quoteId: data['quote_id'] ?? doc.id,
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
      status: QuoteStatus.values.firstWhere(
        (e) => e.toString() == 'QuoteStatus.${data['status']}',
        orElse: () => QuoteStatus.pending,
      ),
      finalPrice: data['final_price']?.toDouble(),
      workerNote: data['worker_note'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      acceptedAt: data['accepted_at'] != null
          ? (data['accepted_at'] as Timestamp).toDate()
          : null,
      declinedAt: data['declined_at'] != null
          ? (data['declined_at'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelled_at'] != null
          ? (data['cancelled_at'] as Timestamp).toDate()
          : null,
      bookingId: data['booking_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quote_id': quoteId,
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
      'status': status.toString().split('.').last,
      'final_price': finalPrice,
      'worker_note': workerNote,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'accepted_at':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'declined_at':
          declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
      'cancelled_at':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'booking_id': bookingId,
    };
  }

  QuoteModel copyWith({
    String? quoteId,
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
    QuoteStatus? status,
    double? finalPrice,
    String? workerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? cancelledAt,
    String? bookingId,
  }) {
    return QuoteModel(
      quoteId: quoteId ?? this.quoteId,
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
      workerNote: workerNote ?? this.workerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}
