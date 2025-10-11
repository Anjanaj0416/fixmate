// lib/models/quote_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final String customerEmail;
  final String customerPhone;
  final String workerId;
  final String workerName;
  final String workerEmail;
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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final double? finalPrice; // Worker's quoted price
  final String? workerNote; // Worker's note when accepting

  QuoteModel({
    required this.quoteId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.workerId,
    required this.workerName,
    required this.workerEmail,
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
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.declinedAt,
    this.finalPrice,
    this.workerNote,
  });

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return QuoteModel(
      quoteId: data['quote_id'] ?? doc.id,
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      customerEmail: data['customer_email'] ?? '',
      customerPhone: data['customer_phone'] ?? '',
      workerId: data['worker_id'] ?? '',
      workerName: data['worker_name'] ?? '',
      workerEmail: data['worker_email'] ?? '',
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
        (e) => e.toString() == 'QuoteStatus.${data['status'] ?? 'pending'}',
        orElse: () => QuoteStatus.pending,
      ),
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
      finalPrice: data['final_price']?.toDouble(),
      workerNote: data['worker_note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quote_id': quoteId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'worker_id': workerId,
      'worker_name': workerName,
      'worker_email': workerEmail,
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
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'accepted_at':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'declined_at':
          declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
      'final_price': finalPrice,
      'worker_note': workerNote,
    };
  }

  QuoteModel copyWith({
    String? quoteId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? workerId,
    String? workerName,
    String? workerEmail,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    double? finalPrice,
    String? workerNote,
  }) {
    return QuoteModel(
      quoteId: quoteId ?? this.quoteId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerEmail: workerEmail ?? this.workerEmail,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      finalPrice: finalPrice ?? this.finalPrice,
      workerNote: workerNote ?? this.workerNote,
    );
  }

  String getStatusText() {
    switch (status) {
      case QuoteStatus.pending:
        return 'Pending';
      case QuoteStatus.accepted:
        return 'Accepted';
      case QuoteStatus.declined:
        return 'Declined';
      case QuoteStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case QuoteStatus.pending:
        return Color(0xFFFF9800); // Orange
      case QuoteStatus.accepted:
        return Color(0xFF4CAF50); // Green
      case QuoteStatus.declined:
        return Color(0xFFF44336); // Red
      case QuoteStatus.cancelled:
        return Color(0xFF9E9E9E); // Grey
      default:
        return Color(0xFF9E9E9E);
    }
  }
}
