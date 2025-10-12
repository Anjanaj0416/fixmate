// lib/services/quote_service.dart
// NEW FILE - Quote Service for managing quotes and invoices

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../models/booking_model.dart';

class QuoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CREATE QUOTE ====================

  /// Create a new quote and send to worker
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

      // Generate quote ID
      String quoteId = _firestore.collection('quotes').doc().id;
      print('Generated quote ID: $quoteId');

      // Create quote model
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

      // Save quote to Firestore
      await _firestore
          .collection('quotes')
          .doc(quoteId)
          .set(quote.toFirestore());

      print('✅ Quote created successfully!');
      print('   Quote ID: $quoteId');
      print('   Status: pending');

      // Send notification to worker about new quote
      await _notifyWorkerNewQuote(workerId, quoteId, customerName, serviceType);

      print('========== CREATE QUOTE END ==========\n');

      return quoteId;
    } catch (e) {
      print('❌ Error creating quote: $e');
      print('========== CREATE QUOTE END ==========\n');
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  // ==================== WORKER ACTIONS ====================

  /// Worker accepts the quote and provides final price & note
  static Future<void> acceptQuote({
    required String quoteId,
    required double finalPrice,
    required String workerNote,
  }) async {
    try {
      print('\n========== ACCEPT QUOTE ==========');
      print('Quote ID: $quoteId');
      print('Final Price: $finalPrice');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Update quote status
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'accepted',
        'final_price': finalPrice,
        'worker_note': workerNote,
        'accepted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Quote accepted successfully');

      // Send notification to customer
      await _notifyCustomerQuoteAccepted(
        quoteData['customer_id'],
        quoteId,
        quoteData['worker_name'],
      );

      print('========== ACCEPT QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error accepting quote: $e');
      throw Exception('Failed to accept quote: ${e.toString()}');
    }
  }

  /// Worker declines the quote
  static Future<void> declineQuote({
    required String quoteId,
  }) async {
    try {
      print('\n========== DECLINE QUOTE ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Update quote status
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'declined',
        'declined_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Quote declined successfully');

      // Send notification to customer
      await _notifyCustomerQuoteDeclined(
        quoteData['customer_id'],
        quoteId,
        quoteData['worker_name'],
      );

      print('========== DECLINE QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error declining quote: $e');
      throw Exception('Failed to decline quote: ${e.toString()}');
    }
  }

  // ==================== CUSTOMER ACTIONS ====================

  /// Customer deletes the quote
  static Future<void> deleteQuote({
    required String quoteId,
  }) async {
    try {
      print('\n========== DELETE QUOTE ==========');
      print('Quote ID: $quoteId');

      // Get quote data for worker notification
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
  static Future<String> acceptInvoice({
    required String quoteId,
  }) async {
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
        status: BookingStatus.accepted,
        finalPrice: quote.finalPrice,
        workerNotes: quote.workerNote,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );

      // Save booking to Firestore
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .set(booking.toFirestore());

      // Update quote to mark it as converted to booking
      await _firestore.collection('quotes').doc(quoteId).update({
        'booking_id': bookingId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Invoice accepted and booking created');
      print('   Booking ID: $bookingId');

      // Send notification to worker
      await _notifyWorkerInvoiceAccepted(
        quote.workerId,
        bookingId,
        quote.customerName,
      );

      print('========== ACCEPT INVOICE END ==========\n');

      return bookingId;
    } catch (e) {
      print('❌ Error accepting invoice: $e');
      throw Exception('Failed to accept invoice: ${e.toString()}');
    }
  }

  /// Customer cancels the invoice
  static Future<void> cancelInvoice({
    required String quoteId,
  }) async {
    try {
      print('\n========== CANCEL INVOICE ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Update quote status to cancelled
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Invoice cancelled successfully');

      // Send notification to worker
      await _notifyWorkerInvoiceCancelled(
        quoteData['worker_id'],
        quoteId,
        quoteData['customer_name'],
      );

      print('========== CANCEL INVOICE END ==========\n');
    } catch (e) {
      print('❌ Error cancelling invoice: $e');
      throw Exception('Failed to cancel invoice: ${e.toString()}');
    }
  }

  // ==================== NOTIFICATION METHODS ====================

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
        'title': 'New Quote Request 💼',
        'message':
            'You have a new $serviceType quote request from $customerName',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent: New quote request');
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  static Future<void> _notifyCustomerQuoteAccepted(
    String customerId,
    String quoteId,
    String workerName,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'customer',
        'recipient_id': customerId,
        'type': 'quote_accepted',
        'title': 'Quote Accepted ✓',
        'message': '$workerName has accepted your quote and sent an invoice!',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Customer notification sent: Quote accepted');
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

      print('✅ Customer notification sent: Quote declined');
    } catch (e) {
      print('⚠️  Failed to send customer notification: $e');
    }
  }

  static Future<void> _notifyWorkerInvoiceAccepted(
    String workerId,
    String bookingId,
    String customerName,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipient_type': 'worker',
        'recipient_id': workerId,
        'type': 'invoice_accepted',
        'title': 'Invoice Accepted ✓',
        'message': '$customerName has accepted your invoice - booking started!',
        'booking_id': bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent: Invoice accepted');
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

      print('✅ Worker notification sent: Invoice cancelled');
    } catch (e) {
      print('⚠️  Failed to send worker notification: $e');
    }
  }

  // ==================== FETCH QUOTES ====================

  /// Get all quotes for a customer
  static Stream<List<QuoteModel>> getCustomerQuotes(String customerId) {
    return _firestore
        .collection('quotes')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList());
  }

  /// Get all quotes for a worker
  static Stream<List<QuoteModel>> getWorkerQuotes(String workerId) {
    return _firestore
        .collection('quotes')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList());
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
