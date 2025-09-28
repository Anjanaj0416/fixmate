// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? bookingId;
  final String customerId;
  final String workerId;
  final String serviceType;
  final String? subService;
  final String problemDescription;
  final List<String> problemImageUrls;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final double price;
  final String? quoteId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;
  final Map<String, dynamic>? customerDetails;
  final Map<String, dynamic>? workerDetails;
  final String? paymentStatus; // pending, paid, refunded
  final String? notes;

  BookingModel({
    this.bookingId,
    required this.customerId,
    required this.workerId,
    required this.serviceType,
    this.subService,
    required this.problemDescription,
    this.problemImageUrls = const [],
    required this.scheduledDate,
    required this.scheduledTime,
    this.status = 'pending',
    required this.price,
    this.quoteId,
    this.createdAt,
    this.updatedAt,
    this.cancellationReason,
    this.customerDetails,
    this.workerDetails,
    this.paymentStatus = 'pending',
    this.notes,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: doc.id,
      customerId: data['customer_id'] ?? '',
      workerId: data['worker_id'] ?? '',
      serviceType: data['service_type'] ?? '',
      subService: data['sub_service'],
      problemDescription: data['problem_description'] ?? '',
      problemImageUrls: List<String>.from(data['problem_image_urls'] ?? []),
      scheduledDate:
          (data['scheduled_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledTime: data['scheduled_time'] ?? '',
      status: data['status'] ?? 'pending',
      price: (data['price'] ?? 0.0).toDouble(),
      quoteId: data['quote_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellation_reason'],
      customerDetails: data['customer_details'],
      workerDetails: data['worker_details'],
      paymentStatus: data['payment_status'] ?? 'pending',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'worker_id': workerId,
      'service_type': serviceType,
      'sub_service': subService,
      'problem_description': problemDescription,
      'problem_image_urls': problemImageUrls,
      'scheduled_date': Timestamp.fromDate(scheduledDate),
      'scheduled_time': scheduledTime,
      'status': status,
      'price': price,
      'quote_id': quoteId,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'cancellation_reason': cancellationReason,
      'customer_details': customerDetails,
      'worker_details': workerDetails,
      'payment_status': paymentStatus,
      'notes': notes,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? customerId,
    String? workerId,
    String? serviceType,
    String? subService,
    String? problemDescription,
    List<String>? problemImageUrls,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    double? price,
    String? quoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    Map<String, dynamic>? customerDetails,
    Map<String, dynamic>? workerDetails,
    String? paymentStatus,
    String? notes,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      serviceType: serviceType ?? this.serviceType,
      subService: subService ?? this.subService,
      problemDescription: problemDescription ?? this.problemDescription,
      problemImageUrls: problemImageUrls ?? this.problemImageUrls,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      price: price ?? this.price,
      quoteId: quoteId ?? this.quoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      customerDetails: customerDetails ?? this.customerDetails,
      workerDetails: workerDetails ?? this.workerDetails,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
    );
  }
}

// lib/models/quote_model.dart
class QuoteModel {
  final String? quoteId;
  final String workerId;
  final String customerId;
  final String serviceRequestId;
  final double price;
  final String currency;
  final String description;
  final int estimatedDurationHours;
  final List<String> includedServices;
  final List<String> excludedServices;
  final DateTime validUntil;
  final String status; // pending, accepted, rejected, expired
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? workerDetails;
  final bool emergencyService;
  final String? notes;

  QuoteModel({
    this.quoteId,
    required this.workerId,
    required this.customerId,
    required this.serviceRequestId,
    required this.price,
    this.currency = 'LKR',
    required this.description,
    required this.estimatedDurationHours,
    this.includedServices = const [],
    this.excludedServices = const [],
    required this.validUntil,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.workerDetails,
    this.emergencyService = false,
    this.notes,
  });

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuoteModel(
      quoteId: doc.id,
      workerId: data['worker_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      serviceRequestId: data['service_request_id'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'LKR',
      description: data['description'] ?? '',
      estimatedDurationHours: data['estimated_duration_hours'] ?? 1,
      includedServices: List<String>.from(data['included_services'] ?? []),
      excludedServices: List<String>.from(data['excluded_services'] ?? []),
      validUntil: (data['valid_until'] as Timestamp?)?.toDate() ??
          DateTime.now().add(Duration(days: 7)),
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      workerDetails: data['worker_details'],
      emergencyService: data['emergency_service'] ?? false,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'worker_id': workerId,
      'customer_id': customerId,
      'service_request_id': serviceRequestId,
      'price': price,
      'currency': currency,
      'description': description,
      'estimated_duration_hours': estimatedDurationHours,
      'included_services': includedServices,
      'excluded_services': excludedServices,
      'valid_until': Timestamp.fromDate(validUntil),
      'status': status,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'worker_details': workerDetails,
      'emergency_service': emergencyService,
      'notes': notes,
    };
  }
}

// lib/services/booking_service.dart
class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique booking ID
  static Future<String> generateBookingId() async {
    QuerySnapshot bookingCount = await _firestore.collection('bookings').get();
    int count = bookingCount.docs.length + 1;
    String bookingId = 'B${count.toString().padLeft(4, '0')}';

    while (await _bookingIdExists(bookingId)) {
      count++;
      bookingId = 'B${count.toString().padLeft(4, '0')}';
    }

    return bookingId;
  }

  static Future<bool> _bookingIdExists(String bookingId) async {
    QuerySnapshot existing = await _firestore
        .collection('bookings')
        .where('booking_id', isEqualTo: bookingId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Create booking from accepted quote
  static Future<String> createBookingFromQuote({
    required String quoteId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? notes,
  }) async {
    try {
      // Get quote details
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      QuoteModel quote = QuoteModel.fromFirestore(quoteDoc);

      // Get customer and worker details
      DocumentSnapshot customerDoc =
          await _firestore.collection('customers').doc(quote.customerId).get();
      DocumentSnapshot workerDoc =
          await _firestore.collection('workers').doc(quote.workerId).get();

      Map<String, dynamic>? customerDetails = customerDoc.exists
          ? customerDoc.data() as Map<String, dynamic>
          : null;
      Map<String, dynamic>? workerDetails =
          workerDoc.exists ? workerDoc.data() as Map<String, dynamic> : null;

      // Generate booking ID
      String bookingId = await generateBookingId();

      // Create booking
      BookingModel booking = BookingModel(
        bookingId: bookingId,
        customerId: quote.customerId,
        workerId: quote.workerId,
        serviceType: customerDetails?['service_type'] ?? '',
        problemDescription: quote.description,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        price: quote.price,
        quoteId: quoteId,
        status: 'confirmed',
        customerDetails: customerDetails,
        workerDetails: workerDetails,
        notes: notes,
      );

      // Save booking
      DocumentReference bookingRef =
          await _firestore.collection('bookings').add(booking.toFirestore());
      await bookingRef.update({'booking_id': bookingId});

      // Update quote status
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'accepted',
        'updated_at': FieldValue.serverTimestamp(),
      });

      return bookingRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: ${e.toString()}');
    }
  }

  // Get customer bookings
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

  // Update booking status
  static Future<void> updateBookingStatus(String bookingId, String status,
      {String? reason}) async {
    try {
      Map<String, dynamic> updates = {
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (reason != null && status == 'cancelled') {
        updates['cancellation_reason'] = reason;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }
}
