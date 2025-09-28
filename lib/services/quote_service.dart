// lib/services/quote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote_model.dart';
import '../models/worker_model.dart';
import '../models/customer_model.dart';
import 'dart:math' as math;

class QuoteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique quote ID
  static Future<String> generateQuoteId() async {
    QuerySnapshot quoteCount = await _firestore.collection('quotes').get();
    int count = quoteCount.docs.length + 1;
    String quoteId = 'Q${count.toString().padLeft(4, '0')}';

    while (await _quoteIdExists(quoteId)) {
      count++;
      quoteId = 'Q${count.toString().padLeft(4, '0')}';
    }

    return quoteId;
  }

  static Future<bool> _quoteIdExists(String quoteId) async {
    QuerySnapshot existing = await _firestore
        .collection('quotes')
        .where('quote_id', isEqualTo: quoteId)
        .get();
    return existing.docs.isNotEmpty;
  }

  // Create a quote for a service request
  static Future<String> createQuote({
    required String serviceRequestId,
    required String customerId,
    required double price,
    required String description,
    required int estimatedDurationHours,
    List<String> includedServices = const [],
    List<String> excludedServices = const [],
    bool emergencyService = false,
    String? notes,
    int validityDays = 7,
  }) async {
    try {
      String? workerId = FirebaseAuth.instance.currentUser?.uid;
      if (workerId == null) {
        throw Exception('Worker not authenticated');
      }

      // Get worker details
      DocumentSnapshot workerDoc =
          await _firestore.collection('workers').doc(workerId).get();
      Map<String, dynamic>? workerDetails =
          workerDoc.exists ? workerDoc.data() as Map<String, dynamic> : null;

      String quoteId = await generateQuoteId();

      QuoteModel quote = QuoteModel(
        quoteId: quoteId,
        workerId: workerId,
        customerId: customerId,
        serviceRequestId: serviceRequestId,
        price: price,
        description: description,
        estimatedDurationHours: estimatedDurationHours,
        includedServices: includedServices,
        excludedServices: excludedServices,
        validUntil: DateTime.now().add(Duration(days: validityDays)),
        workerDetails: workerDetails,
        emergencyService: emergencyService,
        notes: notes,
      );

      DocumentReference quoteRef =
          await _firestore.collection('quotes').add(quote.toFirestore());
      await quoteRef.update({'quote_id': quoteId});

      // Create notification for customer
      await _createQuoteNotification(
          customerId, workerId, quoteId, serviceRequestId);

      return quoteRef.id;
    } catch (e) {
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  // Get quotes for a customer
  static Future<List<QuoteModel>> getCustomerQuotes(String customerId,
      {String? serviceRequestId}) async {
    try {
      Query query = _firestore
          .collection('quotes')
          .where('customer_id', isEqualTo: customerId);

      if (serviceRequestId != null) {
        query = query.where('service_request_id', isEqualTo: serviceRequestId);
      }

      QuerySnapshot snapshot =
          await query.orderBy('created_at', descending: true).get();

      return snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get customer quotes: ${e.toString()}');
    }
  }

  // Get quotes sent by a worker
  static Future<List<QuoteModel>> getWorkerQuotes(String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('quotes')
          .where('worker_id', isEqualTo: workerId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get worker quotes: ${e.toString()}');
    }
  }

  // Update quote status
  static Future<void> updateQuoteStatus(String quoteId, String status) async {
    try {
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // If quote is accepted, reject all other quotes for the same service request
      if (status == 'accepted') {
        DocumentSnapshot quoteDoc =
            await _firestore.collection('quotes').doc(quoteId).get();
        if (quoteDoc.exists) {
          String serviceRequestId = quoteDoc.get('service_request_id');
          await _rejectOtherQuotes(serviceRequestId, quoteId);
        }
      }
    } catch (e) {
      throw Exception('Failed to update quote status: ${e.toString()}');
    }
  }

  // Get quote by ID
  static Future<QuoteModel?> getQuoteById(String quoteId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (doc.exists) {
        return QuoteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get quote: ${e.toString()}');
    }
  }

  // Search workers for quotes
  static Future<List<WorkerModel>> searchWorkersForQuote({
    required String serviceType,
    double? latitude,
    double? longitude,
    double radiusKm = 20.0,
    double minRating = 0.0,
    double maxPrice = double.infinity,
    String sortBy = 'rating', // rating, price, distance
  }) async {
    try {
      Query query = _firestore
          .collection('workers')
          .where('service_type', isEqualTo: serviceType)
          .where('rating', isGreaterThanOrEqualTo: minRating);

      QuerySnapshot snapshot = await query.get();
      List<WorkerModel> workers =
          snapshot.docs.map((doc) => WorkerModel.fromFirestore(doc)).toList();

      // Filter by price
      workers = workers
          .where((worker) => worker.pricing.dailyWageLkr <= maxPrice)
          .toList();

      // Filter by distance if location is provided
      if (latitude != null && longitude != null) {
        workers = workers.where((worker) {
          double distance = _calculateDistance(
            latitude,
            longitude,
            worker.location.latitude,
            worker.location.longitude,
          );
          return distance <= radiusKm;
        }).toList();
      }

      // Sort workers
      _sortWorkers(workers, sortBy, latitude, longitude);

      return workers;
    } catch (e) {
      throw Exception('Failed to search workers: ${e.toString()}');
    }
  }

  // Private helper methods
  static Future<void> _createQuoteNotification(String customerId,
      String workerId, String quoteId, String serviceRequestId) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': customerId,
        'title': 'New Quote Received',
        'message': 'You have received a new quote for your service request.',
        'type': 'quote',
        'quote_id': quoteId,
        'service_request_id': serviceRequestId,
        'worker_id': workerId,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to create notification: ${e.toString()}');
    }
  }

  static Future<void> _rejectOtherQuotes(
      String serviceRequestId, String acceptedQuoteId) async {
    try {
      QuerySnapshot otherQuotes = await _firestore
          .collection('quotes')
          .where('service_request_id', isEqualTo: serviceRequestId)
          .where('status', isEqualTo: 'pending')
          .get();

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in otherQuotes.docs) {
        if (doc.id != acceptedQuoteId) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Failed to reject other quotes: ${e.toString()}');
    }
  }

  static void _sortWorkers(List<WorkerModel> workers, String sortBy,
      double? latitude, double? longitude) {
    switch (sortBy) {
      case 'rating':
        workers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price':
        workers.sort(
            (a, b) => a.pricing.dailyWageLkr.compareTo(b.pricing.dailyWageLkr));
        break;
      case 'distance':
        if (latitude != null && longitude != null) {
          workers.sort((a, b) {
            double distanceA = _calculateDistance(
                latitude, longitude, a.location.latitude, a.location.longitude);
            double distanceB = _calculateDistance(
                latitude, longitude, b.location.latitude, b.location.longitude);
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180);

  // Mark expired quotes
  static Future<void> markExpiredQuotes() async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot expiredQuotes = await _firestore
          .collection('quotes')
          .where('status', isEqualTo: 'pending')
          .where('valid_until', isLessThan: Timestamp.fromDate(now))
          .get();

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in expiredQuotes.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Failed to mark expired quotes: ${e.toString()}');
    }
  }

  // Get quote statistics for worker
  static Future<Map<String, dynamic>> getWorkerQuoteStats(
      String workerId) async {
    try {
      QuerySnapshot allQuotes = await _firestore
          .collection('quotes')
          .where('worker_id', isEqualTo: workerId)
          .get();

      int totalQuotes = allQuotes.docs.length;
      int acceptedQuotes = 0;
      int pendingQuotes = 0;
      int rejectedQuotes = 0;
      int expiredQuotes = 0;
      double totalValue = 0;

      for (DocumentSnapshot doc in allQuotes.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';
        double price = (data['price'] ?? 0.0).toDouble();

        switch (status) {
          case 'accepted':
            acceptedQuotes++;
            totalValue += price;
            break;
          case 'pending':
            pendingQuotes++;
            break;
          case 'rejected':
            rejectedQuotes++;
            break;
          case 'expired':
            expiredQuotes++;
            break;
        }
      }

      double acceptanceRate =
          totalQuotes > 0 ? (acceptedQuotes / totalQuotes) * 100 : 0;

      return {
        'total_quotes': totalQuotes,
        'accepted_quotes': acceptedQuotes,
        'pending_quotes': pendingQuotes,
        'rejected_quotes': rejectedQuotes,
        'expired_quotes': expiredQuotes,
        'acceptance_rate': acceptanceRate,
        'total_value': totalValue,
      };
    } catch (e) {
      throw Exception('Failed to get quote statistics: ${e.toString()}');
    }
  }

  // Get recent quotes for dashboard
  static Future<List<QuoteModel>> getRecentQuotes({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('quotes')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recent quotes: ${e.toString()}');
    }
  }

  // Send quote notification to customer
  static Future<void> sendQuoteNotification(
      String customerId, String quoteId, String workerName) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': customerId,
        'title': 'New Quote Available',
        'message': '$workerName has sent you a quote for your service request.',
        'type': 'quote_received',
        'quote_id': quoteId,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send quote notification: ${e.toString()}');
    }
  }

  // Get quotes by service request
  static Future<List<QuoteModel>> getQuotesByServiceRequest(
      String serviceRequestId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('quotes')
          .where('service_request_id', isEqualTo: serviceRequestId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception(
          'Failed to get quotes by service request: ${e.toString()}');
    }
  }

  // Update quote price
  static Future<void> updateQuotePrice(String quoteId, double newPrice,
      {String? reason}) async {
    try {
      Map<String, dynamic> updates = {
        'price': newPrice,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updates['price_update_reason'] = reason;
      }

      await _firestore.collection('quotes').doc(quoteId).update(updates);
    } catch (e) {
      throw Exception('Failed to update quote price: ${e.toString()}');
    }
  }

  // Delete quote (only if pending)
  static Future<void> deleteQuote(String quoteId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('quotes').doc(quoteId).get();

      if (!doc.exists) {
        throw Exception('Quote not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String status = data['status'] ?? '';

      if (status != 'pending') {
        throw Exception('Only pending quotes can be deleted');
      }

      await _firestore.collection('quotes').doc(quoteId).delete();
    } catch (e) {
      throw Exception('Failed to delete quote: ${e.toString()}');
    }
  }

  // Request quote from worker
  static Future<void> requestQuoteFromWorker({
    required String workerId,
    required String customerId,
    required String serviceRequestId,
    required String serviceType,
    required String problemDescription,
  }) async {
    try {
      await _firestore.collection('quote_requests').add({
        'worker_id': workerId,
        'customer_id': customerId,
        'service_request_id': serviceRequestId,
        'service_type': serviceType,
        'problem_description': problemDescription,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send notification to worker
      await _firestore.collection('notifications').add({
        'user_id': workerId,
        'title': 'New Quote Request',
        'message': 'A customer has requested a quote for $serviceType service.',
        'type': 'quote_request',
        'service_request_id': serviceRequestId,
        'customer_id': customerId,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to request quote: ${e.toString()}');
    }
  }

  // Get pending quote requests for a worker
  static Future<List<Map<String, dynamic>>> getWorkerQuoteRequests(
      String workerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('quote_requests')
          .where('worker_id', isEqualTo: workerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get quote requests: ${e.toString()}');
    }
  }

  // Mark quote request as responded
  static Future<void> markQuoteRequestResponded(String requestId) async {
    try {
      await _firestore.collection('quote_requests').doc(requestId).update({
        'status': 'responded',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update quote request: ${e.toString()}');
    }
  }

  // Get quote analytics for admin
  static Future<Map<String, dynamic>> getQuoteAnalytics() async {
    try {
      QuerySnapshot allQuotes = await _firestore.collection('quotes').get();

      int totalQuotes = allQuotes.docs.length;
      int acceptedQuotes = 0;
      int pendingQuotes = 0;
      int rejectedQuotes = 0;
      int expiredQuotes = 0;
      double totalValue = 0;
      double acceptedValue = 0;

      for (DocumentSnapshot doc in allQuotes.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';
        double price = (data['price'] ?? 0.0).toDouble();
        totalValue += price;

        switch (status) {
          case 'accepted':
            acceptedQuotes++;
            acceptedValue += price;
            break;
          case 'pending':
            pendingQuotes++;
            break;
          case 'rejected':
            rejectedQuotes++;
            break;
          case 'expired':
            expiredQuotes++;
            break;
        }
      }

      double acceptanceRate =
          totalQuotes > 0 ? (acceptedQuotes / totalQuotes) * 100 : 0;
      double averageQuoteValue = totalQuotes > 0 ? totalValue / totalQuotes : 0;
      double averageAcceptedValue =
          acceptedQuotes > 0 ? acceptedValue / acceptedQuotes : 0;

      return {
        'total_quotes': totalQuotes,
        'accepted_quotes': acceptedQuotes,
        'pending_quotes': pendingQuotes,
        'rejected_quotes': rejectedQuotes,
        'expired_quotes': expiredQuotes,
        'acceptance_rate': acceptanceRate,
        'total_value': totalValue,
        'accepted_value': acceptedValue,
        'average_quote_value': averageQuoteValue,
        'average_accepted_value': averageAcceptedValue,
      };
    } catch (e) {
      throw Exception('Failed to get quote analytics: ${e.toString()}');
    }
  }
}
