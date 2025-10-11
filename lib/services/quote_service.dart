// lib/services/quote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';

class QuoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new quote
  static Future<String> createQuote({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String workerId,
    required String workerName,
    required String workerEmail,
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
      print('\n========== CREATE QUOTE START ==========');

      // Generate quote ID
      String quoteId = _firestore.collection('quotes').doc().id;
      print('Generated quote ID: $quoteId');

      // Create quote model
      QuoteModel quote = QuoteModel(
        quoteId: quoteId,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        workerId: workerId,
        workerName: workerName,
        workerEmail: workerEmail,
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
      print('   Worker ID: $workerId');
      print('   Status: pending');

      // Send notifications
      await _sendQuoteNotifications(
        quoteId: quoteId,
        customerId: customerId,
        customerName: customerName,
        workerId: workerId,
        workerName: workerName,
        serviceType: serviceType,
      );

      print('========== CREATE QUOTE END ==========\n');
      return quoteId;
    } catch (e) {
      print('❌ Error creating quote: $e');
      print('========== CREATE QUOTE END ==========\n');
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  /// Send notifications when quote is created
  static Future<void> _sendQuoteNotifications({
    required String quoteId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
    required String serviceType,
  }) async {
    try {
      // Notify worker about NEW quote request
      await _firestore.collection('notifications').add({
        'recipient_id': workerId,
        'recipient_type': 'worker',
        'type': 'new_quote',
        'title': 'New Quote Request 📩',
        'message':
            'You have a new quote request from $customerName for $serviceType',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent for quote: $quoteId');
    } catch (e) {
      print('❌ Failed to send quote notifications: $e');
    }
  }

  /// Worker accepts a quote with final price and note
  static Future<void> acceptQuote({
    required String quoteId,
    required double finalPrice,
    required String workerNote,
  }) async {
    try {
      print('\n========== ACCEPT QUOTE START ==========');
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
      await _firestore.collection('notifications').add({
        'recipient_id': quoteData['customer_id'],
        'recipient_type': 'customer',
        'type': 'quote_accepted',
        'title': 'Quote Accepted ✓',
        'message':
            '${quoteData['worker_name']} has accepted your quote with a final price of LKR ${finalPrice.toStringAsFixed(2)}',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Customer notification sent');
      print('========== ACCEPT QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error accepting quote: $e');
      print('========== ACCEPT QUOTE END ==========\n');
      throw Exception('Failed to accept quote: ${e.toString()}');
    }
  }

  /// Worker declines a quote
  static Future<void> declineQuote({
    required String quoteId,
  }) async {
    try {
      print('\n========== DECLINE QUOTE START ==========');
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
      await _firestore.collection('notifications').add({
        'recipient_id': quoteData['customer_id'],
        'recipient_type': 'customer',
        'type': 'quote_declined',
        'title': 'Quote Declined',
        'message':
            '${quoteData['worker_name']} has declined your quote request',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Customer notification sent');
      print('========== DECLINE QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error declining quote: $e');
      print('========== DECLINE QUOTE END ==========\n');
      throw Exception('Failed to decline quote: ${e.toString()}');
    }
  }

  /// Customer deletes/cancels a quote
  static Future<void> deleteQuote({
    required String quoteId,
  }) async {
    try {
      print('\n========== DELETE QUOTE START ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Only allow deletion of pending quotes
      if (quoteData['status'] != 'pending') {
        throw Exception('Can only delete pending quotes');
      }

      // Update quote status to cancelled (don't actually delete)
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Quote cancelled successfully');

      // Send notification to worker
      await _firestore.collection('notifications').add({
        'recipient_id': quoteData['worker_id'],
        'recipient_type': 'worker',
        'type': 'quote_cancelled',
        'title': 'Quote Cancelled',
        'message':
            '${quoteData['customer_name']} has cancelled the quote request',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent');
      print('========== DELETE QUOTE END ==========\n');
    } catch (e) {
      print('❌ Error deleting quote: $e');
      print('========== DELETE QUOTE END ==========\n');
      throw Exception('Failed to delete quote: ${e.toString()}');
    }
  }

  /// Customer accepts the invoice/quote and creates booking
  static Future<String> acceptInvoiceAndCreateBooking({
    required String quoteId,
  }) async {
    try {
      print('\n========== ACCEPT INVOICE & CREATE BOOKING START ==========');
      print('Quote ID: $quoteId');

      // Get quote data
      DocumentSnapshot quoteDoc =
          await _firestore.collection('quotes').doc(quoteId).get();
      if (!quoteDoc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> quoteData = quoteDoc.data() as Map<String, dynamic>;

      // Verify quote is accepted
      if (quoteData['status'] != 'accepted') {
        throw Exception('Quote must be accepted by worker first');
      }

      // Create booking from quote
      String bookingId = _firestore.collection('bookings').doc().id;

      await _firestore.collection('bookings').doc(bookingId).set({
        'booking_id': bookingId,
        'quote_id': quoteId, // Link to original quote
        'customer_id': quoteData['customer_id'],
        'customer_name': quoteData['customer_name'],
        'customer_phone': quoteData['customer_phone'],
        'customer_email': quoteData['customer_email'],
        'worker_id': quoteData['worker_id'],
        'worker_name': quoteData['worker_name'],
        'worker_phone': quoteData['worker_phone'],
        'service_type': quoteData['service_type'],
        'sub_service': quoteData['sub_service'],
        'issue_type': quoteData['issue_type'],
        'problem_description': quoteData['problem_description'],
        'problem_image_urls': quoteData['problem_image_urls'],
        'location': quoteData['location'],
        'address': quoteData['address'],
        'urgency': quoteData['urgency'],
        'budget_range': quoteData['budget_range'],
        'scheduled_date': quoteData['scheduled_date'],
        'scheduled_time': quoteData['scheduled_time'],
        'final_price': quoteData['final_price'],
        'worker_notes': quoteData['worker_note'],
        'status': 'accepted', // Booking starts as accepted
        'created_at': FieldValue.serverTimestamp(),
        'accepted_at': FieldValue.serverTimestamp(),
      });

      print('✅ Booking created: $bookingId');

      // Send notification to worker
      await _firestore.collection('notifications').add({
        'recipient_id': quoteData['worker_id'],
        'recipient_type': 'worker',
        'type': 'invoice_accepted',
        'title': 'Invoice Accepted - Booking Started ✓',
        'message':
            '${quoteData['customer_name']} has accepted your invoice. Booking has started!',
        'booking_id': bookingId,
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent');
      print('========== ACCEPT INVOICE & CREATE BOOKING END ==========\n');

      return bookingId;
    } catch (e) {
      print('❌ Error accepting invoice: $e');
      print('========== ACCEPT INVOICE & CREATE BOOKING END ==========\n');
      throw Exception('Failed to accept invoice: ${e.toString()}');
    }
  }

  /// Customer cancels the invoice
  static Future<void> cancelInvoice({
    required String quoteId,
  }) async {
    try {
      print('\n========== CANCEL INVOICE START ==========');
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
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Invoice cancelled');

      // Send notification to worker
      await _firestore.collection('notifications').add({
        'recipient_id': quoteData['worker_id'],
        'recipient_type': 'worker',
        'type': 'invoice_cancelled',
        'title': 'Invoice Cancelled',
        'message': '${quoteData['customer_name']} has cancelled the invoice',
        'quote_id': quoteId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('✅ Worker notification sent');
      print('========== CANCEL INVOICE END ==========\n');
    } catch (e) {
      print('❌ Error cancelling invoice: $e');
      print('========== CANCEL INVOICE END ==========\n');
      throw Exception('Failed to cancel invoice: ${e.toString()}');
    }
  }

  /// Get quotes for customer
  static Stream<QuerySnapshot> getCustomerQuotes(String customerId) {
    return _firestore
        .collection('quotes')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Get quotes for worker
  static Stream<QuerySnapshot> getWorkerQuotes(String workerId) {
    return _firestore
        .collection('quotes')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
