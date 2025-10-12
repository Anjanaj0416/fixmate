// lib/services/quote_service.dart
// FIXED VERSION - No Firestore indexes required!
// Queries fetch data and sort in memory

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class QuoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CREATE QUOTE ====================

  /// Create a new quote request from customer to worker
  static Future<String> createQuote({
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
      print('\n========== CREATE QUOTE ==========');
      print('Customer: $customerName ($customerId)');
      print('Worker: $workerName ($workerId)');
      print('Service: $serviceType');

      // Create quote document
      DocumentReference quoteRef = _firestore.collection('quotes').doc();
      String quoteId = quoteRef.id;

      QuoteModel quote = QuoteModel(
        quoteId: quoteId,
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
        status: QuoteStatus.pending,
        createdAt: DateTime.now(),
      );

      await quoteRef.set(quote.toFirestore());

      print('Generated quote ID: $quoteId');
      print('✅ Quote created successfully!');
      print('   Quote ID: $quoteId');
      print('   Status: ${quote.status.toString().split('.').last}');

      // Notify worker
      await _notifyWorkerNewQuote(workerId, quoteId, customerName, serviceType);
      print('✅ Worker notification sent: New quote request');

      print('========== CREATE QUOTE END ==========\n');
      return quoteId;
    } catch (e) {
      print('❌ Error creating quote: $e');
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  // ==================== WORKER ACTIONS ====================

  /// Worker accepts the quote and provides final price + note
  static Future<void> acceptQuote({
    required String quoteId,
    required double finalPrice,
    required String workerNote,
  }) async {
    try {
      print('\n========== ACCEPT QUOTE ==========');
      print('Quote ID: $quoteId');
      print('Final Price: LKR $finalPrice');

      await _firestore.collection('quotes').doc(quoteId).update({
        'status': QuoteStatus.accepted.toString().split('.').last,
        'final_price': finalPrice,
        'worker_note': workerNote,
        'accepted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get quote data for notification
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Notify customer
      await _notifyCustomerQuoteAccepted(
        quoteData['customer_id'],
        quoteId,
        quoteData['worker_name'],
        finalPrice,
      );

      print('✅ Quote accepted and invoice created');
      print('========== ACCEPT QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error accepting quote: $e');
      throw Exception('Failed to accept quote: ${e.toString()}');
    }
  }

  /// Worker declines the quote
  static Future<void> declineQuote({required String quoteId}) async {
    try {
      print('\n========== DECLINE QUOTE ==========');
      print('Quote ID: $quoteId');

      // Get quote data before declining
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      await _firestore.collection('quotes').doc(quoteId).update({
        'status': QuoteStatus.declined.toString().split('.').last,
        'declined_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify customer
      await _notifyCustomerQuoteDeclined(
        quoteData['customer_id'],
        quoteId,
        quoteData['worker_name'],
      );

      print('✅ Quote declined');
      print('========== DECLINE QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error declining quote: $e');
      throw Exception('Failed to decline quote: ${e.toString()}');
    }
  }

  // ==================== CUSTOMER ACTIONS ====================

  /// Customer cancels the quote (invoice)
  static Future<void> cancelQuote({required String quoteId}) async {
    try {
      print('\n========== CANCEL QUOTE ==========');
      print('Quote ID: $quoteId');

      // Get quote data before cancelling
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      await _firestore.collection('quotes').doc(quoteId).update({
        'status': QuoteStatus.cancelled.toString().split('.').last,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify worker
      await _notifyWorkerInvoiceCancelled(
        quoteData['worker_id'],
        quoteId,
        quoteData['customer_name'],
      );

      print('✅ Quote cancelled');
      print('========== CANCEL QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error cancelling quote: $e');
      throw Exception('Failed to cancel quote: ${e.toString()}');
    }
  }

  /// Alias for cancelQuote - used by customer to cancel invoices
  static Future<void> cancelInvoice({required String quoteId}) async {
    return cancelQuote(quoteId: quoteId);
  }

  /// Customer deletes a pending quote
  static Future<void> deleteQuote({required String quoteId}) async {
    try {
      print('\n========== DELETE QUOTE ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;
      String workerId = quoteData['worker_id'];

      // Delete the quote
      await _firestore.collection('quotes').doc(quoteId).delete();

      print('✅ Quote deleted successfully');

      // Optionally notify worker
      // await _notifyWorkerQuoteDeleted(workerId, quoteId);

      print('========== DELETE QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error deleting quote: $e');
      throw Exception('Failed to delete quote: ${e.toString()}');
    }
  }

  /// Customer accepts the invoice and creates booking
// lib/services/quote_service.dart
// MODIFIED VERSION - Only the acceptInvoice method is modified
// Replace only the acceptInvoice method in your existing file

  /// Customer accepts the invoice and creates booking
  /// MODIFIED: Creates booking with status "accepted" instead of "requested"
  static Future<String> acceptInvoice({required String quoteId}) async {
    try {
      print('\n========== ACCEPT INVOICE ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      QuoteModel quote = QuoteModel.fromFirestore(quoteDoc);

      if (quote.status != QuoteStatus.accepted) {
        throw Exception('Quote must be accepted by worker first');
      }

      // Create booking from accepted quote
      String bookingId = _firestore.collection('bookings').doc().id;

      // MODIFIED: Create booking with status "accepted" instead of "requested"
      BookingModel booking = BookingModel(
        bookingId: bookingId,
        customerId: quote.customerId,
        customerName: quote.customerName,
        customerPhone: quote.customerPhone,
        customerEmail: quote.customerEmail,
        workerId: quote.workerId,
        workerName: quote.workerName,
        workerPhone: quote.workerPhone,
        serviceType: quote.serviceType,
        subService: quote.subService,
        issueType: quote.issueType,
        problemDescription: quote.problemDescription,
        problemImageUrls: quote.problemImageUrls,
        location: quote.location,
        address: quote.address,
        urgency: quote.urgency,
        budgetRange: quote.budgetRange,
        scheduledDate: quote.scheduledDate,
        scheduledTime: quote.scheduledTime,
        status: BookingStatus
            .accepted, // MODIFIED: Changed from requested to accepted
        finalPrice: quote.finalPrice,
        workerNotes: quote.workerNote,
        createdAt: DateTime.now(),
      );

      // Save booking
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .set(booking.toFirestore());

      // Update quote status to show it's been converted to booking
      await _firestore.collection('quotes').doc(quoteId).update({
        'booking_id': bookingId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify worker
      await _notifyWorkerInvoiceAccepted(
        quote.workerId,
        quoteId,
        bookingId,
        quote.customerName,
      );

      print('✅ Invoice accepted and booking created with accepted status');
      print('   Booking ID: $bookingId');
      print('========== ACCEPT INVOICE END ==========\n');

      return bookingId;
    } catch (e) {
      print('❌ Error accepting invoice: $e');
      throw Exception('Failed to accept invoice: ${e.toString()}');
    }
  }
  // ==================== NOTIFICATIONS ====================

  static Future<void> _notifyWorkerNewQuote(
    String workerId,
    String quoteId,
    String customerName,
    String serviceType,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'recipient_id': workerId,
        'type': 'new_quote',
        'title': 'New Quote Request 📋',
        'message':
            '$customerName requested a quote for ${serviceType.replaceAll('_', ' ')}',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  static Future<void> _notifyCustomerQuoteAccepted(
    String customerId,
    String quoteId,
    String workerName,
    double finalPrice,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'customer',
        'recipient_id': customerId,
        'type': 'quote_accepted',
        'title': 'Quote Accepted ✅',
        'message':
            '$workerName accepted your quote! Final price: LKR $finalPrice',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('⚠️  Failed to send customer notification: $e');
    }
  }

  static Future<void> _notifyCustomerQuoteDeclined(
    String customerId,
    String quoteId,
    String workerName,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'customer',
        'recipient_id': customerId,
        'type': 'quote_declined',
        'title': 'Quote Declined ❌',
        'message': '$workerName has declined your quote request',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('⚠️  Failed to send customer notification: $e');
    }
  }

  static Future<void> _notifyWorkerInvoiceAccepted(
    String workerId,
    String quoteId,
    String bookingId,
    String customerName,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'recipient_id': workerId,
        'type': 'invoice_accepted',
        'title': 'Invoice Accepted ✓',
        'message': '$customerName accepted your invoice — booking started',
        'quote_id': quoteId,
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  static Future<void> _notifyWorkerInvoiceCancelled(
    String workerId,
    String quoteId,
    String customerName,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'recipient_id': workerId,
        'type': 'invoice_cancelled',
        'title': 'Invoice Cancelled ❌',
        'message': '$customerName has cancelled the invoice',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  // ==================== FETCH QUOTES (FIXED - NO INDEX REQUIRED!) ====================

  /// ✅ FIXED: Get all quotes for a customer - NO INDEX REQUIRED!
  /// Fetches data without orderBy and sorts in memory
  static Stream<List<QuoteModel>> getCustomerQuotes(String customerId) {
    return _firestore
        .collection('quotes')
        .where('customer_id', isEqualTo: customerId)
        // ✅ REMOVED: .orderBy('created_at', descending: true) - This caused index error!
        .snapshots()
        .map((snapshot) {
      List<QuoteModel> quotes =
          snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();

      // ✅ SORT IN MEMORY instead of using Firestore orderBy
      quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return quotes;
    });
  }

  /// ✅ FIXED: Get all quotes for a worker - NO INDEX REQUIRED!
  /// Fetches data without orderBy and sorts in memory
  static Stream<List<QuoteModel>> getWorkerQuotes(String workerId) {
    return _firestore
        .collection('quotes')
        .where('worker_id', isEqualTo: workerId)
        // ✅ REMOVED: .orderBy('created_at', descending: true) - This caused index error!
        .snapshots()
        .map((snapshot) {
      List<QuoteModel> quotes =
          snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();

      // ✅ SORT IN MEMORY instead of using Firestore orderBy
      quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return quotes;
    });
  }

  /// Get specific quote by ID
  static Future<QuoteModel> getQuoteById(String quoteId) async {
    DocumentSnapshot doc =
        await _firestore.collection('quotes').doc(quoteId).get();

    if (!doc.exists) {
      throw Exception('Quote not found');
    }

    return QuoteModel.fromFirestore(doc);
  }
}
